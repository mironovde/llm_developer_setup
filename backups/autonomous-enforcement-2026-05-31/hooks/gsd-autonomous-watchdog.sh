#!/usr/bin/env bash
# Autonomous WATCHDOG — resurrection layer for rate-limit / crash recovery.
#
# A Stop hook keeps a LIVE session looping, but cannot revive a DEAD process
# (e.g. one that fell on a rate limit). This watchdog runs from launchd every
# ~120s and relaunches an autonomous session whose heartbeat has gone stale —
# i.e. "restart the agent a couple of minutes after a rate-limited fall".
#
# Per project registered in ~/.claude/.autonomous-registry it relaunches only
# when ALL are true (safety): marker present, heartbeat stale > STALE_S, no live
# launched process, min-gap since last relaunch elapsed, daily cap not hit.
#
# Enable a project:  claude-autonomous on ["<resume prompt>"]   (control script)
# Disable:           claude-autonomous off

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

REGISTRY="$HOME/.claude/.autonomous-registry"
STATE_DIR="$HOME/.claude/autonomous-state"
LOG="$STATE_DIR/watchdog.log"
STALE_S=180          # heartbeat older than this → presumed dead / rate-limited
MIN_GAP_S=180        # min seconds between relaunches of the same project
DAILY_CAP=30         # max relaunches per project per day

mkdir -p "$STATE_DIR"
[ -f "$REGISTRY" ] || exit 0

CLAUDE_BIN=$(command -v claude 2>/dev/null)
now=$(date +%s)
today=$(date +%Y-%m-%d)

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
key() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#_#g'; }

# Rewrite registry without dropped entries.
tmp_reg=$(mktemp)

while IFS= read -r proj; do
  [ -z "$proj" ] && continue
  # Drop entries whose project or marker is gone.
  if [ ! -d "$proj" ] || [ ! -f "$proj/.autonomous" ]; then
    log "deregister $proj (marker/dir gone)"
    continue
  fi
  echo "$proj" >> "$tmp_reg"   # keep

  k=$(key "$proj")
  hb_file="$proj/.autonomous-heartbeat"
  pid_file="$STATE_DIR/$k.pid"
  last_file="$STATE_DIR/$k.last"
  count_file="$STATE_DIR/$k.count"

  # Heartbeat age.
  if [ -f "$hb_file" ]; then
    hb=$(stat -f %m "$hb_file" 2>/dev/null || echo 0)
  else
    hb=0
  fi
  age=$(( now - hb ))
  [ "$age" -le "$STALE_S" ] && continue   # alive

  # A previously-launched process still running? (rate-limit-waiting → let it recover)
  if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      continue
    fi
  fi

  # Min gap since last relaunch.
  if [ -f "$last_file" ]; then
    last=$(cat "$last_file" 2>/dev/null || echo 0)
    [ $(( now - last )) -lt "$MIN_GAP_S" ] && continue
  fi

  # Daily cap.
  cap_day=""; cap_n=0
  if [ -f "$count_file" ]; then
    read -r cap_day cap_n < "$count_file" 2>/dev/null
  fi
  [ "$cap_day" != "$today" ] && { cap_day="$today"; cap_n=0; }
  if [ "$cap_n" -ge "$DAILY_CAP" ]; then
    log "cap reached ($DAILY_CAP/day) $proj — not relaunching"
    continue
  fi

  if [ -z "$CLAUDE_BIN" ]; then
    log "ERROR: 'claude' not on PATH — cannot relaunch $proj"
    continue
  fi

  # Resume prompt.
  if [ -f "$proj/.autonomous-prompt" ]; then
    prompt=$(cat "$proj/.autonomous-prompt")
  else
    prompt="Resume autonomous work on this project (AUTONOMOUS OPERATION). Run /gsd-progress to orient, then self-driving loop. If a team exists, re-attach and ping teammates. Do not wait for me. Stop only via an AUTONOMOUS-HALT: line."
  fi

  # Relaunch detached, headless, unattended. The cross-project guard + REFUSE
  # rules constrain what it may do; skipping prompts is required for unattended.
  ( cd "$proj" && nohup "$CLAUDE_BIN" -p "$prompt" --dangerously-skip-permissions \
      >> "$proj/.autonomous.log" 2>&1 & echo $! > "$pid_file" )
  echo "$now" > "$last_file"
  echo "$today $(( cap_n + 1 ))" > "$count_file"
  # Refresh heartbeat so we don't immediately relaunch again next tick.
  date +%s > "$hb_file" 2>/dev/null
  log "RELAUNCH $proj (heartbeat stale ${age}s, attempt $(( cap_n + 1 ))/$DAILY_CAP today, pid $(cat "$pid_file"))"

done < "$REGISTRY"

mv "$tmp_reg" "$REGISTRY" 2>/dev/null || rm -f "$tmp_reg"
exit 0
