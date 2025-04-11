/datum/mirage_type/filter/radial_blur
	pseudo_type = "/filter/radial_blur"
	filter_type_string = "radial_blur"

	var/x
	var/y
	var/size = 0.01

/datum/mirage_type/filter/radial_blur/locate_var_pointer(datum/mirage_type/filter/radial_blur/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
