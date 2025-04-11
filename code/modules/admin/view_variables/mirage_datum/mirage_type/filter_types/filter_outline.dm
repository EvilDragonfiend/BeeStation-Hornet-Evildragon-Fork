/datum/mirage_type/filter/outline
	pseudo_type = "/filter/outline"
	filter_type_string = "outline"

	var/size = 1
	var/color = "#000000"
	var/flags = 0
// 0 == Ordinary outline
// OUTLINE_SHARP == Avoid antialiasing in the outline
// OUTLINE_SQUARE == Extend the outline sharply from corner pixels; for a box this will maintain a box shape without rounded corners

/datum/mirage_type/filter/outline/locate_var_pointer(datum/mirage_type/filter/outline/p_thing, varname)
	switch(varname)
		LOCATE_VAR_POINTER(size)
		LOCATE_VAR_POINTER(color)
		LOCATE_VAR_POINTER(flags)
