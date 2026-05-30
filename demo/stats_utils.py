def summarize(values):
    """Return count, mean, min, and max for numeric values, ignoring None."""
    numeric = [v for v in values if v is not None]
    if not numeric:
        raise ValueError("at least one numeric value is required")
    count = len(numeric)
    return {
        "count": count,
        "mean": sum(numeric) / count,
        "min": min(numeric),
        "max": max(numeric),
    }
