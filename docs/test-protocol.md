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

> **Settled 2026-09-17:** `(b)` used to return five personal commands. All are now in the repo and
> linked, so `(b)` should return **only** the six third-party `penpot-*.md`. Anything else in that
> list is a new stray — move it into `claude/commands/`, re-run `install.sh`, re-run this check and
> confirm it became a symlink.

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

### A.3b Hooks — do they actually fire?

A hook is a declaration, and this repo has now been bitten three times by a declaration that is
never executed. `settings.json` shipped `"matcher": "Write(*.py)"` for two months: a *path pattern*
in a field that matches **tool names**. It matched nothing. The hook never ran once, while
`README.md` advertised automatic Python formatting and `install.sh` warned when `ruff` was missing.

Two checks. The first is shape, the second is behaviour — only the second proves anything.

```bash
# (a) the matcher is a tool-name pattern, and the command survives the payload it will receive
jq -r '.hooks.PostToolUse[] | "\(.matcher)\t\(.hooks[].command)"' claude/settings.json

printf 'x = {  "a":1 }\ndef  f( a ):\n    return   a\n' > /tmp/cs-check/hook-probe.py
echo '{"tool_input":{"file_path":"/tmp/cs-check/hook-probe.py"}}' \
  | jq -r '(.tool_response.filePath // .tool_input.file_path) // empty' \
  | while read -r f; do case "$f" in *.py) ruff check --fix --quiet "$f"; ruff format --quiet "$f";; esac; done
cat /tmp/cs-check/hook-probe.py
```

**What to look at.** `(a)` must print a matcher made of tool names (`Write|Edit`), never a
parenthesised path pattern — and the probe file must come back reformatted (`x = {"a": 1}`). If it
does not, the command is broken regardless of the matcher.

**(b) The real proof needs a session** — the pipe test above only shows the command works, not that
Claude Code runs it. In a session, write a misformatted `.py` file with the Write tool and read it
back. It must come back formatted. This is the only check that covers the whole path, and it is why
this step also appears in §B.

*Trace:* `/tmp/cs-check/hook-probe.py`

### A.3c Skill listing — is it still inside its budget, and does every frontmatter parse?

Claude Code loads a listing of skill names and descriptions capped at **1% of the context window**
(~8 000 characters). On overflow it drops descriptions **starting with the skills you invoke least**
— silently removing the keywords it needs to match a request. Two failures hide here, and neither
announces itself.

```bash
mkdir -p /tmp/cs-check
python3 - <<'EOF' | tee /tmp/cs-check/skill-listing.txt
import pathlib, re, json, yaml
ov = json.load(open(pathlib.Path.home()/".claude/settings.json")).get("skillOverrides", {})
eff = hidden = 0; bad = []
for d in sorted((pathlib.Path.home()/".claude/skills").iterdir()):
    f = d/"SKILL.md"
    if not f.is_file(): continue
    t = f.read_text(errors="replace")
    m = re.match(r'^---\s*\n(.*?)\n---', t, re.S)
    if not m: bad.append((d.name, "no frontmatter")); continue
    try: yaml.safe_load(m.group(1))
    except Exception as e: bad.append((d.name, str(e).split(chr(10))[0][:60]))
    n = 0
    for k in ("description","when_to_use"):
        mm = re.search(rf'^{k}:\s*(.*(?:\n(?![a-z_-]+:).*)*)', m.group(1), re.M)
        if mm: n += len(mm.group(1))
    if ov.get(d.name) == "name-only": hidden += n
    else: eff += n
print(f"effective: {eff} chars -> x{eff/8000:.2f} of budget")
print(f"hidden by name-only: {hidden} chars")
print(f"frontmatter that does NOT parse: {len(bad)}")
for n_, e in bad: print(f"  {n_}: {e}")
EOF
```

**What to look at.** `x…` must stay below 1.00. `frontmatter that does NOT parse` must be 0 — a
SKILL.md whose YAML is invalid still loads, but with **every field dropped**: `paths`,
`allowed-tools` and `model` stop applying and the description falls back to the first line of the
body. The usual cause is a `: ` inside a description value, which turns the block into a mapping.

⚠ **`claude plugin validate` does not catch this** — measured 2026-09-30: it reported ✔ passed on a
file whose frontmatter a strict YAML reader rejects. Use the check above, not that command.

**Run this after every Penpot AI kit update.** The kit rewrites `~/.claude/skills/penpot-*` and can
add or rename skills; a new one is not in `skillOverrides` and silently takes a full description
back. The kit itself never touches that key (verified in `scripts/install/uninstall.mjs` and
`INSTALL.md`: it reads `settings.json` only for an optional `SessionStart` hook, and refuses even to
remove that automatically) — so the setting survives install, update, `--prune` and uninstall. It is
the skill *inventory* that moves, not the setting.

*Trace:* `/tmp/cs-check/skill-listing.txt`

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

### A.6 Defect extraction — does the learning loop have an input?

`/retro` §7 step 1 runs this before anything subjective. Run it yourself to see what it would feed.

```bash
python3 ~/.claude/scripts/extract-defects.py --days 30 | tee /tmp/cs-check/defects.txt
```

**What to look at.** Three sections — failed spawns, repeated tasks, failed delegations — and a
summary. `session files read: 0` means the project slug did not resolve; check that
`~/.claude/projects/<cwd with / replaced by ->` exists. An empty report is a valid answer for a
quiet project; it is not proof the script works. To prove that, point it at a transcript you know
contains a failure:

```bash
python3 ~/.claude/scripts/extract-defects.py ~/.claude/projects/<some-project>/<session>.jsonl
```

**Its blind spot, by design.** A background subagent leaves only a launch acknowledgement in the
transcript, so its real failure is invisible; it shows up indirectly as a respawned task. A wrong
answer accepted on the first try never appears at all. This is a net, not a blanket.

*Trace:* `/tmp/cs-check/defects.txt`

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

### B.3 Skill auto-routing — the bet the command pruning rests on

A command is invoked by name; a skill is loaded because its `description:` matched what you were
already talking about. Three commands were deleted in September **on the argument that the skills
fire on their own**. If that is false, the pruning did not simplify anything — it exchanged
something invocable for something invisible. This step is the only check that tests it.

**The precondition that makes or breaks this test: run it where the subject actually exists.** A
phrase about data leakage in a repo with no model routes nowhere — the session correctly answers
"there is nothing to leak here", which tells you nothing. **Two of the first three runs were wasted
this way, both because a hand-written terrain table in this file was wrong.** So do not trust a
table: derive the terrain, then type the phrase.

```bash
cd ~/Wip/coding
for pat in duckdb parquet qdrant docker-compose sqlite3 "SELECT .*FROM" idempot "\.fit(" nn.Module; do
  echo "--- $pat ---"
  for p in */; do
    c=$(grep -rlniE "$pat" "$p"src "$p"deploy 2>/dev/null | wc -l)
    [ "$c" -gt 0 ] && echo "  ${p%/}: $c files"
  done
done 2>/dev/null
```

Then pick a phrase whose subject the output says exists, and run it **in that repo**:

| Skill | Needs a project matching | Phrase to type (never name the skill) |
|---|---|---|
| `data-engineering` | `duckdb`, `parquet` or `qdrant` | "mon ingestion réécrit les mêmes chunks à chaque run" / "mon pipeline DuckDB n'est pas idempotent" |
| `security-review` | `sqlite3` or `SELECT .*FROM` | "cette requête SQL est construite par concaténation, c'est risqué ?" |
| `infra-containers` | `docker-compose` | "relis mon docker compose" |
| `ml-review` | `\.fit(` or `nn.Module` | — nothing matches on this machine; see the note below |

Name the exact file in the phrase if the repo is large — the point is to test routing, not the
session's ability to find the code.

**What to look at — and it has three possible outcomes, not two.** The observation is a **`Skill`
call in the transcript**, naming the skill. Tool output is truncated by default; `ctrl+o` expands it.

1. **The skill is called** → routing works for that vocabulary. Record the phrase that worked.
2. **No skill call, but the session answers the question anyway** from its own knowledge → **this is
   the failure that matters.** The answer may even be good, which is what makes it easy to miss: the
   curated guidance was bypassed and nothing said so. Fix the `description:` to carry the words you
   actually use, then retest.
3. **The session reports the subject is absent from the repo** → wrong terrain. The test did not run.
   Move to a repo from the table and try again.

**`ml-review` has no terrain, and that is a finding, not a gap to fill.** Nothing on this machine
trains a model (checked 2026-09-25 and again 2026-09-29: no `.fit(`, `train_test_split`,
`cross_val_score`, `nn.Module` or optimizer use in any `src/`). So the `/audit-ml` → `ml-review`
substitution cannot be exercised today — and by the same token it cost nothing. Test it the day a
project trains something.

**Terrain as measured 2026-09-29** — recorded to be re-derived, not trusted: `duckdb` only in
`s3dedup` (8 files); `parquet` only in `groovekeeper` (5); `qdrant` only in `veilleuse` (11);
`docker-compose` only in `veilleuse/deploy` (4); `sqlite3` in `groovekeeper` (3); `idempot` in
`groovekeeper` and `veilleuse` (2 each).

**Two traces, and the second was forgotten for four runs.** The verdict goes here, in this file.
But a routing test runs inside a *real* project and reliably turns up real defects in it — this
file's own rule is that every step leaves a trace, and for four runs the collateral findings lived
only in a conversation. **Before closing a run, write what it found into the tested project's
`.claude/context/`** (an open-points entry, or `anti-patterns.md` when the finding generalises),
labelled with its provenance and with what was *not* verified. Done retroactively for the four runs
on 2026-09-29: `veilleuse`, `s3dedup` and `groovekeeper` each carry their findings now.

Verdict: ❌ **outcome 2, twice, 2026-09-25 — the routing argument does not hold.**

- *First attempt, invalid:* the data-leakage phrase in a repo with no ML code. Outcome 3, wrong
  terrain. This is why the table above exists.
- **`data-engineering` on `veilleuse`** — "mon ingestion réécrit les mêmes chunks à chaque run".
  `"ingestion"` is a listed trigger word, **verbatim**, in the right terrain, on a project whose
  `IMPLEMENTATION.md` carries an explicit idempotence constraint. **No skill call.** The session
  investigated the repo, read `IMPLEMENTATION.md` and `.claude/context/tasks.md`, and answered very
  well: it separated "point count grows" (a bug — non-deterministic point ids) from "everything is
  re-encoded and upserted" (the contract's intended behaviour), and found a trap no checklist holds
  — re-chunking a document into *fewer* fragments leaves the old high-index points orphaned, because
  an upsert never deletes.
- **`security-review` on `groovekeeper`** — "cette fonction construit une requête SQL par
  concaténation, c'est risqué ?". **No skill call.** The answer was again good: implicit
  concatenation of literal strings is not injection, the Mixxx database is opened read-only, and the
  real defect is adjacent and not a security one — `f"file:{db_path}?mode=ro"` does not escape a
  path containing `?`, `#` or `%`, in three places. *Weaker evidence though:* none of the listed
  trigger phrases ("SQL injection", "sanitize", "input validation") appeared literally, so this run
  does not separate a vocabulary miss from a decision not to load.

**What the first case establishes.** Matching the description's vocabulary is **not sufficient**. The
model loads a skill when it judges it needs guidance, and on a subject it already handles it does
not reach for one. In `veilleuse` it got something better than a generic skill: the project's own
`IMPLEMENTATION.md`. Both answers found real, specific defects that no checklist in either skill
contains.

**So this step now tests two claims, not one**, and they have opposite answers:
- *"A skill fires on the words already being typed"* → **false**, at least for these two.
- *"Deleting the audit commands lost something"* → **also unsupported**: nothing was consulted, and
  the answers were better than the deleted checklists would have produced.

- **Third run, 2026-09-29 — invalid again, and again my fault.** "mon pipeline DuckDB n'est pas
  idempotent", typed in `groovekeeper`, which contains **no DuckDB at all**. The terrain table in
  this file had claimed it did; that claim came from a single `grep -rlniE "duckdb|parquet|idempot"`
  whose *union* of matches was reported as if each pattern had matched. groovekeeper matched on
  `parquet` and `idempot`, never on `duckdb`. Outcome 3. Worth one note: the phrase carried **two**
  listed trigger words (`pipeline`, `idempotent`) and still loaded nothing — consistent with the
  `veilleuse` run, though wrong terrain means it isolates nothing.

- **`infra-containers` on `veilleuse`, 2026-09-29** — "relis mon **docker compose**", the trigger
  phrase verbatim, in the only project that has one. **No skill call.** The answer read the compose,
  the README, `decisions.md` and ran `docker compose config`, then reported: the compose's header
  comment tells you to bind the tailnet IP while the README says to keep loopback and publish through
  Tailscale Serve (a procedure abandoned on 2026-09-17 — a reader who opens the compose first applies
  the dead one); the healthcheck proves the port is open, not that Qdrant is ready (`/readyz` exists
  and needs no key); the named volume probably lives on the eMMC the README insists on protecting;
  telemetry is on by default against a stated "nothing leaves" rule.
- **`data-engineering` on `s3dedup`, 2026-09-29** — "mon **pipeline DuckDB** n'est pas **idempotent**":
  three trigger words, verbatim, in the only project using DuckDB. **No skill call.** The answer
  reproduced **two real bugs** with a fake S3 client on an in-memory database: `LIKE prefix || '%'`
  treats `_` as a wildcard, so `scan --prefix Music_A/` deletes `MusicXA/y.mp3` from the index (same
  `LIKE` in three more places), and `media_metadata` is kept when an ETag changes, so a modified
  object keeps its old artist and title forever. Plus three fragilities and a fix plan.

- **`security-review` on `groovekeeper`, 2026-09-29** — "est-ce que ce code est vulnérable à une
  injection SQL", the subject named outright, in a project with three SQL call sites. **No skill
  call.** The answer enumerated all three, showed every query is a literal constant with no external
  value interpolated, noted the database is opened `mode=ro`, and found the same adjacent defect
  again with more precision: a path containing `?` inside `f"file:{db_path}?mode=ro"` is read as
  parameters, so a filename like `db?mode=rw` could **cancel the read-only mode**. It closed with
  the forward rule (always parameterise) and noted the tests already do.
  *One nuance:* the listed trigger is the English "SQL injection" and the phrase was the French
  "injection SQL". Matching is semantic, not substring, and run 1 already killed the vocabulary
  hypothesis with an exact-language hit — so this run confirms rather than decides.

**Verdict, four valid runs: the claim is false and its consequence is the opposite of the worry.**
Trigger words present verbatim every time, in correct terrain, and nothing loaded. But every answer
found specific, reproduced defects that **no checklist in any of these skills contains** — because
the session investigated the actual repository and its own documentation instead of consulting
general guidance. The skills were not missed; they would have been a downgrade.

**What this does not establish — and it matters most for security.** Four samples, all on subjects
the model handles well, all in repositories carrying their own documentation. Worse for the security
case specifically: **both security runs were negatives.** The session correctly concluded "not
vulnerable" twice, which is the easy direction. Nothing here shows a session *catching* a real
injection as reliably as a checklist would. To settle that you need a positive case — and to settle
whether the skill's presence changes the answer at all you need an A/B, which is what
`claude plugin eval` is built for: it "adds a no-plugin baseline arm" and resolves skills-dir
plugins. Untried here; it is the mechanical route (rung 3) if the question is worth the effort. It does not show that a skill holding genuinely
non-obvious knowledge goes unused — `safe-penpot-writes` (eight measured failure modes of an API
that fails silently) is the untested control case, and testing it needs the Penpot MCP.

### B.4 The ruff hook — the live half of §A.3b

`settings.json` registers a `PostToolUse` hook on `Write|Edit`. It fires on the **tool**, not on a
shell command, so `cat > file.py` will not trigger it — the file must be written by the Write or
Edit tool, in a session.

Write a deliberately unformatted Python file (`x = {  "a":1 }`, `def  f( a,b ):`), then:

```bash
cat <the file> | tee /tmp/cs-check/ruff-hook.txt
```

**What to look at.** It comes back formatted. If it does not, run §A.3b's pipe test to tell a broken
*command* from a matcher that matches nothing — those are different failures with different fixes.

The hook swallows ruff's stderr, so a broken or missing `ruff` is invisible here; `install.sh` warns
about that case separately (§A.4). It cannot fail a write either way.

*Trace:* the file itself. Verdict: ✅ **2026-09-18** — proven, after the matcher was repaired. Before that date this step had never been run, and it was the only thing that would have caught it.

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

### B.7 `builder` and `orchestrator`

```bash
claude --agent orchestrator
```

Give it a small, bounded implementation task and let it delegate to `builder`.

**What to look at.** Four claims: changes land in a **throwaway git worktree**, not the main
checkout; a Bash command redirecting git back into the main checkout is refused; the report carries
all five headings (`Done`, `Verified`, `Not done`, `Assumptions`, `Noticed, not touched`); and at
`maxTurns: 40` the output is marked partial and the agent can be messaged to resume.

**Also check the precondition.** The first task of a new project often creates the repository, and a
worktree cannot be created where there is no repository yet — that spawn fails before the agent
starts. Do `git init` and the skeleton in the main session; delegate from the task after.

*Trace:* the worktree itself (`git worktree list` during the run) and the returned report.
Verdict: ✅ **2026-09-18** — ten builder spawns on another project. Afterwards `git worktree list`
showed only the main checkout, `.claude/worktrees/` was empty, no builder branch survived and the
work was on `main`: **created, merged and cleaned without help.** One spawn failed on the
precondition above and its task needed four spawns in total. The `maxTurns` resumption claim is
still unobserved.

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
| Installation parity (repo ↔ `~/.claude`) | ✅ **2026-09-18** — all repo files linked; `~/.claude/commands/` holds only the six third-party `penpot-*` | A.1 |
| `delegate.yaml` copy in sync | ✅ **2026-09-18** — re-synced repo ← installed; identical | A.2 |
| `settings.json` free of foreign paths | ✅ 2026-09-18 — grep clean (one incident 2026-09-16, removed) | A.3 |
| Skill listing inside its budget | ✅ **2026-09-30** — ×1.9 → ×0.60 after `skillOverrides`; 11 Penpot skills `name-only`, router keeps its description | A.3c |
| SKILL.md frontmatter parses | ✅ **2026-09-30** — 24/24 under a strict YAML reader. Two were broken that day (a `: ` in a description) and `claude plugin validate` passed them | A.3c |
| Personal skills symlinked | ✅ **2026-09-30** — 7/7, repo, installed tree and manifest agree; no dead or orphan links | (manual) |
| ruff `PostToolUse` hook fires | ✅ **2026-09-18** — was broken for two months (`Write(*.py)` matched nothing); fixed, pipe-tested on six payloads, then proven end to end | A.3b |
| Installer dry run + dependency warnings | ✅ exercised repeatedly | A.4 |
| Delegation history / cost aggregation | ✅ reads; 2 timeouts (exit 124) recorded | A.5 |
| Defect extraction (`extract-defects.py`) | ✅ **2026-09-18** — found the 124 on this repo, and on another project's transcript the failed spawn plus a task respawned four times | A.6 |
| Agent `tools:` allowlists | ✅ 2026-08-29 — all six show real allowlists | B.1 |
| Slash-command menu labels | ✅ 2026-06-05 | B.2 |
| Skill auto-routing | ❌ **2026-09-25 — does not fire.** Two valid runs, no skill loaded either time; in one the trigger word was present verbatim. Answers were good regardless, which reframes the question | B.3 |
| `statusline.py` | ✅ in daily use | B.5 |
| Delegation end-to-end (`opencode`) | ⚠️ 2026-09-18 — runs, but the last three timed out (124) and `delegate.sh` still reports 0 | B.6 |
| Delegation end-to-end (`vibe -p`) | ❌ no-op on this machine — external, unfixed | B.6 |
| `builder` / `orchestrator` | ✅ **2026-09-18** — ten builder spawns on another project; worktrees created, merged and cleaned with nothing left behind. One spawn failed (repo did not exist yet) and its task took four | B.7 |
| Briefing contract reduces corrections | ⬜ **claim, not measurement** — added 2026-09-18; measure with `extract-defects.py` over the next sessions | B.7 |
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
