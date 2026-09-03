#!/usr/bin/env python3
"""
Generate household records in Postgres so Debezium captures them as CDC creates.

Each row inserted here becomes one `op = "c"` event on the
clickhouse-household-events topic, which the ClickHouse Kafka engine consumes
into analytics.household_events_raw. Run update_households.py afterwards to
produce the matching `op = "u"` events.

Shapes match a real row from the unified dev database:

    id                     H-2023-09-26-000017          <- not a uuid
    tenantid               mz
    clientreferenceid      582097d0-1daa-11ed-...       <- uuid
    numberofmembers        3
    addressid              70ab01ef-e839-4828-...       <- uuid
    additionaldetails      null                         <- often absent
    createdby              24a4254a-ebaa-...            }  server audit
    lastmodifiedby         24a4254a-ebaa-...            }  same user
    createdtime            1695727059462                }  identical on insert
    lastmodifiedtime       1695727059462                }
    rowversion             1
    isdeleted              f
    clientcreatedtime      1676518296071                }  months BEFORE the
    clientlastmodifiedtime 1676518296071                }  server timestamps
    clientcreatedby        59c1d98d-5876-...            }  a DIFFERENT user
    clientlastmodifiedby   59c1d98d-5876-...            }  from createdby

lastmodifiedtime is the ReplacingMergeTree version column in the bronze layer, so
update_households.py must push it strictly higher for FINAL to return the update.

Usage:
    python generate_households.py [--rows 500] [--host localhost --port 5435]

Prerequisites:
    - the household table exists in the target database (see postgres/tables.sql)
    - the Debezium connector is registered, so the inserts arrive as op='c'
      rather than as a later snapshot read
"""

import argparse
import json
import random
import sys
import time
import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone

import psycopg2
from psycopg2.extras import execute_values

# Reference data
TENANTS = ["mz"]
HOUSEHOLD_TYPE = "FAMILY"  # matches the Postgres column DEFAULT

# Business ids look like H-YYYY-MM-DD-NNNNNN, the date being the day the record
# was created and NNNNNN a per-day counter.
ID_PREFIX = "H"
ID_SEQ_WIDTH = 6

COLUMNS = [
    "id",
    "tenantid",
    "clientreferenceid",
    "numberofmembers",
    "householdtype",
    "addressid",
    "additionaldetails",
    "createdby",
    "lastmodifiedby",
    "createdtime",
    "lastmodifiedtime",
    "clientcreatedtime",
    "clientlastmodifiedtime",
    "clientcreatedby",
    "clientlastmodifiedby",
    "rowversion",
    "isdeleted",
]

INSERT_SQL = f"INSERT INTO household ({', '.join(COLUMNS)}) VALUES %s"

# Continue each day's counter from whatever is already in the table, so re-running
# the script never collides on the primary key.
MAX_SEQ_SQL = """
    SELECT coalesce(max(split_part(id, '-', 5)::int), 0)
    FROM household
    WHERE id LIKE %s
"""


def to_ms(dt: datetime) -> int:
    return int(dt.timestamp() * 1000)


def make_id(day: datetime, seq: int) -> str:
    return f"{ID_PREFIX}-{day:%Y-%m-%d}-{seq:0{ID_SEQ_WIDTH}d}"


def build_rows(cur, count: int, days: int, details_pct: int,
               server_users: list, client_users: list) -> list:
    """One tuple per household, in COLUMNS order."""
    now = datetime.now(timezone.utc)

    # Spread the records over the last `days` days so the ids carry a realistic
    # spread of dates rather than all landing on today.
    created_at = sorted(
        now - timedelta(seconds=random.randint(0, days * 86_400))
        for _ in range(count)
    )

    # Seed one counter per distinct day from what the table already holds.
    next_seq = {}
    for day in {d.date() for d in created_at}:
        cur.execute(MAX_SEQ_SQL, (f"{ID_PREFIX}-{day:%Y-%m-%d}-%",))
        next_seq[day] = cur.fetchone()[0] + 1

    rows = []

    for created in created_at:
        day = created.date()
        seq = next_seq[day]
        next_seq[day] = seq + 1

        created_ms = to_ms(created)

        # The device recorded this well before the server ever saw it — the
        # reference row is ~7 months apart. Anything from a day to eight months.
        client_ms = created_ms - random.randint(1, 240) * 86_400_000

        # Server-side and client-side audit users are different people.
        server_user = random.choice(server_users)
        client_user = random.choice(client_users)

        # Most real rows carry no additionalDetails at all. The ones that do use
        # the pregnantWomen / children keys HouseholdTransformationService reads
        # to derive isVulnerable.
        if random.randint(1, 100) <= details_pct:
            additional_details = json.dumps({
                "pregnantWomen": random.randint(0, 2),
                "children": random.randint(0, 4),
            })
        else:
            additional_details = None

        rows.append((
            make_id(created, seq),             # id
            random.choice(TENANTS),            # tenantid
            str(uuid.uuid4()),                 # clientreferenceid (UNIQUE)
            random.randint(1, 12),             # numberofmembers
            HOUSEHOLD_TYPE,                    # householdtype
            str(uuid.uuid4()),                 # addressid
            additional_details,                # additionaldetails (jsonb, often NULL)
            server_user,                       # createdby
            server_user,                       # lastmodifiedby
            created_ms,                        # createdtime
            created_ms,                        # lastmodifiedtime  <- version column
            client_ms,                         # clientcreatedtime
            client_ms,                         # clientlastmodifiedtime
            client_user,                       # clientcreatedby
            client_user,                       # clientlastmodifiedby
            1,                                 # rowversion
            False,                             # isdeleted
        ))

    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=5435)
    parser.add_argument("--dbname", default="testdb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default="postgres")
    parser.add_argument("--rows", type=int, default=500,
                        help="households to insert (default: 500)")
    parser.add_argument("--days", type=int, default=7,
                        help="spread createdtime over the last N days (default: 7)")
    parser.add_argument("--details-pct", type=int, default=30,
                        help="percent of rows carrying additionaldetails; the rest "
                             "are NULL, as most real rows are (default: 30)")
    parser.add_argument("--batch", type=int, default=500,
                        help="rows per execute_values page (default: 500)")
    parser.add_argument("--seed", type=int, default=42,
                        help="random seed (default: 42)")
    args = parser.parse_args()

    random.seed(args.seed)
    server_users = [str(uuid.uuid4()) for _ in range(10)]
    client_users = [str(uuid.uuid4()) for _ in range(25)]

    print(f"Connecting to {args.user}@{args.host}:{args.port}/{args.dbname}")
    conn = psycopg2.connect(host=args.host, port=args.port, dbname=args.dbname,
                            user=args.user, password=args.password)

    try:
        with conn.cursor() as cur:
            rows = build_rows(cur, args.rows, args.days, args.details_pct,
                              server_users, client_users)

            for i in range(0, len(rows), args.batch):
                page = rows[i:i + args.batch]
                execute_values(cur, INSERT_SQL, page, page_size=args.batch)
                print(f"  inserted {i + len(page)}/{len(rows)}")
            conn.commit()

            cur.execute("""
                SELECT count(*), count(additionaldetails),
                       min(createdtime), max(createdtime)
                FROM household
            """)
            total, with_details, min_ct, max_ct = cur.fetchone()

        print()
        print(f"Inserted {len(rows)} households")
        print(f"  household table now holds : {total} rows "
              f"({with_details} with additionaldetails, {total - with_details} NULL)")
        print(f"  createdtime range         : {min_ct} .. {max_ct}")
        print(f"  id range                  : {rows[0][0]} .. {rows[-1][0]}")
        print()
        print("Next: python update_households.py --pct 50")

    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
