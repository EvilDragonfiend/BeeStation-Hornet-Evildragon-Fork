#define LOCATE_FILTER_VAR_POINTER
/primitive/filter
	var/filter_type_string
	var/static/primitive/filter/alpha_mask/alpha_mask = new()
	var/static/primitive/filter/angular_blur/angular_blur = new()
	var/static/primitive/filter/bloom/bloom = new()
	var/static/primitive/filter/color_matrix/color_matrix = new()
	var/static/primitive/filter/displacement_map/displacement_map = new()
	var/static/primitive/filter/drop_shadow/drop_shadow = new()
	var/static/primitive/filter/gaussian_blur/gaussian_blur = new()
	var/static/primitive/filter/layering/layering = new()
	var/static/primitive/filter/motion_blur/motion_blur = new()
	var/static/primitive/filter/outline/outline = new()
	var/static/primitive/filter/radial_blur/radial_blur = new()
	var/static/primitive/filter/rays/rays = new()
	var/static/primitive/filter/ripple/ripple = new()
	var/static/primitive/filter/wave/wave = new()

/primitive/filter/locate_var_pointer(primitive/filter/p_thing, varname)
	if(varname == NAMEOF(src, type)) // type is /datum var already
		return ..()

	switch((*p_thing).type)
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

/primitive/filter/set_var(primitive/filter/p_thing, varname, val)
	if(varname == NAMEOF(src, type)) // type is readonly variable
		return
	..()
