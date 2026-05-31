#!/bin/bash
# UserPromptSubmit hook: напоминание о pipeline
# Инжектирует контекст в каждый промпт пользователя

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
