import unittest

from stats_utils import summarize


class SummarizeTests(unittest.TestCase):
    def test_ignores_none_values(self):
        self.assertEqual(
            summarize([1, None, 3, 5]),
            {"count": 3, "mean": 3.0, "min": 1, "max": 5},
        )

    def test_empty_or_only_none_values_raise_clear_error(self):
        with self.assertRaisesRegex(ValueError, "at least one numeric value"):
            summarize([])
        with self.assertRaisesRegex(ValueError, "at least one numeric value"):
            summarize([None, None])


if __name__ == "__main__":
    unittest.main()
