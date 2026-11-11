// Definition-side rules.

/datum/defs

/datum/defs/proc/variadic_params(a, ...) // EXPECT: variadic
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return a

/datum/defs/proc/uses_args(a) // EXPECT: variadic
	SHOULD_STATE_PARAM_NAMES(TRUE)
	return length(args)

/// OK(variadic): neither `...` nor `args`.
/datum/defs/proc/local_args(a)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	var/list/args_copy = list(a)
	return args_copy

/mob/verb/marked_verb() // EXPECT: marked_verb
	SHOULD_STATE_PARAM_NAMES(TRUE)
	return

/// OK(marked_verb): unmarked verb.
/mob/verb/plain_verb()
	return

/datum/defs/proc/with_defaults(a, b = 2, c = "x") // EXPECT: default_value
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return a

/// OK(default_value): defaults are only an error with SHOULD_CALL_ALL_PARAMS.
/datum/defs/proc/names_only_defaults(a, b = 2)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	return a

/// OK(default_value) OK(unverifiable_definition): multi-line parameter list through a forwarding macro, no defaults.
/datum/defs/proc/macro_params(FORWARD_THREE(
	a,
	datum/b,
	list/c), NO_PARAMS)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return a

/datum/defs/proc/macro_defaults(FORWARD_THREE( // EXPECT: default_value
	a,
	b = "x, y",
	list/c = list(1, 2)))
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return a

/// Hides its parameters in an object-like macro, so the parameter text cannot be analysed.
/datum/defs/proc/object_macro_params(TWO_PARAMS) // EXPECT: unverifiable_definition
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return a

// ---------------------------------------------------------------------------
// Marker parsing.

/datum/defs/proc/bad_argument(a)
	SHOULD_CALL_ALL_PARAMS(YES) // EXPECT: bad_marker
	SHOULD_STATE_PARAM_NAMES(1) // OK(bad_marker)
	return a

/datum/defs/proc/ignored_markers(a)
	// SHOULD_CALL_ALL_PARAMS(TRUE)
	/* SHOULD_STATE_PARAM_NAMES(TRUE)
	   SHOULD_CALL_ALL_PARAMS(TRUE) */
	var/text = "SHOULD_CALL_ALL_PARAMS(TRUE) [a] SHOULD_STATE_PARAM_NAMES(TRUE)"
	var/more = {"
		SHOULD_CALL_ALL_PARAMS(TRUE)
	"}
	return text + more

/datum/defs/not_a_proc
	var/x = 1
	SHOULD_STATE_PARAM_NAMES(TRUE) // EXPECT: bad_marker

/datum/defs/proc/conflicting(a)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	SHOULD_CALL_ALL_PARAMS(FALSE) // EXPECT: bad_marker
	return a
