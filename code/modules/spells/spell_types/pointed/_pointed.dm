/**
 * ## Pointed spells
 *
 * These spells override the caster's click,
 * allowing them to cast the spell on whatever is clicked on.
 *
 * To add effects on cast, override "cast(atom/cast_on)".
 * The cast_on atom is the person who was clicked on.
 */
/datum/action/spell/pointed
	requires_target = TRUE

	/// The base icon state of the spell's button icon, used for editing the icon "on" and "off"
	var/base_icon_state
	/// Message showing to the spell owner upon activating pointed spell.
	var/active_msg
	/// Message showing to the spell owner upon deactivating pointed spell.
	var/deactive_msg
	/// The casting range of our spell
	var/cast_range = 7
	/// Variable dictating if the spell will use turf based aim assist
	var/aim_assist = TRUE

/datum/action/spell/pointed/New(Target)
	. = ..()
	if(!active_msg)
		active_msg = "You prepare to use [src] on a target..."
	if(!deactive_msg)
		deactive_msg = "You dispel [src]."

/datum/action/spell/pointed/set_click_ability(mob/on_who)
	. = ..()
	if(!.)
		return

	on_activation(on_who)

// Note: Destroy() calls Remove(), Remove() calls unset_click_ability() if our spell is active.
/datum/action/spell/pointed/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(!.)
		return

	on_deactivation(on_who, refund_cooldown = refund_cooldown)

/datum/action/spell/pointed/pre_cast(mob/user, atom/target)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		on_deactivation(owner, refund_cooldown = FALSE)

/// Called when the spell is activated / the click ability is set to our spell
/datum/action/spell/pointed/proc/on_activation(mob/on_who)
	SHOULD_CALL_PARENT(TRUE)

	to_chat(on_who, ("<span class='notice'>[active_msg] <B>Left-click to cast the spell on a target!</B></span>"))
	if(base_icon_state)
		button_icon_state = "[base_icon_state]1"
		update_buttons()
	return TRUE

/// Called when the spell is deactivated / the click ability is unset from our spell
/datum/action/spell/pointed/proc/on_deactivation(mob/on_who, refund_cooldown = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if(refund_cooldown)
		// Only send the "deactivation" message if they're willingly disabling the ability
		to_chat(on_who, ("<span class='notice'>[deactive_msg]</span>"))
	if(base_icon_state)
		button_icon_state = "[base_icon_state]0"
		update_buttons()
	return TRUE

/datum/action/spell/pointed/InterceptClickOn(mob/living/clicker, params, atom/click_target)

	var/atom/aim_assist_target
	if(aim_assist && isturf(click_target))
		// Find any human in the list. We aren't picky, it's aim assist after all
		aim_assist_target = locate(/mob/living/carbon/human) in click_target
		if(!aim_assist_target)
			// If we didn't find a human, we settle for any living at all
			aim_assist_target = locate(/mob/living) in click_target

	return ..(clicker, params, aim_assist_target || click_target)

/datum/action/spell/pointed/is_valid_spell(mob/user, atom/target)
	if(target == owner)
		to_chat(owner, ("<span class='warning'>You cannot cast [src] on yourself!</span>"))
		return FALSE

	return TRUE

/datum/action/spell/pointed/pre_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	if(owner && get_dist(get_turf(owner), get_turf(cast_on)) > cast_range)
		cast_on.balloon_alert(owner, "too far away!")
		return . | SPELL_CANCEL_CAST

/**
 * ### Pointed projectile spells
 *
 * Pointed spells that, instead of casting a spell directly on the target that's clicked,
 * will instead fire a projectile pointed at the target's direction.
 */
/datum/action/spell/pointed/projectile
	/// What projectile we create when we shoot our spell.
	var/obj/projectile/magic/projectile_type = /obj/projectile/magic/teleport
	/// How many projectiles we can fire per cast. Not all at once, per click, kinda like charges
	var/projectile_amount = 1
	/// How many projectiles we have yet to fire, based on projectile_amount
	var/current_amount = 0
	/// How many projectiles we fire every fire_projectile() call.
	/// Unwise to change without overriding or extending ready_projectile.
	var/projectiles_per_fire = 1

/datum/action/spell/pointed/projectile/New(Target)
	. = ..()
	if(projectile_amount > 1)
		unset_after_click = FALSE

/datum/action/spell/pointed/projectile/is_valid_spell(mob/user, atom/target)
	return TRUE

/datum/action/spell/pointed/projectile/on_activation(mob/on_who)
	. = ..()
	if(!.)
		return

	current_amount = projectile_amount

/datum/action/spell/pointed/projectile/on_deactivation(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(projectile_amount > 1 && current_amount)
		start_cooldown(cooldown_time * ((projectile_amount - current_amount) / projectile_amount))
		current_amount = 0

// cast_on is a turf, or atom target, that we clicked on to fire at.
/datum/action/spell/pointed/projectile/on_cast(mob/user, atom/target)
	. = ..()
	if(!isturf(owner.loc))
		return FALSE

	var/turf/caster_turf = get_turf(owner)
	// Get the tile infront of the caster, based on their direction
	var/turf/caster_front_turf = get_step(owner, owner.dir)

	fire_projectile(target)
	owner.newtonian_move(get_dir(caster_front_turf, caster_turf))
	if(current_amount <= 0)
		unset_click_ability(owner, refund_cooldown = FALSE)

	return TRUE

/datum/action/spell/pointed/projectile/post_cast(mob/user, atom/target)
	. = ..()
	if(current_amount > 0)
		// We still have projectiles to cast!
		// Reset our cooldown and let them fire away
		reset_spell_cooldown()

/datum/action/spell/pointed/projectile/proc/fire_projectile(atom/target)
	current_amount--
	for(var/i in 1 to projectiles_per_fire)
		var/obj/projectile/to_fire = new projectile_type()
		ready_projectile(to_fire, target, owner, i)
		to_fire.fire()
	return TRUE

/datum/action/spell/pointed/projectile/proc/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	to_fire.firer = owner
	to_fire.fired_from = get_turf(owner)
	to_fire.preparePixelProjectile(target, owner)
	RegisterSignal(to_fire, COMSIG_PROJECTILE_ON_HIT, PROC_REF(on_cast_hit))

	if(istype(to_fire, /obj/projectile/magic))
		var/obj/projectile/magic/magic_to_fire = to_fire
		magic_to_fire.antimagic_flags = antimagic_flags

/// Signal proc for whenever the projectile we fire hits someone.
/// Pretty much relays to the spell when the projectile actually hits something.
/datum/action/spell/pointed/projectile/proc/on_cast_hit(atom/source, mob/firer, atom/hit, angle)
	SIGNAL_HANDLER

	SEND_SIGNAL(src, COMSIG_SPELL_PROJECTILE_HIT, hit, firer, source)

