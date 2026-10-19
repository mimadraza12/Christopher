## What changes in ClickHouse
<!-- tables / columns / views / data scripts -->

## Checklist
- [ ] One changeset per file, `--liquibase formatted sql` header, unique `id`
- [ ] Precondition + `IF [NOT] EXISTS`, explicit `--rollback`
- [ ] No `ON CLUSTER` and no `Replicated*` engine paths on objects (Replicated databases replicate DDL themselves)
- [ ] No edits to already-applied files (views/ excepted)
- [ ] Lossy type mappings called out below
- [ ] Ordering: this must be applied BEFORE the source change flows through CDC — source change is gated on it
- [ ] Reviewed the `plan-test` SQL artifact from CI

## Lossy mappings / risks
