#!/usr/bin/env node
// Stop hook — AUTONOMOUS LOOP DRIVER (Layer-4 enforcement of AUTONOMOUS OPERATION).
//
// PROBLEM this solves: a Claude session ENDS its turn and waits for the user by
// default. Prompt rules (Layer 1, in CLAUDE.md) cannot reliably keep it looping —
// the model yields when it thinks it took a step. Teammates in Agent Teams go idle
// after their turn and only wake on an inbound SendMessage; if the orchestrator
// also yields, everyone waits for a ping. This hook keeps an autonomous session
// driving by BLOCKING the stop and re-injecting the loop directive — until the
// work is genuinely done or a stop-and-ask condition is hit.
//
// OFF BY DEFAULT. Supervised sessions are never affected. Activates only when an
// autonomous marker is present:
//   - <cwd>/.autonomous              (project / worktree scoped) , or
//   - ~/.claude/.autonomous-active   (global, all sessions)
// Toggle:  touch .autonomous   /   rm .autonomous
//
// ESCAPE: the agent stops cleanly by emitting a line starting with
//   AUTONOMOUS-HALT: <reason>
// (genuinely complete, or a stop-and-ask condition). The hook then allows the stop.
//
// CIRCUIT BREAKERS (always on, prevent runaway cost):
//   - MAX_LOOPS consecutive auto-continues per session
//   - STALL_LIMIT consecutive stops with no git change (no progress)

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

const MAX_LOOPS = 40;     // hard ceiling of auto-continues per session
const STALL_LIMIT = 5;    // consecutive no-git-change stops → halt (research/planning
                          // loops legitimately produce no commits for a few turns;
                          // git status --porcelain already counts uncommitted edits)

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 10000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => (input += c));
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    main(JSON.parse(input || '{}'));
  } catch {
    process.exit(0); // never block a stop on hook error
  }
});

function allow() { process.exit(0); }              // emit nothing → stop proceeds
function block(reason) {
  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
  process.exit(0);
}

function main(data) {
  const cwd = data.cwd || process.cwd();

  // --- activation gate -----------------------------------------------------
  const projMarker = path.join(cwd, '.autonomous');
  const globalMarker = path.join(os.homedir(), '.claude', '.autonomous-active');
  const active = safeExists(projMarker) || safeExists(globalMarker);
  if (!active) allow(); // normal supervised session — let it stop

  // Liveness heartbeat: "<epoch_seconds> <session_id>". PostToolUse refreshes it
  // continuously; this Stop-time write also records the session id so the watchdog
  // can RESUME the same conversation (claude -p --resume <id>) after a crash.
  try {
    const sid = data.session_id || '';
    fs.writeFileSync(path.join(cwd, '.autonomous-heartbeat'), Math.floor(Date.now() / 1000) + ' ' + sid);
  } catch {}

  // --- escape: agent signalled a clean halt --------------------------------
  if (lastMessageHasHalt(data.transcript_path)) allow();

  // --- circuit-breaker state ----------------------------------------------
  const sid = String(data.session_id || 'nosession').replace(/[^a-zA-Z0-9_-]/g, '_');
  const stateFile = path.join(os.tmpdir(), `claude-auto-${sid}.json`);
  let st = readJSON(stateFile) || { loops: 0, stall: 0, sig: null };

  const sig = gitSignature(cwd);
  st.stall = sig !== null && sig === st.sig ? st.stall + 1 : 0;
  st.sig = sig;
  st.loops += 1;

  if (st.loops > MAX_LOOPS) {
    writeJSON(stateFile, { loops: 0, stall: 0, sig });
    allow(); // ceiling hit — yield to the user
  }
  if (st.stall >= STALL_LIMIT) {
    writeJSON(stateFile, { loops: 0, stall: 0, sig });
    block(
      `AUTONOMOUS DRIVER: no file/git changes across ${STALL_LIMIT} loops — possible spin. ` +
      `Take a DIFFERENT concrete action (new task from the backlog/TaskList), or, if work is ` +
      `genuinely complete or blocked, emit a line "AUTONOMOUS-HALT: <reason>" to stop.`
    );
  }

  writeJSON(stateFile, st);

  // --- the loop directive --------------------------------------------------
  block(
    'AUTONOMOUS MODE — do NOT stop to wait for a ping. Continue the self-driving loop NOW:\n' +
    '1. ORIENT — re-read .planning/STATE.md / shared TaskList / backlog.\n' +
    '2. TEAM HEALTH (if you are the orchestrator) — you are the resurrection layer for teammates ' +
    '(the watchdog cannot relaunch in-harness teammates, only you). Check the shared TaskList: any task ' +
    'claimed but stale, or a teammate idle/unresponsive after a ping → RE-DISPATCH it or re-spawn that ' +
    'archetype. TeamDelete teams whose work is finished — never leave idle teammates accumulating.\n' +
    '3. PRIORITIZE — security-first, then (Value×Reach)/Effort, then unblock-others. If teammate: claim the next UNCLAIMED task.\n' +
    '4. EXECUTE the next concrete unit: plan→build→verify→secure→ship, atomic commits.\n' +
    '5. RECORD to STATE.md, then keep looping.\n' +
    'Decide craft/technical choices YOURSELF (how to fix a model, which method, refactor approach, test design) — ' +
    'research, try, measure, iterate. Do NOT ask the user about anything you can resolve by investigation or experiment.\n' +
    'A rate limit / partial answer is NOT completion and NOT a halt — back off and continue. ' +
    'ONLY stop by writing a line that STARTS with "AUTONOMOUS-HALT:" and ONLY when ' +
    '(a) all roadmap/backlog work is genuinely complete, or (b) a TRUE user-only condition: ' +
    'security trade-off you cannot resolve safely, irreversible deletion of code you did not write, ' +
    'public-API/contract change other services depend on, business DIRECTION not derivable from code/docs, budget exceeded. ' +
    'On low context: checkpoint to STATE.md → /compact → continue.'
  );
}

// ---- helpers --------------------------------------------------------------
function safeExists(p) { try { return fs.existsSync(p); } catch { return false; } }
function readJSON(p) { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; } }
function writeJSON(p, o) { try { fs.writeFileSync(p, JSON.stringify(o)); } catch {} }

function gitSignature(cwd) {
  try {
    const head = execSync('git rev-parse HEAD', { cwd, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString().trim();
    const dirty = execSync('git status --porcelain', { cwd, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString();
    // hash the dirty listing cheaply (length + last-mod count) to detect any change
    return head + ':' + dirty.length + ':' + dirty.split('\n').length;
  } catch {
    return null; // not a git repo → stall detection disabled (rely on MAX_LOOPS)
  }
}

// Read the tail of the transcript JSONL and check whether the most recent
// assistant text contains the AUTONOMOUS-HALT escape token.
function lastMessageHasHalt(transcriptPath) {
  if (!transcriptPath || !safeExists(transcriptPath)) return false;
  let text = '';
  try { text = fs.readFileSync(transcriptPath, 'utf8'); } catch { return false; }
  const lines = text.trim().split('\n');
  // scan from the end, find the last assistant message, inspect its text
  for (let i = lines.length - 1, seen = 0; i >= 0 && seen < 40; i--, seen++) {
    let obj;
    try { obj = JSON.parse(lines[i]); } catch { continue; }
    const role = obj.role || (obj.message && obj.message.role) || obj.type;
    if (role !== 'assistant') continue;
    const content = (obj.message && obj.message.content) || obj.content;
    let s = '';
    if (typeof content === 'string') s = content;
    else if (Array.isArray(content)) s = content.map(b => (typeof b === 'string' ? b : b.text || '')).join('\n');
    if (/AUTONOMOUS-HALT:/.test(s)) return true;
    return false; // only the latest assistant message matters
  }
  return false;
}
