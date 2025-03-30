/datum/mirage_type/appearance
	pseudo_type = "/appearance"
	var/alpha
	var/appearance_flags
	var/blend_mode
	var/color
	var/icon_file_name
	var/icon
	var/icon_state
	var/invisibility
	var/infra_luminosity
	var/filters
	var/layer
	var/name
	var/overlays
	var/override
	var/pixel_x
	var/pixel_y
	var/pixel_w
	var/plane
	var/render_source
	var/render_target
	var/suffix
	var/text
	var/transform
	var/underlays
	var/dir
	var/glide_size
	var/pixel_step_size

/datum/mirage_type/appearance/locate_var_pointer(datum/mirage_type/appearance/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(caller)
		LOCATE_VAR_POINTER(appearance_flags)
		LOCATE_VAR_POINTER(blend_mode)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(icon_file_name)
		LOCATE_VAR_POINTER(icon)
		LOCATE_VAR_POINTER(icon_state)
		LOCATE_VAR_POINTER(invisibility)
		LOCATE_VAR_POINTER(infra_luminosity)
		LOCATE_VAR_POINTER(filters)
		LOCATE_VAR_POINTER(name)
		LOCATE_VAR_POINTER(overlays)
		LOCATE_VAR_POINTER(override)
		LOCATE_VAR_POINTER(pixel_x)
		LOCATE_VAR_POINTER(pixel_y)
		LOCATE_VAR_POINTER(pixel_w)
		LOCATE_VAR_POINTER(plane)
		LOCATE_VAR_POINTER(render_source)
		LOCATE_VAR_POINTER(render_target)
		LOCATE_VAR_POINTER(suffix)
		LOCATE_VAR_POINTER(text)
		LOCATE_VAR_POINTER(transform)
		LOCATE_VAR_POINTER(underlays)
		LOCATE_VAR_POINTER(dir)
		LOCATE_VAR_POINTER(glide_size)
		LOCATE_VAR_POINTER(pixel_step_size)

/datum/mirage_type/appearance/set_var(p_thing, varname, val)
	return


/datum/mirage_type/appearance/vv_get_header_primitive(datum/mirage_type/appearance/thing)
	. = list()
	var/icon_name = "<b>[thing.icon || "null"]</b><br/>"
	. += replacetext(icon_name, "icons/obj", "") // shortens the name. We know the path already.
	if(thing.icon)
		. += thing.icon_state ? "\"[thing.icon_state]\"" : "(icon_state = null)"

/image/vv_get_header() // it should redirect to global proc version because /appearance can't call a proc, unless we want dupe code here
	return GLOB.mirage_type.appearance.vv_get_header_primitive(src)

/datum/mirage_type/appearance/show_vv_summary_name(datum/mirage_type/appearance/thing)
	var/icon_file_name = thing.icon ? splittext("[thing.icon]", "/") : "null"
	if(islist(icon_file_name))
		icon_file_name = length(icon_file_name) ? icon_file_name[length(icon_file_name)] : "null"
	if(thing.icon_state)
		return "[icon_file_name]:[thing.icon_state]"
	else
		return "[icon_file_name]"

/datum/mirage_type/appearance/vv_get_dropdown_primitive(datum/mirage_type/appearance/thing)
	. = list()
	VV_DROPDOWN_OPTION_APPEARANCE(thing, "", "---")
	VV_DROPDOWN_OPTION_APPEARANCE(thing, VV_HK_EXPOSE, "Show VV To Player")
	return .
