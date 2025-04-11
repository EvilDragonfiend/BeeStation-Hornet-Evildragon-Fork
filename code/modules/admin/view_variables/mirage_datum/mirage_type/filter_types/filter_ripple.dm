/datum/mirage_type/filter/ripple
	pseudo_type = "/filter/ripple"
	filter_type_string = "ripple"

	var/x = 0
	var/y = 0
	var/size = 1
	var/repeat = 2
	var/radius = 0
	var/falloff = 1
	var/flags = NONE // WAVE_BOUNDED

/datum/mirage_type/filter/ripple/locate_var_pointer(datum/mirage_type/filter/ripple/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(repeat)
		LOCATE_VAR_POINTER(radius)
		LOCATE_VAR_POINTER(falloff)
		LOCATE_VAR_POINTER(flags)
