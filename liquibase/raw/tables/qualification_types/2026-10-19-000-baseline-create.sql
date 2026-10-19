--liquibase formatted sql

--changeset baseline:baseline-raw-qualification_types labels:ddl,baseline
--comment: Baseline: raw.qualification_types as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'raw' AND name = 'qualification_types'
CREATE TABLE IF NOT EXISTS raw.qualification_types (`_source_db` LowCardinality(String), `_tenant` LowCardinality(String), `_product` LowCardinality(String), `Qualification_Type_ID` Int32, `Qualification_Type_Name` String, `Qualification_Type_Display_Name` String, `Qualification_Type_Description` Nullable(String), `Qualification_Group_ID` Nullable(Int32), `Is_Active` Bool, `Created_On` DateTime64(3), `Created_By` String, `Last_modified_on` Nullable(DateTime64(3)), `Last_modified_by` Nullable(String), `_source_ts_ms` UInt64, `_source_change_lsn` Nullable(String), `_op` LowCardinality(String), `__deleted` String) ENGINE = ReplacingMergeTree(_source_ts_ms) ORDER BY (_source_db, Qualification_Type_ID) SETTINGS index_granularity = 8192, number_of_free_entries_in_pool_to_execute_mutation = 0;
--rollback DROP TABLE IF EXISTS raw.qualification_types SYNC;