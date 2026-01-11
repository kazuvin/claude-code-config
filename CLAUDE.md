# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Claude Code configuration repository (`~/.claude`) for syncing settings, hooks, commands, and agent definitions across multiple devices.

## Key Files and Structure

| File/Directory | Purpose |
|----------------|---------|
| `settings.json` | Hooks, permissions, enabled plugins, status line config |
| `hooks/` | Shell scripts triggered by Claude Code events |
| `commands/` | Custom slash commands (`/task`, `/task-pr`, `/issue-pr`, `/create-pr`) |
| `agents/` | Specialized agent definitions for Task tool delegation |

## Hooks System

Hooks in `hooks/` respond to Claude Code events:

- **Stop** (`notify-complete.sh`): Voice notification with task summary when Claude finishes
- **PreToolUse:AskUserQuestion** (`notify-ask-user.sh`): Voice notification when user input needed

Both hooks use macOS `say` command for TTS. Debug with `DEBUG=1`.

## Commands Architecture

Commands in `commands/` define slash command workflows:

- `/task` - Task Commander pattern: analyzes, delegates to specialized subagents, synthesizes results
- `/task-pr` - Task execution with automatic PR creation
- `/issue-pr` - Task from GitHub issue with PR
- `/create-pr` - PR creation workflow

## Permission Configuration

`settings.json` defines auto-approved and denied operations. Changes here affect what Claude can do without confirmation.

Denied by default: `.env`, secrets, destructive commands (`rm -rf`, `sudo`, `git push --force`).

## Syncing Changes

```bash
cd ~/.claude
git add settings.json hooks/ commands/ agents/
git commit -m "Update config"
git push
```

On other devices:
```bash
cd ~/.claude
git pull
```

## Plugin Installation

After cloning, reinstall plugins:
```bash
/plugin marketplace add anthropics/skills
/plugin marketplace add anthropics/claude-plugins-official
/plugin install example-skills@anthropic-agent-skills
/plugin install document-skills@anthropic-agent-skills
/plugin install frontend-design@claude-plugins-official
/plugin install github@claude-plugins-official
```
