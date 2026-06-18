#!/usr/bin/env bash
# PostToolUse hook — CONTINUOUS autonomous heartbeat.
#
# The Stop hook only fires at a clean turn-end, so it misses long-running turns
# and crashes (rate-limit / partial-answer falls). This hook stamps a heartbeat
# on EVERY tool use of an armed autonomous session, so the watchdog can reliably
# tell "alive & working" from "dead/stalled" and resurrect by session id.
#
# Ultra-light: only acts when the project has an `.autonomous` marker.
# Heartbeat format (single line):  <epoch_seconds> <session_id>

INPUT=$(cat 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0
[ -f "$CWD/.autonomous" ] || exit 0
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
echo "$(date +%s) $SID" > "$CWD/.autonomous-heartbeat" 2>/dev/null
exit 0
