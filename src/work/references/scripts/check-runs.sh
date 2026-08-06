#!/usr/bin/env bash
# check-runs.sh — validate the runs ledger against itself, the event spine, and git.
#
# Why this exists: appending the closed-run row is the last step of a unit and it is done by
# hand, so it is the step that gets skipped. A missing row has no symptom — the work shipped,
# the tests passed, nobody notices — and every yield number is silently computed on a short
# denominator. Runs that end badly are the ones most likely to skip their own close, which
# biases the metrics in exactly the wrong direction. A reminder cannot fix that; a check can.
#
# Project-agnostic: discovers .agent-tools/runs/ by walking up from the working directory, and
# derives work-item key prefixes (DAY-, SPEC-, LIN-, …) from the ledger's own unit values.
#
# Usage: check-runs.sh [--no-git] [--quiet] [--path <dir>] [--help]
# Exit:  0 clean (warnings allowed) · 1 errors found · 2 no runs ledger

set -euo pipefail

no_git=0
quiet=0
start_dir="$PWD"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-git) no_git=1; shift ;;
    --quiet)  quiet=1; shift ;;
    --path)   start_dir="${2:?--path needs a directory}"; shift 2 ;;
    --help|-h)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) printf 'check-runs: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

# --- locate the runs tree -----------------------------------------------------------------

runs_dir=""
dir="$(cd "$start_dir" 2>/dev/null && pwd)" || { printf 'check-runs: no such directory: %s\n' "$start_dir" >&2; exit 2; }
while [[ "$dir" != "/" ]]; do
  if [[ -f "$dir/.agent-tools/runs/ledger.yml" ]]; then runs_dir="$dir/.agent-tools/runs"; break; fi
  dir="$(dirname "$dir")"
done

if [[ -z "$runs_dir" ]]; then
  printf 'check-runs: no .agent-tools/runs/ledger.yml found from %s upward.\n' "$start_dir" >&2
  printf '            Run /work:setup to scaffold the runs tree.\n' >&2
  exit 2
fi

repo_root="$(dirname "$(dirname "$runs_dir")")"
ledger="$runs_dir/ledger.yml"
events="$runs_dir/events.ndjson"
ignore_file="$runs_dir/.check-runs-ignore"

errors=0
warnings=0
err()  { printf 'error: %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf 'warning: %s\n' "$1" >&2; warnings=$((warnings + 1)); }

is_ignored() {
  [[ -f "$ignore_file" ]] || return 1
  sed 's/#.*$//' "$ignore_file" | tr -d ' \t' | grep -qx -- "$1"
}

# --- 1. ledger schema ---------------------------------------------------------------------
#
# A deliberately narrow reader rather than a YAML library: the drift this is built to catch
# (`id:` where every other row says `run_id:`) is exactly what a real parser would accept
# silently. Rows start at two spaces, scalar fields at four; note bodies and the fidelity
# block sit deeper and are skipped.

schema_report="$(
  awk '
    /^  - [a-z_]+:/ {
      if (have_row) print_row()
      have_row = 1
      line_no   = NR
      row_key   = $0; sub(/^  - /, "", row_key); sub(/:.*$/, "", row_key)
      row_id    = $0; sub(/^  - [a-z_]+:[[:space:]]*/, "", row_id)
      has_unit = has_opened = has_closed = has_outcome = 0
      outcome = ""
      next
    }
    have_row && /^    [a-z_]+:/ {
      key = $0; sub(/^    /, "", key); sub(/:.*$/, "", key)
      val = $0; sub(/^    [a-z_]+:[[:space:]]*/, "", val)
      if (key == "unit")    has_unit = 1
      if (key == "opened")  has_opened = 1
      if (key == "closed")  has_closed = 1
      if (key == "outcome") { has_outcome = 1; outcome = val }
      if (key == "run_id")  row_id = val
    }
    END { if (have_row) print_row() }
    function print_row() {
      printf "%s\t%s\t%s\t%d%d%d%d\t%s\n", line_no, row_key, row_id, has_unit, has_opened, has_closed, has_outcome, outcome
    }
  ' "$ledger"
)"

declare -a ledger_ids=()
declare -a ledger_units=()
seen_ids=""
row_count=0

while IFS=$'\t' read -r line_no row_key row_id flags outcome; do
  [[ -z "${line_no:-}" ]] && continue
  row_count=$((row_count + 1))

  [[ "$row_key" != "run_id" ]] && err "ledger.yml:$line_no: row starts with \`$row_key:\` — every row must start with \`run_id:\`. A tool splitting the ledger on run_id silently drops this row."

  case " $seen_ids " in
    *" $row_id "*) err "ledger.yml:$line_no: duplicate run_id \`$row_id\`." ;;
    *) seen_ids="$seen_ids $row_id" ;;
  esac
  ledger_ids+=("$row_id")

  [[ "${flags:0:1}" == "0" ]] && err "ledger.yml:$line_no: \`$row_id\` is missing required field \`unit\`."
  [[ "${flags:1:1}" == "0" ]] && err "ledger.yml:$line_no: \`$row_id\` is missing required field \`opened\`."
  [[ "${flags:2:1}" == "0" ]] && err "ledger.yml:$line_no: \`$row_id\` is missing required field \`closed\`."
  [[ "${flags:3:1}" == "0" ]] && err "ledger.yml:$line_no: \`$row_id\` is missing required field \`outcome\`."

  case "${outcome%%[[:space:]]*}" in
    shipped|abandoned|blocked_out|superseded|"") ;;
    *) err "ledger.yml:$line_no: \`$row_id\` has outcome \`$outcome\` — expected shipped, abandoned, blocked_out or superseded." ;;
  esac
done <<< "$schema_report"

# Units, for the git cross-check. Split on + / and whitespace so PROJ-1+PROJ-2 counts as both.
# A shorthand pair like PROJ-10/11 leaves a bare number, which would never match a commit key;
# re-attach the most recent prefix so the second half counts too.
while IFS= read -r unit; do
  [[ -z "$unit" ]] && continue
  ledger_units+=("$unit")
done < <(
  awk '
    /^    unit:/ {
      sub(/^    unit:[[:space:]]*/, "")
      n = split($0, parts, /[+\/[:space:]]+/)
      prefix = ""
      for (i = 1; i <= n; i++) {
        p = parts[i]
        if (p == "") continue
        if (p ~ /^[A-Za-z]+-[0-9]+$/) { prefix = p; sub(/-[0-9]+$/, "", prefix); print p }
        else if (p ~ /^[0-9]+$/ && prefix != "") print prefix "-" p
        else print p
      }
    }
  ' "$ledger" | sed '/^$/d'
)

# --- 2. events that finished but never got a row -------------------------------------------
#
# The spine is append-only NDJSON. Any run reaching a terminal phase owes a ledger row; a run
# still mid-flight does not.

if [[ -f "$events" ]]; then
  while IFS=$'\t' read -r run_id unit phases; do
    [[ -z "${run_id:-}" ]] && continue
    case " ${ledger_ids[*]} " in *" $run_id "*) continue ;; esac
    [[ "$phases" != *compound* && "$phases" != *integrate* ]] && continue
    is_ignored "$run_id" && continue
    err "$run_id (${unit:-unknown unit}) reached a terminal phase in events.ndjson but has no ledger row. Append it per the close recipe, or add the run_id to .agent-tools/runs/.check-runs-ignore with a reason."
  done < <(
    awk '
      {
        run = ""; unit = ""; phase = ""
        if (match($0, /"run_id"[[:space:]]*:[[:space:]]*"[^"]*"/)) { run = substr($0, RSTART, RLENGTH); sub(/.*"run_id"[[:space:]]*:[[:space:]]*"/, "", run); sub(/"$/, "", run) }
        if (match($0, /"unit"[[:space:]]*:[[:space:]]*"[^"]*"/))   { unit = substr($0, RSTART, RLENGTH); sub(/.*"unit"[[:space:]]*:[[:space:]]*"/, "", unit); sub(/"$/, "", unit) }
        if (match($0, /"phase"[[:space:]]*:[[:space:]]*"[^"]*"/))  { phase = substr($0, RSTART, RLENGTH); sub(/.*"phase"[[:space:]]*:[[:space:]]*"/, "", phase); sub(/"$/, "", phase) }
        if (run == "") next
        if (unit != "") units[run] = unit
        if (phase != "") phases[run] = phases[run] "," phase
      }
      END { for (r in phases) printf "%s\t%s\t%s\n", r, units[r], phases[r] }
    ' "$events"
  )
fi

# --- 3. git cross-check (warning only) ------------------------------------------------------
#
# Not every work-item key in a commit subject is a claimable unit — epics, follow-on commits
# filed under a parent key, and non-code work all appear here legitimately. Warning, never error.
#
# Bounded to the ledger's own era: commits predating the first row cannot have one, and scanning
# further back reports the whole history of the repo as missing, burying the real signal.

if [[ "$no_git" -eq 0 ]] && command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
  since="$(awk '/^    opened:/ { sub(/^    opened:[[:space:]]*/, ""); if ($0 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) print }' "$ledger" | sort | head -1)"

  if [[ -z "$since" ]]; then
    warn "No dated ledger rows — skipping the git cross-check."
  else
    # Key prefixes come from the ledger's own units, so this needs no per-project configuration.
    prefixes="$(printf '%s\n' "${ledger_units[@]:-}" | grep -oE '^[A-Za-z]+-[0-9]+$' | sed 's/-[0-9]*$//' | sort -u || true)"

    if [[ -z "$prefixes" ]]; then
      warn "No ticket-shaped units in the ledger — skipping the git cross-check."
    else
      pattern="$(printf '%s\n' $prefixes | paste -sd'|' -)"
      subjects="$(git -C "$repo_root" log --since="$since" --format=%s 2>/dev/null || true)"

      while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        case " ${ledger_units[*]} " in *" $key "*) continue ;; esac
        is_ignored "$key" && continue
        count="$(printf '%s\n' "$subjects" | grep -coE "\b${key}\b" || true)"
        warn "$key has $count commit(s) since $since but no ledger row. Reconstruct the row if it was a claimable unit; add it to .check-runs-ignore if it is an epic or follow-on work."
      done < <(printf '%s\n' "$subjects" | grep -oE "\b(${pattern})-[0-9]+\b" | sort -u)
    fi
  fi
fi

# --- report ---------------------------------------------------------------------------------

if [[ "$errors" -gt 0 ]]; then
  printf '\nRuns ledger FAILED — %d error(s), %d warning(s), %d rows.\n' "$errors" "$warnings" "$row_count" >&2
  exit 1
fi

[[ "$quiet" -eq 1 ]] || printf 'Runs ledger OK — %d rows, %d warning(s).\n' "$row_count" "$warnings"
exit 0
