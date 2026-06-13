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

# git status --short counts BOTH modified (tracked) and new (untracked) files.
# git diff alone misses files the agent created — they show as untracked.
DIFF_STAT=$(cd "$WORKDIR" && git status --short 2>/dev/null || echo "(not a git repo)")
FILES_CHANGED=$(cd "$WORKDIR" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "[delegate] Exit code: $EXIT_CODE | Duration: ${DURATION}s | Files changed: $FILES_CHANGED"
echo "$DIFF_STAT"

# Pull real usage metrics (tokens, cost, steps) from the backend's own session
# logs. Best-effort: the parser prints {} on any failure, so logging never breaks.
# Resolve symlinks first — this script is usually invoked via ~/.claude/scripts/
# symlink, so $0's dir is not where the parser sibling actually lives.
SCRIPT_REAL="$(readlink -f "$0" 2>/dev/null || echo "$0")"
PARSER="$(cd "$(dirname "$SCRIPT_REAL")" && pwd)/delegate-parse-session.py"
METRICS_JSON="{}"
if [ -f "$PARSER" ]; then
  METRICS_JSON=$(python3 "$PARSER" "$NAME" "$WORKDIR" "$START_TIME" 2>/dev/null || echo "{}")
fi

# Pass metrics + run facts through the environment (injection-safe — no values
# are interpolated into the Python source). The script writes one enriched
# JSONL line and prints a one-line usage summary.
DELEGATE_METRICS="$METRICS_JSON" \
DELEGATE_LOG_FILE="$LOG_FILE" \
DELEGATE_NAME="$NAME" \
DELEGATE_MODEL="$MODEL" \
DELEGATE_TASK="$TASK_OVERRIDE" \
DELEGATE_DURATION="$DURATION" \
DELEGATE_EXIT="$EXIT_CODE" \
DELEGATE_FILES="$FILES_CHANGED" \
DELEGATE_WORKDIR="$WORKDIR" \
python3 -c "
import json, datetime, os

def _num(env, cast):
    raw = os.environ.get(env, '')
    try:
        return cast(raw)
    except (TypeError, ValueError):
        return None

try:
    metrics = json.loads(os.environ.get('DELEGATE_METRICS', '{}'))
except Exception:
    metrics = {}

entry = {
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
    'backend': os.environ.get('DELEGATE_NAME') or None,
    'model': os.environ.get('DELEGATE_MODEL') or None,
    'task': os.environ.get('DELEGATE_TASK') or None,
    'duration_secs': _num('DELEGATE_DURATION', int),
    'exit_code': _num('DELEGATE_EXIT', int),
    'files_changed': _num('DELEGATE_FILES', int),
    'workdir': os.environ.get('DELEGATE_WORKDIR') or None,
    # Native backend metrics (None when parsing found nothing).
    'input_tokens': metrics.get('input_tokens'),
    'output_tokens': metrics.get('output_tokens'),
    'total_tokens': metrics.get('total_tokens'),
    'cost': metrics.get('cost'),
    'steps': metrics.get('steps'),
    'session_id': metrics.get('session_id'),
    'session_dir': metrics.get('session_dir'),
}

with open(os.environ['DELEGATE_LOG_FILE'], 'a') as f:
    f.write(json.dumps(entry) + '\n')

# Surface the cost in the run output too.
cost, tok = metrics.get('cost'), metrics.get('total_tokens')
if cost is not None or tok is not None:
    parts = []
    if cost is not None:
        parts.append(f'\${cost:.4f}')
    if tok is not None:
        parts.append(f'{tok} tokens')
    print('[delegate] Usage: ' + ' | '.join(parts))
else:
    print('[delegate] Usage: not available for this backend/run')
"
echo "[delegate] Logged to $LOG_FILE"
