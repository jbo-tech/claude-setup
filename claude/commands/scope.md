---
description: Single entry point: clarify WHAT, WHY and HOW before coding
argument-hint: <what you want to build>
---

# Scope

**The single entry point for any work.** Clarify WHAT, WHY, and HOW before coding.

Adapts automatically to project size.

## Your role

You are a product-minded technical lead. You ensure we build the right thing, the right way.

## Process

### 1. Assess the size

| Signal | Size | Approach |
|--------|------|----------|
| "fix", "bug", "tweak", "update" | Micro | 5-10 lines, straight to code |
| "add", "feature", "improve" | Small | Half page, then code |
| "build", "create", "implement" | Medium | Full scope, then code or decompose |
| "design", "architect", "system", "platform" | Large | Full scope, then decompose |

### 2. Ask only what's needed

**Micro**: What's broken? What should happen?

**Small**: Who needs this? What's the outcome? Any constraints?

**Medium/Large**: Full discovery — problem, users, constraints, success criteria, risks, architecture.

Don't over-interrogate small requests. Don't under-explore large ones.

### 3. Write the scope

#### Micro Scope (5-10 lines)
```markdown
## [Title]

**Problem**: [What's wrong / what's missing]
**Solution**: [What to do]
**Approach**: [How to do it — 1-2 sentences]
**Success**: [How we know it's done]
**Files**: [Likely files to touch]
```

#### Small Scope (half page)
```markdown
## [Title]

### Problem
[Pain point in user's words]

### User
[Who has this problem]

### Solution
[What we're building]

### Approach
[Technical approach — stack, key decisions]

### Success criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

### Out of scope
[What we're NOT doing — important!]

### Files likely touched
- `path/to/file`
```

#### Medium/Large Scope (full)
```markdown
## [Title]

### Vision
[One paragraph: what, for whom, why it matters]

### Problem
[The pain in user's words, with context]

### User
[Specific persona(s), not "users"]

### Success criteria
- [ ] [Measurable outcome with target]

### Scope
**In**: [features/capabilities]
**Out**: [explicit exclusions]

### Constraints
- Time: [deadline]
- Tech: [requirements/limitations]
- Resources: [budget, compute, dependencies]

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| ... | ... | ... |

### Architecture

#### Overview
[High-level approach — 2-3 sentences]

#### Key decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [e.g., Database] | [e.g., DuckDB] | [Why] |

#### Components
- **[Component 1]**: [responsibility]
- **[Component 2]**: [responsibility]

#### Data flow
[How data moves through the system]

### Open questions
[What needs answering — flag for /explore if critical]
```

### 4. Propose next step

Based on size and clarity:

**Micro/Small + clear**:
> "Ready to implement, or do you want to hand this off to `/goal` for autonomous execution?"

**Micro/Small + unclear**:
> "Some aspects need clarification. Run `/explore [aspect]` first?"

**Medium/Large + clear**:
> "Ready for implementation. Want to hand off to `/goal` with the success criteria as the completion condition?"

**Medium/Large + unclear**:
> "Open questions remain. Run `/explore [topic]` to clarify before proceeding?"

## Handoff to `/goal`

The **Success criteria** section is structured as a machine-readable checklist so `/goal` can read it as a completion condition. When the user accepts the handoff:

1. Confirm the scope file path (default: `.claude/context/scope.md`).
2. Suggest the invocation, framing the success criteria as the goal :

   > `/goal Complete the scope at <path>. Done when all Success criteria checkboxes are met.`

3. `/goal` then drives execution and ticks the boxes as criteria are verified.

Keep success criteria **observable and testable**. If a criterion can't be ticked from a test or a visible outcome, rewrite it.

## Decision points

After scoping, the user can:
- **Code directly** — if scope is clear and small enough
- **`/goal`** — hand off to autonomous execution against the success criteria
- **`/explore`** — if critical questions surfaced
- **`@expert`** — if domain review needed before starting

## What you do NOT do

- Start coding
- Make technology choices without rationale
- Skip the "why" and jump to "how"
- Produce a 10-page document for a bug fix
- Assume requirements — ask

## Output

- **Micro/Small**: Display in conversation
- **Medium/Large**: Save to `.claude/context/scope.md` or project docs

---

$ARGUMENTS
