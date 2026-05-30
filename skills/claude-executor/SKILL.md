---
name: claude-executor
description: Use when the user explicitly wants Codex to delegate implementation or repeated trial-and-error work to local Claude Code backed by DeepSeek API, then have Codex inspect results, diffs, logs, tests, and decide whether to accept, retry, or disable delegation. Requires explicit enablement through the bundled config script.
metadata:
  short-description: Delegate work to local Claude Code, then verify with Codex
---

# Claude Executor

Use this skill only when the user explicitly asks to enable or use the Claude Code + DeepSeek executor workflow.

## Guardrails

- Default state is disabled.
- Do not call Claude automatically unless the config says `enabled: true` and the current user request asks to use this workflow.
- Codex remains responsible for task planning, permission decisions, diff review, testing, and final acceptance.
- Claude can be used as an independent adviser, executor, or reviewer. Treat its files, logs, and claims as untrusted until verified.
- Do not use `--dangerously-skip-permissions` or `bypassPermissions` unless the user explicitly approves that risk for a specific task.
- Prefer isolated git branches or worktrees for non-trivial changes.

## Files

- `scripts/Set-ClaudeExecutor.ps1`: enable, disable, or show status.
- `scripts/Invoke-ClaudeExecutor.ps1`: call local `claude -p` with a task file and capture logs.

Runtime config lives at:

`$HOME\.codex\claude-executor\config.json`

## Workflow

1. Confirm the user asked to use Claude delegation.
2. Create a concrete `TASK.md` with goal, allowed files, forbidden files, commands to run, success criteria, and required output files.
3. Optional independent planning pass:
   `scripts/Invoke-ClaudeExecutor.ps1 -Mode advise -TaskPath <TASK.md> -Workspace <repo>`
4. Execution pass:
   `scripts/Invoke-ClaudeExecutor.ps1 -Mode execute -TaskPath <TASK.md> -Workspace <repo>`
5. Optional independent review pass:
   `scripts/Invoke-ClaudeExecutor.ps1 -Mode review -TaskPath <TASK.md> -Workspace <repo>`
6. Codex reads Claude's output files and generated run logs.
7. Codex inspects `git diff`, runs focused tests, and decides:
   - accept the result,
   - ask Claude for another attempt with a narrower `TASK.md`,
   - fix directly in Codex,
   - disable the executor if it is causing churn.

## Modes

- `advise`: Claude thinks independently, reads the task and workspace, writes `CLAUDE_ADVICE.md`, and must not edit files.
- `execute`: Claude implements the task and writes `RESULT.md`.
- `review`: Claude inspects the task, current diff, logs, and result files, writes `CLAUDE_REVIEW.md`, and must not edit files.

The strongest default loop is:

`Codex plan -> Claude advise -> Codex revise task -> Claude execute -> Claude review -> Codex final verification`

## Enable And Disable

Enable:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" -Enabled $true
```

Disable:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" -Enabled $false
```

Status:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" -Status
```
