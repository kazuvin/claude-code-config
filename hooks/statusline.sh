#!/bin/bash
# Claude Code statusLine script - displays git branch, model, and context usage with colors

input=$(cat)

# ANSI colors
CYAN='\033[36m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Model info
MODEL=$(echo "$input" | jq -r '.model // empty')
# Shorten model name and extract version for display
MODEL_SHORT=""
if [ -n "$MODEL" ]; then
    # Extract model name
    case "$MODEL" in
        *opus*) MODEL_NAME="opus" ;;
        *sonnet*) MODEL_NAME="sonnet" ;;
        *haiku*) MODEL_NAME="haiku" ;;
        *) MODEL_NAME="$MODEL" ;;
    esac

    # Extract version (e.g., claude-opus-4-5-20251101 → 4.5, claude-3-5-sonnet → 3.5)
    if [[ "$MODEL" =~ claude-([0-9]+)-([0-9]+)- ]]; then
        # claude-3-5-sonnet format
        MODEL_SHORT="${MODEL_NAME} ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    elif [[ "$MODEL" =~ claude-[a-z]+-([0-9]+)-([0-9]+)- ]]; then
        # claude-opus-4-5-20251101 format
        MODEL_SHORT="${MODEL_NAME} ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    elif [[ "$MODEL" =~ claude-[a-z]+-([0-9]+)- ]]; then
        # claude-sonnet-4-20250514 format
        MODEL_SHORT="${MODEL_NAME} ${BASH_REMATCH[1]}"
    else
        MODEL_SHORT="$MODEL_NAME"
    fi
fi

# Context window info
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
USAGE=$(echo "$input" | jq '.context_window.current_usage // empty')

output=""

# Add branch if available (cyan)
if [ -n "$BRANCH" ]; then
    output="${CYAN}${BRANCH}${RESET}"
fi

# Add model if available (magenta)
if [ -n "$MODEL_SHORT" ]; then
    if [ -n "$output" ]; then
        output="$output ${DIM}|${RESET} ${MAGENTA}${MODEL_SHORT}${RESET}"
    else
        output="${MAGENTA}${MODEL_SHORT}${RESET}"
    fi
fi

# Add context usage if available
if [ -n "$CONTEXT_SIZE" ] && [ "$USAGE" != "null" ] && [ -n "$USAGE" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq '.input_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq '.cache_read_input_tokens // 0')

    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    REMAINING=$((CONTEXT_SIZE - CURRENT_TOKENS))

    # Format remaining tokens (e.g., 120k)
    if [ $REMAINING -ge 1000 ]; then
        REMAINING_FMT="$((REMAINING / 1000))k"
    else
        REMAINING_FMT="$REMAINING"
    fi

    # Choose color based on usage
    if [ $PERCENT_USED -lt 50 ]; then
        BAR_COLOR="$GREEN"
    elif [ $PERCENT_USED -lt 80 ]; then
        BAR_COLOR="$YELLOW"
    else
        BAR_COLOR="$RED"
    fi

    # Build progress bar (10 segments)
    BAR_LENGTH=10
    FILLED=$((PERCENT_USED * BAR_LENGTH / 100))
    EMPTY=$((BAR_LENGTH - FILLED))

    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

    if [ -n "$output" ]; then
        output="$output ${DIM}|${RESET} ${BAR_COLOR}[${BAR}]${RESET} ${PERCENT_USED}% ${DIM}(${REMAINING_FMT})${RESET}"
    else
        output="${BAR_COLOR}[${BAR}]${RESET} ${PERCENT_USED}% ${DIM}(${REMAINING_FMT})${RESET}"
    fi
fi

echo -e "$output"
