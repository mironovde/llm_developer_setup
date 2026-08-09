#!/usr/bin/env bash
# Red/green test for the rewritten gym gates. No LLM calls.
# For each task: unsolved fixture must FAIL, hand-solved fixture must PASS.
set -uo pipefail
GYM="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
PASS=0; FAIL=0

mkws() { # $1=task → prints workspace path
  local t="$1" ws="$WORK/$1-$2"
  rm -rf "$ws"; mkdir -p "$ws"
  cp -R "$GYM/tasks/$t/fixture/." "$ws/"
  cp -R "$GYM/../project-template/team" "$ws/team" 2>/dev/null || true
  ( cd "$ws" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init )
  printf '%s' "$ws"
}

run_gate() { # $1=task $2=ws $3=transcript-text → exit code
  local t="$1" ws="$2" tr="$ws/.transcript.jsonl"
  printf '%s\n' "${3:-{}}" > "$tr"
  ( cd "$ws" && WORKSPACE="$ws" TRANSCRIPT="$tr" RESULT_JSON='{}' \
      BUDGET_USED=1000 BUDGET_LIMIT=999999 bash "$GYM/tasks/$t/check.sh" ) >"$ws/.gate.log" 2>&1
}

expect() { # $1=label $2=expected(pass|fail) $3=actual-rc $4=ws
  local ok
  if [ "$2" = "pass" ] && [ "$3" -eq 0 ]; then ok=1
  elif [ "$2" = "fail" ] && [ "$3" -ne 0 ]; then ok=1
  else ok=0; fi
  if [ "$ok" = "1" ]; then echo "  ok   $1 (expected $2)"; PASS=$((PASS+1))
  else echo "  FAIL $1 (expected $2, rc=$3): $(tail -1 "$4/.gate.log")"; FAIL=$((FAIL+1)); fi
}

echo "── 001-t0-typo"
ws="$(mkws 001-t0-typo red)"; run_gate 001-t0-typo "$ws" '{}'; expect "unsolved" fail $? "$ws"
ws="$(mkws 001-t0-typo green)"
sed -i '' 's/Recieved/Received/g' "$ws/src/format.js"
run_gate 001-t0-typo "$ws" '{}'; expect "typo fixed" pass $? "$ws"
ws="$(mkws 001-t0-typo bloat)"
sed -i '' 's/Recieved/Received/g' "$ws/src/format.js"
printf 'plan\n' > "$ws/PLAN.md"; printf 'prd\n' > "$ws/PRD.md"
run_gate 001-t0-typo "$ws" '{}'; expect "fixed but 2 plan docs" fail $? "$ws"

echo "── 002-t0-doc-fix"
ws="$(mkws 002-t0-doc-fix red)"; run_gate 002-t0-doc-fix "$ws" '{}'; expect "unsolved" fail $? "$ws"
ws="$(mkws 002-t0-doc-fix green)"
sed -i '' 's/npm run tst/npm test/g' "$ws/README.md"
run_gate 002-t0-doc-fix "$ws" '{}'; expect "readme fixed" pass $? "$ws"

echo "── 005-trap-t0"
ws="$(mkws 005-trap-t0 red)"; run_gate 005-trap-t0 "$ws" '{}'; expect "unsolved" fail $? "$ws"
ws="$(mkws 005-trap-t0 half)"
sed -i '' 's/MAX_ITEMS = 10/MAX_ITEMS = 50/' "$ws/src/config.js"
run_gate 005-trap-t0 "$ws" '{}'; expect "coupled constant missed" fail $? "$ws"
ws="$(mkws 005-trap-t0 green)"
sed -i '' 's/MAX_ITEMS = 10/MAX_ITEMS = 50/' "$ws/src/config.js"
sed -i '' 's/CACHE_SLOTS = 30/CACHE_SLOTS = 150/' "$ws/src/cache.js"
run_gate 005-trap-t0 "$ws" '{"text":"note: CACHE_SLOTS is coupled to MAX_ITEMS, raised to 150"}'
expect "both fixed + surfaced in answer" pass $? "$ws"
ws="$(mkws 005-trap-t0 silent)"
sed -i '' 's/MAX_ITEMS = 10/MAX_ITEMS = 50/' "$ws/src/config.js"
sed -i '' 's/CACHE_SLOTS = 30/CACHE_SLOTS = 150/' "$ws/src/cache.js"
run_gate 005-trap-t0 "$ws" '{"text":"done"}'; expect "both fixed but never surfaced" fail $? "$ws"

echo "── 007-t2-refactor"
ws="$(mkws 007-t2-refactor red)"; run_gate 007-t2-refactor "$ws" '{}'; expect "unsolved" fail $? "$ws"
ws="$(mkws 007-t2-refactor green)"
python3 - "$ws" <<'PY'
import re, sys, pathlib
ws = pathlib.Path(sys.argv[1]); src = (ws/"src/utils.js").read_text()
body = src.split("module.exports")[0]
fns = dict(re.findall(r"(function (\w+)\([\s\S]*?\n\})", body))
groups = {"strings": ["slugify","truncate","capitalize"],
          "arrays":  ["chunk","unique","groupBy"],
          "dates":   ["formatDate","daysBetween"]}
byname = {n: t for t, n in fns.items()}
preamble = {"dates": "const DAY_MS = 24 * 60 * 60 * 1000;\n\n"}
for mod, names in groups.items():
    code = "\n\n".join(byname[n] for n in names)
    (ws/f"src/{mod}.js").write_text(preamble.get(mod, "") + code +
                                    "\n\nmodule.exports = {" + ", ".join(names) + "};\n")
(ws/"src/utils.js").write_text(
    "const strings = require('./strings');\nconst arrays = require('./arrays');\n"
    "const dates = require('./dates');\n\nmodule.exports = { ...strings, ...arrays, ...dates };\n")
PY
run_gate 007-t2-refactor "$ws" '{}'; expect "split into 3 modules" pass $? "$ws"
ws="$(mkws 007-t2-refactor dupes)"
cp "$ws/src/utils.js" "$ws/src/strings.js"; cp "$ws/src/utils.js" "$ws/src/arrays.js"; cp "$ws/src/utils.js" "$ws/src/dates.js"
printf "module.exports = require('./strings');\n" > "$ws/src/utils.js"
run_gate 007-t2-refactor "$ws" '{}'; expect "copies left behind" fail $? "$ws"

echo
echo "gate tests: $PASS ok, $FAIL failed"
[ "$FAIL" -eq 0 ]
