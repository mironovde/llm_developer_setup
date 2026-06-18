#!/usr/bin/env bash
# SessionStart hook — archive orphaned Agent Teams.
#
# Layer-4 enforcement for the "TeamDelete after work" discipline that prompt
# rules (Layer 1) repeatedly fail to enforce. A team is considered ORPHANED
# when NO file inside its dir (config.json, inboxes/*, or its task list) has
# been modified within STALE_DAYS. Orphaned teams are MOVED (not deleted) to
# ~/.claude/teams/_archived/<name>-<date>/ so the action is fully reversible.
#
# Standing/long-running teams stay untouched: any recent inbox or task write
# resets their staleness. Freshly-created teams (current session) are always
# fresh. Conservative threshold avoids archiving an active standing team.

TEAMS_DIR="$HOME/.claude/teams"
TASKS_DIR="$HOME/.claude/tasks"
ARCHIVE_DIR="$TEAMS_DIR/_archived"
STALE_DAYS=14

[ -d "$TEAMS_DIR" ] || exit 0

archived=()
DATE_TAG=$(date +%Y-%m-%d)

for team_path in "$TEAMS_DIR"/*/; do
  name=$(basename "$team_path")
  # Never touch the archive dir itself.
  [ "$name" = "_archived" ] && continue

  # Collect mtimes from team dir + matching task dir. If ANY file was modified
  # within STALE_DAYS, the team is live — skip it.
  recent=$(find "$team_path" "$TASKS_DIR/$name" -type f -mtime "-${STALE_DAYS}" 2>/dev/null | head -1)
  if [ -n "$recent" ]; then
    continue
  fi

  # Orphaned → archive (reversible move).
  dest="$ARCHIVE_DIR/${name}-${DATE_TAG}"
  mkdir -p "$dest"
  mv "$team_path" "$dest/team" 2>/dev/null
  [ -d "$TASKS_DIR/$name" ] && mv "$TASKS_DIR/$name" "$dest/tasks" 2>/dev/null
  archived+=("$name")
done

# Emit a SessionStart additionalContext envelope only if we archived anything.
if [ ${#archived[@]} -gt 0 ]; then
  list=$(printf '%s, ' "${archived[@]}")
  list=${list%, }
  node -e '
    const list = process.argv[1];
    const days = process.argv[2];
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: "Auto-archived orphaned Agent Teams (no activity >" + days + "d): " + list + ". Moved to ~/.claude/teams/_archived/ (reversible). Run TeamDelete after future team work to avoid this.",
      },
    }));
  ' "$list" "$STALE_DAYS"
fi

exit 0
