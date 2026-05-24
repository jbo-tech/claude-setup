# Delegate On

Enable auto-delegation for this project. All implementation tasks will be delegated automatically.

## Process

1. Create the auto-mode marker:
   ```bash
   touch .claude/delegate-auto
   ```

2. Verify `.claude/delegate-auto` is in the project's `.gitignore`. If not, warn the user.

3. Confirm: "Auto-delegation enabled for this project. All implementation tasks will be delegated. Use `/delegate-off` to disable."
