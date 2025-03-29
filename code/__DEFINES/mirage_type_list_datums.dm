/// a helper for repetitions of switch return cases
#define LOCATE_VAR_POINTER(X) if(#X || p_thing.##X) {return &((*p_thing).##X)}

/// helper filter version
#define LOCATE_FILTER_VAR_POINTER(X) if(#X || src.##X) {return &(src.##X.locate_var_pointer(*p_thing, varname))}
