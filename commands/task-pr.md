---
description: Execute tasks as a commander with automatic PR creation upon completion
argument-hint: <task description>
---

# Task Commander with PR Creation

タスクを `/task` フローで実行し、完了後に `/create-pr` でPRを作成します。

---

## Task Input

$ARGUMENTS

---

## Phase 1: Branch Setup

**Goal**: Create a clean working branch for the changes

**Actions**:

1. Check current git status to ensure clean working directory
2. Fetch latest from remote
3. Create a feature branch with descriptive name based on task
   - Format: `feature/<short-description>` or `fix/<short-description>`
   - Use kebab-case, keep it concise

**Example**:

```bash
git fetch origin
git checkout -b feature/add-user-authentication origin/main
```

---

## Phase 2: Task Execution

**Goal**: Execute the task using `/task` workflow

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

タスク完了後、`/create-pr` フローを実行してPRを作成する:

1. **Pre-flight Checks**: ブランチ確認、変更確認
2. **Quality Verification**: テスト・リント・ビルド実行
3. **Commit Changes**: コミット作成
4. **Push and Create PR**: プッシュしてPR作成
5. **Summary**: PR URL報告

**参照**: `/create-pr` コマンドのフローをそのまま実行すること

---

## Phase 4: Final Summary

**Goal**: Report completion and provide PR link

**Deliverables**:

1. Mark all todos as completed
2. Provide summary:
   - Original task
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

### Git Safety

- Never force push
- Never commit secrets or credentials
- Always verify branch before pushing

---

## Example Full Execution

**Task**: "Add user authentication to the application"

1. **Branch**: `git checkout -b feature/user-authentication`
2. **Task Execution**: `/task` フローを実行（分析→エージェント選定→実行→統合）
3. **PR Creation**: `/create-pr` フローを実行（検証→コミット→PR作成）
4. **Summary**: Report with PR URL

---

Now create branch and begin task execution.
