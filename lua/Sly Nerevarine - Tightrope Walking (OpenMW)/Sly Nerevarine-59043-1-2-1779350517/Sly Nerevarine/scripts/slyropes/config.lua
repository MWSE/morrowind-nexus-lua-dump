local M = {}

-- Diagnostic logging defaults. The in-game Sly Nerevarine settings page can enable these at runtime.
M.DEBUG = false
M.LOG_STATE_CHANGES = false

-- Runtime collision helper. This is still normal physics collision: no levitation and no player teleport.
M.COLLISION_RECORD_ID = 'slyropes_invisible_tightrope_collision'
M.COLLISION_MODEL = 'meshes/slyropes/invisible_tightrope_collision.dae'

-- Collision helper dimensions are baked into the DAE: approximately 180 x 56 x 12 game units.
-- This offset controls where the helper's TOP surface sits relative to the visual rendering-ray hit.
M.HELPER_TOP_OFFSET = 2
M.HELPER_HALF_HEIGHT = 6

-- How often the player asks the global script to refresh/move the collision helper while actively tightrope-walking.
M.SEND_INTERVAL = 0.025

-- Performance gate. When enabled, Sly Nerevarine does no rope raycasts, no stat/fatigue reads,
-- no random balance rolls, and no collision-helper maintenance unless the player is holding sneak.
M.REQUIRE_SNEAK_FOR_DETECTION = true

-- While sneaking but not currently on a rope, throttle acquisition scans. Once active,
-- scans run every frame for responsive edge/drop detection and stable support placement.
M.INACTIVE_SCAN_INTERVAL_SECONDS = 0.15

-- Detection rays around the player's feet.
M.SCAN_UP = 120
M.SCAN_DOWN = 220
M.SAMPLE_RADIUS = 32 -- legacy fallback if SAMPLE_RADII is removed
M.SAMPLE_RADII = { 16, 32, 48 }

-- A rope hit must be close to the player's current X/Y to count as standing on/near the rope.
-- v0.11 scales this from Acrobatics, Agility, and current fatigue.
M.MAX_VALID_HIT_XY_DISTANCE = 54

-- Balance / competency model. Uses modified stats when available.
-- The weighted average keeps Acrobatics important, but a strong single stat can carry the player.
-- This matches the intended progression: 5/5 is nearly hopeless, roughly 40-60 combined is viable,
-- and 60+ in either Acrobatics or Agility is mostly reliable with occasional mishaps.
-- Effective competency then gets multiplied by a fatigue factor.
M.COMPETENCY_ENABLED = true
M.COMPETENCY_REFRESH_SECONDS = 0.35
M.COMPETENCY_ACROBATICS_WEIGHT = 0.80
M.COMPETENCY_AGILITY_WEIGHT = 0.20
M.COMPETENCY_BEST_STAT_CARRY_AT_60 = 0.82
M.COMPETENCY_FALLBACK_ACROBATICS = 50
M.COMPETENCY_FALLBACK_AGILITY = 50
M.COMPETENCY_FALLBACK_FATIGUE_RATIO = 1.0

-- Low fatigue penalty. 1.0 fatigue = no penalty, 0.0 fatigue = severe penalty.
-- Values below are deliberately not zeroing out the player; a skilled character can still recover while tired.
M.FATIGUE_COMPETENCY_MULT_MIN = 0.35
M.FATIGUE_COMPETENCY_MULT_MAX = 1.05

-- Per-effective-competency limits. Fatigue now affects these too.
-- This also makes stepping off the rope resolve slightly quicker than v0.9.
M.MAX_VALID_HIT_XY_DISTANCE_MIN = 48
M.MAX_VALID_HIT_XY_DISTANCE_MAX = 64
M.RAY_LOST_GRACE_SECONDS_MIN = 0.28
M.RAY_LOST_GRACE_SECONDS_MAX = 0.58
M.MAX_STICKY_XY_DRIFT_MIN = 54
M.MAX_STICKY_XY_DRIFT_MAX = 90
M.DRIFT_DISMOUNT_AFTER_SECONDS_MIN = 0.08
M.DRIFT_DISMOUNT_AFTER_SECONDS_MAX = 0.22

-- Static fallbacks used when competency scaling is disabled.
M.RAY_LOST_GRACE_SECONDS = 0.36
M.MAX_STICKY_XY_DRIFT = 68
M.DRIFT_DISMOUNT_AFTER_SECONDS = 0.12

-- Mount check. This is evaluated only when the player first tries to acquire a rope.
-- It provides the missing feedback path for failing before the helper ever becomes active.
M.MOUNT_FAILURE_ENABLED = true
M.MOUNT_SUCCESS_CHANCE_MIN = 0.005
M.MOUNT_SUCCESS_CHANCE_MAX = 0.997
M.MOUNT_COMPETENCY_ZERO = 0.12
M.MOUNT_COMPETENCY_FULL = 0.62
M.MOUNT_SUCCESS_CURVE = 0.50
M.MOUNT_RETRY_SUPPRESSION_SECONDS = 0.55
M.SHOW_MOUNT_FAIL_MESSAGES = true

-- Active balance checks. These make tightrope walking a skill/fatigue check rather than only a collision patch.
-- v0.11 deliberately removes running, strafing, backpedaling, sharp turning, and off-center ray distance
-- from the stochastic fall model. Those inputs no longer cause balance messages or balance failures.
M.BALANCE_FAILURE_ENABLED = true
M.BALANCE_CHECK_INTERVAL_SECONDS = 0.90
M.BALANCE_FAIL_CHANCE_MIN = 0.000
M.BALANCE_FAIL_CHANCE_MAX = 0.16
M.BALANCE_REQUIRE_MOVING = true
M.BALANCE_COMPETENCY_MITIGATION_LOW = 1.10
M.BALANCE_COMPETENCY_MITIGATION_HIGH = 0.12

-- After a failed balance roll, keep the helper disabled briefly so the failure becomes a real fall
-- instead of immediately reacquiring the rope on the next frame.
M.BALANCE_REACQUIRE_SUPPRESSION_SECONDS = 0.85
M.BALANCE_MESSAGE_MIN_FALL_Z = 6

-- Risk terms are per balance check before competency reduction.
-- Only competency/fatigue, low Acrobatics, and optional jumping affect random balance loss.
M.BALANCE_BASE_RISK = 0.000
M.BALANCE_SKILL_DEFICIT_RISK = 0.016
M.BALANCE_LOW_ACROBATICS_RISK = 0.045
M.BALANCE_LOW_ACROBATICS_THRESHOLD = 40
M.BALANCE_LOW_STAT_COMPENSATION_START = 40
M.BALANCE_LOW_STAT_COMPENSATION_END = 60
M.BALANCE_LOW_STAT_COMPENSATED_MULT = 0.05
M.BALANCE_LOW_FATIGUE_RISK = 0.145
M.BALANCE_JUMP_RISK = 0.600

-- Legacy keys kept at zero so old configs can still be compared without enabling movement-based failure.
M.BALANCE_OFFCENTER_RISK = 0.000
M.BALANCE_STRAFE_RISK = 0.000
M.BALANCE_BACKPEDAL_RISK = 0.000
M.BALANCE_RUNNING_RISK = 0.000
M.BALANCE_TURN_RISK = 0.000

-- Skill gain. This uses the vanilla Acrobatics_Jump skill-use channel but scaled down.
-- v0.20 slightly increases tightrope XP, but it remains far below a full jump-use tick.
-- Only awarded while the player is actually moving on a detected rope, not while standing still or sticky-falling.
M.ACROBATICS_XP_ENABLED = true
M.ACROBATICS_XP_INTERVAL_SECONDS = 1.00
M.ACROBATICS_XP_SCALE = 0.12
M.ACROBATICS_XP_MIN_MOVEMENT = 0.15

-- Player-facing feedback.
-- Failed-mount messages are shown immediately because no active rope helper exists yet.
-- Skill/fatigue balance-fail messages are delayed until the script observes an actual vertical drop.
-- Deterministic "walked off the rope" messages are suppressed by default because the player action is obvious.
M.SHOW_FALL_MESSAGES = true
M.SHOW_SKILL_FALL_MESSAGES = true
M.SHOW_OFF_ROPE_MESSAGES = false
M.MESSAGE_COOLDOWN_SECONDS = 1.25

-- Absolute safety cutoff for one continuous rope lock.
M.MAX_LOCK_SECONDS = 24

-- Logging controls. Keep state changes visible, but do not spam every transient ray miss unless debugging raycasts.
M.LOG_RAY_LOST_TRANSITIONS = false
M.LOG_MOUNT_ROLLS = true -- effective only when debug logging is enabled in the Sly Nerevarine settings page
M.LOG_BALANCE_ROLLS = true -- effective only when debug logging is enabled in the Sly Nerevarine settings page
M.LOG_SKILL_SNAPSHOTS = true -- effective only when debug logging is enabled in the Sly Nerevarine settings page
M.LOG_SKILL_SNAPSHOT_INTERVAL_SECONDS = 1.00
M.LOG_XP_TICKS = false

-- v0.11 uses the visual rope hit as the support point, not the player position.
-- This is what makes walking off the rope drop the player instead of carrying the helper under them.
M.SUPPORT_FOLLOWS_PLAYER = false

-- Alignment for the invisible collision patch:
--   'rope'          = align with the detected rope object's rotation. Best default for the canal-pole records.
--   'locked-player' = freeze the player's yaw at first rope contact.
--   'player'        = rotate with the player every frame.
--   'world-x' or 'world-y' = fixed world axes for debugging.
M.ALIGNMENT_MODE = 'rope'
M.ROPE_EXTRA_YAW_DEGREES = 0

-- Adds a second perpendicular collision patch at the same support point. Useful if the helper orientation is wrong,
-- but too generous for final gameplay. Leave false unless the helper is visibly sideways when using tcb.
M.USE_CROSS_HELPER = false

-- Control mutation. Defaults preserve exact sneak/crouch-walk movement.
M.FORCE_WALK = false
M.ZERO_STRAFE = false
M.BLOCK_JUMP = false

-- Broad heuristics for fallback matches. Known target IDs bypass these.
M.USE_BBOX_FILTER_FOR_FALLBACKS = false
M.MIN_FALLBACK_LENGTH = 64
M.MAX_FALLBACK_WIDTH = 80
M.MAX_FALLBACK_HEIGHT = 128

-- Detection fallback toggles.
M.RECORD_ENABLE_NAME_FALLBACKS = true
M.TEXTURE_ENABLE_NAME_FALLBACKS = true

-- Extra printed misses are useful only for the texture build; harmless here.
M.PRINT_TEXTURE_MISSES = false

return M
