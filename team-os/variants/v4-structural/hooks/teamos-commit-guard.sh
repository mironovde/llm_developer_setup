#!/usr/bin/env bash
# Stop hook: if this session edited files and the tree is still dirty, don't let the turn end
# silently. Either commit, or say out loud that you are leaving it uncommitted and why.
#
# Why a hook and not a line in CLAUDE.md: the rule WAS in CLAUDE.md, in bold, and the gym still
# measured the agent walking away from uncommitted work on 003 in two consecutive rounds. A rule
# stated once at the top of a file does not fire at the moment work ends. A hook costs no context
# and is not forgotten. Rules that must hold every time belong here, not in prose.
#
# Fails open on every doubt — a guard that traps a session is worse than the drift it prevents.
set -u

IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
SID="$(printf '%s' "$IN" | jq -r '.session_id // "nosession"' 2>/dev/null)"
TRANSCRIPT="$(printf '%s' "$IN" | jq -r '.transcript_path // empty' 2>/dev/null)"
ACTIVE="$(printf '%s' "$IN" | jq -r '.stop_hook_active // false' 2>/dev/null)"

[ -z "$CWD" ] && exit 0
[ "$ACTIVE" = "true" ] && exit 0          # already came back through a stop hook — never chain

# Block at most once per session: the point is a reminder, not a hostage situation.
STATE_DIR="${TMPDIR:-/tmp}/teamos-commit-guard"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
MARK="$STATE_DIR/$SID"
[ -f "$MARK" ] && exit 0

cd "$CWD" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Dirty? (porcelain already ignores gitignored paths, so .artifacts/ does not trigger this)
DIRTY="$(git status --porcelain 2>/dev/null | grep -v '^?? .*\.artifacts/' | head -20)"
[ -z "$DIRTY" ] && exit 0

# Did THIS session write anything? A tree that was dirty before the agent arrived is not its doing.
[ -f "$TRANSCRIPT" ] || exit 0
if ! grep -qE '"name":"(Edit|Write|NotebookEdit|MultiEdit)"' "$TRANSCRIPT" 2>/dev/null; then
  exit 0
fi

# Did the agent already address it? A stated reason is a valid ending — the rule is
# "don't leave silently", not "always commit".
# LC_ALL=C: `tail -c` cuts mid-character, and BSD tr rejects the resulting partial UTF-8 byte
# with "Illegal byte sequence" — which this guard printed to stderr the first time it fired for
# real. Byte-wise collation makes tr indifferent to encoding.
LAST="$(tail -c 20000 "$TRANSCRIPT" 2>/dev/null | LC_ALL=C tr '\n' ' ')"
if printf '%s' "$LAST" | grep -qiE 'uncommitted|not commit|without commit|leaving .{0,20}(staged|uncommitted)|не коммич|без коммита|не буду коммитить'; then
  exit 0
fi

COUNT="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
FILES="$(git status --porcelain 2>/dev/null | awk '{print $2}' | head -5 | LC_ALL=C tr '\n' ' ')"
: > "$MARK"

echo "BLOCKED: this session edited files and $COUNT path(s) are still uncommitted ($FILES...). A unit is not finished until it is committed. Either commit the work per the repo's convention now, or state in your final message that you are leaving it uncommitted and why — a deliberate reason is fine, silence is not. This guard fires once per session." >&2
exit 2
