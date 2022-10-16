/datum/component/knowledge
	/// one of these: KL_BASIC, KL_EXTRA, KL_FAIL
	var/type
	/// knowledge define
	var/req
	///
	var/req_level
	var/c_name
	var/c_desc
	var/flags
	var/group
	var/dist


/datum/component/knowledge/Initialize(
	type,
	req,
	req_level=0,
	c_name="",
	c_desc="",
	flags=NONE,
	group=NONE,
	dist=-1
	)

	src.type = type
	src.req = req
	src.req_level = req_level
	src.c_name = c_name
	src.c_desc = c_desc
	src.flags = flags
	src.group = group
	src.dist = dist


/datum/component/knowledge/Destroy(force, silent)
	return ..()

/datum/component/knowledge/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/on_examine)

/datum/component/knowledge/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ITEM_ATTACK_SELF,
		COMSIG_ITEM_ATTACK,
		COMSIG_ITEM_ATTACK_OBJ,
		COMSIG_ITEM_ATTACK_EFFECT,
		))
	if(examine_message)
		UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/*
 * Signal proc for [COMSIG_PARENT_EXAMINE].
 * Gives the examiner, if they're a cultist, our set examine message.
 * Usually, this will include various instructions on how to use the thing.
 */
/datum/component/knowledge/proc/on_examine(datum/source, mob/examiner, list/examine_text)
	SIGNAL_HANDLER

	if(!IS_CULTIST(examiner))
		return

	examine_text += examine_message
