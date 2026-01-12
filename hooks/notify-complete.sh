#!/bin/bash
# Claude Code Stop hook - タスク完了通知スクリプト
# 完了したタスクの内容を音声で通知し、効果音を再生

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
  TASK_CONTENT=$(head -n 50 "$TRANSCRIPT_PATH" | jq -r '
    select(.type == "user") |
    .message.content |
    if type == "string" then .
    elif type == "array" then (.[] | select(.type == "text") | .text)
    else empty end
  ' 2>/dev/null | head -n 1 | head -c 200)
  debug_log "Raw TASK_CONTENT: $TASK_CONTENT"

  if [ -n "$TASK_CONTENT" ]; then
    # 改行を空白に置換
    TASK_CONTENT=$(echo "$TASK_CONTENT" | tr '\n' ' ' | sed 's/  */ /g')
    # 音声用に短く（50文字程度）
    if [ ${#TASK_CONTENT} -gt 50 ]; then
      TASK_CONTENT="${TASK_CONTENT:0:50}"
    fi
    MESSAGE="${TASK_CONTENT}、が完了しました"
    debug_log "Final MESSAGE: $MESSAGE"
  else
    debug_log "TASK_CONTENT is empty, using default message"
  fi
else
  debug_log "Transcript file not found or path is empty"
fi

# Ghostty タブに 🔔 を表示 (OSC 0)
printf '\033]0;🔔 完了\007' > /dev/tty 2>/dev/null || true
debug_log "Tab title updated with bell icon"

# macOS デスクトップ通知 (OSC 9)
printf '\033]9;🔔 %s\007' "$MESSAGE" > /dev/tty 2>/dev/null || true
debug_log "Desktop notification sent via OSC 9"

# 音声で通知し、効果音を再生
debug_log "Speaking notification..."
say "$MESSAGE"
debug_log "Speech completed (exit code: $?)"
afplay /System/Library/Sounds/Purr.aiff
debug_log "Sound played"
