--liquibase formatted sql

--changeset imad.raza:v_christopher_smoke_current runOnChange:true context:test labels:view,smoke
--comment: Views are edited IN PLACE; runOnChange re-applies the file whenever it changes. git history holds previous definitions.
CREATE OR REPLACE VIEW ${DB}.v_christopher_smoke_current ON CLUSTER '{cluster}' AS
SELECT id, name, created_at, note
FROM ${DB}._christopher_smoke FINAL
WHERE _is_deleted = 0;
--rollback DROP VIEW IF EXISTS ${DB}.v_christopher_smoke_current ON CLUSTER '{cluster}' SYNC;
