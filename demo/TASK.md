# Task

Fix `stats_utils.summarize`.

## Goal

Make `summarize(values)` return a dictionary with `count`, `mean`, `min`, and `max` for numeric values while ignoring `None` entries.

## Allowed files

- `stats_utils.py`
- `RESULT.md`
- `CLAUDE_ADVICE.md`
- `CLAUDE_REVIEW.md`

## Forbidden files

- Do not edit `test_stats_utils.py`.
- Do not create or modify environment, package, or user configuration files.
- Do not install dependencies.

## Required behavior

- `None` values are ignored.
- `count` is the number of non-None numeric values.
- If there are no non-None values, raise `ValueError` with a message containing `at least one numeric value`.

## Validation command

Run:

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
