--liquibase formatted sql

--changeset baseline:baseline-analytics-vendor_types labels:ddl,baseline
--comment: Baseline: analytics.vendor_types as it existed in ClickHouse on 2026-10-19 (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'vendor_types'
CREATE TABLE IF NOT EXISTS analytics.vendor_types (`product` LowCardinality(String), `tenant` LowCardinality(String), `vendor_type_id` Int32, `name` String, `description` Nullable(String), `is_active` Bool, `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `eligible_for_sign_up` Bool, `only_use_selected_order_types` Bool, `only_use_selected_qualification_groups` Bool, `auto_complete_order_on_file_submission` Bool, `selected_loan_type_ids` Nullable(String), `is_selected_loan_type` Bool, `restrict_auto_completion_for_nonagency_orders` Bool, `_version` UInt64, `_deleted` UInt8) ENGINE = ReplacingMergeTree(_version, _deleted) ORDER BY (product, tenant, vendor_type_id) SETTINGS index_granularity = 8192;
--rollback DROP TABLE IF EXISTS analytics.vendor_types SYNC;