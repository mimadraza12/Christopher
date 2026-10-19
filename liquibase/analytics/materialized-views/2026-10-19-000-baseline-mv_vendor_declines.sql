--liquibase formatted sql

--changeset baseline:baseline-analytics-mv_vendor_declines labels:mv,baseline
--comment: Baseline: materialized view analytics.mv_vendor_declines as of 2026-10-19.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'mv_vendor_declines'
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_vendor_declines ON CLUSTER '{cluster}' TO analytics.vendor_declines (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_id` Int32, `order_id` Int32, `decline_reason` Nullable(String), `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) AS SELECT _product AS product, _tenant AS tenant, Declined_Order_Log_ID AS id, Appraiser_ID AS vendor_id, Appraisal_ID AS order_id, Decline_Reason AS decline_reason, Created_On AS created_on, Created_By AS created_by, Last_Modified_On AS last_modified_on, Last_Modified_By AS last_modified_by, _source_ts_ms AS _version, toUInt8(__deleted = 'true') AS _deleted FROM raw.declined_order_log;
--rollback DROP VIEW IF EXISTS analytics.mv_vendor_declines ON CLUSTER '{cluster}' SYNC;