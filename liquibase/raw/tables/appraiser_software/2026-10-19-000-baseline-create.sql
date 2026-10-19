--liquibase formatted sql

--changeset baseline:baseline-raw-appraiser_software labels:ddl,baseline
--comment: Baseline: raw.appraiser_software as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'raw' AND name = 'appraiser_software'
CREATE TABLE IF NOT EXISTS raw.appraiser_software ON CLUSTER '{cluster}' (`_source_db` LowCardinality(String), `_tenant` LowCardinality(String), `_product` LowCardinality(String), `Appraiser_Software_ID` Int32, `Appraiser_Software_Name` String, `Created_On` DateTime64(3), `Created_By` String, `_source_ts_ms` UInt64, `_source_change_lsn` Nullable(String), `_op` LowCardinality(String), `__deleted` String) ENGINE = ReplacingMergeTree(_source_ts_ms) ORDER BY (_source_db, Appraiser_Software_ID) SETTINGS index_granularity = 8192, number_of_free_entries_in_pool_to_execute_mutation = 0;
--rollback DROP TABLE IF EXISTS raw.appraiser_software ON CLUSTER '{cluster}' SYNC;