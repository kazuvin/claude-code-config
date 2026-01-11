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
# Step 1: マーケットプレイスを登録
/plugin marketplace add anthropics/skills
/plugin marketplace add anthropics/claude-plugins-official

# Step 2: プラグインをインストール（デフォルトはuser scope）
/plugin install example-skills@anthropic-agent-skills
/plugin install document-skills@anthropic-agent-skills
/plugin install frontend-design@claude-plugins-official
/plugin install github@claude-plugins-official
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
# Step 1: マーケットプレイスを登録
/plugin marketplace add anthropics/skills
/plugin marketplace add anthropics/claude-plugins-official

# Step 2: プラグインをインストール（デフォルトはuser scope）
/plugin install example-skills@anthropic-agent-skills
/plugin install document-skills@anthropic-agent-skills
/plugin install frontend-design@claude-plugins-official
/plugin install github@claude-plugins-official
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

### Permissions（自動許可設定）

`/task`, `/task-pr`, `/issue-pr`, `/create-pr` などのコマンドをスムーズに実行するため、安全な操作は自動許可されています。

#### 自動許可される操作（allow）

| カテゴリ | 操作 |
|---------|------|
| **ファイル操作** | Read, Edit, Write, Glob, Grep, LS |
| **タスク管理** | Task, TodoWrite |
| **Web** | WebFetch, WebSearch |
| **Git（読み取り）** | status, diff, log, branch, fetch, show, rev-parse, remote |
| **Git（ローカル変更）** | add, commit, checkout, stash, worktree |
| **GitHub CLI** | gh pr, gh issue, gh api |
| **開発ツール** | npm/pnpm/yarn run/test, npx, node, python, cargo, go, make |
| **ファイルシステム** | mkdir, ls, cat, head, tail, wc, pwd, which, echo |

#### 拒否される操作（deny）

| カテゴリ | 操作 |
|---------|------|
| **機密ファイル** | .env, .env.*, secrets/, *.pem, credentials*, .aws/, .ssh/ |
| **危険なコマンド** | rm -rf, sudo, chmod 777, > /dev |
| **危険なGit操作** | git push --force/-f, git reset --hard |

#### 確認が求められる操作

`allow`/`deny` に含まれない操作は実行前に確認が表示されます。例：
- `git push`（通常のプッシュ）
- `npm install`
- その他の未定義コマンド

### Enabled Plugins

- `example-skills@anthropic-agent-skills`
- `document-skills@anthropic-agent-skills`
- `frontend-design@claude-plugins-official`
- `github@claude-plugins-official`

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
