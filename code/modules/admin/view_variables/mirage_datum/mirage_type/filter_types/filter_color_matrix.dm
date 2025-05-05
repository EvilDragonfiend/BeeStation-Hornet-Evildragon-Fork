/datum/mirage_type/filter/color_matrix
	pseudo_type = "/filter/color_matrix"
	filter_type_string = "color"

	var/color
	var/space

/datum/mirage_type/filter/color_matrix/locate_var_pointer(datum/mirage_type/filter/color_matrix/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(space)
