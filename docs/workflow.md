# Workflow

How a change goes from an idea to a merge, and what runs at each step.

## The 7 phases

| # | Phase | Who | What happens |
| --- | --- | --- | --- |
| 1 | Decide what I want | `/grill-me` (I type it) | Rounds of questions until nothing is open. No code. |
| 2 | Write it as specs and tasks | ODD | Feature doc `odd/tasks/<feature>.md`: specs `S#` in my own words, tasks, log. |
| 3 | Critique the plan | `plan-critic` agent (automatic) | An independent read-only agent checks the plan against the real code before any code is written. |
| 4 | Implement | ODD | Test first, then code, commits of about 400 lines per task. |
| 5 | Review quality and risk | RDD (`gentle-ai review`) | Lens review only when a commit is high risk or I ask. |
| 6 | Check it does what I asked | `/mattpocock-skills:code-review` (I type it) | Spec axis: compares the result with the criteria. |
| 7 | Push and merge | Me | Always my decision. |

How to start: `/grill-me <idea>`, answer until it stops asking, then "dale, impleméntalo".
ODD and the plan critique are always on; I never ask for them. Plain `/code-review` is Claude Code's built-in bug review, not the spec check.

## How each piece works

### `~/.claude/CLAUDE.md`

Claude reads it at the start of every session. Two kinds of blocks:

- Between `<!-- gentle-ai:* -->` markers: written by Gentle AI. `gentle-ai sync` rewrites them.
  Never edit by hand.
- Between `<!-- claude-config:custom -->` markers: mine, from `claude/CLAUDE.custom.md`.
  Sections: Idioma, Progress dashboard, Plan critique.

### ODD (Organic Driven Development)

Gentle AI block `agent-routing`. Runs on every request:

1. Checks whether I asked for a change or only a question.
2. Explores the code.
3. Sizes the task. Small (understood, no high risk, resumable from the diff): done directly with
   a failing test first. Large: feature doc plus a copy in Engram (`odd/<feature>/tasks`).
4. Every change ends with a `Risk:` line. A named high-risk item (data, security, public
   contracts, concurrency, installers/CI, untested code) adds an independent verifier.

### Plan critique

My block in `CLAUDE.custom.md`, agent in `claude/agents/plan-critic.md`.

- When: large tasks, or a change that names a high-risk item. After the plan, before the
  first source write.
- The critic gets the plan and my request, not the parent's conclusions, and returns defects,
  behavior the plan breaks and wrong assumptions with `path:line` evidence.
- Money or security: a second critic on Fable runs in parallel.
- Accepted findings go into the feature doc's log and the affected `S#`.

### RDD (receipt-driven development)

After each work-unit commit, `gentle-ai review assess` rates the risk. A lens review (risk,
resilience, readability, reliability) runs only when `review_due` is true or I ask, and it
asks for consent first (`granted` / `declined`).

- Status: `gentle-ai review mode status`
- Turn off: `gentle-ai review mode disable`

### Engram, CodeGraph, dashboard

- Engram: memory across sessions (decisions, bugs, summaries, ODD feature docs).
- CodeGraph: `.codegraph/` index per repo, to see callers before a change.
  Created with `gentle-ai codegraph init --cwd <repo>`.
- Dashboard: tasks with more than 5 steps get `.dashboard/index.html`, kept by the
  `dashboard-builder` agent. Its hook only lets it write in the session's own folder.

## Which model each agent uses

| Agent | Model | Where it is set |
| --- | --- | --- |
| Main session | `opus[1m]` | `claude/settings.custom.json` → `model` |
| `plan-critic` | `opus` | `claude/agents/plan-critic.md` → `model:` |
| Second critic (money/security) | `fable` | `CLAUDE.custom.md`, passed as the Agent `model` override |
| `dashboard-builder` | `opus` | its frontmatter |
| Gentle AI `review-*`, `jd-*` | `sonnet` | written by Gentle AI |
| Any other subagent | same as the session | Claude Code default |

To change a model, edit the `model:` line and commit. Subagents can only run Claude models
(`opus`, `sonnet`, `haiku`, `fable`). Codex and Gemini are installed as CLIs (`codex`,
`gemini`); a critic could call them through Bash for an outside opinion, but that is not wired.

## Skills: when to use which

| Moment | Signal | Skill |
| --- | --- | --- |
| Before starting | Fuzzy idea | `/grill-me`, `/grill-with-docs` |
| Business terms | Code and I name things differently | `domain-modeling` |
| Uncertain design | Torn between two shapes | `prototype` |
| Module design | New boundary or interface | `codebase-design` |
| Hard bug | Two fixes failed | `diagnosing-bugs` |
| Does it do what I asked? | Feature with clear criteria | `/mattpocock-skills:code-review` |
| After the feature | Something went wrong or slow | `retro` |

Out of service next to Gentle AI, because they duplicate ODD or RDD: `tdd`,
`test-driven-development`, `writing-plans`, `executing-plans`, `subagent-driven-development`,
`implement`, `to-tickets`, `wayfinder`, `sdd-*`.

## Open items

- Skills that hold client data stay out of this repo. They live only in `~/.claude/skills/`
  on the work Mac until they get a private repo under the work account.
- `spec-probes`, `verify-commands`, `blast-radius`: still to port.
- `dashboard-builder` cannot build a dashboard for another repo from a session opened
  elsewhere: its hook limits it to the session's folder.
- Isolated minimal config for factory agents (`claude -p` must not load ODD/RDD).
