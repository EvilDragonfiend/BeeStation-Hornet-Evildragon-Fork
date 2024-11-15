/datum/mock/appearance
    var/alpha
    var/appearance_flags
    var/blend_mode
    var/color
    var/desc
    var/gender
    var/icon
    var/icon_state
    var/invisibility
    var/infra_luminosity
    var/list/filters
    var/layer
    var/luminosity
    var/maptext
    var/maptext_width
    var/maptext_height
    var/maptext_x
    var/maptext_y
    var/mouse_over_pointer
    var/mouse_drag_pointer
    var/mouse_drop_pointer
    var/mouse_drop_zone
    var/mouse_opacity
    var/name
    var/opacity
    var/overlays
    var/apearance
    var/override
    var/pixel_x
    var/pixel_y
    var/pixel_w
    var/pixel_z
    var/plane
    var/render_source
    var/render_target
    var/suffix
    var/text
    var/transform
    var/underlays
    var/animate_movement
    var/dir
    var/glide_size
    var/pixel_step_size
    var/contents
    var/loc
    var/vis_contents
    var/vis_flags
    var/density
    var/screen_loc
    var/sorted_verbs

/datum/mimic_type/appearance/proc/get_vv_vars()
    return src.vars

/datum/mock_type/appearance/get_dropdown__mock_type(thing)
	. = list("NO-OPTION")
	return .

/datum/mock_type/appearance/vv_get_header__mock_type(var/datum/mock_type/appearance/thing)
	. = list()
	var/icon_name = "<b>[thing.icon || "null"]</b><br/>"
	. += replacetext(icon_name, "icons/obj", "") // shortens the name. We know the path already.
	if(thing.icon)
		. += thing.icon_state ? "\"[thing.icon_state]\"" : "(icon_state = null)"

/image/vv_get_header()
	var/static/datum/mock_type/appearance/app_mirror = new()
	return app_mirror.vv_get_header__mock_type(src)

/datum/mock_type/appearance/get_virtual_var_list__mock_type(var/datum/mock_type/appearance/thing)
	return list("x", "icon", "icon_state")

/datum/mock_type/appearance/debug_variable__mock_type(var_name, var/datum/mock_type/appearance/thing)
	var/value = debug_variable()
    return "<li style='backgroundColor:white'>(READ ONLY) <font color='blue'>[var_name] = (untrackable)</font></li>"

	try
		value = locate_appearance_variable(var_name, thing)
	catch
		
	if(value == "_switch_result_variable_not_found")
		return "<li style='backgroundColor:white'>(READ ONLY) [var_name] <font color='blue'>(Undefined var name in switch)</font></li>"
	return "<li style='backgroundColor:white'>(READ ONLY) [var_name] = [_debug_variable_value(var_name, value, 0, thing, sanitize = TRUE, display_flags = NONE)]</li>"
