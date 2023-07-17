#define NEW_BANK_ACCOUNT_COST 1000

//Keeps track of the time for the ID console. Having it as a global variable prevents people from dismantling/reassembling it to
//increase the slots of many jobs.
GLOBAL_VAR_INIT(time_last_changed_position, 0)

/obj/machinery/computer/card
	name = "identification console"
	desc = "You can use this to manage jobs and ID access."
	icon_screen = "id"
	icon_keyboard = "id_key"
	req_one_access = list(ACCESS_CHANGE_IDS,
							ACCESS_HEADS,
							ACCESS_HOP,
							ACCESS_HOS,
							ACCESS_CMO,
							ACCESS_RD,
							ACCESS_CE,
							ACCESS_CAPTAIN,
							ACCESS_CENT_CAPTAIN)
	circuit = /obj/item/circuitboard/computer/card
	var/mode = 0
	var/printing = null
	// remove var/target_dept = DEPT_ALL //Which department this computer has access to.
	// remove var/available_paycheck_departments = list()
	// var/list/region_access = null
	// var/region_access_payment = NONE
	// var/list/head_subordinates = null

	/// if TRUE, can't access to some features
	var/minor = FALSE
	var/target_paycheck = ACCOUNT_SRV_ID
	var/list/available_departments = list(DEPT_NAME_SERVICE,
											DEPT_NAME_CIVILIAN, // civ has no access list, but exists for manifest and payment
											DEPT_NAME_SUPPLY,
											DEPT_NAME_MEDICAL,
											DEPT_NAME_SCIENCE,
											DEPT_NAME_ENGINEERING,
											DEPT_NAME_SECURITY,
											DEPT_NAME_COMMAND)
	var/auth_bitflag_dominant = NONE
	var/auth_bitflag_supervisor = NONE
	var/auth_bitflag_manifest = NONE
	var/auth_bitflag_budget = NONE

	//Cooldown for closing positions in seconds
	//if set to -1: No cooldown... probably a bad idea
	//if set to 0: Not able to close "original" positions. You can only close positions that you have opened before
	var/change_position_cooldown = 30
	//Jobs you cannot open new positions for
	var/list/blacklisted = list(
		JOB_NAME_AI,
		JOB_NAME_ASSISTANT,
		JOB_NAME_CYBORG,
		JOB_NAME_CAPTAIN,
		JOB_NAME_HEADOFPERSONNEL,
		JOB_NAME_HEADOFSECURITY,
		JOB_NAME_CHIEFENGINEER,
		JOB_NAME_RESEARCHDIRECTOR,
		JOB_NAME_CHIEFMEDICALOFFICER,
		JOB_NAME_BRIGPHYSICIAN,
		JOB_NAME_DEPUTY)

	//The scaling factor of max total positions in relation to the total amount of people on board the station in %
	var/max_relative_positions = 30 //30%: Seems reasonable, limit of 6 @ 20 players

	//This is used to keep track of opened positions for jobs to allow instant closing
	//Assoc array: "JobName" = (int)<Opened Positions>
	var/list/opened_positions = list();
	var/obj/item/card/id/inserted_scan_id
	var/obj/item/card/id/inserted_modify_id

	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/card/Initialize(mapload)
	. = ..()
	change_position_cooldown = CONFIG_GET(number/id_console_jobslot_delay)
	for(var/G in typesof(/datum/job/gimmick))
		var/datum/job/gimmick/J = new G
		blacklisted += J.title

/obj/machinery/computer/card/centcom
	name = "\improper CentCom identification console"
	circuit = /obj/item/circuitboard/computer/card/centcom
	req_access = list(ACCESS_CENT_CAPTAIN)

/obj/machinery/computer/card/centcom/Initialize(mapload)
	. = ..()
	available_departments |= SSdepartment.department_id_list

/obj/machinery/computer/card/minor
	name = "department management console"
	desc = "You can use this to change ID's for specific departments."
	minor = TRUE
	icon_screen = "idminor"
	circuit = /obj/item/circuitboard/computer/card/minor

/obj/machinery/computer/card/minor/hos
	name = "security department console"
	available_departments = list(DEPT_NAME_SECURITY)
	target_paycheck = ACCOUNT_SEC_ID
	icon_screen = "idhos"

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/card/minor/cmo
	name = "medical department console"
	available_departments = list(DEPT_NAME_MEDICAL)
	target_paycheck = ACCOUNT_MED_ID
	icon_screen = "idcmo"

/obj/machinery/computer/card/minor/rd
	name = "science department console"
	available_departments = list(DEPT_NAME_SCIENCE)
	target_paycheck = ACCOUNT_SCI_ID
	icon_screen = "idrd"

	light_color = LIGHT_COLOR_PINK

/obj/machinery/computer/card/minor/ce
	name = "engineering department console"
	available_departments = list(DEPT_NAME_ENGINEERING)
	target_paycheck = ACCOUNT_ENG_ID
	icon_screen = "idce"

	light_color = LIGHT_COLOR_YELLOW

#undef NEW_BANK_ACCOUNT_COST
