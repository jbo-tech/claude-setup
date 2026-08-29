---
name: safe-penpot-writes
description: Read-back discipline for the Penpot plugin API, whose write path fails SILENTLY. Activates when the user mentions "apply tokens", "rename a token", "change a token value", "edit a component", "update all instances", "work across pages" — and above all when they say "why didn't my change apply", "the token is right but nothing moved", or "the component and its copies disagree" — and when they say "my work disappeared" or "the file went back in time". Complements the official Penpot AI kit (penpot-* skills); does not replace any of them.
---

# Safe Penpot writes

The official `penpot-*` skills know *what* to build. This one knows *how a write goes wrong*.

Penpot's plugin API has a failure class that ordinary care does not catch: **the mutation does
nothing, and the read that follows returns the old state, so the call reports success.** No error, no
visible change, and the file is quietly wrong — usually surfacing days later as "the token is right
but nothing moves".

> **The one rule: a write you have not read back did not happen.**
> Not "probably happened" — did not happen. Write in one tool call, verify in the next. Never fold the
> verification into the call that wrote: the state you read there is stale by construction.

## When this skill activates

- Applying, renaming or re-valuing a design token
- Editing a component that already has copies placed
- Any work that spans more than one page
- Debugging "I changed it and nothing happened"
- After any `clone()` — clones inherit their source's bindings
- Opening a campaign of any length: prove the session reaches the server before building on it

## Dependency — the official Penpot AI kit

This skill is a **complement**, not a standalone. It assumes the Penpot AI kit is installed and its
MCP reachable:

- **Kit**: <https://github.com/penpot/penpot-ai-kit> → `~/.penpot-ai-kit`, skills vendored into
  `~/.claude/skills/penpot-*`
- **Full gotcha list**: `~/.claude/skills/penpot-router/shared/plugin-api-gotchas.md`
- **Routing**: let `penpot-router` pick the domain skill; use this one alongside it, for the write path

If the kit is absent, the recipes below still hold — but `penpotUtils` comes from the MCP plugin
context, so nothing here runs without it. The scripts use exactly four of its functions:
`getPages`, `getPageById`, `findShapes`, `findShape`.

**Reads are independent of the active page.** `getPageById` + `findShapes` return shapes, token
bindings and rendered values on a **closed** page, identical to the same read with that page open.
*Measured 2026-08-28, Penpot 2.17.2: 3687 bindings read on a closed page, 3687 after opening it,
same sampled rendered value.* The active-page restriction bears on the **write** path only — which
is what makes the discipline practical: you verify page B while A is active.

**These seven observations live here on purpose, and are not upstreamed** (decision, 2026-08-27). They
were measured on one real file over one campaign; the kit's own `plugin-api-gotchas.md` is
version-pinned and probe-verified, and dropping unprobed findings into it would weaken that contract.
Keep them here, keep them dated, and re-measure before trusting them against a newer Penpot build.

`install.sh` warns when the kit is missing.

## The seven silent failure modes

Each measured on a real file, not inferred from the docs.

### 1. Writes only reach the ACTIVE page
`applyToShapes`, property setters and `createBoard` act on the currently open page. Aimed elsewhere
they do nothing. Only `shape.remove()` fails loudly (`Cannot modify a page that is not currently
active`) — treat that error as the reminder that the quiet ones failed too.

A loop does not fix it: `await penpot.openPage(p)` inside a loop lands only on the **last** page,
because the mutation resolves after the page has changed again. *Measured: 0, 0, then 7.*

```js
// WRONG — measured: 0 applied on page A, 0 on page B, 7 on page C (the last one)
for (const p of pages) { await penpot.openPage(p); tok.applyToShapes(shapesOf(p), ["typography"]); }

// RIGHT — one execute_code call per page, and read back between them
await penpot.openPage(pageA);
tok.applyToShapes(shapesOnA, ["typography"]);
// …next tool call: verify page A, then open page B
```

**→ One tool call per page. `openPage` first. Verify before moving on.**

This rule is about **writing**. The read-back does not need the page open (see the dependency
section) — and a read-only verifier must never call `openPage`: it would change the file's active
page under the user and actuate the very mechanism it is watching.

### 2. Re-applying the same token REMOVES it
Application is a toggle. On a shape that already carries the token, `applyToShapes` clears the
binding; the rendered value stays frozen, so nothing moves on screen.
*Measured: 40 texts unbound in one call.*

```js
tok.applyToShapes(alreadyBound, ["typography"]);  // → 0 bindings (unbind)
tok.applyToShapes(alreadyBound, ["typography"]);  // → bound again, now with the new value
```

**→ Read `shape.tokens[prop]` first. Apply only to shapes that lack it — or apply twice deliberately
and verify between the two.**

### 3. Changing a token's VALUE does not re-flow its consumers
`token.resolvedValue` reports the new value while every bound shape keeps the old one, indefinitely.
The binding is live in name and dead in effect.
*Measured: token at 13px/700, its 40 texts still at 12px/800, bindings intact.*

```js
const consumers = penpotUtils.findShapes(s => (s.tokens || {})[prop] === tokenName, page.root);
tok.value = newValue;
tok.applyToShapes(consumers, [prop]);   // unbinds — they still carry the name
tok.applyToShapes(consumers, [prop]);   // rebinds, now with the new value
// verify, in the NEXT call: every consumer still bound AND the rendered value changed
```

**→ Inventory consumers before the change, re-apply after (twice, per #2), verify a sampled shape's
rendered property — never the token's `resolvedValue`.**

### 4. Renaming a token orphans its consumers
Each bound shape keeps the **old name** and the value frozen at rename time. It follows nothing.
*Measured: one rename cost 52 re-bindings.*

**Corollary:** renaming a component's **main instance** renames the **component**. `isMainComponent`
is not reliably exposed — a probe reading `null` will call the main instance "a copy". Identify it by
`component().mainInstance().id`, and re-read `penpot.library.local.components` after any shape rename.

### 5. A component COPY refuses every structural change
Properties propagate to copies; structure does not. `insertChild` on a copy throws `Cannot change the
structure of a component copy`, and the same change in the main component never reaches existing
copies. They diverge with nothing to flag it.
*Measured: a wrapper added to 9 variants reached 0 of 10 copies — main 111×24, copies 101×14.*

**→ Rebuild the copy** (see below). Budget for it: rebuilding surfaces overrides you assumed were set.

### 6. Never mutate a variant component
Standing policy from the kit (kit #12): the probe that would verify it is itself corrupting. Add variants
by cloning a main instance and creating a component from the clone — Penpot attaches it to the
container on its own.

### 7. A whole session can be unpersisted — and every read-back still passes
Reads and writes both hit the **client** state. When the client never commits to the server, the
verification confirms work that does not exist anywhere but that tab. Counts match, sampled rendered
values match, `export_shape` looks right — and the file on the server is untouched.

*Measured 2026-08-28/29, Penpot 2.17.2: a campaign's ≈820 shapes and ≈4400 bindings read back
correctly through the plugin while the server had none of it — server revision advanced by 5 across
three days, with **no autosave snapshot at all** on the two working days. The work was not recoverable
from version history: it had never arrived.*

**→ The proof is server-side, and there are two of them.**

```js
// in the call that writes
const before = penpot.currentFile.revn;
// …the write…

// in the NEXT call — revn does NOT increment inside the writing call
return { revn: penpot.currentFile.revn };          // must be > before
```

*Measured: a plugin-data write left `revn` unchanged when read in the same call, and `+1` in the next
one, with a matching server-side `internal/snapshot/<revn>` timestamped to the minute of the write.*

Second proof, stronger and independent: `await penpot.currentFile.findVersions()` is a server round
trip. A **new `internal/snapshot/<revn>` entry** is direct evidence the server received the work.

**→ Two standing rules.**

- **One tab per file during a campaign.** The plugin lives in a tab; a second tab is a second client
  with its own state, and on reconnection it can win. This is how a live file reverts three days.
- **Pin a named version at every stage boundary** — `penpot.currentFile.saveVersion(label)`, or the
  Versions panel. Autosaves expire; named versions do not. A stage you cannot pin is a stage you
  cannot lose safely.

## What counts as proof

| Write | Proof | Not proof |
|---|---|---|
| Apply a token | consumer count matches the expected after-count | the call returned without error |
| Change a value | a sampled consumer's **rendered** property changed | `token.resolvedValue`, or a `"mixed"` read |
| Rename a token | consumers of the **old** name = 0 | the token's new name reads back fine |
| Rename a shape | `penpot.library.local.components` unchanged — unless you meant it | the shape's name reads back fine |
| Structural edit | the **copies** carry the new child | the main component carries it |
| Cross-page work | the count **on that page** | a total, which hides a zero |
| Anything at all | `revn` moved, read in a **later** call | any read of the state you just wrote (#7) |

**If the counts disagree, stop and report the delta. Do not re-run the write** — if the first
application landed, the second unbinds it (#2), turning a partial success into a clean failure.

`export_shape` catches what counts cannot (a mirrored subtree, a collapsed grid). It does **not**
catch a frozen value: a dead binding renders exactly like a live one. Use both.

## Rebuilding a component copy

Record **first**, in a call of its own — the rebuild destroys the copy, and whatever you failed to
record is gone: variant props, parent, index, `layoutChild` sizing, every text, and the
**interactions** (they live on the instance and do not survive the rebuild on their own).

Interactions are **restorable**, not merely reportable: the API exposes a writer, and an interaction
carries `{ trigger, delay?, action }`. Two constraints — they can sit on any **descendant** of the
copy, so index them by path from the copy root, not by root alone; and `action` is a union
(`NavigateTo`, `OpenOverlay`, `ToggleOverlay`, `CloseOverlay`, `PreviousScreen`, `OpenUrl`), so
replaying means rebuilding the right variant. `rebuildCopy.js` records, replays, and returns
`interactionsRestored: "n/m"` — a shortfall is loud by construction.

Then: `remove()` the old one **before** `insertChild` at its index, or the index shifts under you.
Restore `layoutChild.horizontalSizing` — a fresh instance returns at its intrinsic width, not the one
the layout had given it. `scripts/rebuildCopy.js`.

> **A default that was never overridden looks exactly like a deliberate choice.** In one rebuild pass,
> 9 of 10 fields turned out to carry the component's default label — every field named "Durée (min)".
> No audit can see this: it is not a token, not a binding, not a measurement. **Read the labels out
> loud at every review.**

## Anti-rationalization

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "It returned without error, it worked." | Six of seven traps return cleanly. | Read back in a **separate** call. |
| "I'll loop over the pages." | The loop lands only on the last (#1). | One tool call per page. |
| "I'll re-apply the token to refresh it." | Re-applying **unbinds** (#2). | Read `shape.tokens` first, or apply twice on purpose. |
| "The token resolves to the new value." | That's the token's value, not the shape's (#3). | Sample a consumer's rendered property. |
| "I'll add the wrapper inside the copy." | Copies refuse structure (#5). | Change the main, rebuild the copies. |
| "Nothing looks different, so nothing broke." | A frozen value looks like a live one. | The count is the evidence, not the render. |
| "I verified it, the counts were right." | Counts read the client, which may never have committed (#7). | Check `revn` moved, in a later call. |

## Scripts

| Script | What it does |
|---|---|
| `scripts/inventoryConsumers.js` | Counts a token's consumers per page — the baseline to take **before** |
| `scripts/verifyBindings.js` | The read-back: counts, old-name leftovers, sampled rendered value |
| `scripts/rebuildCopy.js` | Rebuilds a copy from the right variant, restores its overrides, replays its interactions |
| `scripts/verifyPersistence.js` | The pre-flight: proves writes reach the **server**, not just the tab — run it before a campaign and at its end |

Each is a body for `execute_code`: paste, replace the `REPLACE-ME` placeholders, run. Verify any
unfamiliar signature with `penpot_api_info` first.

**Reference convention:** the scripts cite *this skill's* numbering (#1–#6). Any reference to the
kit's own list is prefixed explicitly (`kit #12`), which runs to #16 and never overlaps.

A text shape returns `"mixed"` for `fontSize` / `fontWeight` when its ranges disagree. `"mixed"`
reads like a value and passes the eye, so `verifyBindings.js` refuses it as a sample and looks for
another consumer — reporting `sample: null, reason: "mixed-range"` if every candidate is mixed.
