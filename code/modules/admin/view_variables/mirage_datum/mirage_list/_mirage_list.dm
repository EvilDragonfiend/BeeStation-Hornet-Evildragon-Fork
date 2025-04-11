/datum/mirage_list
	var/list_name
	var/bound_typepath
	var/secure_level
	var/macro_support_type

/datum/mirage_list/proc/check_list_ownership(varname, datum_typepath, depth)
	if(ispath(datum_typepath, bound_typepath))
		return TRUE
	return null
/datum/mirage_list/proc/debug_variable_list(list/target_list)
	return
/*
	var/flag = (special_list_secure_level && (special_list_secure_level <= VV_LIST_READ_ONLY)) ? VV_READ_ONLY : null
	var/list/items = list()
	for (var/i in 1 to length(list_value))
		var/key = list_value[i]
		var/val
		if (IS_NORMAL_LIST(list_value) && !isnum(key))
			val = list_value[key]
		if (isnull(val)) // we still want to display non-null false values, such as 0 or ""
			val = key
			key = i

		items += debug_variable(key, val, level + 1, sanitize = sanitize, display_flags = flag)

	return "[a_open][list_type] ([length(list_value)])[a_close]<ul>[items.Join()]</ul>"
*/
/datum/mirage_list/normal
	list_name = null
	bound_typepath = null
