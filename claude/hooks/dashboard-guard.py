#!/usr/bin/env python3
"""PreToolUse guard for the dashboard-builder subagent.

Allows Read/Write/Edit only inside <cwd>/.dashboard/ and the agent's own memory,
and Bash only for `date` and `mkdir -p .dashboard`. Everything else is blocked.
"""
import json
import os
import re
import sys


def deny(reason):
    print(f"dashboard-builder: {reason}", file=sys.stderr)
    sys.exit(2)


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    args = data.get("tool_input") or {}
    cwd = data.get("cwd") or os.getcwd()

    roots = [
        os.path.join(os.path.realpath(cwd), ".dashboard"),
        os.path.join(os.path.realpath(os.path.expanduser("~/.claude")), "agent-memory", "dashboard-builder"),
    ]

    if tool in ("Read", "Write", "Edit"):
        file_path = args.get("file_path")
        if not isinstance(file_path, str) or not file_path:
            deny("file_path must be a non-empty string")
        path = os.path.realpath(os.path.join(cwd, file_path))
        if any(path == r or path.startswith(r + os.sep) for r in roots):
            sys.exit(0)
        deny(f"{path} is outside .dashboard/ and the agent memory")

    if tool == "Bash":
        cmd = args.get("command", "").strip()
        if re.fullmatch(r"date( [+'%A-Za-z:\- ]*)?", cmd) or cmd == "mkdir -p .dashboard":
            sys.exit(0)
        deny("only `date` and `mkdir -p .dashboard` are allowed")

    deny(f"tool {tool} is not allowed")


try:
    main()
except SystemExit:
    raise
except Exception as exc:
    deny(f"blocked on error: {exc!r}")
