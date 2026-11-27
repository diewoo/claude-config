# claude-config

My Claude Code setup: the parts I wrote myself, the workflow I follow, and a script that
rebuilds it on a new machine. Gentle AI, plugins and npx skills are installed from their own
sources; this repo only keeps what nobody else ships.

## Quick start

```bash
git clone https://github.com/diewoo/claude-config.git ~/Documents/Developer/Proyectos/claude-config
cd ~/Documents/Developer/Proyectos/claude-config
./setup.sh --dry-run     # shows what it would do, changes nothing
./setup.sh               # first time on a machine with existing sections: ./setup.sh --adopt
```

A new machine needs a few manual steps before and after: [`docs/new-machine.md`](docs/new-machine.md).

> **Before you copy this setup:** `claude/settings.custom.json` turns on
> `defaultMode: bypassPermissions` and skips its warning prompt, so Claude Code runs tools without
> asking. It also overwrites `model`, `outputStyle` and other scalar settings. Edit that file
> first if you want something else. This repo is a personal setup, shared as a reference.

## Map

| Need | Read |
| --- | --- |
| How I work: the 7 phases, what each piece does, which model each agent uses | [`docs/workflow.md`](docs/workflow.md) |
| Set up another computer | [`docs/new-machine.md`](docs/new-machine.md) |
| What changed in the workflow and why | [`docs/log.md`](docs/log.md) |

## What lives here

| Path | Goes to | How |
| --- | --- | --- |
| `claude/CLAUDE.custom.md` | end of `~/.claude/CLAUDE.md`, between `<!-- claude-config:custom -->` markers | block replaced on every run |
| `claude/agents/*.md` | `~/.claude/agents/` | one symlink per file |
| `claude/skills/*/` | `~/.claude/skills/` | one symlink per skill |
| `claude/hooks/*` | `~/.claude/hooks/` | one symlink per file |
| `claude/settings.custom.json` | `~/.claude/settings.json` | merged with `jq`; deny/allow lists are unioned |
| `manifest/plugins.txt` | Claude Code plugins | `claude plugin marketplace add` / `install` |
| `manifest/skills-npx.txt` | skills from skills.sh | commands printed, run by hand |

Once `setup.sh` has run on a machine, agents, skills and hooks are symlinks, so editing them
in `~/.claude` edits this repo. Commit from here. `CLAUDE.custom.md` is the exception: edit it here and run `./setup.sh` again.

Anything the script replaces is first moved to `~/.claude/claude-config-backups/<timestamp>/`.

The settings merge overwrites scalar keys (`model`, `outputStyle`, `effortLevel`, …) with the
values here, and turns on `defaultMode: bypassPermissions` with
`skipDangerousModePermissionPrompt`. Edit `claude/settings.custom.json` before running it on a
machine where you want something else.

Exit codes: `0` done, `2` missing prerequisite or unknown option, `3` own sections outside the
block (use `--adopt`), `4` Gentle AI not installed yet, `5` `settings.json` is not valid JSON.
The checks for `3`, `4` and `5` run before anything is written.

Pushing from a machine where `gh` uses SSH without a GitHub key: keep the remote on HTTPS
(`git remote set-url origin https://github.com/diewoo/claude-config.git`) and run
`gh auth switch --user diewoo` before `git push`.

## What does not live here

- Gentle AI's own blocks in `CLAUDE.md` (`<!-- gentle-ai:* -->`), its skills and its `review-*`
  and `jd-*` agents: `gentle-ai install` and `gentle-ai sync` write them.
- Hooks inside `settings.json`: Gentle AI, CodeGraph and Orca add their own.
- Engram memory: it holds client data. Move it with `engram export` / `engram import`.

## Tests

```bash
bash tests/test_setup.sh
```

Runs `setup.sh` against a temporary `HOME` with fake `brew`, `npm`, `claude` and `gentle-ai`,
so it never touches the real `~/.claude`.

## License

[MIT](LICENSE) for the files I wrote: the setup script, its tests, `lib/`, the docs, the
`plan-critic` and `dashboard-builder` agents, the hook and the skills whose frontmatter names `diewoo` as author. Skills whose frontmatter
names another author (for example `prowler-cloud`, Apache-2.0) keep that author's license. The
other skills were collected from public skill collections and keep their original licenses.
