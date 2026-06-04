# Document

Generate **orientation documentation** — NOT a README, NOT usage docs.

The audience is the **project owner who steers but does not write every line** and is losing
the thread as the code moves fast. Goal: let them (1) regain detailed control and (2) teach
the project to others. This is the *explanation + reference* layer, read from the **code as
ground truth**, cross-checked against recorded intent.

Do not duplicate the README (which covers install/usage). If something belongs in the README,
leave it there and link to it.

## What to produce — two artifacts in `docs/`

### 1. `docs/architecture.md` — the map (pedagogical)

Written to *teach* the system, not to enumerate it:
- **What & why** — the project's purpose and core idea in 2-3 lines.
- **Reading order** — "to understand this system, start here, then this." A mental model.
- **Components** — each major module/dir → one-line responsibility. A table.
- **How it fits** — data/control flow, with a **diagram** (mermaid preferred, ASCII if not).
- **Boundaries & extension points** — where to plug in, what not to touch.

Front-matter (used by `/retro` for the freshness check):
```yaml
---
generated_from_commit: <short hash at generation time>
generated_on: <YYYY-MM-DD>
---
```

### 2. `docs/reference.md` — the référentiel + drift (what the code does, vs what was intended)

The reference documents reality (what the code does); drift is the gap between recorded intent
and that same reality. They describe the same objects, so they live together: a scannable drift
summary at the top, divergences annotated **in context** below.

Structure:

**a) `## Drift — to arbitrate` (top, scannable).** Cross `.claude/context/decisions.md` (intent)
against the code (reality) and list **only the gaps** — this is the owner's to-do:
- Decisions recorded but **not applied** in code.
- Code that **diverged** from a recorded decision.
- Significant choices **in the code with no traced decision** (silent drift).
- **Docs that don't earn their place** — existing `docs/` files that are redundant with these
  orientation docs, stale, or orphaned (nothing links to them, nobody maintains them). A removal-
  or-merge candidate, with the reason. This keeps the doc set sharp.

For each: the **file to look at**, the **question to resolve**, and a link to the annotated spot
below. If `.claude/context/decisions.md` is absent, say so and base drift on code-vs-README/CLAUDE.md.

**b) Per-component reference (below).** The **public surface** — useful, not exhaustive:
- Entry points (adapt to project type, see "Adapt to the project type"): commands, scripts,
  exported functions, HTTP routes, public classes…
- For each: inputs/outputs, key behavior, important gotchas.
- Config: the keys that matter and what they control.
- Skip private helpers and trivia — document what a maintainer needs to *act*, not every line.
- Where a component diverged from intent, add an inline **`⚠ drift:`** note right there, and make
  sure it appears in the top summary too.

## Don't proliferate documents

Multiplying docs is counter-productive — the maintainer must always know which file is
authoritative. This command **owns exactly two files** and never spawns parallels:

1. **Fixed namespace, updated in place.** Only ever write/overwrite `docs/architecture.md` and
   `docs/reference.md`. Re-running regenerates them — it never accumulates new variants.
2. **Adopt, don't duplicate.** Before writing, scan `docs/` for a pre-existing doc covering the
   same purpose under a different name (e.g. `ARCHITECTURE.md`, `design.md`, `overview.md`, an
   existing reference). If found, **update that file in place** (keep its name) and say so —
   do not create a second one. If two rival docs already exist, flag it and ask which to keep.
3. **Link if it earns its place — otherwise flag it.** Other docs (specs, ADRs, guides — e.g.
   `learning-loop-spec.md`) are out of scope to *rewrite*, but not exempt from scrutiny. Classify
   each existing `docs/` file:
   - **complementary** (different purpose, still accurate) → keep and link from architecture/reference;
   - **same purpose** under another name → adopt/merge (rule 2);
   - **redundant / stale / orphaned** → list it as a removal-or-merge candidate in the drift summary
     (with the reason). Never delete — flag; the maintainer arbitrates. Non-absorption is not a free pass.
4. **Never touch the README** (see top).

## How to generate

1. **Map first, don't read everything.** Identify entry points, top-level dirs, build/config.
   For large projects, use the Explore agent to fan out; read only key files yourself.
2. Write `architecture.md` (high level, teaching tone, with the diagram).
3. Write `reference.md`: the per-component public surface, with inline `⚠ drift:` notes where the
   code diverged from `.claude/context/decisions.md` (intent). Then put a scannable
   `## Drift — to arbitrate` summary at the top, linking down to each annotated spot. While there,
   inventory the other `docs/` files and give each a relevance verdict (complementary / merge /
   removal-candidate) — surface dead weight, don't accumulate it.
4. Stamp `architecture.md` front-matter with the current commit (`git rev-parse --short HEAD`) and date.

**Language:** match the language of existing project docs (README/CLAUDE.md); default to the
repository's prevailing language. Keep code identifiers as they are.

## Adapt to the project type

The two artifacts are a frame, not a rigid template. **Detect the project type first** and shift
the emphasis — never force a project into the wrong shape:

| Type | Architecture emphasis | Reference emphasis |
|---|---|---|
| **Library / package** | public API surface, module boundaries, dependency direction | exported functions/classes, signatures, contracts |
| **Service / API** | request lifecycle, layers, external deps, data stores | endpoints, payloads, auth, error modes, config |
| **CLI / tooling** | command set, config resolution, execution flow | commands/flags, inputs/outputs, exit codes |
| **Data pipeline** | DAG/stages, sources→sinks, scheduling, idempotency | tasks, schemas, transforms, run/config params |
| **Frontend / app** | component tree, state/data flow, routing | routes, key components/props, stores, API calls |
| **Monorepo** | packages and their relationships first, then drill per package | per-package surface, shared contracts |

If the type is mixed or unclear, say which frame you chose and why. Keep section headings stable
across runs of the same project so diffs stay readable.

## Freshness (hybrid — paired with /retro)

- `/document` (this command) **fully regenerates** on demand. Run it when you feel out of touch.
- `/retro` only **flags staleness** — it compares `generated_from_commit` to HEAD and tells you
  the docs may be stale. It does **not** rewrite them. Regeneration stays an explicit choice.

## Output format

```
## Documentation generated

- architecture.md: [written / updated] — N components mapped
- reference.md:    [written / updated] — N entry points; M drift gaps ([X not-applied, Y diverged, Z untraced])

### Most important to look at
[1-3 lines: the drift items or areas the owner should review first]
```

$ARGUMENTS
