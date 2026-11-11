// Indirect uses of marked procs.

/obj/machine/proc/references()
	var/datum/callback/cb = CALLBACK(src, PROC_REF(grow), 1, 2) // EXPECT: proc_reference
	cb = CALLBACK(src, PROC_REF(other)) // OK(proc_reference)
	cb = CALLBACK(src, TYPE_PROC_REF(/obj/machine, grow)) // EXPECT: proc_reference
	cb = CALLBACK(src, TYPE_PROC_REF(/obj/unrelated, grow))
	cb = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(global_marked)) // EXPECT: proc_reference
	INVOKE_ASYNC(src, PROC_REF(grow), 1, 2) // EXPECT: proc_reference
	INVOKE_ASYNC(src, "grow", 1, 2) // EXPECT: dynamic_call
	call(src, "grow")(a = 1, b = 2) // EXPECT: dynamic_call
	call(src, "other")() // OK(dynamic_call)
	var/obj/unrelated/u = locate()
	call(u, "grow")(1) // OK: unrelated receiver
	var/p = /obj/machine/proc/grow // EXPECT: proc_reference
	p = /obj/machine::grow() // EXPECT: proc_reference
	p = /obj/unrelated/proc/grow
	cb = CALLBACK(src, PARAM_LINT_SKIP(PROC_REF(grow)))
	return list(cb, p)
