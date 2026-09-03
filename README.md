# CDC Health Pipeline

Change-data-capture pipeline for eGov DIGIT **Health Campaign Management (HCM)**:
operational Postgres → Debezium → Kafka → ClickHouse (medallion layers) →
reporting Postgres.

This repo holds every artifact for that flow — source schema, connector config,
ClickHouse DDL, Airflow DAGs, test-data generators, and a local Docker stack that
runs the whole thing on one machine.

---

## The flow

```
┌─ 1. POSTGRES (operational source) ─────────────────────────────────┐
│  01-postgres/tables.sql          ~30 HCM tables                    │
│  wal_level=logical, max_replication_slots=10                       │
└────────────────────────────┬───────────────────────────────────────┘
                             │  WAL (logical replication)
                             ▼
┌─ 2. DEBEZIUM CONNECT ──────────────────────────────────────────────┐
│  02-debezium/health-connector.json                                 │
│                                                                     │
│  ONE connector, ONE replication slot, ONE publication for all       │
│  tables -- deliberately not one per service, which would hold N     │
│  slots against a single database.                                   │
│                                                                     │
│    slot: debezium_health_cdc      publication: dbz_health_cdc       │
│    plugin: pgoutput               snapshot.mode: initial            │
│    decimal.handling.mode: string  tombstones.on.delete: false       │
│                                                                     │
│  RegexRouter renames each topic (× 26):                             │
│    health.public.household  →  clickhouse-household-events          │
└────────────────────────────┬───────────────────────────────────────┘
                             ▼
┌─ 3. KAFKA ─────────────────────────────────────────────────────────┐
│  one topic per table:  clickhouse-<table>-events                    │
└────────────────────────────┬───────────────────────────────────────┘
                             ▼
┌─ 4. CLICKHOUSE  (database: analytics) ─────────────────────────────┐
│                                                                     │
│  00_database.sql              CREATE DATABASE analytics             │
│                                                                     │
│  01  kafka_<t>_events         Kafka engine, JSONAsString      × 28  │
│            │                  consumers, NOT storage                │
│  03        ▼ mv_<t>_events_raw   pass-through, no parsing     × 28  │
│            ▼                                                        │
│  02  <t>_events_raw           MergeTree: event_time, id, raw  × 28  │
│            │                  the replayable event log              │
│            │                                                        │
│            ▼   ★ Airflow: raw → bronze  (04-airflow) ★              │
│                                                                     │
│  04  stg_<t>                  ReplacingMergeTree, typed 1:1   × 28  │
│            │                  replica of the Postgres table         │
│            │                                                        │
│            ▼     Airflow: bronze → silver                           │
│                                                                     │
│  05  <t>_entity               flattened + enriched            × 10  │
│  06  boundary_hierarchy_dim   dimensions                            │
└────────────────────────────┬───────────────────────────────────────┘
                             ▼
┌─ 5. REPORTING POSTGRES ────────────────────────────────────────────┐
│  06-analytics-postgres/       *_enriched tables, data marts        │
│  ⚠ transport mechanism not yet defined                             │
└────────────────────────────────────────────────────────────────────┘
```

**Why four ClickHouse layers and not two.** The Kafka engine table is a
*consumer*: reading from it advances the consumer-group offset and the rows are
gone. So it can never be queried directly — only the layer-03 materialized views
select from it, landing every event in layer 02 where it is durable and
replayable. Bronze is then rebuildable from layer 02 at any time without
re-reading Kafka.

---

## Repo layout

| Path | Stage | What it is |
|---|---|---|
| `01-postgres/` | 1 | `tables.sql` — source schema reference. `reference_data.sql` — real row samples the generators imitate |
| `02-debezium/` | 2 | `health-connector.local.json` — ready to POST locally. `health-connector.json` — deployed shape, with `REPLACE_ME` placeholders for host/db/user/password that must be filled in first |
| `03-clickhouse/` | 4 | `00_database.sql` then `01`–`06`, applied in order. `users.d/` lets non-loopback clients reach the default user |
| `04-airflow/dags/` | 4 | Both Airflow stages — see below |
| `05-test-data/` | — | CDC event generators, so the pipeline has something to carry |
| `06-analytics-postgres/` | 5 | Reporting-side DDL |
| `local/` | — | `docker-compose.yml` — the entire stack on one machine |

### `04-airflow/dags/`

Two stages with **deliberately different shapes**:

```
raw → bronze   (parallel, config-driven)
├── raw_event_to_bronze_orchestrator.py     the DAG: 1 window task + N mapped tasks
├── config/raw_event_bronze_tables.py       ← THE ONLY FILE YOU EDIT PER TABLE
└── processors/raw_event_bronze_processor.py  all extraction logic, no Airflow imports

bronze → silver   (serial, one DAG per entity)
├── bronze-to-silver_orcestrator.py         triggers each entity DAG in order, waits
├── <entity>_transformation.py  × 9
└── egov_api_utils.py                       boundary / user / MDMS lookups

shared
└── clickhouse_utils.py                     client from the `clickhouse_default` Connection
```

| | raw → bronze | bronze → silver |
|---|---|---|
| Topology | 1 DAG, `.expand()` over the config | orchestrator + 9 child DAGs |
| Execution | **parallel**, capped at 5 | **serial** |
| One table fails | others still load | chain halts |
| Adding a table | one config entry | a new DAG file |

The asymmetry is load-bearing, not drift: each raw→bronze task reads exactly one
event store and writes exactly one bronze table, so nothing constrains the order.
Silver transforms join other bronze tables and call external eGov services, so
serial execution bounds load on services outside our control. **Don't "fix" one
to match the other.**

---

## Running it locally

Requires Docker. Everything below is one machine, no cluster.

### Step 1 — start the stack

```bash
cd local
docker compose up -d
```

| Service | Container | Host port | Notes |
|---|---|---|---|
| postgres | `cdc-postgres` | 5435 | source DB, `testdb` |
| zookeeper | `cdc-zookeeper` | 2181 | |
| kafka | `cdc-kafka` | 9092 | |
| connect | `cdc-connect` | 8083 | Debezium REST API |
| clickhouse | `cdc-clickhouse` | 8123 / 9000 | |
| airflow | `cdc-airflow` | **8090** | Airflow **3.0.6**, `standalone` |

Compose project name is pinned to `cdc-health-pipeline`, so volumes are
`cdc-health-pipeline_{postgres,clickhouse,airflow}_data`.

> **If Kafka exits immediately** with
> `KeeperErrorCode = NodeExists ... /brokers/ids/1`, ZooKeeper is still holding
> the previous broker's ephemeral znode — its session hadn't expired when Kafka
> was recreated. Restarting Kafka alone will not fix it; recreate both:
>
> ```bash
> docker compose rm -sf kafka zookeeper && docker compose up -d
> ```

Airflow takes ~50s to answer. Get the admin password:

```bash
docker compose exec airflow cat /opt/airflow/simple_auth_manager_passwords.json.generated
```

> **Airflow 3 is required, not 2.x** — `raw_event_to_bronze_orchestrator.py`
> imports `airflow.sdk`, which does not exist before 3.0. Two related traps:
> `SequentialExecutor` was **removed** in Airflow 3 (don't set it), and
> `AIRFLOW__API_AUTH__JWT_SECRET` is now **mandatory** — without it the
> api-server exits while the scheduler and dag-processor keep running, so the
> container looks healthy while port 8090 refuses connections.

### Step 2 — create the source tables

```bash
docker compose exec -T postgres psql -U postgres -d testdb < ../01-postgres/tables.sql
```

### Step 3 — apply the ClickHouse DDL

```bash
cd ..
for f in 03-clickhouse/0{0,1,2,3,4,5,6}_*.sql; do
  echo "-- $f"
  docker compose -f local/docker-compose.yml exec -T clickhouse clickhouse-client --multiquery < "$f"
done
```

> `00_database.sql` **must** run first. Every other file is `analytics.*`
> qualified but none creates the database, and `--multiquery` aborts on the
> first error — so a missing database looks like "the DDL didn't apply".

Verify 28 objects per layer:

```bash
docker compose -f local/docker-compose.yml exec -T clickhouse clickhouse-client -q "
SELECT engine, count() FROM system.tables
WHERE database='analytics' GROUP BY engine ORDER BY engine"
```

### Step 4 — register the Debezium connector

Order matters: **create the ClickHouse Kafka consumers (step 3) before producing
events**, or the first messages land with no consumer group to read them.

```bash
curl -i -X POST -H "Content-Type: application/json" \
  --data @02-debezium/health-connector.local.json \
  http://localhost:8083/connectors

curl -s http://localhost:8083/connectors/health-cdc-connector/status | jq
```

The connector is named `health-cdc-connector` (not `health-connector`) — that's
the name used in every REST path. To delete and re-register:

```bash
curl -X DELETE http://localhost:8083/connectors/health-cdc-connector
```

An empty reply with `Expecting value: line 1 column 1` means Connect is down, not
that the request was malformed — check `docker compose logs connect`.

### Step 5 — generate CDC events

```bash
cd 05-test-data
pip install psycopg2-binary
python generate_records.py --list              # supported tables, in FK order
python generate_records.py --all --rows 500    # inserts  → op='c'
python update_records.py  --all --pct 50       # updates  → op='u'
```

Confirm they reached ClickHouse:

```bash
docker compose -f ../local/docker-compose.yml exec -T clickhouse clickhouse-client -q "
SELECT count() FROM analytics.household_events_raw"
```

### Step 6 — configure Airflow, then run raw → bronze

```bash
cd ../local
docker compose exec airflow airflow pools set clickhouse_bronze_extraction 5 "Raw -> Bronze"
docker compose exec airflow airflow connections add clickhouse_default \
  --conn-type http --conn-host clickhouse --conn-port 8123 \
  --conn-login default --conn-password "" --conn-schema analytics
docker compose exec airflow airflow variables set raw_to_bronze_schedule "0 * * * *"
```

> The **pool is not optional.** A task pointing at a pool that doesn't exist is
> not scheduled at all — `max_active_tasks` is not a fallback for it.
> Use `--conn-host clickhouse` (the container name), not `localhost`.
> The Variable is optional but silences a `Variable not found` error logged on
> every parse cycle.

Then unpause `raw_event_to_bronze` in the UI and trigger it.

**Mapped tasks come from the config file, not from which tables hold data.** With
two entries you get two `process_table_task` instances, no matter how many
`*_events_raw` tables have rows. Add a table by adding an entry to
`04-airflow/dags/config/raw_event_bronze_tables.py`.

### Step 7 — verify

```sql
SELECT count() AS stored,          -- rises on every re-run
       uniqExact(id) AS entities   -- the real number
FROM analytics.stg_household;

SELECT count() FROM analytics.stg_household FINAL;   -- == entities
```

A rising `count()` is **not** a bug. Bronze is
`ReplacingMergeTree(last_modified_time)`, so re-running a window stores a second
version of each row and the duplicates collapse on merge. Always compare
`uniqExact(id)` or `count() FINAL`.

---

## Design decisions worth knowing

**The read window overlaps by 5 minutes.** Each run reads
`[data_interval_start − 5min, data_interval_end)`. Without the overlap an event
stamped 10:59:58 but physically inserted at 11:00:01 falls in a permanent gap —
the 10:00 run already read past it and the 11:00 run starts at 11:00. Re-reading
is free because bronze deduplicates.

**Each stage filters on its own arrival-time column.** raw→bronze filters the
event store on `event_time`; bronze→silver filters bronze on `_ingested_at`.
Never filter on `last_modified_time` — that is when the row changed *at the
source*, so pipeline latency would silently drop late arrivals.

**Keyset pagination, never OFFSET.** Pages walk `(event_time, id)` — the event
store's own sort key, and unique — so the read stays an index seek that always
advances and handles `event_time` ties. The cursor passes `event_time` as **epoch
millis**, not a datetime parameter: a driver that drops sub-second precision would
move the cursor *backwards* within a second and re-read the same page forever.

**Two different `id` columns.** `<t>_events_raw.id` is a `UUID` surrogate key for
the *event*; `stg_<t>.id` is the `String` business id from Postgres. The keyset
cursor binds the UUID.

**Type coercion is driven by the target ClickHouse type**, because Debezium's
wire encoding isn't the Postgres type: a `DATE` arrives as an *Int32 day count*,
and `NUMERIC` arrives as an exact decimal *string* (`decimal.handling.mode=string`
— `double` would drift at the cent level). Bronze columns are non-Nullable, so a
missing field becomes `''`/`0`/`false`; `individual.date_of_birth` is the
deliberate exception, `Nullable(Date32)`, because `1970-01-01` would read as a
real birth date and corrupt age math downstream.

**Both sides of every mapping are validated at run time.** Bronze targets are
checked against `system.columns`; source keys are checked against a sample of
real event payloads. Without the second check a typo silently loads `''`/`0`
forever — the one failure mode an explicit mapping doesn't remove by itself.

**A null `after` fails the task.** Only CREATE and UPDATE are expected and both
carry a row image, so a null one means silent data loss. `allow_null_after: True`
per table is the documented escape hatch — it exists because the failure is
otherwise a poison pill: the event stays in the window and every retry re-reads it.

**Hard deletes are out of scope.** Services soft-delete via `isdeleted`, and the
connector runs `tombstones.on.delete=false`.

---

## Known gaps

| Gap | Detail |
|---|---|
| **2 of 28 tables configured** | Only `household` and `project_task` are in the raw→bronze config. `address`, `facility`, `individual`, `product`, `project` already have events waiting in the event store |
| bronze → silver never run | The 9 DAGs are implemented but untested end-to-end |
| silver → reporting Postgres | No transport defined; `02_data_marts.sql` is an empty placeholder |
| `household_member` | No usable replica identity — no PK and a nullable `id`, so it needs `REPLICA IDENTITY FULL`, which the production no-ALTER constraint forbids. Held out of scope |
| `service` | `stg_service` models `eg_service`, but the live DB has a different `service` table |
| `household.household_type`, `stock.campaign_number` | In `tables.sql` and bronze, but possibly absent from the live source |
| Layers 01–03 are hand-written × 28 | All three are pure functions of the table name (verified: all 28 raw-store bodies are byte-identical after whitespace normalisation, and every topic/consumer-group name is derivable). A generator would remove ~84 hand-maintained objects |

---

## Note on provenance

**This stack starts empty.** The earlier local run lived under the
`debezium-local` Compose project, so its data sits in
`debezium-local_{postgres,clickhouse,airflow}_data`. This project uses
`cdc-health-pipeline_*` volumes, which are fresh — so steps 2–6 must be run once
to rebuild the schema, connector, events and Airflow config. The old volumes are
untouched if you need anything from them:

```bash
docker volume ls | grep debezium-local
```


These files were **copied** from `debezium-implementation/` and
`Kafka-Postgres-Health-Analytics/`; the originals still exist. Two directories now
hold the same content, so pick one as authoritative before editing further.

Where versions differed, the newer set won: `debezium-implementation/clickhouse/`
held an earlier DDL layout (`02_bronze_tables.sql`, `04_silver_level_tables.sql`)
that the `01`–`06` set here supersedes, and `debezium-implementation/dag/` holds an
unrelated DAG that is **not** part of this pipeline. `00_database.sql` is new here.
