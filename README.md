# Christopher

Keeps the ClickHouse schema for the CDC pipeline (MSSQL → Debezium → Kafka → ClickHouse)
versioned and applied through Liquibase.

This repo holds two things:

- **Schema**: every table, column, view and materialized view in ClickHouse, as Liquibase changesets.
- **Script history**: every data script run against ClickHouse, as run-once changesets.

GitHub has the text and review history. Liquibase's `DATABASECHANGELOG` table in ClickHouse
has the proof of what ran, where, and when. **Nothing changes ClickHouse schema except a
merged PR applied by GitHub Actions.**

## Layout

```
.
├── liquibase/                      # the changelog (Liquibase search path)
│   ├── changelog-master.yaml       # includes the folders below, in this order
│   ├── tables/<table>/             # DDL, run once:   YYYY-MM-DD-NNN-<what>.sql
│   ├── views/<view>.sql            # one file per view, edited in place (runOnChange)
│   ├── materialized-views/         # run once, never edited
│   └── scripts/<year>/             # data scripts, run once: YYYY-MM-DD-NNN-<what>.sql
├── templates/changesets/           # starting points for each changeset type
├── docker/liquibase/               # Liquibase + ClickHouse extension image (cluster mode)
├── ops/clickhouse/                 # one-time bootstrap (db, users, grants) + audit queries
├── config/replicated-subset.yaml   # which MSSQL tables/columns go to ClickHouse
├── bin/                            # lb.sh / lb.ps1 (local liquibase), new-changeset.sh
└── .github/                        # plan on PR, apply on merge, image build, CODEOWNERS
```

## How a change flows

1. Create a file: `bin/new-changeset.sh column orders discount_code`. Edit it.
2. Open a PR. CI runs these checks:
   - **lint**: every `.sql` has the formatted-SQL header, and no applied file was modified, renamed or deleted (only `views/` may be edited).
   - **plan**: `validate`, `status`, then `update-sql` against `test`. The exact SQL is uploaded as the `plan-test` artifact.
3. Review and merge.
4. `liquibase-apply` runs against `test`: `validate` → `status` → `update` → `tag release-<run>-<attempt>` → `history`.
   It runs one at a time per environment, queued and never cancelled.
5. (Later) the same thing runs for `prod` after a manual approval on the `prod` GitHub Environment.

### If an apply fails partway

| Fails at | State | Action |
|---|---|---|
| validate / status | nothing applied | fix in a new PR |
| update | earlier changesets applied + recorded; the failing one either not applied, or its DDL ran but wasn't recorded | fix the cause, re-run the workflow: preconditions + `IF [NOT] EXISTS` make it converge |
| `ON CLUSTER` timeout | DDL applied on reachable replicas; the others catch up from the DDL queue | check replicas (`ops/clickhouse/003-ledger-queries.sql`, last query), don't roll back |
| tag | applied, but this release is untagged | re-run; tagging is idempotent |

## Conventions

| | tables/ | views/ | materialized-views/ | scripts/ |
|---|---|---|---|---|
| runs | once | on every file change (`runOnChange:true`) | once | once |
| edit after apply | never; add a new file | yes, in place | never | never |
| labels | `ddl` | `view` | `mv` | `data` |
| rollback | explicit | `DROP VIEW`; previous version is in git | explicit `DROP` | explicit, or `--rollback empty` with a reason |

- One changeset per file. On ClickHouse, keep it to one DDL statement per changeset: DDL isn't transactional.
- `id` = file name without the date folder; `author` = your handle (or `christopher` for generated changesets).
- Every changeset has a precondition (`onFail:MARK_RAN` for DDL) and `IF [NOT] EXISTS`, so re-runs converge.
- Always use `${DB}.<table>`, `ON CLUSTER '{cluster}'` and `Replicated*` engines with
  `'/clickhouse/tables/{uuid}/{shard}', '{replica}'`.
- CDC tables: `ReplicatedReplacingMergeTree(..., _version, _is_deleted)` with `_version UInt64`
  and `_is_deleted UInt8`, identical on every table. Adjust the names once to whatever the sink writes, then never vary them.
- Contexts: `context:test` changesets only run with `--contexts=test`. Changesets without a context run everywhere.
- **Ordering:** ClickHouse DDL is applied **before** the matching source change flows through CDC.
- **Never move or rename an applied file.** Its path is part of its identity, and Liquibase would run it again.
- Avoid data scripts on CDC-fed tables. The next CDC event for a row overwrites the fix. Fix data at the source instead.

The `_christopher_smoke` table, view and seed script are `context:test` smoke tests for the whole flow.
They never run in prod.

## Running Liquibase

Liquibase always runs in the container built from `docker/liquibase/Dockerfile`:

- Liquibase 4.33.0 + `liquibase-clickhouse` 0.8.3-arenadata (built from the tag) + clickhouse-jdbc 0.9.4. These are pinned together.
- `liquibaseClickhouse.conf` is packed into a jar, so cluster mode is always on. Look for
  `Work in cluster replicated clickhouse mode` in the log. If it's missing, Liquibase's own tables were created non-replicated.

### Local (inspection / planning only)

```bash
docker build -t christopher-liquibase:local docker/liquibase
cp .env.example .env               # fill in; .env is git-ignored
kubectl port-forward svc/<one-replica-service> 8123:8123 -n <ns>   # ONE replica, not the cluster service

bin/lb.sh status --verbose --contexts=test
bin/lb.sh update-sql --contexts=test
bin/lb.sh history
```

On Windows, use `.\bin\lb.ps1` with the same arguments, and set
`LIQUIBASE_COMMAND_URL=jdbc:clickhouse://host.docker.internal:8123/<db>` in `.env`.

Don't run `update` against shared environments from a laptop. Merging is the deploy.

## One-time setup

### ClickHouse (admin, once per environment)

Run `ops/clickhouse/001-bootstrap-database-and-users.sql` with the placeholders filled in. It:

- creates the database and the `liquibase` user, which is the only user with DDL grants
- creates the `cdc_sink` user (SELECT/INSERT only) and a `readonly` role

Also turn off auto-create and schema evolution in the sink connector.

### GitHub

1. **Self-hosted runner in AKS** (actions-runner-controller) with labels `self-hosted, aks`. It must be able to reach
   ClickHouse and pull from ACR.
2. **Image**: set repo variables `ACR_NAME`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
   (an OIDC federated credential for this repo). Then run `build-liquibase-image`.
3. **Environments** `test-plan` and `test` (later `prod-plan` / `prod`, with required reviewers on `prod`). Each needs:

| name | kind | example |
|---|---|---|
| `LIQUIBASE_IMAGE` | var | `<acr>.azurecr.io/christopher-liquibase:4.33.0-0.8.3-arenadata` |
| `CH_JDBC_URL` | var | `jdbc:clickhouse://<replica-0-service>.<ns>.svc:8123/test_db` |
| `CH_DB` | var | `test_db` |
| `CH_LIQUIBASE_USER` | var | `liquibase` |
| `LB_CONTEXTS` | var | `test` |
| `CH_LIQUIBASE_PASSWORD` | secret | from your secret store |

4. **Branch protection on `main`**: PR required, 1+ approval, `lint` and `plan` must pass. Turn on CODEOWNERS review
   and replace the placeholder teams in `.github/CODEOWNERS`.

## Audit / paper trail

`ops/clickhouse/003-ledger-queries.sql` has queries for:

- everything applied
- data scripts that ran
- what each run applied
- replicas that missed `ON CLUSTER` DDL

`ops/clickhouse/002-out-of-band-ddl-check.sql` finds DDL sent by anyone other than `liquibase`.

## Known limits (liquibase-clickhouse)

See `docs/liquibase-clickhouse.md` in the Christopher project for the full notes. In short:

- Only `update`, `tag` and `rollback` with hand-written SQL are supported. There's no `diff`, `generate-changelog` or auto-rollback.
- The Liquibase lock isn't atomic. The workflow `concurrency` group is the real lock.
- Always connect to one fixed replica, because Liquibase's own tables replicate with lag.
