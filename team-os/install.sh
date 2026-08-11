#!/usr/bin/env bash
# Team OS installer: overlays team-os/home/ into ~/.claude/ (or $CLAUDE_HOME).
# - Timestamped backup of EVERY file it replaces (nothing is ever lost)
# - Idempotent: re-run safely; unchanged files are skipped
# - --dry-run shows the plan; --yes skips the confirmation
# Restore: cp -R <backup-dir>/. "$HOME/.claude/"
set -euo pipefail

SRC_ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_HOME/teamos-backups/$TS"
DRY=0
YES=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --yes) YES=1 ;;
    *) echo "usage: install.sh [--dry-run] [--yes]" >&2; exit 1 ;;
  esac
done

# (dest-relative-to-CLAUDE_HOME, source) pairs
MAPPINGS=()
MAPPINGS+=("CLAUDE.md|$SRC_ROOT/home/CLAUDE.md")
# Carried so a new machine is not quietly poorer: the global security policy and the legal
# document templates lived only in ~/.claude and were in no repository.
[ -f "$SRC_ROOT/home/SECURITY.md" ] && MAPPINGS+=("SECURITY.md|$SRC_ROOT/home/SECURITY.md")
for f in "$SRC_ROOT"/home/legal-templates/*.md; do
  [ -e "$f" ] || continue
  MAPPINGS+=("legal-templates/$(basename "$f")|$f")
done
MAPPINGS+=("settings.json|$SRC_ROOT/home/settings.json")
MAPPINGS+=("statusline.sh|$SRC_ROOT/home/statusline.sh")
for f in "$SRC_ROOT"/home/hooks/*.sh; do
  MAPPINGS+=("hooks/$(basename "$f")|$f")
done
for d in "$SRC_ROOT"/home/skills/*/; do
  name="$(basename "$d")"
  MAPPINGS+=("skills/$name/SKILL.md|$d/SKILL.md")
done
for f in "$SRC_ROOT"/home/agents/*.md; do
  [ -e "$f" ] || continue
  MAPPINGS+=("agents/$(basename "$f")|$f")
done
# Slash commands: carried so a new machine is not missing them. They are not part of the measured
# core — they are the user's own commands, kept here only so a rollout is lossless.
for f in "$SRC_ROOT"/home/commands/*.md; do
  [ -e "$f" ] || continue
  MAPPINGS+=("commands/$(basename "$f")|$f")
done
for f in "$SRC_ROOT"/scripts/*; do
  [ -f "$f" ] || continue
  MAPPINGS+=("teamos/bin/$(basename "$f")|$f")
done

REPLACED=()
ADDED=()
UNCHANGED=()
for m in "${MAPPINGS[@]}"; do
  rel="${m%%|*}"; src="${m#*|}"
  dest="$CLAUDE_HOME/$rel"
  if [ ! -f "$src" ]; then echo "WARN: missing source $src (skipped)" >&2; continue; fi
  if [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then UNCHANGED+=("$rel"); else REPLACED+=("$rel"); fi
  else
    ADDED+=("$rel")
  fi
done

echo "Team OS install → $CLAUDE_HOME"
echo "  new files      : ${#ADDED[@]}"
echo "  replaced (with backup): ${#REPLACED[@]}"
if [ "${#REPLACED[@]}" -gt 0 ]; then printf '    - %s\n' "${REPLACED[@]}"; fi
echo "  unchanged      : ${#UNCHANGED[@]}"
if [ "${#REPLACED[@]}" -gt 0 ]; then
  echo "  backup dir     : $BACKUP_DIR"
  echo "  restore with   : cp -R \"$BACKUP_DIR/.\" \"$CLAUDE_HOME/\""
fi
echo "  NOTE: replacing CLAUDE.md/settings.json swaps your global config for Team OS (old one fully preserved in the backup)."

[ "$DRY" -eq 1 ] && { echo "(dry-run: nothing written)"; exit 0; }

if [ "$YES" -ne 1 ]; then
  printf 'Proceed? [y/N] '
  read -r ANSWER
  case "$ANSWER" in y|Y|yes|YES) ;; *) echo "aborted"; exit 1 ;; esac
fi

for m in "${MAPPINGS[@]}"; do
  rel="${m%%|*}"; src="${m#*|}"
  dest="$CLAUDE_HOME/$rel"
  [ -f "$src" ] || continue
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then continue; fi
  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -p "$dest" "$BACKUP_DIR/$rel"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  case "$rel" in *.sh|teamos/bin/*) chmod +x "$dest" ;; esac
done

# Preserve machine-personal keys from the just-backed-up settings.json (plugins, theme, env extras).
# Team OS keys win on conflict; env objects are merged (Team OS overrides same-name vars).
OLD_SETTINGS="$BACKUP_DIR/settings.json"
NEW_SETTINGS="$CLAUDE_HOME/settings.json"
if [ -f "$OLD_SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  TMPJ="$(mktemp)"
  if jq -s '
    .[0] as $old | .[1] as $new
    | $new
    | .env = (($old.env // {}) + ($new.env // {}))
    | reduce ("enabledPlugins","theme","effortLevel","agentPushNotifEnabled","remoteControlAtStartup",
              "skipDangerousModePermissionPrompt","skipWorkflowUsageWarning","forceLoginMethod") as $k
        (.; if ($old[$k] != null) then .[$k] = $old[$k] else . end)
  ' "$OLD_SETTINGS" "$NEW_SETTINGS" > "$TMPJ" 2>/dev/null && jq -e . "$TMPJ" >/dev/null 2>&1; then
    mv "$TMPJ" "$NEW_SETTINGS"
    echo "personal settings preserved: enabledPlugins/theme/effort/notifications + env merged (Team OS wins conflicts)."
  else
    rm -f "$TMPJ"
    echo "WARN: personal-settings merge skipped (jq merge failed); pristine Team OS settings installed." >&2
  fi
fi

mkdir -p "$CLAUDE_HOME/teamos"
printf '%s\n' "$SRC_ROOT" > "$CLAUDE_HOME/teamos/repo-path"

echo "done."
if [ "${#REPLACED[@]}" -gt 0 ]; then
  echo "backup: $BACKUP_DIR"
  echo "restore: cp -R \"$BACKUP_DIR/.\" \"$CLAUDE_HOME/\""
fi
echo "Restart Claude Code sessions (or /reload-skills) to pick up the new config."
