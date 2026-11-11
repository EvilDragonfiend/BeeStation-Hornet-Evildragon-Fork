/proc/_stack_trace(msg, file, line, proc, type)
	return

/datum/callback
	var/datum/object
	var/delegate

/datum/callback/New(thingtocall, proctocall, ...)
	object = thingtocall
	delegate = proctocall

/datum/plain

/datum/plain/New(a)
	return

// ---------------------------------------------------------------------------
// A marked New() and its subtypes.

/datum/widget
	var/datum/widget/buddy
	var/list/widgets

/datum/widget/New(a, b, c)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	if(!a)
		stack_trace("widget without a")
	return ..()

/// Appends a parameter: allowed. OK(override_params)
/datum/widget/big/New(a, b, c, d)
	..() // OK: pass-through parent call

/// Turns both checks off for itself and its subtypes.
/datum/widget/loose/New(a, b, c)
	SHOULD_CALL_ALL_PARAMS(FALSE)
	SHOULD_STATE_PARAM_NAMES(FALSE)
	..(a = a, b = b, c = c) // OK: parent call with arguments, all named

/// `..(a)` is a real call to the parent and is checked.
/datum/widget/checked_parent/New(a, b, c)
	..(a) // EXPECT: positional_arg, missing_params

/// Renames a parent parameter.
/datum/widget/renamed/New(a, bee, c) // EXPECT: override_params
	..()

// ---------------------------------------------------------------------------
// A marked member proc.

/obj/machine
	var/obj/machine/linked

/obj/machine/proc/grow(a, b)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	if(!a)
		return .(a = 1, b = b) // OK: self call, named
	if(!b)
		return .(1) // EXPECT: positional_arg, missing_params
	return a

/obj/machine/proc/other()
	return

/obj/machine/proc/self_calls()
	grow(a = 1, b = 2) // OK: bare call resolves to src.grow
	grow(1) // EXPECT: positional_arg, missing_params
	src.grow(b = 2) // EXPECT: missing_params

/// Inherits both markers.
/obj/machine/sub/grow(a, b)
	return ..()

/// Same proc name on an unrelated type, not marked.
/obj/unrelated/proc/grow(q)
	return q

// ---------------------------------------------------------------------------
// A proc that is only marked in a subtype.

/datum/animal/proc/speak(words)
	return words

/datum/animal/dog/speak(words)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	return words

// ---------------------------------------------------------------------------
// A marked global proc.

/proc/global_marked(x, y)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	return x + y

// ---------------------------------------------------------------------------
// SHOULD_KEEP_PARAM_ORDER on its own (no arity or naming requirement).

/datum/ordered/proc/build(a, b, c)
	SHOULD_KEEP_PARAM_ORDER(TRUE)
	return a

/// Inherits the order requirement.
/datum/ordered/strict/build(a, b, c)
	return ..()

/datum/ordered/loose/build(a, b, c)
	SHOULD_KEEP_PARAM_ORDER(FALSE)
	return ..()

/// Unmarked base whose override is marked: calls through the base type cannot be verified.
/datum/ordered_base/proc/run_it(a, b)
	return a

/datum/ordered_base/child/run_it(a, b)
	SHOULD_KEEP_PARAM_ORDER(TRUE)
	return ..()
