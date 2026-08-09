#!/usr/bin/env bash
# Compare config variants over gym runs. Usage: compare.sh <summary.json> [<summary.json> ...]
# With no arguments, compares the newest run of each variant found under results/.
#
# The decision rule is fixed in docs/EXPERIMENT-config-simplification.md and applied here:
# a variant wins when its OUTCOME pass-rate does not regress against the control and its token
# total is materially lower. process_pass_rate is printed but never decides.
set -uo pipefail

GYM="$(cd "$(dirname "$0")" && pwd)"
SUMS=("$@")

if [ ${#SUMS[@]} -eq 0 ]; then
  for v in $(ls -d "$GYM"/results/*/ 2>/dev/null | sed 's|.*/results/||; s|/$||' | sed 's|^[0-9]*-||' | sort -u); do
    newest="$(ls -td "$GYM"/results/*-"$v"/ 2>/dev/null | head -1)"
    [ -n "$newest" ] && [ -f "$newest/summary.json" ] && SUMS+=("$newest/summary.json")
  done
fi
[ ${#SUMS[@]} -eq 0 ] && { echo "no summaries found" >&2; exit 1; }

# per-variant totals
printf '%-12s %6s %6s %6s %9s %9s %10s %8s\n' VARIANT PASS FAIL SKIP OUTCOME PROCESS TOKENS DUR_S
for s in "${SUMS[@]}"; do
  [ -f "$s" ] || continue
  jq -r '
    (.variant // "unknown") as $v
    | [.tasks[]? | select(.status != "skip" and .status != "limit")] as $t
    | ($t | map(select(.status == "pass")) | length) as $pass
    | ($t | map(select(.status == "fail")) | length) as $fail
    | ([.tasks[]? | select(.status == "skip" or .status == "limit")] | length) as $skip
    | ([$t[] | .judge_pass_rate // empty]) as $out
    | ([$t[] | .process_pass_rate // empty]) as $pro
    | ($t | map(.budget_used // 0) | add // 0) as $tok
    | ($t | map(.dur_s // 0) | add // 0) as $dur
    | [$v, $pass, $fail, $skip,
       (if ($out|length) > 0 then (($out|add)/($out|length)*1000|round/1000|tostring) else "n/a" end),
       (if ($pro|length) > 0 then (($pro|add)/($pro|length)*1000|round/1000|tostring) else "n/a" end),
       $tok, $dur]
    | @tsv' "$s"
done | awk -F'\t' '{printf "%-12s %6s %6s %6s %9s %9s %10s %8s\n", $1,$2,$3,$4,$5,$6,$7,$8}'

echo
echo "per task (status · outcome-rate · tokens):"
{
  printf 'TASK'
  for s in "${SUMS[@]}"; do printf '\t%s' "$(jq -r '.variant // "?"' "$s")"; done
  printf '\n'
  jq -r '.tasks[].id' "${SUMS[0]}" | while read -r id; do
    printf '%s' "$id"
    for s in "${SUMS[@]}"; do
      printf '\t%s' "$(jq -r --arg id "$id" '
        (.tasks[] | select(.id == $id))
        | "\(.status)·\(.judge_pass_rate // "-")·\(if .budget_used then (.budget_used/1000|floor|tostring + "k") else "-" end)"' "$s" 2>/dev/null || echo "-")"
    done
    printf '\n'
  done
} | column -t -s$'\t'

echo
CONTROL="$(for s in "${SUMS[@]}"; do jq -r 'select(.variant == "v0-control") | input_filename' "$s" 2>/dev/null; done | head -1)"
[ -z "$CONTROL" ] && CONTROL="${SUMS[0]}"
echo "control arm: $(jq -r '.variant' "$CONTROL")"
echo "decision rule: adopt a variant only if its outcome rate >= control AND its token total is materially lower."
echo "process_pass_rate is diagnostic — it measures ritual compliance, not delivered work."
