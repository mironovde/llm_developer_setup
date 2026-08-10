#!/usr/bin/env bash
# PostToolUse(Bash) hook: replace noisy test/build output with a digest.
# Official pattern: hookSpecificOutput.updatedToolOutput (docs/costs). Fail-open: on any doubt, exit 0 silently.
set -u
IN="$(cat)"

CMD="$(printf '%s' "$IN" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

# Only known chatty runners/builds; leave everything else untouched.
if ! printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|])(npm (test|run [a-z:]*test[a-z:]*|run build)|npx (jest|vitest|playwright|tsc)|pnpm (test|build)|yarn (test|build)|jest|vitest|pytest|python3? -m (pytest|unittest)|go test|cargo (test|build)|xcodebuild|swift (test|build)|tsc|next build|vite build)([[:space:]]|$)'; then
  exit 0
fi

OUT="$(printf '%s' "$IN" | jq -r '.tool_response
  | if type=="object" then ((.stdout // "") + (if (.stderr // "") != "" then "\n--stderr--\n" + .stderr else "" end))
    elif type=="string" then .
    else tostring end' 2>/dev/null)"
[ -z "$OUT" ] && exit 0

LEN=${#OUT}
# Small outputs pass through untouched.
[ "$LEN" -le 3500 ] && exit 0

TOTAL_LINES=$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')
HEAD="$(printf '%s\n' "$OUT" | head -3)"
SIGNAL="$(printf '%s\n' "$OUT" | grep -inE 'fail|error|✗|✖|FAILED|PASSED|passing|failing|Tests?:|Test Suites?:|assert|BUILD (SUCCEEDED|FAILED)|warning:|exit code' | head -60)"
TAIL="$(printf '%s\n' "$OUT" | tail -15)"

DIGEST="$(printf '[teamos filter] %s chars / %s lines of output condensed. Signal lines (grep fail/error/pass):\n%s\n\n--- first 3 lines ---\n%s\n\n--- last 15 lines ---\n%s\n\n[Full output was NOT saved by this hook — if the verification protocol needs the full log, re-run redirecting to team/artifacts/.]' \
  "$LEN" "$TOTAL_LINES" "${SIGNAL:-<none matched>}" "$HEAD" "$TAIL")"

jq -n --arg d "$DIGEST" '{hookSpecificOutput:{hookEventName:"PostToolUse", updatedToolOutput:$d}}'
exit 0
