--liquibase formatted sql

--changeset __AUTHOR__:__ID__ runOnChange:true labels:view
--comment: __TICKET__ __VIEW__. Edit this file in place for later changes; runOnChange re-applies it.
CREATE OR REPLACE VIEW __DB__.__VIEW__ ON CLUSTER '{cluster}' AS
SELECT *
FROM __DB__.__TABLE__ FINAL
WHERE _deleted = 0;
--rollback DROP VIEW IF EXISTS __DB__.__VIEW__ ON CLUSTER '{cluster}' SYNC;
