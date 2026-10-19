--liquibase formatted sql

--changeset __AUTHOR__:__VIEW__ runOnChange:true labels:view
--comment: __TICKET__ __VIEW__. Edit this file in place for later changes; runOnChange re-applies it.
CREATE OR REPLACE VIEW ${DB}.__VIEW__ ON CLUSTER '{cluster}' AS
SELECT *
FROM ${DB}.__TABLE__ FINAL
WHERE _is_deleted = 0;
--rollback DROP VIEW IF EXISTS ${DB}.__VIEW__ ON CLUSTER '{cluster}' SYNC;
