#!/usr/bin/env python3
"""Extract usage metrics from a delegate backend's native session logs.

Called by delegate.sh right after a run. Given the backend name, the working
directory, and the run's start time, it locates the session the backend just
wrote and returns its real token/cost metrics as a JSON dict on stdout.

Design choices:
  - Backends are the source of truth. We never re-estimate tokens or price;
    we read what Vibe / OpenCode already computed.
  - Best-effort: any failure (missing log, format change, backend absent)
    prints an empty JSON object `{}` and exits 0. delegate.sh then logs the
    metric fields as null — a run is never lost because parsing failed.
  - Correlation is by (workdir, time): we pick the most recent session whose
    creation time is at/after the run start. Reliable for sequential use;
    concurrent runs in the same workdir may mis-attribute (documented limit).

Usage:
    delegate-parse-session.py <backend> <workdir> <run_start_epoch>

Output (stdout, JSON): a subset of
    {input_tokens, output_tokens, total_tokens, cost, steps,
     session_id, session_dir}
Only keys that were resolved are included.
"""

import json
import subprocess
import sys
from pathlib import Path

# Vibe records each session under here as session_*/meta.json
VIBE_SESSION_DIR = Path.home() / ".vibe" / "logs" / "session"

# Clock skew tolerance: a session may register its start a hair before the
# shell captured START_TIME. Accept sessions created up to this many seconds
# before the run start.
START_SLACK_SECONDS = 5


def _norm_backend(backend: str) -> str:
    """Map a config backend name to its underlying CLI.

    Config names are task-specialized (e.g. "opencode-python", "vibe"), but
    the logs only know the real tool. We key off the command prefix.
    """
    if backend.startswith("vibe"):
        return "vibe"
    if backend.startswith("opencode"):
        return "opencode"
    return backend


def parse_vibe(workdir: str, run_start: float) -> dict:
    """Read the freshest Vibe session matching this run.

    Vibe's meta.json carries a `stats` block with the exact prompt/completion
    token counts and the session cost it billed.
    """
    if not VIBE_SESSION_DIR.is_dir():
        return {}

    candidate = None
    candidate_mtime = -1.0
    for session_dir in VIBE_SESSION_DIR.glob("session_*"):
        meta = session_dir / "meta.json"
        if not meta.is_file():
            continue
        mtime = meta.stat().st_mtime
        # Skip sessions written before this run could have started.
        if mtime < run_start - START_SLACK_SECONDS:
            continue
        if mtime > candidate_mtime:
            candidate_mtime = mtime
            candidate = meta

    if candidate is None:
        return {}

    try:
        data = json.loads(candidate.read_text())
    except (OSError, json.JSONDecodeError):
        return {}

    stats = data.get("stats", {})
    out = {
        "session_id": data.get("session_id"),
        "session_dir": str(candidate.parent),
        "input_tokens": stats.get("session_prompt_tokens"),
        "output_tokens": stats.get("session_completion_tokens"),
        "total_tokens": stats.get("session_total_llm_tokens"),
        "cost": stats.get("session_cost"),
        "steps": stats.get("steps"),
    }
    return {k: v for k, v in out.items() if v is not None}


def parse_opencode(workdir: str, run_start: float) -> dict:
    """Read the freshest OpenCode session for this workdir.

    OpenCode keeps sessions in a local store, queryable via the CLI. We list
    the most recent ones as JSON, pick the newest created in this workdir at/
    after the run start, then `export` it to read session-level cost/tokens.
    """
    sessions = _opencode_session_list()
    if not sessions:
        return {}

    run_start_ms = run_start * 1000
    workdir = str(Path(workdir).resolve())

    match = None
    for sess in sessions:
        if sess.get("directory") != workdir:
            continue
        created = sess.get("created")
        if created is None or created < run_start_ms - START_SLACK_SECONDS * 1000:
            continue
        # sessions are returned newest-first; first match is the freshest.
        match = sess
        break

    if match is None:
        return {}

    return _opencode_export(match["id"])


def _opencode_session_list(limit: int = 10) -> list:
    """Return recent OpenCode sessions as a list of dicts (newest first)."""
    try:
        proc = subprocess.run(
            ["opencode", "session", "list", "--format", "json", "-n", str(limit)],
            capture_output=True, text=True, timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired):
        return []
    if proc.returncode != 0:
        return []
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []


def _opencode_export(session_id: str) -> dict:
    """Export one OpenCode session and pull its session-level metrics."""
    try:
        proc = subprocess.run(
            ["opencode", "export", session_id],
            capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired):
        return {}
    if proc.returncode != 0:
        return {}
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return {}

    info = data.get("info", {})
    tokens = info.get("tokens", {}) or {}
    input_tokens = tokens.get("input")
    output_tokens = tokens.get("output")
    total = None
    if input_tokens is not None and output_tokens is not None:
        total = input_tokens + output_tokens

    out = {
        "session_id": info.get("id"),
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "total_tokens": total,
        "cost": info.get("cost"),
        # OpenCode counts assistant messages, not "steps"; left absent.
    }
    return {k: v for k, v in out.items() if v is not None}


def main() -> int:
    if len(sys.argv) != 4:
        print("{}")
        return 0

    backend, workdir, run_start_raw = sys.argv[1], sys.argv[2], sys.argv[3]
    try:
        run_start = float(run_start_raw)
    except ValueError:
        print("{}")
        return 0

    tool = _norm_backend(backend)
    try:
        if tool == "vibe":
            metrics = parse_vibe(workdir, run_start)
        elif tool == "opencode":
            metrics = parse_opencode(workdir, run_start)
        else:
            metrics = {}
    except Exception:
        # Never let a parsing bug break a delegation log.
        metrics = {}

    print(json.dumps(metrics))
    return 0


if __name__ == "__main__":
    sys.exit(main())
