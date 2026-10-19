--liquibase formatted sql

-- Materialized views are NOT runOnChange: they cannot be CREATE OR REPLACE'd, and a
-- drop/recreate misses rows inserted in between. Every change is a new reviewed file.
-- Two changesets: the target table, then the MV writing TO it.

--changeset __AUTHOR__:__ID__-target labels:mv
--comment: __TICKET__ target table for __MV__
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '${DB}' AND name = '__MV___target'
CREATE TABLE IF NOT EXISTS ${DB}.__MV___target ON CLUSTER '{cluster}'
(
    day   Date,
    cnt   UInt64
)
ENGINE = ReplicatedSummingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY day;
--rollback DROP TABLE IF EXISTS ${DB}.__MV___target ON CLUSTER '{cluster}' SYNC;

--changeset __AUTHOR__:__ID__-mv labels:mv
--comment: __TICKET__ __MV__ (only sees rows inserted AFTER creation; backfill separately in scripts/)
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '${DB}' AND name = '__MV__'
CREATE MATERIALIZED VIEW IF NOT EXISTS ${DB}.__MV__ ON CLUSTER '{cluster}'
TO ${DB}.__MV___target AS
SELECT toDate(created_at) AS day, count() AS cnt
FROM ${DB}.__TABLE__
GROUP BY day;
--rollback DROP VIEW IF EXISTS ${DB}.__MV__ ON CLUSTER '{cluster}' SYNC;
