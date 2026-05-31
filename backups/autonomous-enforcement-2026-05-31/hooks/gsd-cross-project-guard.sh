#!/usr/bin/env bash
# PreToolUse(Bash) hook — CROSS-PROJECT / SHARED-STATE GUARD.
#
# Multiple Claude sessions run in parallel over different projects. A destructive
# command from one session can wreck another session's state (clearing a shared
# cache, pruning someone else's worktree, deleting a live team's tasks, nuking
# memory). This hook DENIES destructive commands that reach OUTSIDE the current
# project or touch shared multi-session state, while leaving project-local work
# untouched.
#
# It is intentionally narrow: only DESTRUCTIVE verbs against FOREIGN/SHARED paths
# are denied. Normal project-local commands pass through.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

deny() {
  # PreToolUse deny envelope — Claude sees the reason and avoids the action.
  printf '%s' "$INPUT" >/dev/null
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"$1"}}
EOF
  exit 0
}

# --- 1. Is this a destructive command at all? --------------------------------
# Any rm/mv/shred/truncate, git clean -d/-x, git worktree prune, docker/system
# prune, find ... -delete. Broad on the VERB so plain `rm file` (no flags) is
# caught — the path checks below stay narrow, so project-local ops still pass.
if ! printf '%s' "$CMD" | grep -qiE '(^|[[:space:]])(rm|mv|shred|truncate)[[:space:]]|git[[:space:]]+clean[[:space:]]+-[a-z]*[dx]|git[[:space:]]+worktree[[:space:]]+prune|(docker|system|builder)[[:space:]]+prune|find[[:space:]].*-delete'; then
  exit 0
fi

# --- 2. Shared multi-session state — ALWAYS protected ------------------------
# Teams / tasks / memory / per-session runtime are owned by potentially-live
# OTHER sessions. Agents must use proper tools (TeamDelete) or leave them be.
if printf '%s' "$CMD" | grep -qiE '\.claude/(teams|tasks)([/ ]|$)'; then
  deny "BLOCKED: this destructively touches ~/.claude/teams or ~/.claude/tasks — shared state of possibly-LIVE parallel sessions. Use TeamDelete after shutdown_response, or the mtime-gated gsd-team-archive hook. Never rm a team/task dir directly."
fi
if printf '%s' "$CMD" | grep -qiE '\.claude/projects/.*/memory|(^|[/ ])memory/MEMORY\.md'; then
  deny "BLOCKED: this would destroy persistent MEMORY. Memory is cross-session and append-only — read and update files, never bulk-delete. Remove a single wrong memory only with an explicit, narrow command."
fi
if printf '%s' "$CMD" | grep -qiE '/tmp/claude-|\.claude/(cache|sessions|history|shell-snapshots|paste-cache|file-history)([/ ]|$)'; then
  deny "BLOCKED: this clears Claude runtime/cache state used by other live sessions. Do not clear shared caches from inside a project task."
fi

# --- 3. Foreign project dirs under ~/development -----------------------------
# Determine the current project root (git toplevel of cwd, else cwd).
PROJ_ROOT="$CWD"
if [ -n "$CWD" ]; then
  TOP=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$TOP" ] && PROJ_ROOT="$TOP"
fi
PROJ_BASE=$(basename "$PROJ_ROOT" 2>/dev/null)

# If the command names an absolute ~/development/<other> path (a different
# project than the current one), deny destructive ops on it.
DEV="${HOME}/development"
# Extract dev-path references from the command and check each segment.
for ref in $(printf '%s' "$CMD" | grep -oE "(${DEV}|~/development|\\\$HOME/development)/[A-Za-z0-9._-]+" 2>/dev/null); do
  name=$(basename "$ref")
  if [ "$name" != "$PROJ_BASE" ]; then
    deny "BLOCKED: destructive op targets a DIFFERENT project ('$name') than the current one ('$PROJ_BASE'). Parallel sessions may be working there. Stay within your own project; if cross-project change is truly needed, surface it (AUTONOMOUS-HALT) instead of acting."
  fi
done

# --- 4. Admin context safety -------------------------------------------------
# Destructive command issued while cwd is inside ~/.claude itself.
case "$CWD" in
  "$HOME/.claude"|"$HOME/.claude/"*)
    deny "BLOCKED: destructive command with cwd inside ~/.claude (shared config/state of all sessions). Operate from a project directory."
    ;;
esac

exit 0
