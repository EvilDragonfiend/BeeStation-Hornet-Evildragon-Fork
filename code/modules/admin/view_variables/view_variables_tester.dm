// a global datum that simply helps to investigate if 'view variables' window works well.
GLOBAL_DATUM_INIT(vv_tester, /datum/view_variables_tester, new)

/datum/view_variables_tester
	var/datum/datum = new
	var/atom/atom = new
	var/atom/movable/movable = new
	var/obj/obj = new
	var/mob/mob = new
	var/turf/turf
	var/area/area

	var/image/image
	var/mutable_appearance/mutable_appearance
	var/icon/_icon
	var/generator/generator
	var/particles/particles
	var/matrix/matrix

	var/sound/sound

	var/regex/regex
	var/database/database
	var/database/query/query
	var/exception/exception

	//var/dm_filter/dm_filter // this exists, but I think it's meaningless to check

	var/world/wworld
	var/client/client
	var/savefile/savefile
	var/list/list
	var/list/filter

	var/static/list/true_vars
	var/static/__________________ // separator

#if DM_VERSION > 515
	var/callee/callee
	var/pixloc/pixloc
	var/vector/vector
#endif

/datum/view_variables_tester/New()
	setupt_true_vars()
	turf = locate(1,1,1)
	filter = filter(type="outline", size=1, color=rgb(255,0,0))

#if DM_VERSION > 515
	// callee
	pixloc = pixloc(3, 4, 1)
	vector = vector(3, 4, 5)
	GLOB.refid_pixloc = TYPEID(pixloc)
	GLOB.refid_vector = TYPEID(vector)
#endif


/datum/view_variables_tester/proc/setupt_true_vars()
	// need to do this manually because sorting is miserable
	if(isnull(true_vars))
		true_vars = list(
			NAMEOF_SRC(datum),
			NAMEOF_SRC(atom),
			NAMEOF_SRC(movable),
			NAMEOF_SRC(obj),
			NAMEOF_SRC(mob),
			NAMEOF_SRC(turf),
			NAMEOF_SRC(area),
			NAMEOF_SRC(__________________),
			NAMEOF_SRC(image),
			NAMEOF_SRC(mutable_appearance),
			NAMEOF_SRC(_icon),
			NAMEOF_SRC(generator),
			NAMEOF_SRC(particles),
			NAMEOF_SRC(matrix),
#if DM_VERSION > 515
			NAMEOF_SRC(pixloc),
			NAMEOF_SRC(vector),
#endif
			NAMEOF_SRC(sound),
			NAMEOF_SRC(__________________),
			NAMEOF_SRC(regex),
			NAMEOF_SRC(database),
			NAMEOF_SRC(query),
			NAMEOF_SRC(exception),
#if DM_VERSION > 515
			NAMEOF_SRC(callee),
#endif
			NAMEOF_SRC(__________________),
			NAMEOF_SRC(wworld),
			NAMEOF_SRC(client),
			NAMEOF_SRC(savefile),
			NAMEOF_SRC(list),
			NAMEOF_SRC(filter)
		)

/datum/view_variables_tester/vv_get_vars_list()
	return true_vars
