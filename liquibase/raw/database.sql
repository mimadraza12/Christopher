--liquibase formatted sql

--changeset christopher:database-raw labels:state
--comment: The raw database itself.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.databases WHERE name = 'raw'
CREATE DATABASE IF NOT EXISTS raw ON CLUSTER '{cluster}'
    ENGINE = Atomic;
--rollback empty
