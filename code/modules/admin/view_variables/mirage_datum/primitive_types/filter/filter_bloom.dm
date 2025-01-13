/datum/mirage_type/filter/bloom
	pseudo_type = "/filter/bloom"
	filter_type_string = "bloom"

	var/threshold
	var/size
	var/offset
	var/alpha

/datum/mirage_type/filter/bloom/locate_var_pointer(datum/mirage_type/filter/bloom/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(threshold)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(offset)
		LOCATE_VAR_POINTER(alpha)
