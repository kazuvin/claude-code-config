#!/bin/bash
# Claude Code UserPromptSubmit hook - スリープ抑制開始
# タスク開始時に caffeinate でMacのスリープを無効化

PID_FILE="$HOME/.claude/hooks/.caffeinate.pid"

# 既存の caffeinate プロセスがあれば停止
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
fi

# caffeinate をバックグラウンドで起動
# -d: ディスプレイスリープ防止
# -i: アイドルスリープ防止
# -s: システムスリープ防止
caffeinate -dis &
CAFFEINATE_PID=$!
echo "$CAFFEINATE_PID" > "$PID_FILE"
