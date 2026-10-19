--liquibase formatted sql

--changeset __AUTHOR__:__ID__ labels:ddl
--comment: __TICKET__ create __TABLE__ (replicated from MSSQL __SOURCE_TABLE__)
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '__DB__' AND name = '__TABLE__'
CREATE TABLE IF NOT EXISTS __DB__.__TABLE__
(
    -- business columns (types from internal/typemap/mssql.go; flag lossy mappings in the PR)
    id          Int64,

    -- CDC columns: identical on every CDC table
    _version    UInt64,
    _deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(_version, _deleted)   -- plain engine, no Keeper paths (single replica today)
ORDER BY (id);
--rollback DROP TABLE IF EXISTS __DB__.__TABLE__ SYNC;
