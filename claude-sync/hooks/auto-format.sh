#!/bin/bash
# PostToolUse hook: auto-format after Edit/Write
# Runs the project's formatter on changed files

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Determine project root
PROJECT_DIR=$(cd "$(dirname "$FILE_PATH")" && git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_DIR" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Try project-specific formatters
if [ -f "$PROJECT_DIR/biome.json" ] || [ -f "$PROJECT_DIR/biome.jsonc" ]; then
  cd "$PROJECT_DIR" && npx biome check --fix "$FILE_PATH" 2>/dev/null
elif [ -f "$PROJECT_DIR/.prettierrc" ] || [ -f "$PROJECT_DIR/.prettierrc.json" ] || [ -f "$PROJECT_DIR/.prettierrc.js" ] || [ -f "$PROJECT_DIR/prettier.config.js" ]; then
  cd "$PROJECT_DIR" && npx prettier --write "$FILE_PATH" 2>/dev/null
fi

# Python formatting
if [ "$EXT" = "py" ]; then
  if command -v ruff &>/dev/null; then
    ruff format "$FILE_PATH" 2>/dev/null
    ruff check --fix "$FILE_PATH" 2>/dev/null
  elif command -v black &>/dev/null; then
    black --quiet "$FILE_PATH" 2>/dev/null
  fi
fi

exit 0
