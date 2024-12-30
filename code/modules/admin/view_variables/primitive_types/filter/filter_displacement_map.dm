/primitive/filter/displacement_map
	pseudo_type = "/filter/displacement_map"
	filter_type_string = "displace"

	var/x
	var/y
	var/size
	var/icon/icon
	var/render_source
	var/flags

/primitive/filter/displacement_map/locate_var_pointer(primitive/filter/displacement_map/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(icon)
		LOCATE_VAR_POINTER(render_source)
		LOCATE_VAR_POINTER(flags)
