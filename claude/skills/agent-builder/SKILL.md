---
name: agent-builder
description: Creates specialized Claude Code agents tailored to the project. Use when starting a new project requiring specific expertise. Triggers on "create an agent", "build an agent", "need an expert", "new agent", "specialized assistant", "make an agent for", "custom agent".
allowed-tools: Read, Write, Glob
---

# Agent Builder

This skill helps create specialized Claude Code agents adapted to a specific project context.

## When to use

- Starting a project with specific expertise needs
- Need a "creative director" or domain expert
- Existing agents (infra-expert, creative-director) don't cover the domain
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

### 5. Verify the tool restriction actually applies

An agent's tool allowlist is `tools:` (denylist: `disallowedTools:`). **Not `allowed-tools:`** —
that is the field for *skills and slash commands*. An unrecognized frontmatter key is ignored
without any warning, so the agent silently inherits every tool while its prompt keeps claiming it
is restricted. That is worse than no restriction: it reads as a guarantee and isn't one.

Two agents in this repo shipped that way for months (`infra-expert` announced "read-only mode"
while holding `Write` and `Edit`), which is why this step exists.

**Check, don't assume.** The agent listing injected at the start of a session prints each agent's
effective tools. An agent meant to be restricted must not read `(Tools: All tools)`. Also note:

- One tool per parenthesis — `Bash(docker:*), Bash(podman:*)`, not `Bash(docker:*, podman:*)`.
- `tools:` **replaces** the inherited pool. Anything absent is gone, including `WebSearch`,
  `WebFetch` and `Skill`. List what the agent needs, not only what you want to forbid.
- `Agent(a, b)` restricts which subagents can be spawned, but only when the agent runs as the main
  thread (`claude --agent <name>`). Inside a subagent definition the parenthesised list is ignored.

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
