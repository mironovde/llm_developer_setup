#!/bin/bash
# PreToolUse hook: проверка юрдокументов перед деплоем
# Срабатывает на deploy/build команды, проверяет наличие и заполненность /legal/

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Паттерны deploy/build команд
IS_DEPLOY=false
for pattern in "vercel deploy" "vercel --prod" "npm run build" "npm run deploy" "docker build" "docker compose up" "docker-compose up" "next build" "vite build" "gh release"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    IS_DEPLOY=true
    break
  fi
done

if [ "$IS_DEPLOY" = false ]; then
  exit 0
fi

# Определяем рабочую директорию проекта
WORK_DIR=$(echo "$INPUT" | jq -r '.tool_input.working_directory // empty')
if [ -z "$WORK_DIR" ]; then
  WORK_DIR="$PWD"
fi

LEGAL_DIR="$WORK_DIR/legal"
WARNINGS=""

# Проверка 1: есть ли папка /legal/ вообще
if [ ! -d "$LEGAL_DIR" ]; then
  # Проверяем признаки монетизации в проекте
  HAS_PAYMENTS=false
  for indicator in "yookassa" "stripe" "storekit" "payment" "billing" "subscription" "paywall" "checkout"; do
    if grep -rqi "$indicator" "$WORK_DIR/package.json" "$WORK_DIR/requirements.txt" "$WORK_DIR/pyproject.toml" 2>/dev/null; then
      HAS_PAYMENTS=true
      break
    fi
    if find "$WORK_DIR/src" "$WORK_DIR/app" "$WORK_DIR/pages" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" 2>/dev/null | head -50 | xargs grep -qi "$indicator" 2>/dev/null; then
      HAS_PAYMENTS=true
      break
    fi
  done

  if [ "$HAS_PAYMENTS" = true ]; then
    WARNINGS="⚠️ LEGAL: Проект содержит монетизацию, но папка /legal/ отсутствует. Запусти /legal-compliance для генерации юрдокументов."
  fi
else
  # Проверка 2: есть ли незаполненные placeholder'ы
  UNFILLED=$(grep -roh '{{[A-Z_]*}}' "$LEGAL_DIR" 2>/dev/null | sort -u)
  if [ -n "$UNFILLED" ]; then
    COUNT=$(echo "$UNFILLED" | wc -l | tr -d ' ')
    SAMPLE=$(echo "$UNFILLED" | head -5 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="⚠️ LEGAL: В /legal/ найдено $COUNT незаполненных placeholder'ов: $SAMPLE. Заполни перед деплоем!"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "$WARNINGS"
  }
}
EOF
else
  exit 0
fi
