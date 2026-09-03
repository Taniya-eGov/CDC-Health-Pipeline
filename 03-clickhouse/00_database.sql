-- ============================================================================
-- DATABASE
-- ============================================================================
-- Run this FIRST, before 01-06.
--
-- Every statement in 01_kafka_event_consumers.sql through 06_dimension_tables.sql
-- is qualified as `analytics.<object>`, but none of them creates the database.
-- On a fresh ClickHouse instance those files therefore all fail with
-- "Code: 81. DB::Exception: Database analytics does not exist", which reads like
-- a broken DDL file rather than a missing prerequisite.
--
-- Note also that clickhouse-client --multiquery ABORTS ON THE FIRST ERROR, so a
-- missing database makes it look as though nothing was applied at all -- or
-- worse, that only the first object was created.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS analytics;
