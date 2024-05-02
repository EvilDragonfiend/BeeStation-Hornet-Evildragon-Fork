/datum/PreInit
	var/list/pre_arguments

/datum/PreInit/New(list/arguments)
	pre_arguments = arguments

/obj/machinery/PreInitialize(list/mything)
	. = ..()
	for(var/each in mything)
		message_admins("I have this: [each]")
