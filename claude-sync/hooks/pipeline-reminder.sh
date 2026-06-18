#!/bin/bash
# UserPromptSubmit hook: pipeline reminder + autonomous halt-resume.
# Injects context into every user prompt.

INPUT=$(cat 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
# The user re-engaged: clear a standing AUTONOMOUS-HALT so the driver loop and the
# watchdog resume work. (A halt pauses the machinery; a new user message lifts it.)
if [ -n "$CWD" ] && [ -f "$CWD/.autonomous" ] && [ -f "$CWD/.autonomous-halt" ]; then
  rm -f "$CWD/.autonomous-halt"
fi

cat <<'EOF'
<user-prompt-submit-hook>
PIPELINE REMINDER: before acting, check — is /skill-router needed for this task?
- Feature/bugfix/refactor → /skill-router is MANDATORY as the first step
- Simple question/clarification → fine without skill-router
- Questions to the user → BATCH 2-4 via AskUserQuestion, NEVER one at a time
Reply to the user in their language (Russian); think in English.
</user-prompt-submit-hook>
EOF
exit 0
