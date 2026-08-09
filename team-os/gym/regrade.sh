#!/usr/bin/env bash
# Re-grade finished runs with the current judge, without re-running any agent.
# Usage: regrade.sh <results-dir> [<results-dir> ...]
#
# Grading is a pure function of (transcript, expectations, judge). When the judge is fixed —
# as on 2026-08-09, when tool results were missing from its digest — the honest move is to
# re-grade the transcripts that are already on disk, not to re-run the agents: re-running
# would change the thing being measured and cost 100x more.
set -uo pipefail

GYM="$(cd "$(dirname "$0")" && pwd)"

for D in "$@"; do
  D="${D%/}"
  S="$D/summary.json"
  [ -f "$S" ] || { echo "skip $D (no summary.json)" >&2; continue; }
  echo "── re-grading $(basename "$D")"
  for t in "$D"/*/transcript.jsonl; do
    [ -f "$t" ] || continue
    id="$(basename "$(dirname "$t")")"
    base="${id%-remeasured}"
    exp="$GYM/tasks/$base/expectations.md"
    [ -f "$exp" ] || continue
    out="$(dirname "$t")/grading.json"
    if bash "$GYM/judge.sh" "$t" "$exp" "$out" 2>/dev/null; then
      jr="$(jq -r '.summary.outcome_pass_rate // empty' "$out")"
      pr="$(jq -r '.summary.process_pass_rate // empty' "$out")"
      jq --arg id "$base" --argjson jr "${jr:-null}" --argjson pr "${pr:-null}" \
        '.tasks = [.tasks[] | if .id == $id then .judge_pass_rate = $jr | .process_pass_rate = $pr else . end]' \
        "$S" > "$S.tmp" && mv "$S.tmp" "$S"
      printf '   %-28s outcome=%s process=%s\n' "$base" "${jr:-n/a}" "${pr:-n/a}"
    else
      echo "   $base: judge failed, previous grading kept" >&2
    fi
  done
  jq '. + {regraded: "judge digest including tool results, 2026-08-09"}' "$S" > "$S.tmp" && mv "$S.tmp" "$S"
done
