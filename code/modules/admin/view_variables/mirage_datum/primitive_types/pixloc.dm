/datum/mirage_type/pixloc
	pseudo_type = "/pixloc"
	var/x
	var/y
	var/z

/datum/mirage_type/pixloc/locate_var_pointer(datum/mirage_type/pixloc/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(x)
		LOCATE_VAR_POINTER(y)
		LOCATE_VAR_POINTER(z)
