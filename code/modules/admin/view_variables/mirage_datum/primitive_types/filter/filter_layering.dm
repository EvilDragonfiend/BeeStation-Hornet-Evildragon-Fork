/datum/mirage_type/filter/layering
	pseudo_type = "/filter/layering"
	filter_type_string = "layer"

	var/x = 0
	var/y = 0
	var/icon/icon
	var/render_source
	var/flags = FILTER_OVERLAY // ?
	var/color/color
	var/transform/transform
	var/blend_mode

/datum/mirage_type/filter/layering/locate_var_pointer(datum/mirage_type/filter/layering/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(icon)
		LOCATE_VAR_POINTER(render_source)
		LOCATE_VAR_POINTER(flags)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(transform)
		LOCATE_VAR_POINTER(blend_mode)
