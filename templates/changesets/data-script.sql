--liquibase formatted sql

--changeset __AUTHOR__:__ID__ labels:data
--comment: __TICKET__ __DESCRIPTION__
-- Runs ONCE per environment and is recorded in DATABASECHANGELOG. Never edit after it ran.
-- Avoid scripts on CDC-fed tables: the next CDC event for a row overwrites your fix.
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:1 SELECT count() FROM system.columns WHERE database = '${DB}' AND table = '__TABLE__' AND name = '__COLUMN__'
ALTER TABLE ${DB}.__TABLE__
    UPDATE __COLUMN__ = 'UNKNOWN' WHERE __COLUMN__ IS NULL
    SETTINGS mutations_sync = 2;
--rollback empty
