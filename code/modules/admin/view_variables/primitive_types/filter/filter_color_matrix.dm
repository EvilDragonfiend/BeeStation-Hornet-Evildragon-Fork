/primitive/filter/color_matrix
	pseudo_type = "/filter/color_matrix"
	filter_type_string = "color"

	var/color
	var/space

/primitive/filter/color_matrix/locate_var_pointer(primitive/filter/color_matrix/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(space)
