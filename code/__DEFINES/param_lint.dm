// Markers for tools/param_lint, a static checker for calls to procs with many parameters.
// These expand to nothing for every compiler and linter; param_lint finds them in the
// source text. See tools/param_lint/README.md for the full rules.

/**
 * If set, every call to this proc (and to overrides of it in subtypes) must bind every
 * declared parameter exactly once, by position or by `name = value`, and must not pass
 * more arguments than the proc declares. Parameters of such a proc must not declare
 * default values. Calls that param_lint cannot verify statically are errors.
 * Child procs may set this to `FALSE` to turn the check off for themselves and their subtypes.
 */
#define SHOULD_CALL_ALL_PARAMS(X)
/**
 * If set, every argument of every call to this proc (and to overrides of it in subtypes)
 * must be a keyword argument (`name = value`); positional arguments are errors.
 * Child procs may set this to `FALSE` to turn the check off for themselves and their subtypes.
 */
#define SHOULD_STATE_PARAM_NAMES(X)
/**
 * If set, the arguments of every call to this proc (and to overrides of it in subtypes) must appear
 * in the order the parameters are declared. Skipping parameters is allowed; only the relative order
 * is checked (combine with SHOULD_CALL_ALL_PARAMS to require every parameter).
 * Child procs may set this to `FALSE` to turn the check off for themselves and their subtypes.
 */
#define SHOULD_KEEP_PARAM_ORDER(X)
/**
 * Wraps a single call expression to exempt that call site from param_lint on purpose,
 * for example `PARAM_LINT_SKIP(new /datum/record/cloning())` where an empty call is intended.
 * Expands to its argument.
 */
#define PARAM_LINT_SKIP(X) X
