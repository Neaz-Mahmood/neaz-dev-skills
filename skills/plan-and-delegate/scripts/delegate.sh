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
dependencies unless told to. When finished, briefly list the files you changed.

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
    # Headless agy aborts on any terminal command outside its allowlist, so say what's allowed.
    cmd+=(-p "$prompt

## Terminal commands
Run each command on its own (no &&, pipes or redirects). Only these are allowed, and ANY other command ends your whole run with nothing saved: ls, cat, head, tail, wc, grep, rg, find, git status, git diff, git log, git grep, node -v, pnpm exec tsc --noEmit, pnpm lint, pnpm test, pnpm test:db, pnpm eval, pnpm db:generate, pnpm db:migrate. Do not run pnpm build or pnpm dev (the reviewer builds; an interrupted build corrupts .next). Create directories and files with your file-editing tools, never with mkdir or shell redirection.") ;;
  *) echo "Unknown provider: $provider" >&2; exit 2 ;;
esac

echo "[delegate] provider=$provider model=${model:-default} task=$(basename "$task") log=$log"
start=$(date +%s)

# Portable timeout (macOS has no `timeout` by default).
set +e
( cd "$workdir" && "${cmd[@]}" ) >"$log" 2>&1 &
pid=$!
# The watchdog must not hold our stdout: a leftover `sleep` keeps the caller's pipe open until the timeout.
( sleep "$timeout_secs" && kill "$pid" 2>/dev/null && echo "[delegate] TIMEOUT after ${timeout_secs}s" >>"$log" ) >/dev/null 2>&1 &
watchdog=$!
wait "$pid"; status=$?
pkill -P "$watchdog" 2>/dev/null; kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null
set -e

echo "[delegate] exit=$status in $(( $(date +%s) - start ))s — last 40 lines:"
tail -n 40 "$log"
exit "$status"
