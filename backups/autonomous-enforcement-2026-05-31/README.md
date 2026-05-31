# Autonomous Enforcement Layer (2026-05-31)

L4 mechanisms that make AUTONOMOUS OPERATION actually work (prompt alone fails).

| File | Hook/role | Purpose |
|------|-----------|---------|
| `hooks/gsd-autonomous-driver.js` | `Stop` | Blocks turn-end while marker `.autonomous` present → re-injects loop. Breakers: 40 loops, no-git-change×3, `AUTONOMOUS-HALT:` escape. Writes heartbeat. |
| `hooks/gsd-autonomous-watchdog.sh` | launchd /120s | Stale heartbeat (>180s) → relaunch `claude -p` (rate-limit/crash resurrection). Breakers: PID-lock, 180s gap, 30/day cap. |
| `hooks/gsd-cross-project-guard.sh` | `PreToolUse(Bash)` | DENY destructive cmds against foreign projects / shared state (teams, tasks, memory, /tmp/claude-*, caches). |
| `hooks/gsd-team-archive.sh` | `SessionStart` | Archive orphaned teams idle >14d (mtime-based, reversible). |
| `scripts/claude-autonomous` | CLI | `on/off/status` — marker + watchdog registry. Symlinked to ~/.local/bin. |
| `launchd/com.claude.autonomous-watchdog.plist` | launchd | runs watchdog every 120s. |

Install: copy hooks/scripts to ~/.claude/, plist to ~/Library/LaunchAgents/ + `launchctl load`,
register Stop + PreToolUse(Bash) in settings.json. OFF by default (marker-gated).
