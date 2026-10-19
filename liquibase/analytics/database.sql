--liquibase formatted sql

--changeset baseline:database-analytics labels:ddl,baseline
--comment: The analytics database itself.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.databases WHERE name = 'analytics'
CREATE DATABASE IF NOT EXISTS analytics ON CLUSTER '{cluster}';
--rollback empty