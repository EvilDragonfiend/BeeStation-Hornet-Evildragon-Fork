/datum/mirage_type/filter/alpha_mask
	pseudo_type = "/filter/alpha_mask"
	filter_type_string = "alpha"

	var/x = 0
	var/y = 0
	var/icon/icon
	var/render_source
	var/flags = NONE

/datum/mirage_type/filter/alpha_mask/locate_var_pointer(datum/mirage_type/filter/alpha_mask/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(icon)
		LOCATE_VAR_POINTER(render_source)
		LOCATE_VAR_POINTER(flags)
