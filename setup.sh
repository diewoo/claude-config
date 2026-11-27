#!/usr/bin/env bash
# Usage: ./setup.sh [--dry-run] [--adopt]
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DRY=0
ADOPT=0
BACKUP_DIR=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --adopt) ADOPT=1 ;;
    -h|--help) sed -n 2p "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n== %s\n' "$1"; }
run() {
  if [ "$DRY" -eq 1 ]; then echo "[dry-run] $*"; else echo "+ $*"; "$@"; fi
}
backup() {
  local target="$1" rel
  if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$CLAUDE_DIR/claude-config-backups/$(date +%Y%m%d-%H%M%S)"
  fi
  rel="${target#"$CLAUDE_DIR"/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  if [ "${2:-move}" = copy ]; then cp "$target" "$BACKUP_DIR/$rel"; else mv "$target" "$BACKUP_DIR/$rel"; fi
  echo "  backed up $target"
}

say "Prerequisites"
if ! command -v npm >/dev/null 2>&1 && [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
fi
missing=()
for cmd in brew python3 claude npm; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing: ${missing[*]}. See docs/new-machine.md, step 1." >&2
  exit 2
fi
echo "brew, python3, claude and npm found"

say "Command-line tools"
if ! command -v jq >/dev/null 2>&1; then run brew install jq; fi
if ! command -v gentle-ai >/dev/null 2>&1; then
  run brew tap gentleman-programming/tap
  run brew install gentleman-programming/tap/gentle-ai
fi
if ! command -v engram >/dev/null 2>&1; then run brew install gentleman-programming/tap/engram; fi
if ! command -v codegraph >/dev/null 2>&1; then run npm install -g @colbymchenry/codegraph; fi

say "Gentle AI"
if [ ! -f "$HOME/.gentle-ai/state.json" ]; then
  if [ "$DRY" -eq 1 ]; then
    echo "[dry-run] Gentle AI is not installed yet; a real run stops here."
  else
    echo "Gentle AI is not installed yet. Run the gentle-ai install command from"
    echo "docs/new-machine.md, step 3, then run ./setup.sh again."
    exit 4
  fi
else
  echo "found ~/.gentle-ai/state.json"
fi

if [ -f "$CLAUDE_DIR/settings.json" ] && ! jq empty "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
  echo "$CLAUDE_DIR/settings.json is not valid JSON. Fix it (or move it away) and run ./setup.sh again." >&2
  exit 5
fi

MODE=install
[ "$ADOPT" -eq 1 ] && MODE=adopt
if [ "$MODE" = install ]; then
  python3 "$REPO/lib/claude_md.py" check "$CLAUDE_DIR/CLAUDE.md" "$REPO/claude/CLAUDE.custom.md" || exit $?
fi

say "Plugins"
installed_plugins="$(claude plugin list 2>/dev/null || true)"
known_markets="$(claude plugin marketplace list 2>/dev/null || true)"
while read -r kind name source; do
  case "$kind" in
    marketplace)
      if ! grep -qw -- "$name" <<<"$known_markets"; then run claude plugin marketplace add "$source"; fi ;;
    plugin)
      if ! grep -qF -- "$name" <<<"$installed_plugins"; then run claude plugin install "$name"; fi ;;
  esac
done < <(grep -v '^#' "$REPO/manifest/plugins.txt")

say "Skills installed with npx (run these by hand)"
while read -r skill source; do
  if [ ! -e "$CLAUDE_DIR/skills/$skill" ]; then
    echo "  npx skills add $source    # pick only: $skill, agent: Claude Code"
  fi
done < <(grep -v '^#' "$REPO/manifest/skills-npx.txt")

say "Links into ~/.claude"
for kind in agents skills hooks; do
  for src in "$REPO/claude/$kind"/*; do
    dst="$CLAUDE_DIR/$kind/$(basename "$src")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then continue; fi
    if [ "$DRY" -eq 1 ]; then
      echo "[dry-run] link $dst -> $src"
      continue
    fi
    mkdir -p "$CLAUDE_DIR/$kind"
    if [ -e "$dst" ] || [ -L "$dst" ]; then backup "$dst"; fi
    ln -s "$src" "$dst"
    echo "  linked $dst"
  done
done

say "settings.json"
SETTINGS="$CLAUDE_DIR/settings.json"
current='{}'
[ -f "$SETTINGS" ] && current="$(cat "$SETTINGS")"
merged="$(jq -s '
  def uniq: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
  .[0] as $a | .[1] as $b
  | ($a * $b)
  | .permissions.deny = ((($a.permissions.deny // []) + ($b.permissions.deny // [])) | uniq)
  | .permissions.allow = ((($a.permissions.allow // []) + ($b.permissions.allow // [])) | uniq)
' <(printf '%s' "$current") "$REPO/claude/settings.custom.json")"
if [ "$(jq -S . <<<"$current")" = "$(jq -S . <<<"$merged")" ]; then
  echo "$SETTINGS: unchanged"
elif [ "$DRY" -eq 1 ]; then
  echo "[dry-run] $SETTINGS: would merge claude/settings.custom.json"
else
  mkdir -p "$CLAUDE_DIR"
  if [ -f "$SETTINGS" ]; then backup "$SETTINGS" copy; fi
  printf '%s\n' "$merged" > "$SETTINGS"
  echo "$SETTINGS: merged claude/settings.custom.json"
fi

say "CLAUDE.md"
if [ "$DRY" -eq 1 ]; then
  python3 "$REPO/lib/claude_md.py" "$MODE" "$CLAUDE_DIR/CLAUDE.md" "$REPO/claude/CLAUDE.custom.md" --dry-run
else
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && ! python3 "$REPO/lib/claude_md.py" "$MODE" "$CLAUDE_DIR/CLAUDE.md" "$REPO/claude/CLAUDE.custom.md" --dry-run | grep -q ': unchanged$'; then
    backup "$CLAUDE_DIR/CLAUDE.md" copy
  fi
  python3 "$REPO/lib/claude_md.py" "$MODE" "$CLAUDE_DIR/CLAUDE.md" "$REPO/claude/CLAUDE.custom.md"
fi

say "Done"
[ -n "$BACKUP_DIR" ] && echo "Backups: $BACKUP_DIR"
echo "Next: docs/new-machine.md, step 6 (check)."
