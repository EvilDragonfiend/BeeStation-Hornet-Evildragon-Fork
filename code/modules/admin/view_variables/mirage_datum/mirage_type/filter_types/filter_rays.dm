/datum/mirage_type/filter/rays
	pseudo_type = "/filter/rays"
	filter_type_string = "rays"

	var/x
	var/y
	var/size
	var/color = "#000000"
	var/offset = 0
	var/density = 10
	var/threshold = 0.5
	var/factor = 0
	var/flags = FILTER_OVERLAY | FILTER_UNDERLAY

// 0
// The rays are drawn alone, erasing the existing image (useful for some effects).
// FILTER_OVERLAY
// The rays are overlaid on top of the existing image.
// FILTER_UNDERLAY
// The rays are drawn underneath the existing image.
// FILTER_OVERLAY | FILTER_UNDERLAY
// Default. For plane masters, this will use the FILTER_OVERLAY behavior and draw the rays over the plane, and for all other images it will default to FILTER_UNDERLAY to draw the rays beneath them.

/datum/mirage_type/filter/rays/locate_var_pointer(datum/mirage_type/filter/rays/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(offset)
		LOCATE_VAR_POINTER(density)
		LOCATE_VAR_POINTER(threshold)
		LOCATE_VAR_POINTER(factor)
		LOCATE_VAR_POINTER(flags)
