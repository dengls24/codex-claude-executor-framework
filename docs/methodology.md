# Methodology

## Principle

This framework separates **thinking authority** from **execution labor**.

Codex stays responsible for the objective, task decomposition, permission decisions, and final acceptance. Claude Code with DeepSeek API is used as a lower-cost worker that can advise, implement, and review, but it does not decide whether the work is correct.

## Role Definition

| Role | Agent | Responsibility |
|---|---|---|
| Principal agent | Codex | Plan, constrain, verify, accept or reject |
| Adviser | Claude Code | Independent risk analysis before implementation |
| Executor | Claude Code | Make scoped edits and run requested validation |
| Reviewer | Claude Code | Second opinion on diff, logs, and result |
| Human | User | Sets high-level goals and approves sensitive operations |

## Why It Reduces Cost

The expensive part of many coding tasks is not the final patch. It is the loop:

```text
try -> run -> fail -> inspect -> patch -> run again
```

If Codex performs every loop itself, high-value context and model budget are spent on repetitive execution. In this framework:

- Codex writes a precise `TASK.md`.
- Claude performs bounded trial-and-error.
- Claude writes structured artifacts.
- Codex spends attention on reviewing evidence and making the final decision.

## Why It Can Improve Quality

The workflow adds independent disagreement points:

1. `advise` checks the task before implementation.
2. `execute` performs the actual work.
3. `review` checks the implementation from a separate pass.
4. Codex verifies tests and diff independently.

This reduces the chance that one agent's mistaken assumption goes straight into the final result.

## Acceptance Rule

A task is accepted only when all of these are true:

- The diff matches the stated task.
- Forbidden files were not changed.
- Required tests pass when run by Codex or a human, not only by Claude.
- `RESULT.md` documents commands and risks.
- `CLAUDE_REVIEW.md` has no unresolved blocking finding.

## Recommended Task Template

````markdown
# Task

## Goal

What should be true after the task is complete?

## Allowed files

- file or directory list

## Forbidden files

- files, directories, configs, lockfiles, or generated outputs that must not change

## Required behavior

- concrete behavioral requirements

## Validation command

```powershell
command to run
```

## Required output

Write `RESULT.md` with:

1. Summary
2. Files changed
3. Commands run
4. Test results
5. Remaining risks
````
