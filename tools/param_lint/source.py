"""Raw DM source text helpers for param_lint.

avulto (the SpacemanDMM parser bindings) only exposes the *preprocessed* AST,
so anything that lives in the unexpanded source text has to be found here:

* the marker macros, which expand to nothing,
* parameter default values, which avulto does not expose,
* `#define` bodies, used to see through macros when an argument list is hidden.

All scanning is done on a "masked" copy of a file in which comments and the
contents of string/resource literals are replaced by spaces. Newlines and
string quotes are kept, so offsets, line numbers and columns stay identical to
the original text. Embedded expressions inside strings (`"[foo()]"`) are kept,
because DM compiles them as code.
"""

import bisect
import os
import re

IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")

_CODE_TOKENS = re.compile(r'//|/\*|\{"|"|\'|@|\[|\]')
_STR_TOKENS = re.compile(r'\\.|"|\[', re.S)
_MSTR_TOKENS = re.compile(r'\\.|"\}|\[', re.S)
_RES_TOKENS = re.compile(r"\\.|'", re.S)
_BLOCK_TOKENS = re.compile(r"/\*|\*/")
_NOT_NEWLINE = re.compile(r"[^\n]")


def _blank(s):
	return _NOT_NEWLINE.sub(" ", s)


def mask_source(text):
	"""Return `text` with comments and literal string contents blanked out."""
	out = []
	n = len(text)
	i = 0
	# Stack of modes. "code" is the file itself, ["interp", depth] is an
	# embedded expression inside a string, "str"/"mstr" are "..." and {"..."}.
	stack = ["code"]
	while i < n:
		top = stack[-1]
		if top == "code" or isinstance(top, list):
			m = _CODE_TOKENS.search(text, i)
			if not m:
				out.append(text[i:])
				break
			out.append(text[i:m.start()])
			tok = m.group()
			j = m.end()
			if tok == "//":
				end = text.find("\n", j)
				if end == -1:
					end = n
				out.append(_blank(text[m.start():end]))
				i = end
			elif tok == "/*":
				depth = 1
				k = j
				while depth:
					bm = _BLOCK_TOKENS.search(text, k)
					if not bm:
						k = n
						break
					depth += 1 if bm.group() == "/*" else -1
					k = bm.end()
				out.append(_blank(text[m.start():k]))
				i = k
			elif tok == '"':
				out.append('"')
				stack.append("str")
				i = j
			elif tok == '{"':
				out.append('{"')
				stack.append("mstr")
				i = j
			elif tok == "'":
				k = j
				closed = False
				while True:
					rm = _RES_TOKENS.search(text, k)
					if not rm:
						k = n
						break
					k = rm.end()
					if rm.group() == "'":
						closed = True
						break
				if closed:
					out.append("'" + _blank(text[j:k - 1]) + "'")
				else:
					out.append("'" + _blank(text[j:k]))
				i = k
			elif tok == "@":
				# BYOND 515 raw strings: @"..", @{".."}, @(DELIM)..DELIM, @x..x
				if text.startswith('{"', j):
					end = text.find('"}', j + 2)
					end = n if end == -1 else end + 2
				elif text.startswith("(", j):
					close = text.find(")", j)
					if close == -1:
						end = n
					else:
						delim = text[j + 1:close]
						end = text.find(delim, close + 1) if delim else -1
						end = n if end == -1 else end + len(delim)
				elif j < n and not text[j].isspace():
					end = text.find(text[j], j + 1)
					end = n if end == -1 else end + 1
				else:
					end = j
				out.append(_blank(text[m.start():end]))
				i = end
			elif tok == "[":
				out.append("[")
				if isinstance(top, list):
					top[1] += 1
				i = j
			else:  # "]"
				out.append("]")
				if isinstance(top, list):
					if top[1] == 0:
						stack.pop()
					else:
						top[1] -= 1
				i = j
		else:
			pattern = _STR_TOKENS if top == "str" else _MSTR_TOKENS
			m = pattern.search(text, i)
			if not m:
				out.append(_blank(text[i:]))
				break
			out.append(_blank(text[i:m.start()]))
			tok = m.group()
			if tok.startswith("\\"):
				out.append(_blank(tok))
			elif tok == "[":
				out.append("[")
				stack.append(["interp", 0])
			else:
				out.append(tok)
				stack.pop()
			i = m.end()
	result = "".join(out)
	assert len(result) == len(text), "mask_source must preserve length"
	return result


def read_text(path):
	with open(path, "rb") as f:
		data = f.read()
	return data.decode("utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")


class SourceFile:
	"""A source file with its masked text and line index."""

	def __init__(self, path, text=None):
		self.path = path
		self.text = read_text(path) if text is None else text
		self._masked = None
		self.line_starts = [0]
		for m in re.finditer("\n", self.text):
			self.line_starts.append(m.end())
		self._directive_lines = None

	@property
	def masked(self):
		if self._masked is None:
			self._masked = mask_source(self.text)
		return self._masked

	def offset(self, line, column):
		"""Offset of a 1-based (line, column) position, or None."""
		if line < 1 or line > len(self.line_starts):
			return None
		off = self.line_starts[line - 1] + column - 1
		return off if 0 <= off <= len(self.text) else None

	def position(self, offset):
		"""1-based (line, column) of an offset."""
		idx = bisect.bisect_right(self.line_starts, offset) - 1
		return idx + 1, offset - self.line_starts[idx] + 1

	def line_text(self, line, masked=True):
		src = self.masked if masked else self.text
		start = self.line_starts[line - 1]
		end = self.line_starts[line] - 1 if line < len(self.line_starts) else len(src)
		return src[start:end]

	@property
	def directive_lines(self):
		"""Set of 1-based line numbers that belong to preprocessor directives
		(including backslash continuation lines)."""
		if self._directive_lines is None:
			lines = set()
			masked = self.masked.split("\n")
			raw = self.text.split("\n")
			continuing = False
			for idx, mline in enumerate(masked):
				if continuing or mline.lstrip().startswith("#"):
					lines.add(idx + 1)
					continuing = raw[idx].rstrip().endswith("\\")
				else:
					continuing = False
			self._directive_lines = lines
		return self._directive_lines


def balanced_end(masked, open_offset):
	"""Given the offset of an opening `(`, return the offset just past the
	matching `)` in masked text, or None if unbalanced."""
	depth = 0
	n = len(masked)
	i = open_offset
	while i < n:
		c = masked[i]
		if c in "([{":
			depth += 1
		elif c in ")]}":
			depth -= 1
			if depth == 0:
				return i + 1
		i += 1
	return None


# ---------------------------------------------------------------------------
# Includes and defines

_INCLUDE_RE = re.compile(r'^[ \t]*#[ \t]*include[ \t]+"([^"]+)"', re.M)
_DEFINE_RE = re.compile(
	r"^[ \t]*#[ \t]*define[ \t]+(?P<name>[A-Za-z_]\w*)(?P<params>\([^)\n]*\))?(?P<body>(?:\\\n|[^\n])*)",
	re.M,
)
_COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.S)


def collect_included_files(dme_path):
	"""Recursively follow `#include "..."` lines starting at the DME.

	Conditional compilation is ignored, so this is a superset of what the
	compiler sees. Only .dm/.dme files are returned (absolute, normalised)."""
	seen = []
	seen_set = set()
	todo = [os.path.abspath(dme_path)]
	while todo:
		path = todo.pop()
		key = os.path.normcase(path)
		if key in seen_set or not os.path.isfile(path):
			continue
		seen_set.add(key)
		seen.append(path)
		try:
			text = read_text(path)
		except OSError:
			continue
		base = os.path.dirname(path)
		for m in _INCLUDE_RE.finditer(text):
			inc = m.group(1).replace("\\", "/")
			if not inc.lower().endswith((".dm", ".dme")):
				continue
			todo.append(os.path.abspath(os.path.join(base, inc)))
	return seen


class Macro:
	__slots__ = ("name", "function_like", "bodies")

	def __init__(self, name, function_like):
		self.name = name
		self.function_like = function_like
		self.bodies = []


def collect_defines(files_text):
	"""Map macro name -> Macro from an iterable of raw file texts."""
	macros = {}
	for text in files_text:
		if "define" not in text:
			continue
		for m in _DEFINE_RE.finditer(text):
			name = m.group("name")
			body = _COMMENT_RE.sub(" ", m.group("body").replace("\\\n", " "))
			macro = macros.get(name)
			if macro is None:
				macro = macros[name] = Macro(name, m.group("params") is not None)
			elif m.group("params") is not None:
				macro.function_like = True
			macro.bodies.append(body)
	return macros


# ---------------------------------------------------------------------------
# Markers

MARKER_NAMES = ("SHOULD_CALL_ALL_PARAMS", "SHOULD_STATE_PARAM_NAMES", "SHOULD_KEEP_PARAM_ORDER", "PARAM_LINT_SKIP")
_MARKER_RE = re.compile(r"\b(SHOULD_CALL_ALL_PARAMS|SHOULD_STATE_PARAM_NAMES|SHOULD_KEEP_PARAM_ORDER|PARAM_LINT_SKIP)\b")


class MarkerHit:
	"""A marker macro invocation found in source text."""

	__slots__ = ("kind", "file", "line", "column", "arg", "end_line", "end_column", "error")

	def __init__(self, kind, file, line, column):
		self.kind = kind
		self.file = file
		self.line = line
		self.column = column
		self.arg = None
		self.end_line = None
		self.end_column = None
		self.error = None


def find_markers(source):
	"""Find marker invocations in a SourceFile, skipping comments, strings and
	preprocessor directives (including the `#define`s of the markers)."""
	hits = []
	if not any(name in source.text for name in MARKER_NAMES):
		return hits
	masked = source.masked
	directives = source.directive_lines
	for m in _MARKER_RE.finditer(masked):
		line, col = source.position(m.start())
		if line in directives:
			continue
		hit = MarkerHit(m.group(1), source.path, line, col)
		k = m.end()
		while k < len(masked) and masked[k] in " \t":
			k += 1
		if k >= len(masked) or masked[k] != "(":
			hit.error = f"`{hit.kind}` must be invoked with parentheses"
			hits.append(hit)
			continue
		end = balanced_end(masked, k)
		if end is None:
			hit.error = f"unbalanced parentheses after `{hit.kind}`"
			hits.append(hit)
			continue
		hit.arg = source.text[k + 1:end - 1].strip()
		hit.end_line, hit.end_column = source.position(end - 1)
		hits.append(hit)
	return hits


# ---------------------------------------------------------------------------
# Proc definitions

class ParamSegment:
	__slots__ = ("name", "has_default", "text")

	def __init__(self, name, has_default, text):
		self.name = name
		self.has_default = has_default
		self.text = text


class ProcDefText:
	"""What the raw text tells us about a proc definition."""

	__slots__ = ("path_text", "open_offset", "close_offset", "params", "error")

	def __init__(self):
		self.path_text = None  # e.g. "/datum/foo/verb/bar"
		self.open_offset = None
		self.close_offset = None  # offset just past the closing paren
		self.params = None  # list[ParamSegment] or None if unparseable
		self.error = None


def _top_level_eq(seg):
	"""Index of a top-level `=` (not part of ==, !=, <=, >=) or -1."""
	depth = 0
	for i, c in enumerate(seg):
		if c in "([{":
			depth += 1
		elif c in ")]}":
			depth -= 1
		elif c == "=" and depth == 0:
			prev = seg[i - 1] if i else ""
			nxt = seg[i + 1] if i + 1 < len(seg) else ""
			if prev in "=!<>" or nxt == "=":
				continue
			return i
	return -1


def _segment_name(seg):
	eq = _top_level_eq(seg)
	head = seg if eq == -1 else seg[:eq]
	# strip `as type` / `in list` suffixes
	head = re.split(r"\s+(?:as|in)\b", head, maxsplit=1)[0]
	head = head.strip()
	if head == "...":
		return "...", eq != -1
	idents = IDENT_RE.findall(head)
	if not idents:
		return None, eq != -1
	return idents[-1], eq != -1


def parse_proc_definition(source, line, column, name, macros):
	"""Inspect the text of a proc definition whose parameter list opens at the
	1-based (line, column) reported by avulto."""
	info = ProcDefText()
	masked = source.masked
	off = source.offset(line, column)
	if off is None or off >= len(masked) or masked[off] != "(":
		# fall back to finding `name(` on that line
		lt = source.line_text(line) if 1 <= line <= len(source.line_starts) else ""
		m = re.search(r"\b" + re.escape(name) + r"\s*\(", lt)
		if not m:
			info.error = "could not locate the parameter list in the source text (definition generated by a macro?)"
			return info
		off = source.line_starts[line - 1] + m.end() - 1
	info.open_offset = off
	line_start = source.line_starts[source.position(off)[0] - 1]
	before = masked[line_start:off].rstrip()
	if not re.search(r"(^|/)" + re.escape(name) + r"$", before):
		info.error = f"text before the parameter list does not end with the proc name `{name}`"
		return info
	info.path_text = before.strip()

	segments = []
	current = []
	stack = []  # "T" = transparent macro paren, "O" = opaque bracket
	i = off + 1
	n = len(masked)
	closed = False

	def flush():
		seg = "".join(current).strip()
		current.clear()
		if seg:
			segments.append(seg)

	while i < n:
		c = masked[i]
		if c == "(":
			# Identifier right before this paren?
			j = len(current)
			while j > 0 and current[j - 1] in " \t":
				j -= 1
			k = j
			while k > 0 and (current[k - 1].isalnum() or current[k - 1] == "_"):
				k -= 1
			ident = "".join(current[k:j])
			macro = macros.get(ident) if ident else None
			if macro is not None and macro.function_like and not stack_has_opaque(stack):
				del current[k:]
				flush()
				stack.append("T")
			else:
				stack.append("O")
				current.append(c)
		elif c in "[{":
			stack.append("O")
			current.append(c)
		elif c in ")]}":
			if not stack:
				if c != ")":
					info.error = "unbalanced brackets in parameter list"
					return info
				flush()
				closed = True
				info.close_offset = i + 1
				break
			kind = stack.pop()
			if kind == "T":
				flush()
			else:
				current.append(c)
		elif c == "," and not stack_has_opaque(stack):
			flush()
		else:
			current.append(c)
		i += 1
	if not closed:
		info.error = "unterminated parameter list"
		return info

	params = []
	for seg in segments:
		if IDENT_RE.fullmatch(seg) and seg in macros and not macros[seg].function_like:
			if all(not b.strip() for b in macros[seg].bodies):
				continue  # object-like macro expanding to nothing
			info.error = f"parameter list uses object-like macro `{seg}`; cannot map it to parameters"
			return info
		pname, has_default = _segment_name(seg)
		if pname is None:
			info.error = f"could not read a parameter name from `{seg}`"
			return info
		params.append(ParamSegment(pname, has_default, seg))
	info.params = params
	return info


def stack_has_opaque(stack):
	return "O" in stack
