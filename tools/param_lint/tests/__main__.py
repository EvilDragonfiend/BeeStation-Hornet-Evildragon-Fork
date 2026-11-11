import sys
import unittest

sys.setrecursionlimit(max(sys.getrecursionlimit(), 20000))
result = unittest.main(module="param_lint.tests.test_param_lint", exit=False, verbosity=2).result
sys.exit(0 if result.wasSuccessful() else 1)
