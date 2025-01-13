/datum/mirage_list/filters
	list_name = "filters"
	bound_typepath = /atom

/datum/mirage_list/filters/debug_variable_list(list/target_list)
    if(!length(target_list))
        return "/special_list:filters (0)"
    
    var/list/items = list()
	for(var/each in target_list)
        items += primitive_filters.debug_variable_primitive(sdfad)

    return "/special_list:filters (0)
