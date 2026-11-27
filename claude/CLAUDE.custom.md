# Idioma

Responde siempre en español neutro con tú, también después de muchas llamadas a herramientas o de leer material en inglés. Código, commits, PRs y docs del repo van en inglés.

## Progress dashboard

- For any task with more than 5 steps or expected to take more than 30 minutes, launch the
  `dashboard-builder` subagent to set up `.dashboard/index.html` before the first step. Launch it
  again after every step with the updated steps, waiting questions, latest deliverables and
  blockers. Tell the user the dashboard path once.
- If it returns `NEEDS_STYLE`, ask the user those three style questions once and pass the answer
  back.
- During such a task, when a decision from the user is needed: add it to the dashboard's question
  list with the default you are taking, and continue with that default. This applies ONLY to
  reversible choices inside the authorized scope. Still STOP and wait for:
  - consent envelopes (review consent, edit authority);
  - destructive or hard-to-reverse actions;
  - remote or outward-facing actions (push, merge, deploy, sending messages, production config);
  - credentials;
  - scope changes.
  This rule overrides "ask and STOP" only for those reversible choices.

## Plan critique

- For a large task (it gets a feature document) or a change that names a Task Size high-risk
  item: after the plan is written and before the first source write, launch the `plan-critic`
  agent to critique the plan against the code. Its model is set in its own file,
  `~/.claude/agents/plan-critic.md`. Hand it the plan and the user's request, not your
  conclusions. Ask for defects, existing behavior the plan breaks, and wrong assumptions about
  the code, each with `path:line` evidence. Fold the accepted findings into the feature
  document's Log and affected `S#` before implementing.
- When the work moves money or touches security (high-risk items 1-2), launch a second
  `plan-critic` with `model: fable` in the same turn, in parallel. Treat this as unmeasured: on
  2026-11-19 the two critics found different defects in a single test (n=1).
- This critique is a named delegation reason. Do not route planning or implementation to a
  different model because of task size alone: the same measurement found no planning-quality
  difference between Fable and Opus, at about 2.5x the cost.
