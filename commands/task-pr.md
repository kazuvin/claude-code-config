---
description: Execute tasks as a commander with automatic PR creation upon completion
argument-hint: <task description>
---

# Task Commander with PR Creation

タスクを `/task` フローで実行し、完了後に `/create-pr` でPRを作成します。

**並列実行対応**: git worktree を使用して独立した作業環境で実行するため、複数タスクを同時に実行可能です。

---

## Task Input

$ARGUMENTS

---

## Phase 1: Worktree Setup

**Goal**: Create an isolated working environment using git worktree

**Why worktree?**:

- 複数タスクを並列実行する際、各タスクが独立したディレクトリで作業可能
- mainブランチや他のタスクの作業に影響を与えない
- 作業完了後にクリーンアップが容易

**Actions**:

1. Check current git status and repository root
2. Generate unique worktree name based on task
3. Create worktree with feature branch

**Worktree naming convention**:

```
<repo-root>/.worktrees/<branch-name>
```

**Example**:

```bash
# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)

# Create worktree directory if not exists
mkdir -p "$REPO_ROOT/.worktrees"

# Create worktree with new branch
git fetch origin
git worktree add -b feature/add-user-auth "$REPO_ROOT/.worktrees/feature-add-user-auth" origin/main

# Change to worktree directory
cd "$REPO_ROOT/.worktrees/feature-add-user-auth"
```

**Important**: Add `.worktrees/` to `.gitignore` if not already present.

---

## Phase 2: Task Execution

**Goal**: Execute the task using `/task` workflow in the worktree

**Context**: All work happens in the worktree directory, not the main repository.

タスク内容をそのまま `/task` フローに渡して実行する:

1. **Task Analysis**: タスクを分析し、サブタスクに分解
2. **Agent Selection**: 適切なエージェントを選定
3. **Parallel Execution**: エージェントを並列実行
4. **Result Synthesis**: 結果を統合
5. **Verification & Delivery**: 品質確認

**参照**: `/task` コマンドのフロー（Phase 1〜5）をそのまま実行すること

---

## Phase 3: PR Creation

**Goal**: Create PR using `/create-pr` workflow

タスク完了後、worktree内で `/create-pr` フローを実行してPRを作成する:

1. **Pre-flight Checks**: ブランチ確認、変更確認
2. **Quality Verification**: テスト・リント・ビルド実行
3. **Commit Changes**: コミット作成
4. **Push and Create PR**: プッシュしてPR作成
5. **Summary**: PR URL報告

**参照**: `/create-pr` コマンドのフローをそのまま実行すること

---

## Phase 4: Cleanup & Summary

**Goal**: Clean up worktree and report completion

**Actions**:

1. Return to original repository directory
2. Remove worktree (optional - can keep for reference)

```bash
# Return to original directory
cd "$REPO_ROOT"

# Remove worktree (optional)
git worktree remove "$REPO_ROOT/.worktrees/feature-add-user-auth"

# Or list worktrees to verify
git worktree list
```

**Deliverables**:

1. Mark all todos as completed
2. Provide summary:
   - Original task
   - Worktree location used
   - Agents used and their contributions
   - Key decisions made
   - Files modified
   - **PR URL** (most important!)
   - Suggested reviewers if applicable

---

## Execution Guidelines

### Communication with user

- Report high-level progress, not every detail
- Surface important decisions that need user input
- Present synthesized results, not raw agent outputs
- **Always provide the PR URL at the end**

### Error handling

- If tests/build fail, fix before creating PR
- Escalate to user only when truly blocked
- If worktree creation fails, fall back to regular branch checkout (with warning)

### Git Safety

- Never force push
- Never commit secrets or credentials
- Always verify branch before pushing
- Clean up worktrees after PR is merged

---

## Parallel Execution Example

When running multiple `/task-pr` commands simultaneously:

```
Terminal 1: /task-pr Add user authentication
  → Creates .worktrees/feature-add-user-auth
  → Works independently

Terminal 2: /task-pr Add dark mode
  → Creates .worktrees/feature-add-dark-mode
  → Works independently

Terminal 3: /task-pr Fix login bug
  → Creates .worktrees/fix-login-bug
  → Works independently
```

Each task operates in isolation, no conflicts.

---

## Example Full Execution

**Task**: "Add user authentication to the application"

1. **Worktree Setup**:
   ```bash
   git worktree add -b feature/user-authentication \
     "$REPO_ROOT/.worktrees/feature-user-authentication" origin/main
   cd "$REPO_ROOT/.worktrees/feature-user-authentication"
   ```

2. **Task Execution**: `/task` フローを実行（分析→エージェント選定→実行→統合）

3. **PR Creation**: `/create-pr` フローを実行（検証→コミット→PR作成）

4. **Cleanup**: worktreeを削除（オプション）

5. **Summary**: Report with PR URL

---

Now create worktree and begin task execution.
