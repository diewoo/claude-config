#!/usr/bin/env python3
"""Keep the claude-config block at the end of ~/.claude/CLAUDE.md.

Usage: claude_md.py check|install|adopt FILE BLOCK [--dry-run]

check    exit 3 if FILE has the own sections outside the block, else 0
install  replace or append the block; exit 3 if own sections sit outside it
adopt    remove the own sections found outside the block, then install
"""
import argparse
import pathlib
import re
import sys

BEGIN = "<!-- claude-config:custom -->"
END = "<!-- /claude-config:custom -->"
OWN = {"# Idioma": 1, "## Progress dashboard": 2, "## Plan critique": 2}
HEADING = re.compile(r"^(#+) ")


def strip_block(lines):
    out, inside = [], False
    for line in lines:
        text = line.strip()
        if text == BEGIN:
            inside = True
            continue
        if text == END:
            inside = False
            continue
        if not inside:
            out.append(line)
    return out


def loose_sections(lines):
    return [line.rstrip() for line in lines if line.rstrip() in OWN]


def remove_sections(lines):
    out, level = [], None
    for line in lines:
        text = line.rstrip()
        if level is not None:
            if text.startswith("<!--") or HEADING.match(text):
                level = None
            else:
                continue
        if text in OWN:
            level = OWN[text]
            continue
        out.append(line)
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["check", "install", "adopt"])
    parser.add_argument("file")
    parser.add_argument("block")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    path = pathlib.Path(args.file)
    current = path.read_text() if path.exists() else ""
    lines = strip_block(current.splitlines(keepends=True))
    loose = loose_sections(lines)

    if loose and args.mode != "adopt":
        print(f"{path} has these sections outside the claude-config block: {', '.join(loose)}")
        print("Run ./setup.sh --adopt to move them into the block (a backup is kept).")
        return 3
    if args.mode == "check":
        return 0
    if loose:
        lines = remove_sections(lines)

    body = "".join(lines).rstrip("\n")
    block = pathlib.Path(args.block).read_text().rstrip("\n")
    wanted = (body + "\n\n" if body else "") + f"{BEGIN}\n{block}\n{END}\n"

    if wanted == current:
        print(f"{path}: unchanged")
        return 0
    if args.dry_run:
        print(f"{path}: would update the claude-config block")
        return 0
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(wanted)
    print(f"{path}: updated the claude-config block")
    return 0


if __name__ == "__main__":
    sys.exit(main())
