///Called on /mob/living/Initialize(), for the mob to register to relevant signals.
/mob/living/proc/register_init_signals()
	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_loss))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_DEATHCOMA), PROC_REF(on_deathcoma_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_DEATHCOMA), PROC_REF(on_deathcoma_trait_loss))

	RegisterSignals(src, list(
		SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION),
		SIGNAL_REMOVETRAIT(TRAIT_CRITICAL_CONDITION),

		SIGNAL_ADDTRAIT(TRAIT_NODEATH),
		SIGNAL_REMOVETRAIT(TRAIT_NODEATH),
	), PROC_REF(update_succumb_action))


///Called when TRAIT_KNOCKEDOUT is added to the mob.
/mob/living/proc/on_knockedout_trait_gain(datum/source)
	SIGNAL_HANDLER
	if(stat < UNCONSCIOUS)
		set_stat(UNCONSCIOUS)

///Called when TRAIT_KNOCKEDOUT is removed from the mob.
/mob/living/proc/on_knockedout_trait_loss(datum/source)
	SIGNAL_HANDLER
	if(stat <= UNCONSCIOUS)
		update_stat()


///Called when TRAIT_DEATHCOMA is added to the mob.
/mob/living/proc/on_deathcoma_trait_gain(datum/source)
	SIGNAL_HANDLER
	ADD_TRAIT(src, TRAIT_KNOCKEDOUT, TRAIT_DEATHCOMA)

///Called when TRAIT_DEATHCOMA is removed from the mob.
/mob/living/proc/on_deathcoma_trait_loss(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, TRAIT_DEATHCOMA)

/// Called when traits that alter succumbing are added/removed.
/// Will show or hide the succumb alert prompt.
/mob/living/proc/update_succumb_action()
	SIGNAL_HANDLER
	if (CAN_SUCCUMB(src))
		throw_alert("succumb", /atom/movable/screen/alert/succumb)
	else
		clear_alert("succumb")
