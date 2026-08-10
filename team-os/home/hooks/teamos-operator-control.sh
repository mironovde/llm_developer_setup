#!/usr/bin/env bash
# PreToolUse hook: two operator controls for unattended runs, in one hook so there is one place to
# look when a run stops behaving.
#
#   AGENT_STOP  — while this file exists at the repo root, every tool call is denied. A kill switch
#                 you can hit from another terminal without killing the process, so the agent stops
#                 cleanly and its state stays on disk.
#   STEER.md    — mid-run redirection. Its contents are surfaced to the agent once, then the file is
#                 cleared, so you can change direction without restarting the session.
#
# Fails open on every doubt: a control that jams a run is worse than no control.
set -u

IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$CWD"

if [ -f "$ROOT/AGENT_STOP" ]; then
  REASON="$(head -c 400 "$ROOT/AGENT_STOP" 2>/dev/null)"
  jq -n --arg r "${REASON:-no reason given}" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny",
    permissionDecisionReason:("Halted by the operator: AGENT_STOP is present at the repo root. Reason: " + $r + ". Write down where you got to, then stop. Do not delete AGENT_STOP — only the operator removes it.")}}'
  exit 0
fi

if [ -s "$ROOT/STEER.md" ]; then
  MSG="$(head -c 2000 "$ROOT/STEER.md" 2>/dev/null)"
  : > "$ROOT/STEER.md"
  jq -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"ask",
    permissionDecisionReason:("New direction from the operator, delivered mid-run:\n\n" + $m + "\n\nTake this into account before continuing.")}}'
  exit 0
fi

exit 0
