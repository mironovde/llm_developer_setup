#!/usr/bin/env bash
# Team OS Gym runner — executes golden tasks headless against the CURRENT team-os/home config.
# Hermetic per ADR-003: --setting-sources project --strict-mcp-config; Team OS config is installed
# into each fixture at project level, so the user's real ~/.claude content never loads.
#
# Usage: run.sh [smoke|all|<task-id>...] [--config DIR] [--baseline] [--runs N] [--no-judge] [--keep-workspace]
#   smoke = 001 + 003 (fast sanity); all = every task; task ids like 001 or 001-t0-typo
#   --config DIR = config variant to test (default: team-os/home). DIR is shaped like home/
#     and may carry variant.json: {name, claude_md, copy[], seed_team, settings}.
#     This is what makes the gym able to COMPARE configs instead of only testing the current one.
set -uo pipefail

GYM="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$GYM")"
. "$ROOT/scripts/teamos-lib.sh"

SELECT=()
BASELINE=0
RUNS=1
JUDGE=1
KEEP=0
DRY=0
CONFIG_ROOT="$ROOT/home"
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG_ROOT="$(cd "${2:?--config needs a dir}" && pwd)"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --baseline) BASELINE=1; shift ;;
    --runs) RUNS="${2:?}"; shift 2 ;;
    --no-judge) JUDGE=0; shift ;;
    --keep-workspace) KEEP=1; shift ;;
    smoke|all) SELECT+=("$1"); shift ;;
    *) SELECT+=("$1"); shift ;;
  esac
done
[ ${#SELECT[@]} -eq 0 ] && SELECT=(smoke)

# ── config variant under test ────────────────────────────────────────────────
[ -d "$CONFIG_ROOT" ] || { echo "config dir not found: $CONFIG_ROOT" >&2; exit 1; }
VARIANT_JSON="$CONFIG_ROOT/variant.json"
vget() { # $1=jq path, $2=default
  [ -f "$VARIANT_JSON" ] && jq -r "$1 // empty" "$VARIANT_JSON" 2>/dev/null | grep . || printf '%s' "$2"
}
VARIANT="$(vget '.name' "$(basename "$CONFIG_ROOT")")"
V_CLAUDE_MD="$(vget '.claude_md' "CLAUDE.md")"
V_SEED_TEAM="$(vget '.seed_team' "true")"
V_SETTINGS="$(vget '.settings' "$GYM/gym-settings.json")"
case "$V_SETTINGS" in /*) ;; *) V_SETTINGS="$CONFIG_ROOT/$V_SETTINGS" ;; esac
[ -f "$V_SETTINGS" ] || V_SETTINGS="$GYM/gym-settings.json"
if [ -f "$VARIANT_JSON" ] && jq -e '.copy' "$VARIANT_JSON" >/dev/null 2>&1; then
  V_COPY="$(jq -r '.copy[]' "$VARIANT_JSON" | tr '\n' ' ')"
else
  V_COPY="agents skills hooks"
fi

TASKS=()
resolve_tasks() {
  case "${SELECT[0]}" in
    all) for d in "$GYM"/tasks/*/; do TASKS+=("$(basename "$d")"); done ;;
    smoke) TASKS=(001-t0-typo 003-t1-js-bugfix) ;;
    *)
      for s in "${SELECT[@]}"; do
        local hit=""
        for d in "$GYM"/tasks/*/; do
          b="$(basename "$d")"
          case "$b" in "$s"|"$s"-*) hit="$b"; break ;; esac
        done
        [ -n "$hit" ] && TASKS+=("$hit") || { echo "unknown task: $s" >&2; exit 1; }
      done ;;
  esac
}
resolve_tasks

RUN_ID="$(date -u +%Y%m%d-%H%M%S)"
OUT="$GYM/results/$RUN_ID-$VARIANT"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.json"
jq -n --arg r "$RUN_ID" --arg v "$VARIANT" --arg c "$CONFIG_ROOT" \
  '{run_id: $r, variant: $v, config_root: $c, tasks: []}' > "$SUMMARY"

capability_ok() { # $1=requirement → 0/1
  case "$1" in
    node) command -v node >/dev/null 2>&1 ;;
    python3) command -v python3 >/dev/null 2>&1 ;;
    xcodebuild) xcodebuild -version >/dev/null 2>&1 ;;
    chrome) [ -d "/Applications/Google Chrome.app" ] || command -v google-chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

add_summary() { # id status check judge_rate budget_used budget_limit tokens_out dur note process_rate
  local tmp
  tmp="$(mktemp)"
  jq --arg id "$1" --arg st "$2" --arg ck "$3" --arg jr "$4" --arg bu "$5" --arg bl "$6" --arg to "$7" --arg du "$8" --arg no "$9" --arg pr "${10:-}" '
    .tasks += [{id: $id, status: $st, check: $ck,
      judge_pass_rate: (if $jr == "" then null else ($jr|tonumber) end),
      process_pass_rate: (if $pr == "" then null else ($pr|tonumber) end),
      budget_used: (if $bu == "" then null else ($bu|tonumber) end),
      budget_limit: (if $bl == "" then null else ($bl|tonumber) end),
      out_tokens: (if $to == "" then null else ($to|tonumber) end),
      dur_s: (if $du == "" then null else ($du|tonumber) end),
      note: (if $no == "" then null else $no end)}]' "$SUMMARY" > "$tmp" && mv "$tmp" "$SUMMARY"
}

run_task_once() { # $1=task_name $2=attempt → sets GLOBALS: T_STATUS T_CHECK T_JR T_BU T_TOK T_DUR T_NOTE
  local task="$1" attempt="$2"
  local tdir="$GYM/tasks/$task"
  local meta="$tdir/meta.json"
  local rundir="$OUT/$task${attempt:+-r$attempt}"
  mkdir -p "$rundir"

  local tier budget timeout browser
  tier="$(jq -r '.tier // "T1"' "$meta")"
  budget="$(jq -r '.budget // 150000' "$meta")"
  timeout="$(jq -r '.timeout // 900' "$meta")"
  browser="$(jq -r '.browser // false' "$meta")"

  # capability gate
  local req missing=""
  for req in $(jq -r '(.requires // [])[]' "$meta"); do
    capability_ok "$req" || missing="$missing $req"
  done
  if [ -n "$missing" ]; then
    T_STATUS="skip"; T_CHECK="skip"; T_JR=""; T_BU=""; T_TOK=""; T_DUR=""; T_NOTE="missing capability:$missing"
    echo "[$task] SKIP (missing:$missing)"
    return 0
  fi

  # workspace: fixture + the config variant under test at project level + optional team state
  local ws
  ws="$(mktemp -d "${TMPDIR:-/tmp}/gym-$task.XXXXXX")"
  cp -R "$tdir/fixture/." "$ws/"
  mkdir -p "$ws/.claude"
  local sub
  for sub in $V_COPY; do
    case "$sub" in
      hooks) [ -d "$CONFIG_ROOT/hooks" ] || continue
             mkdir -p "$ws/.claude/hooks"
             cp "$CONFIG_ROOT/hooks/"*.sh "$ws/.claude/hooks/" 2>/dev/null || true ;;
      *)     [ -d "$CONFIG_ROOT/$sub" ] && cp -R "$CONFIG_ROOT/$sub" "$ws/.claude/$sub" ;;
    esac
  done
  # project CLAUDE.md = variant's global content (+ fixture's own project notes appended)
  if [ -f "$CONFIG_ROOT/$V_CLAUDE_MD" ]; then
    if [ -f "$ws/CLAUDE.md" ]; then
      cat "$CONFIG_ROOT/$V_CLAUDE_MD" > "$ws/CLAUDE.md.variant"
      printf '\n\n---\n\n' >> "$ws/CLAUDE.md.variant"
      cat "$ws/CLAUDE.md" >> "$ws/CLAUDE.md.variant"
      mv "$ws/CLAUDE.md.variant" "$ws/CLAUDE.md"
    else
      cp "$CONFIG_ROOT/$V_CLAUDE_MD" "$ws/CLAUDE.md"
    fi
  fi
  if [ "$V_SEED_TEAM" = "true" ] && [ ! -d "$ws/team" ]; then
    cp -R "$ROOT/project-template/team" "$ws/team"
  fi
  ( cd "$ws" && git init -q && git add -A && git -c user.email=gym@teamos -c user.name=gym commit -qm "fixture init" )

  # --dry-run: verify what the variant actually puts in front of the model, spend no tokens
  if [ "$DRY" -eq 1 ]; then
    echo "[$task] DRY workspace for variant '$VARIANT' ($CONFIG_ROOT):"
    ( cd "$ws" && find . -path ./.git -prune -o -type f -print | sed 's|^\./|  |' | sort | head -40 )
    echo "  CLAUDE.md: $( [ -f "$ws/CLAUDE.md" ] && wc -l < "$ws/CLAUDE.md" | tr -d ' ' || echo 0) lines"
    echo "  team/ seeded: $( [ -d "$ws/team" ] && echo yes || echo no)"
    T_STATUS="skip"; T_CHECK="skip"; T_JR=""; T_BU=""; T_TOK=""; T_DUR=0; T_NOTE="dry-run"
    [ "$KEEP" -eq 0 ] && rm -rf "$ws"
    return 0
  fi

  local mcp_args=()
  [ "$browser" = "true" ] && mcp_args=(--mcp-config "$GYM/mcp-chrome.json")

  echo "[$task] running (tier=$tier budget=$budget timeout=${timeout}s browser=$browser)"
  local t0 t1
  t0="$(date +%s)"
  set +e
  ( cd "$ws" && run_with_timeout "$timeout" \
      claude -p "$(cat "$tdir/prompt.md")" \
        --setting-sources project \
        --settings "$V_SETTINGS" \
        --strict-mcp-config "${mcp_args[@]}" \
        --permission-mode acceptEdits \
        --output-format stream-json --verbose \
        < /dev/null > "$rundir/transcript.jsonl" 2> "$rundir/stderr.log" )
  local rc=$?
  set -e
  t1="$(date +%s)"
  T_DUR=$((t1 - t0))

  # kill any fixture server the agent left behind
  pkill -f "gym-fixture" 2>/dev/null || true

  local result
  result="$(extract_result_json "$rundir/transcript.jsonl")"
  append_metrics "$OUT/metrics.jsonl" "$result" "gym:$task" "$tier" "gym:$VARIANT" "rc=$rc"

  if detect_limit "$rundir/transcript.jsonl" >/dev/null; then
    T_STATUS="limit"; T_CHECK="skip"; T_JR=""; T_BU=""; T_TOK=""; T_NOTE="usage limit hit mid-run"
    echo "[$task] LIMIT hit — rerun after the window resets"
    [ "$KEEP" -eq 0 ] && rm -rf "$ws"
    return 0
  fi

  T_BU="$(budget_used "$result")"
  T_TOK="$(printf '%s' "$result" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo 0)"

  # deterministic gate
  set +e
  ( cd "$ws" && WORKSPACE="$ws" TRANSCRIPT="$rundir/transcript.jsonl" RESULT_JSON="$result" \
      BUDGET_USED="$T_BU" BUDGET_LIMIT="$budget" bash "$tdir/check.sh" ) > "$rundir/check.log" 2>&1
  local ck=$?
  set -e
  if [ "$ck" -eq 0 ] && [ "${T_BU:-0}" -le "$budget" ]; then
    T_CHECK="pass"
  elif [ "$ck" -eq 0 ]; then
    T_CHECK="fail"; echo "budget exceeded: $T_BU > $budget" >> "$rundir/check.log"
  else
    T_CHECK="fail"
  fi

  # judge
  T_JR=""; T_PR=""
  if [ "$JUDGE" -eq 1 ] && [ -f "$tdir/expectations.md" ]; then
    bash "$GYM/judge.sh" "$rundir/transcript.jsonl" "$tdir/expectations.md" "$rundir/grading.json" || true
    if [ -f "$rundir/grading.json" ]; then
      # judge_pass_rate = OUTCOME rate: the only judge number config adoption may depend on.
      T_JR="$(jq -r '.summary.outcome_pass_rate // .summary.pass_rate // empty' "$rundir/grading.json" 2>/dev/null)"
      T_PR="$(jq -r '.summary.process_pass_rate // empty' "$rundir/grading.json" 2>/dev/null)"
    fi
  fi

  if [ "$T_CHECK" = "pass" ]; then T_STATUS="pass"; else T_STATUS="fail"; fi
  T_NOTE=""
  echo "[$task] $T_STATUS (check=$T_CHECK judge=${T_JR:-n/a} budget=$T_BU/$budget dur=${T_DUR}s) → $rundir"
  [ "$KEEP" -eq 0 ] && rm -rf "$ws"
  return 0
}

OVERALL_PASS=0; OVERALL_FAIL=0; OVERALL_SKIP=0
for task in "${TASKS[@]}"; do
  PASSK="$(jq -r '.pass_k // 1' "$GYM/tasks/$task/meta.json" 2>/dev/null || echo 1)"
  N=$RUNS
  [ "$PASSK" -gt "$N" ] && N=$PASSK
  FINAL="pass"; CHECKS=""; JRS=""; PRS=""; BUS=""; TOKS=""; DURS=""; NOTE=""
  for a in $(seq 1 "$N"); do
    run_task_once "$task" "$([ "$N" -gt 1 ] && echo "$a" || echo "")"
    CHECKS="$T_CHECK"; JRS="$T_JR"; PRS="${T_PR:-}"; BUS="$T_BU"; TOKS="$T_TOK"; DURS="$T_DUR"; NOTE="$T_NOTE"
    if [ "$T_STATUS" = "skip" ] || [ "$T_STATUS" = "limit" ]; then FINAL="$T_STATUS"; break; fi
    if [ "$T_STATUS" = "fail" ]; then FINAL="fail"; break; fi   # pass^k: first fail kills
  done
  case "$FINAL" in
    pass) OVERALL_PASS=$((OVERALL_PASS+1)) ;;
    fail) OVERALL_FAIL=$((OVERALL_FAIL+1)) ;;
    *) OVERALL_SKIP=$((OVERALL_SKIP+1)) ;;
  esac
  add_summary "$task" "$FINAL" "$CHECKS" "$JRS" "$BUS" "$([ -f "$GYM/tasks/$task/meta.json" ] && jq -r '.budget // 150000' "$GYM/tasks/$task/meta.json")" "$TOKS" "$DURS" "$NOTE" "$PRS"
done

TMP="$(mktemp)"
jq --arg p "$OVERALL_PASS" --arg f "$OVERALL_FAIL" --arg s "$OVERALL_SKIP" \
  '.totals = {pass: ($p|tonumber), fail: ($f|tonumber), skip: ($s|tonumber)}' "$SUMMARY" > "$TMP" && mv "$TMP" "$SUMMARY"

echo
echo "== gym $RUN_ID [$VARIANT]: pass=$OVERALL_PASS fail=$OVERALL_FAIL skip=$OVERALL_SKIP =="
jq -r '.tasks[] | "\(.id): \(.status) (check=\(.check) outcome=\(.judge_pass_rate // "n/a") process=\(.process_pass_rate // "n/a") budget=\(.budget_used // "?")/\(.budget_limit // "?"))"' "$SUMMARY"
TOTAL_BUDGET=$(jq -r '[.tasks[].budget_used // 0] | add' "$SUMMARY")
echo "total tokens: $TOTAL_BUDGET"

if [ "$DRY" -eq 1 ]; then rm -rf "$OUT"; echo "(dry-run: no results kept)"; exit 0; fi

if [ "$BASELINE" -eq 1 ]; then
  cp "$SUMMARY" "$GYM/results/baseline.json"
  echo "baseline updated → gym/results/baseline.json"
fi
[ "$OVERALL_FAIL" -eq 0 ]
