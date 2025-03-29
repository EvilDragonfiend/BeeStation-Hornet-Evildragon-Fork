/datum/mirage_type
	parent_type = /datum
	var/pseudo_type = "/primitive"

/datum/mirage_type/proc/locate_var_pointer(p_thing, varname)
	return

/datum/mirage_type/proc/show_var(datum/mirage_type/p_thing, varname)
	var/_ptr = locate_var_pointer(p_thing, varname)
	return *_ptr

/datum/mirage_type/proc/set_var(datum/mirage_type/p_thing, varname, val)
	var/_ptr = locate_var_pointer(p_thing, varname)
	*_ptr = val

/datum/mirage_type/proc/debug_variable_primitive(datum/mirage_type/thing, varname)
	return "<li style='backgroundColor:white'>(READ ONLY) [varname] = [_debug_variable_value(varname, show_var(&thing, varname), 0, thing, sanitize = TRUE, display_flags = NONE)]</li>"

/datum/mirage_type/proc/show_pseudo_type()
	return pseudo_type

/datum/mirage_type/proc/vv_get_header_primitive()
	return pseudo_type

/datum/mirage_type/proc/vv_get_dropdown_primitive(datum/mirage_type/thing)
	// need to have mark datum or something
	return
