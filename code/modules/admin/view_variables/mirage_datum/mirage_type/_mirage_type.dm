GLOBAL_DATUM_INIT(mirage_type, /datum/mirage_type, new)

/datum/mirage_type
	var/pseudo_type = "/primitive"

	var/static/datum/mirage_type/appearance/appearance = new

// internal use only
/datum/mirage_type/proc/locate_var_pointer(p_thing, varname)
	return

/datum/mirage_type/proc/show_var(datum/mirage_type/p_thing, varname)
	var/_ptr = locate_var_pointer(p_thing, varname)
	return *_ptr

/datum/mirage_type/proc/set_var(datum/mirage_type/p_thing, varname, val)
	var/_ptr = locate_var_pointer(p_thing, varname)
	*_ptr = val

/datum/mirage_type/proc/show_pseudo_type()
	return pseudo_type

/datum/mirage_type/proc/show_vv_summary_name(datum/mirage_type/thing)
	return pseudo_type



/datum/mirage_type/proc/vv_get_header_primitive(datum/mirage_type/thing)
	return pseudo_type

/datum/mirage_type/proc/vv_get_dropdown_primitive(datum/mirage_type/thing)
	// need to have mark datum or something
	return

/datum/mirage_type/proc/vv_get_var_primitive(datum/mirage_type/appearance/thing, varname)
	var/result = locate_var_pointer(thing, varname)
	if(isnull(result))
		return
	return debug_variable(varname, *result, 0, *thing)
