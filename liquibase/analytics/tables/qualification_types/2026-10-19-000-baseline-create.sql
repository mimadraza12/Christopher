--liquibase formatted sql

--changeset baseline:baseline-analytics-qualification_types labels:ddl,baseline
--comment: Baseline: analytics.qualification_types as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'qualification_types'
CREATE TABLE IF NOT EXISTS analytics.qualification_types ON CLUSTER '{cluster}' (`product` LowCardinality(String), `tenant` LowCardinality(String), `qualification_type_id` Int32, `name` String, `display_name` String, `description` Nullable(String), `qualification_group_id` Nullable(Int32), `is_active` Bool, `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, qualification_type_id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.qualification_types ON CLUSTER '{cluster}' SYNC;