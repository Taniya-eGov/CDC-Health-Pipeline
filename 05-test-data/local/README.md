# Local end-to-end CDC run — `household`

Proves the whole chain on one table:

```
postgres.household
    │  Debezium  (op = 'c' on insert, 'u' on update)
    ▼
clickhouse-household-events            750 messages
    │  ClickHouse Kafka engine + materialized view
    ▼
analytics.household_events_raw         750 envelopes  (c 500 · u 250)
    │  health_raw_to_bronze DAG  →  load_household
    ▼
analytics.stg_household                500 households, latest version each
```

Everything below was executed and the outputs are the real ones.


## Setup

```
export LOCAL=/home/admin1/Desktop/dag/debezium-implementation/debezium-local
export REPO=/home/admin1/Desktop/dag/Kafka-Postgres-Health-Analytics
export CH="docker exec -i debezium-clickhouse clickhouse-client"
export PG="docker exec -i debezium-postgres psql -U postgres -d testdb"
```


## 1. Start all services

Defined in `$LOCAL/docker-compose.yml`:

```
debezium-postgres
debezium-zookeeper
debezium-kafka
debezium-connect
debezium-clickhouse
```

```
$ cd $LOCAL
$ docker compose up -d
```

**Do not move on until all five are Up.** Kafka and Connect can exit silently and
everything downstream then fails in confusing ways.

```
$ docker compose ps

$ until docker exec debezium-kafka /kafka/bin/kafka-topics.sh \
        --bootstrap-server kafka:9092 --list >/dev/null 2>&1; do sleep 2; done && echo "kafka up"

$ until curl -sf localhost:8083/ >/dev/null; do sleep 2; done && echo "connect up"
$ curl -s localhost:8083/ | python3 -m json.tool
```

The last command must print a JSON object with `version` and `kafka_cluster_id`:

```json
{"version":"3.9.0","commit":"a60e31147e6b01ee","kafka_cluster_id":"t10M3VwQQ_Ck6..."}
```

If Kafka exited with `KeeperErrorCode = NodeExists ... registerBroker`, a previous
run left its broker registration in ZooKeeper. Neither Kafka nor ZooKeeper has a
volume in this compose, so recreating all three is a clean reset:

```
$ docker compose rm -sf kafka connect zookeeper && docker compose up -d
```


## 2. Create the Postgres table

```
$ docker exec -it debezium-postgres psql -U postgres -d testdb
```

```sql
CREATE TABLE household
(
    id                     character varying(64) NOT NULL,
    tenantid               character varying(1000),
    clientreferenceid      character varying(1000),
    numberofmembers        integer,
    householdtype          character varying(64) DEFAULT 'FAMILY' NOT NULL,
    addressid              character varying(1000),
    additionaldetails      jsonb,
    createdby              character varying(64),
    lastmodifiedby         character varying(64),
    createdtime            bigint,
    lastmodifiedtime       bigint,
    clientcreatedtime      bigint,
    clientlastmodifiedtime bigint,
    clientcreatedby        character varying(64),
    clientlastmodifiedby   character varying(64),
    rowversion             bigint,
    isdeleted              boolean,

    CONSTRAINT uk_household_id
        PRIMARY KEY (id),

    CONSTRAINT uk_household_client_reference_id
        UNIQUE (clientreferenceid)
);
```

The table must be **empty** when the connector is registered in step 4. If it
already holds rows from an earlier attempt:

```sql
TRUNCATE household;
```

An empty table means the connector's initial snapshot finds nothing, so the
inserts in step 5 arrive as `op='c'`. If rows are already present they arrive as
snapshot reads, `op='r'` — harmless for the DAG, which never inspects `op`, but
the event log tells you less.

`REPLICA IDENTITY` needs no change: `household` has a primary key, which is enough
for insert and update capture. It only matters for the `before` image on deletes,
and this exercise issues none.


## 3. Apply the ClickHouse DDL

```
$ docker exec -it debezium-clickhouse clickhouse-client
```

Create the Kafka table **first**. The consumer group has to exist before any
message is produced, otherwise the consumer starts at the tail of a topic that
already has data.

```sql
CREATE DATABASE IF NOT EXISTS analytics;
```

No DDL file in `ClickHouse_ddl/` creates the database — every statement there is
qualified `analytics.*` — so this line is required on a fresh server.

```sql
CREATE TABLE IF NOT EXISTS analytics.kafka_household_events
(
    raw String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'clickhouse-household-events',
    kafka_group_name = 'clickhouse-household-consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 65536,
    kafka_skip_broken_messages = 100,
    kafka_auto_offset_reset = 'earliest';
```

Two differences from `ClickHouse_ddl/01_kafka_event_consumers.sql`, which is why
that file is **never applied locally**:

- `kafka_broker_list` must be `kafka:9092`. The committed file has
  `release-name-kafka.kafka-kraft.svc.cluster.local:9092`, which does not resolve
  outside the cluster. Symptom: the topic fills up but
  `household_events_raw` stays at 0.
- `kafka_auto_offset_reset = 'earliest'` is not in the committed file. Without it a
  re-run against a topic that already holds messages starts at the end and
  silently ingests nothing.

Event store and ingestion view, copied verbatim from `02` and `03`:

```sql
CREATE TABLE IF NOT EXISTS analytics.household_events_raw
(
    event_time DateTime64(3) DEFAULT now64(3),
    id         UUID          DEFAULT generateUUIDv4(),
    raw        String
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_time)
ORDER BY (event_time, id)
SETTINGS index_granularity = 8192;

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_household_events_raw
TO analytics.household_events_raw
AS
SELECT raw
FROM analytics.kafka_household_events;
```

Bronze table, copied verbatim from `04_bronze_tables.sql`:

```sql
CREATE TABLE IF NOT EXISTS analytics.stg_household
(
    _ingested_at              DateTime64(3) DEFAULT now64(3),
    id                        String,
    tenant_id                 LowCardinality(String),
    client_reference_id       String,
    member_count              Int32,
    household_type            LowCardinality(String),
    address_id                String,
    additional_details        String,
    created_by                String,
    last_modified_by          String,
    created_time              Int64,
    last_modified_time        Int64,
    client_created_time       Int64,
    client_last_modified_time Int64,
    client_created_by         String,
    client_last_modified_by   String,
    row_version               Int64,
    is_deleted                Bool
)
ENGINE = ReplacingMergeTree(last_modified_time)
ORDER BY (tenant_id, id)
SETTINGS index_granularity = 8192;
```

Do **not** apply `03_raw_events_ingestion_mvs.sql` whole. It declares 18 views,
each selecting from a `kafka_<x>_events` table. Only `kafka_household_events`
exists locally, so the second view fails and `--multiquery` aborts the file.

Confirm four objects:

```
$ $CH -q "SELECT name, engine FROM system.tables WHERE database='analytics' ORDER BY name"

household_events_raw        MergeTree
kafka_household_events      Kafka
mv_household_events_raw     MaterializedView
stg_household               ReplacingMergeTree
```


## 4. Register the Debezium connector

Debezium is what reads the Postgres WAL through the `pgoutput` plugin and produces
to Kafka. Postgres pushes nowhere on its own — with no connector there is no
replication slot, no publication and no topic.

Always check the worker is answering first:

```
$ curl -sf localhost:8083/ | head -c 80
```

If that prints **nothing at all**, Connect is down — stop here. `-s` hides the
progress meter and `-f` suppresses the error body, so a dead port produces total
silence, and the POST below then fails with the misleading
`Expecting value: line 1 column 1 (char 0)`. That message means `json.tool`
received an empty string, not that the JSON file is malformed.

```
$ curl -s -X POST -H 'Content-Type: application/json' \
    --data @$REPO/test-data/local/household-connector.local.json \
    localhost:8083/connectors | python3 -m json.tool | head -20

$ curl -s localhost:8083/connectors/household-cdc-connector/status | python3 -m json.tool
```

Connector **and** task must both read `RUNNING`:

```json
{
    "name": "household-cdc-connector",
    "connector": { "state": "RUNNING", "worker_id": "172.27.0.5:8083" },
    "tasks": [ { "id": 0, "state": "RUNNING", "worker_id": "172.27.0.5:8083" } ],
    "type": "source"
}
```

Then confirm Postgres created the slot and publication:

```
$ $PG -c "SELECT slot_name, plugin, active FROM pg_replication_slots;" \
      -c "SELECT pubname, tablename FROM pg_publication_tables;"

       slot_name        |  plugin  | active
------------------------+----------+--------
 debezium_household_cdc | pgoutput | t

      pubname      | tablename
-------------------+-----------
 dbz_household_cdc | household
```

`active = t` is the important column. Any older inactive slot from a previous demo
retains WAL indefinitely and should be dropped:

```sql
SELECT pg_drop_replication_slot('debezium');
DROP PUBLICATION dbz_publication;
```


## 5. Generate the data

```
$ cd $REPO/test-data
$ python3 generate_households.py --rows 500

Inserted 500 households
  household table now holds : 500 rows (147 with additionaldetails, 353 NULL)
  createdtime range         : 1786444661423 .. 1787048832423
  id range                  : H-2026-08-11-000001 .. H-2026-08-18-000027
```

Row shapes follow a real row from the unified dev database: `id` is
`H-YYYY-MM-DD-NNNNNN` rather than a uuid, `additionaldetails` is `NULL` on most
rows, and `clientcreatedtime` sits months before `createdtime` because the device
recorded the record long before it synced.

**Check the creates reached ClickHouse before updating anything.** Give the Kafka
engine a few seconds — it flushes on a block or interval boundary, so an immediate
count can read 0:

```
$ $CH -q "SELECT count() FROM analytics.household_events_raw"
500
```

If it stays 0, go to Troubleshooting rather than layering updates on top.

```
$ python3 update_households.py --pct 50

Updated 250 of 500 households (50% target)
  household table          : 500 rows, sum(rowversion) = 750

  sample id                : H-2026-08-15-000052
    before (members, version, lastmodifiedtime) : (12, 1, 1786801020423)
    after  (members, version, lastmodifiedtime) : (13, 2, 1787049272306)
```

Keep the sample id — step 8 traces that row.

The update uses `lastmodifiedtime = GREATEST(lastmodifiedtime + 1, <now_ms>)`. That
guarantees a strictly higher value even if the update lands in the same
millisecond as the insert. `lastmodifiedtime` is the `ReplacingMergeTree` version
column, so a tie would make `FINAL` non-deterministic.


## 6. Verify the event store

```
$ $CH -q "SELECT count() FROM analytics.household_events_raw"
750

$ $CH -q "SELECT JSONExtractString(raw,'op') op, count() FROM analytics.household_events_raw GROUP BY op ORDER BY op"
c   500
u   250
```

The envelope arrives unwrapped — `before` / `after` / `source` / `op` at the top
level with no `schema`/`payload` around them — because every connector runs with
`value.converter.schemas.enable=false`:

```
$ $CH -q "SELECT JSONExtractString(JSONExtractRaw(raw,'after'),'id') id,
                 JSONExtractInt(JSONExtractRaw(raw,'after'),'numberofmembers') members
          FROM analytics.household_events_raw LIMIT 3"
```

Consumer health, and bronze still untouched:

```
$ $CH -q "SELECT table, num_messages_read, last_exception FROM system.kafka_consumers" --format Vertical
$ $CH -q "SELECT count() FROM analytics.stg_household"
0
```

Kafka-side cross-check:

```
$ docker exec debezium-kafka /kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
    --bootstrap-server kafka:9092 --topic clickhouse-household-events
clickhouse-household-events:0:750
```


## 7. Run the raw → bronze DAG

The DAG imports `common.health_ch_utils`, so both files go into the Airflow dags
mount:

```
$ export AF="/home/admin1/Documents/airflow tutorial/airflow-etl/dags"
$ cp /home/admin1/Desktop/dag/dags/health_raw_to_bronze.py   "$AF/"
$ cp /home/admin1/Desktop/dag/dags/common/health_ch_utils.py "$AF/common/"

$ docker exec airflow-etl-scheduler-1 airflow tasks list health_raw_to_bronze
```

Expect 18 `load_*` tasks plus `start` and `end`.

`CLICKHOUSE_PASSWORD` is the one environment override that matters. The
airflow-etl containers set it to `egov`, but the local ClickHouse `default` user
has no password. `CLICKHOUSE_HOST=172.23.0.1` and `CLICKHOUSE_PORT=8123` are
already correct, and `HEALTH_CLICKHOUSE_DB` is unset so it defaults to `analytics`.

```
$ docker exec -e CLICKHOUSE_PASSWORD= -it airflow-etl-scheduler-1 \
    airflow tasks test health_raw_to_bronze load_household 2026-08-18
```

### If the metadata database is down

`airflow tasks test` needs Airflow's own Postgres. On this machine
`airflow-etl-airflow_db-1` publishes host port **5435**, which `debezium-postgres`
also uses, so the two cannot run at the same time. Symptom:

```
sqlalchemy.exc.OperationalError: could not translate host name "airflow_db" to address
```

Either change `airflow_db`'s published port in the airflow-etl compose file, or
move `debezium-postgres` off 5435. As a stopgap the task body is a plain function
and can be called directly in the same container — same code, same environment,
without the scheduler:

```
$ docker exec -e CLICKHOUSE_PASSWORD= airflow-etl-scheduler-1 python -c "
import sys; sys.path.insert(0,'/opt/airflow/dags')
from health_raw_to_bronze import transform_load_events
print(transform_load_events(stem='household'))"
```

This proves the extraction, pagination, mapping and insert path, but **not** the
Airflow wiring — scheduling, retries and the `max_active_tasks=5` fan-out cap
remain untested.

Either way the log reads:

```
INFO - Manual window: [2026-08-17 17:55:36.919591+00:00, 2026-08-18 17:55:36.918591+00:00)
INFO - stg_household window: [...]
INFO - stg_household: 17 columns | source keys {'id': 'id', 'tenant_id': 'tenantid',
       'client_reference_id': 'clientreferenceid', 'member_count': 'numberofmembers', ...}
INFO - Processing 750 household_events_raw events | fetch=2000/insert=10000
INFO - Chunk 0-750: 750 rows | Total: 750
INFO - Inserted 750 rows into stg_household
INFO - stg_household complete: read 750 events, wrote 750 rows
{'stg_household': 750}
```

The `source keys` line is worth reading. Bronze column names are the Postgres
names in snake_case, so the key in the Debezium `after` object is the column name
with the underscores removed. That holds for 303 of the 304 columns across all 18
bronze tables. The exception is visible above:
`member_count → numberofmembers`, the only entry in `COLUMN_OVERRIDES`.

A manual run takes `get_window`'s rolling-24h branch, which covers events just
ingested. Scheduled runs use Airflow's data interval instead.


## 8. Verify bronze

```
$ $CH -q "SELECT count() FROM analytics.stg_household"          -- 500
$ $CH -q "SELECT count() FROM analytics.stg_household FINAL"    -- 500
$ $CH -q "SELECT uniqExact(id) FROM analytics.stg_household"    -- 500

$ $CH -q "SELECT row_version, count() FROM analytics.stg_household GROUP BY row_version ORDER BY row_version"
1   250        -- never updated
2   250        -- updated once
```

`member_count` must be populated. A wrong source key yields `0` silently and never
raises, so this is the check that catches a broken mapping:

```
$ $CH -q "SELECT min(member_count), max(member_count), countIf(member_count=0) FROM analytics.stg_household FINAL"
1   13   0
```

Trace the sample id from step 5 and compare it to Postgres:

```
$ $CH -q "SELECT id, member_count, row_version, last_modified_time, additional_details
          FROM analytics.stg_household FINAL WHERE id='H-2026-08-11-000003'" --format Vertical

id:                 H-2026-08-11-000003
member_count:       12
row_version:        2
last_modified_time: 1787074017534
additional_details: {"updatedByScript": true}

$ $PG -x -c "SELECT id, numberofmembers, rowversion, lastmodifiedtime, additionaldetails
             FROM household WHERE id='H-2026-08-11-000003'"

id                | H-2026-08-11-000003
numberofmembers   | 12
rowversion        | 2
lastmodifiedtime  | 1787074017534
additionaldetails | {"updatedByScript": true}
```

Whole-table reconciliation — one number that has to match on both sides:

```
$ $PG -tAc "SELECT count(*)||' | '||sum(('x'||substr(md5(id||tenantid||clientreferenceid||numberofmembers||rowversion||lastmodifiedtime),1,8))::bit(32)::bigint) FROM household"
500 | 1088465491115

$ $CH -q "SELECT count() ||' | '|| sum(reinterpretAsUInt32(reverse(unhex(substr(hex(MD5(concat(id,tenant_id,client_reference_id,toString(member_count),toString(row_version),toString(last_modified_time)))),1,8))))) FROM analytics.stg_household FINAL"
500 | 1088465491115
```


## 9. Why `count()` shows 500 and not 750

The DAG reports `wrote 750 rows`, yet:

```
$ $CH -q "SELECT count() FROM analytics.stg_household"
500
```

There are **two** places `ReplacingMergeTree` deduplicates, and they are easy to
conflate.

**Within a single INSERT block.** `optimize_on_insert = 1` is a ClickHouse default:

```
$ $CH -q "SELECT name, value FROM system.settings WHERE name='optimize_on_insert'"
optimize_on_insert   1
```

It applies the engine's merge logic to the inserted block *before* the part is
written. All 750 rows arrived in one `INSERT`, and both versions of each updated
household were inside that block, so they collapsed in memory and the part hit
disk already at 500. It was never 750 on disk — `system.part_log` shows a single
`NewPart` event with `rows = 500` and no merge at all:

```
$ $CH -q "SELECT event_time, event_type, part_name, rows FROM system.part_log
          WHERE database='analytics' AND table='stg_household' ORDER BY event_time"
2026-08-18 17:55:38   NewPart   all_1_1_1   500
```

**Across parts.** No deduplication happens until a background merge combines them,
and merges are asynchronous with no guaranteed schedule. Run the load a second
time and the difference appears:

```
$ $CH -q "SELECT count() FROM analytics.stg_household"          -- 1000
$ $CH -q "SELECT count() FROM analytics.stg_household FINAL"    -- 500
$ $CH -q "SELECT uniqExact(id) FROM analytics.stg_household"    -- 500

$ $CH -q "SELECT name, active, rows FROM system.parts
          WHERE database='analytics' AND table='stg_household' AND active"
all_1_1_1   1   500
all_2_2_1   1   500
```

Two parts, 500 rows each. `count()` honestly reports 1000 stored rows; `FINAL`
resolves them to 500 at query time regardless of part layout.

**The rule:** `count()` on a `ReplacingMergeTree` is a storage metric, not a
business one. Only `FINAL` — or `argMax` / `LIMIT 1 BY` — answers "how many
households are there". Silver must read bronze with `FINAL` for the same reason.

That second run also proves idempotency: `count() FINAL` and `uniqExact(id)` both
stayed at 500, so re-running a task over an already-loaded window is safe. To tidy
the extra part:

```sql
OPTIMIZE TABLE analytics.stg_household FINAL;
```

Fine at 500 rows; it forces a full table rewrite, so not something to run
routinely at real volumes.


## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Expecting value: line 1 column 1 (char 0)` | curl returned an empty body — Connect is down. `docker compose ps`, then `docker logs debezium-connect --tail 30` |
| Kafka `Exited (1)`, `KeeperErrorCode = NodeExists` | Stale ZooKeeper broker registration. `docker compose rm -sf kafka connect zookeeper && docker compose up -d` |
| Connect `No resolvable bootstrap urls given in bootstrap.servers` | Kafka is down. Fix Kafka first; Connect follows |
| Topic has offsets but `household_events_raw` = 0 | Kafka table pointing at the cluster broker. Check with `$CH -q "SELECT extract(create_table_query,'kafka_broker_list = ''([^'']*)''') FROM system.tables WHERE database='analytics' AND engine='Kafka'"` — must be `kafka:9092` |
| `household_events_raw` = 0 and topic is empty | Debezium never produced. `docker logs debezium-connect --tail 30` |
| `op` shows `r` not `c` | Table was not empty when the connector was registered |
| Topic named `health.public.household` | `RegexRouter` not applied. `curl -s localhost:8083/connectors/household-cdc-connector/config \| python3 -m json.tool` |
| Connector task `FAILED` | Usually a stale slot. `$PG -c "SELECT pg_drop_replication_slot('debezium_household_cdc');"` then re-POST |
| DAG auth error against ClickHouse | `CLICKHOUSE_PASSWORD` not blanked — the local `default` user has none |
| `could not translate host name "airflow_db"` | Airflow metadata DB down; port 5435 clashes with `debezium-postgres`. See step 7 |
| `stg_household` empty but raw has rows | Events fall outside the DAG's 24h window, or the `analytics` database is missing |
| `member_count` is 0 everywhere | `COLUMN_OVERRIDES` lost its `member_count → numberofmembers` entry |
