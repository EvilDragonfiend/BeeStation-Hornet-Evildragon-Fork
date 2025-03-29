/datum/mirage_type/vector
	pseudo_type = "/vector"
	var/x
	var/y
	var/z

/datum/mirage_type/vector/locate_var_pointer(datum/mirage_type/vector/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(z)
