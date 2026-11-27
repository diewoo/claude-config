# Log

Changes to the workflow, newest first. One entry per change: date, what, why.

## 2026-11-27: repo public, deny rules and dashboard hook fixed

- Repo made public. Client names replaced with generic examples; history squashed to one commit.
- Deny rules for home files are now anchored to `~/` (`Read(~/.ssh/**)`, …). Before, paths like
  `.ssh/*` only matched inside the folder Claude Code was opened in. `secrets/` rules now match
  nested files (`**/secrets/**`). Rules like `Read(.env)` stay as they are: a bare filename already
  matches at any depth under that folder, but not in other projects.
- `dashboard-guard.py` no longer follows a `.dashboard` symlink: the allowed root is the real
  project folder plus `.dashboard`, so a symlinked `.dashboard` cannot point writes elsewhere.
  Any error in the hook now blocks the call (exit 2) instead of letting it through (exit 1).
- Why: an automated security review flagged both.

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
