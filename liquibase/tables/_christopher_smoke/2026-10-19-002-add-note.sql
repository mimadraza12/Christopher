--liquibase formatted sql

--changeset imad.raza:2026-10-19-002-christopher-smoke-add-note context:test labels:ddl,smoke
--comment: Smoke test of the additive path: new nullable column.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.columns WHERE database = '${DB}' AND table = '_christopher_smoke' AND name = 'note'
ALTER TABLE ${DB}._christopher_smoke ON CLUSTER '{cluster}'
    ADD COLUMN IF NOT EXISTS note Nullable(String) AFTER created_at;
--rollback ALTER TABLE ${DB}._christopher_smoke ON CLUSTER '{cluster}' DROP COLUMN IF EXISTS note;
