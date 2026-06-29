-- ScheduleConfig.lua
-- Central tunables for the ProceduralChatter NPC Scheduling System.
-- All named constants are defined here. No logic, no requires.

return {
    -- Relocation
    GRACE_WINDOW_SECONDS    = 30,     -- after door disable, player has this long to follow before NPC goes deep inside
    ARRIVAL_DIST            = 200,    -- units from door target; NPC is considered "arrived"
    SCAN_RANGE_DOORS        = 8192,   -- radius to search for destination doors (units)

    NAVMESH_SNAP_RADIUS     = 64,     -- hint radius passed to findNearestNavMeshPosition

    -- Navmesh-ranked furniture selection (local scripts only)
    NAVMESH_RANKING_ENABLED = true,   -- false = rough-distance order only (rollback)
    SIT_SHORTLIST_SIZE      = 6,      -- max seat candidates per NPC before local path ranking
    SIT_SCAN_DISTANCE       = 8192,   -- rough-distance seat search radius before local path ranking
    SIT_Z_SQUARE_SCALE      = 0.15,   -- vertical bias for seat shortlist; same shape as bed selection
    SLEEP_SHORTLIST_SIZE    = 4,      -- max bed candidates per NPC before local path ranking

    -- Stuck detection (schedule_npc.lua)
    STUCK_CHECK_INTERVAL    = 0.5,    -- seconds between position polls
    STUCK_MOVE_THRESHOLD    = 30,     -- units; less than this over STUCK_WINDOW = stuck
    STUCK_WINDOW            = 5.0,    -- seconds of movement history evaluated
    ESCAPE_ATTEMPTS_MAX     = 2,      -- escape raycasts before requesting forced teleport

    -- Targeted Travel unstuck nudges (npc.lua-owned Travel only; never Wander)
    TARGETED_TRAVEL_UNSTUCK_ENABLED = true,
    TARGETED_TRAVEL_NUDGE_COOLDOWN  = 1.5,
    TARGETED_TRAVEL_MAX_NUDGES      = 3,
    TARGETED_TRAVEL_NUDGE_DISTANCE  = 35,

    -- Sitting approach early-lerp failsafe
    SIT_ARRIVE_DIST                 = 40,
    SIT_STOOL_ARRIVE_DIST           = 60,
    SIT_APPROACH_STUCK_MULTIPLIER   = 2,
    SIT_APPROACH_STUCK_SECONDS      = 2.5,
    SIT_APPROACH_PROGRESS_EPSILON   = 5,
    SIT_APPROACH_TIMEOUT            = 25.0,

    -- Batching / performance
    MORNING_BATCH_SIZE      = 8,      -- max NPC transitions processed per second (prevents frame spikes)

    -- Occupancy
    SAFE_PLACE_MAX_OCCUPANCY = 6,     -- max NPCs routed to a single safe-place interior (set low to avoid packing)
    GRID_SPACING             = 64,    -- units between NPCs placed inside an interior

    -- Time windows (game hours, 0-23)
    TAVERN_WINDOW_START     = 18,
    TAVERN_WINDOW_END       = 22,     -- 6pm–10pm tavern social window
    HOME_WINDOW_START       = 22,
    HOME_WINDOW_END         = 7,      -- 10pm–7am, wraps midnight
    WAKE_HOUR               = 6,      -- NPCs get out of bed (SleepManager)
    LEAVE_HOME_HOUR         = 8,      -- NPCs exit their home interior and return to native position

    -- Debug / subsystem toggles
    -- Controlled by settings menu (Settings_Chatter_Debug). All default OFF so
    -- systems remain disabled until the player script syncs the user's preference.
    -- This prevents race-condition activation during Lua reload.
    DEBUG_MODE               = false,  -- verbose [Scheduler]/[Relocator]/[HomeNight] prints
    ACTIVITY_MANAGER_ENABLED = false, -- controlled by Settings_Chatter_Debug.ActivitiesEnabled
    SLEEP_MANAGER_ENABLED    = false, -- controlled by Settings_Chatter_Debug.SleepEnabled
    SITTING_GLOBAL_ENABLED   = false, -- controlled by Settings_Chatter_Debug.SittingEnabled
    SCHEDULE_ENABLED         = false, -- controlled by Settings_Chatter_Debug.ScheduleEnabled
    SCHEDULE_MOVEMENT_ENABLED = false, -- controlled by Settings_Chatter_Debug.ScheduleMovementEnabled

    -- Walk-speed estimate used to predict when a walking NPC will reach the door.
    -- Conservative (low) so real walk arrival always takes priority over ETA teleport.
    -- Units per simulation-second.  Tune if NPCs consistently arrive before/after estimate.
    ESTIMATED_WALK_SPEED     = 80,

    -- Audio settings
    ENABLE_DOOR_SOUNDS       = true,
    DOOR_SOUND_COOLDOWN      = 1.0,
}
