---
name: repo-ia-amigable
description: "Trigger: repo IA amigable, AGENTS.md, documentar repo para agentes, docs en español, plantilla de docs. Scaffold a Spanish, AI-friendly knowledge layout sized to the repo."
license: Apache-2.0
metadata:
  author: "diewoo"
  version: "1.0"
---

## Activation Contract

Load when Diego asks to make a repo "IA amigable", add `AGENTS.md`, document a repo for agents, or reuse "la plantilla de lead-tracking-kit". Not for code docstrings or a single README tweak.

## Hard Rules

- Docs Diego reads are Spanish, neutral register; code, identifiers, commands, paths stay English.
- Never create an empty or placeholder doc. A file exists only if it has real content from the repo, its history, or the conversation.
- Every fact must come from the code, git history, task docs, or the user. Unknown → ask or leave it out; never invent.
- `CLAUDE.md` contains exactly `@AGENTS.md`.
- Client data (IDs, phone numbers, audits) goes only in `clientes/` of a private repo, with the "delete before public" warning in `AGENTS.md` and `clientes/README.md`.
- Verify every relative link resolves before committing.

## Decision Gates

| Signal in the repo | Create |
|---|---|
| Always | `AGENTS.md`, `CLAUDE.md` |
| More than one module/app, or a non-obvious data flow | `docs/ARQUITECTURA.md` |
| A choice with a rejected alternative (commit, review finding, discussion) | `docs/decisiones/<tema>.md`, one per decision |
| A repeatable manual procedure (install, deploy, onboarding) | `docs/guias/<tarea>.md` |
| An external format/API the code must match | `docs/referencias/<tema>.md` |
| Known pending work or review advisories | `docs/deuda-tecnica.md` |
| Real per-client work in a private repo | `clientes/README.md`, `clientes/<cliente>/README.md` |

## Execution Steps

1. Map the repo: `git ls-files`, package manifests, CI config, existing docs, task/ODD docs, git log.
2. Pick files with the Decision Gates; list which ones you skip and why.
3. Fill templates from `assets/` with repo facts. Keep `AGENTS.md` ~80–120 lines: qué es, estructura, comandos exactos, reglas e invariantes, trampas conocidas, índice de docs, checklist de verificación.
4. Run the repo checks (typecheck/tests) and a relative-link check.
5. Commit as `docs: ...` (Conventional Commits, no AI attribution).

## Output Contract

Return: files created, files skipped with the reason, open facts you could not verify, commit hash.

## References

- `assets/` — Spanish templates for each file.
- `references/ejemplo-lead-tracking-kit.md` — the real repo this layout was extracted from.
