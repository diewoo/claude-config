---
name: update-project-docs
description: >
  Use when the user asks to update documentation, says "actualiza la doc",
  or invokes /update-docs. Reviews session changes and syncs CLAUDE.md,
  docs/guidelines.md, and docs/architecture.md.
---

# Update Project Docs

## Overview

Reviews what changed in the current session and updates the three project docs to stay in sync. Each doc has a different purpose — write to the right one.

## Doc Ownership

| What changed | Target doc |
|---|---|
| New command, domain, endpoint, DB table, vendor | `CLAUDE.md` |
| New env var (add to secrets table) | `CLAUDE.md` + `docs/guidelines.md` |
| New coding convention, naming rule, port, example | `docs/guidelines.md` |
| New architectural decision (WHY we chose X) | `docs/architecture.md` |
| New business flow step or state transition | `CLAUDE.md` (flow section) |

## Process

### Step 1 — Gather session context

```bash
git log --oneline -10          # recent commits
git diff HEAD~5..HEAD --stat   # files changed this session
```

Also use the conversation context — what was discussed, fixed, or decided.

### Step 2 — Read before writing

**Always read the target section** before editing. Match existing format exactly.

### Step 3 — Classify and update

For each change, pick the right doc from the table above. Apply format rules below.

---

## Format Rules

### CLAUDE.md

- Code-facing facts: commands, file paths, table rows, state machines
- No opinions, no "why" — just what the system does
- Add env vars to the secrets table with correct classification

### docs/guidelines.md

Conventions with ✓/✗ examples:

```markdown
### [Section Name]

[Brief intro]

```typescript
// ✓ correct
correct example here

// ✗ incorrect
wrong example here
```
```

Port and env var tables follow the existing markdown table format.

### docs/architecture.md

Only the WHY — never implementation details:

```markdown
## Por qué [Decision]

[Problem — 1-2 sentences]

Solución: [brief]

```typescript
// code example if useful
```

**Consecuencia práctica**: [what this means for day-to-day dev]
```

---

## What NOT to add

- Session-specific context (current task, temporary state)
- Info already documented — check before adding
- Implementation details in `architecture.md` (they go in `guidelines.md`)
- The "what" in `architecture.md` — only the "why"
- Redundant entries — search the doc first

---

## Env Var Classification (Quick Ref)

| Is a secret if... | Example |
|---|---|
| Gives access to a system | `DATABASE_URL`, `PAYMENT_PROVIDER_CLIENT_SECRET` |
| Encrypts or signs data | `JWT_SECRET`, `ENCRYPTION_KEY` |
| Is a credential/password | `BANK_API_PASSWORD`, `BANK_API_USER_ID` |
| Is an API key | `INTERNAL_JOB_API_KEY` |
| Is a bank account number | `BANK_ACCOUNT_NUMBER` |

| Plain env var if... | Example |
|---|---|
| Is a public URL | `PAYMENT_PROVIDER_BASE_URL` |
| Is app config | `NODE_ENV`, `API_PREFIX` |
| Is a TTL | `JWT_EXPIRES_IN` |

If secret → add it to every place the project lists its secrets (for example a `SECRET_KEYS` list in the `Makefile` and the deploy scripts).
