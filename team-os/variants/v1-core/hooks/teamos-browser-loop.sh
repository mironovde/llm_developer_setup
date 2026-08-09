#!/usr/bin/env bash
# Helper for the browser edit-test loop protocol (not a hook itself; called by the browser-loop skill).
# Commands:
#   open "<task>"            — start a loop (creates marker with required proofs)
#   prove <key> <value>      — record a proof (build_marker|test_pass|console_clean|screenshot)
#   status                   — show current marker
#   close                    — verify all proofs and close the loop (exit 1 if incomplete)
set -euo pipefail

# Artifacts live in .artifacts/ (this config keeps no team/ state layer). An existing
# team/artifacts/ upward is honoured so the helper also works inside older projects.
find_artifacts() {
  local d="$PWD"
  for _ in 1 2 3 4 5; do
    if [ -d "$d/team/artifacts" ]; then printf '%s' "$d/team/artifacts"; return 0; fi
    if [ -d "$d/.artifacts" ] || [ -f "$d/package.json" ] || [ -d "$d/.git" ]; then
      printf '%s' "$d/.artifacts"; return 0
    fi
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done
  printf '%s' "$PWD/.artifacts"
}

ART="$(find_artifacts)"
mkdir -p "$ART"
MARKER="$ART/.browser-loop.json"
REQUIRED='["build_marker","test_pass","console_clean","screenshot"]'

case "${1:-}" in
  open)
    TASK="${2:-unnamed}"
    jq -n --arg task "$TASK" --argjson req "$REQUIRED" \
      '{task: $task, opened_epoch: (now|floor), requires: $req, proofs: {}, blocks: 0}' > "$MARKER"
    echo "browser-loop OPEN for: $TASK"
    echo "Required proofs before any stop/done: build_marker, test_pass, console_clean, screenshot."
    ;;
  prove)
    KEY="${2:?prove needs a key}"
    VAL="${3:?prove needs a value or path}"
    [ -f "$MARKER" ] || { echo "no open browser-loop (run: open)" >&2; exit 1; }
    if ! printf '%s' "$REQUIRED" | jq -e --arg k "$KEY" 'index($k) != null' >/dev/null; then
      echo "unknown proof key '$KEY' (valid: build_marker test_pass console_clean screenshot)" >&2; exit 1
    fi
    if [ "$KEY" = "screenshot" ] && [ ! -f "$VAL" ]; then
      echo "screenshot proof must be an existing file path, got: $VAL" >&2; exit 1
    fi
    TMP="$(mktemp)"
    jq --arg k "$KEY" --arg v "$VAL" '.proofs[$k] = $v' "$MARKER" > "$TMP" && mv "$TMP" "$MARKER"
    echo "proof recorded: $KEY = $VAL"
    ;;
  status)
    [ -f "$MARKER" ] && jq . "$MARKER" || echo "no open browser-loop"
    ;;
  close)
    [ -f "$MARKER" ] || { echo "no open browser-loop"; exit 0; }
    MISSING="$(jq -r '[.requires[] as $r | select((.proofs[$r] // "") == "") | $r] | join(", ")' "$MARKER")"
    if [ -n "$MISSING" ]; then
      echo "cannot close: missing proofs: $MISSING" >&2
      exit 1
    fi
    echo "browser-loop CLOSED. Proofs:"
    jq -r '.proofs | to_entries[] | "  \(.key): \(.value)"' "$MARKER"
    rm -f "$MARKER"
    ;;
  *)
    echo "usage: teamos-browser-loop.sh open \"task\" | prove <key> <value> | status | close" >&2
    exit 1
    ;;
esac
