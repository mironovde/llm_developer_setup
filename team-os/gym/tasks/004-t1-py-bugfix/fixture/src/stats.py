"""Small numeric summary helpers used by the reporting layer."""


def mean(values):
    """Arithmetic mean of a non-empty sequence."""
    if not values:
        raise ValueError("mean() requires at least one value")
    return sum(values) / len(values)


def median(values):
    """Median of a non-empty sequence.

    For an odd number of values this is the middle element; for an even
    number it is the average of the two middle elements.
    """
    if not values:
        raise ValueError("median() requires at least one value")
    ordered = sorted(values)
    mid = len(ordered) // 2
    return ordered[mid]


def spread(values):
    """Difference between the largest and smallest value."""
    if not values:
        raise ValueError("spread() requires at least one value")
    return max(values) - min(values)
