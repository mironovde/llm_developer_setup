#!/usr/bin/env bash
#
# install.sh — deploy the user-custom Claude Code hooks onto this machine.
#
# Portable, idempotent. Copies the canonical hooks from this repo into
# ~/.claude/hooks/ and (on macOS) installs + loads the autonomous watchdog
# launchd agent, generating its plist with the current $HOME.
#
# It only touches the 9 USER-CUSTOM hooks listed below — it never overwrites
# GSD-framework hooks (those are managed by GSD's own updater).
#
# Usage:
#   ./install.sh [--dry-run] [--no-launchd] [-h|--help]
#
set -euo pipefail

# --- locate repo-relative source dir (works from any cwd) -------------------
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SRC="$SRC_DIR/hooks"
PLIST_TEMPLATE="$SRC_DIR/launchd/com.claude.autonomous-watchdog.plist.template"

DEST_HOOKS="$HOME/.claude/hooks"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS/com.claude.autonomous-watchdog.plist"
STATE_DIR="$HOME/.claude/autonomous-state"

DRY_RUN=0
DO_LAUNCHD=1

for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=1 ;;
    --no-launchd) DO_LAUNCHD=0 ;;
    -h|--help)
      # print the leading comment header only (stop at first non-comment line)
      awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# The 9 user-custom hooks this repo owns (NOT GSD-framework, NOT reinstallable).
HOOKS=(
  gsd-autonomous-driver.js
  gsd-autonomous-heartbeat.sh
  gsd-autonomous-watchdog.sh
  gsd-cross-project-guard.sh
  gsd-team-archive.sh
  pipeline-reminder.sh
  auto-format.sh
  legal-deploy-check.sh
  pre-commit-check.sh
)

run() {  # echo + execute, or just echo under --dry-run
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] $*"; else eval "$@"; fi
}

echo "==> Installing Claude hooks from: $HOOKS_SRC"
[ "$DRY_RUN" -eq 1 ] && echo "    (DRY RUN — no changes will be made)"

# --- 1) hooks ---------------------------------------------------------------
run "mkdir -p \"$DEST_HOOKS\""
for h in "${HOOKS[@]}"; do
  if [ ! -f "$HOOKS_SRC/$h" ]; then
    echo "  ! missing in repo, skipped: $h" >&2; continue
  fi
  run "cp \"$HOOKS_SRC/$h\" \"$DEST_HOOKS/$h\""
  run "chmod +x \"$DEST_HOOKS/$h\""
  echo "  ✓ $h"
done

# --- 2) launchd watchdog (macOS only) ---------------------------------------
if [ "$DO_LAUNCHD" -eq 1 ] && [ "$(uname)" = "Darwin" ]; then
  echo "==> Installing launchd watchdog (com.claude.autonomous-watchdog)"
  run "mkdir -p \"$STATE_DIR\" \"$LAUNCH_AGENTS\""
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] render $PLIST_TEMPLATE (__HOME__ -> $HOME) > $PLIST_DEST"
  else
    sed "s#__HOME__#$HOME#g" "$PLIST_TEMPLATE" > "$PLIST_DEST"
  fi
  echo "  ✓ plist -> $PLIST_DEST"
  # idempotent reload
  run "launchctl unload \"$PLIST_DEST\" 2>/dev/null || true"
  run "launchctl load -w \"$PLIST_DEST\""
  echo "  ✓ watchdog loaded (runs every 120s)"
elif [ "$DO_LAUNCHD" -eq 1 ]; then
  echo "==> Skipping launchd (not macOS: $(uname)). Watchdog hook still copied;"
  echo "    wire it to a timer (cron/systemd) yourself if you need resurrection."
fi

# --- 3) reminder about wiring ----------------------------------------------
cat <<EOF

==> Done. Hook FILES are in place.
    NOTE: hooks only fire once wired in ~/.claude/settings.json.
    See the hooks block in backups/<latest>/global-settings.json and apply it.
    Two portability fixes to make there:
      • use "node" (or \$(command -v node)) instead of an absolute /opt/homebrew path
      • use ~/.claude/hooks/... (not /Users/<name>/...) so paths are user-agnostic
EOF
