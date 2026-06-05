---
description: Show the current delegation backend and status
---

# Delegate Status

Show current delegation status.

## Process

1. **Config**: Read and display the active backend from `~/.config/claude-code/delegate.yaml`:
   ```bash
   python3 -c "
   try:
       import yaml
   except ImportError:
       print('  ERROR: pyyaml not installed. Run: pip install pyyaml')
       raise SystemExit(1)
   import os
   from shutil import which
   path = os.path.expanduser('~/.config/claude-code/delegate.yaml')
   if not os.path.exists(path):
       print('  No config found at', path)
       raise SystemExit(0)
   with open(path) as f:
       cfg = yaml.safe_load(f)
   backends = sorted(
       [b for b in cfg.get('backends', []) if b.get('enabled')],
       key=lambda b: b.get('priority', 99)
   )
   for b in backends:
       status = '✓ installed' if which(b['command']) else '✗ not found'
       active = ' ← active' if which(b['command']) and not any(
           which(x['command']) for x in backends if x['priority'] < b['priority']
       ) else ''
       print(f\"  {b['name']} (priority {b['priority']}): {b.get('model', 'default')} [{status}]{active}\")
   "
   ```

2. **Auto-mode**: Check if `.claude/delegate-auto` exists in the project root.

3. **Recent runs**: Show last 5 entries from the log:
   ```bash
   tail -5 ~/.local/share/claude-code/delegate-runs.jsonl 2>/dev/null | python3 -c "
   import sys, json
   for line in sys.stdin:
       e = json.loads(line)
       status = '✓' if e['exit_code'] == 0 else '✗'
       print(f\"  {status} {e['timestamp'][:16]} | {e['backend']} | {e['duration_secs']}s | {e['files_changed']} files\")
   " 2>/dev/null || echo "  (no runs yet)"
   ```

4. Present the information clearly to the user.
