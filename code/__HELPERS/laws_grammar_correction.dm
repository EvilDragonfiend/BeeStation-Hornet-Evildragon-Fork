// species grammar correction and pluralisation
/proc/p_grammar_correction_species(taken_species, lower=TRUE)
	if(taken_species)
		var/temp_species = lowertext(taken_species)
		temp_species = replacetext(temp_species, "\improper", "")
		temp_species = replacetext(temp_species, "\proper", "")
		var/static/grammar_correction = list(
			"human" = "human being",
			"ipc" = "\improper Integrated Positronic Chassis"
		)
		if(temp_species in grammar_correction)
			return lower ? lowertext(grammar_correction[temp_species]) : grammar_correction[temp_species]
		return taken_species

/proc/p_pluralize_species(taken_species, lower=TRUE)
	if(taken_species)
		var/temp_species = lowertext(taken_species)
		temp_species = replacetext(temp_species, "\improper", "")
		temp_species = replacetext(temp_species, "\proper", "")
		var/static/species_plural = list(
			"human" = "\improper Humans",
			"human being" = "\improper Human beings",
			"sentient creature" = "\improper Sentient creatures", // specimov default
			"integrated positronic chassis" = "\improper Integrated Positronic Chassis", // Chassis's plural is Chassis
			"ipc" = "\improper Integrated Positronic Chassis", // grammar correction
			"ethereal" = "\improper Ethreals",
			"plasmaman" = "\improper Plasmamen",
			"apid" = "\improper Apids",
			"moth" = "\improper Moths",
			"lizardperson" = "\improper Lizardpeople",
			"ashwalker" = "\improper Ashwalkers",
			"felinid" = "\improper Felinids",
			"flyperson" = "\improper Flypeople",
			"monkey" = "\improper Monkies",
			"oozeling" = "\improper Oozalings",
			"jellyperson" = "\improper Jellypeople",
			"slimeperson" = "\improper Slimepeople",
			"luminescent" = "\improper Luminescents",
			"stargazer" = "\improper Stargzers",
			"podperson" = "\improper Podpeople",
			"golem" = "\improper Golems",
			"abductor" = "\improper Abductors",
			"shadowperson" = "\improper Shadowpeople",
			"zombie" = "\improper Zombies",
			"vampire" = "\improper Vampires",
			"snailperson" = "\improper Snailpeople",
			"spooky scary skeleton" = "\improper Spooky Scary Skeletons",
			"dullahan" = "\improper Dullahans",
			"android" = "\improper Androids",
			"xenomorph" = "\improper Xenomorphs",
			"person" = "people",
			"man" = "men",
			"woman" = "women",
			"child" = "children"
			)
		if(temp_species in species_plural)
			return lower ? lowertext(species_plural[temp_species]) : species_plural[temp_species]
		return "[taken_species]s"
