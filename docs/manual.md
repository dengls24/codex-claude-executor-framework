# User Manual

## 1. Purpose

This manual explains how to use the Codex-Claude Executor Framework in a local coding workflow. The framework is designed for users who have multiple AI coding tools and want to reduce manual context transfer, control cost, balance subscription usage, and improve reliability.

## 2. Concepts

### 2.1 Principal Agent

In the reference implementation, Codex is the principal agent. It should:

- understand the user goal;
- write `TASK.md`;
- decide whether delegation is appropriate;
- inspect Claude output;
- run final validation;
- accept, reject, or retry.

### 2.2 Executor Agent

In the reference implementation, Claude Code with DeepSeek API is the executor. It can:

- advise before implementation;
- implement bounded changes;
- review the resulting diff.

Claude should not be trusted as the final authority.

For other tool combinations, replace these names with the tools available to you. The workflow still applies if two tools are comparable monthly subscriptions and the main problem is quota balancing rather than price difference.

### 2.3 Portable Task State

Instead of transferring long chat context, the framework uses files:

```text
TASK.md
CLAUDE_ADVICE.md
RESULT.md
CLAUDE_REVIEW.md
claude-run-YYYYMMDD-HHMMSS/
```

These files let another model or human reconstruct the task state.

## 3. Installation

Clone the repository:

```powershell
git clone https://github.com/dengls24/codex-claude-executor-framework.git
cd codex-claude-executor-framework
```

Install the skill:

```powershell
& ".\scripts\install-skill.ps1"
```

Check status:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" -Status
```

Expected default:

```json
{
  "enabled": false,
  "permissionMode": "auto"
}
```

## 4. Enable and Disable

Enable for a bounded task:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" `
  -Enabled $true `
  -MaxBudgetUsd 0.20 `
  -PermissionMode auto
```

Disable after the task:

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Set-ClaudeExecutor.ps1" -Enabled $false
```

## 5. Write a Good TASK.md

A high-quality task file should be narrow and testable.

````markdown
# Task

## Goal

Describe the expected final behavior.

## Allowed files

- `src/module.py`
- `RESULT.md`
- `CLAUDE_ADVICE.md`
- `CLAUDE_REVIEW.md`

## Forbidden files

- Do not edit lockfiles.
- Do not edit tests unless explicitly requested.
- Do not install dependencies.

## Required behavior

- Requirement 1
- Requirement 2

## Validation command

```powershell
python -m unittest
```

## Required output

Write `RESULT.md` with:

1. Summary
2. Files changed
3. Commands run
4. Test results
5. Remaining risks
````

## 6. Run the Three-Pass Workflow

### 6.1 Advice Pass

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Invoke-ClaudeExecutor.ps1" `
  -Mode advise `
  -TaskPath ".\TASK.md" `
  -Workspace "."
```

Read `CLAUDE_ADVICE.md`. If the task is ambiguous, Codex should revise `TASK.md` before execution.

### 6.2 Execution Pass

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Invoke-ClaudeExecutor.ps1" `
  -Mode execute `
  -TaskPath ".\TASK.md" `
  -Workspace "."
```

Read:

- `RESULT.md`;
- changed source files;
- `claude-run-*/run-summary.json`;
- stderr logs if present.

### 6.3 Review Pass

```powershell
& "$HOME\.codex\skills\claude-executor\scripts\Invoke-ClaudeExecutor.ps1" `
  -Mode review `
  -TaskPath ".\TASK.md" `
  -Workspace "."
```

Read `CLAUDE_REVIEW.md` and classify findings:

- blocking;
- non-blocking but should fix;
- informational.

## 7. Codex Final Verification

Codex should run:

```powershell
git diff
python -m unittest
```

Acceptance checklist:

- Diff only touches allowed files.
- Tests pass locally.
- No secrets are present.
- Claude review has no blocking finding.
- The implementation matches the task, not just the tests.

## 8. Usage-Aware Routing

Use this routing policy:

| Task | Preferred agent |
|---|---|
| Problem framing and task decomposition | Codex |
| Repetitive implementation and debugging | Claude Code + DeepSeek |
| Independent risk review | Claude Code + DeepSeek |
| Final verification | Codex |
| Paper or report polishing | GPT Pro or a writing-focused model |

When Codex usage is constrained, convert the current state into `TASK.md` and delegate bounded execution. When Claude/DeepSeek budget is constrained or the task is high-risk, keep the work in Codex.

For comparable subscriptions, use the same principle:

- convert the current state into durable artifacts before quota pressure becomes severe;
- route the next step to the tool with healthier remaining usage and better role fit;
- keep final verification separate from the agent that performed the edit.

## 9. Recovery and Retry

If Claude fails:

1. Read `claude-error.txt`.
2. Read `run-summary.json`.
3. Narrow `TASK.md`.
4. Retry only the failed mode.
5. If repeated failures occur, disable the executor and let Codex implement directly.

If Claude changes forbidden files:

1. Stop the workflow.
2. Inspect the diff.
3. Revert only the unauthorized changes after confirming they are not user changes.
4. Make `TASK.md` more explicit.

## 10. Recommended Operating Pattern

For small tasks:

```text
Codex TASK.md -> Claude execute -> Codex verify
```

For medium tasks:

```text
Codex TASK.md -> Claude advise -> Claude execute -> Codex verify
```

For high-risk tasks:

```text
Codex TASK.md -> Claude advise -> Codex revise -> Claude execute -> Claude review -> Codex verify
```
