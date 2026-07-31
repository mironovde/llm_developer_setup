import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from stats import median


class TestMedian(unittest.TestCase):
    def test_odd_length_returns_middle_element(self):
        self.assertEqual(median([7, 1, 3]), 3)

    def test_even_length_returns_average_of_two_middles(self):
        self.assertEqual(median([1, 2, 3, 4]), 2.5)

    def test_single_element(self):
        self.assertEqual(median([42]), 42)


if __name__ == "__main__":
    unittest.main()
