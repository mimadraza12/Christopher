--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_qualifications labels:ddl,baseline
--comment: Baseline: analytics.vendor_qualifications as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_qualifications'
CREATE TABLE IF NOT EXISTS analytics.vendor_qualifications ON CLUSTER '{cluster}' (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_id` Int32, `qualification_type_id` Int32, `created_on` Nullable(DateTime64(3)), `created_by` Nullable(String), `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, vendor_id, qualification_type_id, id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_qualifications ON CLUSTER '{cluster}' SYNC;