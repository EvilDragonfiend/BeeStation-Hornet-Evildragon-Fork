SUBSYSTEM_DEF(status)
	name = "Mobs Status"
	flags = SS_KEEP_TIMING | SS_NO_INIT
	priority = FIRE_PRIORITY_STATUS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 2 SECONDS

	var/list/status_list = list()
	var/list/current_mobs = list()
	var/list/mobs_duration = list()


/datum/controller/subsystem/status/Initialize(timeofday)
	for(var/datum/status/S in subtypesof(/datum/status))
		status_list += list("[S.key]" = S)

/datum/controller/subsystem/status/Recover()
	status_list = SSstatus.status_list
	current_mob = SSstatus.current_mob
	duration_mob = SSstatus.duration_mob

/datum/controller/subsystem/status/fire(resumed = FALSE)
	if(length(current_mob))
		var/current_i = 0
		while(current_i++ < length(current_victims))
			var/mob/living/L = current_victims[current_i]
			if(istype(L, /mob/living))
				ADD_TRAIT(L, TRAIT_INTENT_LOCKED, MAGIC_TRAIT)
				victim_duration[current_i] -= delta_time * 10
				if(victim_duration[current_i] <= 0)
					free_victim(current_victims[current_i])
					current_i--


/datum/controller/subsystem/status/proc/add_status(mob/victim, status, duration, stackable=FALSE)
	for(var/i in 1 to length(current_victims))
		if(current_mobs[i] == victim)
			if(stackable)
				mobs_duration[i] += duration
			else
				if(victim_duration[i] > duration)
			return
	current_victims += victim
	victim_duration += spell_duration

/datum/controller/subsystem/status/proc/remove_status(mob/victim, status, time)
