#!/bin/bash
# Claude Code Stop hook - タスク完了通知スクリプト
# 完了したタスクの内容を含めて macOS 通知を表示

# stdin から hook input (JSON) を読み込む
INPUT=$(cat)

# トランスクリプトパスを抽出
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# デフォルトメッセージ
MESSAGE="タスクが完了しました"

# トランスクリプトからタスク内容を抽出
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # 最初のユーザーメッセージ（タスク内容）を取得
  TASK_CONTENT=$(head -n 20 "$TRANSCRIPT_PATH" | jq -r '
    select(.type == "human") |
    .message.content[]? |
    select(.type == "text") |
    .text
  ' 2>/dev/null | head -n 1 | head -c 100)

  if [ -n "$TASK_CONTENT" ]; then
    # 改行を空白に置換し、長すぎる場合は省略
    TASK_CONTENT=$(echo "$TASK_CONTENT" | tr '\n' ' ' | sed 's/  */ /g')
    if [ ${#TASK_CONTENT} -gt 80 ]; then
      TASK_CONTENT="${TASK_CONTENT:0:80}..."
    fi
    MESSAGE="完了: ${TASK_CONTENT}"
  fi
fi

# macOS 通知を送信
osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" sound name \"Glass\""
