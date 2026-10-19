--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_type_qualification_groups labels:ddl,baseline
--comment: Baseline: analytics.vendor_type_qualification_groups as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_type_qualification_groups'
CREATE TABLE IF NOT EXISTS analytics.vendor_type_qualification_groups (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_type_id` Int32, `qualification_group_id` Int32, `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, vendor_type_id, qualification_group_id, id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_type_qualification_groups SYNC;