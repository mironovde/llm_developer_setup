#!/usr/bin/env bash
# Head-to-head config experiment: run the same task set against every variant, then compare.
# Usage: run-experiment.sh [task-ids... | all]   (default: all)
#
# Arms run sequentially on purpose — parallel headless agents on one machine distort both
# wall-clock and any token-per-second reading, and the fixtures bind ports.
set -uo pipefail

GYM="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$GYM")"
TASKS=("$@")
[ ${#TASKS[@]} -eq 0 ] && TASKS=(all)

ARMS=(
  "$ROOT/home"
  "$ROOT/variants/v1-core"
  "$ROOT/variants/v2-bare"
)

SUMMARIES=()
for arm in "${ARMS[@]}"; do
  name="$(jq -r '.name // "?"' "$arm/variant.json" 2>/dev/null || basename "$arm")"
  echo
  echo "================= ARM: $name ================="
  bash "$GYM/run.sh" "${TASKS[@]}" --config "$arm"
  newest="$(ls -td "$GYM"/results/*-"$name"/ 2>/dev/null | head -1)"
  [ -n "$newest" ] && SUMMARIES+=("$newest/summary.json")
done

echo
echo "================= COMPARISON ================="
bash "$GYM/compare.sh" "${SUMMARIES[@]}"
