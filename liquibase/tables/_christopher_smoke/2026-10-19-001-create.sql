--liquibase formatted sql

--changeset imad.raza:2026-10-19-001-create-christopher-smoke context:test labels:ddl,smoke
--comment: Smoke-test table to prove the Liquibase -> ClickHouse flow end to end. context:test, so it never runs in prod.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '${DB}' AND name = '_christopher_smoke'
CREATE TABLE IF NOT EXISTS ${DB}._christopher_smoke ON CLUSTER '{cluster}'
(
    id          Int64,
    name        String,
    created_at  DateTime64(3, 'UTC'),
    _version    UInt64,
    _is_deleted UInt8 DEFAULT 0
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', _version, _is_deleted)
ORDER BY id;
--rollback DROP TABLE IF EXISTS ${DB}._christopher_smoke ON CLUSTER '{cluster}' SYNC;
