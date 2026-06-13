#!/usr/bin/env python3
"""Centralized usage dashboard for /delegate runs.

Reads the append-only JSONL written by delegate.sh and prints a unified view
of cost and tokens across every backend — the /delegate counterpart to
llm-sparring's get_usage. Read-only; it never writes or mutates the log.

Tolerates legacy lines (pre-metrics) that lack token/cost fields: those
contribute to run counts but not to cost/token totals.

Usage:
    delegate-status.py [--log <path>] [--days N]

    --days N   only aggregate runs from the last N days (default: all)
"""

import argparse
import json
import os
from collections import defaultdict
from datetime import datetime, timedelta, timezone

DEFAULT_LOG = os.path.expanduser("~/.local/share/claude-code/delegate-runs.jsonl")


def _parse_ts(raw: str):
    """Parse the ISO timestamp delegate.sh writes (UTC, trailing 'Z')."""
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_runs(log_path: str, days: int | None) -> list[dict]:
    """Read the JSONL, one run per line, skipping malformed lines."""
    if not os.path.exists(log_path):
        return []

    cutoff = None
    if days is not None:
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)

    runs = []
    with open(log_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                run = json.loads(line)
            except json.JSONDecodeError:
                continue
            if cutoff is not None:
                ts = _parse_ts(run.get("timestamp", ""))
                if ts is None or ts < cutoff:
                    continue
            runs.append(run)
    return runs


def _num(value):
    """Coerce a metric to a number, treating None/missing as 0."""
    return value if isinstance(value, (int, float)) else 0


def aggregate(runs: list[dict]) -> dict:
    """Build totals and per-backend / per-day breakdowns."""
    today = datetime.now(timezone.utc).date().isoformat()

    totals = {"runs": 0, "cost": 0.0, "tokens": 0, "errors": 0, "priced_runs": 0}
    daily_cost = defaultdict(float)
    by_backend = defaultdict(
        lambda: {"runs": 0, "cost": 0.0, "tokens": 0, "errors": 0}
    )

    for run in runs:
        cost = _num(run.get("cost"))
        tokens = _num(run.get("total_tokens"))
        is_error = run.get("exit_code") not in (0, None)
        backend = run.get("backend") or "unknown"
        model = run.get("model") or "default"
        key = f"{backend} · {model}"

        totals["runs"] += 1
        totals["cost"] += cost
        totals["tokens"] += tokens
        if is_error:
            totals["errors"] += 1
        # A run is "priced" if the backend gave us real cost/token data.
        if run.get("cost") is not None or run.get("total_tokens") is not None:
            totals["priced_runs"] += 1

        b = by_backend[key]
        b["runs"] += 1
        b["cost"] += cost
        b["tokens"] += tokens
        if is_error:
            b["errors"] += 1

        ts = _parse_ts(run.get("timestamp", ""))
        if ts is not None:
            daily_cost[ts.date().isoformat()] += cost

    return {
        "totals": totals,
        "by_backend": dict(by_backend),
        "daily_cost": dict(daily_cost),
        "today": today,
    }


def render(agg: dict, scope_label: str) -> str:
    """Format the aggregation as a compact text dashboard."""
    t = agg["totals"]
    lines = []
    lines.append(f"Delegate usage — {scope_label}")
    lines.append("=" * 48)

    if t["runs"] == 0:
        lines.append("  (no runs recorded)")
        return "\n".join(lines)

    today_cost = agg["daily_cost"].get(agg["today"], 0.0)
    untracked = t["runs"] - t["priced_runs"]

    lines.append(f"  Runs        : {t['runs']}  ({t['errors']} errors)")
    lines.append(f"  Cost total  : ${t['cost']:.4f}")
    lines.append(f"  Cost today  : ${today_cost:.4f}")
    lines.append(f"  Tokens total: {t['tokens']:,}")
    if untracked:
        lines.append(f"  Untracked   : {untracked} run(s) without backend metrics")

    lines.append("")
    lines.append("  By backend · model")
    lines.append("  " + "-" * 46)
    ordered = sorted(
        agg["by_backend"].items(), key=lambda kv: kv[1]["cost"], reverse=True
    )
    for key, b in ordered:
        lines.append(
            f"  {key}\n"
            f"      {b['runs']} runs | ${b['cost']:.4f} | "
            f"{b['tokens']:,} tokens | {b['errors']} err"
        )

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Delegate usage dashboard")
    parser.add_argument("--log", default=DEFAULT_LOG, help="path to the JSONL log")
    parser.add_argument(
        "--days", type=int, default=None, help="only count the last N days"
    )
    args = parser.parse_args()

    runs = load_runs(args.log, args.days)
    agg = aggregate(runs)
    scope = f"last {args.days}d" if args.days else "all time"
    print(render(agg, scope))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
