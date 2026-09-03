#!/usr/bin/env python3
"""
Update a share of the existing rows in any health-campaign table, so Debezium
captures them as CDC updates.

Each row touched becomes one `op = "u"` event, giving the bronze table a second
version of that row. After the raw-to-bronze DAG runs:

    SELECT count() FROM analytics.stg_<table>         -- creates + updates
    SELECT count() FROM analytics.stg_<table> FINAL   -- one row per source row

and FINAL returns the updated values, because ReplacingMergeTree keeps the
highest last_modified_time.

The engine bumps whatever version columns the table has -- lastmodifiedtime,
clientlastmodifiedtime, rowversion -- and applies one table-specific business
change from table_specs.MUTATIONS. Columns are checked against
information_schema first, so a table missing a later migration is handled.

Usage:
    python update_records.py --table project_task --pct 50
    python update_records.py --all --pct 50

Prerequisites:
    - run generate_records.py first
"""

import argparse
import sys
import time
import uuid

import psycopg2

import table_specs as S


def now_ms():
    return int(time.time() * 1000)


def existing_columns(cur, table):
    cur.execute("""
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s
    """, (table,))
    rows = cur.fetchall()
    if not rows:
        raise SystemExit(f"table public.{table} does not exist in this database")
    return {r[0] for r in rows}


def build_update(table, cols):
    """SET clauses, applied only for columns the table actually has.

    GREATEST(<col> + 1, %(now_ms)s) guarantees the new version is strictly higher
    than the old one even when the update lands in the same millisecond as the
    insert. Without it ReplacingMergeTree could keep either row and FINAL would
    be non-deterministic.
    """
    sets = []

    if 'lastmodifiedby' in cols:
        sets.append("lastmodifiedby = %(user)s")
    if 'lastmodifiedtime' in cols:
        sets.append("lastmodifiedtime = GREATEST(lastmodifiedtime + 1, %(now_ms)s)")
    if 'clientlastmodifiedby' in cols:
        sets.append("clientlastmodifiedby = %(user)s")
    if 'clientlastmodifiedtime' in cols:
        sets.append("clientlastmodifiedtime = GREATEST(clientlastmodifiedtime + 1, %(now_ms)s)")
    if 'rowversion' in cols:
        sets.append("rowversion = coalesce(rowversion, 0) + 1")
    if 'additionaldetails' in cols:
        sets.append("additionaldetails = coalesce(additionaldetails, '{}'::jsonb) "
                    "|| '{\"updatedByScript\": true}'::jsonb")

    mutation = S.MUTATIONS.get(table)
    if mutation:
        sets.append(mutation)

    return sets


def update(conn, table, pct, rows_arg, seed):
    with conn.cursor() as cur:
        cols = existing_columns(cur, table)

        cur.execute(f"SELECT count(*) FROM {table}")
        available = cur.fetchone()[0]
        if available == 0:
            print(f"  {table:26} skipped — no rows (run generate_records.py first)")
            return 0

        target = rows_arg if rows_arg is not None else max(1, available * pct // 100)
        target = min(target, available)

        where = "WHERE isdeleted = false" if 'isdeleted' in cols else ""
        cur.execute(f"SELECT id FROM {table} {where} ORDER BY random() LIMIT %s",
                    (target,))
        ids = [r[0] for r in cur.fetchall()]
        if not ids:
            print(f"  {table:26} skipped — nothing selectable")
            return 0

        sets = build_update(table, cols)
        cur.execute(
            f"UPDATE {table} SET {', '.join(sets)} WHERE id = ANY(%(ids)s)",
            {"user": str(uuid.uuid4()), "now_ms": now_ms(), "ids": ids},
        )
        updated = cur.rowcount
        conn.commit()

        versioned = 'lastmodifiedtime' in cols
        note = "" if versioned else "   (no audit columns — bronze versions by load order)"
        print(f"  {table:26} {updated:<6} of {available:<7} updated"
              f"   sample {ids[0]}{note}")
        return updated


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=5435)
    parser.add_argument("--dbname", default="testdb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default="postgres")
    parser.add_argument("--table")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--pct", type=int, default=50,
                        help="percent of rows to update (default: 50)")
    parser.add_argument("--rows", type=int, default=None,
                        help="exact number to update; overrides --pct")
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()

    if not args.table and not args.all:
        parser.error("pass --table <name> or --all")
    if args.table and args.table not in S.SUPPORTED:
        parser.error(f"unsupported table {args.table!r}")

    tables = S.ORDER if args.all else [args.table]

    print(f"Connecting to {args.user}@{args.host}:{args.port}/{args.dbname}")
    conn = psycopg2.connect(host=args.host, port=args.port, dbname=args.dbname,
                            user=args.user, password=args.password)
    try:
        total = sum(update(conn, t, args.pct, args.rows, args.seed) for t in tables)
        print(f"\nUpdated {total} rows across {len(tables)} table(s)")
        print("Next: run the health_raw_to_bronze DAG, then compare "
              "count() with count() FINAL in ClickHouse")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
