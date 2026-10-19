#!/usr/bin/env bash
# Create a new changeset file from a template with the right name and id.
#
#   bin/new-changeset.sh table   <table>                    # CREATE TABLE
#   bin/new-changeset.sh column  <table> <column>           # ADD COLUMN
#   bin/new-changeset.sh view    <view>  [<source_table>]   # runOnChange view (one file per view)
#   bin/new-changeset.sh mv      <mv>    [<source_table>]   # materialized view
#   bin/new-changeset.sh script  <slug>  [<table>]          # one-off data script
#
# AUTHOR defaults to `git config user.email` local part. Edit the generated file
# (types, columns, SQL) before opening the PR.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/templates/changesets"
LB="$ROOT/liquibase"
kind="${1:?kind: table|column|view|mv|script}"; name="${2:?name}"; extra="${3:-}"
AUTHOR="${AUTHOR:-$(git -C "$ROOT" config user.email 2>/dev/null | cut -d@ -f1)}"
AUTHOR="${AUTHOR:-unknown}"
TODAY="$(date +%F)"

next_seq() { # next NNN for today within a directory
  local dir="$1" n
  n=$(ls "$dir" 2>/dev/null | grep -c "^$TODAY-" || true)
  printf '%03d' $((n + 1))
}

render() { # template out_file id
  sed -e "s/__AUTHOR__/$AUTHOR/g" -e "s/__ID__/$3/g" \
      -e "s/__TABLE__/${TABLE:-__TABLE__}/g" -e "s/__COLUMN__/${COLUMN:-__COLUMN__}/g" \
      -e "s/__VIEW__/${VIEW:-__VIEW__}/g" -e "s/__MV__/${MV:-__MV__}/g" \
      "$1" > "$2"
  [ -e "$2" ] && echo "created ${2#"$ROOT/"}"
}

refuse_existing() { [ -e "$1" ] && { echo "exists: $1" >&2; exit 1; } || true; }

case "$kind" in
  table)
    TABLE="$name"; dir="$LB/tables/$name"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-create.sql"; refuse_existing "$f"
    render "$T/create-table.sql" "$f" "$TODAY-$seq-create-$name" ;;
  column)
    TABLE="$name"; COLUMN="${extra:?column name}"; dir="$LB/tables/$name"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-add-$COLUMN.sql"; refuse_existing "$f"
    render "$T/add-column.sql" "$f" "$TODAY-$seq-$name-add-$COLUMN" ;;
  view)
    VIEW="$name"; TABLE="${extra:-__TABLE__}"; f="$LB/views/$name.sql"; refuse_existing "$f"
    render "$T/view.sql" "$f" "$name" ;;
  mv)
    MV="$name"; TABLE="${extra:-__TABLE__}"; dir="$LB/materialized-views"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-$name.sql"; refuse_existing "$f"
    render "$T/materialized-view.sql" "$f" "$TODAY-$seq-$name" ;;
  script)
    TABLE="${extra:-__TABLE__}"; dir="$LB/scripts/$(date +%Y)"; mkdir -p "$dir"
    seq=$(next_seq "$dir"); f="$dir/$TODAY-$seq-$name.sql"; refuse_existing "$f"
    render "$T/data-script.sql" "$f" "$TODAY-$seq-$name" ;;
  *) echo "unknown kind: $kind" >&2; exit 1 ;;
esac
