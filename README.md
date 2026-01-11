# Claude Code Configuration

Claude Code の設定ファイルを管理するリポジトリです。

## セットアップ手順

### 新しいデバイスでの初期設定

```bash
# 1. 既存の .claude ディレクトリをバックアップ（存在する場合）
mv ~/.claude ~/.claude.bak

# 2. リポジトリをクローン
git clone <repository-url> ~/.claude

# 3. プラグインを再インストール
claude /plugins install example-skills
claude /plugins install document-skills
claude /plugins install frontend-design
```

### 既存環境への適用

```bash
# 1. 既存設定をバックアップ
cp ~/.claude/settings.json ~/.claude/settings.json.bak

# 2. リポジトリから設定を取得
cd ~/.claude
git init
git remote add origin <repository-url>
git fetch origin
git checkout origin/main -- settings.json .gitignore

# 3. プラグインを再インストール（必要に応じて）
claude /plugins install example-skills
claude /plugins install document-skills
claude /plugins install frontend-design
```

## 管理対象ファイル

| ファイル | 説明 |
|---------|------|
| `settings.json` | hooks, enabledPlugins, statusLine などの設定 |
| `hooks/notify-complete.sh` | タスク完了時の通知スクリプト |
| `.gitignore` | Git除外設定 |
| `README.md` | このファイル |

## 設定内容

### Hooks

- **Stop**: タスク完了時に macOS 通知を表示（完了したタスクの内容を含む）

### Status Line

- 現在の Git ブランチを表示

### Enabled Plugins

- `example-skills@anthropic-agent-skills`
- `document-skills@anthropic-agent-skills`
- `frontend-design@claude-plugins-official`

## 設定変更時

```bash
cd ~/.claude
git add settings.json
git commit -m "Update settings"
git push
```

## 他デバイスへの同期

```bash
cd ~/.claude
git pull
```
