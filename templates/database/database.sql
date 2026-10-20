--liquibase formatted sql

--changeset __AUTHOR__:database-__DB__ labels:state
--comment: The __DB__ database itself.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.databases WHERE name = '__DB__'
CREATE DATABASE IF NOT EXISTS __DB__ ON CLUSTER '{cluster}'
    ENGINE = Atomic;
--rollback empty
