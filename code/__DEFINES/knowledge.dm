#define KL_BASIC "klbasic"
#define KL_EXTRA "klextra"
#define KL_FAIL "klfail"


#define KNOWLEDGE_DIFFICULTY_EASY 1
#define KNOWLEDGE_DIFFICULTY_MEDIUM 2
#define KNOWLEDGE_DIFFICULTY_HARD 3
#define KNOWLEDGE_DIFFICULTY_VERY_HARD 3

#define KNOWLEDGE_DESC_SAME "same_above" // use to place multiple knowledge has the same desc
#define KNOWLEDGE_NAME_SAME "same_above"
#define KNOWLEDGE_DESC_DEFAULT "You are not sure what this is..."
#define KNOWLEDGE_NAME_DEFAULT "???"

// Used in `knowledge_flags` in atoms.dm
#define NOSHOW_FAIL_NAME_ON_FAIL_BASIC (1<<0) // If you fail to check `req_knowledge_basic`, it will show default name, don't show fail name.
#define NOSHOW_FAIL_DESC_ON_FAIL_BASIC (1<<1) // If you fail to check `req_knowledge_basic`, it will show default description, don't show fail description.
#define NOSHOW_EXTRA_DESC_ON_FAIL_BASIC (1<<2) //If you fail to check `req_knowledge_basic`, it will NOT show any extra description.
                                // This makes you need two knowledge requirement. one from basic, one from extra
#define FORCESHOW_FAIL_NAME_ON_FAIL_EXTRA (1<<3) // If you fail to check `req_knowledge_extra`, it will show fail name, will not show the default name even if you success basic check
#define FORCESHOW_FAIL_DESC_ON_FAIL_EXTRA (1<<4) // If you fail to check `req_knowledge_extra`, it will show fail description, will not show the default description even if you success basic check

#define NOSHOW_DETAILS_ON_SUCCESS_EXTRA (1<<5) // It will not show any knowledge you successed. [Medical] [Engineering] stuff will not be seen.
#define FORCESHOW_DETAILS_ON_SINGLE_SUCCESS_EXTRA (1<<6) // single success on extra knowledge req doesn't show which knowledge you successed. I mean, it wouldn't show [Medical] thing if it is a single line. This flag will force show it.

///////////////////
//// knowledge ////
///////////////////
#define KNOWLEDGE_DEBUG "Debug" // let you know all
#define KNOWLEDGE_NO_KEY "no_key" // dummy key for fail_name & fail_desc
// `KNOWLEDGE_NO_KEY` must be base key for all fail cases

// hierarchy
#define KNOWLEDGE_COMMAND "Command"

// Species only
#define KNOWLEDGE_SPACE_MAN "Spcae Man" // common to crews
#define KNOWLEDGE_ASHWALKER "Ashwalker"
#define KNOWLEDGE_ABDUCTOR "Abductor"

// standard knowledge
#define KNOWLEDGE_BASIC "Basic" // a monkey has not this.
#define KNOWLEDGE_STATION "Station" // a monkey + a bitch bum has not this. - to be deleted. spaceman should use this
#define KNOWLEDGE_SPACE_LAW "Spacelaw"
#define KNOWLEDGE_COMPUTER "Computer"
#define KNOWLEDGE_DRINKS "Drinks"
#define KNOWLEDGE_FOODS "Foods"
#define KNOWLEDGE_PLANTS "Plants"
#define KNOWLEDGE_MATERIALS "Materials"
#define KNOWLEDGE_CREATURES "Creatures"
#define KNOWLEDGE_HISTORY "History"

// medical
#define KNOWLEDGE_MEDICAL "Medical" // overall knowledge about medical
#define KNOWLEDGE_SURGERY "Surgery"
#define KNOWLEDGE_CHEMISTRY "Chemistry"
#define KNOWLEDGE_GENETICS "Genetics"
#define KNOWLEDGE_VIROLOGY "Virology"

// engineering
#define KNOWLEDGE_ENGINEERING "Engineering"
#define KNOWLEDGE_CONSTRUCTION "Construct"
#define KNOWLEDGE_ELECTRONICS "Electronics"
#define KNOWLEDGE_ATMOSPHERIC "Atmos"

// science
#define KNOWLEDGE_SCIENCE "Science"
#define KNOWLEDGE_ROBOTICS "Robotics"
#define KNOWLEDGE_MECHATRONICS "Mechatronics"

// combat & security
#define KNOWLEDGE_COMBAT "Combat"
#define KNOWLEDGE_GUN "Gun"
#define KNOWLEDGE_FORENSICS "Forensics"

// civilian & service
#define KNOWLEDGE_BOTANY "Botany"
#define KNOWLEDGE_BARTENDING "Bartending"
#define KNOWLEDGE_COOKING "Cooking"
#define KNOWLEDGE_ENTERTAINMENT "Entertainment"
#define KNOWLEDGE_CLEANING "Cleaning"
#define KNOWLEDGE_SUPPLY "Supply"

// unusual knowledge
#define KNOWLEDGE_SYNDICATE "Syndicate"
#define KNOWLEDGE_HACKING "Hacking"
#define KNOWLEDGE_OCCULT "Occult"
#define KNOWLEDGE_RELIGION "Religion"
#define KNOWLEDGE_MAGIC "Magic"


///////////////////
//// expertise ////
///////////////////
#define EXPERTISE_DEBUG "debug" // let you know all

// standard knowledge
#define EXPERTISE_FIRST_AID "first_aid"

// surgery
#define EXPERTISE_BRAIN_RECALIBRATION "brain_recalibration"
#define EXPERTISE_LOBOTOMY "lobotomy"



////////////////
//// source ////
//////////////// *KNEX = KNOWLEDGE + EXPERTISE
#define KNEX_SOURCE_ROUNDSTART "roundstart"
#define KNEX_SOURCE_TRAITOR "traitor" // given to traitors and incursionists
#define KNEX_SOURCE_NUKETEAM "nukies"
