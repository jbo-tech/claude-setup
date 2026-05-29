#!/usr/bin/env bash
set -euo pipefail

# Parse flags (position-independent)
BACKEND_OVERRIDE=""
TASK_OVERRIDE=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) BACKEND_OVERRIDE="$2"; shift 2 ;;
    --task)    TASK_OVERRIDE="$2";    shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

WORKDIR="${1:-.}"
PROMPT="${2:?Usage: delegate.sh [--backend <name>] [--task <type>] <workdir> <prompt> [timeout]}"
TIMEOUT="${3:-}"

CONFIG="${DELEGATE_CONFIG:-$HOME/.config/claude-code/delegate.yaml}"
DEFAULT_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/config/delegate.yaml"

if [ ! -f "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  cp "$DEFAULT_CONFIG" "$CONFIG"
  echo "[delegate] Config created at $CONFIG"
fi

# Write prompt to temp file (avoids shell injection through sed/bash -c)
PROMPT_FILE=$(mktemp /tmp/delegate-prompt.XXXXXX)
trap 'rm -f "$PROMPT_FILE"' EXIT
printf '%s' "$PROMPT" > "$PROMPT_FILE"

# Parse YAML config — select backend by priority, task, or name override
CONFIG_OUT=$(python3 -c "
import yaml, sys, os
from shutil import which
from shlex import quote

with open(os.path.expanduser('$CONFIG')) as f:
    cfg = yaml.safe_load(f) or {}

override = '$BACKEND_OVERRIDE'
task = '$TASK_OVERRIDE'
backends = sorted(
    [b for b in cfg.get('backends', []) if b.get('enabled')],
    key=lambda b: b.get('priority', 99)
)
s = cfg.get('settings', {})
print(f\"DEFAULT_TIMEOUT={s.get('default_timeout', 120)}\")
print(f\"LOG_FILE={quote(s.get('log_file', '~/.local/share/claude-code/delegate-runs.jsonl'))}\")

if override:
    candidates = [b for b in backends if b['name'] == override]
    err_label = f'Backend {override!r} not found or not installed'
elif task:
    task_specific = [b for b in backends if b.get('task') == task]
    candidates = task_specific if task_specific else [b for b in backends if not b.get('task')]
    err_label = f'No backend found for task {task!r}'
else:
    candidates = [b for b in backends if not b.get('task')]
    err_label = 'No enabled backend found in PATH'

for b in candidates:
    if which(b['command']):
        for k in ('name','command','args','workdir_flag','model'):
            print(f\"{k.upper()}={quote(str(b.get(k, '')))}\")
        default_flag = '' if b.get('command') == 'vibe' else '--model'
        print(f\"MODEL_FLAG={quote(b.get('model_flag', default_flag))}\")
        print(f\"NEEDS_PTY={int(b.get('needs_pty', False))}\")
        sys.exit(0)

print(f'[delegate] ERROR: {err_label}.', file=sys.stderr)
sys.exit(1)
") || exit 1
eval "$CONFIG_OUT"

TIMEOUT="${TIMEOUT:-$DEFAULT_TIMEOUT}"
LOG_FILE="$(eval echo "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Build command — {prompt_file} and {timeout} are replaced with safe values
CMD_ARGS=$(echo "$ARGS" | sed "s|{prompt_file}|$PROMPT_FILE|g; s|{timeout}|$TIMEOUT|g")
CMD="$COMMAND $CMD_ARGS"
[ -n "$WORKDIR_FLAG" ] && CMD="$CMD $WORKDIR_FLAG $WORKDIR"
if [ -n "$MODEL" ] && [ -n "$MODEL_FLAG" ]; then
  CMD="$CMD $MODEL_FLAG $MODEL"
elif [ -n "$MODEL" ]; then
  export VIBE_ACTIVE_MODEL="$MODEL"
fi

echo "[delegate] Backend: $NAME | Model: ${MODEL:-default} | Task: ${TASK_OVERRIDE:-default} | Timeout: ${TIMEOUT}s"
echo "[delegate] Workdir: $WORKDIR"
echo "[delegate] Running..."

START_TIME=$(date +%s)
EXIT_CODE=0
if [ "$NEEDS_PTY" -eq 1 ]; then
  script -q -c "cd $WORKDIR && timeout $TIMEOUT $CMD" /dev/null 2>&1 || EXIT_CODE=$?
else
  (cd "$WORKDIR" && timeout "$TIMEOUT" bash -c "$CMD") 2>&1 || EXIT_CODE=$?
fi
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

DIFF_STAT=$(cd "$WORKDIR" && git diff --stat 2>/dev/null || echo "(not a git repo)")
FILES_CHANGED=$(cd "$WORKDIR" && git diff --name-only 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "[delegate] Exit code: $EXIT_CODE | Duration: ${DURATION}s | Files changed: $FILES_CHANGED"
echo "$DIFF_STAT"

python3 -c "
import json, datetime
with open('$LOG_FILE', 'a') as f:
    f.write(json.dumps({
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
        'backend': '$NAME', 'model': '$MODEL' or None, 'task': '$TASK_OVERRIDE' or None,
        'duration_secs': $DURATION, 'exit_code': $EXIT_CODE,
        'files_changed': $FILES_CHANGED, 'workdir': '$WORKDIR'
    }) + '\n')
"
echo "[delegate] Logged to $LOG_FILE"
