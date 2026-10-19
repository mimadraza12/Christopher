# Run Liquibase locally in the container against the env in .env (Windows / PowerShell).
#
#   .\bin\lb.ps1 status --verbose --contexts=test
#   .\bin\lb.ps1 update-sql --contexts=test
#   .\bin\lb.ps1 history
#
# Use for planning/inspection. Applying to shared environments goes through
# GitHub Actions (merge to main), not this script.
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$EnvFile = Join-Path $Root '.env'
if (-not (Test-Path $EnvFile)) { throw "missing $EnvFile (copy .env.example)" }

$vars = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    $vars[$k.Trim()] = $v.Trim()
}
if (-not $vars['LB_IMAGE'] -or -not $vars['CH_DB']) { throw 'LB_IMAGE and CH_DB must be set in .env' }

# On Docker Desktop, reach a port-forward on the host via host.docker.internal
# (set LIQUIBASE_COMMAND_URL=jdbc:clickhouse://host.docker.internal:8123/<db> in .env).
docker run --rm -i `
  --env-file $EnvFile `
  -v "$(Join-Path $Root 'liquibase'):/liquibase/changelog:ro" `
  $vars['LB_IMAGE'] @args "-DDB=$($vars['CH_DB'])"
