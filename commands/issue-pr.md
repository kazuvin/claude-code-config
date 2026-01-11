---
description: Execute task-pr workflow from a GitHub issue
argument-hint: <issue number or URL>
---

# Issue to PR Commander

GitHub issueからタスク内容を取得し、`/task-pr` のワークフローを実行してPRを作成します。

---

## Input

$ARGUMENTS

---

## Phase 1: Issue Retrieval

**Goal**: issueから必要な情報を取得し、タスク内容を構築する

**Actions**:

1. 引数を解析:
   - 数字のみ: issue番号として扱う
   - URL: `owner/repo#number` を抽出
   - 例: `123`, `https://github.com/owner/repo/issues/123`

2. GitHub MCP ツールでissue情報を取得:
   ```
   mcp__plugin_github_github__issue_read with method: "get"
   ```

3. 以下の情報を抽出:
   - **タイトル**: issueのタイトル
   - **本文**: 詳細な説明、要件
   - **ラベル**: bug, feature, enhancement など
   - **関連issue**: 参照されている他のissue

4. タスク内容を構築:
   ```
   Issue #<number>: <title>

   <issue body>

   Labels: <labels>
   ```

---

## Phase 2: Task-PR Execution

**Goal**: `/task-pr` フローを実行してタスクを完了しPRを作成する

issueから取得した内容をタスクとして `/task-pr` フローを実行する。

**issue-pr 固有の設定**:

1. **ブランチ名**: issueのラベルに基づいて決定

   | ラベル                   | ブランチ形式                              |
   | ------------------------ | ----------------------------------------- |
   | `bug`, `fix`             | `fix/issue-<number>-<short-desc>`         |
   | `feature`, `enhancement` | `feature/issue-<number>-<short-desc>`     |
   | `refactor`               | `refactor/issue-<number>-<short-desc>`    |
   | `docs`, `documentation`  | `docs/issue-<number>-<short-desc>`        |
   | その他                   | `feature/issue-<number>-<short-desc>`     |

2. **PR作成時**: `/create-pr` に `--issue <number>` オプションを渡す
   - これにより PR 本文に `Closes #<issue-number>` が追加される
   - PRタイトルにもissue番号を含める

**参照**: `/task-pr` コマンドのフロー（Phase 1〜4）をそのまま実行すること

---

## Phase 3: Final Summary

**Goal**: 完了報告

**Deliverables**:

1. Issue番号と内容
2. 作成したブランチ名
3. 使用したエージェント
4. **PR URL**（issueとリンク済み）

---

## Example Execution

**Input**: `/issue-pr 42`

1. **Issue取得**: GitHub issue #42 の情報を取得
   ```
   Title: Add dark mode support
   Body: Users should be able to toggle between light and dark themes...
   Labels: enhancement, ui
   ```

2. **タスク構築**:
   ```
   Issue #42: Add dark mode support

   Users should be able to toggle between light and dark themes.
   Requirements:
   - Theme toggle in settings
   - Persist preference in localStorage
   - System preference detection

   Labels: enhancement, ui
   ```

3. **task-pr 実行**: ブランチ `feature/issue-42-dark-mode` を作成し、タスク実行

4. **PR作成**: `--issue 42` オプション付きで `/create-pr` 実行
   ```
   Title: feat: Add dark mode support (#42)
   Body: ... Closes #42 ...
   ```

5. **完了報告**: PR URL を提供

---

Now retrieve the issue and begin execution.
