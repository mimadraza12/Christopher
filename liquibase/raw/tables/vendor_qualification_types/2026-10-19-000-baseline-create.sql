--liquibase formatted sql

--changeset baseline:baseline-raw-vendor_qualification_types labels:ddl,baseline
--comment: Baseline: raw.vendor_qualification_types as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'raw' AND name = 'vendor_qualification_types'
CREATE TABLE IF NOT EXISTS raw.vendor_qualification_types ON CLUSTER '{cluster}' (`_source_db` LowCardinality(String), `_tenant` LowCardinality(String), `_product` LowCardinality(String), `Vendor_QualificationType_ID` Int32, `Vendor_ID` Int32, `Qualification_Type_ID` Int32, `Created_On` Nullable(DateTime64(3)), `Created_By` Nullable(String), `Last_Modified_On` Nullable(DateTime64(3)), `Last_Modified_By` Nullable(String), `_source_ts_ms` UInt64, `_source_change_lsn` Nullable(String), `_op` LowCardinality(String), `__deleted` String) ENGINE = ReplacingMergeTree(_source_ts_ms) ORDER BY (_source_db, Vendor_QualificationType_ID) SETTINGS index_granularity = 8192, number_of_free_entries_in_pool_to_execute_mutation = 0;
--rollback DROP TABLE IF EXISTS raw.vendor_qualification_types ON CLUSTER '{cluster}' SYNC;