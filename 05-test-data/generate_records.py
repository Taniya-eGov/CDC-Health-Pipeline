#!/usr/bin/env python3
"""
Generate records in Postgres for any health-campaign table, so Debezium captures
them as CDC creates.

Each row inserted here becomes one `op = "c"` event on that table's topic. Run
update_records.py afterwards to produce the matching `op = "u"` events.

Columns are read from information_schema at runtime, so only columns that
actually exist in the target database are written. That matters because
tables.sql and the deployed schema drift -- a table missing a later migration
simply gets fewer columns rather than failing.

Values follow real rows from postgres/reference_data.sql; see table_specs.py.
Foreign keys sample real parent ids, so the data joins.

Usage:
    python generate_records.py --table project --rows 200
    python generate_records.py --all --rows 200          # every table, in FK order
    python generate_records.py --list

Prerequisites:
    - the tables exist (see postgres/tables.sql)
    - the Debezium connector is registered, so inserts arrive as op='c'
    - parents are generated before children (--all handles this)
"""

import argparse
import json
import sys
import time
import uuid
from datetime import date, datetime, timedelta, timezone

import psycopg2
from psycopg2.extras import execute_values

import table_specs as S

# Columns the engine fills for every table that has them.
AUDIT_SERVER = ("createdby", "lastmodifiedby")
AUDIT_CLIENT = ("clientcreatedby", "clientlastmodifiedby")
TIME_SERVER = ("createdtime", "lastmodifiedtime")
TIME_CLIENT = ("clientcreatedtime", "clientlastmodifiedtime")

MAX_SEQ_SQL = """
    SELECT coalesce(max(split_part({col}, '-', 5)::int), 0)
    FROM {table} WHERE {col} LIKE %s
"""


def to_ms(dt):
    return int(dt.timestamp() * 1000)


def columns_of(cur, table):
    """(name, data_type, is_nullable) for the table as it exists right now."""
    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s
        ORDER BY ordinal_position
    """, (table,))
    rows = cur.fetchall()
    if not rows:
        # Signals "skip me" so --all keeps going. A single uncreated table used to
        # abort the whole run, leaving every later level ungenerated.
        return None
    return [(n, t, nul == 'YES') for n, t, nul in rows]


def parent_ids(cur, parent, limit=5000):
    cur.execute(f"SELECT id FROM {parent} ORDER BY random() LIMIT %s", (limit,))
    ids = [r[0] for r in cur.fetchall()]
    if not ids:
        raise SystemExit(
            f"parent table {parent} is empty — generate it first "
            f"(order: {' -> '.join(S.ORDER)})"
        )
    return ids


def next_sequences(cur, table, col, prefix, days):
    """Seed one counter per day from what the table already holds."""
    seqs = {}
    for offset in range(days + 1):
        day = (datetime.now(timezone.utc) - timedelta(days=offset)).date()
        cur.execute(MAX_SEQ_SQL.format(col=col, table=table),
                    (f"{prefix}-{day:%Y-%m-%d}-%",))
        seqs[day] = cur.fetchone()[0] + 1
    return seqs


def fallback(data_type, nullable, rnd, col):
    """Value for a column with no rule. NULL where the schema allows it — most
    columns are empty in the reference rows."""
    if nullable:
        return None
    if data_type in ('character varying', 'text'):
        return f"{col}-{rnd.randint(1, 9999)}"
    if data_type in ('bigint', 'integer', 'smallint'):
        return 0
    if data_type == 'boolean':
        return False
    if data_type == 'double precision':
        return 0.0
    if data_type == 'jsonb':
        return json.dumps({})
    if data_type == 'date':
        return date(2000, 1, 1)
    return None


def additional_details(table, rnd, created_ms):
    spec = S.ADDITIONAL_DETAILS.get(table)
    if spec is None:
        return None
    schema, fields = spec
    return json.dumps({
        "fields": [{"key": k, "value": (str(created_ms) if v == "epoch" else v)}
                   for k, v in fields],
        "schema": schema,
        "version": 1,
    })


def build_rows(cur, table, count, days, rnd, server_users, client_users):
    cols = columns_of(cur, table)
    if cols is None:
        return None, None
    names = [c for c, _, _ in cols]
    types = {c: t for c, t, _ in cols}
    nullable = {c: n for c, _, n in cols}

    values = S.VALUES.get(table, {})
    fks = S.FKS.get(table, {})
    prefix = S.ID_PREFIX.get(table)
    secondary = S.SECONDARY_IDS.get(table, {})

    # Resolve foreign keys up front: one query per parent, not per row.
    fk_pool = {}
    for col, parent in fks.items():
        if col not in names:
            continue
        if (table, col) in S.OPTIONAL_FKS:
            continue
        fk_pool[col] = parent_ids(cur, parent)

    now = datetime.now(timezone.utc)
    created_at = sorted(now - timedelta(seconds=rnd.randint(0, days * 86_400))
                        for _ in range(count))

    seqs = next_sequences(cur, table, 'id', prefix, days) if prefix else {}
    sec_seqs = {c: next_sequences(cur, table, c, p, days)
                for c, p in secondary.items() if c in names}

    rows = []
    for created in created_at:
        day = created.date()
        created_ms = to_ms(created)
        # The device recorded the row well before the server saw it — the
        # reference rows are months apart.
        client_ms = created_ms - rnd.randint(1, 240) * 86_400_000
        server_user = rnd.choice(server_users)
        client_user = rnd.choice(client_users)

        row = {}
        for col in names:
            if col == 'id':
                if prefix:
                    row[col] = f"{prefix}-{day:%Y-%m-%d}-{seqs[day]:06d}"
                    seqs[day] += 1
                else:
                    row[col] = str(uuid.uuid4())
            elif col in sec_seqs:
                p = secondary[col]
                row[col] = f"{p}-{day:%Y-%m-%d}-{sec_seqs[col][day]:06d}"
                sec_seqs[col][day] += 1
            elif col in fk_pool:
                row[col] = rnd.choice(fk_pool[col])
            elif col == 'tenantid':
                row[col] = rnd.choice(S.TENANTS)
            elif col == 'clientreferenceid' or col.endswith('clientreferenceid'):
                row[col] = str(uuid.uuid4())
            elif col in AUDIT_SERVER:
                row[col] = server_user
            elif col in AUDIT_CLIENT:
                row[col] = client_user
            elif col in TIME_SERVER:
                row[col] = created_ms
            elif col in TIME_CLIENT:
                row[col] = client_ms
            elif col == 'rowversion':
                row[col] = 1
            elif col == 'isdeleted':
                row[col] = False
            elif col == 'additionaldetails' and col not in values:
                row[col] = additional_details(table, rnd, created_ms)
            elif col in values:
                rule = values[col]
                if rule == 'date':
                    row[col] = date(1970, 1, 1) + timedelta(days=rnd.randint(3650, 20000))
                else:
                    v = rule(rnd)
                    row[col] = json.dumps(v) if isinstance(v, (dict, list)) else v
            else:
                row[col] = fallback(types[col], nullable[col], rnd, col)

        rows.append(tuple(row[c] for c in names))

    return names, rows


def generate(conn, table, count, days, batch, seed):
    rnd = S.new_random(seed)
    server_users = [str(uuid.uuid4()) for _ in range(10)]
    client_users = [str(uuid.uuid4()) for _ in range(25)]

    with conn.cursor() as cur:
        names, rows = build_rows(cur, table, count, days, rnd,
                                 server_users, client_users)
        if names is None:
            print(f"  {table:26} SKIPPED — table does not exist in this database")
            return 0
        sql = f"INSERT INTO {table} ({', '.join(names)}) VALUES %s"

        for i in range(0, len(rows), batch):
            execute_values(cur, sql, rows[i:i + batch], page_size=batch)
        conn.commit()

        cur.execute(f"SELECT count(*) FROM {table}")
        total = cur.fetchone()[0]

    print(f"  {table:26} +{len(rows):<6} -> {total:<7} rows   "
          f"({len(names)} cols)  first id {rows[0][names.index('id')]}")
    return len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=5435)
    parser.add_argument("--dbname", default="testdb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default="postgres")
    parser.add_argument("--table", help="table to generate")
    parser.add_argument("--all", action="store_true",
                        help="every supported table, in foreign-key order")
    parser.add_argument("--list", action="store_true", help="show supported tables")
    parser.add_argument("--rows", type=int, default=500)
    parser.add_argument("--days", type=int, default=7,
                        help="spread createdtime over the last N days (default: 7)")
    parser.add_argument("--batch", type=int, default=500)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    if args.list:
        for level, tables in enumerate(S.LEVELS):
            print(f"level {level}: {', '.join(tables)}")
        return 0

    if not args.table and not args.all:
        parser.error("pass --table <name> or --all")
    if args.table and args.table not in S.SUPPORTED:
        parser.error(f"unsupported table {args.table!r}; --list shows the supported set")

    tables = S.ORDER if args.all else [args.table]

    print(f"Connecting to {args.user}@{args.host}:{args.port}/{args.dbname}")
    conn = psycopg2.connect(host=args.host, port=args.port, dbname=args.dbname,
                            user=args.user, password=args.password)
    try:
        total = 0
        for t in tables:
            total += generate(conn, t, args.rows, args.days, args.batch, args.seed)
        print(f"\nInserted {total} rows across {len(tables)} table(s)")
        print("Next: python update_records.py --all --pct 50")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
