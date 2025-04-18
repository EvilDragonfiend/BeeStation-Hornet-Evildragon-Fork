SUBSYSTEM_DEF(security_level)
	name = "Security Level"
	can_fire = FALSE // We will control when we fire in this subsystem
	init_order = INIT_ORDER_SECURITY_LEVEL
	/// Currently set security level
	var/datum/security_level/current_security_level
	/// A list of initialised security level datums.
	var/list/available_levels = list()

/datum/controller/subsystem/security_level/Initialize()
	for(var/iterating_security_level_type in subtypesof(/datum/security_level))
		var/datum/security_level/new_security_level = new iterating_security_level_type
		available_levels[new_security_level.name] = new_security_level
	current_security_level = available_levels[number_level_to_text(SEC_LEVEL_GREEN)]
	return SS_INIT_SUCCESS

/datum/controller/subsystem/security_level/fire(resumed)
	if(!current_security_level.looping_sound) // No sound? No play.
		can_fire = FALSE
		return
	sound_to_playing_players(current_security_level.looping_sound)


/**
 * Sets a new security level as our current level
 *
 * This is how everything should change the security level.
 *
 * Arguments:
 * * new_level - The new security level that will become our current level
 */
/datum/controller/subsystem/security_level/proc/set_level(new_level)
	new_level = istext(new_level) ? new_level : number_level_to_text(new_level)
	if(new_level == current_security_level.name) // If we are already at the desired level, do nothing
		return

	var/datum/security_level/selected_level = available_levels[new_level]

	if(!selected_level)
		CRASH("set_level was called with an invalid security level([new_level])")

	if(SSnightshift.can_fire && (selected_level.number_level >= SEC_LEVEL_RED || current_security_level.number_level >= SEC_LEVEL_RED))
		SSnightshift.next_fire = world.time + 7 SECONDS // Fire nightshift after the security level announcement is complete

	level_announce(selected_level, current_security_level.number_level) // We want to announce BEFORE updating to the new level

	SSsecurity_level.current_security_level = selected_level

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	var/datum/signal/status_signal = new(list("command" = "alert"))

	switch(SSsecurity_level.get_current_level_as_number())
		if(SEC_LEVEL_DELTA)
			status_signal.data["picture_state"] = "deltaalert"
		if(SEC_LEVEL_RED)
			status_signal.data["picture_state"] = "redalert"
		if(SEC_LEVEL_BLUE)
			status_signal.data["picture_state"] = "bluealert"
		if(SEC_LEVEL_GREEN)
			status_signal.data["picture_state"] = "greenalert"
	frequency.post_signal(src, status_signal)

	if(selected_level.looping_sound)
		wait = selected_level.looping_sound_interval
		can_fire = TRUE
	else
		can_fire = FALSE

	if(SSshuttle.emergency.mode == SHUTTLE_CALL || SSshuttle.emergency.mode == SHUTTLE_RECALL) // By god this is absolutely shit
		SSshuttle.emergency.alert_coeff_change(selected_level.shuttle_call_time_mod)

	SEND_SIGNAL(src, COMSIG_SECURITY_LEVEL_CHANGED, selected_level.number_level)
	SSblackbox.record_feedback("tally", "security_level_changes", 1, selected_level.name)

/**
 * Returns the current security level as a number
 */
/datum/controller/subsystem/security_level/proc/get_current_level_as_number()
	return ((!initialized || !current_security_level) ? SEC_LEVEL_GREEN : current_security_level.number_level) //Send the default security level in case the subsystem hasn't finished initializing yet

/**
 * Returns the current security level as text
 */
/datum/controller/subsystem/security_level/proc/get_current_level_as_text()
	return ((!initialized || !current_security_level) ? "green" : current_security_level.name)

/**
 * Converts a text security level to a number
 *
 * Arguments:
 * * level - The text security level to convert
 */
/datum/controller/subsystem/security_level/proc/text_level_to_number(text_level)
	var/datum/security_level/selected_level = available_levels[text_level]
	return selected_level?.number_level

/**
 * Converts a number security level to a text
 *
 * Arguments:
 * * level - The number security level to convert
 */
/datum/controller/subsystem/security_level/proc/number_level_to_text(number_level)
	for(var/iterating_level_text in available_levels)
		var/datum/security_level/iterating_security_level = available_levels[iterating_level_text]
		if(iterating_security_level.number_level == number_level)
			return iterating_security_level.name
