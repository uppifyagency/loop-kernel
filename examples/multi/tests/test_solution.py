import unittest

from solution import roman_to_int, is_palindrome, fib


class TestRoman(unittest.TestCase):
    def test_iv(self):
        self.assertEqual(roman_to_int("IV"), 4)

    def test_mcmxciv(self):
        self.assertEqual(roman_to_int("MCMXCIV"), 1994)


class TestPalindrome(unittest.TestCase):
    def test_true(self):
        self.assertTrue(is_palindrome("racecar"))

    def test_false(self):
        self.assertFalse(is_palindrome("hello"))


class TestFib(unittest.TestCase):
    def test_one(self):
        self.assertEqual(fib(1), 1)

    def test_ten(self):
        self.assertEqual(fib(10), 55)


if __name__ == "__main__":
    unittest.main()
