#!/bin/bash

# Color theme: gray, orange, blue, teal, green, lavender, rose, gold, slate, cyan
# Preview colors with: bash scripts/color-preview.sh
COLOR="blue"

# Color codes
C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'  # explicit gray for default text
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
    *)        C_ACCENT="$C_GRAY" ;;  # gray: all same color
esac

input=$(cat)

# Extract model, directory, and cwd
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd" 2>/dev/null || echo "?")

# Get git branch, uncommitted file count, and sync status
branch=""
git_status=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        # 1. Fichiers non commités & conflits
        raw_status=$(git -C "$cwd" --no-optional-locks status --porcelain -uall 2>/dev/null)
        file_count=$(echo "$raw_status" | grep -v '^??' | wc -l | tr -d ' ')
        untracked_count=$(echo "$raw_status" | grep '^??' | wc -l | tr -d ' ')
        conflict_count=$(echo "$raw_status" | grep '^UU' | wc -l | tr -d ' ')
        
        # 2. Temps depuis le dernier commit
        last_commit_date=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null)
        if [[ -n "$last_commit_date" ]]; then
            now=$(date +%s)
            commit_diff=$((now - last_commit_date))
            if [[ $commit_diff -lt 3600 ]]; then last_commit="last: $((commit_diff / 60))m";
            elif [[ $commit_diff -lt 86400 ]]; then last_commit="last: $((commit_diff / 3600))h";
            else last_commit="last: $((commit_diff / 86400))d"; fi
        fi

        # 3. État de synchronisation (Ahead/Behind)
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

        # 4. Stash count
        stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
        [[ "$stash_count" -gt 0 ]] && stash_str=" 📦${stash_count}" || stash_str=""

        # Construction du texte final
        # On utilise des couleurs pour les alertes (conflits ou fichiers)
        color_files="${C_GRAY}"
        [[ "$file_count" -gt 0 ]] && color_files="${C_ACCENT}"
        [[ "$conflict_count" -gt 0 ]] && color_files="${C_RED}"

        # Format compact : [Branch] Sync | Files | Last | Stash
        git_status="${C_WHITE}${branch}${C_RESET} ${C_GRAY}(${sync_info})${C_RESET} "
        git_status+="${color_files}${file_count}m+${untracked_count}u${C_RESET} "
        git_status+="${C_GRAY}${last_commit}${stash_str}${C_RESET}"
    fi
fi

# Get transcript path for context calculation and last message feature
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Get context window size from JSON (accurate), but calculate tokens from transcript
# (more accurate than total_input_tokens which excludes system prompt/tools/memory)
# See: github.com/anthropics/claude-code/issues/13652
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
max_k=$((max_context / 1000))

# Calculate context bar from transcript
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    context_length=$(jq -s '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        last |
        if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end
    ' < "$transcript_path")

    # 20k baseline: includes system prompt (~3k), tools (~15k), memory (~300),
    # plus ~2k for git status, env block, XML framing, and other dynamic context
    baseline=20000
    bar_width=10

    if [[ "$context_length" -gt 0 ]]; then
        pct=$((context_length * 100 / max_context))
        pct_prefix=""
    else
        # At conversation start, ~20k baseline is already loaded
        pct=$((baseline * 100 / max_context))
        pct_prefix="~"
    fi

    [[ $pct -gt 100 ]] && pct=100

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

    ctx="${bar} ${C_GRAY}${pct_prefix}${pct}% of ${max_k}k tokens"
else
    # Transcript not available yet - show baseline estimate
    baseline=20000
    bar_width=10
    pct=$((baseline * 100 / max_context))
    [[ $pct -gt 100 ]] && pct=100

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

    ctx="${bar} ${C_GRAY}~${pct}% of ${max_k}k tokens"
fi

# Session tracking - rolling 5h window
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    # Timestamp du premier message (epoch)
    first_msg_ts=$(jq -s '
        [.[] | select(.message.usage) | .timestamp // .ts // empty][0] // empty
    ' < "$transcript_path")
    
    if [[ -n "$first_msg_ts" && "$first_msg_ts" != "null" ]]; then
        # Convertir en epoch si format ISO
        if [[ "$first_msg_ts" =~ ^[0-9]+$ ]]; then
            first_epoch=$first_msg_ts
        else
            first_epoch=$(date -d "$first_msg_ts" +%s 2>/dev/null || echo "")
        fi
        
        if [[ -n "$first_epoch" ]]; then
            now_epoch=$(date +%s)
            elapsed=$((now_epoch - first_epoch))
            window=$((5 * 3600))  # 5h en secondes
            remaining=$((window - elapsed))
            
            if [[ $remaining -le 0 ]]; then
                reset_info="${C_GREEN}●${C_RESET} ${C_GRAY}quota reset${C_RESET}"
            else
                hours=$((remaining / 3600))
                mins=$(((remaining % 3600) / 60))
                # Couleur selon urgence
                if [[ $remaining -lt 1800 ]]; then
                    color="$C_GREEN"   # <30min = bientôt reset
                elif [[ $remaining -lt 3600 ]]; then
                    color="$C_YELLOW"  # <1h
                else
                    color="$C_GRAY"
                fi
                reset_info="${color}⏱ ${hours}h${mins}m${C_RESET}"
            fi
            
            # Tokens output cumulés (indicateur de consommation)
            output_tokens=$(jq -s '
                [.[] | select(.message.usage) | .message.usage.output_tokens // 0] | add // 0
            ' < "$transcript_path")
            output_k=$((output_tokens / 1000))
            
            session="${reset_info} ${C_GRAY}↑${output_k}k${C_RESET}"
        fi
    fi
fi

# Build output: Model | Dir | Branch (uncommitted) | Context
output="${C_ACCENT}${model}${C_GRAY} | 📁 ${dir}"
[[ -n "$branch" ]] && output+=" | 🔀 ${git_status}"
output+=" | ${ctx}${C_RESET}"
output+=" ${C_GRAY}${session}${C_RESET}"

printf '%b\n' "$output"

