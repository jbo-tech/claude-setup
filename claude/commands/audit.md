---
description: Audit existing code — security, homogeneity, maintainability. The axes /code-review does not cover
argument-hint: [file, module or component]
---

# Audit

You are in audit mode. You criticise; you do not fix.

## What this covers, and what it deliberately does not

`/code-review` (native) reviews a **change** — a diff, a PR, a branch — for **correctness bugs**
and **reuse, simplification, efficiency**. It is the right tool for those and this command does not
repeat it.

This one reviews **state**: an existing file, module or component, whether or not it changed. Three
axes, chosen because the native review covers none of them:

| Axis | What you look for |
|---|---|
| **Security** | secrets in the tree or in logs; input that reaches SQL, a shell, a path or HTML unsanitised; auth checks that exist on some entry points and not others; a dependency introduced without a reason |
| **Homogeneity** | does this read like the code around it — naming, error handling, existing helpers reused rather than reinvented, one vocabulary for one concept, design-system tokens rather than raw values |
| **Maintainability** | could someone else take this over: is the design testable, are the dependencies justified, does the structure survive the next change |

For the security axis, the `security-review` skill holds the detailed checklist (injection surfaces,
auth, secrets, then the infrastructure side). Load it with `/security-review` when the target
warrants depth — it will not load itself.

If the request is really about a bug or a cleanup, say so and point at `/code-review` rather than
doing a worse version of it here.

## How to run it

1. **Read the target fully** before saying anything. An audit that samples is an opinion.
2. **Check the axes against the code**, not against a memory of best practice. Every finding names
   a file and a line.
3. **Reproduce what can be reproduced.** A finding you demonstrated outranks one you inferred, and
   the difference must be visible in the report.
4. Read the project's own documentation — `CLAUDE.md`, `.claude/context/`, the README. Half the
   real findings are contradictions between the code and what the project says about itself.

## Report format

### 🔴 Must fix
Will cause an incident, a data loss, or a wrong result. Say what triggers it.

### 🟡 Consider
Depends on context you may have and the code does not show. Give the trade-off, not a verdict.

### 🟢 Holds up
What is done well, named specifically. Not politeness — it tells the reader which patterns to copy.

### 💡 Noticed, not in scope
Adjacent things worth someone's attention.

For each finding: the file and line, what is wrong, why it matters, and whether you **reproduced**
it or **inferred** it. Never blur the two.

## What you do not do

- Modify code. This command produces a report.
- Rewrite whole functions to illustrate a point — quote the line.
- Impose a personal style preference as a finding.
- Report a concern without naming its consequence.

---

$ARGUMENTS
