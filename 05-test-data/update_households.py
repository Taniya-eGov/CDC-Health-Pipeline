#!/usr/bin/env python3
"""
Update a share of the existing households so Debezium captures them as CDC updates.

Each row touched here becomes one `op = "u"` event, giving the bronze table a
second version of that household. After the raw-to-bronze DAG runs:

    SELECT count() FROM analytics.stg_household         -> creates + updates
    SELECT count() FROM analytics.stg_household FINAL   -> one row per household

and FINAL returns the updated member_count / row_version, because
ReplacingMergeTree(last_modified_time) keeps the highest version.

Usage:
    python update_households.py [--pct 50 | --rows 250]

Prerequisites:
    - run generate_households.py first
"""

import argparse
import random
import sys
import time
import uuid

import psycopg2

# numberofmembers + 1 and rowversion + 1 give a visible, verifiable delta.
#
# GREATEST(lastmodifiedtime + 1, %s) is the important part: it guarantees the new
# version is strictly higher than the old one even if the update lands in the same
# millisecond as the insert. Without it ReplacingMergeTree could keep either row
# and FINAL would be non-deterministic.
UPDATE_SQL = """
    UPDATE household SET
        numberofmembers        = numberofmembers + 1,
        additionaldetails      = coalesce(additionaldetails, '{}'::jsonb)
                                 || '{"updatedByScript": true}'::jsonb,
        lastmodifiedby         = %(user)s,
        lastmodifiedtime       = GREATEST(lastmodifiedtime + 1, %(now_ms)s),
        clientlastmodifiedby   = %(user)s,
        clientlastmodifiedtime = GREATEST(clientlastmodifiedtime + 1, %(now_ms)s),
        rowversion             = rowversion + 1
    WHERE id = ANY(%(ids)s)
"""

SNAPSHOT_SQL = """
    SELECT id, numberofmembers, rowversion, lastmodifiedtime
    FROM household WHERE id = ANY(%s) ORDER BY id
"""


def now_ms() -> int:
    return int(time.time() * 1000)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=5435)
    parser.add_argument("--dbname", default="testdb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default="postgres")
    parser.add_argument("--pct", type=int, default=50,
                        help="percent of households to update (default: 50)")
    parser.add_argument("--rows", type=int, default=None,
                        help="exact number to update; overrides --pct")
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()

    random.seed(args.seed)

    print(f"Connecting to {args.user}@{args.host}:{args.port}/{args.dbname}")
    conn = psycopg2.connect(host=args.host, port=args.port, dbname=args.dbname,
                            user=args.user, password=args.password)

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM household WHERE isdeleted = false")
            available = cur.fetchone()[0]

            if available == 0:
                print("No households found — run generate_households.py first.")
                return 1

            target = args.rows if args.rows is not None else max(1, available * args.pct // 100)
            target = min(target, available)

            # Pick the targets from Postgres itself, so nothing has to be passed
            # between the two scripts.
            cur.execute(
                "SELECT id FROM household WHERE isdeleted = false "
                "ORDER BY random() LIMIT %s",
                (target,),
            )
            ids = [r[0] for r in cur.fetchall()]

            cur.execute(SNAPSHOT_SQL, (ids,))
            before = {r[0]: r[1:] for r in cur.fetchall()}

            cur.execute(UPDATE_SQL, {
                "user": str(uuid.uuid4()),
                "now_ms": now_ms(),
                "ids": ids,
            })
            updated = cur.rowcount

            cur.execute(SNAPSHOT_SQL, (ids,))
            after = {r[0]: r[1:] for r in cur.fetchall()}

            conn.commit()

            cur.execute("SELECT count(*), sum(rowversion) FROM household")
            total, version_sum = cur.fetchone()

        sample_id = ids[0]
        print()
        print(f"Updated {updated} of {available} households ({args.pct}% target)")
        print(f"  household table          : {total} rows, sum(rowversion) = {version_sum}")
        print()
        print(f"  sample id                : {sample_id}")
        print(f"    before (members, version, lastmodifiedtime) : {before[sample_id]}")
        print(f"    after  (members, version, lastmodifiedtime) : {after[sample_id]}")
        print()
        print("Next: run the health_raw_to_bronze DAG, then in ClickHouse:")
        print(f"  SELECT id, member_count, row_version, last_modified_time")
        print(f"  FROM analytics.stg_household WHERE id = '{sample_id}'")
        print(f"  ORDER BY last_modified_time;            -- expect 2 rows")
        print()
        print(f"  SELECT id, member_count, row_version FROM analytics.stg_household FINAL")
        print(f"  WHERE id = '{sample_id}';               -- expect 1 row, the later version")
        return 0

    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
