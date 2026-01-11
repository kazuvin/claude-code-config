#!/bin/bash
# Claude Code Stop hook - タスク完了通知スクリプト
# 完了したタスクの内容を含めて macOS 通知を表示

# デバッグログ関数
# 使用方法: DEBUG=1 で有効化
debug_log() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> ~/.claude/hooks/debug.log
  fi
}

# stdin から hook input (JSON) を読み込む
INPUT=$(cat)
debug_log "INPUT: $INPUT"

# トランスクリプトパスを抽出
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
debug_log "TRANSCRIPT_PATH: $TRANSCRIPT_PATH"

# デフォルトメッセージ
MESSAGE="タスクが完了しました"

# トランスクリプトからタスク内容を抽出
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  debug_log "Transcript file exists, extracting task content..."
  # 最初のユーザーメッセージ（タスク内容）を取得
  # type が "user" のレコードから message.content を抽出
  # content は文字列または配列の場合があるため両方に対応
  TASK_CONTENT=$(head -n 20 "$TRANSCRIPT_PATH" | jq -r '
    select(.type == "user") |
    .message.content |
    if type == "string" then .
    elif type == "array" then (.[] | select(.type == "text") | .text)
    else empty end
  ' 2>/dev/null | head -n 1 | head -c 100)
  debug_log "Raw TASK_CONTENT: $TASK_CONTENT"

  if [ -n "$TASK_CONTENT" ]; then
    # 改行を空白に置換し、長すぎる場合は省略
    TASK_CONTENT=$(echo "$TASK_CONTENT" | tr '\n' ' ' | sed 's/  */ /g')
    if [ ${#TASK_CONTENT} -gt 80 ]; then
      TASK_CONTENT="${TASK_CONTENT:0:80}..."
    fi
    MESSAGE="完了: ${TASK_CONTENT}"
    debug_log "Final MESSAGE: $MESSAGE"
  else
    debug_log "TASK_CONTENT is empty, using default message"
  fi
else
  debug_log "Transcript file not found or path is empty"
fi

# macOS 通知を送信
debug_log "Sending notification..."
osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" sound name \"Glass\""
debug_log "Notification sent (exit code: $?)"
