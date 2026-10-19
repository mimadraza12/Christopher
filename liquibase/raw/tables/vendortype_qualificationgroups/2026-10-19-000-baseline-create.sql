--liquibase formatted sql

--changeset baseline:baseline-raw-vendortype_qualificationgroups labels:ddl,baseline
--comment: Baseline: raw.vendortype_qualificationgroups as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'raw' AND name = 'vendortype_qualificationgroups'
CREATE TABLE IF NOT EXISTS raw.vendortype_qualificationgroups ON CLUSTER '{cluster}' (`_source_db` LowCardinality(String), `_tenant` LowCardinality(String), `_product` LowCardinality(String), `VendorType_QualificationGroup_ID` Int32, `Vendor_Type_ID` Int32, `Qualification_Group_ID` Int32, `Created_On` DateTime64(3), `Created_By` String, `Last_Modified_On` Nullable(DateTime64(3)), `Last_Modified_By` Nullable(String), `_source_ts_ms` UInt64, `_source_change_lsn` Nullable(String), `_op` LowCardinality(String), `__deleted` String) ENGINE = ReplacingMergeTree(_source_ts_ms) ORDER BY (_source_db, VendorType_QualificationGroup_ID) SETTINGS index_granularity = 8192, number_of_free_entries_in_pool_to_execute_mutation = 0;
--rollback DROP TABLE IF EXISTS raw.vendortype_qualificationgroups ON CLUSTER '{cluster}' SYNC;