---
description: Create a pull request from current changes
argument-hint: [options]
---

# Create Pull Request

現在の変更からPRを作成します。品質検証、コミット、PR作成までを担当します。

---

## Context

$ARGUMENTS

---

## Phase 1: Pre-flight Checks

**Goal**: Ensure the working directory is ready for PR creation

**Actions**:

1. Verify we are on a feature branch (not main/master)
2. Check for uncommitted changes with `git status`
3. Ensure there are commits to push

**Validation**:

```bash
# Current branch should not be main/master
git branch --show-current

# Check for changes
git status
git log origin/main..HEAD --oneline
```

---

## Phase 2: Quality Verification

**Goal**: Ensure code is PR-ready

**Actions**:

1. Run tests if available (`npm test`, `pytest`, etc.)
2. Run linter/formatter if configured
3. Run build to verify no compilation errors
4. Optionally launch code-reviewer agent for quality check

**Must Pass Before PR**:

- [ ] All tests pass
- [ ] No linting errors
- [ ] Build succeeds

If any checks fail, fix issues before proceeding.

---

## Phase 3: Commit Changes (if needed)

**Goal**: Create clean, well-organized commits

**Actions**:

1. Review all changes with `git status` and `git diff`
2. Stage changes logically
3. Write clear commit messages following conventional commits:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `refactor:` for refactoring
   - `docs:` for documentation
   - `test:` for tests
   - `chore:` for maintenance

**Commit Message Format**:

```
<type>: <short description>

<optional body explaining what and why>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Phase 4: Push and Create PR

**Goal**: Create a comprehensive, review-ready PR

**Actions**:

1. Push branch to remote: `git push -u origin <branch-name>`
2. Create PR using `gh pr create` with proper formatting

**PR Template**:

```markdown
## Summary

<2-3 bullet points describing what this PR does>

## Changes

<List of key changes made>

## Test Plan

- [ ] <How to verify this works>
- [ ] <Any manual testing steps>

## Notes

<Any additional context, trade-offs, or follow-up items>

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Example Command**:

```bash
gh pr create --title "feat: Add user authentication" --body "$(cat <<'EOF'
## Summary

- Implements JWT-based authentication system
- Adds login/logout endpoints
- Integrates with existing user model

## Changes

- Added `src/auth/` module with authentication logic
- Created middleware for protected routes
- Added tests for auth flows

## Test Plan

- [ ] Run `npm test` - all tests pass
- [ ] Test login with valid credentials
- [ ] Test protected route access

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Phase 5: Summary

**Goal**: Report completion and provide PR link

**Deliverables**:

1. Provide summary:
   - Branch name
   - Commits included
   - Files modified
   - **PR URL** (most important!)
   - Suggested reviewers if applicable

---

## Options (via $ARGUMENTS)

以下のオプションを $ARGUMENTS で受け取ることができる:

- `--skip-tests`: テストをスキップ
- `--skip-lint`: リントをスキップ
- `--draft`: ドラフトPRとして作成
- `--issue <number>`: 関連issueを指定（`Closes #<number>` を追加）

---

## Git Safety

- Never force push
- Never commit secrets or credentials
- Always verify branch before pushing
- Refuse to create PR from main/master branch

---

Now verify the current state and begin PR creation process.
