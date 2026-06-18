#!/bin/bash
# PreToolUse hook: проверка перед git commit
# Срабатывает ТОЛЬКО для коммитов в основном рабочем каталоге
# (не для подрепозиториев типа infra/keycloak и т.д.)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Проверяем только git commit команды
if echo "$COMMAND" | grep -q "git commit"; then
  # Пропускаем коммиты в подрепозиториях (git -C ... commit)
  if echo "$COMMAND" | grep -q "git -C"; then
    exit 0
  fi
  # Пропускаем коммиты с cd в другие директории
  if echo "$COMMAND" | grep -q "^cd .*/infra/"; then
    exit 0
  fi
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "PRE-COMMIT CHECK: Убедись что verification-before-completion был выполнен перед этим коммитом. Если нет — сначала выполни verification, потом коммить."
  }
}
EOF
else
  exit 0
fi
