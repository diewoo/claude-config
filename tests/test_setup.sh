#!/usr/bin/env bash
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
JQ="$(command -v jq)"
PASSES=0
FAILS=0
SCRATCH=()

pass() { PASSES=$((PASSES + 1)); echo "ok   $1"; }
fail() { FAILS=$((FAILS + 1)); echo "FAIL $1"; [ -f "$T/out.txt" ] && sed 's/^/     | /' "$T/out.txt"; }
check() { local name="$1"; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }

new_env() {
  T="$(mktemp -d)"
  SCRATCH+=("$T")
  export HOME="$T/home"
  mkdir -p "$HOME/.gentle-ai"
  echo '{}' > "$HOME/.gentle-ai/state.json"
  SHIMS="$T/shims"
  LOG="$T/calls.log"
  mkdir -p "$SHIMS"
  : > "$LOG"
  for c in brew npm claude gentle-ai codegraph engram; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$c" "$LOG" > "$SHIMS/$c"
    chmod +x "$SHIMS/$c"
  done
  ln -s "$JQ" "$SHIMS/jq"
  export PATH="$SHIMS:/usr/bin:/bin"
  unset NVM_DIR
}

run_setup() {
  bash "$REPO/setup.sh" "$@" > "$T/out.txt" 2>&1
  RC=$?
}

count_markers() { grep -c '^<!-- claude-config:custom -->$' "$HOME/.claude/CLAUDE.md"; }

all_linked() {
  local kind="$1" src name
  for src in "$REPO/claude/$kind"/*; do
    name="$(basename "$src")"
    [ -L "$HOME/.claude/$kind/$name" ] || return 1
    [ "$(readlink "$HOME/.claude/$kind/$name")" = "$src" ] || return 1
  done
}

backup_count() { find "$HOME/.claude/claude-config-backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '; }

new_env
run_setup
check "fresh install exits 0" [ "$RC" -eq 0 ]
check "fresh install links every agent" all_linked agents
check "fresh install links every skill" all_linked skills
check "fresh install links the dashboard hook" all_linked hooks
check "fresh install writes one custom block" [ "$(count_markers)" -eq 1 ]
check "custom block holds Plan critique" grep -q '^## Plan critique$' "$HOME/.claude/CLAUDE.md"
check "settings get attribution off" [ "$(jq -r '.attribution.commit' "$HOME/.claude/settings.json")" = "" ]
check "settings get the 24 deny rules" [ "$(jq '.permissions.deny | length' "$HOME/.claude/settings.json")" -eq 24 ]
check "plugins are installed" grep -q '^claude plugin install mattpocock-skills@claude-plugins-official$' "$LOG"
check "marketplaces are added" grep -q '^claude plugin marketplace add Gentleman-Programming/engram$' "$LOG"
check "npx skill commands are printed" grep -q 'npx skills add tt-a1i/archify' "$T/out.txt"
check "existing tools are not reinstalled" bash -c "! grep -q '^brew install' '$LOG'"

BACKUPS_BEFORE="$(backup_count)"
run_setup
check "second run exits 0" [ "$RC" -eq 0 ]
check "second run keeps one custom block" [ "$(count_markers)" -eq 1 ]
check "second run keeps 24 deny rules" [ "$(jq '.permissions.deny | length' "$HOME/.claude/settings.json")" -eq 24 ]
check "second run moves nothing to backup" [ "$(backup_count)" -eq "$BACKUPS_BEFORE" ]
check "second run backs up no link" bash -c "[ -z \"\$(find '$HOME/.claude/claude-config-backups' -path '*/agents/*' -o -path '*/skills/*' 2>/dev/null)\" ]"

new_env
mkdir -p "$HOME/.claude/agents"
echo old > "$HOME/.claude/agents/dba.md"
printf '%s\n' '<!-- gentle-ai:persona -->' 'keep me' '<!-- /gentle-ai:persona -->' > "$HOME/.claude/CLAUDE.md"
echo '{"hooks":{"Stop":[]},"permissions":{"deny":["Read(foo)"]}}' > "$HOME/.claude/settings.json"
run_setup
check "existing setup exits 0" [ "$RC" -eq 0 ]
check "existing agent file is replaced by a link" [ -L "$HOME/.claude/agents/dba.md" ]
check "existing agent file is kept in a backup" bash -c "grep -rqx old '$HOME/.claude/claude-config-backups'"
check "existing CLAUDE.md content is kept" grep -q '^keep me$' "$HOME/.claude/CLAUDE.md"
check "existing settings keys are kept" [ "$(jq -c '.hooks' "$HOME/.claude/settings.json")" = '{"Stop":[]}' ]
check "existing deny rules are merged" [ "$(jq '.permissions.deny | length' "$HOME/.claude/settings.json")" -eq 25 ]
check "old settings.json is backed up" bash -c "find '$HOME/.claude/claude-config-backups' -name settings.json | grep -q ."

new_env
run_setup --dry-run
check "dry run exits 0" [ "$RC" -eq 0 ]
check "dry run writes nothing under ~/.claude" [ ! -e "$HOME/.claude" ]
check "dry run installs no plugin" bash -c "! grep -q '^claude plugin install' '$LOG'"

new_env
mkdir -p "$HOME/.claude"
printf '%s\n' '# Idioma' 'viejo' '<!-- gentle-ai:persona -->' 'keep me' '<!-- /gentle-ai:persona -->' '## Progress dashboard' 'old dashboard' '## Plan critique' 'old critique' > "$HOME/.claude/CLAUDE.md"
cp "$HOME/.claude/CLAUDE.md" "$T/original.md"
run_setup
check "unmarked own sections stop the setup" [ "$RC" -eq 3 ]
check "stopped setup leaves CLAUDE.md unchanged" cmp -s "$HOME/.claude/CLAUDE.md" "$T/original.md"
check "stop message suggests --adopt" grep -q -- '--adopt' "$T/out.txt"

run_setup --adopt
check "adopt exits 0" [ "$RC" -eq 0 ]
check "adopt removes the old sections" bash -c "! grep -q -e '^viejo$' -e '^old dashboard$' -e '^old critique$' '$HOME/.claude/CLAUDE.md'"
check "adopt keeps gentle-ai blocks" grep -q '^keep me$' "$HOME/.claude/CLAUDE.md"
check "adopt writes one custom block" [ "$(count_markers)" -eq 1 ]
check "adopt writes each own heading once" [ "$(grep -c -e '^# Idioma$' -e '^## Progress dashboard$' -e '^## Plan critique$' "$HOME/.claude/CLAUDE.md")" -eq 3 ]

new_env
rm "$HOME/.gentle-ai/state.json"
run_setup
check "missing gentle-ai install stops with exit 4" [ "$RC" -eq 4 ]
check "missing gentle-ai install names the command" grep -q 'gentle-ai install' "$T/out.txt"
check "missing gentle-ai install writes no CLAUDE.md" [ ! -e "$HOME/.claude/CLAUDE.md" ]

new_env
rm "$SHIMS/engram" "$SHIMS/codegraph"
run_setup
check "missing engram is installed from the tap" grep -q '^brew install gentleman-programming/tap/engram$' "$LOG"
check "missing codegraph is installed with npm" grep -q '^npm install -g @colbymchenry/codegraph$' "$LOG"

block_file() {
  echo '<!-- claude-config:custom -->'
  cat "$REPO/claude/CLAUDE.custom.md"
  echo '<!-- /claude-config:custom -->'
}

new_env
mkdir -p "$HOME/.claude"
{ echo '## Plan critique'; echo stale; block_file; } > "$HOME/.claude/CLAUDE.md"
run_setup
check "loose section next to the block stops the setup" [ "$RC" -eq 3 ]
run_setup --adopt
check "adopt leaves one Plan critique" [ "$(grep -c '^## Plan critique$' "$HOME/.claude/CLAUDE.md")" -eq 1 ]
check "adopt drops the stale text" bash -c "! grep -q '^stale$' '$HOME/.claude/CLAUDE.md'"

new_env
mkdir -p "$HOME/.claude"
block_file | sed 's/$/\r/' > "$HOME/.claude/CLAUDE.md"
run_setup
check "CRLF block already current is left unchanged" grep -q 'CLAUDE.md: unchanged$' "$T/out.txt"

new_env
mkdir -p "$HOME/.claude"
printf '{"a":,}' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$T/original.json"
run_setup
check "invalid settings.json stops with exit 5" [ "$RC" -eq 5 ]
check "invalid settings.json is left intact" cmp -s "$T/original.json" "$HOME/.claude/settings.json"
check "invalid settings.json stops before any link" [ ! -e "$HOME/.claude/agents" ]
check "invalid settings.json message names the file" grep -q 'settings.json is not valid JSON' "$T/out.txt"

new_env
(cd /tmp && bash "$REPO/setup.sh" > "$T/out.txt" 2>&1)
check "setup works from another folder" [ "$(readlink "$HOME/.claude/agents/plan-critic.md")" = "$REPO/claude/agents/plan-critic.md" ]

new_env
mkdir -p "$HOME/.claude"
printf '# Other\nx\n' > "$HOME/.claude/CLAUDE.md"
run_setup --adopt
check "adopt without loose sections keeps content" grep -q '^x$' "$HOME/.claude/CLAUDE.md"

new_env
mkdir -p "$HOME/.claude"
printf '# Idioma\nv\n' > "$HOME/.claude/CLAUDE.md"
cp "$HOME/.claude/CLAUDE.md" "$T/original.md"
run_setup --dry-run --adopt
check "dry run with adopt exits 0" [ "$RC" -eq 0 ]
check "dry run with adopt writes nothing" cmp -s "$T/original.md" "$HOME/.claude/CLAUDE.md"

new_env
mkdir -p "$HOME/.claude"
printf '# Idioma\nv\n## Rules\nmine\n' > "$HOME/.claude/CLAUDE.md"
run_setup --adopt
check "adopt keeps an unmarked section after Idioma" grep -q '^mine$' "$HOME/.claude/CLAUDE.md"
check "adopt removes the Idioma text" bash -c "! grep -q '^v$' '$HOME/.claude/CLAUDE.md'"

new_env
run_setup --bogus
check "unknown option exits 2" [ "$RC" -eq 2 ]

HOOK="$REPO/claude/hooks/dashboard-guard.py"
H=$(mktemp -d); SCRATCH+=("$H")
mkdir -p "$H/proj/.dashboard" "$H/outside" "$H/evil"
ln -s "$H/outside" "$H/evil/.dashboard"
ln -s "$H/outside/target" "$H/proj/.dashboard/link"
guard() { printf '{"tool_name":"%s","cwd":"%s","tool_input":{"%s":"%s"}}' "$1" "$2" "$3" "$4" | python3 "$HOOK" 2>/dev/null; }
check "hook allows a write inside .dashboard" guard Write "$H/proj" file_path .dashboard/index.html
check "hook allows date" guard Bash "$H/proj" command date
denied() { ! guard "$@"; }
check "hook denies a write outside .dashboard" denied Write "$H/proj" file_path ../outside/x
check "hook denies a symlinked .dashboard" denied Write "$H/evil" file_path .dashboard/index.html
check "hook denies a symlink inside .dashboard" denied Write "$H/proj" file_path .dashboard/link
check "hook denies invalid input" bash -c "echo 'not json' | python3 '$HOOK' 2>/dev/null; [ \$? -eq 2 ]"
check "hook denies a non-string path" bash -c "printf '{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":123}}' | python3 '$HOOK' 2>/dev/null; [ \$? -eq 2 ]"

DENY="$REPO/claude/settings.custom.json"
check "home deny rules are anchored to ~" jq -e '[.permissions.deny[] | select(test("^(Read|Edit)\\((\\.ssh|\\.aws|\\.config|\\.credentials|Library)"))] | length == 0' "$DENY"
check "ssh deny rule covers ~/.ssh recursively" jq -e '.permissions.deny | index("Read(~/.ssh/**)") != null' "$DENY"
check "secrets deny rule covers nested folders" jq -e '.permissions.deny | index("Read(**/secrets/**)") != null' "$DENY"

for d in "${SCRATCH[@]}"; do rm -rf "$d"; done
echo "$PASSES passed, $FAILS failed"
[ "$FAILS" -eq 0 ]
