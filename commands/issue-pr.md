---
description: Execute task-pr workflow from a GitHub issue
argument-hint: <issue number or URL>
---

# Issue to PR Commander

GitHub issueからタスク内容を取得し、`/task-pr` のワークフローを実行してPRを作成します。

**並列実行対応**: git worktree を使用して独立した作業環境で実行するため、複数のissueを同時に処理可能です。

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

## Phase 2: Worktree Setup

**Goal**: Create an isolated working environment using git worktree

**Why worktree?**:

- 複数issueを並列処理する際、各タスクが独立したディレクトリで作業可能
- mainブランチや他のタスクの作業に影響を与えない
- 作業完了後にクリーンアップが容易

**Branch naming based on issue labels**:

| ラベル                   | ブランチ形式                              |
| ------------------------ | ----------------------------------------- |
| `bug`, `fix`             | `fix/issue-<number>-<short-desc>`         |
| `feature`, `enhancement` | `feature/issue-<number>-<short-desc>`     |
| `refactor`               | `refactor/issue-<number>-<short-desc>`    |
| `docs`, `documentation`  | `docs/issue-<number>-<short-desc>`        |
| その他                   | `feature/issue-<number>-<short-desc>`     |

**Worktree setup**:

```bash
# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)

# Create worktree directory if not exists
mkdir -p "$REPO_ROOT/.worktrees"

# Create worktree with new branch (example for issue #42)
git fetch origin
git worktree add -b feature/issue-42-dark-mode \
  "$REPO_ROOT/.worktrees/feature-issue-42-dark-mode" origin/main

# Change to worktree directory
cd "$REPO_ROOT/.worktrees/feature-issue-42-dark-mode"
```

**Important**: Add `.worktrees/` to `.gitignore` if not already present.

---

## Phase 3: Task Execution

**Goal**: Execute Task Commander workflow in the worktree using issue content

### Step 3.1: Task Analysis

1. Parse and understand the issue requirements
2. Break down into subtasks that can be delegated to specialized agents
3. Identify dependencies between subtasks
4. Create a todo list with TodoWrite to track progress

### Step 3.2: Agent Selection

**Use the Task tool with appropriate `subagent_type` to delegate work.**

| Agent Type               | Best For                                                     |
| ------------------------ | ------------------------------------------------------------ |
| `Explore`                | Codebase exploration, finding files, understanding structure |
| `Plan`                   | Designing implementation strategies, architectural decisions |
| `frontend-developer`     | React components, UI implementation, web standards           |
| `typescript-pro`         | TypeScript development, type system, full-stack TS           |
| `react-specialist`       | React 18+, hooks, server components, performance             |
| `nextjs-developer`       | Next.js 14+, App Router, server actions                      |
| `rust-engineer`          | Systems programming, Rust, performance-critical code         |
| `cli-developer`          | CLI tools, terminal applications                             |
| `debugger`               | Issue diagnosis, root cause analysis                         |
| `error-detective`        | Error pattern analysis, distributed debugging                |
| `performance-engineer`   | Optimization, profiling, bottleneck identification           |
| `code-reviewer`          | Code quality, security, best practices                       |
| `refactoring-specialist` | Safe code transformation, design patterns                    |
| `tdd-specialist`         | Test-driven development, test first approach                 |
| `security-auditor`       | Security assessments, vulnerability detection                |
| `accessibility-tester`   | WCAG compliance, screen reader compatibility                 |
| `ui-designer`            | Visual design, interaction patterns                          |
| `mobile-app-developer`   | iOS/Android, cross-platform development                      |
| `git-workflow-manager`   | Git strategies, branching, collaboration                     |
| `dx-optimizer`           | Build performance, developer experience                      |
| `seo-specialist`         | Technical SEO, search optimization                           |
| `general-purpose`        | Complex multi-step tasks, research                           |
| `Bash`                   | Shell commands, git operations                               |

### Step 3.3: Parallel Execution

**CRITICAL**: Launch multiple agents simultaneously by sending a SINGLE message with MULTIPLE Task tool calls.

```
Independent Group A: Launch agents A1, A2, A3 in parallel
    ↓ (wait for all to complete)
Dependent Group B: Launch agents B1, B2 that need A's results
    ↓ (wait for all to complete)
Final Group C: Launch final agents with all context
```

### Step 3.4: Result Synthesis

1. Collect outputs from all completed agents
2. Resolve any conflicts or inconsistencies
3. Identify gaps or areas needing additional work
4. Create unified deliverable

### Step 3.5: Verification

1. Review overall completion against original task
2. Run any necessary validation (tests, builds, etc.)
3. Fix any issues before proceeding to PR creation

---

## Phase 4: PR Creation

**Goal**: Create PR with issue linkage

PR作成時の特別な設定:

1. **PR Title**: issue番号を含める
   - 例: `feat: Add dark mode support (#42)`

2. **PR Body**: `Closes #<issue-number>` を追加
   - これによりPRマージ時にissueが自動クローズされる

3. `/create-pr` フローを実行

---

## Phase 5: Cleanup & Summary

**Goal**: Clean up worktree and report completion

**Actions**:

1. Return to original repository directory
2. Remove worktree (optional - can keep for reference)

```bash
# Return to original directory
cd "$REPO_ROOT"

# Remove worktree (optional)
git worktree remove "$REPO_ROOT/.worktrees/feature-issue-42-dark-mode"

# Or list worktrees to verify
git worktree list
```

**Deliverables**:

1. Issue番号と内容
2. Worktree location used
3. 作成したブランチ名
4. 使用したエージェント
5. **PR URL**（issueとリンク済み）

---

## Parallel Execution Example

When processing multiple issues simultaneously:

```
Terminal 1: /issue-pr 42
  → Creates .worktrees/feature-issue-42-dark-mode
  → Works independently

Terminal 2: /issue-pr 43
  → Creates .worktrees/fix-issue-43-login-bug
  → Works independently

Terminal 3: /issue-pr 44
  → Creates .worktrees/feature-issue-44-user-profile
  → Works independently
```

Each issue is processed in isolation, no conflicts.

---

## Example Full Execution

**Input**: `/issue-pr 42`

1. **Issue取得**: GitHub issue #42 の情報を取得
   ```
   Title: Add dark mode support
   Body: Users should be able to toggle between light and dark themes...
   Labels: enhancement, ui
   ```

2. **Worktree Setup**:
   ```bash
   git worktree add -b feature/issue-42-dark-mode \
     "$REPO_ROOT/.worktrees/feature-issue-42-dark-mode" origin/main
   cd "$REPO_ROOT/.worktrees/feature-issue-42-dark-mode"
   ```

3. **タスク構築**:
   ```
   Issue #42: Add dark mode support

   Users should be able to toggle between light and dark themes.
   Requirements:
   - Theme toggle in settings
   - Persist preference in localStorage
   - System preference detection

   Labels: enhancement, ui
   ```

4. **Task実行**: `/task` フローを実行

5. **PR作成**:
   ```
   Title: feat: Add dark mode support (#42)
   Body: ... Closes #42 ...
   ```

6. **Cleanup**: worktreeを削除（オプション）

7. **完了報告**: PR URL を提供

---

Now retrieve the issue and begin execution.
