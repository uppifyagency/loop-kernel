import unittest

from solution import roman_to_int


class TestRomanToInt(unittest.TestCase):
    def test_I(self):
        self.assertEqual(roman_to_int("I"), 1)

    def test_III(self):
        self.assertEqual(roman_to_int("III"), 3)

    def test_IV(self):
        self.assertEqual(roman_to_int("IV"), 4)

    def test_IX(self):
        self.assertEqual(roman_to_int("IX"), 9)

    def test_LVIII(self):
        self.assertEqual(roman_to_int("LVIII"), 58)

    def test_MCMXCIV(self):
        self.assertEqual(roman_to_int("MCMXCIV"), 1994)


if __name__ == "__main__":
    unittest.main()
