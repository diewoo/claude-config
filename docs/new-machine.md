# New machine

Steps in order. Versions on the source Mac (2026-11-26): Gentle AI 5.0.0, Engram 3.0.0,
CodeGraph 1.6.0, mattpocock-skills 1.3.1.

## 1. Prerequisites

- Homebrew, git, python3.
- Node 22 (via nvm) so `npm` and `npx` exist.
- Claude Code installed and logged in: `claude`.
- GitHub CLI logged in with `diewoo`: `gh auth login`.

## 2. Clone

```bash
gh repo clone diewoo/claude-config ~/Documents/Developer/Proyectos/claude-config
cd ~/Documents/Developer/Proyectos/claude-config
```

## 3. Gentle AI

```bash
brew tap gentleman-programming/tap
brew install gentleman-programming/tap/gentle-ai gentleman-programming/tap/engram
gentle-ai install --dry-run   # preview
gentle-ai install             # pick Claude Code
```

`setup.sh` stops with exit code 4 until this step is done.

## 4. Run the setup

```bash
./setup.sh --dry-run
./setup.sh
```

If `~/.claude/CLAUDE.md` already has Idioma, Progress dashboard or Plan critique outside the
markers, the script stops with exit code 3. `./setup.sh --adopt` moves them into the block and
keeps a backup.

## 5. Skills from skills.sh

The setup prints one `npx skills add <source>` line per missing skill. Run each, pick only the
named skill and Claude Code, and check that it lands in `~/.claude/skills/`.

Skills that hold client data are not in this repo. Copy them by hand from the work Mac if this
machine needs them.

## 6. Check

```bash
gentle-ai --version
gentle-ai review mode status
./setup.sh --dry-run          # after any gentle-ai sync: must say "CLAUDE.md: unchanged"
claude plugin list
codegraph --version
```

Then open Claude Code in any repo:

- `/agents` lists `plan-critic` and `dashboard-builder`.
- Ask "cómo es mi flujo de trabajo": it should describe the 7 phases in
  [`workflow.md`](workflow.md).

## 7. Memory (optional)

```bash
# on the old machine
engram export --all engram-export.json
# on the new machine
engram import engram-export.json
```

The export holds client data. Move it by hand and delete it after the import; never commit it
(`.gitignore` blocks `engram-export*.json`).
