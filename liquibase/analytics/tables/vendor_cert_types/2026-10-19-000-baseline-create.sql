--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_cert_types labels:ddl,baseline
--comment: Baseline: analytics.vendor_cert_types as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_cert_types'
CREATE TABLE IF NOT EXISTS analytics.vendor_cert_types ON CLUSTER '{cluster}' (`product` LowCardinality(String), `tenant` LowCardinality(String), `cert_type_id` Int32, `name` String, `created_on` DateTime64(3), `created_by` String, `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, cert_type_id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_cert_types ON CLUSTER '{cluster}' SYNC;