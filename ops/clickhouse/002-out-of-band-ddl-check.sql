-- DDL on managed databases in the last day by anyone other than the liquibase user.
-- Any row here means the schema was changed outside the changelog.
SELECT event_time, hostName() AS replica, user, query_kind, query
FROM clusterAllReplicas('{cluster}', system.query_log)
WHERE type = 'QueryFinish'
  AND query_kind IN ('Create', 'Alter', 'Drop', 'Rename')
  AND user != 'liquibase'
  AND hasAny(databases, ['raw', 'analytics'])   -- every managed database
  AND event_time > now() - INTERVAL 1 DAY
ORDER BY event_time DESC;
