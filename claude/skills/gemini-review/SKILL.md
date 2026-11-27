---
name: gemini-review
description: "Generate an adversarial review brief to paste into Gemini Pro (or any external LLM) for second-opinion code review. Trigger: 'review with gemini', 'second opinion', 'adversarial review', 'gemini-review', or before merging significant changes."
license: MIT
metadata:
  author: diewoo
  version: "1.0"
---

## When to Use

Invoke this skill whenever:
- Code is about to be merged and you want a second-opinion review by an EXTERNAL model (Gemini Pro, ChatGPT, Claude in another session)
- You're auditing a critical hot path and want adversarial coverage
- A previous review found gaps your primary model missed (classic blind-spot scenario)

**Why a different model**: two LLMs from different providers have different training corpora, attention patterns, and blind spots. Multi-provider review covers more surface than any single model alone. This is true EVEN when both are state-of-the-art.

---

## What This Skill Does

Generates a complete, copy-paste-ready review brief for an external LLM. The brief includes:

1. The git diff to review (you choose scope: last commit, range, branch)
2. A 5-dimension adversarial framework that targets common blind spots of architectural-first reviewers
3. Project context (tests passing, branch state) so the external LLM doesn't ask for it back

**Output**: a markdown block. You copy it to Gemini Pro / ChatGPT / wherever, paste, read the response, and bring the findings back.

This skill does NOT call any external API. It's a brief generator. Zero credentials, zero cost, zero infra.

---

## How to Invoke

```
/gemini-review                    # default: last commit vs HEAD~1
/gemini-review --commits 3        # last 3 commits
/gemini-review --branch <name>    # entire branch vs its merge-base with develop/main
/gemini-review --diff HEAD~5..HEAD  # arbitrary range
/gemini-review --focus financial   # emphasis on financial-loss vectors
/gemini-review --focus security    # emphasis on auth/replay/injection
/gemini-review --focus performance # emphasis on N+1, locks, queries
```

If user invokes without args, default to "last commit on current branch".

---

## Workflow

### Step 1 — Determine scope
Parse the args. If no `--commits`, `--branch`, or `--diff`, default to `git diff HEAD~1..HEAD`. If `--branch X` is given, compute merge-base against the default branch (`main` or `develop` — detect via `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, fallback to `main`).

### Step 2 — Capture diff
```bash
git diff <scope> --stat              # for summary
git diff <scope>                     # full diff (may be large)
git log <scope> --oneline             # commit list
```

If diff is > 1500 lines, warn the user and offer to:
- (a) Trim to a specific subdirectory
- (b) Generate ONLY commit messages + file list (the external LLM can ask for specifics)
- (c) Proceed anyway (may exceed external LLM's context window)

### Step 3 — Gather context
- Tests status: read recent CI output if available, or suggest the user run tests and paste the count
- Branch state: `git status`, `git log --oneline -5`
- Recent decisions: search engram for `audit/*` or `sdd/*` topic_keys related to the file paths in the diff. Quote relevant snippets in the brief.

### Step 4 — Render the brief

Output this exact markdown structure (substitute placeholders):

````markdown
# Adversarial Code Review Brief

## Context
- **Project**: <project name from CLAUDE.md or directory>
- **Branch**: <current branch>
- **Scope**: <commit range or branch description>
- **Tests**: <NNN/NNN passing>
- **My background**: solo dev, fintech / production-critical / etc — adapt from CLAUDE.md if available

## Recent commit log
```
<git log --oneline output>
```

## Diff
```diff
<git diff output>
```

## Review Framework

Hacé review adversario aplicando estas 5 dimensiones. **Anchura, no profundidad** — quiero superficie cubierta, no análisis denso de un solo issue.

### 1. ADYACENCIA
Para cada fix en el diff, buscá el MISMO patrón en archivos NO tocados. Si arreglé X en `webhook-A.ts`, ¿vive X en `webhook-B.ts`? ¿en use cases? ¿en repos? Listame cada lugar donde el patrón existe sin arreglar.

### 2. ADVERSARIOS
Generá 5 payloads HOSTILES por cada endpoint o función tocada:
- campos vacíos / null / undefined
- campos con valores fuera de rango razonable
- unidades/monedas/tipos inesperados
- ordering de eventos invertido (race conditions)
- mensajes deliberadamente malformados pero estructuralmente válidos

Trazá QUÉ PASA con cada uno. ¿Cuál se procesa cuando NO debería?

### 3. DEFAULTS SILENCIOSOS
Listame TODOS los `?? 'default'`, `|| 'fallback'`, y valores asumidos en hot paths. Cada uno es un footgun potencial cuando un campo upstream cambia. Marcá cuáles son seguros y cuáles son riesgos reales.

### 4. BALANCE CONTABLE / CONSISTENCY
Para cada transición de estado o escritura, trazá: ¿queda el sistema en estado consistente después? Si hay ledger, ¿balanceado? Si hay metadata flag (pendingRefund, anomaly), ¿se setea cuándo corresponde?

### 5. CONTRADICCIONES INTERNAS
Buscá logs que mencionen dos cosas que el código NO compara. Buscá comentarios que prometen algo que el código no hace. Buscá tests que mockean algo crítico (haciendo el test verde mientras el código real falla).

---

## Restricciones de output

- **No me digas best-practices genéricas** (logging, error handling abstracto). Quiero hallazgos atados a ESTE diff.
- **Cada hallazgo con file:line**.
- **Top 5-10 gaps máximo**. Si encontrás más, listame los títulos sin profundizar.
- **Sin "looks good overall"** — asumí que hay bugs, encontralos.

---

## Si no encontrás nada en una dimensión
Decime explícitamente *"Dimensión N: clean"* y por qué. NO inventes hallazgos para llenar el output.
````

### Step 5 — Save the brief
Write the brief to a file: `.claude/gemini-briefs/<timestamp>-<branch>.md` (create dirs if needed). Print the file path so the user knows where it landed.

Also print the brief content directly to terminal so the user can copy without opening the file.

### Step 6 — Suggest next action
After printing, suggest:

> Copialo a Gemini Pro / ChatGPT / cualquier LLM externo. Cuando vuelvas con los hallazgos, decime "encontró estos N gaps" y los priorizamos contra el resto del work pendiente.

---

## Focus Modes

If `--focus financial`:
- Emphasize dimension 4 (balance contable) — push for ledger trace verification
- Add explicit "look for currency/amount/rate inconsistencies"
- Add explicit "look for asymmetric error handling between success and failure paths"

If `--focus security`:
- Emphasize dimension 5 (contradicciones)
- Add explicit "look for auth bypass, replay attacks, injection"
- Add explicit "look for trust boundary violations"

If `--focus performance`:
- Add explicit "look for N+1 queries, missing LIMIT, hot loops over unbounded sets"
- Add explicit "look for transactions held longer than necessary"

---

## Examples

### Example: review last commit on feat branch

User: `/gemini-review`

You:
1. Detect we're on `feat/payout-error-handling`
2. Get last commit diff
3. Render brief with that diff
4. Print file path + brief inline

### Example: review entire branch with financial focus

User: `/gemini-review --branch fix/audit-error-paths --focus financial`

You:
1. Compute merge-base of branch vs develop
2. Get full diff
3. Add financial emphasis to framework section
4. Render and print

---

## Why This Works

- **Different model = different blind spots**. Don't pick a model "smarter than yours". Pick a model with a different training corpus.
- **The framework is the value**, not the LLM call. The brief encodes a review methodology the requester's primary LLM (Claude/me) tends to skip.
- **Reusable across projects**. Same brief template works for fintech, infra, frontend — the framework is domain-agnostic.

## What This Skill Is NOT

- ❌ NOT a wrapper around Gemini API. No HTTP calls. No credentials.
- ❌ NOT a replacement for human code review. Use it BEFORE or ALONGSIDE human review.
- ❌ NOT a "trust the second LLM blindly" tool. Their findings may also be wrong. You still curate.
