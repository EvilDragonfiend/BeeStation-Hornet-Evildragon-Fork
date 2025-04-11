/datum/mirage_type/filter/wave
	pseudo_type = "/filter/wave"
	filter_type_string = "wave"

	var/x
	var/y
	var/size = 1
	var/offset
	var/flags

/datum/mirage_type/filter/wave/locate_var_pointer(datum/mirage_type/filter/wave/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(offset)
		LOCATE_VAR_POINTER(flags)
