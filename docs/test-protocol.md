# Test protocol — claude-setup

This repo has **no test suite** — that was the v1 scope decision, and it still holds. Everything
here is verified by a person. This document is that verification layer: what to run, in what order,
and what to look at.

It is written to be used **away from a Claude Code session**, with your hands on the keyboard.
Everything you need during a run is below; nothing sends you to another document mid-step.

Two levels: **A** needs only a shell and runs in a minute; **B** needs a live session, an external
backend, or your own eyes. **C** is the status table — what is actually proven today. Start there
if you only have a minute.

All commands assume you are at the repo root (`cd ~/Wip/coding/claude-setup`). Traces are written to
`/tmp/cs-check/`; create it once with `mkdir -p /tmp/cs-check`.

---

## Prerequisites

The framework is installed by symlink, so the repo **is** the live copy:

```bash
./install.sh --dry-run     # always safe; shows what would change
./install.sh               # links claude/* into ~/.claude/, copies delegate.yaml
```

Three traps that have each cost a session:

- **Editing through `~/.claude/<file>` edits the repo file.** They are the same inode. This is the
  point of the design, and it also means an external installer writing to `~/.claude/` produces
  diffs in this repo that nobody here authored.
- **`install.sh` runs under `set -euo pipefail`.** A function whose last statement is
  `[ cond ] && cmd` returns non-zero when the condition is false and kills the script silently. Use
  `if/then` at a function tail.
- **`delegate.yaml` is a copy, not a symlink.** Editing the repo does not change the live config,
  and editing the live config does not come back. §A.2 exists because of this.

---

## A. Verifiable alone — shell only, no session

### A.1 Installation parity — does the installed tree match the repo?

This is the check that matters most, because nothing else performs it. It runs in both directions.

```bash
mkdir -p /tmp/cs-check

# (a) Repo files that are NOT linked into ~/.claude — an install that never ran
for f in claude/commands/*.md claude/agents/*.md claude/scripts/*; do
  [ -f "$f" ] || continue                      # skips __pycache__, which is not linked and should not be
  t="$HOME/.claude/${f#claude/}"
  [ -L "$t" ] || echo "NOT LINKED: $f"
done | tee /tmp/cs-check/parity-missing.txt

# (b) Personal artifacts living in ~/.claude but NOT in the repo — unversioned, lost on a rebuild
find "$HOME/.claude/commands" "$HOME/.claude/agents" -maxdepth 1 -type f \
  | sort | tee /tmp/cs-check/parity-strays.txt
```

**What to look at.** `(a)` must be empty. `(b)` must contain **only** third-party files — today that
means `penpot-*.md`, shipped by the Penpot AI kit. Any other plain file is a personal command or
agent that git has never seen: `install.sh` will not link it, and a machine change loses it.

> **Known open finding (2026-09-17):** `(b)` returns four personal commands —
> `worktree-setup`, `worktree-merge`, `git-pr`, `history`. They work and appear in the slash menu;
> they are simply not in the repo. The fix is to move the file into `claude/commands/`, re-run
> `install.sh`, then re-run this check and see it become a symlink — `decompose` went through
> exactly that on 2026-09-17 and is no longer in the list. Not yet arbitrated: whether the
> remaining four are wanted. See `reference.md` → Drift.

*Traces:* `/tmp/cs-check/parity-missing.txt`, `/tmp/cs-check/parity-strays.txt`

### A.2 `delegate.yaml` — has the copy diverged?

```bash
diff -u claude/config/delegate.yaml ~/.config/claude-code/delegate.yaml \
  | tee /tmp/cs-check/delegate-yaml.diff
```

**What to look at.** Empty output is the pass. Any hunk means the two have separated — and the
**installed side is usually the one that is ahead**, because that is the file you edit when you want
a different model today. The risk runs in the direction people don't expect: a fresh install on a new
machine overwrites the live config with the repo's older version.

> **Known open finding (2026-09-17):** they have diverged. The installed copy swaps the `vibe` /
> `opencode` priorities, re-points three models (`qwen3.7-max`, `kimi-k2.7-code`, `glm-5.2`) and adds
> a backend the repo has never heard of (`opencode-archi`, `task: architecture`). Not yet arbitrated.

*Trace:* `/tmp/cs-check/delegate-yaml.diff`

### A.3 `settings.json` — is it still only about this repo?

This file is symlinked to `~/.claude/settings.json`, shared by **every** project, and this repo is
**public on GitHub**. Anything written at user level lands here.

```bash
python3 -c "import json;json.load(open('claude/settings.json'));print('valid JSON')"
grep -nE '/(home|Users)/[^"]*' claude/settings.json | grep -v 'claude-setup' \
  | tee /tmp/cs-check/settings-foreign-paths.txt
```

**What to look at.** The grep must return nothing. A path pointing at another project — or a block
describing another project's infrastructure — must be removed before any commit. It happened on
2026-09-16 (an `autoMode.environment` block describing a different repo) and was caught only because
someone read the diff.

*Trace:* `/tmp/cs-check/settings-foreign-paths.txt`

### A.4 Installer dry run

```bash
./install.sh --dry-run | tee /tmp/cs-check/install-dryrun.txt
```

**What to look at.** Three things, in this order: every repo file appears as a would-link line; the
`check_ruff` warning fires only if `ruff` is genuinely absent; and `check_skill_deps` warns about the
Penpot AI kit only if `~/.claude/skills/penpot-router` is missing. A warning is not a failure — the
installer is designed to warn and continue.

*Trace:* `/tmp/cs-check/install-dryrun.txt`

### A.5 Delegation history

```bash
~/.claude/scripts/delegate-status.py --days 90 | tee /tmp/cs-check/delegate-status.txt
```

**What to look at.** Cost, tokens and the per-backend breakdown come from each backend's own session
logs — this repo never computes pricing itself. Lines counted as *untracked* are pre-2026-06 runs
from before metrics existed; that is expected, not a bug. An `exit_code: 124` is a timeout.

*Trace:* `~/.local/share/claude-code/delegate-runs.jsonl` (the source), `/tmp/cs-check/delegate-status.txt`

---

## B. Needs a session, a backend, or your eyes

### B.1 Agent tool allowlists — **start a new session first**

The order is imposed: the agent listing is injected **at session start**, so a session already open
shows the state from when it began. Open a fresh one, then read the listing.

**What to look at.** Each of the six agents prints its real allowlist. `infra-expert` must show
`Read, Grep, Glob, Bash(docker:*)…` — **not** "All tools". `orchestrator` must have no `Write` and
no `Edit`.

This is the highest-value check in the document, and the only one that catches its bug class. A
subagent reads `tools:`; `allowed-tools:` is the field for skills and slash commands. An unrecognised
key is ignored **silently**, so an agent keeps every tool while its own body announces restraint.
That defect lived for six months and no test exists that would have caught it.

**No trace is possible** — the listing is not written anywhere on disk. This one is read with your
eyes. Verdict: `2026-08-29 — OK, all six show real allowlists`.

### B.2 Slash-command menu labels

Type `/` in a session and read the list.

**What to look at.** Each command shows its `description:` text. A command showing
`Document (User)` — its filename plus a scope label — has lost its front-matter. The scope suffix
itself is not removable; the description is what you control.

**No trace.** Eyes only. Verdict: `2026-06-05 — OK, all commands described`.

### B.3 Skill auto-routing

Skills load on relevance, not by name. Say a trigger phrase in a session — "review my Dockerfile"
for `infra-containers`, "create a skill" for `skill-factory` — and watch whether the skill loads.

**What to look at.** The skill announces itself. If nothing loads, the `description:` front-matter
is not carrying the vocabulary you actually use.

**No trace.** Eyes only. Verdict: _not recorded_.

### B.4 The ruff hook

`settings.json` registers a `PostToolUse` hook on `Write(*.py)`. It fires on the **tool**, not on a
shell command, so a `cat > file.py` will not trigger it — ask a session to write the file.

Have a session write a deliberately unformatted Python file (`import os` unused, `x=1` without
spaces), then:

```bash
cat <the file> | tee /tmp/cs-check/ruff-hook.txt
```

**What to look at.** The unused import is gone and the spacing is normalised. The hook ends in
`true`, so it can never fail a write — which also means a broken `ruff` is invisible here. `install.sh`
warns about that case separately (§A.4).

*Trace:* the file itself. Verdict: _not recorded_.

### B.5 Status line

```bash
echo '{}' | ~/.claude/scripts/statusline.py; echo "(exit $?)"
```

**What to look at.** A smoke test only — it should not traceback on empty input. The real check is
visual: the line at the bottom of a session shows context usage, the 5h/7d quotas and a minimal git
indicator.

*Trace:* stdout. Verdict: in daily use, unbroken.

### B.6 A real delegation, end to end

```bash
mkdir -p /tmp/deltest
~/.claude/scripts/delegate.sh --backend opencode /tmp/deltest "create hello.txt containing hello" 120
tail -1 ~/.local/share/claude-code/delegate-runs.jsonl | tee /tmp/cs-check/delegate-last-run.json
```

**What to look at.** Three things: the file actually exists in `/tmp/deltest`; the console prints a
`[delegate] Usage: $cost | N tokens` line; and the JSONL line carries non-null `cost` / `total_tokens`
/ `session_id`. All three matter — an `exit_code: 0` alone proves nothing, because a backend can
return success having done no work.

**Known traps.** `vibe` in programmatic mode (`-p`) is a no-op on this machine: zero tokens, zero
files, success. The two most recent logged runs (2026-07-11) are both `exit_code: 124` — timeouts at
the 120s default — with null metrics. Raise the timeout before concluding a backend is broken.

*Trace:* `~/.local/share/claude-code/delegate-runs.jsonl`

### B.7 `builder` and `orchestrator` — never exercised

```bash
claude --agent orchestrator
```

Give it a small, bounded implementation task and let it delegate to `builder`.

**What to look at.** Four claims, none of them yet observed: changes land in a **throwaway git
worktree**, not the main checkout; a Bash command redirecting git back into the main checkout is
refused; the report carries all five headings (`Done`, `Verified`, `Not done`, `Assumptions`,
`Noticed, not touched`); and at `maxTurns: 40` the output is marked partial and the agent can be
messaged to resume rather than being cut off.

*Trace:* the worktree itself (`git worktree list` during the run) and the returned report.
Verdict: **never run** — the first real delegation is also the first test.

### B.8 Penpot write-back scripts

Needs the Penpot AI kit installed (`~/.claude/skills/penpot-router`, present) **and** a real Penpot
file open in the plugin. Run each script through `execute_code`.

**What to look at.** Each returns JSON, which *is* the trace — no eyeballing needed.
`verifyPersistence.js` must be run as part A then part B **back to back in the same session**: it
carries its baseline through a `storage` object whose survival between separated calls has never been
measured. `verifyRemoval.js` settles failure mode #8 (`remove()` on a component descendant is
*reported* to hide rather than delete) by counting the parent's children, not by asking the shape
about itself.

*Trace:* the returned JSON. Verdict: seven of eight modes measured; #8 and the `storage` assumption
open.

### B.9 Uninstall

```bash
./uninstall.sh --dry-run | tee /tmp/cs-check/uninstall-dryrun.txt
```

**What to look at.** It reads `~/.claude/.claude-setup-manifest` (TSV: target, source, timestamp) and
lists only entries it created and that are untouched. A link you replaced by hand must be listed as
left alone.

**Stop at the dry run** unless you intend to actually uninstall. There is no recorded full run.

*Trace:* `/tmp/cs-check/uninstall-dryrun.txt`

---

## C. Status — what is actually proven today

| Path | Status | Where |
|---|---|---|
| Installation parity (repo ↔ `~/.claude`) | ⚠️ **fails today** — five unversioned commands | A.1 |
| `delegate.yaml` copy in sync | ⚠️ **fails today** — installed copy is ahead | A.2 |
| `settings.json` free of foreign paths | ✅ clean since 2026-09-16 (one incident, removed) | A.3 |
| Installer dry run + dependency warnings | ✅ exercised repeatedly | A.4 |
| Delegation history / cost aggregation | ✅ reads, 44 runs logged | A.5 |
| Agent `tools:` allowlists | ✅ 2026-08-29 — all six show real allowlists | B.1 |
| Slash-command menu labels | ✅ 2026-06-05 | B.2 |
| Skill auto-routing | ⬜ never formally checked | B.3 |
| ruff `PostToolUse` hook | ⬜ never formally checked | B.4 |
| `statusline.py` | ✅ in daily use | B.5 |
| Delegation end-to-end (`opencode`) | ✅ 2026-06-13; last two runs timed out at 120s | B.6 |
| Delegation end-to-end (`vibe -p`) | ❌ no-op on this machine — external, unfixed | B.6 |
| `builder` / `orchestrator` | ⬜ **never run** — written and committed 2026-08-29 | B.7 |
| Penpot failure modes #1–#7 | ✅ measured on a real file | B.8 |
| Penpot failure mode #8 | ⬜ reported, probe written, never run | B.8 |
| `verifyPersistence.js` `storage` survival | ⬜ unmeasured — run parts A and B back to back | B.8 |
| `uninstall.sh` | ⬜ dry run only, no recorded full run | B.9 |

✅ proven · ⚠️ currently failing · ⬜ wired but never exercised · ❌ known broken

**Write your verdict next to the step** when you run one of the ⬜ rows — date and outcome, one line.
The next `/document` reads this file before regenerating and carries your verdicts into this table.

---

## D. Reading the traces

| Trace | Written by | What it tells you |
|---|---|---|
| `/tmp/cs-check/parity-*.txt` | §A.1 | Left column empty = install ran. Right column beyond `penpot-*` = unversioned artifacts. |
| `/tmp/cs-check/delegate-yaml.diff` | §A.2 | Empty = in sync. Hunks = decide which side is intent before re-syncing. |
| `~/.local/share/claude-code/delegate-runs.jsonl` | `delegate.sh`, one line per run | `exit_code` 0 success · 124 timeout. Null `cost`/`tokens` = the backend exposed nothing, or the parser could not correlate. |
| `~/.claude/.claude-setup-manifest` | `install.sh` | TSV `target⇥source⇥timestamp`. The uninstall contract: only these entries, only if untouched. |
| Penpot script JSON | `execute_code` | `reason: "mixed-range"` = a sample was rejected, not a value read. `baselineLost: true` = part A's baseline did not reach part B. |

**Why `cost` can be null on a successful run.** `delegate-parse-session.py` correlates a run to a
backend session by *working directory + the most recent session at or after the run's start*. Two
delegations running concurrently in the same directory can be mis-attributed, and a backend that
writes no session log yields nothing at all. The parser is best-effort by design: it prints `{}` and
exits 0 rather than failing the run. A null metric is missing information, not a failed delegation.

---

*Owned and regenerated by `/document`. `reference.md` records **that** a path can only be verified by
hand; this file records **how**.*
