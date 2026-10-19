#!/usr/bin/env bash
# Run Liquibase locally in the container against the env in .env.
#
#   bin/lb.sh status --verbose --contexts=test
#   bin/lb.sh update-sql --contexts=test
#   bin/lb.sh history
#
# Use for planning/inspection. Applying to shared environments goes through
# GitHub Actions (merge to main), not this script.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$ROOT/.env" ] || { echo "missing $ROOT/.env (copy .env.example)"; exit 1; }
# shellcheck disable=SC1091
set -a; . "$ROOT/.env"; set +a
: "${LB_IMAGE:?}" "${CH_DB:?}"

docker run --rm -i \
  --network host \
  --env-file "$ROOT/.env" \
  -v "$ROOT/liquibase:/liquibase/changelog:ro" \
  "$LB_IMAGE" "$@" "-DDB=$CH_DB"
