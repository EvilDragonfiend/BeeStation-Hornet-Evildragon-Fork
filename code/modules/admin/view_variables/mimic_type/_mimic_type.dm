/datum/mimic_type

/datum/mimic_type/proc/get_vv_list__mimic_type(thing)
	return

/datum/mimic_type/proc/get_dropdown__mimic_type(thing)
	return

/datum/mimic_type/proc/vv_get_header__mimic_type(thing)
	return

/datum/mimic_type/proc/get_virtual_var_list__mimic_type(thing)
	return

/datum/mimic_type/proc/debug_variable__mimic_type(varname, thing)
	return

/datum/mimic_type/proc/locate_variable__mimic_type(thing)
	return

////////////////////////
/datum/mimic_type/appearance
	var/x
	var/icon
	var/icon_state

/datum/mimic_type/appearance/get_dropdown__mimic_type(thing)
	. = list("NO-OPTION")
	return .

/datum/mimic_type/appearance/vv_get_header__mimic_type(var/datum/mimic_type/appearance/thing)
	. = list()
	var/icon_name = "<b>[thing.icon || "null"]</b><br/>"
	. += replacetext(icon_name, "icons/obj", "") // shortens the name. We know the path already.
	if(thing.icon)
		. += thing.icon_state ? "\"[thing.icon_state]\"" : "(icon_state = null)"

/image/vv_get_header()
	var/static/datum/mimic_type/appearance/app_mirror = new()
	return app_mirror.vv_get_header__mimic_type(src)

/datum/mimic_type/appearance/get_virtual_var_list__mimic_type(var/datum/mimic_type/appearance/thing)
	return list("x", "icon", "icon_state")

/datum/mimic_type/appearance/debug_variable__mimic_type(var_name, var/datum/mimic_type/appearance/thing)
	var/value
	try
		value = locate_appearance_variable(var_name, thing)
	catch
		return "<li style='backgroundColor:white'>(READ ONLY) <font color='blue'>[var_name] = (untrackable)</font></li>"
	if(value == "_switch_result_variable_not_found")
		return "<li style='backgroundColor:white'>(READ ONLY) [var_name] <font color='blue'>(Undefined var name in switch)</font></li>"
	return "<li style='backgroundColor:white'>(READ ONLY) [var_name] = [_debug_variable_value(var_name, value, 0, thing, sanitize = TRUE, display_flags = NONE)]</li>"
