---
description: Disable auto-delegation for this project
---

# Delegate Off

Disable auto-delegation for this project.

## Process

1. Remove the auto-mode marker:
   ```bash
   rm -f .claude/delegate-auto
   ```

2. Confirm: "Auto-delegation disabled. Use `/delegate <instruction>` for explicit delegation, or `/delegate-on` to re-enable."
