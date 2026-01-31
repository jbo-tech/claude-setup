---
name: agent-builder
description: Creates specialized Claude Code agents tailored to the project. Use when starting a new project requiring specific expertise (frontend, creative, domain-specific). Triggers on create agent, need expert, build agent, new agent, specialized assistant.
allowed-tools: Read, Write, Glob
---

# Agent Builder

This skill helps create specialized Claude Code agents adapted to a specific project context.

## When to use

- Starting a project with specific expertise needs
- Need a "creative director" or domain expert
- Existing agents (data-ml-expert, infra-expert) don't cover the domain
- Want to capitalize expertise for a recurring project

## Process

### 1. Understand the need

Ask these questions:

**Domain**
- What is the area of expertise? (frontend, backend, UX, creative, business...)
- Which specific frameworks/tools?

**Stance**
- Review only (read-only) or can modify code?
- Style: directive, socratic, provocative?

**Focus**
- What are the 3-5 critical points to always check?
- What are common anti-patterns to detect?

**Project context**
- One-time or recurring project?
- Solo or team collaboration?

### 2. Choose the template

Two templates available:

- `expert-template.md` — For technical experts (review, audit, advice)
- `creative-template.md` — For creative roles (brainstorm, direction, ideation)

### 3. Generate the agent

Use the appropriate template and customize:

- Name and description (for frontmatter)
- Allowed tools
- Domain-specific checklist
- Adapted response format

### 4. File placement

- **User-level** (`~/.claude/agents/`): if reusable across projects
- **Project-level** (`.claude/agents/`): if specific to this project

## Available templates

See `templates/` folder:

- `expert-template.md`: structure for technical expertise agents
- `creative-template.md`: structure for creative/strategic agents

## Example agents to create

### Frontend Expert
- Domain: React, TypeScript, CSS
- Focus: accessibility, performance, reusable components
- Tools: Read, Grep, Glob, Bash(npm:*, eslint:*)

### Creative Director
- Domain: product ideation, UX strategy
- Stance: provocative, challenges assumptions
- Tools: Read (read-only, no code)

### Domain Expert (e.g., Finance)
- Domain: specific business rules
- Focus: compliance, business edge cases
- Tools: Read, Grep

## Best practices

1. **Keep checklists short** — 10-15 points max, otherwise dilution
2. **Be specific** — "check React hooks" > "check code"
3. **Include anti-patterns** — what NOT to do
4. **Define output format** — structure the agent's responses
5. **Version with project** — if project-level, commit the agent
