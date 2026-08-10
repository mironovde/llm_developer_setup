#!/usr/bin/env bash
# PreToolUse hook: refuse to let the agent mark a criterion as passing unless it has just looked at
# real output. The enforcing half of the default-FAIL contract (see teamos-evidence-track.sh).
#
# The contract file is `test-results.json` at the repo root, and it only exists when a project opts
# in — no file, no gate, so this is inert everywhere else. Every criterion starts false; flipping one
# to true consumes one piece of evidence, so a single test run cannot bless ten features.
#
# Deliberately NOT a general "did you verify" nag: it fires on exactly one file, which is why it can
# be strict without getting in the way. Fails open on every doubt.
set -u

IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
TOOL="$(printf '%s' "$IN" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -z "$CWD" ] && exit 0

case "$TOOL" in Write|Edit|MultiEdit|NotebookEdit) ;; *) exit 0 ;; esac

P="$(printf '%s' "$IN" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
case "$P" in
  */test-results.json|test-results.json) ;;
  *) exit 0 ;;
esac

cd "$CWD" 2>/dev/null || exit 0
[ -f "$P" ] || [ -f test-results.json ] || exit 0

# Does this edit actually claim a pass? Reading or reformatting the file is not gated.
PAYLOAD="$(printf '%s' "$IN" | jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits // [] | map(.new_string) | join(" "))] | map(select(. != null)) | join(" ")' 2>/dev/null)"
printf '%s' "$PAYLOAD" | grep -qE '"(passes|passed|ok)"[[:space:]]*:[[:space:]]*true|"status"[[:space:]]*:[[:space:]]*"(pass|passed|done)"' || exit 0

EV=".artifacts/.evidence"
COUNT=0
[ -f "$EV" ] && COUNT="$(wc -l < "$EV" | tr -d ' ')"

if [ "${COUNT:-0}" -lt 1 ]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny",
    permissionDecisionReason:"Marking a criterion as passing requires observed output first. Nothing has been read or run since the last time a criterion was marked. Run the check that proves this specific criterion — or open the log, screenshot, or test output that shows it — and then write the result. Every criterion in test-results.json starts false on purpose."}}'
  exit 0
fi

# Consume the evidence: one observation blesses one write, not the whole file.
: > "$EV"
exit 0
