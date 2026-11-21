"""AST analysis for param_lint (one preprocessor pass over one DME)."""

import bisect
import os
import re

from .source import IDENT_RE, balanced_end, parse_proc_definition

FLAG_ALL = "all"
FLAG_NAMES = "names"
FLAG_ORDER = "order"
MARKER_FLAG = {
	"SHOULD_CALL_ALL_PARAMS": FLAG_ALL,
	"SHOULD_STATE_PARAM_NAMES": FLAG_NAMES,
	"SHOULD_KEEP_PARAM_ORDER": FLAG_ORDER,
}
FLAG_ORDERING = (FLAG_ALL, FLAG_NAMES, FLAG_ORDER)
NO_FLAGS = (False, False, False)

# Every rule id the tool can emit, with a one-line description (used by --list-rules and the README).
RULES = {
	"missing_params": "SHOULD_CALL_ALL_PARAMS: a call does not bind every declared parameter",
	"too_many_args": "SHOULD_CALL_ALL_PARAMS: a call passes more arguments than the proc declares",
	"positional_arg": "SHOULD_STATE_PARAM_NAMES: a call passes an argument positionally instead of `name = value`",
	"param_order": "SHOULD_KEEP_PARAM_ORDER: a call passes arguments in a different order than the proc declares its parameters",
	"positional_after_keyword": "a positional argument follows a keyword argument in a call to a marked proc",
	"duplicate_binding": "a parameter of a marked proc is bound twice in one call",
	"unknown_keyword": "a keyword argument names no parameter of the marked proc",
	"arglist": "arglist() is used in a call to a marked proc (the arguments cannot be counted)",
	"unverifiable_call": "a call that may reach a marked proc cannot be verified statically",
	"proc_reference": "a marked proc is referenced indirectly (PROC_REF, CALLBACK, call()(), ...)",
	"dynamic_call": "a marked proc is called through call(thing, \"name\")()",
	"override_params": "an override of a marked proc does not start with the parent's parameters in order",
	"variadic": "a marked proc is variadic (`...` parameter or use of `args`)",
	"marked_verb": "a marked proc is a verb",
	"default_value": "SHOULD_CALL_ALL_PARAMS: a parameter of a marked proc declares a default value",
	"unverifiable_definition": "the source text of a marked proc's definition could not be analysed",
	"unparsable_proc": "avulto could not parse or walk a proc body, so calls inside it cannot be checked",
	"bad_marker": "a marker has an invalid argument or is not inside a proc body",
	"unused_skip": "PARAM_LINT_SKIP() does not wrap any call that would have produced an error",
}

_MISSING = object()

# Statement visitor names avulto 0.1.x calls on a walker. When a walker defines
# one of these, avulto does not descend into that statement, so the collector
# below receives exactly the top-level statements of a proc body.
_STMT_VISITS = (
	"Break", "Continue", "Crash", "Del", "DoWhile", "ForInfinite", "ForKeyValue",
	"ForList", "ForLoop", "ForRange", "Goto", "If", "Label", "Return", "Setting",
	"Switch", "Throw", "TryCatch", "Var", "While",
)


class _Collector:
	def __init__(self):
		self.items = []

	def visit_Expr(self, node, loc):
		self.items.append(node)


def _make_visit():
	def visit(self, node, loc):
		self.items.append(node)
	return visit


for _name in _STMT_VISITS:
	setattr(_Collector, "visit_" + _name, _make_visit())


class UnsupportedNode(Exception):
	pass


class Diagnostic:
	__slots__ = ("path", "line", "rule", "message")

	def __init__(self, path, line, rule, message):
		self.path = path
		self.line = line
		self.rule = rule
		self.message = message

	def key(self):
		return (os.path.normcase(self.path), self.line, self.rule, self.message)


class ProcInfo:
	__slots__ = ("type", "name", "index", "decl", "file", "fkey", "line", "column", "params", "explicit", "_text")

	def display(self):
		if self.type == "/":
			return f"/proc/{self.name}()"
		return f"{self.type}/{self.name}()"


def _cls(node):
	return type(node).__name__


def _op_name(op):
	return str(op).rsplit(".", 1)[-1]


def _const_string(expr):
	if expr is not None and _cls(expr) == "Expression_Constant" and _cls(expr.constant) == "Constant_String":
		return expr.constant.val
	return None


def _is_null_const(expr):
	return expr is not None and _cls(expr) == "Expression_Constant" and _cls(expr.constant) == "Constant_Null"


def _is_arglist(expr):
	return (
		expr is not None
		and _cls(expr) == "Expression_Call"
		and expr.name.name == "arglist"
		and _is_null_const(expr.expr)
	)


def _keyword(arg):
	"""Return (is_keyword, name). name is None for a keyword with an unusable lhs."""
	if _cls(arg) != "Expression_AssignOp" or _op_name(arg.op) != "ASSIGN":
		return False, None
	lhs = arg.lhs
	if _cls(lhs) == "Expression_Identifier":
		return True, lhs.name
	s = _const_string(lhs)
	if s is not None:
		return True, s
	return True, None


def _fmt_list(items, limit=8):
	items = list(items)
	text = ", ".join(f"`{i}`" for i in items[:limit])
	if len(items) > limit:
		text += f" (+{len(items) - limit} more)"
	return text


class Analyzer:
	def __init__(self, dme, wrapper_dir, sources, macros, options):
		self.dme = dme
		self.wrapper_dir = wrapper_dir
		self.sources = sources
		self.macros = macros
		self.options = options
		self.diags = []
		self.parent = {}
		self.abs = {}
		self.abs_to_rel = {}
		self.tdecl = {}
		self.procs = {}  # (type, name) -> [ProcInfo]
		self.all_procs = []
		self.procs_by_file = {}
		self._resolve_cache = {}
		self._eff_cache = {}
		self._var_cache = {}
		self._marked_defs_cache = {}
		self.marked_names = set()
		self.types_defining = {}
		self.skips_by_file = {}
		self.consumed_skips = set()
		self.used_skips = None
		self.walked = 0
		self.checked_calls = 0
		self._build()

	# ------------------------------------------------------------------ setup
	def _file_path(self, loc):
		fp = str(loc.file_path)
		if not os.path.isabs(fp):
			fp = os.path.join(self.wrapper_dir, fp)
		return os.path.abspath(fp)

	def _build(self):
		for p in self.dme.typesof("/"):
			rel = str(p)
			td = self.dme.types[p]
			self.tdecl[rel] = td
			self.parent[rel] = None if rel == "/" else str(p.parent)
			self.abs[rel] = p.abs
			self.abs_to_rel[p.abs] = rel
			names = td.proc_names(declared=True, modified=True)
			for name in names:
				decls = td.proc_decls(name)
				if not decls:
					continue
				lst = []
				for idx, pd in enumerate(decls):
					pi = ProcInfo()
					pi.type = rel
					pi.name = name
					pi.index = idx
					pi.decl = pd
					loc = pd.source_loc
					pi.file = self._file_path(loc)
					pi.fkey = os.path.normcase(pi.file)
					pi.line = loc.line
					pi.column = loc.column
					pi.params = [a.arg_name for a in pd.args]
					pi.explicit = {}
					pi._text = None
					lst.append(pi)
					self.all_procs.append(pi)
					self.procs_by_file.setdefault(pi.fkey, []).append((pi.line, pi))
				self.procs[(rel, name)] = lst
		for lst in self.procs_by_file.values():
			lst.sort(key=lambda x: x[0])
		self._file_lines = {k: [x[0] for x in v] for k, v in self.procs_by_file.items()}

	def add(self, path, line, rule, message):
		self.diags.append(Diagnostic(path, line, rule, message))

	# ---------------------------------------------------------------- markers
	def def_text(self, pi):
		if pi._text is None:
			src = self.sources.get(pi.file)
			pi._text = parse_proc_definition(src, pi.line, pi.column, pi.name, self.macros)
		return pi._text

	def _marker_in_body(self, pi, hit):
		src = self.sources.get(pi.file)
		info = self.def_text(pi)
		start = src.position(info.close_offset - 1)[0] if info.close_offset else pi.line
		if hit.line < start:
			return False
		directives = src.directive_lines
		for ln in range(start + 1, hit.line):
			if ln in directives:
				continue
			text = src.line_text(ln)
			if text.strip() and not text[0].isspace():
				return False
		return True

	def map_markers(self, hits, mapped):
		"""Attach SHOULD_* markers (already validated) to procs."""
		for hit in hits:
			fkey = os.path.normcase(hit.file)
			lines = self._file_lines.get(fkey)
			if not lines:
				continue
			idx = bisect.bisect_right(lines, hit.line) - 1
			if idx < 0:
				continue
			pi = self.procs_by_file[fkey][idx][1]
			if not self._marker_in_body(pi, hit):
				continue
			mapped.add(id(hit))
			flag = MARKER_FLAG[hit.kind]
			value = hit.arg.strip() in ("TRUE", "1")
			prev = pi.explicit.get(flag)
			if prev is not None and prev != value:
				self.add(hit.file, hit.line, "bad_marker", f"conflicting `{hit.kind}` markers in {pi.display()}")
			pi.explicit[flag] = value
		for pi in self.all_procs:
			if any(pi.explicit.values()):
				self.marked_names.add(pi.name)
		for (t, name), lst in self.procs.items():
			if name in self.marked_names:
				self.types_defining.setdefault(name, []).append(t)

	def setup_skips(self, hits, used):
		self.used_skips = used
		for hit in hits:
			self.skips_by_file.setdefault(os.path.normcase(hit.file), []).append(hit)

	def try_consume_skip(self, fkey, line, col):
		for hit in self.skips_by_file.get(fkey, ()):
			if id(hit) in self.consumed_skips:
				continue
			if (hit.line, hit.column) <= (line, col) <= (hit.end_line, hit.end_column):
				self.consumed_skips.add(id(hit))
				self.used_skips.add(id(hit))
				return True
		return False

	# ----------------------------------------------------------------- typing
	def norm_type(self, s):
		if not s or s == "/" or s == "None":
			return None
		if s == "/list" or s.startswith("/list/"):
			return "/list"
		if s in self.parent:
			return s
		return self.abs_to_rel.get(s)

	def var_type(self, t, name):
		"""Declared type of var `name` on type `t`: _MISSING, None (untyped) or a type."""
		key = (t, name)
		res = self._var_cache.get(key, _MISSING)
		if res is not _MISSING or key in self._var_cache:
			return res
		td = self.tdecl.get(t)
		if td is None:
			res = _MISSING
		else:
			try:
				vd = td.var_decl(name, True)
			except Exception:
				res = _MISSING
			else:
				dt = vd.declared_type
				res = self.norm_type(str(dt)) if dt is not None else None
		self._var_cache[key] = res
		return res

	def is_strict_descendant(self, t, ancestor):
		if ancestor == "/" or t == ancestor:
			return False
		a = self.abs.get(ancestor)
		b = self.abs.get(t)
		return a is not None and b is not None and b.startswith(a + "/")

	def resolve(self, t, name):
		key = (t, name)
		if key in self._resolve_cache:
			return self._resolve_cache[key]
		res = None
		cur = t
		while cur is not None:
			lst = self.procs.get((cur, name))
			if lst:
				res = lst[-1]
				break
			cur = self.parent.get(cur)
		self._resolve_cache[key] = res
		return res

	def parent_def(self, pi):
		lst = self.procs[(pi.type, pi.name)]
		if pi.index > 0:
			return lst[pi.index - 1]
		p = self.parent.get(pi.type)
		return self.resolve(p, pi.name) if p is not None else None

	def eff_def(self, pi):
		"""Effective (all, names, order) flags of a definition, honouring inheritance and opt-outs."""
		if pi is None:
			return NO_FLAGS
		key = id(pi)
		res = self._eff_cache.get(key)
		if res is not None:
			return res
		lst = self.procs[(pi.type, pi.name)]
		out = []
		parent_flags = None
		for flag in FLAG_ORDERING:
			val = None
			for d in reversed(lst[:pi.index + 1]):
				v = d.explicit.get(flag)
				if v is not None:
					val = v
					break
			if val is None:
				if parent_flags is None:
					p = self.parent.get(pi.type)
					parent_flags = self.eff_def(self.resolve(p, pi.name)) if p is not None else NO_FLAGS
				val = parent_flags[FLAG_ORDERING.index(flag)]
			out.append(val)
		res = tuple(out)
		self._eff_cache[key] = res
		return res

	def marked_defs(self, name):
		res = self._marked_defs_cache.get(name)
		if res is None:
			res = sorted({d.display() for t in self.types_defining.get(name, ()) for d in self.procs[(t, name)] if any(self.eff_def(d))})
			self._marked_defs_cache[name] = res
		return res

	def risky_descendants(self, t, name, base_def, flags):
		"""Overrides below `t` that a call on a `t`-typed receiver could dispatch to
		at runtime and that the check against `base_def` would not cover."""
		risky = []
		base_params = [p for p in base_def.params if p != "..."] if base_def else []
		for dt in self.types_defining.get(name, ()):
			if not self.is_strict_descendant(dt, t):
				continue
			d = self.procs[(dt, name)][-1]
			fl = self.eff_def(d)
			if not any(fl):
				continue
			if any(f and not g for f, g in zip(fl, flags)):
				risky.append(d.display())
			elif fl[0] and len([p for p in d.params if p != "..."]) > len(base_params):
				risky.append(d.display())
		return sorted(set(risky))

	def proc_possibly_marked(self, t, name):
		"""True if `t.name` or an override below `t` is marked."""
		if t is None:
			return name in self.marked_names
		d = self.resolve(t, name)
		if any(self.eff_def(d)):
			return True
		if t == "/":
			return False
		for dt in self.types_defining.get(name, ()):
			if self.is_strict_descendant(dt, t) and any(self.eff_def(self.procs[(dt, name)][-1])):
				return True
		return False

	# ----------------------------------------------------------------- checks
	def check_args(self, d, flags, args):
		"""Bind `args` against marked definition `d`; returns [(rule, message)]."""
		self.checked_calls += 1
		out = []
		callee = d.display()
		params = [p for p in d.params if p != "..."]
		for a in args:
			is_kw, _ = _keyword(a)
			if _is_arglist(a) or (is_kw and _is_arglist(a.rhs)):
				return [("arglist", f"arglist() in a call to marked proc {callee}: the arguments cannot be counted or named")]
		bound = {}
		positional = 0
		# Parameter indices in the order the call binds them (for SHOULD_KEEP_PARAM_ORDER).
		sequence = []
		seen_keyword = False
		# How BYOND binds a positional argument that follows a keyword argument is
		# not something this tool relies on: such calls are reported and the
		# missing/too-many checks are skipped for them.
		ambiguous = False
		for index, a in enumerate(args):
			is_kw, kw = _keyword(a)
			if is_kw:
				seen_keyword = True
				if kw is None:
					out.append(("unknown_keyword", f"keyword argument with a non-name left-hand side in call to {callee}"))
				elif kw not in params:
					out.append(("unknown_keyword", f"`{kw}` is not a parameter of {callee} (parameters: {_fmt_list(params, 30)})"))
				elif kw in bound:
					out.append(("duplicate_binding", f"parameter `{kw}` of {callee} is bound twice ({bound[kw]} and keyword)"))
				else:
					bound[kw] = "keyword"
					sequence.append(params.index(kw))
				continue
			if seen_keyword:
				ambiguous = True
				if flags[1]:
					out.append(("positional_arg", f"argument {index + 1} of call to {callee} is positional; SHOULD_STATE_PARAM_NAMES requires `name = value`"))
				out.append(("positional_after_keyword", f"positional argument {index + 1} follows a keyword argument in call to {callee}; name it"))
				continue
			target = params[positional] if positional < len(params) else None
			if flags[1]:
				where = f"parameter `{target}`" if target else "an extra argument"
				out.append(("positional_arg", f"argument {index + 1} of call to {callee} is positional ({where}); SHOULD_STATE_PARAM_NAMES requires `name = value`"))
			if target is not None:
				bound[target] = f"position {positional + 1}"
				sequence.append(positional)
			positional += 1
		if flags[2] and not ambiguous:
			for prev, cur in zip(sequence, sequence[1:]):
				if cur < prev:
					passed = [params[i] for i in sequence]
					expected = [params[i] for i in sorted(sequence)]
					out.append(("param_order", f"call to {callee} passes `{params[cur]}` after `{params[prev]}`, but `{params[cur]}` is declared first; SHOULD_KEEP_PARAM_ORDER requires the declared order: expected {_fmt_list(expected, 30)}, got {_fmt_list(passed, 30)}"))
					break
		if flags[0] and not ambiguous:
			if positional > len(params):
				out.append(("too_many_args", f"call to {callee} passes {positional} positional argument(s) but it declares only {len(params)} parameter(s)"))
			missing = [p for p in params if p not in bound]
			if missing:
				out.append(("missing_params", f"call to {callee} does not pass parameter(s) {_fmt_list(missing, 30)}"))
		return out

	def check_call(self, t, name, args, exact):
		"""Check a call of `name` on a receiver whose static type is `t` (None = unknown)."""
		if t is not None and t not in self.parent:
			t = None
		if t is None:
			if name == "New":
				return []
			return [("unverifiable_call", f"cannot verify call to possibly-marked proc `{name}`: the receiver's static type is unknown (marked definitions: {', '.join(self.marked_defs(name))})")]
		d = self.resolve(t, name)
		flags = self.eff_def(d)
		out = []
		if any(flags):
			out.extend(self.check_args(d, flags, args))
		if not exact:
			risky = self.risky_descendants(t, name, d, flags)
			if risky:
				out.append(("unverifiable_call", f"call to `{name}` on a receiver of static type {t} may dispatch at runtime to marked override(s) {', '.join(risky)} which this call is not checked against; use a more specific type"))
		return out

	def check_definition(self, pi, uses_args):
		flags = self.eff_def(pi)
		if not any(flags):
			return
		disp = pi.display()
		if "..." in pi.params:
			self.add(pi.file, pi.line, "variadic", f"marked proc {disp} declares a `...` parameter")
		if uses_args:
			self.add(pi.file, pi.line, "variadic", f"marked proc {disp} uses the `args` list")
		info = self.def_text(pi)
		if info.error:
			self.add(pi.file, pi.line, "unverifiable_definition", f"cannot analyse the definition of marked proc {disp}: {info.error}")
		# verb check: this definition or any definition it overrides
		d = pi
		while d is not None:
			dinfo = self.def_text(d)
			if dinfo.path_text and "/verb/" in dinfo.path_text + "/":
				self.add(pi.file, pi.line, "marked_verb", f"marked proc {disp} is a verb (declared as `{dinfo.path_text}`)")
				break
			d = self.parent_def(d)
		pd = self.parent_def(pi)
		if pd is not None:
			expected = [p for p in pd.params if p != "..."]
			actual = pi.params[:len(expected)]
			if actual != expected:
				self.add(pi.file, pi.line, "override_params", f"{disp} must start with the parameters of {pd.display()} in the same order: expected {_fmt_list(expected, 30)}, got {_fmt_list(pi.params, 30)}")
		if flags[0] and self.options.check_defaults and not info.error:
			names = [s.name for s in info.params]
			if names != pi.params:
				self.add(pi.file, pi.line, "unverifiable_definition", f"parameter names read from the source of {disp} ({_fmt_list(names, 30)}) do not match the parsed parameters ({_fmt_list(pi.params, 30)})")
			else:
				defaults = [s.name for s in info.params if s.has_default]
				if defaults:
					self.add(pi.file, pi.line, "default_value", f"{disp} is SHOULD_CALL_ALL_PARAMS but declares default value(s) for {_fmt_list(defaults, 30)}; every caller must pass these, so the defaults are dead code (remove them, or run with --no-default-value-check)")

	# -------------------------------------------------------------- dangerous
	def prepare_dangerous(self):
		"""Identifiers / macros whose presence in hidden argument text could mean a call to a marked proc."""
		self.danger_idents = {n for n in self.marked_names if n != "New"}
		self.new_marked = "New" in self.marked_names
		danger_macros = set()
		macro_tokens = {}
		for name, macro in self.macros.items():
			idents = set()
			paths = []
			for body in macro.bodies:
				idents.update(IDENT_RE.findall(body))
				paths.extend(_NEW_PATH_RE.findall(body))
			macro_tokens[name] = (idents, paths)
		changed = True
		while changed:
			changed = False
			for name, (idents, paths) in macro_tokens.items():
				if name in danger_macros:
					continue
				if self._tokens_dangerous(idents, paths, danger_macros):
					danger_macros.add(name)
					changed = True
		self.danger_macros = danger_macros

	def _path_dangerous(self, path):
		t = self.norm_type(path)
		return t is not None and self.proc_possibly_marked(t, "New")

	def _tokens_dangerous(self, idents, paths, danger_macros):
		if idents & self.danger_idents or idents & danger_macros:
			return True
		if self.new_marked:
			if "New" in idents:
				return True
			for p in paths:
				if self._path_dangerous(p):
					return True
		return False

	def hidden_text_danger(self, text):
		idents = set(IDENT_RE.findall(text))
		paths = _NEW_PATH_RE.findall(text)
		hits = sorted((idents & self.danger_idents) | (idents & self.danger_macros))
		if self.new_marked:
			if "New" in idents:
				hits.append("New")
			hits.extend(f"new {p}" for p in paths if self._path_dangerous(p))
		return hits

	# -------------------------------------------------------------------- run
	def run(self):
		has_markers = bool(self.marked_names)
		if has_markers:
			self.prepare_dangerous()
		for pi in self.all_procs:
			collector = _Collector()
			try:
				pi.decl.walk(collector)
			except (KeyboardInterrupt, SystemExit):
				raise
			except BaseException as exc:  # pyo3 PanicException is a BaseException
				if has_markers:
					what = "its body failed to parse" if type(exc).__name__ == "EmptyProcError" else f"avulto raised {type(exc).__name__}: {str(exc).strip()[:120]}"
					self.add(pi.file, pi.line, "unparsable_proc", f"cannot check calls inside {pi.display()}: {what}")
				continue
			self.walked += 1
			walker = ProcWalker(self, pi)
			try:
				walker.run(collector.items)
			except UnsupportedNode as exc:
				if has_markers:
					self.add(pi.file, pi.line, "unparsable_proc", f"cannot check calls inside {pi.display()}: unsupported AST node {exc}")
				continue
			self.check_definition(pi, walker.uses_args)


_NEW_PATH_RE = re.compile(r"\bnew\s*(/[A-Za-z_][\w/]*)")
_PROC_SEGMENTS = ("proc", "verb")


class ProcWalker:
	def __init__(self, an, pi):
		self.an = an
		self.pi = pi
		self.src_type = None if pi.type == "/" else pi.type
		params = {}
		for a in pi.decl.args:
			if a.arg_name == "...":
				continue
			params[a.arg_name] = an.norm_type(str(a.arg_type)) if a.arg_type is not None else None
		self.scopes = [params]
		self.uses_args = False
		self.cur_line = pi.line
		self.active = bool(an.marked_names)

	def run(self, items):
		for s in items:
			self.stmt(s)

	# ------------------------------------------------------------ utilities
	def declare(self, name, t):
		self.scopes[-1][name] = t

	def block(self, stmts):
		if not stmts:
			return
		self.scopes.append({})
		for s in stmts:
			self.stmt(s)
		self.scopes.pop()

	def ident_type(self, name):
		for scope in reversed(self.scopes):
			if name in scope:
				return scope[name]
		if name == "src":
			return self.src_type
		if name == "usr":
			return "/mob"
		if name == "world":
			return "/world"
		if name == "args":
			return "/list"
		if self.src_type is not None:
			t = self.an.var_type(self.src_type, name)
			if t is not _MISSING:
				return t
		t = self.an.var_type("/", name)
		return None if t is _MISSING else t

	def expr_type(self, e):
		if e is None:
			return None
		c = _cls(e)
		if c == "Expression_Identifier":
			return self.ident_type(e.name)
		if c == "Expression_Field":
			if e.expr is None:
				return None
			t = self.expr_type(e.expr)
			if t is None:
				return None
			v = self.an.var_type(t, e.field.name)
			return None if v is _MISSING else v
		if c == "Expression_NewPrefab":
			return self.an.norm_type(str(e.prefab.path))
		return None

	def emit(self, node, diags):
		if not diags:
			return
		loc = getattr(node, "source_loc", None)
		if loc is not None:
			line, col = loc.line, loc.column
		else:
			line, col = self.cur_line, 0
		if self.an.try_consume_skip(self.pi.fkey, line, col):
			return
		for rule, msg in diags:
			self.an.add(self.pi.file, line, rule, msg)

	def note_loc(self, node):
		loc = getattr(node, "source_loc", None)
		if loc is not None:
			self.cur_line = loc.line

	# ------------------------------------------------------------ statements
	def stmt(self, s):
		if s is None:
			return
		c = _cls(s)
		if c.startswith("Expression_"):
			self.expr(s)
			return
		self.note_loc(s)
		h = _STMT_HANDLERS.get(c)
		if h is None:
			raise UnsupportedNode(c)
		h(self, s)

	def s_expression(self, s):
		self.expr(s.expr)

	def s_var(self, s):
		dt = self.an.norm_type(str(s.declared_type)) if s.declared_type is not None else None
		self.expr(s.value, target=dt)
		self.declare(s.name.name, dt)

	def s_vars(self, s):
		for v in s.vars:
			self.stmt(v)

	def s_return(self, s):
		self.expr(s.retval)

	def s_expr_field(self, s):
		self.expr(s.expr)

	def s_while(self, s):
		self.expr(s.condition)
		self.block(s.block)

	def s_if(self, s):
		for cond, blk in s.if_arms:
			self.expr(cond)
			self.block(blk)
		if s.else_arm:
			self.block(s.else_arm)

	def s_for_infinite(self, s):
		self.block(s.block)

	def s_for_loop(self, s):
		self.scopes.append({})
		for part in (s.init, s.test, s.inc):
			if part is None:
				continue
			if _cls(part).startswith("Expression_"):
				self.expr(part)
			else:
				self.stmt(part)
		self.block(s.block)
		self.scopes.pop()

	def s_for_list(self, s):
		self.expr(s.in_list)
		self.scopes.append({})
		if s.var_type is not None:
			self.declare(s.name.name, self.an.norm_type(str(s.var_type)))
		self.block(s.block)
		self.scopes.pop()

	def s_for_key_value(self, s):
		self.expr(s.in_list)
		self.scopes.append({})
		if s.var_type is not None:
			self.declare(s.key.name, self.an.norm_type(str(s.var_type)))
		self.block(s.block)
		self.scopes.pop()

	def s_for_range(self, s):
		self.expr(s.start)
		self.expr(s.end)
		self.expr(s.step)
		self.block(s.block)

	def s_setting(self, s):
		self.expr(s.value)

	def s_spawn(self, s):
		self.expr(s.delay)
		self.block(s.block)

	def s_switch(self, s):
		self.expr(s.input)
		for case in s.cases:
			for e in case.exact:
				self.expr(e)
			for rng in case.range:
				for e in rng:
					self.expr(e)
			self.block(case.block)
		if s.default:
			self.block(s.default)

	def s_try(self, s):
		self.block(s.try_block)
		self.scopes.append({})
		for params in s.catch_params or ():
			names = [p.name for p in params if _cls(p) == "Expression_Identifier"]
			if len(names) >= 2 and names[0] == "var":
				t = "/" + "/".join(names[1:-1]) if len(names) > 2 else None
				self.declare(names[-1], self.an.norm_type(t) if t else None)
		self.block(s.catch_block)
		self.scopes.pop()

	def s_nothing(self, s):
		pass

	def s_label(self, s):
		self.block(s.block)

	def s_unknown(self, s):
		raise UnsupportedNode("Node_Unknown")

	# ----------------------------------------------------------- expressions
	def expr(self, e, target=None):
		if e is None:
			return
		c = _cls(e)
		h = _EXPR_HANDLERS.get(c)
		if h is None:
			raise UnsupportedNode(c)
		h(self, e, target)

	def e_nothing(self, e, target):
		pass

	def e_identifier(self, e, target):
		if e.name == "args" and not any("args" in s for s in self.scopes):
			self.uses_args = True

	def e_list(self, e, target):
		lst = e.list
		for k in lst.keys():
			self.expr(k)
			try:
				v = lst[k]
			except Exception as exc:
				raise UnsupportedNode(f"list literal value not retrievable ({exc})")
			if v is not k:
				self.expr(v)

	def e_binary(self, e, target):
		self.expr(e.lhs)
		self.expr(e.rhs)

	def e_assign(self, e, target):
		self.expr(e.lhs)
		op = _op_name(e.op)
		rhs_target = None
		if op in ("ASSIGN", "ASSIGN_OR", "ASSIGN_AND") and self.active:
			rhs_target = self.expr_type(e.lhs)
		self.expr(e.rhs, target=rhs_target)

	def e_ternary(self, e, target):
		self.expr(e.cond)
		self.expr(e.if_expr)
		self.expr(e.else_expr)

	def e_interp(self, e, target):
		for pair in e.token_pairs:
			if pair[0] is not None:
				self.expr(pair[0])

	def e_locate(self, e, target):
		for a in e.args:
			self.expr(a)
		self.expr(e.in_list)

	def e_index(self, e, target):
		self.expr(e.expr)
		self.expr(e.index)

	def e_field(self, e, target):
		self.expr(e.expr)

	def e_unary(self, e, target):
		self.expr(e.expr)

	def e_input(self, e, target):
		for a in e.args:
			self.expr(a)
		self.expr(e.in_list)

	def e_pick(self, e, target):
		for key, val in e.args:
			self.expr(key)
			self.expr(val)

	def e_external(self, e, target):
		self.expr(e.library_name)
		self.expr(e.function_name)
		for a in e.args:
			self.expr(a)

	def visit_args(self, args):
		for a in args or ():
			is_kw, _ = _keyword(a)
			if is_kw:
				self.expr(a.rhs)
			else:
				self.expr(a)

	def e_call(self, e, target):
		self.note_loc(e)
		name = e.name.name
		recv = e.expr
		bare = _is_null_const(recv)
		if self.active and name in self.an.marked_names:
			if bare:
				if self.src_type is not None and self.an.resolve(self.src_type, name) is not None:
					diags = self.an.check_call(self.src_type, name, e.args, exact=False)
				else:
					diags = self.an.check_call("/", name, e.args, exact=True)
			elif _cls(recv) == "Expression_Identifier" and recv.name == "global" and not any("global" in sc for sc in self.scopes):
				diags = self.an.check_call("/", name, e.args, exact=True)
			else:
				diags = self.an.check_call(self.expr_type(recv), name, e.args, exact=False)
			self.emit(e, diags)
		if not bare:
			self.expr(recv)
		self.visit_args(e.args)

	def e_self_call(self, e, target):
		self.note_loc(e)
		if self.active and self.pi.name in self.an.marked_names:
			if self.src_type is None:
				diags = self.an.check_call("/", self.pi.name, e.args, exact=True)
			else:
				diags = self.an.check_call(self.src_type, self.pi.name, e.args, exact=False)
			self.emit(e, diags)
		self.visit_args(e.args)

	def e_parent_call(self, e, target):
		self.note_loc(e)
		if self.active and e.args:
			pd = self.an.parent_def(self.pi)
			flags = self.an.eff_def(pd)
			if any(flags):
				self.emit(e, self.an.check_args(pd, flags, e.args))
		self.visit_args(e.args)

	def e_new_prefab(self, e, target):
		self.note_loc(e)
		if self.active and "New" in self.an.marked_names:
			t = self.an.norm_type(str(e.prefab.path))
			if t is not None:
				self.emit(e, self.an.check_call(t, "New", e.args or [], exact=True))
		self.visit_args(e.args)

	def e_new_implicit(self, e, target):
		self.note_loc(e)
		if self.active and target is not None and "New" in self.an.marked_names:
			self.emit(e, self.an.check_call(target, "New", e.args or [], exact=True))
		self.visit_args(e.args)

	def mini_type(self, e):
		base = e.name.name
		fields = [f.field.name for f in e.fields]
		if base == "type" and not fields and not any("type" in s for s in self.scopes):
			return self.src_type
		t = self.ident_type(base)
		for f in fields:
			if t is None:
				return None
			if f == "type":
				continue
			v = self.an.var_type(t, f)
			t = None if v is _MISSING else v
		return t

	def e_new_mini(self, e, target):
		self.note_loc(e)
		if not self.active:
			return
		expr_text = ".".join([e.name.name] + [f.field.name for f in e.fields])
		diags = []
		if "New" in self.an.marked_names:
			t = self.mini_type(e) or target
			if t is not None and self.an.proc_possibly_marked(t, "New"):
				diags.append(("unverifiable_call", f"`new {expr_text}(...)` may create {t} or a subtype with a marked New(), but avulto does not expose the arguments of `new <variable>(...)`, so the call cannot be checked; use `new /explicit/path(...)`"))
		hidden = self.hidden_args_danger(e)
		if hidden:
			diags.append(("unverifiable_call", f"the argument list of `new {expr_text}(...)` is not visible to param_lint (avulto drops it) and its source text references {hidden}; move that call out of these arguments"))
		self.emit(e, diags)

	def hidden_args_danger(self, e):
		"""Inspect the raw text of a `new <expr>(...)` argument list, which avulto drops."""
		loc = e.source_loc
		src = self.an.sources.get(self.pi.file)
		off = src.offset(loc.line, loc.column) if loc is not None else None
		if off is None:
			return "an unlocatable expression (no source location)"
		masked = src.masked
		m = re.compile(r"new\b\s*[\w.:]*\s*").match(masked, off)
		if m:
			k = m.end()
			if k >= len(masked) or masked[k] != "(":
				return None
			end = balanced_end(masked, k)
			text = masked[k:end] if end else masked[k:]
			hits = self.an.hidden_text_danger(text)
			return _fmt_list(hits) if hits else None
		m = IDENT_RE.match(masked, off)
		if m:
			# The `new` came from a macro expansion; inspect the whole invocation.
			ident = m.group()
			k = m.end()
			while k < len(masked) and masked[k] in " \t":
				k += 1
			text = ident
			if k < len(masked) and masked[k] == "(":
				end = balanced_end(masked, k)
				text = masked[off:end] if end else masked[off:]
			hits = self.an.hidden_text_danger(text)
			return _fmt_list(hits) if hits else None
		return "an unlocatable expression (source text does not start with `new` or a macro name)"

	def ref_check(self, node, t_spec, name, shown):
		an = self.an
		if t_spec == "SRC":
			t = self.src_type or "/"
		else:
			t = t_spec
		if t is None or an.proc_possibly_marked(t, name):
			marked = ", ".join(an.marked_defs(name))
			self.emit(node, [("proc_reference", f"`{shown}` references marked proc `{name}` ({marked}); calls made through proc references (PROC_REF, CALLBACK, INVOKE_ASYNC, call()(), ...) cannot be checked")])

	def e_prefab(self, e, target):
		if not self.active:
			return
		s = str(e.prefab.path)
		spec = _parse_proc_path(s)
		if spec is None:
			return
		tpart, name = spec
		if name not in self.an.marked_names:
			return
		self.note_loc(e)
		if tpart == "SRC":
			t = "SRC"
		elif tpart == "/":
			t = "/"
		else:
			t = self.an.norm_type(tpart)
		self.ref_check(e, t, name, s)

	def e_proc_reference(self, e, target):
		self.note_loc(e)
		name = e.name.name
		base = e.expr
		if self.active and name in self.an.marked_names:
			if _cls(base) == "Expression_Prefab":
				t = self.an.norm_type(str(base.prefab.path))
			else:
				t = self.expr_type(base)
			shown = str(base.prefab.path) if _cls(base) == "Expression_Prefab" else str(base)
			self.ref_check(e, t, name, f"{shown}::{name}()")
		if _cls(base) != "Expression_Prefab":
			self.expr(base)

	def e_static_field(self, e, target):
		self.expr(e.expr)

	def e_dynamic_call(self, e, target):
		self.note_loc(e)
		lib = list(e.lib_name)
		if self.active and lib:
			name = _const_string(lib[-1])
			if name is not None and name in self.an.marked_names:
				t = self.expr_type(lib[0]) if len(lib) >= 2 else "/"
				if t is None or self.an.proc_possibly_marked(t, name):
					self.emit(e, [("dynamic_call", f"call(..., \"{name}\")() may call marked proc `{name}` ({', '.join(self.an.marked_defs(name))}) without any argument checking")])
		for a in lib:
			self.expr(a)
		for a in e.proc_name:
			is_kw, _ = _keyword(a)
			self.expr(a.rhs if is_kw else a)


def _parse_proc_path(s):
	"""('/type' | '/' | 'SRC', name) for a proc path prefab, else None."""
	if s.startswith("."):
		parts = [p for p in s[1:].split("/") if p]
		if len(parts) == 2 and parts[0] in _PROC_SEGMENTS:
			return "SRC", parts[1]
		if len(parts) == 1:
			return "SRC", parts[0]
		return None
	# TYPE_PROC_REF expands to `/type.proc/name`; accept `.` and `:` separators too.
	parts = [p for p in re.split(r"[/.:]", s) if p]
	if len(parts) >= 2 and parts[-2] in _PROC_SEGMENTS:
		head = parts[:-2]
		return ("/" + "/".join(head)) if head else "/", parts[-1]
	return None


_STMT_HANDLERS = {
	"Node_Expression": ProcWalker.s_expression,
	"Node_Var": ProcWalker.s_var,
	"Node_Vars": ProcWalker.s_vars,
	"Node_Return": ProcWalker.s_return,
	"Node_Throw": ProcWalker.s_expr_field,
	"Node_Del": ProcWalker.s_expr_field,
	"Node_Crash": ProcWalker.s_expr_field,
	"Node_While": ProcWalker.s_while,
	"Node_DoWhile": ProcWalker.s_while,
	"Node_If": ProcWalker.s_if,
	"Node_ForInfinite": ProcWalker.s_for_infinite,
	"Node_ForLoop": ProcWalker.s_for_loop,
	"Node_ForList": ProcWalker.s_for_list,
	"Node_ForKeyValue": ProcWalker.s_for_key_value,
	"Node_ForRange": ProcWalker.s_for_range,
	"Node_Setting": ProcWalker.s_setting,
	"Node_Spawn": ProcWalker.s_spawn,
	"Node_Switch": ProcWalker.s_switch,
	"Node_TryCatch": ProcWalker.s_try,
	"Node_Continue": ProcWalker.s_nothing,
	"Node_Break": ProcWalker.s_nothing,
	"Node_Goto": ProcWalker.s_nothing,
	"Node_Label": ProcWalker.s_label,
	"Node_Unknown": ProcWalker.s_unknown,
}

_EXPR_HANDLERS = {
	"Expression_Constant": ProcWalker.e_nothing,
	"Expression_Identifier": ProcWalker.e_identifier,
	"Expression_List": ProcWalker.e_list,
	"Expression_BinaryOp": ProcWalker.e_binary,
	"Expression_AssignOp": ProcWalker.e_assign,
	"Expression_TernaryOp": ProcWalker.e_ternary,
	"Expression_InterpString": ProcWalker.e_interp,
	"Expression_Locate": ProcWalker.e_locate,
	"Expression_Prefab": ProcWalker.e_prefab,
	"Expression_Index": ProcWalker.e_index,
	"Expression_Field": ProcWalker.e_field,
	"Expression_StaticField": ProcWalker.e_static_field,
	"Expression_Call": ProcWalker.e_call,
	"Expression_SelfCall": ProcWalker.e_self_call,
	"Expression_ParentCall": ProcWalker.e_parent_call,
	"Expression_UnaryOp": ProcWalker.e_unary,
	"Expression_ProcReference": ProcWalker.e_proc_reference,
	"Expression_ExternalCall": ProcWalker.e_external,
	"Expression_NewMiniExpr": ProcWalker.e_new_mini,
	"Expression_NewImplicit": ProcWalker.e_new_implicit,
	"Expression_NewPrefab": ProcWalker.e_new_prefab,
	"Expression_DynamicCall": ProcWalker.e_dynamic_call,
	"Expression_Input": ProcWalker.e_input,
	"Expression_Pick": ProcWalker.e_pick,
}
