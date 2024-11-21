/proc/identify_type(datum/thing)
    if(isdatum(thing))

    if(istext(thing))

    if(isnum(thing))

	if(isnull(value))
		return "<span class='value'>null</span>"

	if(iscolortext(value))
		return "<span class='value'>\"[value]\" <span class='colorbox' style='background-color:[value]'>_________</span></span>"

	if(istext(value))
		return "<span class='value'>\"[VV_HTML_ENCODE(value)]\"</span>"

	if(isicon(value))
		#ifdef VARSICON
		var/icon/icon_value = icon(value)
		var/rnd = rand(1,10000)
		var/rname = "tmp[REF(icon_value)][rnd].png"
		usr << browse_rsc(icon_value, rname)
		return "(<span class='value'>[value]</span>) <img class=icon src=\"[rname]\">"
		#else
		return "/icon (<span class='value'>[value]</span>)"
		#endif

	if(isappearance(value)) // Reminder: Do not replace this into /image/debug_variable_value() proc. /appearance can't do that.
		return "<a href='?_src_=vars;[HrefToken()];Vars=[REF(value)]'>/appearance (<span class='value'>[get_appearance_vv_summary_name(value)]</span>) [REF(value)]</a>"

	if(isimage(value))
		var/image/image = value
		return "<a href='?_src_=vars;[HrefToken()];Vars=[REF(value)]'>[image.type] (<span class='value'>[get_appearance_vv_summary_name(image)]</span>) [REF(value)]</a>"

	if(isfilter(value))
		var/datum/filter_value = value
		return "/filter (<span class='value'>[filter_value.type] [REF(filter_value)]</span>)"

	if(isfile(value))
		return "<span class='value'>'[value]'</span>"

	if(isdatum(value))
		var/datum/datum_value = value
		return datum_value.debug_variable_value(name, level, owner, sanitize, display_flags)


'test.dme'

isarea
isfile
isicon
isnum
islist
isloc
ismob
ismovable
isnum
isnull
isnum
isobj
ispath
ispointer
issaved
istext
isturf
istype


#define VV_TYPE_DATUM "/datum"
#define VV_TYPE_ATOM "/atom"
#define VV_TYPE_TURF "/turf"
#define VV_TYPE_MOVABLE "/atom/movable"

/proc/identify_type(datum/thing)
	if(isnull(thing))
		return null
	
	
	if(isdatum(thing))
		//if(isclient )
		if(isatom(thing))
			if(isarea(thing))
			if(isturf())
			if
		

	
    if(istext(thing))

    if(isnum(thing))

	if(isnull(value))
		return "<span class='value'>null</span>"

	if(iscolortext(value))
		return "<span class='value'>\"[value]\" <span class='colorbox' style='background-color:[value]'>_________</span></span>"

	if(istext(value))
		return "<span class='value'>\"[VV_HTML_ENCODE(value)]\"</span>"

	if(isicon(value))
		#ifdef VARSICON
		var/icon/icon_value = icon(value)
		var/rnd = rand(1,10000)
		var/rname = "tmp[REF(icon_value)][rnd].png"
		usr << browse_rsc(icon_value, rname)
		return "(<span class='value'>[value]</span>) <img class=icon src=\"[rname]\">"
		#else
		return "/icon (<span class='value'>[value]</span>)"
		#endif

	if(isappearance(value)) // Reminder: Do not replace this into /image/debug_variable_value() proc. /appearance can't do that.
		return "<a href='?_src_=vars;[HrefToken()];Vars=[REF(value)]'>/appearance (<span class='value'>[get_appearance_vv_summary_name(value)]</span>) [REF(value)]</a>"

	if(isimage(value))
		var/image/image = value
		return "<a href='?_src_=vars;[HrefToken()];Vars=[REF(value)]'>[image.type] (<span class='value'>[get_appearance_vv_summary_name(image)]</span>) [REF(value)]</a>"

	if(isfilter(value))
		var/datum/filter_value = value
		return "/filter (<span class='value'>[filter_value.type] [REF(filter_value)]</span>)"

	if(isfile(value))
		return "<span class='value'>'[value]'</span>"

	if(isdatum(value))
		var/datum/datum_value = value
		return datum_value.debug_variable_value(name, level, owner, sanitize, display_flags)
