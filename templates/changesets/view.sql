--liquibase formatted sql

--changeset __AUTHOR__:__ID__ labels:view
--comment: __TICKET__ create/replace view __VIEW__. views/__VIEW__.sql is regenerated from ClickHouse afterwards.
CREATE OR REPLACE VIEW __DB__.__VIEW__ AS
SELECT *
FROM __DB__.__TABLE__ FINAL
WHERE _deleted = 0;
--rollback DROP VIEW IF EXISTS __DB__.__VIEW__ SYNC;
