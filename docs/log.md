# Log

Changes to the workflow, newest first. One entry per change: date, what, why.

## 2026-11-26: repo created

- Moved my own pieces of `~/.claude` here: the Idioma, Progress dashboard and Plan critique
  sections; agents `dashboard-builder`, `dba`, `infra`, `security-reviewer`; the dashboard hook;
  my own skills; the settings that are mine (attribution off, deny rules, model, output style).
- New agent `plan-critic`. Before, the plan critique ran as a generic subagent on the session
  model; now its model is one editable line (`opus`). Fable stays as the second critic for
  money and security.
- The settings carried over include `defaultMode: bypassPermissions` and
  `skipDangerousModePermissionPrompt: true`, as on the source Mac.
- Left out on purpose: two work skills that hold client data.
  Internal package names in `hexagonal-field-propagation` replaced with `@<org>/…`.
- Why: to set up another computer the same way, and to iterate on the workflow with history.

## 2026-11-19: plan critique added

- Independent read-only critic before the first source write, for large or high-risk work.
  A second critic on Fable for money or security.
- Why: in one test the two critics found different defects (n=1). Planning quality showed no
  difference between Fable and Opus, at about 2.5x the cost, so planning stays on Opus.

## 2026-10-18: skills map

- Gentle AI (ODD + RDD) as the main line; `/grill-me` before and `/code-review` after.
- Skills that duplicate ODD or RDD set aside (`tdd`, `implement`, `writing-plans`, `sdd-*`, …).
