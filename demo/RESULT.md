# Result

## Summary

Fixed `stats_utils.summarize` to filter out `None` values before computing statistics and to raise `ValueError` when no numeric values remain.

## Files changed

- `stats_utils.py`: rewrote the function body to filter `None` entries, raise `ValueError("at least one numeric value is required")` on empty input, and compute `count`, `mean`, `min`, and `max` over the filtered list.

## Commands run

```powershell
python -m unittest
```

## Test results

```text
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

Both tests passed:

- `test_ignores_none_values`
- `test_empty_or_only_none_values_raise_clear_error`

## Remaining risks

None identified for the requested scope. The implementation does not add type validation for non-`None` non-numeric values because that behavior was outside `TASK.md`.

