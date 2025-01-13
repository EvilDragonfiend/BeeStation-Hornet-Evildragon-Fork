/datum/mirage_type/appearance
	pseudo_type = "/appearance"
	var/alpha
	var/appearance_flags
	var/color
	var/icon
	var/icon_state
	// snip. should sort out everything

/datum/mirage_type/appearance/locate_var_pointer(datum/mirage_type/appearance/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(alpha)
		LOCATE_VAR_POINTER(appearance_flags)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(icon)
		LOCATE_VAR_POINTER(icon_state)

/datum/mirage_type/appearance/set_var(p_thing, varname, val) // read-only
	return

/datum/mirage_type/appearance/vv_get_dropdown_primitive(datum/mirage_type/appearance/thing)
	return
