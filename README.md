# ~/.claude — Claude Code Configuration

Claude Code のユーザー設定を複数デバイス間で同期するためのリポジトリ。

## 管理対象

| パス | 内容 |
|---|---|
| `settings.json` | permissions / hooks / statusLine / enabledPlugins / 個人設定 |
| `hooks/notify-complete.sh` | Stop hook — タスク完了を音声読み上げ + 効果音 |
| `hooks/notify-ask-user.sh` | PreToolUse:AskUserQuestion hook — 質問時に音声読み上げ |
| `hooks/statusline.sh` | 5行ステータスライン。現在地/モデル + コンテキスト/5時間枠/週次枠のゲージ |
| `CLAUDE.md` | 全プロジェクト共通のグローバル指示 |
| `.gitignore` | ランタイム状態を除外 |

これ以外（`projects/` `sessions/` `plugins/` `skills/` `cache/` など）はすべて
マシンローカルなランタイム状態で、git 管理外。

## セットアップ

```bash
git clone <repository-url> ~/.claude
```

プラグインは設定ファイルに含まれないため、別途インストールする:

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install frontend-design@claude-plugins-official
/plugin install swift-lsp@claude-plugins-official
```

既存の `~/.claude` がある場合は退避してからクローンする。

## Hooks

`notify-complete.sh` / `notify-ask-user.sh` は macOS の `say` / `afplay` を使う音声通知。
デバッグは `DEBUG=1` で `hooks/debug.log` に出力される。

## Status line

`hooks/statusline.sh` はヘッダ2行 + 予算1つにつき1行を出力する:

```
📁 ~/.claude  🌿 main +23 ~5
🤖 Opus 5 (1M context) · high · think · 💰$7.33
🧠 context ███▎░░░░░░░░░░░░  21%  792k left
⏳ 5-hour  █████▌░░░░░░░░░░  35%  ↻2h25m  08/26 14:20 JST
📅 weekly  ▊░░░░░░░░░░░░░░░   5%  ↻4d18h  08/31 06:00 JST
```

ゲージ3行はどれも読み方が同じで、**バーと％が使った分、右の淡色が残り**。
コンテキストは残りトークン数、上限はリセットまでの残り時間と、解除される日時。

- **🧠 context** — コンテキストウィンドウ
- **⏳ 5-hour / 📅 weekly** — Claude.ai サブスクの5時間枠と週次枠
- バーは1セルを8分割した精度なので、10%刻みで飛ばず滑らかに動く

### リセット時刻

`resets_at`（Unix epoch）を JST に変換して表示する。タイムゾーンは
スクリプト冒頭の `RESET_TZ` で変更できる（`%Z` から `JST` の表記も自動で追従する）。

`date` は macOS の BSD 形式（`-r`）を先に試し、Linux では GNU 形式（`-d @`）に
フォールバックする。どちらも失敗はstderrにしか出さないため、`||` で値が壊れない。

### 配色

行ごとに シアン / 青 / マゼンタ。70% で黄、90% で赤に切り替わる。

緑は使っていない。`dark-daltonized` テーマは色覚多様性向けであり、緑と赤・緑と黄は
最も判別しにくい組み合わせのため。git の差分も同じ理由で `+staged` をシアン、
`~unstaged` を黄にしている。

### レイアウトの制約

**折り返しは厳禁**。一度1行に詰めた際、82桁になって80桁端末で末尾のゲージが
分断された。ヘッダも絵文字込みで84桁に達したため2行に分けてある。現在は最長57桁。

- 絵文字は**全て East Asian Wide（2桁固定）のものだけ**を使う。`⏱`（U+23F1）は
  幅が不定なので不可 — 混ぜるとその行のバーが1桁ずれる
- 絵文字はパディング対象の外に置く。`printf` の `%-*s` は文字数で詰めるため、
  幅2の文字をフィールド内に入れると桁が狂う
- 深いパスは末尾2成分に短縮される（`…/core/src`）

### 実装メモ

- 入力フィールドは[公式の statusLine スキーマ](https://code.claude.com/docs/en/statusline)に準拠
- `rate_limits` は Pro/Max のみ、かつセッション初回のAPI応答後にしか存在しない。
  無い枠は行ごと省略される（API キー利用時は3行になる）
- 依存は `jq` のみ。git 情報は `session_id` をキーに5秒キャッシュ（公式の推奨手順）
- bash 3.2（macOS 同梱の `/bin/bash`）で動作

## Permissions

`defaultMode: "auto"` で運用しているため、`allow` は auto mode が自動承認しない
書き込み系コマンド（git 変更操作 / gh / パッケージマネージャ）のみを列挙している。
読み取り系コマンドや `Read` `Edit` などのツール名は auto mode がカバーするため列挙しない。

`deny` は機密ファイルの読み取りと破壊的コマンドを禁止する安全弁。

## 同期

```bash
cd ~/.claude && git pull       # 取得
cd ~/.claude && git add -A && git commit && git push   # 反映
```
