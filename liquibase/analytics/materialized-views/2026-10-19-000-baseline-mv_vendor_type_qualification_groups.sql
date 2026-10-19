--liquibase formatted sql

--changeset baseline:baseline-analytics-mv_vendor_type_qualification_groups labels:mv,baseline
--comment: Baseline: materialized view analytics.mv_vendor_type_qualification_groups as of 2026-10-19.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = 'analytics' AND name = 'mv_vendor_type_qualification_groups'
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.mv_vendor_type_qualification_groups ON CLUSTER '{cluster}' TO analytics.vendor_type_qualification_groups (`product` LowCardinality(String), `tenant` LowCardinality(String), `id` Int32, `vendor_type_id` Int32, `qualification_group_id` Int32, `created_on` DateTime64(3), `created_by` String, `last_modified_on` Nullable(DateTime64(3)), `last_modified_by` Nullable(String), `_version` UInt64, `_deleted` UInt8) AS SELECT _product AS product, _tenant AS tenant, VendorType_QualificationGroup_ID AS id, Vendor_Type_ID AS vendor_type_id, Qualification_Group_ID AS qualification_group_id, Created_On AS created_on, Created_By AS created_by, Last_Modified_On AS last_modified_on, Last_Modified_By AS last_modified_by, _source_ts_ms AS _version, toUInt8(__deleted = 'true') AS _deleted FROM raw.vendortype_qualificationgroups;
--rollback DROP VIEW IF EXISTS analytics.mv_vendor_type_qualification_groups ON CLUSTER '{cluster}' SYNC;