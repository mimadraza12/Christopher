--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_declines labels:ddl,baseline
--comment: Baseline: analytics.vendor_declines as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_declines'
CREATE TABLE IF NOT EXISTS analytics.vendor_declines (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_id` Int32, `order_id` Int32, `decline_reason` Nullable(String), `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, vendor_id, id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_declines SYNC;