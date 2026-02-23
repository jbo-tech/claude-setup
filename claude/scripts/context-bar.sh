#!/bin/bash

# Color theme: gray, orange, blue, teal, green, lavender, rose, gold, slate, cyan
COLOR="blue"

# Color codes
C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'
C_WHITE='\033[38;5;255m'
C_RED='\033[38;5;167m'
C_GREEN='\033[38;5;71m'
C_YELLOW='\033[38;5;178m'
C_BAR_EMPTY='\033[38;5;238m'
case "$COLOR" in
    orange)   C_ACCENT='\033[38;5;173m' ;;
    blue)     C_ACCENT='\033[38;5;74m' ;;
    teal)     C_ACCENT='\033[38;5;66m' ;;
    green)    C_ACCENT='\033[38;5;71m' ;;
    lavender) C_ACCENT='\033[38;5;139m' ;;
    rose)     C_ACCENT='\033[38;5;132m' ;;
    gold)     C_ACCENT='\033[38;5;136m' ;;
    slate)    C_ACCENT='\033[38;5;60m' ;;
    cyan)     C_ACCENT='\033[38;5;37m' ;;
    *)        C_ACCENT="$C_GRAY" ;;
esac

input=$(cat)

# ─── Extract model, directory, cost ───────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd" 2>/dev/null || echo "?")

# Cost (from native JSON — no transcript parsing needed)
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_display=$(printf '%.2f' "$cost_usd" 2>/dev/null || echo "0.00")

# Session duration
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
duration_s=$((duration_ms / 1000))
if [[ $duration_s -ge 3600 ]]; then
    duration_str="$((duration_s / 3600))h$((duration_s % 3600 / 60))m"
elif [[ $duration_s -ge 60 ]]; then
    duration_str="$((duration_s / 60))m"
else
    duration_str="${duration_s}s"
fi

# ─── Git status ───────────────────────────────────────────────────────────────
branch=""
git_status=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        # Fichiers non commités & conflits
        raw_status=$(git -C "$cwd" --no-optional-locks status --porcelain -uall 2>/dev/null)
        file_count=$(echo "$raw_status" | grep -cv '^??' | tr -d ' ')
        untracked_count=$(echo "$raw_status" | grep -c '^??' | tr -d ' ')
        conflict_count=$(echo "$raw_status" | grep -c '^UU' | tr -d ' ')

        # Temps depuis le dernier commit
        last_commit=""
        last_commit_date=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null)
        if [[ -n "$last_commit_date" ]]; then
            now=$(date +%s)
            diff=$((now - last_commit_date))
            if [[ $diff -lt 3600 ]]; then last_commit="last:$((diff / 60))m"
            elif [[ $diff -lt 86400 ]]; then last_commit="last:$((diff / 3600))h"
            else last_commit="last:$((diff / 86400))d"; fi
        fi

        # Sync (ahead/behind)
        sync_info=""
        upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            counts=$(git -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
            ahead=$(echo "$counts" | cut -f1); behind=$(echo "$counts" | cut -f2)
            [[ "$ahead" -gt 0 ]] && sync_info+="↑${ahead}"
            [[ "$behind" -gt 0 ]] && sync_info+="↓${behind}"
            [[ -z "$sync_info" ]] && sync_info="✓"
        else
            sync_info="no-up"
        fi

        # Stash
        stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
        [[ "$stash_count" -gt 0 ]] && stash_str=" 📦${stash_count}" || stash_str=""

        # Couleur selon état
        color_files="${C_GRAY}"
        [[ "$file_count" -gt 0 ]] && color_files="${C_ACCENT}"
        [[ "$conflict_count" -gt 0 ]] && color_files="${C_RED}"

        git_status="${C_WHITE}${branch}${C_RESET} ${C_GRAY}(${sync_info})${C_RESET} "
        git_status+="${color_files}${file_count}m+${untracked_count}u${C_RESET} "
        git_status+="${C_GRAY}${last_commit}${stash_str}${C_RESET}"
    fi
fi

# ─── Context bar (from native JSON — no transcript parsing needed) ────────────
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
max_k=$((max_context / 1000))

# Color the percentage based on urgency
if [[ "$pct" -ge 80 ]]; then
    C_PCT="${C_RED}"
elif [[ "$pct" -ge 50 ]]; then
    C_PCT="${C_YELLOW}"
else
    C_PCT="${C_GRAY}"
fi

bar_width=10
bar=""
for ((i=0; i<bar_width; i++)); do
    bar_start=$((i * 10))
    progress=$((pct - bar_start))
    if [[ $progress -ge 8 ]]; then
        bar+="${C_ACCENT}█${C_RESET}"
    elif [[ $progress -ge 3 ]]; then
        bar+="${C_ACCENT}▄${C_RESET}"
    else
        bar+="${C_BAR_EMPTY}░${C_RESET}"
    fi
done

ctx="${bar} ${C_PCT}${pct}%${C_GRAY} of ${max_k}k"

# ─── Output ───────────────────────────────────────────────────────────────────
output="${C_ACCENT}${model}${C_GRAY} | 📁 ${dir}"
[[ -n "$branch" ]] && output+=" | 🔀 ${git_status}"
output+=" | ${ctx}"
output+=" ${C_GRAY}| \$${cost_display} ${duration_str}${C_RESET}"

printf '%b\n' "$output"
