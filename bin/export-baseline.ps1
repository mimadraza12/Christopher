# Export the CURRENT ClickHouse schema as baseline changesets, one folder per database:
#   liquibase\<db>\tables\<table>\<date>-000-baseline-create.sql
#   liquibase\<db>\views\<view>.sql
#   liquibase\<db>\materialized-views\<date>-000-baseline-<mv>.sql
#
# Read-only against ClickHouse (SELECTs on system tables over HTTP). Existing files are
# never overwritten, so re-running only adds objects that are missing from the repo.
#
# Which databases: -Databases if given, else LB_DATABASES from .env (comma-separated,
# e.g. LB_DATABASES=raw,analytics), else every non-system database.
# Each database gets its folder (changelog.yaml, database.sql, subfolders) and is added
# to changelog-master.yaml automatically.
#
#   .\bin\export-baseline.ps1                              # LB_DATABASES from .env
#   .\bin\export-baseline.ps1 -Databases raw               # just raw
#   .\bin\export-baseline.ps1 -Url http://localhost:18123
param(
    [string[]]$Databases = @(),
    [string]$Url = 'http://localhost:8123',
    [string]$Author = 'baseline'
)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Lb   = Join-Path $Root 'liquibase'
$Date = Get-Date -Format 'yyyy-MM-dd'
$Excluded = @('system', 'INFORMATION_SCHEMA', 'information_schema', 'default', 'liquibase')

# --- read .env -----------------------------------------------------------------
$vars = @{}
Get-Content (Join-Path $Root '.env') | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; $vars[$k.Trim()] = $v.Trim()
}
$Headers = @{ 'X-ClickHouse-User' = $vars['LIQUIBASE_COMMAND_USERNAME']; 'X-ClickHouse-Key' = $vars['LIQUIBASE_COMMAND_PASSWORD'] }

function Invoke-Ch([string]$sql) {
    $resp = Invoke-WebRequest -Uri $Url -Method Post -Body ($sql + "`nFORMAT JSONEachRow") -UseBasicParsing -Headers $Headers
    $text = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    @($text -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}
function Write-Lf([string]$path, [string]$content) {
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    if (Test-Path $path) { Write-Host "  exists, skipped: $($path.Substring($Root.Length + 1))"; return }
    [IO.File]::WriteAllText($path, ($content -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding $false))
    Write-Host "  wrote $($path.Substring($Root.Length + 1))"
}
function Convert-Ddl([string]$ddl, [bool]$isView) {
    $d = $ddl
    $d = $d -replace " UUID '[0-9a-f-]{36}'", ''                                   # hidden table UUIDs
    $d = $d -replace '/clickhouse/tables/[0-9a-f-]{36}/', '/clickhouse/tables/{uuid}/' # expanded {uuid}
    if ($isView) {
        $d = $d -replace '^CREATE VIEW (\S+)', 'CREATE OR REPLACE VIEW $1 ON CLUSTER ''{cluster}'''
    } else {
        $d = $d -replace '^CREATE (TABLE|MATERIALIZED VIEW) (\S+)', 'CREATE $1 IF NOT EXISTS $2 ON CLUSTER ''{cluster}'''
    }
    $d.TrimEnd() + ';'
}

$tplDatabase = @'
--liquibase formatted sql

--changeset __AUTHOR__:database-__DB__ labels:ddl,baseline
--comment: The __DB__ database itself.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.databases WHERE name = '__DB__'
CREATE DATABASE IF NOT EXISTS __DB__ ON CLUSTER '{cluster}';
--rollback empty
'@
$tplTable = @'
--liquibase formatted sql

--changeset __AUTHOR__:baseline-__DB__-__NAME__ labels:ddl,baseline
--comment: Baseline: __DB__.__NAME__ as it existed in ClickHouse on __DATE__ (captured from system.tables).
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '__DB__' AND name = '__NAME__'
__DDL__
--rollback DROP TABLE IF EXISTS __DB__.__NAME__ ON CLUSTER '{cluster}' SYNC;
'@
$tplView = @'
--liquibase formatted sql

--changeset __AUTHOR__:__DB__-__NAME__ runOnChange:true labels:view,baseline
--comment: Baseline: view __DB__.__NAME__ as of __DATE__. Edit this file in place for later changes.
__DDL__
--rollback DROP VIEW IF EXISTS __DB__.__NAME__ ON CLUSTER '{cluster}' SYNC;
'@
$tplMv = @'
--liquibase formatted sql

--changeset __AUTHOR__:baseline-__DB__-__NAME__ labels:mv,baseline
--comment: Baseline: materialized view __DB__.__NAME__ as of __DATE__.
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM system.tables WHERE database = '__DB__' AND name = '__NAME__'
__DDL__
--rollback DROP VIEW IF EXISTS __DB__.__NAME__ ON CLUSTER '{cluster}' SYNC;
'@
function Fill([string]$tpl, [string]$db, [string]$name, [string]$ddl) {
    $tpl.Replace('__AUTHOR__', $Author).Replace('__DB__', $db).Replace('__NAME__', $name).Replace('__DATE__', $Date).Replace('__DDL__', $ddl)
}

# --- which databases ---------------------------------------------------------------
if ($Databases.Count -eq 0 -and $vars['LB_DATABASES']) {
    $Databases = $vars['LB_DATABASES'] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    Write-Host "using LB_DATABASES from .env"
}
if ($Databases.Count -eq 0) {
    $Databases = (Invoke-Ch "SELECT name FROM system.databases ORDER BY name") |
        ForEach-Object { $_.name } | Where-Object { $Excluded -notcontains $_ }
}
Write-Host "databases: $($Databases -join ', ')"

$skipped = @()
foreach ($db in $Databases) {
    $dbDir = Join-Path $Lb $db
    Write-Host "== $db"
    Write-Lf (Join-Path $dbDir 'database.sql') (Fill $tplDatabase $db '' '')
    $tplChangelog = [IO.File]::ReadAllText((Join-Path $Root 'templates\database\changelog.yaml')).Replace('__DB__', $db)
    Write-Lf (Join-Path $dbDir 'changelog.yaml') $tplChangelog
    foreach ($sub in 'tables', 'views', 'materialized-views', 'scripts') {
        New-Item -ItemType Directory -Force -Path (Join-Path $dbDir $sub) | Out-Null
    }
    $master = Join-Path $Lb 'changelog-master.yaml'
    if (-not (Select-String -Path $master -Pattern ("^\s*file: " + [regex]::Escape($db) + "/changelog\.yaml\s*$") -Quiet)) {
        [IO.File]::AppendAllText($master, "  - include:`n      file: $db/changelog.yaml`n      relativeToChangelogFile: true`n", (New-Object Text.UTF8Encoding $false))
        Write-Host "  added $db/changelog.yaml at the END of changelog-master.yaml -> move it up if '$db' must run before a database listed above it"
        Write-Host "  TODO grant the liquibase user on $db.* (ops\clickhouse\001-bootstrap-database-and-users.sql)"
    }
    $rows = Invoke-Ch @"
SELECT name, engine, create_table_query
FROM system.tables
WHERE database = '$db'
  AND NOT is_temporary
  AND name NOT LIKE 'DATABASECHANGELOG%'
  AND name NOT LIKE '.inner%'
ORDER BY name
"@
    Write-Host "  $($rows.Count) objects"
    foreach ($r in $rows) {
        switch ($r.engine) {
            'View'             { Write-Lf (Join-Path $dbDir "views\$($r.name).sql") (Fill $tplView $db $r.name (Convert-Ddl $r.create_table_query $true)) }
            'MaterializedView' { Write-Lf (Join-Path $dbDir "materialized-views\$Date-000-baseline-$($r.name).sql") (Fill $tplMv $db $r.name (Convert-Ddl $r.create_table_query $false)) }
            'Dictionary'       { $skipped += "$db.$($r.name) (dictionary)" }
            default            { Write-Lf (Join-Path $dbDir "tables\$($r.name)\$Date-000-baseline-create.sql") (Fill $tplTable $db $r.name (Convert-Ddl $r.create_table_query $false)) }
        }
    }
}
if ($skipped) { Write-Warning ("not exported, handle manually: " + ($skipped -join ', ')) }
Write-Host "Liquibase tracking tables (DATABASECHANGELOG*) were skipped in every database."
