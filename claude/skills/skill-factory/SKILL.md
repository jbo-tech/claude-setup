# Skill Factory

Create custom skills that auto-activate when relevant.

## When this skill activates

- "I need a skill for..."
- "Create a skill that..."
- "Make a reusable pattern for..."
- "I keep doing X, can Claude remember how?"

## Skills vs Agents vs Commands

| Type | Activation | Duration | Best for |
|------|------------|----------|----------|
| **Skill** | Automatic (keywords in description) | Single task | Domain knowledge, patterns, integrations |
| **Agent** | Explicit (`@agent`) | Full session | Deep expertise, dedicated persona |
| **Command** | Explicit (`/command`) | Single task | Workflow steps, structured output |

**Choose Skill when**: You want Claude to automatically apply knowledge when a topic comes up.

## Skill structure

```
~/.claude/skills/[skill-name]/
├── SKILL.md              # Main skill file (required)
└── [supporting files]    # Optional: examples, schemas, reference docs
```

## SKILL.md format

```markdown
---
name: [skill-name]
description: [What this skill does. Include trigger keywords for auto-activation.]
---

# [Skill Title]

## When to use
[Conditions that trigger this skill]

## Knowledge / Patterns / Process
[The actual content — what Claude should know or do]

## Examples
[Concrete examples of applying this skill]

## Anti-patterns
[What NOT to do]
```

## Types of skills

### 1. Domain Knowledge
Expertise about a specific technology, API, or domain.

**Use when**: You work with a specific tool/API and want Claude to always know the best practices.

**Example**: DuckDB skill, Kestra workflow skill, Plex API skill

### 2. Workflow Pattern
A repeatable process for a specific type of task.

**Use when**: You have a proven approach you want to reuse.

**Example**: Feature engineering checklist, API design pattern, data validation workflow

### 3. Project-Specific
Knowledge specific to one project.

**Use when**: A project has conventions Claude should always follow.

**Location**: `.claude/skills/` in project (not user-level)

## Creating a skill

### 1. Identify the need

Ask yourself:
- Do I keep explaining the same thing to Claude?
- Is there a pattern I follow repeatedly?
- Does Claude make the same mistakes with this topic?

### 2. Choose the type

- **Domain knowledge**: "Claude should know X about [technology]"
- **Workflow pattern**: "When doing X, follow these steps"
- **Project-specific**: "In this project, always do X"

### 3. Write the skill

Use the appropriate template:
- `templates/domain-template.md` for domain knowledge
- `templates/workflow-template.md` for workflow patterns

### 4. Place the skill

- **User-level** (all projects): `~/.claude/skills/[name]/SKILL.md`
- **Project-level** (one project): `.claude/skills/[name]/SKILL.md`

## Key principles

### Trigger keywords matter
The `description` field determines when the skill activates. Include:
- Technology names (duckdb, kestra, plex)
- Task types (feature engineering, data validation)
- Specific terms users would mention

### Keep it focused
One skill = one topic. Don't create a "data science skill" — create separate skills for feature engineering, model evaluation, data validation.

### Include anti-patterns
What NOT to do is as valuable as what to do. Prevents repeated mistakes.

### Add examples
Concrete examples > abstract explanations.

## Your task

When asked to create a skill:

1. **Clarify the need**: What should Claude know/do automatically?
2. **Choose type**: Domain knowledge or workflow pattern?
3. **Extract content**: What are the key points, patterns, anti-patterns?
4. **Write the skill**: Use appropriate template
5. **Suggest location**: User-level or project-level?

Output the complete SKILL.md file ready to save.
