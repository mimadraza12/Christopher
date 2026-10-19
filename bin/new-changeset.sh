#!/usr/bin/env bash
# Create a new changeset file from a template with the right name and id.
#
#   bin/new-changeset.sh <db> database                            # just create the database folder
#   bin/new-changeset.sh <db> table   <table>                    # CREATE TABLE
#   bin/new-changeset.sh <db> column  <table> <column>           # ADD COLUMN
#   bin/new-changeset.sh <db> view    <view>  [<source_table>]   # runOnChange view (one file per view)
#   bin/new-changeset.sh <db> mv      <mv>    [<source_table>]   # materialized view
#   bin/new-changeset.sh <db> script  <slug>  [<table>]          # one-off data script
#
# e.g. bin/new-changeset.sh analytics column vendors region
#
# If liquibase/<db>/ doesn't exist yet, it is created automatically:
#   liquibase/<db>/changelog.yaml, database.sql (CREATE DATABASE ... ON CLUSTER),
#   tables/ views/ materialized-views/ scripts/, and an include at the END of
#   changelog-master.yaml. Move that include up if the new database must run before
#   one listed after it, and grant the liquibase user on it (ops/clickhouse/001-...).
#
# AUTHOR defaults to `git config user.email` local part. Edit the generated file
# (types, columns, SQL) before opening the PR.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/templates/changesets"
TD="$ROOT/templates/database"
MASTER="$ROOT/liquibase/changelog-master.yaml"
DB="${1:?database (folder under liquibase/, e.g. raw or analytics)}"
kind="${2:?kind: database|table|column|view|mv|script}"
if [ "$kind" = "database" ]; then name=""; else name="${3:?name}"; fi
extra="${4:-}"
[[ "$DB" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { echo "invalid database name: $DB" >&2; exit 1; }
LB="$ROOT/liquibase/$DB"
AUTHOR="${AUTHOR:-$(git -C "$ROOT" config user.email 2>/dev/null | cut -d@ -f1)}"
AUTHOR="${AUTHOR:-unknown}"
TODAY="$(date +%F)"

next_seq() { # next NNN for today within a directory
  local dir="$1" n
  n=$(ls "$dir" 2>/dev/null | grep -c "^$TODAY-" || true)
  printf '%03d' $((n + 1))
}

render() { # template out_file id
  sed -e "s/__AUTHOR__/$AUTHOR/g" -e "s/__ID__/$3/g" -e "s/__DB__/$DB/g" \
      -e "s/__TABLE__/${TABLE:-__TABLE__}/g" -e "s/__COLUMN__/${COLUMN:-__COLUMN__}/g" \
      -e "s/__VIEW__/${VIEW:-__VIEW__}/g" -e "s/__MV__/${MV:-__MV__}/g" \
      "$1" > "$2"
  [ -e "$2" ] && echo "created ${2#"$ROOT/"}"
}

ensure_database() { # create liquibase/<db>/ + register it in the master changelog
  local created=0
  if [ ! -f "$LB/changelog.yaml" ]; then
    mkdir -p "$LB"
    sed -e "s/__DB__/$DB/g" "$TD/changelog.yaml" > "$LB/changelog.yaml"
    sed -e "s/__DB__/$DB/g" -e "s/__AUTHOR__/$AUTHOR/g" "$TD/database.sql" > "$LB/database.sql"
    created=1
  fi
  for sub in tables views materialized-views scripts; do
    mkdir -p "$LB/$sub"
    [ -n "$(ls -A "$LB/$sub")" ] || touch "$LB/$sub/.gitkeep"
  done
  if ! grep -qE "^[[:space:]]*file: $DB/changelog\.yaml[[:space:]]*$" "$MASTER"; then
    printf '  - include:\n      file: %s/changelog.yaml\n      relativeToChangelogFile: true\n' "$DB" >> "$MASTER"
    created=1
  fi
  if [ "$created" = 1 ]; then
    echo "NEW DATABASE '$DB':"
    echo "  created liquibase/$DB/ (changelog.yaml, database.sql, tables/ views/ materialized-views/ scripts/)"
    echo "  added   $DB/changelog.yaml at the END of liquibase/changelog-master.yaml"
    echo "          -> move it up if '$DB' must exist before a database listed above it"
    echo "  TODO    grant the liquibase user on $DB.* (ops/clickhouse/001-bootstrap-database-and-users.sql)"
  fi
}

refuse_existing() { [ -e "$1" ] && { echo "exists: $1" >&2; exit 1; } || true; }

ensure_database

case "$kind" in
  database) ;;  # folder only
  table)
    TABLE="$name"; dir="$LB/tables/$name"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-create.sql"; refuse_existing "$f"
    render "$T/create-table.sql" "$f" "$TODAY-$seq-$DB-create-$name" ;;
  column)
    TABLE="$name"; COLUMN="${extra:?column name}"; dir="$LB/tables/$name"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-add-$COLUMN.sql"; refuse_existing "$f"
    render "$T/add-column.sql" "$f" "$TODAY-$seq-$DB-$name-add-$COLUMN" ;;
  view)
    VIEW="$name"; TABLE="${extra:-__TABLE__}"; f="$LB/views/$name.sql"; refuse_existing "$f"
    render "$T/view.sql" "$f" "$DB-$name" ;;
  mv)
    MV="$name"; TABLE="${extra:-__TABLE__}"; dir="$LB/materialized-views"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-$name.sql"; refuse_existing "$f"
    render "$T/materialized-view.sql" "$f" "$TODAY-$seq-$DB-$name" ;;
  script)
    TABLE="${extra:-__TABLE__}"; dir="$LB/scripts/$(date +%Y)"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-$name.sql"; refuse_existing "$f"
    render "$T/data-script.sql" "$f" "$TODAY-$seq-$DB-$name" ;;
  *) echo "unknown kind: $kind" >&2; exit 1 ;;
esac
