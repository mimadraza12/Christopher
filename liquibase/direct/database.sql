--liquibase formatted sql

--changeset baseline:database-direct labels:ddl,baseline
--comment: The direct database itself.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.databases WHERE name = 'direct'
CREATE DATABASE IF NOT EXISTS direct ON CLUSTER '{cluster}';
--rollback empty