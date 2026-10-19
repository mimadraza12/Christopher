--liquibase formatted sql

--changeset __AUTHOR__:__ID__ labels:ddl
--comment: __TICKET__ create __TABLE__ (replicated from MSSQL __SOURCE_TABLE__)
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '${DB}' AND name = '__TABLE__'
CREATE TABLE IF NOT EXISTS ${DB}.__TABLE__ ON CLUSTER '{cluster}'
(
    -- business columns (types from internal/typemap/mssql.go; flag lossy mappings in the PR)
    id          Int64,

    -- CDC columns: identical on every CDC table
    _version    UInt64,
    _is_deleted UInt8 DEFAULT 0
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', _version, _is_deleted)
ORDER BY (id);
--rollback DROP TABLE IF EXISTS ${DB}.__TABLE__ ON CLUSTER '{cluster}' SYNC;
