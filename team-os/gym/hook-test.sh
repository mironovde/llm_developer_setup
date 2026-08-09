#!/usr/bin/env bash
# Red/green tests for the Stop hooks. No LLM calls, no gym runs.
# A guard that can trap a session is more dangerous than the drift it prevents, so every
# fail-open path is tested explicitly, not assumed.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/home/hooks/teamos-commit-guard.sh"
WORK="$(mktemp -d)"
PASS=0; FAIL=0

mkrepo() { # $1=label → prints repo path
  local r="$WORK/$1"; mkdir -p "$r"
  ( cd "$r" && git init -q && printf 'x\n' > seed.txt && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm init )
  printf '%s' "$r"
}

# Transcripts live OUTSIDE the repo under test: writing them inside made the tree dirty and the
# guard fired on the harness's own litter. The artifact-hygiene rule, broken by its own test.
mktranscript() { # $1=repo $2=with-edits(yes|no) $3=trailing text → prints path
  local f="$WORK/transcripts/$(basename "$1").jsonl"
  mkdir -p "$WORK/transcripts"
  : > "$f"
  [ "$2" = "yes" ] && printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}\n' >> "$f"
  printf '{"type":"assistant","message":{"content":[{"type":"text","text":"%s"}]}}\n' "$3" >> "$f"
  printf '%s' "$f"
}

# Session ids must be unique per test RUN: the guard keeps a once-per-session marker in TMPDIR,
# so reusing "s3" across runs made the second run's block silently allow. Found by this suite.
RUN_ID="test-$$"

run_hook() { # $1=cwd $2=transcript $3=session $4=stop_hook_active → rc
  jq -n --arg c "$1" --arg t "$2" --arg s "$RUN_ID-$3" --argjson a "$4" \
    '{cwd:$c, transcript_path:$t, session_id:$s, stop_hook_active:$a}' \
    | bash "$HOOK" >"$WORK/.out" 2>"$WORK/.err"
}

expect() { # $1=label $2=block|allow $3=rc
  local ok=0
  { [ "$2" = "block" ] && [ "$3" -eq 2 ]; } && ok=1
  { [ "$2" = "allow" ] && [ "$3" -eq 0 ]; } && ok=1
  if [ "$ok" = 1 ]; then echo "  ok   $1 (expected $2)"; PASS=$((PASS+1))
  else echo "  FAIL $1 (expected $2, rc=$3) $(head -c 120 "$WORK/.err")"; FAIL=$((FAIL+1)); fi
}

echo "── teamos-commit-guard"

r="$(mkrepo clean)";      t="$(mktranscript "$r" yes "all done")"
run_hook "$r" "$t" s1 false; expect "clean tree" allow $?

r="$(mkrepo noedit)";     printf 'y\n' > "$r/new.txt"; t="$(mktranscript "$r" no "just looked around")"
run_hook "$r" "$t" s2 false; expect "dirty but this session edited nothing" allow $?

r="$(mkrepo dirty)";      printf 'y\n' > "$r/new.txt"; t="$(mktranscript "$r" yes "Fixed the bug, tests pass.")"
run_hook "$r" "$t" s3 false; expect "edited and left dirty silently" block $?

run_hook "$r" "$t" s3 false; expect "same session again — fires once only" allow $?

r="$(mkrepo active)";     printf 'y\n' > "$r/new.txt"; t="$(mktranscript "$r" yes "Fixed it.")"
run_hook "$r" "$t" s4 true;  expect "stop_hook_active — never chains" allow $?

r="$(mkrepo stated)";     printf 'y\n' > "$r/new.txt"
t="$(mktranscript "$r" yes "Leaving this uncommitted: the fixture repo is throwaway.")"
run_hook "$r" "$t" s5 false; expect "left uncommitted WITH a stated reason" allow $?

r="$(mkrepo statedru)";   printf 'y\n' > "$r/new.txt"
t="$(mktranscript "$r" yes "Оставляю без коммита — это временная песочница.")"
run_hook "$r" "$t" s6 false; expect "reason stated in Russian" allow $?

r="$WORK/notgit"; mkdir -p "$r"; printf 'y\n' > "$r/new.txt"
t="$(mktranscript "$r" yes "done")"
run_hook "$r" "$t" s7 false; expect "not a git repo" allow $?

r="$(mkrepo artifacts)";  mkdir -p "$r/.artifacts"; printf 'log\n' > "$r/.artifacts/run.log"
t="$(mktranscript "$r" yes "done")"
run_hook "$r" "$t" s8 false; expect "only scratch in .artifacts/" allow $?

r="$(mkrepo notranscript)"; printf 'y\n' > "$r/new.txt"
run_hook "$r" "$r/missing.jsonl" s9 false; expect "transcript unreadable" allow $?

run_hook "" "" s10 false; expect "no cwd in payload" allow $?

echo
echo "hook tests: $PASS ok, $FAIL failed"
[ "$FAIL" -eq 0 ]
