#!/usr/bin/env bash
# Gym judge — cheap LLM (haiku) grades a transcript against expectations with mandatory evidence.
# Usage: judge.sh <transcript.jsonl> <expectations.md> <out-grading.json>
set -euo pipefail

TRANSCRIPT="$1"
EXPECT="$2"
OUTFILE="$3"
GYM="$(cd "$(dirname "$0")" && pwd)"

# Digest the transcript: assistant text + tool calls + TOOL RESULTS + result lines.
#
# Tool results were missing here until 2026-08-09, and expectations of the form "ran the tests and
# READ the output" were being graded against a digest that structurally could not contain any output.
# Every arm was losing outcome points for evidence the judge was never shown. Results are truncated
# hard (600 chars) because test runners are verbose and the pass/fail lines sit at either end.
DIGEST_RAW="$(jq -r '
  select(.type? == "assistant" or .type? == "user" or .type? == "result") |
  if .type == "assistant" then
    (.message.content // [] | map(
      if .type == "text" then "ASSISTANT: " + (.text | .[0:1500])
      elif .type == "tool_use" then "TOOL_USE: " + .name + " " + ((.input | tostring) | .[0:400])
      else empty end) | join("\n"))
  elif .type == "user" then
    (.message.content // [] | map(
      if (.type? == "tool_result") then
        "TOOL_RESULT: " + ((.content | if type == "array" then (map(.text? // "") | join(" ")) else tostring end) | .[0:600])
      else empty end) | join("\n"))
  else
    "RESULT: is_error=" + ((.is_error // false)|tostring) + " turns=" + ((.num_turns // 0)|tostring)
  end' "$TRANSCRIPT" 2>/dev/null)"

# Long runs get head AND tail, not just head: "reproduced the failure first" lives at the start and
# "verified fresh at the end" lives at the end. Cutting only the tail silently fails the second kind.
# Cap measured, not guessed: a 54,757-character digest grades fine, a 69,291-character one comes
# back is_error with zero output tokens. The old threshold of 70,000 sat above that cliff, so every
# long run — the ones this suite exists to measure — silently lost its grading. 44,000 leaves room
# for the expectations and the instructions on top.
DIGEST_LEN=${#DIGEST_RAW}
if [ "$DIGEST_LEN" -gt 44000 ]; then
  DIGEST="$(printf '%s' "$DIGEST_RAW" | head -c 22000)
[... middle of the transcript omitted, $((DIGEST_LEN - 44000)) characters ...]
$(printf '%s' "$DIGEST_RAW" | tail -c 22000)"
else
  DIGEST="$DIGEST_RAW"
fi

[ -z "$DIGEST" ] && DIGEST="(empty transcript)"

PROMPT="You are a strict eval judge. Grade an agent transcript against expectations.

RULES:
- For each expectation output passed=true/false with EVIDENCE: a verbatim quote from the transcript below or a concrete fact from it. 'The agent said it passed' is NOT evidence of the underlying fact — look for the actual command/output/action.
- Expectations assert correctness, not presence. A plausible-sounding claim without a matching action fails.
- When uncertain, fail the expectation and say why.
- Each expectation carries a [outcome] or [process] tag. Copy it into the 'group' field verbatim.
  Judge both groups by the same strict standard, but never let a [process] expectation influence
  how you grade an [outcome] one: an agent that reached the right result through a different
  working style still passes every outcome it actually achieved.
- Compute outcome_pass_rate over [outcome] items only and process_pass_rate over [process] items only.
  If a group is empty, report its rate as 1.

EXPECTATIONS:
$(cat "$EXPECT")

TRANSCRIPT DIGEST (assistant text + tool calls):
$DIGEST"

# The prompt goes in on STDIN, not as an argv string. Passing a 55-70KB digest as an argument was
# failing with is_error and zero output tokens on exactly the long runs this suite exists to grade —
# and failing silently, since the error was swallowed. Two attempts, because some failures are
# transient rather than structural.
judge_call() {
  printf '%s' "$PROMPT" | claude -p \
    --model haiku \
    --effort low \
    --setting-sources project \
    --strict-mcp-config \
    --tools "" \
    --output-format json \
    --json-schema "$(cat "$GYM/grading-schema.json")" 2>/dev/null \
    | jq -r '.result // .structured_output // empty'
}

judge_call > "$OUTFILE.tmp" 2>/dev/null
if [ ! -s "$OUTFILE.tmp" ]; then
  sleep 3
  judge_call > "$OUTFILE.tmp" 2>/dev/null
fi
if [ ! -s "$OUTFILE.tmp" ]; then
  rm -f "$OUTFILE.tmp"; echo "judge: claude call failed after a retry" >&2; exit 1
fi

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

# Recompute the summary from the per-expectation verdicts. The model judges; it does not count.
# (Measured 2026-08-09: haiku reported passed=2 for a grading whose items contained 3 true —
#  config decisions ride on these numbers, so they are derived, never taken on trust.)
RECALC="$(mktemp)"
if jq '
  (.expectations // []) as $e
  | ($e | map(select(.group != "process"))) as $out
  | ($e | map(select(.group == "process"))) as $pro
  | (def rate($xs): if ($xs|length) == 0 then 1
      else (($xs | map(select(.passed)) | length) / ($xs|length) * 1000 | round / 1000) end;
    .summary = {
      passed:  ($e   | map(select(.passed)) | length),
      failed:  ($e   | map(select(.passed | not)) | length),
      total:   ($e   | length),
      pass_rate: rate($e),
      outcome_passed: ($out | map(select(.passed)) | length),
      outcome_total:  ($out | length),
      outcome_pass_rate: rate($out),
      process_passed: ($pro | map(select(.passed)) | length),
      process_total:  ($pro | length),
      process_pass_rate: rate($pro)
    })' "$OUTFILE" > "$RECALC" 2>/dev/null && jq -e . "$RECALC" >/dev/null 2>&1; then
  mv "$RECALC" "$OUTFILE"
else
  rm -f "$RECALC"
  echo "judge: summary recompute failed — model-reported counts left in place" >&2
fi
