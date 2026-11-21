"""Tests for tools/param_lint against the fixture environment in tests/fixture/.

Run from the repository root:
	tools/bootstrap/python -m param_lint.tests
"""

import collections
import contextlib
import io
import os
import re
import sys
import unittest

from param_lint.analysis import RULES
from param_lint.check import Options, main, run
from param_lint.source import mask_source

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(HERE, "fixture")
FIXTURE_DME = os.path.join(FIXTURE, "fixture.dme")
CLEAN_DME = os.path.join(HERE, "clean", "clean.dme")
EXTRA_DEFINE = ("PARAM_LINT_FIXTURE_EXTRA", "")

_EXPECT_RE = re.compile(r"//.*?\bEXPECT(?:\((\w+)\))?:\s*(.*)$")
_OK_RE = re.compile(r"\bOK\((\w+)\)")


def _fixture_files():
	return sorted(f for f in os.listdir(FIXTURE) if f.endswith(".dm"))


def expected(extra=False, check_defaults=True):
	"""Counter of (file, line, rule) built from `// EXPECT:` annotations."""
	out = collections.Counter()
	for name in _fixture_files():
		with open(os.path.join(FIXTURE, name), encoding="utf-8") as f:
			for lineno, line in enumerate(f, 1):
				m = _EXPECT_RE.search(line)
				if not m:
					continue
				if m.group(1) == "extra" and not extra:
					continue
				for item in m.group(2).split(","):
					item = item.strip()
					if not item:
						continue
					rule, _, count = item.partition("*")
					if rule == "default_value" and not check_defaults:
						continue
					out[(name, lineno, rule)] += int(count or 1)
	return out


def ok_rules():
	rules = set()
	for name in _fixture_files():
		with open(os.path.join(FIXTURE, name), encoding="utf-8") as f:
			rules.update(_OK_RE.findall(f.read()))
	return rules


def actual(result, base=FIXTURE):
	return collections.Counter(
		(os.path.relpath(d.path, base).replace("\\", "/"), d.line, d.rule) for d in result.diagnostics
	)


def _diff(want, got):
	lines = []
	for key in sorted(set(want) | set(got)):
		if want[key] != got[key]:
			lines.append(f"  {key[0]}:{key[1]} {key[2]}: expected {want[key]}, got {got[key]}")
	return "\n".join(lines)


class FixtureTests(unittest.TestCase):
	@classmethod
	def setUpClass(cls):
		cls.base = run(FIXTURE_DME)
		cls.extra = run(FIXTURE_DME, extra_passes=[[EXTRA_DEFINE]])
		cls.no_defaults = run(FIXTURE_DME, options=Options(check_defaults=False))

	def assertDiagnostics(self, result, want):
		got = actual(result)
		self.assertEqual(want, got, "diagnostics differ:\n" + _diff(want, got) + "\nfull output:\n" + "\n".join(
			f"  {os.path.relpath(d.path, FIXTURE)}:{d.line}: [{d.rule}] {d.message}" for d in result.diagnostics))

	def test_base_pass(self):
		self.assertDiagnostics(self.base, expected())

	def test_extra_define_pass(self):
		self.assertDiagnostics(self.extra, expected(extra=True))
		self.assertEqual(self.extra.passes, 2)

	def test_default_value_check_can_be_disabled(self):
		self.assertDiagnostics(self.no_defaults, expected(check_defaults=False))

	def test_every_rule_has_a_failing_and_a_passing_case(self):
		failing = {rule for (_, _, rule) in expected(extra=True)}
		self.assertEqual(set(RULES), failing, "rules without an EXPECT case: " + ", ".join(sorted(set(RULES) - failing)))
		passing = ok_rules()
		self.assertEqual(set(), set(RULES) - passing, "rules without an OK(rule) case")

	def test_every_proc_was_walked_or_reported(self):
		unparsable = sum(1 for d in self.base.diagnostics if d.rule == "unparsable_proc")
		self.assertEqual(self.base.walked + unparsable, self.base.procs)

	def test_messages_name_the_proc_and_parameters(self):
		msgs = [d.message for d in self.base.diagnostics if d.rule == "missing_params" and "/datum/widget/big/New()" in d.message]
		self.assertTrue(msgs)
		self.assertIn("`d`", msgs[0])


class CliTests(unittest.TestCase):
	def _main(self, argv, github=False):
		old = os.environ.get("GITHUB_ACTIONS")
		if github:
			os.environ["GITHUB_ACTIONS"] = "true"
		else:
			os.environ.pop("GITHUB_ACTIONS", None)
		buf = io.StringIO()
		try:
			with contextlib.redirect_stdout(buf):
				code = main(argv)
		finally:
			if old is None:
				os.environ.pop("GITHUB_ACTIONS", None)
			else:
				os.environ["GITHUB_ACTIONS"] = old
		return code, buf.getvalue().splitlines()

	def test_failing_environment_exits_1(self):
		code, lines = self._main([FIXTURE_DME])
		self.assertEqual(code, 1)
		diag_re = re.compile(r"^(.+):(\d+): error\[([a-z_]+)\]: (.+)$")
		diag_lines = [l for l in lines if diag_re.match(l)]
		self.assertEqual(len(diag_lines), sum(expected().values()))
		self.assertTrue(lines[-1].startswith("param_lint: "), lines[-1])
		self.assertRegex(lines[-1], r"\d+\.\ds$")
		self.assertFalse(any(l.startswith("::error") for l in lines))

	def test_github_annotations(self):
		code, lines = self._main([FIXTURE_DME], github=True)
		self.assertEqual(code, 1)
		annotations = [l for l in lines if l.startswith("::error file=")]
		self.assertEqual(len(annotations), sum(expected().values()))
		self.assertRegex(annotations[0], r"^::error file=[^,]+,line=\d+,title=param_lint [a-z_]+::.+")

	def test_clean_environment_exits_0(self):
		code, lines = self._main([CLEAN_DME])
		self.assertEqual(code, 0, "\n".join(lines))
		self.assertRegex(lines[-1], r"^param_lint: 0 error\(s\);")


class MaskTests(unittest.TestCase):
	def test_mask_keeps_length_and_code(self):
		src = 'a = "x [b("y")] z" // c\n/* d /* e */ f */ g = {"h\n[i]"} + \'icon.dmi\' + @"raw[" + j\n'
		masked = mask_source(src)
		self.assertEqual(len(src), len(masked))
		self.assertEqual(src.count("\n"), masked.count("\n"))
		for kept in ("a =", "[b(", "]", "g =", "[i]", "+ j"):
			self.assertIn(kept, masked)
		for gone in ("x ", " z", "// c", "d ", "e ", " f", "h", "icon", "raw"):
			self.assertNotIn(gone, masked)


def load_tests(loader, tests, pattern):
	suite = unittest.TestSuite()
	for case in (FixtureTests, CliTests, MaskTests):
		suite.addTests(loader.loadTestsFromTestCase(case))
	return suite


if __name__ == "__main__":
	sys.setrecursionlimit(max(sys.getrecursionlimit(), 20000))
	unittest.main()
