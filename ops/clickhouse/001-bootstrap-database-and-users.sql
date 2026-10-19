-- One-time bootstrap, run MANUALLY by a ClickHouse admin (not by Liquibase: it creates
-- the database Liquibase connects to and the user Liquibase runs as).
--
-- Replace ${DB}, ${LIQUIBASE_CH_PASSWORD}, ${SINK_CH_PASSWORD} before running, e.g.
--   envsubst < 001-bootstrap-database-and-users.sql | clickhouse-client --multiquery
-- Passwords come from your secret store; never commit them.
--
-- Assumes SQL-driven access control (RBAC) with replicated access storage, so
-- ON CLUSTER replicates users/grants. If users are defined in the operator's XML
-- config instead, translate these grants there.

CREATE DATABASE IF NOT EXISTS ${DB} ON CLUSTER '{cluster}';

-- Liquibase runner: the ONLY schema-changing user
CREATE USER IF NOT EXISTS liquibase ON CLUSTER '{cluster}'
    IDENTIFIED WITH sha256_password BY '${LIQUIBASE_CH_PASSWORD}';
GRANT ON CLUSTER '{cluster}'
    CREATE TABLE, CREATE VIEW, ALTER TABLE, ALTER VIEW, DROP TABLE, DROP VIEW,
    SELECT, INSERT
    ON ${DB}.* TO liquibase;
GRANT ON CLUSTER '{cluster}' CLUSTER ON *.* TO liquibase;           -- required for ON CLUSTER DDL
GRANT ON CLUSTER '{cluster}' SELECT ON system.* TO liquibase;       -- preconditions read system.tables/columns

-- CDC sink: writes data, never touches schema (also disable auto-create/evolve in the connector)
CREATE USER IF NOT EXISTS cdc_sink ON CLUSTER '{cluster}'
    IDENTIFIED WITH sha256_password BY '${SINK_CH_PASSWORD}';
GRANT ON CLUSTER '{cluster}' SELECT, INSERT ON ${DB}.* TO cdc_sink;

-- Humans / BI: read-only
CREATE ROLE IF NOT EXISTS readonly ON CLUSTER '{cluster}';
GRANT ON CLUSTER '{cluster}' SELECT ON ${DB}.* TO readonly;
