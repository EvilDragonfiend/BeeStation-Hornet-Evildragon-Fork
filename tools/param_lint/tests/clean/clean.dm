#define SHOULD_CALL_ALL_PARAMS(X)
#define SHOULD_STATE_PARAM_NAMES(X)
#define PARAM_LINT_SKIP(X) X

/datum/thing/New(a, b)
	SHOULD_CALL_ALL_PARAMS(TRUE)
	SHOULD_STATE_PARAM_NAMES(TRUE)
	return ..()

/datum/thing/child/New(a, b, c)
	return ..()

/datum/user/proc/make()
	var/datum/thing/t = new(a = 1, b = 2)
	var/datum/thing/child/c = new /datum/thing/child(a = 1, b = 2, c = 3)
	var/datum/thing/skipped = PARAM_LINT_SKIP(new /datum/thing())
	return list(t, c, skipped)
