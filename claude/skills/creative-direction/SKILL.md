---
name: creative-direction
description: Naming, brand identity, tone of voice, taglines, concept development — the working method, not the reviewer. Applies in an ordinary session without mobilising the creative-director agent — use it whenever the task is to generate and narrow creative options.
---

# Creative Direction

Workflow for creative tasks: naming, branding, concept development, and identity work.

## When this skill activates

- Naming projects, features, or products
- Developing brand identity or tone of voice
- Brainstorming concepts or ideas
- Creating taglines or messaging
- Reviewing creative work for coherence

## Process

### 1. Engage the Creative Director

For deep creative work, invoke `@creative-director` agent who will:
- Challenge assumptions before ideating
- Use explicit modes (DIVERGE → CONNECT → CONVERGE → CHALLENGE)
- Produce documented artifacts

### 2. Quick creative tasks

For lighter tasks, apply these principles directly:

**Before ideating:**
- What's the essence? (3 words max)
- Who is this for? Who is it NOT for?
- What emotion should it evoke?

**During ideation:**
- Quantity first, judgment later
- Welcome the absurd — it often hides insight
- Connect distant domains

**Before finalizing:**
- What's the obvious flaw?
- Who would hate this? Why?
- Is this actually new or just familiar?

## Artifacts

When creative decisions are made, document them:

| Artifact | Use when | Location |
|----------|----------|----------|
| `creative-direction.md` | Project needs identity foundation | `.claude/context/` |
| Naming Rationale | Significant naming decision | In artifact or context |
| Creative Brief | Handing off to execution | Project docs |

## Key principles

1. **Clarify before creating** — Never assume you understand the brief
2. **Diverge before converging** — Premature closure kills creativity
3. **Document decisions** — Ideas without artifacts are just conversation
4. **Challenge everything** — If it breaks easily, it wasn't strong

## Integration

- Check `.claude/context/creative-direction.md` if it exists
- Flag inconsistencies with established creative direction
- Update creative-direction.md when direction evolves

## When to escalate to @creative-director

Use the full agent for:
- Major naming decisions (project, product, company)
- Brand identity development
- Complex concept exploration
- When you need structured diverge/converge workflow
- When artifacts need to be production-ready
