-- Paper trail queries against Liquibase's ledger (the `liquibase` database).

-- Everything applied, newest first
SELECT DATEEXECUTED, ORDEREXECUTED, EXECTYPE, ID, AUTHOR, FILENAME, TAG, LABELS, CONTEXTS
FROM liquibase.DATABASECHANGELOG
ORDER BY ORDEREXECUTED DESC;

-- Data scripts that have run
SELECT DATEEXECUTED, EXECTYPE, ID, AUTHOR, FILENAME, TAG
FROM liquibase.DATABASECHANGELOG
WHERE LABELS LIKE '%data%'
ORDER BY DATEEXECUTED;

-- What each run applied (one DEPLOYMENT_ID per `liquibase update`; the release tag
-- is stored only on the LAST row of that run)
SELECT DEPLOYMENT_ID,
       min(DATEEXECUTED)        AS started,
       count()                  AS changesets,
       anyIf(TAG, TAG IS NOT NULL) AS release_tag,
       groupArray(ID)           AS ids
FROM liquibase.DATABASECHANGELOG
GROUP BY DEPLOYMENT_ID
ORDER BY started DESC;

-- Replicas whose schema differs from the others (missed ON CLUSTER DDL)
SELECT database, name, uniqExact(create_table_query) AS variants,
       groupArray((hostName(), substring(create_table_query, 1, 120))) AS per_replica
FROM clusterAllReplicas('{cluster}', system.tables)
WHERE database IN ('raw', 'analytics')
GROUP BY database, name
HAVING variants > 1;
