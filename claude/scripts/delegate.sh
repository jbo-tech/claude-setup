#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-.}"
PROMPT="${2:?Usage: delegate.sh <workdir> <prompt> [timeout]}"
TIMEOUT="${3:-}"

CONFIG="${DELEGATE_CONFIG:-$HOME/.config/claude-code/delegate.yaml}"
DEFAULT_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/config/delegate.yaml"

# Generate default config if missing
if [ ! -f "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  cp "$DEFAULT_CONFIG" "$CONFIG"
  echo "[delegate] Config created at $CONFIG"
fi

# Parse YAML config with inline Python
read_config() {
  python3 -c "
import yaml, sys, os

with open(os.path.expanduser('$CONFIG')) as f:
    cfg = yaml.safe_load(f) or {}

backends = sorted(
    [b for b in cfg.get('backends', []) if b.get('enabled')],
    key=lambda b: b.get('priority', 99)
)

from shutil import which
from shlex import quote
for b in backends:
    if which(b['command']):
        print(f\"NAME={quote(b['name'])}\")
        print(f\"COMMAND={quote(b['command'])}\")
        print(f\"ARGS={quote(b.get('args', ''))}\")
        print(f\"WORKDIR_FLAG={quote(b.get('workdir_flag', ''))}\")
        print(f\"MODEL={quote(b.get('model', ''))}\")
        print(f\"MODEL_FLAG={quote(b.get('model_flag', ''))}\")
        print(f\"NEEDS_PTY={int(b.get('needs_pty', False))}\")
        sys.exit(0)

print('[delegate] ERROR: No enabled backend found in PATH.', file=sys.stderr)
print('[delegate] Install vibe (https://docs.mistral.ai) or opencode (https://opencode.ai)', file=sys.stderr)
sys.exit(1)
" || exit 1
}

read_settings() {
  python3 -c "
import yaml, os
from shlex import quote
with open(os.path.expanduser('$CONFIG')) as f:
    cfg = yaml.safe_load(f) or {}
s = cfg.get('settings', {})
print(f\"DEFAULT_TIMEOUT={s.get('default_timeout', 120)}\")
print(f\"LOG_FILE={quote(s.get('log_file', '~/.local/share/claude-code/delegate-runs.jsonl'))}\")
"
}

CONFIG_OUT=$(read_config) || exit 1
eval "$CONFIG_OUT"
eval "$(read_settings)"

TIMEOUT="${TIMEOUT:-$DEFAULT_TIMEOUT}"
LOG_FILE="$(eval echo "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Build the command — prompt is passed via DELEGATE_PROMPT env var to avoid quoting issues
export DELEGATE_PROMPT="$PROMPT"
CMD_ARGS=$(echo "$ARGS" | sed 's|{prompt}|"$DELEGATE_PROMPT"|g; s|{timeout}|'"$TIMEOUT"'|g')
CMD="$COMMAND $CMD_ARGS"

# Add workdir
[ -n "$WORKDIR_FLAG" ] && CMD="$CMD $WORKDIR_FLAG $WORKDIR"

# Add model
if [ -n "$MODEL" ]; then
  if [ -n "$MODEL_FLAG" ]; then
    CMD="$CMD $MODEL_FLAG $MODEL"
  else
    export VIBE_ACTIVE_MODEL="$MODEL"
  fi
fi

echo "[delegate] Backend: $NAME | Model: ${MODEL:-default} | Timeout: ${TIMEOUT}s"
echo "[delegate] Workdir: $WORKDIR"
echo "[delegate] Running..."

START_TIME=$(date +%s)

# Execute
EXIT_CODE=0
if [ "$NEEDS_PTY" -eq 1 ]; then
  script -q -c "cd $WORKDIR && timeout $TIMEOUT $CMD" /dev/null 2>&1 || EXIT_CODE=$?
else
  (cd "$WORKDIR" && timeout "$TIMEOUT" bash -c "$CMD") 2>&1 || EXIT_CODE=$?
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Capture git diff
DIFF_STAT=$(cd "$WORKDIR" && git diff --stat 2>/dev/null || echo "(not a git repo)")
FILES_CHANGED=$(cd "$WORKDIR" && git diff --name-only 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "[delegate] Exit code: $EXIT_CODE | Duration: ${DURATION}s"
echo "[delegate] Files changed: $FILES_CHANGED"
echo "$DIFF_STAT"

# Log to JSONL
python3 -c "
import json, datetime
entry = {
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
    'backend': '$NAME',
    'model': '$MODEL' or None,
    'duration_secs': $DURATION,
    'exit_code': $EXIT_CODE,
    'files_changed': $FILES_CHANGED,
    'workdir': '$WORKDIR'
}
with open('$LOG_FILE', 'a') as f:
    f.write(json.dumps(entry) + '\n')
"

echo "[delegate] Logged to $LOG_FILE"
