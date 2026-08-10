#!/usr/bin/env bash
# PostToolUse hook: record that the agent actually LOOKED at something before it is allowed to
# mark work as passing. Half of the "default-FAIL contract" — the other half is teamos-verify-gate.sh.
#
# Why this exists: prompts asking an agent not to claim success prematurely do not reliably work.
# Anthropic's long-running-agents reference calls "asking nicely in prompts to not mark things done"
# an anti-pattern and makes the constraint structural instead. This is the structural version.
#
# Counts as evidence:
#   - reading a file that holds observed output: anything under .artifacts/ or screenshots/,
#     any *.log, *.png/jpg, test-output/result files
#   - running a command that produces observed output: a test runner, a build, or a diff
# Fails open on every doubt.
set -u

IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
TOOL="$(printf '%s' "$IN" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

EVIDENCE=""
case "$TOOL" in
  Read|NotebookRead)
    P="$(printf '%s' "$IN" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
    case "$P" in
      *.log|*.png|*.jpg|*.jpeg|*.webp|*/.artifacts/*|*/screenshots/*|*test-results*|*coverage*)
        EVIDENCE="read:$P" ;;
    esac ;;
  Bash)
    C="$(printf '%s' "$IN" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    if printf '%s' "$C" | grep -qE '(^|[[:space:];&|])(npm (run )?(test|build)|pnpm (test|build)|yarn (test|build)|npx (jest|vitest|playwright)|jest|vitest|pytest|python3? -m (pytest|unittest)|go test|cargo (test|build)|swift test|xcodebuild|node --test|git diff)([[:space:]]|$)'; then
      # An empty stdout is not evidence of anything having run.
      OUT="$(printf '%s' "$IN" | jq -r '.tool_response.stdout // .tool_response // empty' 2>/dev/null | head -c 200)"
      [ -n "$OUT" ] && EVIDENCE="ran:$(printf '%s' "$C" | head -c 80)"
    fi ;;
esac

[ -z "$EVIDENCE" ] && exit 0

mkdir -p .artifacts 2>/dev/null || exit 0
printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$EVIDENCE" >> .artifacts/.evidence 2>/dev/null || true
exit 0
