#!/bin/bash
# Claude Code AskUserQuestion hook - ユーザー入力待ち通知スクリプト
# ユーザーに質問が投げられた際に音声で通知

# デバッグログ関数
# 使用方法: DEBUG=1 で有効化
debug_log() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> ~/.claude/hooks/debug.log
  fi
}

# stdin から hook input (JSON) を読み込む
INPUT=$(cat)
debug_log "AskUser INPUT: $INPUT"

# tool_input から質問内容を抽出
# AskUserQuestion の questions 配列から最初の質問を取得
QUESTION=$(echo "$INPUT" | jq -r '.tool_input.questions[0].question // empty' 2>/dev/null)
debug_log "QUESTION: $QUESTION"

# デフォルトメッセージ
MESSAGE="確認をお願いします"

if [ -n "$QUESTION" ]; then
  # 長すぎる場合は省略（音声なので簡潔に）
  if [ ${#QUESTION} -gt 50 ]; then
    MESSAGE="質問があります、確認をお願いします"
  else
    MESSAGE="${QUESTION}"
  fi
  debug_log "Final MESSAGE: $MESSAGE"
else
  debug_log "QUESTION is empty, using default message"
fi

# Ghostty タブに 🔔 を表示 (OSC 0)
# 質問内容を短くしてタブタイトルに含める
TAB_QUESTION="${QUESTION:0:30}"
printf '\033]0;🔔 確認待ち - %s\007' "$TAB_QUESTION" > /dev/tty 2>/dev/null || true
debug_log "Tab title updated: 🔔 確認待ち - $TAB_QUESTION"

# macOS デスクトップ通知 (OSC 9)
printf '\033]9;🔔 %s\007' "$MESSAGE" > /dev/tty 2>/dev/null || true
debug_log "Desktop notification sent via OSC 9"

# 音声で通知
debug_log "Speaking notification..."
say "$MESSAGE"
debug_log "Speech completed (exit code: $?)"
