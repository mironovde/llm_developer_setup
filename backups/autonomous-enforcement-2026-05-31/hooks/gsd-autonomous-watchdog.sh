#!/usr/bin/env bash
# Autonomous WATCHDOG — runs from launchd every ~120s. Two jobs:
#
# (A) RESURRECTION — relaunch an autonomous session whose heartbeat went stale
#     (rate-limit / partial-answer / crash). RESUMES the same conversation by
#     session id (claude -p --resume <id>) so work continues with full context,
#     rather than starting fresh. Keeps retrying (min-gap) until the rate-limit
#     window clears.
#
# (B) TEAM REAPER — archive Agent Teams that were spawned and forgotten (no file
#     activity for REAP_MIN minutes). Fixes idle teammates piling up. Reversible
#     (moved to ~/.claude/teams/_archived/). A live team writes inboxes far more
#     often than REAP_MIN, so it is never touched.
#
# Heartbeat format: "<epoch_seconds> <session_id>" (written by the PostToolUse
# heartbeat hook continuously + the Stop driver). OFF by default: only projects
# registered via `claude-autonomous on` are resurrected.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

REGISTRY="$HOME/.claude/.autonomous-registry"
STATE_DIR="$HOME/.claude/autonomous-state"
LOG="$STATE_DIR/watchdog.log"
TEAMS_DIR="$HOME/.claude/teams"
TASKS_DIR="$HOME/.claude/tasks"
ARCHIVE_DIR="$TEAMS_DIR/_archived"

STALE_S=240          # heartbeat older than this → presumed dead / rate-limited
MIN_GAP_S=180        # min seconds between relaunches of the same project
DAILY_CAP=40         # max relaunches per project per day
REAP_MIN=60          # team idle minutes before archiving a forgotten team

mkdir -p "$STATE_DIR"
now=$(date +%s)
today=$(date +%Y-%m-%d)
# Log rotation: keep the tail if it grew past ~2MB.
if [ -f "$LOG" ] && [ "$(stat -f %z "$LOG" 2>/dev/null || echo 0)" -gt 2000000 ]; then
  tail -300 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
fi
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
key() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#_#g'; }
CLAUDE_BIN=$(command -v claude 2>/dev/null)

# ============================ (A) RESURRECTION ============================
if [ -f "$REGISTRY" ]; then
  tmp_reg=$(mktemp)
  while IFS= read -r proj; do
    [ -z "$proj" ] && continue
    if [ ! -d "$proj" ] || [ ! -f "$proj/.autonomous" ]; then
      log "deregister $proj (marker/dir gone)"; continue
    fi
    echo "$proj" >> "$tmp_reg"

    # Agent emitted AUTONOMOUS-HALT (backlog done / needs user direction): pause
    # resurrection until the user re-engages (UserPromptSubmit clears the flag).
    # This is what stops the "resurrect → halt → resurrect" churn every few minutes.
    [ -f "$proj/.autonomous-halt" ] && continue

    k=$(key "$proj")
    hb_file="$proj/.autonomous-heartbeat"
    pid_file="$STATE_DIR/$k.pid"
    last_file="$STATE_DIR/$k.last"
    count_file="$STATE_DIR/$k.count"

    # Parse heartbeat "<epoch> <sid>"; fall back to file mtime.
    hb_ts=0; hb_sid=""
    if [ -f "$hb_file" ]; then
      read -r hb_ts hb_sid < "$hb_file" 2>/dev/null
      case "$hb_ts" in (''|*[!0-9]*) hb_ts=$(stat -f %m "$hb_file" 2>/dev/null || echo 0);; esac
    fi
    age=$(( now - hb_ts ))
    [ "$age" -le "$STALE_S" ] && continue   # alive & working (heartbeat fresh)

    # Cross-check liveness against the session transcript and derive the session id.
    # The transcript path is ~/.claude/projects/<enc>/<session-id>.jsonl and is
    # appended to as the session runs — a strong second liveness signal that also
    # catches the case where the heartbeat hook didn't fire. Prevents spawning a
    # DUPLICATE next to a live interactive session, and lets us --resume by id even
    # when the heartbeat lacked one (first resurrection keeps full context).
    enc=$(printf '%s' "$proj" | sed 's#[/_]#-#g')
    tdir="$HOME/.claude/projects/$enc"
    if [ -d "$tdir" ]; then
      newest_jsonl=$(ls -t "$tdir"/*.jsonl 2>/dev/null | head -1)
      if [ -n "$newest_jsonl" ]; then
        tx_m=$(stat -f %m "$newest_jsonl" 2>/dev/null || echo 0)
        [ $(( now - tx_m )) -le "$STALE_S" ] && continue   # transcript still active → live
        # The transcript filename is ground truth for the latest session id —
        # prefer it over a possibly-stale heartbeat sid (e.g. a session that
        # predates the heartbeat hook and never wrote one).
        hb_sid=$(basename "$newest_jsonl" .jsonl)
      fi
    fi

    # A relaunch we previously started still running? (rate-limit-waiting) → wait.
    if [ -f "$pid_file" ]; then
      pid=$(cat "$pid_file" 2>/dev/null)
      [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && continue
    fi
    # Min gap between relaunches.
    if [ -f "$last_file" ]; then
      last=$(cat "$last_file" 2>/dev/null || echo 0)
      [ $(( now - last )) -lt "$MIN_GAP_S" ] && continue
    fi
    # Daily cap.
    cap_day=""; cap_n=0
    [ -f "$count_file" ] && read -r cap_day cap_n < "$count_file" 2>/dev/null
    [ "$cap_day" != "$today" ] && { cap_day="$today"; cap_n=0; }
    if [ "$cap_n" -ge "$DAILY_CAP" ]; then
      log "cap $DAILY_CAP/day reached $proj — skip"; continue
    fi
    if [ -z "$CLAUDE_BIN" ]; then log "ERROR: claude not on PATH for $proj"; continue; fi

    if [ -f "$proj/.autonomous-prompt" ]; then
      prompt=$(cat "$proj/.autonomous-prompt")
    else
      prompt="Resume autonomous work (AUTONOMOUS OPERATION). /gsd-progress, then self-driving loop. Re-attach and ping the team. A rate limit is not completion — continue. Stop only via AUTONOMOUS-HALT:."
    fi

    # Resume the SAME conversation when we know its id → keeps full context and
    # continues a partial / rate-limited turn. Otherwise start a fresh print run.
    if [ -n "$hb_sid" ] && [ "$hb_sid" != "null" ]; then
      ( cd "$proj" && nohup "$CLAUDE_BIN" -p --resume "$hb_sid" "$prompt" \
          --dangerously-skip-permissions >> "$proj/.autonomous.log" 2>&1 & echo $! > "$pid_file" )
      mode="resume:$hb_sid"
    else
      ( cd "$proj" && nohup "$CLAUDE_BIN" -p "$prompt" \
          --dangerously-skip-permissions >> "$proj/.autonomous.log" 2>&1 & echo $! > "$pid_file" )
      mode="fresh"
    fi
    echo "$now" > "$last_file"
    echo "$today $(( cap_n + 1 ))" > "$count_file"
    echo "$now $hb_sid" > "$hb_file"   # refresh so we don't relaunch again next tick
    log "RELAUNCH $proj ($mode, stale ${age}s, $(( cap_n + 1 ))/$DAILY_CAP today, pid $(cat "$pid_file"))"
  done < "$REGISTRY"
  mv "$tmp_reg" "$REGISTRY" 2>/dev/null || rm -f "$tmp_reg"
fi

# ============================ (B) TEAM REAPER ============================
# Archive teams with no file activity for > REAP_MIN minutes (spawned & forgotten).
if [ -d "$TEAMS_DIR" ]; then
  reap_age=$(( REAP_MIN * 60 ))
  for team_path in "$TEAMS_DIR"/*/; do
    name=$(basename "$team_path")
    [ "$name" = "_archived" ] && continue
    # Newest mtime across team dir + its task list.
    newest=$(find "$team_path" "$TASKS_DIR/$name" -type f -exec stat -f '%m' {} \; 2>/dev/null | sort -rn | head -1)
    [ -z "$newest" ] && newest=0
    if [ $(( now - newest )) -gt "$reap_age" ]; then
      dest="$ARCHIVE_DIR/${name}-$(date +%Y-%m-%d_%H%M)"
      mkdir -p "$dest"
      mv "$team_path" "$dest/team" 2>/dev/null
      [ -d "$TASKS_DIR/$name" ] && mv "$TASKS_DIR/$name" "$dest/tasks" 2>/dev/null
      log "REAPED team '$name' (idle $(( (now - newest) / 60 ))min) → $dest"
    fi
  done
fi
exit 0
