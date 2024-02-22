/* client rotate?
 * This is kinda mix with mob thing, so it's sorted in this place instead.
 */
/datum/keybinding/mob/rotate_clockwise
	keys = list("Numpad9")
	name = "rotate_clockwise"
	full_name = "Rotate clockwise"
	description = ""
	keybind_signal = COMSIG_KB_CLIENT_ROTATE_CLOCKWISE_DOWN
	any_modifier = TRUE

/datum/keybinding/mob/rotate_clockwise/down(client/user)
	to_chat(user, "Key down: clockwise")
	. = ..()
	if(.)
		return
	if(!user.mob || isnewplayer(user.mob)) return
	user.rotate_clockwise()
	to_chat(user, "<span class=''>You turn to clockwise.</span>")
	return TRUE

/datum/keybinding/mob/rotate_anticlockwise
	keys = list("Numpad7")
	name = "rotate_anticlockwise"
	full_name = "Rotate anticlockwise"
	description = ""
	keybind_signal = COMSIG_KB_CLIENT_ROTATE_ANTICLOCKWISE_DOWN
	any_modifier = TRUE

/datum/keybinding/mob/rotate_anticlockwise/down(client/user)
	. = ..()
	if(.)
		return
	if(!user.mob || isnewplayer(user.mob)) return
	user.rotate_anticlockwise()
	to_chat(user, "<span class=''>You turn to anticlockwise.</span>")
	return TRUE
