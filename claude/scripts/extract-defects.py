#!/usr/bin/env python3
"""Report defect signal from Claude Code session transcripts and delegation logs.

A *defect* is something the factory produced that had to be redone. This script reads
what already exists on disk and reports three kinds:

  1. Subagent spawns that failed outright.
  2. Tasks that had to be spawned more than once.
  3. Delegations that exited non-zero (timeout, crash, refusal).

It is read-only: it never writes or modifies a file. Intended to be run as the first,
mechanical step of `/retro` §7, before the subjective pass.

Known blind spot: a subagent launched in the background returns only a launch
acknowledgement in the transcript; its real outcome arrives later as a notification that
is not a tool result. So section 1 catches synchronous failures only. Section 2 catches
background failures indirectly — a task that failed is a task that got spawned again.
A wrong answer accepted on the first try is invisible to all three sections.
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"
DELEGATE_LOG = Path.home() / ".local" / "share" / "claude-code" / "delegate-runs.jsonl"

# Substrings that mark a tool result as a failure, matched case-insensitively.
FAILURE_MARKERS = ("cannot ", "error", "failed", "not a git repository")

# A task identifier such as T0.1, T0.2a, T2.1 — used as the retry-grouping key.
TASK_ID = re.compile(r"\bT\d+(?:\.\d+)*[a-z]?\b")


def session_dir_for(project_root: Path) -> Path:
    """Claude Code names a project directory after its absolute path, '/' -> '-'."""
    return PROJECTS_DIR / str(project_root.resolve()).replace("/", "-")


def result_text(content) -> str:
    """A tool result is either a string or a list of blocks carrying 'text'."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(b.get("text", "") for b in content if isinstance(b, dict))
    return ""


def retry_key(description: str) -> str:
    """Group spawns of the same task: by task id when present, else by first 3 words."""
    match = TASK_ID.search(description)
    if match:
        return match.group(0).upper()
    words = re.sub(r"[^0-9a-zA-Z ]", "", description).lower().split()
    return " ".join(words[:3]) or "(no description)"


def read_session(path: Path) -> list[dict]:
    """Return one record per subagent spawn found in a session transcript."""
    spawns: dict[str, dict] = {}
    order: list[str] = []

    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                obj = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue  # a truncated or non-JSON line is not worth failing over

            content = (obj.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue

            for block in content:
                if not isinstance(block, dict):
                    continue

                if block.get("type") == "tool_use" and block.get("name") in ("Agent", "Task"):
                    spawn_id = block.get("id")
                    if not spawn_id:
                        continue
                    payload = block.get("input") or {}
                    spawns[spawn_id] = {
                        "session": path.name,
                        "agent": payload.get("subagent_type") or "unknown",
                        "description": payload.get("description") or "(no description)",
                        "result": "",
                        "failed": False,
                    }
                    order.append(spawn_id)

                elif block.get("type") == "tool_result":
                    spawn = spawns.get(block.get("tool_use_id"))
                    if spawn is None:
                        continue
                    text = result_text(block.get("content"))
                    spawn["result"] = text
                    head = text[:400].lower()
                    spawn["failed"] = bool(block.get("is_error")) or any(
                        marker in head for marker in FAILURE_MARKERS
                    )

    return [spawns[i] for i in order]


def read_delegations(workdir: Path, cutoff: float) -> list[dict]:
    """Return delegation runs for this workdir that exited non-zero."""
    if not DELEGATE_LOG.exists():
        return []

    failures = []
    with DELEGATE_LOG.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                run = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue
            if run.get("exit_code") in (0, None):
                continue
            if workdir and run.get("workdir") != str(workdir.resolve()):
                continue
            stamp = (run.get("timestamp") or "").replace("Z", "+00:00")
            try:
                if time.mktime(time.strptime(stamp[:19], "%Y-%m-%dT%H:%M:%S")) < cutoff:
                    continue
            except ValueError:
                pass  # an unparseable timestamp is reported rather than dropped
            failures.append(run)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="*", type=Path,
                        help="session .jsonl files to read (bypasses --project and --days)")
    parser.add_argument("--project", type=Path, default=Path.cwd(),
                        help="project root whose sessions to read (default: cwd)")
    parser.add_argument("--days", type=int, default=7,
                        help="only sessions modified in the last N days (default: 7)")
    args = parser.parse_args()

    cutoff = time.time() - args.days * 86400

    if args.paths:
        missing = [p for p in args.paths if not p.exists()]
        if missing:
            for path in missing:
                print(f"error: no such file: {path}", file=sys.stderr)
            return 1
        files = list(args.paths)
        workdir = None
    else:
        directory = session_dir_for(args.project)
        files = sorted(
            (p for p in directory.glob("*.jsonl") if p.stat().st_mtime >= cutoff),
            key=lambda p: p.stat().st_mtime,
        ) if directory.is_dir() else []
        workdir = args.project

    spawns = [s for f in files for s in read_session(f)]

    print("## Failed spawns\n")
    failed = [s for s in spawns if s["failed"]]
    if not failed:
        print("None.\n")
    for spawn in failed:
        print(f"{spawn['session']}  [{spawn['agent']}]  {spawn['description']}")
        print(f"    {spawn['result'][:200].strip()}\n")

    print("## Repeated tasks\n")
    groups: dict[str, list[dict]] = {}
    for spawn in spawns:
        groups.setdefault(retry_key(spawn["description"]), []).append(spawn)
    repeated = sorted(
        ((k, v) for k, v in groups.items() if len(v) >= 2),
        key=lambda kv: len(kv[1]),
        reverse=True,
    )
    if not repeated:
        print("None.\n")
    for key, members in repeated:
        print(f"{key}  ({len(members)} spawns)")
        for spawn in members:
            print(f"    {spawn['description']}")
        print()

    print("## Failed delegations\n")
    delegations = read_delegations(workdir, cutoff) if workdir else []
    if not delegations:
        print("None.\n")
    for run in delegations:
        print(f"{run.get('timestamp', '?')}  {run.get('backend')} / {run.get('model')}")
        print(f"    exit {run.get('exit_code')} after {run.get('duration_secs')}s, "
              f"{run.get('files_changed')} files changed\n")

    print("## Summary\n")
    print(f"session files read   : {len(files)}")
    print(f"spawns               : {len(spawns)}")
    print(f"failed spawns        : {len(failed)}")
    print(f"repeated task groups : {len(repeated)}")
    print(f"failed delegations   : {len(delegations)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
