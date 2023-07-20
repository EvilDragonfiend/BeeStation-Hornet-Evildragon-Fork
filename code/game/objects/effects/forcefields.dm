/obj/effect/forcefield
	desc = "A space wizard's magic wall."
	name = "FORCEWALL"
	icon_state = "m_shield"
	anchored = TRUE
	opacity = FALSE
	density = TRUE
	CanAtmosPass = ATMOS_PASS_DENSITY
	obj_flags = CAN_BE_HIT | BLOCK_Z_IN_DOWN | BLOCK_Z_IN_UP
	var/timeleft = 300 //Set to 0 for permanent forcefields (ugh)

/obj/effect/forcefield/Initialize(mapload, ntimeleft)
	. = ..()
	if(isnum_safe(ntimeleft))
		timeleft = ntimeleft
	if(timeleft)
		QDEL_IN(src, timeleft)

/obj/effect/forcefield/singularity_pull()
	return

/obj/effect/forcefield/cult
	desc = "An unholy shield that blocks all attacks."
	name = "glowing wall"
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "cultshield"
	CanAtmosPass = ATMOS_PASS_NO
	timeleft = 200

///////////Mimewalls///////////

/obj/effect/forcefield/mime
	icon_state = "nothing"
	name = "invisible wall"
	desc = "You have a bad feeling about this."
	var/obj/effect/ghost_visual_helper/visible_wall

/obj/effect/forcefield/mime/advanced
	name = "invisible blockade"
	desc = "You're gonna be here awhile."
	timeleft = 600

/obj/effect/forcefield/mime/Initialize(mapload, ntimeleft)
	. = ..()
	visible_wall = new(src)
	vis_contents += visible_wall

/obj/effect/forcefield/mime/Destroy(force)
	QDEL_NULL(visible_wall)
	. = ..()

// this exists to help ghosts
/obj/effect/ghost_visual_helper
	name = "the real wall"
	desc = "holy shit, this is the real wall!"
	icon = 'icons/turf/walls/snow_wall.dmi'
	icon_state = "snow_wall-0"
	alpha = 140
	invisibility = INVISIBILITY_OBSERVER

// use this if you want another.
/obj/effect/ghost_visual_helper/proc/mimics_from_atom(atom/original, try_initial)
	name = try_initial ? "the real [initial(original.name)]": "the real [original.name]"
	desc = "Only ghosts can see this."
	icon = try_initial ? initial(original.icon) : original.icon
	icon_state = try_initial ? initial(original.icon_state) : original.icon_state
