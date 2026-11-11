// Call-site rules.

/datum/caller
	var/datum/widget/my_widget
	var/obj/machine/my_machine
	var/untyped_thing

/datum/caller/proc/new_calls()
	new /datum/widget(a = 1, b = 2, c = 3) // OK(missing_params) OK(positional_arg) OK(too_many_args) OK(duplicate_binding) OK(unknown_keyword) OK(arglist)
	new /datum/widget(a = 1, b = 2) // EXPECT: missing_params
	new /datum/widget(1, b = 2, c = 3) // EXPECT: positional_arg
	new /datum/widget(a = 1, a = 2, b = 2, c = 3) // EXPECT: duplicate_binding
	new /datum/widget(a = 1, b = 2, c = 3, zz = 4) // EXPECT: unknown_keyword
	new /datum/widget(arglist(list(1, 2, 3))) // EXPECT: arglist
	new /datum/widget // EXPECT: missing_params
	new /datum/widget() // EXPECT: missing_params
	new /datum/widget(THREE_KEYWORDS) // OK: macro expanding to three keyword arguments
	new /datum/widget(FORWARD_THREE(a = 1, b = 2, c = 3))
	new /datum/widget(TWO_POSITIONAL, c = 3) // EXPECT: positional_arg*2
	new /datum/widget(
		a = 1,
		b = 2,
		c = 3)
	new /datum/widget( // EXPECT: missing_params
		a = 1,
		b = 2)
	MAKE_WIDGET
	new /datum/widget/big(a = 1, b = 2, c = 3) // EXPECT: missing_params
	new /datum/widget/big(a = 1, b = 2, c = 3, d = 4)
	new /datum/widget/loose(1) // OK: opted out with FALSE
	new /datum/widget/loose
	new /datum/plain(1)

/datum/caller/proc/arity_calls()
	global_marked(x = 1, y = 2)
	global_marked(1, 2) // OK(positional_arg): global_marked is only SHOULD_CALL_ALL_PARAMS
	global_marked(1, 2, 3) // EXPECT: too_many_args
	global_marked(1) // EXPECT: missing_params
	global_marked(1, x = 2, y = 3) // EXPECT: duplicate_binding
	global_marked(x = 1, 2) // EXPECT: positional_after_keyword
	global_marked(1, y = 2) // OK(positional_after_keyword)

/datum/caller/proc/implicit_new_calls()
	var/datum/widget/w = new(a = 1, b = 2, c = 3)
	var/datum/widget/w2 = new(a = 1) // EXPECT: missing_params
	w = new(b = 1) // EXPECT: missing_params
	w2 = new(a = 1, b = 2, c = 3)
	my_widget = new(a = 1, b = 2, c = 3)
	my_widget = new() // EXPECT: missing_params
	my_widget.buddy = new() // EXPECT: missing_params
	var/datum/plain/p = new(1)
	return list(w, w2, p)

/datum/caller/proc/dynamic_new_calls(datum/widget/widget_type, datum/plain/plain_type, some_type)
	new widget_type(1) // EXPECT: unverifiable_call
	new plain_type(1) // OK(unverifiable_call): unrelated static type
	new some_type(1) // OK: completely unknown type (documented gap)
	var/datum/widget/w = new some_type(1) // EXPECT: unverifiable_call
	new some_type(src)
	new some_type(new /datum/widget()) // EXPECT: unverifiable_call
	new some_type(my_machine.grow(1)) // EXPECT: unverifiable_call
	new some_type(CALL_GROW(my_machine)) // EXPECT: unverifiable_call
	return w

/datum/caller/proc/member_calls(obj/machine/m, obj/unrelated/u, obj/thing)
	m.grow(a = 1, b = 2)
	m.grow(1, 2) // EXPECT: positional_arg*2
	m?.grow(a = 1) // EXPECT: missing_params
	my_machine.grow(a = 1, b = 2)
	my_machine.linked.grow(b = 1, a = 2)
	my_machine.linked.grow(a = 1, b = 2, b = 3) // EXPECT: duplicate_binding
	src.my_machine.grow(a = 1) // EXPECT: missing_params
	u.grow(1) // OK: receiver type unrelated to every marked grow()
	thing.grow(a = 1, b = 2) // EXPECT: unverifiable_call
	untyped_thing.grow(a = 1, b = 2) // EXPECT: unverifiable_call
	var/list/things = list()
	things[1].grow(a = 1, b = 2) // EXPECT: unverifiable_call
	var/obj/machine/sub/s = locate() in things
	s.grow(a = 1, b = 2)
	s.grow(1, 2) // EXPECT: positional_arg*2
	for(var/obj/machine/fm in things)
		fm.grow(a = 1) // EXPECT: missing_params
	my_machine.other()
	new_calls()
	m.grow(
		a = 1,
		b = 2)
	m.grow( // EXPECT: positional_arg*2
		1,
		2)
	PARAM_LINT_SKIP(m.grow(1, 2))
	PARAM_LINT_SKIP(m.grow(a = 1, b = 2)) // EXPECT: unused_skip
	PARAM_LINT_SKIP(new /datum/widget()) // OK(unused_skip)
	PARAM_LINT_SKIP(new /datum/widget(new /datum/widget())) // EXPECT: missing_params
	PARAM_LINT_SKIP(new /datum/widget(1)) + new /datum/widget() // EXPECT: missing_params

/datum/caller/proc/ancestor_calls(datum/animal/a, datum/animal/dog/d)
	a.speak("woof") // EXPECT: unverifiable_call
	d.speak(words = "woof")
	d.speak("woof") // EXPECT: positional_arg

/// Markers that only appear in comments and strings must not mark the proc.
/datum/caller/proc/not_marked_calls(datum/defs/d)
	d.ignored_markers()
	d.ignored_markers(1)
	d.conflicting() // the later FALSE marker wins

/datum/caller/proc/global_scope_calls()
	global.global_marked(x = 1, y = 2)
	global.global_marked(1) // EXPECT: missing_params

/// avulto 0.1.x panics on `::proc()` (GlobalCall), so this body cannot be walked.
/datum/caller/proc/unparsable() // EXPECT: unparsable_proc
	::global_marked(x = 1, y = 2)

/datum/caller/proc/parsable() // OK(unparsable_proc)
	stack_trace("__TYPE__ inside a proc body must not break the walk")

#ifdef PARAM_LINT_FIXTURE_EXTRA
/datum/caller/proc/only_in_extra_pass()
	new /datum/widget(a = 1) // EXPECT(extra): missing_params
#endif

/datum/caller/proc/order_calls(datum/ordered/o, datum/ordered/strict/s, datum/ordered/loose/l, datum/ordered_base/base, datum/ordered_base/child/child)
	o.build(a = 1, b = 2, c = 3) // OK(param_order)
	o.build(1, b = 2, c = 3) // OK(param_order): positional prefix, then keywords in order
	o.build(a = 1, c = 3) // OK(param_order): skipping a parameter keeps the relative order
	o.build(1, 2) // OK(param_order) OK(missing_params): order-only procs do not require every parameter
	o.build(b = 2, a = 1) // EXPECT: param_order
	o.build(1, c = 3, b = 2) // EXPECT: param_order
	o.build(c = 3, b = 2, a = 1) // EXPECT: param_order
	o.build( // EXPECT: param_order
		a = 1,
		c = 3,
		b = 2)
	s.build(b = 2, a = 1) // EXPECT: param_order
	l.build(c = 3, a = 1) // OK(param_order): opted out with FALSE
	new /datum/widget(c = 3, b = 2, a = 1) // OK(param_order): widget is not SHOULD_KEEP_PARAM_ORDER
	child.run_it(a = 1, b = 2)
	child.run_it(b = 2, a = 1) // EXPECT: param_order
	base.run_it(a = 1, b = 2) // EXPECT: unverifiable_call
