/datum/wires/radio
	holder_type = /obj/item/radio
	proper_name = "Radio"

/datum/wires/radio/New(atom/holder)
	wires = list(
		WIRE_RESET,
		WIRE_SIGNAL,
		WIRE_RX, WIRE_TX,
		WIRE_ANONYMOUS
	)
	add_duds(2)
	..()


/datum/wires/radio/get_status(mob/user)
	if(!..())
		return list()
	var/obj/item/radio/R = holder
	var/list/status = list()
	status += "The green light is [R.listening ? "on" : "off"]."
	status += "The second green light is [R.broadcasting ? "on" : "off"]."
	status += "The third green light is [R.anonymize ? "on" : "off"]."
	status += "The red light is [R.freerange ? "blinking" : "off"]."
	return status

/datum/wires/radio/interactable(mob/user)
	var/obj/item/radio/R = holder
	return R.unscrewed

/datum/wires/radio/on_pulse(wire)
	var/obj/item/radio/R = holder
	switch(wire)
		if(WIRE_SIGNAL)
			R.listening = !R.listening
			R.broadcasting = R.listening
		if(WIRE_RX)
			R.listening = !R.listening
		if(WIRE_TX)
			R.broadcasting = !R.broadcasting
		if(WIRE_ANONYMOUS)
			R.anonymize = !R.anonymize
		if(WIRE_RESET)
			R.listening = initial(R.listening)
			R.broadcasting = initial(R.listening)
			R.anonymize = initial(R.anonymize)
			R.frequency = initial(R.frequency)
			R.freerange = initial(R.freerange)

/datum/wires/radio/on_cut(wire, mend)
	var/obj/item/radio/R = holder
	switch(wire)
		if(WIRE_RX)
			if(!mend)
				R.listening = FALSE
		if(WIRE_TX)
			if(!mend)
				R.broadcasting = FALSE
		if(WIRE_ANONYMOUS)
			if(!mend)
				R.anonymize = FALSE
