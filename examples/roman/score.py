"""Objective scorer. Prints `score=<fraction>` to stdout, exits 0 iff ALL tests pass.

The kernel runs THIS — never the worker — so the score cannot be fabricated.
"""
import io
import sys
import unittest

here = sys.path[0] or "."
sys.path.insert(0, here)  # make solution.py importable

loader = unittest.TestLoader()
suite = loader.discover(start_dir="tests", pattern="test_*.py", top_level_dir=here)
result = unittest.TextTestRunner(stream=io.StringIO(), verbosity=0).run(suite)

total = result.testsRun
failed = len(result.failures) + len(result.errors)
passed = total - failed
score = (passed / total) if total else 0.0

print("score=%.4f" % score)
print("passed=%d total=%d failed=%d" % (passed, total, failed), file=sys.stderr)
sys.exit(0 if (total > 0 and failed == 0) else 1)
