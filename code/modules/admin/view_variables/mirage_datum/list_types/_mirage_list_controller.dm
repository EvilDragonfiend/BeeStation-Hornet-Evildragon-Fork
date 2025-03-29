/datum/vv_list_master_helper
	var/static/list/associated_list_by_typepath = list(
		"filters" = new /datum/mirage_list/filters()
	)
	var/static/datum/mirage_list/normal/normal_list = new()

/datum/vv_list_master_helper/proc/debug_variable_list(list/target_list, varname, datum/owner, depth)
	var/datum/mirage_list/list_deliveryman = associated_list_by_typepath[varname]
	if(isnull(list_deliveryman) || isnull(list_deliveryman.check_list_ownership(varname, owner.type)))
		return normal_list.debug_variable_list(target_list, #$@#$) // NEED TO CHECK
	return list_deliveryman.debug_variable_list(#$%#$%$#)
