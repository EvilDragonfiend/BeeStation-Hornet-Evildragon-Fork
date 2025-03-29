/datum/mirage_type/filter/angular_blur
	pseudo_type = "/filter/angular_blur"
	filter_type_string = "angular_blur"

	var/x
	var/y
	var/size

/datum/mirage_type/filter/angular_blur/locate_var_pointer(datum/mirage_type/filter/angular_blur/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
