GLOBAL_DATUM_INIT(mirage_filter, /datum/mirage_type/filter, new)
/datum/mirage_type/filter
	var/filter_type_string
	var/static/datum/mirage_type/filter/alpha_mask/alpha_mask = new()
	var/static/datum/mirage_type/filter/angular_blur/angular_blur = new()
	var/static/datum/mirage_type/filter/bloom/bloom = new()
	var/static/datum/mirage_type/filter/color_matrix/color_matrix = new()
	var/static/datum/mirage_type/filter/displacement_map/displacement_map = new()
	var/static/datum/mirage_type/filter/drop_shadow/drop_shadow = new()
	var/static/datum/mirage_type/filter/gaussian_blur/gaussian_blur = new()
	var/static/datum/mirage_type/filter/layering/layering = new()
	var/static/datum/mirage_type/filter/motion_blur/motion_blur = new()
	var/static/datum/mirage_type/filter/outline/outline = new()
	var/static/datum/mirage_type/filter/radial_blur/radial_blur = new()
	var/static/datum/mirage_type/filter/rays/rays = new()
	var/static/datum/mirage_type/filter/ripple/ripple = new()
	var/static/datum/mirage_type/filter/wave/wave = new()

/datum/mirage_type/filter/locate_var_pointer(datum/mirage_type/filter/p_thing, varname)
	if(varname == NAMEOF(src, type)) // type is /datum var already
		return ..()

	var/datum/temp = *p_thing
	switch(temp.type)
		LOCATE_FILTER_VAR_POINTER(alpha_mask)
		LOCATE_FILTER_VAR_POINTER(angular_blur)
		LOCATE_FILTER_VAR_POINTER(bloom)
		LOCATE_FILTER_VAR_POINTER(color_matrix)
		LOCATE_FILTER_VAR_POINTER(displacement_map)
		LOCATE_FILTER_VAR_POINTER(drop_shadow)
		LOCATE_FILTER_VAR_POINTER(gaussian_blur)
		LOCATE_FILTER_VAR_POINTER(layering)
		LOCATE_FILTER_VAR_POINTER(motion_blur)
		LOCATE_FILTER_VAR_POINTER(outline)
		LOCATE_FILTER_VAR_POINTER(radial_blur)
		LOCATE_FILTER_VAR_POINTER(rays)
		LOCATE_FILTER_VAR_POINTER(ripple)
		LOCATE_FILTER_VAR_POINTER(wave)

/datum/mirage_type/filter/set_var(datum/mirage_type/filter/p_thing, varname, val)
	if(varname == NAMEOF(src, type)) // type is readonly variable
		return
	..()
