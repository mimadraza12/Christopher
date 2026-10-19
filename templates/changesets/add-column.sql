--liquibase formatted sql

--changeset __AUTHOR__:__ID__ labels:ddl
--comment: __TICKET__ add __COLUMN__ to __TABLE__ (MSSQL __SOURCE_TYPE__). Must be applied BEFORE the source column flows through CDC.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.columns WHERE database = '__DB__' AND table = '__TABLE__' AND name = '__COLUMN__'
ALTER TABLE __DB__.__TABLE__ ON CLUSTER '{cluster}'
    ADD COLUMN IF NOT EXISTS __COLUMN__ Nullable(String);
--rollback ALTER TABLE __DB__.__TABLE__ ON CLUSTER '{cluster}' DROP COLUMN IF EXISTS __COLUMN__;
