--liquibase formatted sql

--changeset baseline:baseline-analytics-mv_vendor_statuses labels:mv,baseline
--comment: Baseline: materialized view analytics.mv_vendor_statuses as of 2026-10-19.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'mv_vendor_statuses'
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_vendor_statuses ON CLUSTER '{cluster}' TO analytics.vendor_statuses (`product` LowCardinality(String), `tenant` LowCardinality(String), `status_id` Int32, `name` String, `sort_order` Nullable(Int32), `created_on` DateTime64(3), `created_by` String, `_version` UInt64, `_deleted` UInt8) AS SELECT _product AS product, _tenant AS tenant, Appraiser_Status_ID AS status_id, Appraiser_Status_Name AS name, Sort_Order AS sort_order, Created_On AS created_on, Created_By AS created_by, _source_ts_ms AS _version, toUInt8(__deleted = 'true') AS _deleted FROM raw.appraiser_statuses;
--rollback DROP VIEW IF EXISTS analytics.mv_vendor_statuses ON CLUSTER '{cluster}' SYNC;