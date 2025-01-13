/datum/mirage_type/callee
	pseudo_type = "/callee"
	var/caller
	var/category
	var/file
	var/line
	// snip

/datum/mirage_type/callee/locate_var_pointer(datum/mirage_type/callee/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(caller)
		LOCATE_VAR_POINTER(category)
		LOCATE_VAR_POINTER(file)
		LOCATE_VAR_POINTER(line)

/datum/mirage_type/callee/set_var(p_thing, varname, val) // read-only
	return
