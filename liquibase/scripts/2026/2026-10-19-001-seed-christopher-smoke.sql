--liquibase formatted sql

--changeset imad.raza:2026-10-19-001-seed-christopher-smoke context:test labels:data,smoke
--comment: Smoke test of the data-script path: runs once, recorded in DATABASECHANGELOG with labels=data.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM ${DB}._christopher_smoke WHERE id IN (1, 2, 3)
INSERT INTO ${DB}._christopher_smoke (id, name, created_at, note, _version, _is_deleted) VALUES
    (1, 'alpha', now64(3, 'UTC'), 'seeded by liquibase', 1, 0),
    (2, 'beta',  now64(3, 'UTC'), NULL,                  1, 0),
    (3, 'gamma', now64(3, 'UTC'), NULL,                  1, 0);
--rollback ALTER TABLE ${DB}._christopher_smoke DELETE WHERE id IN (1, 2, 3) SETTINGS mutations_sync = 2;
