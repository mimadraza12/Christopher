# Tag the latest Liquibase ledger row with a release name (default: git short hash),
# without relying on `liquibase tag` (whose subquery mutation is unreliable on ClickHouse).
#
# It also diagnoses the ledger: table engine, and mutations stuck on it (a failed mutation
# blocks every later one, including tags). Stuck mutations are only killed if you say yes.
#
#   .\bin\tag-release.ps1                  # tag = git rev-parse --short HEAD
#   .\bin\tag-release.ps1 -Tag baseline
#   .\bin\tag-release.ps1 -Tag 8746c37 -Id 2026-10-20-001-raw-appraisals-loan-amount-scale-2
#       tag an EARLIER changeset (by its ID) instead of the latest row, e.g. to create a
#       rollback point you forgot to tag
param(
    [string]$Tag = '',
    [string]$Id = '',
    [string]$Url = 'http://localhost:8123'
)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$vars = @{}
Get-Content (Join-Path $Root '.env') | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; $vars[$k.Trim()] = $v.Trim()
}
$Headers = @{ 'X-ClickHouse-User' = $vars['LIQUIBASE_COMMAND_USERNAME']; 'X-ClickHouse-Key' = $vars['LIQUIBASE_COMMAND_PASSWORD'] }
# ledger database = path segment of the JDBC URL (e.g. .../raw)
$LedgerDb = ($vars['LIQUIBASE_COMMAND_URL'] -replace '^jdbc:clickhouse://[^/]+/?', '') -replace '[?].*$', ''
if (-not $LedgerDb) { throw 'LIQUIBASE_COMMAND_URL in .env has no database path (e.g. .../raw)' }
$T = "$LedgerDb.DATABASECHANGELOG"

function Invoke-Ch([string]$sql, [switch]$NoFormat) {
    $body = if ($NoFormat) { $sql } else { $sql + "`nFORMAT JSONEachRow" }
    $resp = Invoke-WebRequest -Uri $Url -Method Post -Body $body -UseBasicParsing -Headers $Headers -TimeoutSec 300
    $text = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    if ($NoFormat) { return $text }
    @($text -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}
function Q([string]$s) { "'" + ($s -replace '\\', '\\' -replace "'", "\'") + "'" }

if (-not $Tag) { $Tag = (git -C $Root rev-parse --short HEAD).Trim() }
Write-Host "ledger: $T    tag: $Tag"

# 1. engine
$eng = Invoke-Ch "SELECT engine FROM system.tables WHERE database = $(Q $LedgerDb) AND name = 'DATABASECHANGELOG'"
if (-not $eng) { throw "$T does not exist" }
Write-Host "engine: $($eng[0].engine)"

# 2. stuck mutations
$stuck = Invoke-Ch "SELECT mutation_id, command, latest_fail_reason FROM system.mutations WHERE database = $(Q $LedgerDb) AND table = 'DATABASECHANGELOG' AND is_done = 0 ORDER BY create_time"
if ($stuck) {
    Write-Warning "$($stuck.Count) unfinished mutation(s) on the ledger. They block every later update, including tags:"
    $stuck | ForEach-Object { Write-Host "  [$($_.mutation_id)] $($_.command)"; if ($_.latest_fail_reason) { Write-Host "      fail: $($_.latest_fail_reason)" } }
    $answer = Read-Host 'Kill them? Only the ledger table is affected (y/N)'
    if ($answer -ne 'y') { throw 'not tagging while mutations are stuck' }
    Invoke-Ch "KILL MUTATION WHERE database = $(Q $LedgerDb) AND table = 'DATABASECHANGELOG' AND is_done = 0" -NoFormat | Out-Null
    Write-Host 'killed.'
}

# 3. latest row
$where = if ($Id) { "WHERE ID = $(Q $Id)" } else { '' }
$last = Invoke-Ch "SELECT ID, AUTHOR, FILENAME, toString(DATEEXECUTED) AS d, ORDEREXECUTED, TAG FROM $T $where ORDER BY DATEEXECUTED DESC, ORDEREXECUTED DESC LIMIT 1"
if (-not $last) { throw $(if ($Id) { "no ledger row with ID '$Id'" } else { 'ledger is empty: nothing to tag' }) }
$r = $last[0]
Write-Host "row: $($r.FILENAME)::$($r.ID)::$($r.AUTHOR)  ($($r.d))  current tag: '$($r.TAG)'"

# 4. tag it (plain literal WHERE: deterministic, works on any MergeTree engine)
Invoke-Ch "ALTER TABLE $T UPDATE TAG = $(Q $Tag) WHERE ID = $(Q $r.ID) AND AUTHOR = $(Q $r.AUTHOR) AND FILENAME = $(Q $r.FILENAME) SETTINGS mutations_sync = 2" -NoFormat | Out-Null

# 5. verify
$check = Invoke-Ch "SELECT TAG FROM $T WHERE ID = $(Q $r.ID) AND AUTHOR = $(Q $r.AUTHOR) AND FILENAME = $(Q $r.FILENAME)"
if ($check -and $check[0].TAG -eq $Tag) {
    Write-Host "OK: tagged '$Tag'. Roll back to this point later with: .\bin\lb.ps1 rollback --tag=$Tag --contexts=test"
} else {
    $fail = Invoke-Ch "SELECT latest_fail_reason FROM system.mutations WHERE database = $(Q $LedgerDb) AND table = 'DATABASECHANGELOG' AND is_done = 0"
    throw "tag not set. Mutation state: $(if ($fail) { $fail[0].latest_fail_reason } else { 'no pending mutation' })"
}
