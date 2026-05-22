#!/usr/bin/env python3
"""Statusline Claude Code — contexte, quotas 5h/7d, git."""

import json
import os
import subprocess
import sys
import time

# Couleurs ANSI 256
RESET = '\033[0m'
GRAY = '\033[38;5;245m'
DIM = '\033[38;5;238m'
WHITE = '\033[38;5;255m'
ACCENT = '\033[38;5;74m'
GREEN = '\033[38;5;71m'
YELLOW = '\033[38;5;178m'
RED = '\033[38;5;167m'


def color_for(pct, yellow_at=50, red_at=80):
    if pct >= red_at:
        return RED
    if pct >= yellow_at:
        return YELLOW
    return GREEN


def bar(pct, width, color):
    filled = max(0, min(width, round(pct * width / 100)))
    return f"{color}{'▓' * filled}{DIM}{'░' * (width - filled)}{RESET}"


def fmt_remaining(resets_at):
    if not resets_at:
        return ''
    secs = int(resets_at - time.time())
    if secs <= 0:
        return ''
    if secs >= 86400:
        return f" ~{secs // 86400}d"
    if secs >= 3600:
        return f" ~{secs // 3600}h{(secs % 3600) // 60:02d}"
    return f" ~{secs // 60}m"


def git_info(cwd):
    if not cwd:
        return '', False
    try:
        branch = subprocess.check_output(
            ['git', '-C', cwd, 'branch', '--show-current'],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
        if not branch:
            return '', False
        dirty = bool(subprocess.check_output(
            ['git', '-C', cwd, 'status', '--porcelain'],
            stderr=subprocess.DEVNULL, text=True
        ).strip())
        return branch, dirty
    except Exception:
        return '', False


def main():
    data = json.load(sys.stdin)

    model = data.get('model', {}).get('display_name', '?')
    cwd = data.get('cwd', '')
    dir_name = os.path.basename(cwd) if cwd else '?'

    # Git : repo:branch + indicateur dirty
    branch, dirty = git_info(cwd)
    if branch:
        dot = f" {ACCENT}●{RESET}" if dirty else ''
        git_seg = f"{WHITE}{dir_name}:{branch}{dot}{RESET}"
    else:
        git_seg = f"{WHITE}{dir_name}{RESET}"

    # Contexte
    ctx_pct = int(data.get('context_window', {}).get('used_percentage', 0) or 0)
    ctx_c = color_for(ctx_pct, 50, 80)
    ctx_seg = f"{GRAY}CTX{RESET} {bar(ctx_pct, 10, ctx_c)} {ctx_c}{ctx_pct}%{RESET}"

    # Quota 5h (seuils : jaune 50%, rouge 80%)
    rl = data.get('rate_limits', {})
    fh = rl.get('five_hour') or {}
    fh_pct = fh.get('used_percentage')
    if fh_pct is not None:
        fh_c = color_for(fh_pct, 50, 80)
        fh_seg = f"{GRAY}5h{RESET} {bar(fh_pct, 5, fh_c)} {fh_c}{int(fh_pct)}%{fmt_remaining(fh.get('resets_at'))}{RESET}"
    else:
        fh_seg = f"{DIM}5h --{RESET}"

    # Quota 7d (seuils décalés : jaune 60%, rouge 85%)
    sd = rl.get('seven_day') or {}
    sd_pct = sd.get('used_percentage')
    if sd_pct is not None:
        sd_c = color_for(sd_pct, 60, 85)
        sd_seg = f"{GRAY}7d{RESET} {bar(sd_pct, 5, sd_c)} {sd_c}{int(sd_pct)}%{fmt_remaining(sd.get('resets_at'))}{RESET}"
    else:
        sd_seg = f"{DIM}7d --{RESET}"

    sep = f" {GRAY}|{RESET} "
    print(f"{ACCENT}{model}{sep}{git_seg}{sep}{ctx_seg}{sep}{fh_seg}{sep}{sd_seg}")

    if ctx_pct >= 80:
        print(f"  {RED}>>{RESET} {GRAY}/compact now or /clear to finish{RESET}")
    elif ctx_pct >= 50:
        print(f"  {YELLOW}>{RESET} {GRAY}/clear (new task) {DIM}|{GRAY} /compact (same task) {DIM}| plan>exec>verify>commit>clear{RESET}")


main()
