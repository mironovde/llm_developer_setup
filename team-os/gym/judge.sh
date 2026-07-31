#!/usr/bin/env bash
# Gym judge — cheap LLM (haiku) grades a transcript against expectations with mandatory evidence.
# Usage: judge.sh <transcript.jsonl> <expectations.md> <out-grading.json>
set -euo pipefail

TRANSCRIPT="$1"
EXPECT="$2"
OUTFILE="$3"
GYM="$(cd "$(dirname "$0")" && pwd)"

# Digest the transcript: assistant text + tool calls (names + truncated inputs) + result line.
DIGEST="$(jq -r '
  select(.type? == "assistant" or .type? == "result") |
  if .type == "assistant" then
    (.message.content // [] | map(
      if .type == "text" then "ASSISTANT: " + (.text | .[0:1500])
      elif .type == "tool_use" then "TOOL_USE: " + .name + " " + ((.input | tostring) | .[0:400])
      else empty end) | join("\n"))
  else
    "RESULT: is_error=" + ((.is_error // false)|tostring) + " turns=" + ((.num_turns // 0)|tostring)
  end' "$TRANSCRIPT" 2>/dev/null | head -c 60000)"

[ -z "$DIGEST" ] && DIGEST="(empty transcript)"

PROMPT="You are a strict eval judge. Grade an agent transcript against expectations.

RULES:
- For each expectation output passed=true/false with EVIDENCE: a verbatim quote from the transcript below or a concrete fact from it. 'The agent said it passed' is NOT evidence of the underlying fact — look for the actual command/output/action.
- Expectations assert correctness, not presence. A plausible-sounding claim without a matching action fails.
- When uncertain, fail the expectation and say why.

EXPECTATIONS:
$(cat "$EXPECT")

TRANSCRIPT DIGEST (assistant text + tool calls):
$DIGEST"

claude -p "$PROMPT" \
  --model haiku \
  --effort low \
  --setting-sources project \
  --strict-mcp-config \
  --tools "" \
  --output-format json \
  --json-schema "$(cat "$GYM/grading-schema.json")" \
  < /dev/null 2>/dev/null \
  | jq -r '.result // .structured_output // empty' > "$OUTFILE.tmp" || { rm -f "$OUTFILE.tmp"; echo "judge: claude call failed" >&2; exit 1; }

# result may be a JSON string or already-object depending on CLI version — normalize
if jq -e 'type == "object" and has("expectations")' "$OUTFILE.tmp" >/dev/null 2>&1; then
  mv "$OUTFILE.tmp" "$OUTFILE"
elif jq -e 'type == "string"' "$OUTFILE.tmp" >/dev/null 2>&1; then
  jq -r '.' "$OUTFILE.tmp" | jq '.' > "$OUTFILE" 2>/dev/null && rm -f "$OUTFILE.tmp" || { echo "judge: unparseable output" >&2; mv "$OUTFILE.tmp" "$OUTFILE.raw"; exit 1; }
else
  echo "judge: unexpected output shape" >&2
  mv "$OUTFILE.tmp" "$OUTFILE.raw"
  exit 1
fi
