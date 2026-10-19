-- One-time bootstrap, run MANUALLY by a ClickHouse admin. Liquibase can't run this:
-- it creates the ledger database Liquibase connects to and the user it runs as.
--
-- Replace ${LIQUIBASE_CH_PASSWORD} and ${SINK_CH_PASSWORD} before running; passwords come
-- from your secret store, never commit them. Data databases (raw, analytics, ...) are NOT
-- created here: they are changesets (liquibase/<db>/database.sql).
--
-- Assumes SQL-driven access control (RBAC) with replicated access storage, so ON CLUSTER
-- replicates users/grants. If users live in the operator's XML config, translate there.

-- Ledger: holds ONLY DATABASECHANGELOG + DATABASECHANGELOGLOCK_V1
-- Same engine as raw/analytics/direct (Atomic today). Not `default`: that one is Replicated.
CREATE DATABASE IF NOT EXISTS liquibase ON CLUSTER '{cluster}' ENGINE = Atomic;

-- Liquibase runner: the ONLY schema-changing user
CREATE USER IF NOT EXISTS liquibase ON CLUSTER '{cluster}'
    IDENTIFIED WITH sha256_password BY '${LIQUIBASE_CH_PASSWORD}';
GRANT ON CLUSTER '{cluster}' CREATE DATABASE ON *.* TO liquibase;     -- liquibase/<db>/database.sql
GRANT ON CLUSTER '{cluster}' CLUSTER ON *.* TO liquibase;             -- only CREATE DATABASE uses ON CLUSTER
GRANT ON CLUSTER '{cluster}' SELECT ON system.* TO liquibase;         -- preconditions
GRANT ON CLUSTER '{cluster}' ALL ON liquibase.* TO liquibase;         -- its own ledger
-- one block per managed database (add one when a new liquibase/<db>/ folder appears)
GRANT ON CLUSTER '{cluster}'
    CREATE TABLE, CREATE VIEW, ALTER TABLE, ALTER VIEW, DROP TABLE, DROP VIEW, SELECT, INSERT
    ON raw.* TO liquibase;
GRANT ON CLUSTER '{cluster}'
    CREATE TABLE, CREATE VIEW, ALTER TABLE, ALTER VIEW, DROP TABLE, DROP VIEW, SELECT, INSERT
    ON analytics.* TO liquibase;

-- CDC sink: writes data, never touches schema (also disable auto-create/evolve in the connector)
CREATE USER IF NOT EXISTS cdc_sink ON CLUSTER '{cluster}'
    IDENTIFIED WITH sha256_password BY '${SINK_CH_PASSWORD}';
GRANT ON CLUSTER '{cluster}' SELECT, INSERT ON raw.* TO cdc_sink;

-- Humans / BI: read-only
CREATE ROLE IF NOT EXISTS readonly ON CLUSTER '{cluster}';
GRANT ON CLUSTER '{cluster}' SELECT ON raw.* TO readonly;
GRANT ON CLUSTER '{cluster}' SELECT ON analytics.* TO readonly;
