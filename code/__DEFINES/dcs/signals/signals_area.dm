// Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

///! from base of area/proc/power_change(): ()
#define COMSIG_AREA_POWER_CHANGE "area_power_change"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AREA_POWER_CHANGE)

/// called after a successful area creation by a mob: (area/created_area, list/area/old_areas, mob/creator)
#define COMSIG_AREA_CREATED "!mob_created_area"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AREA_CREATED, area/created_area, list/area/old_areas, mob/creator)

// /area signals///! from base of area/Entered(): (atom/movable/M)
#define COMSIG_AREA_ENTERED "area_entered"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AREA_ENTERED, atom/movable/mob)
///! from base of area/Exited(): (atom/movable/M)
#define COMSIG_AREA_EXITED "area_exited"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AREA_EXITED, atom/movable/mob)

///from base of area/Entered(): (area/new_area). Sent to "area-sensitive" movables, see __DEFINES/traits.dm for info.
#define COMSIG_ENTER_AREA "enter_area"
DEFINE_SIGNAL_ARGUMENT(COMSIG_ENTER_AREA, area/new_area)
///from base of area/Exited(): (area). Sent to "area-sensitive" movables, see __DEFINES/traits.dm for info.
#define COMSIG_EXIT_AREA "exit_area"
DEFINE_SIGNAL_ARGUMENT(COMSIG_EXIT_AREA, area/old_area)

/// Called when an alarm handler fires an alarm
#define COMSIG_ALARM_TRIGGERED "alarm_triggered"
DEFINE_SIGNAL_ARGUMENT(COMSIG_ALARM_TRIGGERED)
/// Called when an alarm handler clears an alarm
#define COMSIG_ALARM_CLEARED "alarm_cleared"
DEFINE_SIGNAL_ARGUMENT(COMSIG_ALARM_CLEARED)

/// Called when the air alarm mode is updated
#define COMSIG_AIRALARM_UPDATE_MODE "airalarm_update_mode"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AIRALARM_UPDATE_MODE)

// Area fire signals
/// Sent when an area's fire var changes: (fire_value)
#define COMSIG_AREA_FIRE_CHANGED "area_fire_set"
DEFINE_SIGNAL_ARGUMENT(COMSIG_AREA_FIRE_CHANGED, fire_value)
