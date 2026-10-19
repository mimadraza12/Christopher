--liquibase formatted sql

--changeset baseline:baseline-analytics-mv_vendor_engagement_types labels:mv,baseline
--comment: Baseline: materialized view analytics.mv_vendor_engagement_types as of 2026-10-19.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'mv_vendor_engagement_types'
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_vendor_engagement_types TO analytics.vendor_engagement_types (`product` LowCardinality(String), `tenant` LowCardinality(String), `engagement_type_id` Int32, `name` String, `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) AS SELECT _product AS product, _tenant AS tenant, Appraiser_Type_ID AS engagement_type_id, Appraiser_Type_Name AS name, Created_On AS created_on, Created_By AS created_by, Last_Modified_On AS last_modified_on, Last_modified_by AS last_modified_by, _source_ts_ms AS _version, toUInt8(__deleted = 'true') AS _deleted FROM raw.appraiser_types;
--rollback DROP VIEW IF EXISTS analytics.mv_vendor_engagement_types SYNC;