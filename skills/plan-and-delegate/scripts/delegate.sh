#!/usr/bin/env bash
# Run one task file through an external coding-agent CLI.
# Usage: delegate.sh --provider cursor|codex|gemini|agy --workdir DIR --task FILE [--model M] [--timeout SECS]
set -euo pipefail

provider=cursor workdir="" task="" model="" timeout_secs=1200
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) provider="$2"; shift 2 ;;
    --workdir)  workdir="$2"; shift 2 ;;
    --task)     task="$2"; shift 2 ;;
    --model)    model="$2"; shift 2 ;;
    --timeout)  timeout_secs="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$workdir" ]] || { echo "workdir not found: $workdir" >&2; exit 2; }
[[ -f "$task" ]]    || { echo "task file not found: $task" >&2; exit 2; }

log="${task%.md}.log"
prompt="You are implementing ONE task in an existing codebase. Follow the task spec exactly, \
mirror the referenced patterns, stay inside the listed files, do not commit, and do not add \
dependencies unless told to. Never start a dev server, watch mode, or any other command that keeps \
running (npm run dev, vite, next dev, --watch, ...): your run cannot finish while one is open, and the \
reviewer runs the app. When finished, briefly list the files you changed.

$(cat "$task")"

case "$provider" in
  cursor)
    command -v cursor-agent >/dev/null || { echo "cursor-agent not installed (https://cursor.com/cli)" >&2; exit 3; }
    cmd=(cursor-agent -p --force --trust --output-format text --workspace "$workdir")
    [[ -n "$model" ]] && cmd+=(--model "$model")
    cmd+=("$prompt") ;;
  codex)
    command -v codex >/dev/null || { echo "codex not installed (npm i -g @openai/codex)" >&2; exit 3; }
    cmd=(codex exec --full-auto --skip-git-repo-check -C "$workdir")
    [[ -n "$model" ]] && cmd+=(-m "$model")
    cmd+=("$prompt") ;;
  gemini)
    command -v gemini >/dev/null || { echo "gemini not installed (npm i -g @google/gemini-cli)" >&2; exit 3; }
    cmd=(gemini --yolo)
    [[ -n "$model" ]] && cmd+=(-m "$model")
    cmd+=(-p "$prompt") ;;
  agy)
    command -v agy >/dev/null || { echo "agy not installed" >&2; exit 3; }
    # File edits are auto-approved; terminal commands stay sandboxed. Claude runs verification.
    cmd=(agy --mode accept-edits --sandbox --output-format text)
    [[ -n "$model" ]] && cmd+=(--model "$model")
    # Headless agy aborts on any terminal command outside the user's agy allowlist, which differs per machine,
    # so the implementer works through file tools only.
    cmd+=(-p "$prompt

## No terminal commands
Do not run any terminal commands; any command outside the local allowlist ends your whole run with nothing saved. Use only your built-in file tools to list, read, search, create and edit files and directories. Don't install dependencies, build, run tests or start servers; the reviewer does that after you finish. Add any new dependency by editing the project's manifest (package.json, pyproject.toml, ...).") ;;
  *) echo "Unknown provider: $provider" >&2; exit 2 ;;
esac

echo "[delegate] provider=$provider model=${model:-default} task=$(basename "$task") log=$log"
start=$(date +%s)

# Portable timeout (macOS has no `timeout` by default).
set +e
# Job control gives the implementer its own process group, so killing -$pid also stops whatever it
# started (dev servers, watchers), not just the CLI itself. stdin is /dev/null because a background
# process group that reads the terminal gets stopped (SIGTTIN); prompts are passed as arguments.
set -m
( cd "$workdir" && "${cmd[@]}" ) </dev/null >"$log" 2>&1 &
pid=$!
set +m
# The watchdog must not hold our stdout: a leftover `sleep` keeps the caller's pipe open until the timeout.
( sleep "$timeout_secs" && kill -TERM -- -"$pid" 2>/dev/null && echo "[delegate] TIMEOUT after ${timeout_secs}s" >>"$log" ) >/dev/null 2>&1 &
watchdog=$!
wait "$pid"; status=$?
pkill -P "$watchdog" 2>/dev/null; kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null
# Stop anything the implementer left running after it exited, e.g. a dev server still holding a port.
kill -TERM -- -"$pid" 2>/dev/null
set -e

echo "[delegate] exit=$status in $(( $(date +%s) - start ))s — last 40 lines:"
tail -n 40 "$log"
exit "$status"
