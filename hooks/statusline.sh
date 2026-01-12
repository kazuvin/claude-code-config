#!/bin/bash
# Claude Code statusLine script - displays git branch and context usage

input=$(cat)

# Git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Context window info
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
USAGE=$(echo "$input" | jq '.context_window.current_usage // empty')

output=""

# Add branch if available
if [ -n "$BRANCH" ]; then
    output="$BRANCH"
fi

# Add context usage if available
if [ -n "$CONTEXT_SIZE" ] && [ "$USAGE" != "null" ] && [ -n "$USAGE" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq '.input_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq '.cache_read_input_tokens // 0')

    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    REMAINING=$((CONTEXT_SIZE - CURRENT_TOKENS))

    # Format remaining tokens (e.g., 180k)
    if [ $REMAINING -ge 1000 ]; then
        REMAINING_FORMATTED="$((REMAINING / 1000))k"
    else
        REMAINING_FORMATTED="$REMAINING"
    fi

    if [ -n "$output" ]; then
        output="$output | Context: ${PERCENT_USED}% (${REMAINING_FORMATTED} left)"
    else
        output="Context: ${PERCENT_USED}% (${REMAINING_FORMATTED} left)"
    fi
fi

echo "$output"
