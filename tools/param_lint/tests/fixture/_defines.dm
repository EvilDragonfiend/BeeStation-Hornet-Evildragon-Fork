// Copies of the real marker macros (code/__DEFINES/param_lint.dm) and of the
// game's callback/proc-ref helpers, so the fixture is self-contained.
// The `#define` lines below mention the markers; param_lint must ignore them.

#define SHOULD_CALL_ALL_PARAMS(X)
#define SHOULD_STATE_PARAM_NAMES(X)
#define SHOULD_KEEP_PARAM_ORDER(X)
#define PARAM_LINT_SKIP(X) X

#define PROC_REF(X) (nameof(.proc/##X))
#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
#define GLOBAL_PROC_REF(X) (/proc/##X)
#define GLOBAL_PROC "some_magic_bullshit"
#define CALLBACK new /datum/callback
#define INVOKE_ASYNC(proc_owner, proc_path, proc_arguments...) \
	if ((proc_owner) == GLOBAL_PROC) { \
		spawn(-1) { \
			call(proc_path)(##proc_arguments); \
		}; \
	} \
	else { \
		spawn(-1) { \
			call(0 || proc_owner, proc_path)(##proc_arguments); \
		}; \
	}

/// Uses __TYPE__, which avulto 0.1.x cannot parse unless param_lint redefines it.
#define stack_trace(msg) _stack_trace(msg, __FILE__, __LINE__, __PROC__, __TYPE__)

/// Expands to three keyword arguments.
#define THREE_KEYWORDS a = 1, b = 2, c = 3
/// Expands to two positional arguments.
#define TWO_POSITIONAL 1, 2
/// Argument-forwarding macro in the style of RECORD_GENERAL_STRICT_ARGS.
#define FORWARD_THREE(x, y, z) x, y, z
/// Object-like macro expanding to two parameters (cannot be mapped to parameter text).
#define TWO_PARAMS a, b
/// Object-like macro expanding to nothing.
#define NO_PARAMS
/// A call to a marked proc that lives entirely in a macro body.
#define MAKE_WIDGET new /datum/widget(a = 1, b = 2, c = 3)
/// A macro hiding a call to the marked proc `grow`.
#define CALL_GROW(obj) obj.grow(a = 1, b = 2)
