--liquibase formatted sql

--changeset baseline:baseline-analytics-mv_vendor_qualifications labels:mv,baseline
--comment: Baseline: materialized view analytics.mv_vendor_qualifications as of 2026-10-19.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'mv_vendor_qualifications'
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_vendor_qualifications ON CLUSTER '{cluster}' TO analytics.vendor_qualifications (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_id` Int32, `qualification_type_id` Int32, `created_on` Nullable(DateTime64(3)), `created_by` Nullable(String), `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) AS SELECT _product AS product, _tenant AS tenant, Vendor_QualificationType_ID AS id, Vendor_ID AS vendor_id, Qualification_Type_ID AS qualification_type_id, Created_On AS created_on, Created_By AS created_by, Last_Modified_On AS last_modified_on, Last_Modified_By AS last_modified_by, _source_ts_ms AS _version, toUInt8(__deleted = 'true') AS _deleted FROM raw.vendor_qualification_types;
--rollback DROP VIEW IF EXISTS analytics.mv_vendor_qualifications ON CLUSTER '{cluster}' SYNC;