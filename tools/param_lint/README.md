# param_lint

A static checker for calls to procs that take many parameters (record datums, `growclone()`, ...).
A proc opts in with a marker; every call that violates the rule, or that the tool cannot prove
correct, is an **error** and fails CI.

It is built on [avulto](https://github.com/warriorstar-orion/avulto) (Python bindings over the
SpacemanDMM parser), pinned to `0.1.22` in `tools/requirements.txt` because that is the newest
release with CPython 3.11 wheels (the repository's pinned Python version).

## Running

From the repository root:

```sh
tools/bootstrap/python -m param_lint.check                 # checks beestation.dme
tools/bootstrap/python -m param_lint.check path/to/x.dme   # any other environment
tools/bootstrap/python -m param_lint.check --extra-pass CIBUILDING   # what CI runs
tools/bootstrap/python -m param_lint.tests                 # the tool's own tests
```

On Windows use `tools\bootstrap\python.bat` instead of `tools/bootstrap/python`. In VS Code, run the
task **param_lint: check marked proc calls**; results show up in the Problems panel.

Options:

| option | meaning |
| --- | --- |
| `dme` | environment to check, default `beestation.dme` |
| `-D NAME[=VALUE]`, `--define` | preprocessor define added to every pass |
| `--extra-pass NAME[=VALUE],...` | run one more pass with these defines; results of all passes are merged |
| `--no-default-value-check` | do not report `default_value` |
| `--list-rules` | print all rule ids |

Output is one line per error, `path:line: error[rule_id]: message`, followed by a summary line with
counts and elapsed time. With `GITHUB_ACTIONS=true` every error is also printed as a
`::error file=...,line=...,title=...::` annotation. The exit code is 1 if there is any error.

## Markers

Defined in `code/__DEFINES/param_lint.dm`. They expand to nothing for every compiler and linter;
param_lint finds them in the raw source text (ignoring comments, strings and `#define` lines) and
attaches each one to the proc whose definition precedes it.

```dm
/datum/record/New(age, blood_type, name)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	SHOULD_KEEP_PARAM_ORDER(TRUE)
```

* `SHOULD_CALL_ALL_PARAMS(TRUE)`: every call must bind every declared parameter exactly once (by
  position or `name = value`) and must not pass more arguments than declared. Parameters must not
  have default values.
* `SHOULD_STATE_PARAM_NAMES(TRUE)`: every argument of every call must be `name = value`.
* `SHOULD_KEEP_PARAM_ORDER(TRUE)`: the arguments of every call must appear in the order the
  parameters are declared. Skipping a parameter is fine (use `SHOULD_CALL_ALL_PARAMS` to forbid
  that); only the relative order is checked. Positional arguments are in order by definition, so
  this matters for keyword arguments: it keeps call sites readable against the definition.
* `PARAM_LINT_SKIP(call)`: expands to `call`; exempts that call site on purpose, e.g.
  `PARAM_LINT_SKIP(new /datum/record/cloning())`. It exempts the first (outermost) call or proc
  reference inside its parentheses that would have produced errors; calls nested in that call's
  arguments are still checked.

A marker applies to the proc it is in and to every override in subtypes. An override can turn a check
off for itself and its subtypes with `SHOULD_CALL_ALL_PARAMS(FALSE)` / `SHOULD_STATE_PARAM_NAMES(FALSE)` / `SHOULD_KEEP_PARAM_ORDER(FALSE)`.
The argument must be `TRUE`, `FALSE`, `1` or `0`.

## How calls are resolved

param_lint does limited static typing to find which definition a call reaches:

* `new /path(...)` and `new /path` (no parentheses = zero arguments) use `/path`'s `New()`.
* `var/some/type/x = new(...)` and `x = new(...)` use the declared type of `x` (local var, proc
  parameter, `for(var/type/x in ...)` var, member var up the type tree, `a.b.c` field chains).
* `x.foo()`, `x?.foo()`, `x:foo()`, `src.foo()`, bare `foo()` (src's type first, then `/proc/foo`),
  `global.foo()`, `.()` (self call) and `..(args)` (the parent definition).
* `..()` with no arguments passes the caller's arguments through and is not checked.

A call on a receiver of static type `T` can dispatch at runtime to any override below `T`, so if an
override below `T` is marked differently (or requires more parameters) the call is an
`unverifiable_call`. A receiver whose type is unrelated to every marked definition of that name is
not checked at all.

## Rules

Call-site rules (only for calls that reach a marked proc):

| rule id | example of an error |
| --- | --- |
| `missing_params` | `new /datum/widget(a = 1)` when `New(a, b)` is `SHOULD_CALL_ALL_PARAMS` |
| `too_many_args` | `global_marked(1, 2, 3)` when it declares `(x, y)` |
| `positional_arg` | `m.grow(1, 2)` when `grow` is `SHOULD_STATE_PARAM_NAMES` |
| `param_order` | `o.build(b = 2, a = 1)` when `build(a, b, c)` is `SHOULD_KEEP_PARAM_ORDER`; reported once per call, at the first out-of-order argument |
| `positional_after_keyword` | `global_marked(x = 1, 2)`; how BYOND binds such an argument is not relied upon, so missing/extra checks are skipped for that call |
| `duplicate_binding` | `f(a = 1, a = 2)` or `f(1, a = 2)` |
| `unknown_keyword` | `f(zz = 4)` when `f` has no parameter `zz` |
| `arglist` | `new /datum/widget(arglist(list(1, 2)))`; the arguments cannot be counted |
| `unverifiable_call` | `thing.grow(a = 1, b = 2)` where `thing` is untyped, a list element, a proc's return value, or typed as an ancestor (`/obj`) of the marked type; `new path_var(...)` whose static type is related to a marked `New()` |
| `proc_reference` | `CALLBACK(src, PROC_REF(grow))`, `TYPE_PROC_REF(/obj/machine, grow)`, `GLOBAL_PROC_REF(f)`, `/obj/machine/proc/grow`, `/obj/machine::grow()` |
| `dynamic_call` | `call(src, "grow")(...)`, `INVOKE_ASYNC(src, "grow", ...)` |

Definition rules (for every definition that is effectively marked):

| rule id | example of an error |
| --- | --- |
| `override_params` | parent `New(a, b, c)`, override `New(a, bee, c)`. Overrides may append parameters (`New(a, b, c, d)`) but must start with the parent's names in order, because keyword arguments bind against the runtime proc's names |
| `variadic` | `proc/f(a, ...)` or a body that uses `args` |
| `marked_verb` | a marker inside a `verb/` |
| `default_value` | `proc/f(a, b = 2)` with `SHOULD_CALL_ALL_PARAMS`; the defaults are dead code once every caller passes everything. Read from the source text; turn off with `--no-default-value-check` |
| `unverifiable_definition` | the parameter list text of a marked proc cannot be matched to its parameters (e.g. parameters hidden in an object-like macro, or a proc generated by a macro) |

Tool rules:

| rule id | example of an error |
| --- | --- |
| `bad_marker` | `SHOULD_CALL_ALL_PARAMS(YES)`, a marker outside any proc body, `TRUE` and `FALSE` in the same proc |
| `unused_skip` | `PARAM_LINT_SKIP(m.grow(a = 1, b = 2))` around a call that is already fine |
| `unparsable_proc` | avulto cannot parse or walk a proc body (e.g. `::proc()` panics avulto 0.1.22), so calls in it cannot be checked. Only reported when at least one proc is marked |

## Known gaps

These are places where the tool is weaker than "every possible call is checked":

* **`new <variable>(...)`**: avulto drops the argument list of `new` with a non-constant type. Such a
  call is an error when the static type of the variable (or of the assignment target) is related to a
  marked `New()`. If the type is completely unknown it is **not** flagged, because otherwise marking
  any `New()` would flag every `new type(loc)` in the codebase. Calls nested inside those hidden
  arguments are found by scanning the raw text for marked proc names, `new /marked/path`, and macros
  whose bodies (transitively) contain those. Implicit `new()` and token-pasted names inside that text
  are not seen.
* **Forwarding**: atom `Initialize()` (arguments flow `New(loc, ...)` -> `Initialize(mapload, ...)`),
  `AddComponent(type, ...)`, `AddElement(...)`, `RegisterSignal` handlers and timers are not
  followed.
* **Proc names in strings**: only `call(thing, "literal")()` is detected. Legacy string callbacks
  (`CALLBACK(src, "name")`), `hascall()`, and `call(thing, some_var)()` are not.
* **Typing is declared-type only**: no `istype()` narrowing, no `RETURN_TYPE`, no list element types.
  `x:foo()` is treated like `x.foo()` using `x`'s declared type. A wrong declared type is trusted.
* **Conditional compilation**: avulto has no API for defines. param_lint parses a generated wrapper
  `.dme` that `#define`s the requested names and then `#include`s the real environment, so only
  code enabled in some pass is checked. CI runs the default pass plus `CIBUILDING` (unit tests are
  always included because `SPACEMAN_DMM` is defined). Code under other defines (`TESTING`, ...) is
  not walked. Markers are found in the raw text regardless of `#if` blocks.
* The wrapper also defines `__TYPE__` and `__IMPLIED_TYPE__` as `null`, because avulto 0.1.22 panics
  on them (they appear in every `stack_trace()`); this keeps every argument count unchanged. A future
  `new __IMPLIED_TYPE__(...)` would then fail to parse and be reported as `unparsable_proc`.
* **Macros**: tokens that come from macro arguments are reported at the macro invocation's line.
  `PARAM_LINT_SKIP` does not work when it is itself inside another macro's arguments (the location
  collapses to the outer macro). Markers inside `#define` bodies are ignored.
* Passing an explicit `null` counts as binding a parameter; nothing checks the value.
* `unused_skip` is also reported for skips in code that no pass compiles.

## Files

* `check.py`: command line entry point, wrapper DME, passes, output.
* `analysis.py`: type tree, marker inheritance, call resolution, all rules.
* `source.py`: raw-text scanning (comment/string masking, includes, defines, markers, parameter lists).
* `tests/`: `unittest` suite and fixture environments. Expected diagnostics are written next to the
  code in `tests/fixture/*.dm` as `// EXPECT: rule[*count]` (and `// EXPECT(extra): ...` for the
  extra-define pass); `// OK(rule)` marks the passing case for each rule.
