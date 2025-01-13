/datum/mirage_type/filter/motion_blur
	pseudo_type = "/filter/motion_blur"
	filter_type_string = "motion_blur"

	var/x = 0
	var/y = 0

/datum/mirage_type/filter/motion_blur/locate_var_pointer(datum/mirage_type/filter/motion_blur/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
