#!/bin/bash
# Claude Code Stop hook - スリープ抑制解除
# タスク完了時に caffeinate を停止してスリープを再有効化

PID_FILE="$HOME/.claude/hooks/.caffeinate.pid"

if [ -f "$PID_FILE" ]; then
  CAFFEINATE_PID=$(cat "$PID_FILE")
  if kill -0 "$CAFFEINATE_PID" 2>/dev/null; then
    kill "$CAFFEINATE_PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
fi
