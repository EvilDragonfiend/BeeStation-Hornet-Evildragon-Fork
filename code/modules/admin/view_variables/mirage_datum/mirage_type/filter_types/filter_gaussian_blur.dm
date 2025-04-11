/datum/mirage_type/filter/gaussian_blur
	pseudo_type = "/filter/gaussian_blur"
	filter_type_string = "blur"

	var/size = 1

/datum/mirage_type/filter/gaussian_blur/locate_var_pointer(datum/mirage_type/filter/gaussian_blur/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(size)
