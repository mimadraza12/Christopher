--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_statuses labels:ddl,baseline
--comment: Baseline: analytics.vendor_statuses as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_statuses'
CREATE TABLE IF NOT EXISTS analytics.vendor_statuses ON CLUSTER '{cluster}' (`product` LowCardinality(String), `tenant` LowCardinality(String), `status_id` Int32, `name` String, `sort_order` Nullable(Int32), `created_on` DateTime64(3), `created_by` String, `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, status_id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_statuses ON CLUSTER '{cluster}' SYNC;