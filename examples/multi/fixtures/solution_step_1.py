def roman_to_int(s: str) -> int:
    values = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    total = 0
    prev = 0
    for ch in reversed(s):
        v = values[ch]
        total += -v if v < prev else v
        prev = v
    return total


def is_palindrome(s: str) -> bool:
    raise NotImplementedError("TODO")


def fib(n: int) -> int:
    raise NotImplementedError("TODO")
