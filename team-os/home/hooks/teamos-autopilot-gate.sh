#!/usr/bin/env bash
# PreToolUse(Bash) hook: in an unattended run (TEAMOS_AUTOPILOT=1) deny irreversible/outward actions.
# Outside autopilot: no-op (interactive gates are handled by permission ask-rules).
set -u
[ "${TEAMOS_AUTOPILOT:-0}" = "1" ] || exit 0

IN="$(cat)"
CMD="$(printf '%s' "$IN" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

if printf '%s' "$CMD" | grep -qE '(vercel (deploy|--prod)|vercel deploy|fastlane|terraform (apply|destroy)|kubectl (apply|delete)|flyctl deploy|eb deploy|npm publish|yarn publish|gh pr merge|gh release|git push[^|;&]*(--force|-f( |$))|aws [a-z0-9-]+ (delete|put|create)-)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny",
    permissionDecisionReason:"Irreversible or outward actions are forbidden in an unattended run. Queue it in the project state file as awaiting the user, and carry on with other work."}}'
  exit 0
fi
exit 0
