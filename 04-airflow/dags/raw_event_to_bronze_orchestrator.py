from __future__ import annotations

import os
import sys

from airflow import DAG
from airflow.decorators import task
from airflow.models import Variable
from airflow.sdk import get_current_context
from pendulum import datetime, duration

# Airflow 3's DAG bundle loader does not reliably put this directory on
# sys.path, so the sibling packages below (and clickhouse_utils, imported by the
# processor) are not importable without this. Same workaround as the
# <entity>_transformation.py DAGs.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.raw_event_bronze_tables import RAW_EVENT_BRONZE_TABLES  # noqa: E402
from processors.raw_event_bronze_processor import process_table  # noqa: E402


DAG_ID = "raw_event_to_bronze"

DEFAULT_SCHEDULE = "0 * * * *"
OVERLAP_MINUTES = 5

# Caps concurrent ClickHouse readers/writers. Both limits are deliberate and
# they bound different things: the pool bounds this work against anything else
# that shares the pool, max_active_tasks bounds it within this DAG. Whichever is
# tighter wins.
#
# The pool is NOT optional and max_active_tasks is NOT a fallback for it. A task
# referencing a pool that does not exist does not quietly run unpooled -- it
# fails to be scheduled. Create it before the first run:
#
#     airflow pools set clickhouse_bronze_extraction 5 \
#         "Raw event store -> Bronze extraction"
BRONZE_EXTRACTION_POOL = "clickhouse_bronze_extraction"
MAX_ACTIVE_TASKS = 5


def get_schedule():
    return Variable.get(
        "raw_to_bronze_schedule",
        default_var=DEFAULT_SCHEDULE,
    )


with DAG(
    dag_id=DAG_ID,
    schedule=get_schedule(),
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    max_active_tasks=MAX_ACTIVE_TASKS,
    tags=[
        "cdc",
        "raw",
        "bronze",
        "clickhouse",
    ],
) as dag:

    @task
    def get_processing_window():
        context = get_current_context()

        data_interval_start = context["data_interval_start"]
        data_interval_end = context["data_interval_end"]

        window_start = (
            data_interval_start
            - duration(minutes=OVERLAP_MINUTES)
        )

        window_end = data_interval_end

        # isoformat(), not to_iso8601_string(): pendulum renders UTC as "Z",
        # which datetime.fromisoformat() only accepts on Python 3.11+.
        # isoformat() emits "+00:00", which parses on every supported version.
        return {
            "window_start": window_start.isoformat(),
            "window_end": window_end.isoformat(),
        }

    @task(
        pool=BRONZE_EXTRACTION_POOL,
        map_index_template="{{ table_name }}",
    )
    def process_table_task(
        table_config: dict,
        window: dict,
    ):
        context = get_current_context()

        table_name = table_config["name"]

        # Used by Airflow to display:
        # process_table_task[household]
        # process_table_task[project_task]
        # etc.
        context["table_name"] = table_name

        return process_table(
            table_config=table_config,
            window_start=window["window_start"],
            window_end=window["window_end"],
        )

    processing_window = get_processing_window()

    process_table_task.partial(
        window=processing_window,
    ).expand(
        table_config=RAW_EVENT_BRONZE_TABLES,
    )