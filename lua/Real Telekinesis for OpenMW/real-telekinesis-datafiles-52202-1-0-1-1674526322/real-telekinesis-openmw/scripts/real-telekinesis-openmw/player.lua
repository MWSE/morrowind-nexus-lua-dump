local MOD_VERSION = "1.0.1"
-- ==============================================
-- IMPORTS
-- ==============================================
-- ALL SCRIPTS
local Interfaces = require('openmw.interfaces')
local Util = require('openmw.util')
local Core = require('openmw.core')
local Types = require('openmw.types')
local Async = require('openmw.async')
local Storage = require('openmw.storage')
-- PLAYER SCRIPTS ONLY
local Camera = require('openmw.camera')
local Ui = require('openmw.ui')
local Input = require('openmw.input')
-- LOCAL SCRIPTS ONLY
local Nearby = require('openmw.nearby')
local Self = require('openmw.self')

-- ==============================================
-- IMPORTED CONSTANTS
-- ==============================================
local ANY_PHY = Nearby.COLLISION_TYPE.AnyPhysical
local ACTOR = Nearby.COLLISION_TYPE.Actor
local DESTRUCTION_SKILL = Types.NPC.stats.skills.destruction(Self.object)
local MYSTICISM_SKILL = Types.NPC.stats.skills.mysticism(Self.object)

local MYSTICISM_SKILL_NAMES = { "Mysticism", "Telekinetic Force Powers" }
local DESTRUCTION_SKILL_NAMES = { "Destruction", "Dark Side Powers" }

-- ==============================================
-- SCRIPT CONFIGURABLE CONSTANTS (BEST TO LEAVE AS-IS)
-- ==============================================
local PUSH_Z_OFFSET = 5             -- Offset from the ground, to prevent collision with ground
local GRAB_Z_OFFSET = 5             -- Offset from the ground, to prevent collision with ground
local PULL_Z_OFFSET = 10            -- Offset from the ground, to prevent collision with ground
local ITEM_Z_OFFSET = 0             -- Items can be very flat so a low / zero z offset is optimal
local PULL_INITIAL_Z_OFFSET = 30    -- Offset from the ground, to prevent collision with ground
local BUMP_OFFSET = 25              -- Offset to prevent teleports from pushing objects through wall / floor
local PULL_SMOOTH = 0.03            -- Base number to put together with smoothing
local MIN_PUSH_Z = 0.1              -- Alwys push target off the ground if possible to avoid ground collision
local STUCK_DIST_THRESHOLD = 0.0001 -- Object has to move more than this distance per tick or sequence ends
local STUCK_COUNT_THRESHOLD = 7     -- Number of frames the object has been stuck before stopping ragdoll
local MAX_TIMEOUT = 8               -- Maximum ragdoll duration (seconds) for fail-safe purposes
local PLAYER_WIDTH = 100            -- For camera purposes, if in 3rd person, specify distance to "ignore" player
local COLLISION_ATTEMPTS = 100      -- Maximum collision attempts to prevent possible inf loops
local DMG_MOVE_THRESHOLD = 100      -- Must've travelled this much distance or no damage, or:
local DMG_DISP_THRESHOLD = 120      -- Must've travelled at this speed or no damage
local GRAB_DMG_MOVE_THRESHOLD = 200 -- Must've travelled this much distance or no damage
local GRAB_CRUSH_RAND_ROTA = 0.0001 -- Limits for crush effect
local ITEM_HALF_WIDTH = 20          -- Bounding box data for items
local ITEM_HEIGHT = 20              -- Bounding box data for items
local PREV_POS_UPDATE_DT = 50/1000  -- Time to update prevPos
local BOUNDING_DATA_PTS = 6         -- Number of points that comprises of a bounding box
local SKILL_LEVEL_RATE = 1/100      -- Rate of levelling, doesn't work
local ITEM_ROTA_SPD = 0.8           -- You spin me right round right round
local ITEM_ROTA_REQ = 15            -- Number of times to spin before a hit is considered a hit
local CUM_AVG_N = 15                -- Number of frames for cumulative average for grab data V
local ANGLE_THRESHOLD_MAX = 4       -- Angle threshold for multi target

local M_TO_UNITS = 400              -- Gut-feel conversion from meters to... whatever units Morrowind uses for distance
local TERMINAL_VELOCITY = 53 * M_TO_UNITS   -- Maximum downward velocity by gravity. Super basic physics ok
local GRAVITY_MS2 = 9.80665 * M_TO_UNITS    -- The power of Earth's love

-- ==============================================
-- ADVANCED USER CONFIGURABLE CONSTANTS
-- ==============================================
Interfaces.Settings.registerPage { key = "RealTelekinesisPg", l10n = "RealTelekinesis", name = "Real Telekinesis", description = "Real Telekinesis Lua Mod v" .. MOD_VERSION .. ". After modifying settings, reload the game or run `reloadlua` in the console to apply them." }
Interfaces.Settings.registerGroup { 
    key = "2_REALTK_SETTINGS", 
    page = "RealTelekinesisPg",
    l10n = "RealTelekinesis", 
    name = "Advanced Settings", 
    description = "Best to leave as-is",
    permanentStorage = true,
    settings = {
        { key = "DMG_MULT_SPD", renderer = "number", name = "DMG_MULT_SPD", default = 0.6, description = 'Damage = spd/s * this multiplier. Usual is 80-100' },
        { key = "DMG_MULT_DIST", renderer = "number", name = "DMG_MULT_DIST", default = 0.03, description = 'Damage = distance travelled * this multiplier. Usual is 1k to 6k' },
        { key = "DMG_MULT_GRABBED", renderer = "number", name = "DMG_MULT_GRABBED", default = 0.25, description = 'Damage multiplier when smacking a grabbed target against environment' },
        { key = "DMG_CRUSH", renderer = "number", name = "DMG_CRUSH", default = 100, description = 'Damaage per second when subjecting target to telekinetic whirlwind' },
        { key = "BASE_SKILL_RANGE", renderer = "number", name = "BASE_SKILL_RANGE", default = 500, description = 'Distance whereby telekinesis is effective' },
        { key = "SKILL_RANGE_PER_LV", renderer = "number", name = "SKILL_RANGE_PER_LV", default = 20, description = 'Distance * mysticism level' },
        { key = "PUSH_SPD", renderer = "number", name = "PUSH_SPD", default = 5000, description = 'Speed per second to push targets at' },
        { key = "PULL_OFFSET", renderer = "number", name = "PULL_OFFSET", default = 100, description = 'Distance from player to pull target to' },
        { key = "PULL_SPD", renderer = "number", name = "PULL_SPD", default = 10000, description = 'Speed per second to pull targets at' },
        { key = "PULL_WATERSLOW", renderer = "number", name = "PULL_WATERSLOW", default = 0.2, description = 'Factor by which water will slow an actor moving through water down. Currently bugged' },
        { key = "LIFT_SPD", renderer = "number", name = "LIFT_SPD", default = 2500, description = 'Speed per second to lift targets' },
        { key = "GRAB_MOVE_SPD", renderer = "number", name = "GRAB_MOVE_SPD", default = 2000, description = 'Speed per second to push / pull a grabbed object' },
        { key = "GRAB_MIN_DIST", renderer = "number", name = "GRAB_MIN_DIST", default = 50, description = 'Closest distance you can pull an object to you' },
        { key = "GRAB_THROW_MULT", renderer = "number", name = "GRAB_THROW_MULT", default = 5, description = 'Multiply vector of grab throw by this factor' },
        { key = "GRAB_THROW_DIST_MULT", renderer = "number", name = "GRAB_THROW_DIST_MULT", default = 5000, description = 'Multiply vector of grab throw by this factor / distance' },
        { key = "GRAB_THROW_MULT_MAX", renderer = "number", name = "GRAB_THROW_MULT_MAX", default = 25, description = 'Maximum speed multiplier at which you can throw a grabbed object' },
        { key = "GRAB_THROW_MAX_SPD", renderer = "number", name = "GRAB_THROW_MAX_SPD", default = 5000, description = 'Maximum speed at which you can throw a grabbed object' },
        { key = "DETACH_CAM_MAG", renderer = "number", name = "DETACH_CAM_MAG", default = 1, description = 'Magnitude to move camera when grabbing object' },
        { key = "DETACH_CAM_SENS", renderer = "number", name = "DETACH_CAM_SENS", default = 0.01, description = 'Camera Sensitivity' },
        { key = "DELAY_CAM_DIST", renderer = "number", name = "DELAY_CAM_DIST", default = 150, description = 'Camera distance from head' },
        { key = "DELAY_CAM_Z_OFFSET", renderer = "number", name = "DELAY_CAM_Z_OFFSET", default = 150, description = 'Camera distance from ground' },
        { key = "DELAY_CAM_POS_SMOOTHING", renderer = "number", name = "DELAY_CAM_POS_SMOOTHING", default = 4.5, description = 'Smoothing for position' },
        { key = "DELAY_CAM_YAW_SMOOTHING", renderer = "number", name = "DELAY_CAM_YAW_SMOOTHING", default = 5.5, description = 'Smoothing for yaw' },
        { key = "DELAY_CAM_PITCH_SMOOTHING", renderer = "number", name = "DELAY_CAM_PITCH_SMOOTHING", default = 5.5, description = 'Smoothing for pitch' },
        { key = "CROSSHAIR_SENS", renderer = "number", name = "CROSSHAIR_SENS", default = 0.2, description = 'Sensitivity for crosshair. Note that there may be a disconnect between actual angle & crosshair position' },
        { key = "CROSSHAIR_PITCH_ALIGN", renderer = "number", name = "CROSSHAIR_PITCH_ALIGN", default = 0.17, description = 'Value for aligning crosshair sens and actual pitch' },
        { key = "CROSSHAIR_YAW_ALIGN", renderer = "number", name = "CROSSHAIR_YAW_ALIGN", default = 0.5, description = 'Value for aligning crosshair sens and actual yaw' },
        { key = "CONVERGENCE_FACTOR", renderer = "number", name = "CONVERGENCE_FACTOR", default = 0.00, description = 'Shift crosshair slightly downwards to account for height difference' },
        { key = "WEAPON_DAMAGE_MAG", renderer = "number", name = "WEAPON_DAMAGE_MAG", default = 1, description = 'Spin damage' },
        { key = "DEFAULT_ITEM_DAMAGE", renderer = "number", name = "DEFAULT_ITEM_DAMAGE", default = 3, description = 'Collision damage for items that are not weapons' },
        { key = "DEFAULT_ITEM_DAMAGE_CLOTH", renderer = "number", name = "DEFAULT_ITEM_DAMAGE_CLOTH", default = 1, description = 'Collision damage for items that are not weapons' },
        { key = "DEFAULT_ITEM_DAMAGE_ARMOR", renderer = "number", name = "DEFAULT_ITEM_DAMAGE_ARMOR", default = 10, description = 'Collision damage for items that are not weapons' },
        { key = "DEFAULT_ITEM_DAMAGE_WEAPON", renderer = "number", name = "DEFAULT_ITEM_DAMAGE_WEAPON", default = 8, description = 'Collision damage for items that are not weapons' },
        { key = "ANGLE_THRESHOLD_SINGLE_T", renderer = "number", name = "ANGLE_THRESHOLD_SINGLE_T", default = 0.1, description = 'Angle threshold for single target' },
        { key = "ANGLE_THRESHOLD_MULTI_T", renderer = "number", name = "ANGLE_THRESHOLD_MULTI_T", default = 0.8, description = 'Angle threshold for multi target' },
        { key = "TIER_TEXT_X_OFFSET", renderer = "number", name = "TIER_TEXT_X_OFFSET", default = 0, description = 'Horizontal offset for the displayed text when charging abilities' },
        { key = "TIER_TEXT_Y_OFFSET", renderer = "number", name = "TIER_TEXT_Y_OFFSET", default = 80, description = 'Vertical offset for the displayed text when charging abilities' },
        { key = "TIER_TEXT_SIZE", renderer = "number", name = "TIER_TEXT_SIZE", default = 16, description = 'Font size for the 3 lines when charging abilities' },
        { key = "COST_MYSTICISM_FACTOR", renderer = "number", name = "COST_MYSTICISM_FACTOR", default = 2.5, description = 'Mana cost is reduced by Mysticism / this factor' },
        { key = "LOWEST_COST", renderer = "number", name = "LOWEST_COST", default = 3, description = 'Lowest mana cost usage' },
        { key = "GRAB_ACTOR_COST", renderer = "number", name = "GRAB_ACTOR_COST", default = 70, description = 'Cost / s when grabbing a NPC / actor' },
        { key = "CRUSH_COST", renderer = "number", name = "CRUSH_COST", default = 20, description = 'Cost / s when whirlwinding an enemy while grabbing them' },
        { key = "GRAB_ITEM_COST", renderer = "number", name = "GRAB_ITEM_COST", default = 30, description = 'Cost / s when grabbing an object' },
        { key = "COMBO_REDUCTION", renderer = "number", name = "COMBO_REDUCTION", default = 0.5, description = 'Cost reduction when performing a combo (something is currently being affected by telekinesis)' }
    }
}
local advancedSettings = Storage.playerSection("2_REALTK_SETTINGS")
local DMG_MULT_SPD = advancedSettings:get("DMG_MULT_SPD")               -- Damage= spd/s * this multiplier. Usual is 80-100
local DMG_MULT_DIST = advancedSettings:get("DMG_MULT_DIST")             -- Damage= distance travelled * this multiplier. Usual is 1k to 6k
local DMG_MULT_GRABBED = advancedSettings:get("DMG_MULT_GRABBED")       -- Damage multiplier when smacking a grabbed target against environment
local DMG_CRUSH = advancedSettings:get("DMG_CRUSH")                     -- Damaage per second when subjecting target to telekinetic whirlwind
local BASE_SKILL_RANGE = advancedSettings:get("BASE_SKILL_RANGE")       -- Distance whereby telekinesis is effective
local SKILL_RANGE_PER_LV = advancedSettings:get("SKILL_RANGE_PER_LV")   -- Distance * mysticism level
local PUSH_SPD = advancedSettings:get("PUSH_SPD")                       -- Speed per second to push targets at
local PULL_OFFSET = advancedSettings:get("PULL_OFFSET")                 -- Distance from player to pull target to
local PULL_SPD = advancedSettings:get("PULL_SPD")                       -- Speed per second to pull targets at
local PULL_WATERSLOW = advancedSettings:get("PULL_WATERSLOW")           -- Factor by which water will slow an actor moving through water down. Currently bugged
local LIFT_SPD = advancedSettings:get("LIFT_SPD")                       -- Speed per second to lift targets
local GRAB_MOVE_SPD = advancedSettings:get("GRAB_MOVE_SPD")             -- Speed per second to push / pull a grabbed object
local GRAB_MIN_DIST = advancedSettings:get("GRAB_MIN_DIST")             -- Closest distance you can pull an object to you
local GRAB_THROW_MULT = advancedSettings:get("GRAB_THROW_MULT")         -- Multiply vector of grab throw by this factor
local GRAB_THROW_DIST_MULT = advancedSettings:get("GRAB_THROW_DIST_MULT") -- Multiply vector of grab throw by this factor / distance
local GRAB_THROW_MULT_MAX = advancedSettings:get("GRAB_THROW_MULT_MAX")   -- Maximum speed multiplier at which you can throw a grabbed object
local GRAB_THROW_MAX_SPD = advancedSettings:get("GRAB_THROW_MAX_SPD")   -- Maximum speed at which you can throw a grabbed object
local DETACH_CAM_MAG = advancedSettings:get("DETACH_CAM_MAG")           -- Magnitude to move camera when grabbing object
local DETACH_CAM_SENS = advancedSettings:get("DETACH_CAM_SENS")         -- Camera Sensitivity
local DELAY_CAM_DIST = advancedSettings:get("DELAY_CAM_DIST")           -- Camera distance from head
local DELAY_CAM_Z_OFFSET = advancedSettings:get("DELAY_CAM_Z_OFFSET")   -- Camera distance from ground
local DELAY_CAM_POS_SMOOTHING = advancedSettings:get("DELAY_CAM_POS_SMOOTHING") -- Smoothing for position
local DELAY_CAM_YAW_SMOOTHING = advancedSettings:get("DELAY_CAM_YAW_SMOOTHING") -- Smoothing for yaw
local DELAY_CAM_PITCH_SMOOTHING = advancedSettings:get("DELAY_CAM_PITCH_SMOOTHING")     -- Smoothing for pitch
local CROSSHAIR_SENS = advancedSettings:get("CROSSHAIR_SENS")                   -- Sensitivity for crosshair. Note that there may be a disconnect between actual angle & crosshair position
local CROSSHAIR_PITCH_ALIGN = advancedSettings:get("CROSSHAIR_PITCH_ALIGN")     -- Value for aligning crosshair sens and actual pitch
local CROSSHAIR_YAW_ALIGN = advancedSettings:get("CROSSHAIR_YAW_ALIGN")         -- Value for aligning crosshair sens and actual yaw
local CONVERGENCE_FACTOR = advancedSettings:get("CONVERGENCE_FACTOR")           -- Shift crosshair slightly downwards to account for height difference
local WEAPON_DAMAGE_MAG = advancedSettings:get("WEAPON_DAMAGE_MAG")             -- Spin damage
local DEFAULT_ITEM_DAMAGE = advancedSettings:get("DEFAULT_ITEM_DAMAGE")         -- Damage for items that aren't weapons
local DEFAULT_ITEM_DAMAGE_CLOTH = advancedSettings:get("DEFAULT_ITEM_DAMAGE_CLOTH")     -- Damage for items that aren't weapons
local DEFAULT_ITEM_DAMAGE_ARMOR = advancedSettings:get("DEFAULT_ITEM_DAMAGE_ARMOR")     -- Damage for items that aren't weapons
local DEFAULT_ITEM_DAMAGE_WEAPON = advancedSettings:get("DEFAULT_ITEM_DAMAGE_WEAPON")   -- Damage for items that aren't weapons
local ANGLE_THRESHOLD_SINGLE_T = advancedSettings:get("ANGLE_THRESHOLD_SINGLE_T")       -- Angle threshold for single target
local ANGLE_THRESHOLD_MULTI_T = advancedSettings:get("ANGLE_THRESHOLD_MULTI_T")         -- Angle threshold for multi target
local TIER_TEXT_X_OFFSET = advancedSettings:get("TIER_TEXT_X_OFFSET")                   -- Horizontal offset for the displayed text when charging abilities
local TIER_TEXT_Y_OFFSET = advancedSettings:get("TIER_TEXT_Y_OFFSET")                   -- Vertical offset for the displayed text when charging abilities
local BASE_TIER_TEXT_SIZE = advancedSettings:get("TIER_TEXT_SIZE")              -- Font size for the 3 lines when charging abilities
local TIER_TEXT_SIZE = { math.floor(BASE_TIER_TEXT_SIZE/2*3), BASE_TIER_TEXT_SIZE, BASE_TIER_TEXT_SIZE }
local COST_MYSTICISM_FACTOR = advancedSettings:get("COST_MYSTICISM_FACTOR")     -- Mana cost is reduced by Mysticism / this factor
local LOWEST_COST = advancedSettings:get("LOWEST_COST")                         -- Lowest mana cost usage
local GRAB_ACTOR_COST = advancedSettings:get("GRAB_ACTOR_COST")                 -- Cost / s when grabbing a NPC / actor
local CRUSH_COST = advancedSettings:get("CRUSH_COST")                           -- Cost / s when whirlwinding an enemy while grabbing them
local GRAB_ITEM_COST = advancedSettings:get("GRAB_ITEM_COST")                   -- Cost / s when grabbing an object
local COMBO_REDUCTION = advancedSettings:get("COMBO_REDUCTION")                   -- Cost reduction when performing a combo (something is currently being affected by telekinesis)

-- ==============================================
-- BASIC USER CONFIGURABLE CONSTANTS SETUP
-- ==============================================
Interfaces.Settings.registerGroup { 
    key = "1_REALTK_SETTINGS", 
    page = "RealTelekinesisPg",
    l10n = "RealTelekinesis", 
    name = "Basic Settings", 
    description = "",
    permanentStorage = true,
    settings = {
        { key = "GRAB_KEY", renderer = "textLine", name = "GRAB_KEY", default = 'g', description = 'Keybinding for grab (lower-case)'},
        { key = "PUSH_KEY", renderer = "textLine", name = "PUSH_KEY", default = 'z', description = 'Keybinding for push (lower-case)'},
        { key = "PULL_KEY", renderer = "textLine", name = "PULL_KEY", default = 'x', description = 'Keybinding for pull (lower-case)'},
        { key = "LIFT_KEY", renderer = "textLine", name = "LIFT_KEY", default = 'c', description = 'Keybinding for lift (lower-case)'},
        { key = "DELAY_CAMERA_KEY", renderer = "textLine", name = "DELAY_CAMERA_KEY", default = 'v', description = 'Keybinding for "Jedi Academy Camera" (lower-case)'},
        { key = "TELEKINETIC_TEXT", renderer = "textLine", name = "TELEKINETIC_TEXT", default = "Telekinetic", description = 'Displayed text when using abilities (e.g. "Telekinetic" push). Replace with "Force" if playing Starwind'},
        { key = "USE_STARWIND_SKILL_NAMES", renderer = "checkbox", name = "USE_STARWIND_SKILL_NAMES", default = false, description = 'Displayed text when levelling up (e.g. "Dark Side Powers" instead of "Destruction")'},
        { key = "ENABLE_MAGICKA_COST", renderer = "checkbox", name = "ENABLE_MAGICKA_COST", default = true , description = 'Disable for unlimited power'},
        { key = "RESTRICT_BY_LEVEL", renderer = "checkbox", name = "RESTRICT_BY_LEVEL", default = true , description = 'Enforce level restriction when using abilities'}
    }
}
local basicSettings = Storage.playerSection("1_REALTK_SETTINGS")
local GRAB_KEY = basicSettings:get("GRAB_KEY")                             -- Keybinding for grab (lower-case)
local PUSH_KEY = basicSettings:get("PUSH_KEY")                             -- Keybinding for push (lower-case)
local PULL_KEY = basicSettings:get("PULL_KEY")                             -- Keybinding for pull (lower-case)
local LIFT_KEY = basicSettings:get("LIFT_KEY")                             -- Keybinding for lift (lower-case)
local DELAY_CAMERA_KEY = basicSettings:get("DELAY_CAMERA_KEY")             -- Keybinding for "Jedi Academy Camera" (lower-case)
local TELEKINETIC_TEXT = basicSettings:get("TELEKINETIC_TEXT")             -- Displayed text when using abilities (e.g. "Telekinetic" push). Replace with "Force" if playing Starwind
local USE_STARWIND_SKILL_NAMES = basicSettings:get("USE_STARWIND_SKILL_NAMES") -- Displayed text when levelling up (e.g. "Dark Side Powers" instead of "Destruction")
local ENABLE_MAGICKA_COST = basicSettings:get("ENABLE_MAGICKA_COST")       -- Disable for unlimited power
local RESTRICT_BY_LEVEL = basicSettings:get("RESTRICT_BY_LEVEL")           -- Enforce level restriction when using abilities

-- TIER DATA
local PUSH_TIER_TYPE = 1
local PUSH_TIERS = {
    { name = TELEKINETIC_TEXT .. " Push (Single Target)", baseCost = 30, radianThreshold = ANGLE_THRESHOLD_SINGLE_T, singleTarget = true,  chargeTime = 0.2, speedMult = 1, knockdown = true, statIncrMult = 1 },
    { name = "Wide " .. TELEKINETIC_TEXT .. " Push (Cone AOE)", baseCost = 70, radianThreshold = ANGLE_THRESHOLD_MULTI_T,singleTarget = false, chargeTime = 1.5, speedMult = 1.25, knockdown = true, statIncrMult = 3 },
    { name = TELEKINETIC_TEXT .. " Wave (Centred AOE)", baseCost = 100, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 2, speedMult = 2, knockdown = true, statIncrMult = 4 },
    { name = TELEKINETIC_TEXT .. " Explosion (Pinpoint AOE)", baseCost = 110, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 1.5, speedMult = 1.5, yOffset = 1000, knockdown = true, statIncrMult = 6 }
}
local PULL_TIER_TYPE = 2
local PULL_TIERS = {
    { name = TELEKINETIC_TEXT .. " Pull (Single Target)", baseCost = 20, radianThreshold = ANGLE_THRESHOLD_SINGLE_T, singleTarget = true,  chargeTime = 0.2, speedMult = 1, knockdown = false, statIncrMult = 1 },
    { name = "Wide " .. TELEKINETIC_TEXT .. " Pull (Cone AOE)", baseCost = 50, radianThreshold = ANGLE_THRESHOLD_MULTI_T, singleTarget = false, chargeTime = 1.5, speedMult = 1.25, knockdown = true, statIncrMult = 3 },
    { name = TELEKINETIC_TEXT .. " Vortex (Centred AOE)",    baseCost = 80, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 2, speedMult = 2, knockdown = true, statIncrMult = 4 },
    { name = TELEKINETIC_TEXT .. " Black Hole (Pinpoint AOE)", baseCost = 300, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 4, speedMult = 0.15, yOffset = 1000, overrideOffsetV = true, contToTime = 7, knockdown = true, statIncrMult = 8 }
}
local LIFT_TIER_TYPE = 3
local LIFT_TIERS = {
    { name = TELEKINETIC_TEXT .. " Lift (Single Target)", baseCost = 20, radianThreshold = ANGLE_THRESHOLD_SINGLE_T, singleTarget = true,  chargeTime = 0.2, speedMult = 1, knockdown = false, statIncrMult = 1 },
    { name = "Wide " .. TELEKINETIC_TEXT .. " Lift (Cone AOE)", baseCost = 70, radianThreshold = ANGLE_THRESHOLD_MULTI_T, singleTarget = false, chargeTime = 1.5, speedMult = 1.25, knockdown = false, statIncrMult = 3 },
    { name = TELEKINETIC_TEXT .. " Earthshatter (Centred AOE)", baseCost = 100, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 1.5, speedMult = 2, knockdown = true, statIncrMult = 4 },
    { name = TELEKINETIC_TEXT .. " Eruption (Centred AOE)", baseCost = 140, radianThreshold = ANGLE_THRESHOLD_MAX, singleTarget = false, chargeTime = 2, speedMult = 3, knockdown = true, statIncrMult = 6 }
}
--[[Tier data
    name:               string
    baseCost:           cost before mysticism offset.
    radianThreshold:    AOE angle
    singleTarget:       boolean to determine if it's AOE or not
    xchargeTime:        amount of time to progress to this tier
    speedMult:          vector speed multiplier
    yOffset:            optional. If set, offset vector origin (cam position) by that amount. Used for 4th tier spells
    overrideOffsetV:    optional. If set, override offsetted vector with a cam pos of said offset. Used to distinguish 4th tier black hole & 4th tier explosion.
                                    Main reason why there's a distinction is because pull needs to know the final absolute position while push just cares about the dir vector.
    knockdown
    statIncrMult
--]]

-- ==============================================
-- RESOURCES & TEXTURES
-- ==============================================
local xhairTexture = "Textures/tk_xhair.dds"
local texture1 = Ui.texture { path = xhairTexture }
local crosshair = Ui.create {
    layer = "HUD",
    type = Ui.TYPE.Image,
    size = Util.vector2(64, 64),
    props = {
        size = Util.vector2(64, 64),
        relativePosition = Util.vector2(0.5, 0.5),
        anchor = Util.vector2(0.5, 0.5),
        resource = texture1,
        visible = false,
        color = Util.color.rgb(1, 1, 1)
    }
}
-- Helper functions for manipulating the text Ui object
local function createText(xOffset, yOffset, textSize)
    return Ui.create {
        layer = "HUD",
        type = Ui.TYPE.Text,
        props = {
            relativePosition = Util.vector2(0.5, 0.5),
            anchor = Util.vector2(0.5, 0.5),
            position = Util.vector2(xOffset, yOffset),
            visible = true,
            text = "",
            textSize = textSize,
            textColor = Util.color.rgb(1, 1, 1)
        }
    }
end

-- ==============================================
-- SCRIPT LOCAL VARIABLES
-- ==============================================
local textBg = Ui.create {
    layer = "HUD",
    type = Ui.TYPE.Image,
    props = {
        size = Util.vector2(450, 32 + (TIER_TEXT_SIZE[1] + 8) + (TIER_TEXT_SIZE[2] + 8) + (TIER_TEXT_SIZE[3] + 8)),
        relativePosition = Util.vector2(0.5, 0.5),
        position = Util.vector2(TIER_TEXT_X_OFFSET, 30 + TIER_TEXT_Y_OFFSET),
        anchor = Util.vector2(0.5, 0.5),
        resource = Interfaces.MWUI.templates.boxTransparent.content[1].template.props.resource,
        visible = false,
        alpha = 0.7,
        color = Util.color.rgb(0, 0, 0)
    }
}
local textLine1 = createText(TIER_TEXT_X_OFFSET, TIER_TEXT_Y_OFFSET, TIER_TEXT_SIZE[1])
local textLine2 = createText(TIER_TEXT_X_OFFSET, TIER_TEXT_Y_OFFSET + TIER_TEXT_SIZE[1] + 8, TIER_TEXT_SIZE[2])
local textLine3 = createText(TIER_TEXT_X_OFFSET, TIER_TEXT_Y_OFFSET + (TIER_TEXT_SIZE[1] + 8) + (TIER_TEXT_SIZE[2] + 8), TIER_TEXT_SIZE[3])
local grabbedObject = nil
local delayCamData = {
    active = false,
    actualYaw = nil,
    actualPitch = nil,
    simulatedYaw = nil,
    simulatedPitch = nil
}
local grabData = {}
function resetGrabData()
    grabData.boundingData = nil
    grabData.release = false            -- Flag to set when releasing, so that the object is properly released on the next update
    grabData.isPulling = false          -- Flags to track when the button is pressed
    grabData.isPushing = false          -- Flags to track when the button is pressed
    grabData.crushDmg = 0               -- Counter to track how much damage you crushed enemy for
    grabData.v = nil                    -- Directional vector that object is moving in, not to be confused with camera direction.
                                        -- Note that for simplicity, the tracking is immediate; v here is simply to track user movement for releasing the object.
    grabData.cumAvgV = Util.vector3(0,0,0) -- Cumulative average v for throwing objects
    grabData.distance = nil             -- Current distance between camera and grabbed object. Used for tracking position
    grabData.prevPos = nil
    grabData.travelled = 0              -- Travelled distance by object,
    grabData.spunRadians = 0            -- Spun radians (for item damage tracking)
    grabData.maxRange = BASE_SKILL_RANGE-- Max range
    grabData.spinDamage = nil           -- Spin damage when you bring an item close to a target

    grabbedObject = nil
end
resetGrabData()

local ragDollData = {}
--[[
    When adding objects to this array, each object in this array follows this format: {
        Name        Type            Descript
        target      GameObject      
        boundingData
        seqs        Sequence[]      Array of Sequences in inverted order; the last occurs first.
        contOnHit   boolean         Optional: Continue animating on colliding with a physical object.
        
        Helper params for the ragdoll logic to work properly
        seqInit     boolean         For the updater to track if these params have been initialized
        origDist    int             There to smooth animation when using targetP
        prevPos     Vector 3        
        dtPrevPos   float           dt since last prevPos update.
        tElapsed    float           Time elapsed
        stuckCount  int             Counter for number of frames item has been stuck
        travelled   float           Distance travelled
    }

    A Sequence comprises of: {
        v           Vector3         Directional vector. Either v or targetP must be set.
        targetP     Vector3         Target position; if set, v is ignored and object is tweened to position instead.
        spd         float           Speed for targetP.
        smoothing   float           Multiplier applied to dist / origDist
        applyG      boolean         Optional: If set, apply gravity to v.
        timeout     float           Optional: Maximum time elapsed (seconds) until terminating sequence
        waterSlow   float           Optional: If set, continually reduce speed by this factor while in water.
        contToTime  boolean         Optional: Continue until timeout.
        contOnHit   boolean         Optional: Continue on hit. Otherwise, the sequence will be removed immediately.
    }

    Implicit rules:
    1. Collisions wlll stop sequences / the entire animating logic by default.
    2. If spd drops to zero or less than 0, or object stops moving (tracked by prevPos), sequence is removed.
    3. Gravity no longer applies when actor is in water
--]]

-- Tiers
local currChargingData = nil
local function resetChargingData()
    currChargingData = {
    type = nil,
    list = nil,
    tier = 0,
    holdTime = 0
}
end
resetChargingData()

-- ==============================================
-- GENERIC FUNCTIONS
-- ==============================================
-- Safely rm items from an array table while iterating
-- For your fnKeep, return true if keeping element, otherwise false
local function ArrayIter(t, fnKeep)
    local j, n = 1, #t
    for i=1,n do
        if (fnKeep(t,i,j)) then
            if(i~=j) then 
                t[j] = t[i];
            end
            j = j+1;
        end
    end
    table.move(t,n+1,n+n-j+1,j)
    return t;
end

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

-- ----------------------------------------------
-- MISC FUNCTIONS
-- ----------------------------------------------
-- Simplified Lodash _.get()
local function _get(o, ...)
    local r = o
    for i, v in ipairs(arg) do
        if r == nil then return r end
        r = r[v]
    end
    return r
end

local function anglesToV(pitch, yaw) 
    local xzLen = math.cos(pitch)
    return Util.vector3(
        xzLen * math.sin(yaw),  -- x
        xzLen * math.cos(yaw),  -- y
        math.sin(pitch)         -- z
    )
end
local function round(x) return math.floor(0.5 + x) end
local function addToVector3(v, xDiff, yDiff, zDiff) return Util.vector3(v.x + xDiff, v.y + yDiff, v.z + zDiff) end
local function addCToVector3(v, c) return Util.vector3(v.x + c, v.y + c, v.z + c) end
local function getLevel(actor) return Types.Actor.stats.level(actor).current end
local function getHP(actor) return Types.Actor.stats.dynamic.health(actor).current end
local function useMP(mp)
    if not ENABLE_MAGICKA_COST then return true end
    local magicka = Types.Actor.stats.dynamic.magicka(Self.object)
    if magicka.current >= mp then
        Self.object:sendEvent('TK_UseMagicka', { amount=mp }) 
        return true
    end
    return false
end
local function isAlive(actor) return getHP(actor) > 0 end
local function getName(o)
    if not o then return "Target" end
    if o.type == Types.NPC then return Types.NPC.record(o).name end
    if o.type == Types.Creature then return Types.Creature.record(o).name end
    return "Target"
end
local function isX(obj, type) return obj.type and obj.type == type end
local function isSelf(t) return t == Self.object end
local function isItem(t) return t and t.type and t.type.baseType == Types.Item end
local function isActor(t) return t and t.type and t.type.baseType == Types.Actor end
local function rmFromRagDollData(t) ArrayIter(ragDollData, function(ragDollData, i, j) return ragDollData[i].target ~= t end) end
local function isGrabCrushing() return grabData.isPulling and grabData.isPushing end
local function radiansBetween(v1, v2)             
    return math.acos(
        math.max(-1, 
            math.min(1, 
                v1:dot(v2) / (v1:length() * v2:length())
            )
        )
    )
end
local function updateTxt(t1, t2, t3)
    if t1 or t2 or t3 then textBg.layout.props.visible = true
    else textBg.layout.props.visible = false end
    textBg:update()
    textLine1.layout.props.text = t1
    textLine1:update()
    textLine2.layout.props.text = t2
    textLine2:update()
    textLine3.layout.props.text = t3
    textLine3:update()
end
local function manaCost(cost) return round(math.max(LOWEST_COST, cost - MYSTICISM_SKILL.modified / COST_MYSTICISM_FACTOR) * (#ragDollData and COMBO_REDUCTION or 1)) end
local function manaCostDt(cost, dt) return dt * math.max(LOWEST_COST, cost - MYSTICISM_SKILL.modified / COST_MYSTICISM_FACTOR) end

-- ----------------------------------------------
-- FUNCTIONS THAT DON'T WORK BECAUSE THE API DOESN'T WORK
-- ----------------------------------------------
local function isInWater(t) return false and isActor(t) and Types.Actor.isSwimming(t) end -- isSwimming doesn't work
local function increaseSkill(skillStat, m)
    local skillNameIdx = USE_STARWIND_SKILL_NAMES and 2 or 1
    m = m or 1
    if skillStat == MYSTICISM_SKILL then Self.object:sendEvent('TK_LevelMysticism', { amount = SKILL_LEVEL_RATE * m, skillName = MYSTICISM_SKILL_NAMES[skillNameIdx] })
    elseif skillStat == DESTRUCTION_SKILL then Self.object:sendEvent('TK_LevelDestruction', {amount = SKILL_LEVEL_RATE * m, skillName = DESTRUCTION_SKILL_NAMES[skillNameIdx] }) end
end

-- ----------------------------------------------
-- ACCESS RESTRICTION FUNCTIONS
-- ----------------------------------------------
local function isGrabbable(t) return isItem(t) or isActor(t) end
local function lvlDiff(target)
    if isActor(target) then
        return getLevel(Self.object) - getLevel(target)
    else
        -- Always allow user to pick up items
        return 1
    end
end

-- Return true if level check succeeded, else fail
local function tryDoAction(target, actionText, quietMode, statIncreaseMultiplier)
    -- If target is nil, return "nothing in range"
    if not target then
        if not quietMode then Ui.showMessage("Nothing in range to " .. actionText .. ".") end
        return
    end

    -- Level check
    local lvlD = lvlDiff(target)
    if lvlD <= 0 then
        if not quietMode then
            Ui.showMessage("You are " .. (lvlD + 1) .. " levels too low to " .. actionText .. " " .. getName(target))
        end
        return false
    end

    increaseSkill(MYSTICISM_SKILL, statIncreaseMultiplier)
    return true
end

local function getTelekinesisRange()
    return Camera.getThirdPersonDistance() + BASE_SKILL_RANGE + MYSTICISM_SKILL.modified * SKILL_RANGE_PER_LV
end

local function tryStartGrab(target)
    if tryDoAction(target, "grab", nil, 1) then
        grabbedObject = target
        Ui.showMessage("Grab Object!")
    end
end


local function tryStartCrush()
    if isGrabCrushing() and isActor(grabbedObject) then
        Ui.showMessage("You spin your target in a " .. TELEKINETIC_TEXT .. " Whirlwind!")
    end
end

local function tryStopCrush()
    if grabData.isPulling ~= grabData.isPushing and isActor(grabbedObject) then
        Ui.showMessage("You hurt your target for " .. math.floor(grabData.crushDmg) .. " damage!")
        grabData.crushDmg = 0
        increaseSkill(DESTRUCTION_SKILL, nil)
    end
end

-- ----------------------------------------------
-- CAMERA FUNCTIONS
-- ----------------------------------------------

local function getCameraDirData(camData)
    local pos = Camera.getPosition()
    local pitch, yaw
    if camData and camData.active and camData.simulatedPitch and camData.simulatedYaw then
        pitch = -camData.simulatedPitch
        yaw = camData.simulatedYaw
    else
        pitch = -(Camera.getPitch() + Camera.getExtraPitch())
        yaw = (Camera.getYaw() + Camera.getExtraYaw())
    end
    return pos, anglesToV(pitch, yaw)
end

-- If earlyterminate, Returns { hitObject = o }, vectorFromCamToObject. Otherwise returns a whole array of said results.
local function getAffectedObjects(threshold, earlyTerminate, yOffset)
    local camPos, camV = getCameraDirData(delayCamData)
    local simPos = camPos + camV * (yOffset or 0)
    local maxRange = getTelekinesisRange()
    local results = {}
    local groups = { Nearby.items, Nearby.actors }
    for i, group in ipairs(groups) do
        for j, o in ipairs(group) do
            local dirV = o.position - simPos
            if o ~= Self.object and dirV:length() <= maxRange then
                local r = radiansBetween(camV, dirV)
                -- print(o, r)
                if r < threshold then
                    if earlyTerminate then return { hitObject = o }, dirV end
                    table.insert(results, { hitObject = o, v = dirV:normalize() })
                end
            end
        end
    end
    if earlyTerminate then return {}, nil end
    return results
end

local function getObjInCrosshairs()
    local pos, v = getCameraDirData(delayCamData)
    local dist = getTelekinesisRange()
    local result = Nearby.castRenderingRay(pos, pos + v * dist)
    -- Ignore player if in 3rd person
    if result.hitObject and isSelf(result.hitObject) then
        result = Nearby.castRenderingRay(result.hitPos + v * PLAYER_WIDTH, result.hitPos + v * (PLAYER_WIDTH + dist))
    end

    -- Get approximated area. Note that this allows you to aim through walls, because we can't distinguish floor and wall
    if not isGrabbable(result.hitObject) then
        local res, v = getAffectedObjects(ANGLE_THRESHOLD_SINGLE_T, true, nil)
        return res, v
    end

    if isGrabbable(result.hitObject) then
        return result, v
    else
        return {}, v
    end
end

local function updateDelayCam(deltaSeconds)
    if delayCamData.active then
        -- Something outside set the camera mode to something else, disable delay cam
        if Camera.getMode() ~= Camera.MODE.Static then toggleDelayCam() end

        local playerPitch = Self.object.rotation.x
        local playerYaw = Self.object.rotation.z
        local v = anglesToV(playerPitch, playerYaw)
        local tmpPos = Self.object.position - v * DELAY_CAM_DIST
        local playerCamPos = Util.vector3(tmpPos.x, tmpPos.y, Self.object.position.z + DELAY_CAM_Z_OFFSET + v.z * DELAY_CAM_DIST)

        local currPos = Camera.getPosition()
        local currPitch = Camera.getPitch() + Camera.getExtraPitch()
        local currYaw = Camera.getYaw() + Camera.getExtraYaw()
        Camera.setStaticPosition(currPos + (playerCamPos - currPos) * (deltaSeconds * DELAY_CAM_POS_SMOOTHING))
        -- Yaw "loops around" so we need to factor that into the delta
        local reverseYaw = math.abs(playerYaw - currYaw) > math.pi and 1 or -1
        local yawDelta = playerYaw - currYaw
        if reverseYaw > 0 then
            yawDelta = yawDelta + (yawDelta > 0 and -2 or 2) * math.pi
        end
        Camera.setYaw(currYaw + yawDelta * deltaSeconds * DELAY_CAM_YAW_SMOOTHING)
        Camera.setPitch(currPitch + (playerPitch - currPitch) * deltaSeconds * DELAY_CAM_PITCH_SMOOTHING)

        -- Update crosshair
        local simYawOffset = delayCamData.hfov * yawDelta * CROSSHAIR_SENS
        local simPitchOffset = delayCamData.vfov * (playerPitch - currPitch)
        crosshair.layout.props.relativePosition = Util.vector2(
            math.min(math.max(0.5 + simYawOffset * CROSSHAIR_SENS, 0), 1),
            math.min(math.max(0.5 + CONVERGENCE_FACTOR + simPitchOffset * CROSSHAIR_SENS, 0), 1)
        )
        delayCamData.simulatedYaw = currYaw + simYawOffset * (CROSSHAIR_SENS + CROSSHAIR_YAW_ALIGN)
        delayCamData.simulatedPitch = currPitch + simPitchOffset * (CROSSHAIR_SENS + CROSSHAIR_PITCH_ALIGN) + CONVERGENCE_FACTOR
        -- print(simYawOffset, simPitchOffset)
        crosshair:update()
    end
end

local function toggleDelayCam()
    if not delayCamData.active then
        -- Don't interfere with cutscenes if possible
        if Camera.getMode() == Camera.MODE.Static then return end

        local pitch = Camera.getPitch() + Camera.getExtraPitch()
        local yaw = Camera.getYaw() + Camera.getExtraYaw()
        local screenDim = Ui.screenSize()
        local fov = Camera.getFieldOfView()
        delayCamData = {
            vfov        = fov,                              -- Constants, Vertical FOV
            hfov        = fov / screenDim.y * screenDim.x,  -- Constants, Horizontal FOV
            simulatedYaw = nil,
            simulatedPitch = nil
        }
        Camera.setMode(Camera.MODE.Static)
        crosshair.layout.props.visible = true
        Camera.showCrosshair(false)
        delayCamData.active = true
    else
        delayCamData.active = false
        crosshair.layout.props.visible = false
        crosshair:update()
        Camera.showCrosshair(true)
        -- Camera.getMode() doesn't return a number lmao so it's incompatible with setMode
        Camera.setMode(Camera.MODE.FirstPerson)
    end
end

-- ----------------------------------------------
-- DAMAGE FUNCTIONS
-- ----------------------------------------------
local function getSpinDamage(item)
    local dmg = 0
    if item.type == Types.Weapon then
        dmg = Types.Weapon.record(item).slashMaxDamage or DEFAULT_ITEM_DAMAGE_WEAPON
    elseif item.type == Types.Armor then
        -- Types.Armor.record doesn't exist
        -- dmg = Types.Armor.record(item).weight
        dmg = DEFAULT_ITEM_DAMAGE_ARMOR
    elseif item.type == Types.Clothing then
        dmg = DEFAULT_ITEM_DAMAGE_CLOTH
    elseif item.type == Types.Apparatus then
        dmg = Types.Apparatus.record(item).weight
    elseif item.type == Types.Book then
        dmg = Types.Book.record(item).weight
    elseif item.type == Types.Container then
        dmg = Types.Container.record(item).weight
    elseif item.type == Types.Ingredient then
        dmg = Types.Ingredient.record(item).weight
    elseif item.type == Types.Lockpick then
        dmg = Types.Lockpick.record(item).weight
    elseif item.type == Types.Potion then
        dmg = Types.Potion.record(item).weight
    elseif item.type == Types.Probe then
        dmg = Types.Probe.record(item).weight
    elseif item.type == Types.Repair then
        dmg = Types.Repair.record(item).weight
    end
    if not dmg then dmg = DEFAULT_ITEM_DAMAGE end
    return math.ceil(dmg * WEAPON_DAMAGE_MAG * (0.5 + MYSTICISM_SKILL.modified / 100))
end

local function dealDamage(target, dmg)
    -- Players or objects shouldn't get hurt
    if not isSelf(target) and dmg > 0 and isActor(target) then
        target:sendEvent('TK_Damage', { damage=dmg })
        if isAlive(target) then
            Ui.showMessage(getName(target) .. " got hurt for " .. dmg .. " damage!")
        else
            Ui.showMessage("Stop! " .. getName(target) .. " is already dead!")
        end
    end
end

-- ----------------------------------------------
-- COLLISION MANAGEMENT FUNCTIONS
-- ----------------------------------------------

-- Teleport with collision handling
-- Returns true (hitPos) if collision happened, otherwise false
local function tpWithCollision(target, boundingData, newPos, deltaSeconds, travelled, rotation)
    local pos = target.position
    local dirVector = (newPos - pos):normalize()
    local currVectorLen = (newPos - pos):length()
    -- print(currVectorLen)
    local validForDamage = (
        target == grabbedObject and (
            (isActor(target) and travelled > GRAB_DMG_MOVE_THRESHOLD) or
            (isItem(target) and travelled > ITEM_ROTA_REQ))
        ) or (
        target ~= grabbedObject and (travelled > DMG_MOVE_THRESHOLD or currVectorLen > DMG_DISP_THRESHOLD)
    )
    local maxDamage = 0
    local collidedWithSomething = false

    -- Iterate through all bounding points, pushing back the travelled distance as necessary
    for idx = 1, BOUNDING_DATA_PTS do
        local tmpPos = pos + boundingData.sideVectors[idx]
        local obstacle = Nearby.castRay(
            tmpPos,
            tmpPos + dirVector * math.max(0, currVectorLen),
            {
                collisionType = ANY_PHY,
                ignore = target
            }
        )
        if obstacle.hitPos and not isSelf(obstacle.hitObject) then
            collidedWithSomething = true

            -- Shorten the actual moved amount
            local f = currVectorLen
            currVectorLen = (tmpPos - obstacle.hitPos):length() - BUMP_OFFSET

            -- Deal damage to parties involved
            if validForDamage then
                local dmg = 0
                -- May be nil if item was pushed / pulled, in which case just use normal collision damage
                if grabData.spinDamage then
                    dmg = grabData.spinDamage
                else
                    dmg = (pos - newPos):length() * DMG_MULT_SPD + travelled * DMG_MULT_DIST
                    if target == grabbedObject then
                        dmg = dmg * DMG_MULT_GRABBED
                    end
                    dmg = math.floor(dmg)
                end
                -- print(maxDamage, dmg)
                maxDamage = math.max(maxDamage, dmg)
                if isActor(obstacle.hitObject) then
                    dealDamage(obstacle.hitObject, dmg)
                end
            end
        end
    end

    if maxDamage > 0 then
        dealDamage(target, maxDamage)
    end

    if collidedWithSomething then
        local actualNewPos = pos + dirVector * currVectorLen
        Core.sendGlobalEvent('TK_Teleport', { object = target, newPos = actualNewPos, rotation = rotation })
        return actualNewPos
    else
        Core.sendGlobalEvent('TK_Teleport', { object = target, newPos = newPos, rotation = rotation })
        return false
    end
end

-- Concept: castRay will impact on target's side, telling us its bounds. Doing so we can obtain an approximation of its bounding box.
-- From the origin, cast a ray outwards to the nearest object, then cast back at the target. The difference is the height / halfWidth depending on the direction.
-- Returns an object that follows this format:
--[[
    {
        halfWidth
        height
        sideVectors: An array of 6 vector3s for the midpoint of every side of the bounding cube. Add position to get their actual position during runtime.
    }
--]]
local function getBoundingData(target, zOffset)
    -- Items don't have collision
    local halfWidth = ITEM_HALF_WIDTH
    local height = ITEM_HEIGHT
    if isActor(target) then
        -- Assumption is that nothing is clipping through the target at time of measurement
        -- Assuming that no actor will be taller than 2000
        -- In the event of failure, just keep it simple & return the default bounds
        local MAX_ACTOR_RADIUS = 2000
        -- Get top
        local refPt = addToVector3(target.position, 0, 0, MAX_ACTOR_RADIUS)
        local ref = Nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, 0, 0, -1) end
        local bbPos = Nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            height = (bbPos - target.position):length()
        end

        -- Assumes that the that position is the midpoint of the width
        refPt = addToVector3(target.position, MAX_ACTOR_RADIUS, 0, height / 2)
        ref = Nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, -1, 0, 0) end
        bbPos = Nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            halfWidth = (bbPos - target.position):length()
        end

        -- Get the larger of x / y
        refPt = addToVector3(target.position, 0, MAX_ACTOR_RADIUS, height / 2)
        ref = Nearby.castRay(target.position, refPt, { collisionType = ANY_PHY, ignore = target })
        if ref.hitPos then refPt = addToVector3(ref.hitPos, 0, -1, 0) end
        bbPos = Nearby.castRay(refPt, target.position, { collisionType = ANY_PHY }).hitPos
        if bbPos then
            halfWidth = math.max(halfWidth, (bbPos - target.position):length())
        end

        -- Note that target will most likely be lying down if they are dead.
        if not isAlive(target) then height = height / 4 end
    else
        -- Items can be very flat, so it's important they don't have a zOffset
        zOffset = ITEM_Z_OFFSET
    end

    return {
            halfWidth = halfWidth, 
            height = height,
            sideVectors = {
                Util.vector3(0, 0, zOffset), -- Assume position is bottom side
                Util.vector3(0, 0, height), -- top
                Util.vector3(halfWidth, 0, height / 2), -- rest of the sides
                Util.vector3(-halfWidth, 0, height / 2),
                Util.vector3(0, halfWidth, height / 2),
                Util.vector3(0, -halfWidth, height / 2),
            }
        }
end

-- ==============================================
-- GRAB SPECIFIC HELPER FUNCTIONS
-- ==============================================
local function grabDataInitialized() return grabData.distance end
local function initGrabData(camPos)
    grabData.boundingData = getBoundingData(grabbedObject, GRAB_Z_OFFSET)
    grabData.prevPos = grabbedObject.position
    grabData.distance = (camPos - grabbedObject.position):length()
    grabData.maxRange = getTelekinesisRange()
    if isItem(grabbedObject) then grabData.spinDamage = getSpinDamage(grabbedObject) end
end

-- ==============================================
-- ON_UPDATE LOGIC
-- ==============================================
local function updateRagdoll(deltaSeconds)
    -- Basic physics ragdolling
    ArrayIter(ragDollData, function(ragDollData, i, j)
        local o = ragDollData[i]
        -- Stop animating object if it's finished all its sequences
        local lastIdx = table.getn(o.seqs)
        if lastIdx <= 0 then
            return false
        end

        local s = o.seqs[lastIdx]
        -- If not initialized, do so
        if not o.seqInit then
            if not o.travelled then o.travelled = 0 end
            o.seqInit = true
            o.tElapsed = deltaSeconds
            o.prevPos = nil
            o.dtPrevPos = 0
            o.stuckCount = 0
            if s.targetP then
                o.origDist = (o.target.position - s.targetP):length()
            end
        else 
            -- Else, monitor termination events
            o.tElapsed = o.tElapsed + deltaSeconds
            if o.prevPos and o.dtPrevPos >= PREV_POS_UPDATE_DT then
                o.travelled = o.travelled + (o.target.position - o.prevPos):length()
            end
            if (s.timeout and s.timeout < o.tElapsed) then
                print("Removed by timeout")
                    table.remove(o.seqs)
                    o.seqInit = false
                    return true
            elseif(o.prevPos and (o.target.position - o.prevPos):length() < STUCK_DIST_THRESHOLD and o.dtPrevPos >= PREV_POS_UPDATE_DT) then
                o.stuckCount = o.stuckCount + 1
                if o.stuckCount > STUCK_COUNT_THRESHOLD and not s.contToTime then
                    print("Removed by stuck position")
                    table.remove(o.seqs)
                    o.seqInit = false
                    return true
                end
            end
        end

        if s.targetP then
            -- Set v to tween to position if targetP is set
            -- Update v continually as teleported position is not guaranteed
            s.v = s.targetP - o.target.position
            local currDist = s.v:length()
            -- Add a nice sliding effect
            s.v = s.v:normalize() * s.spd * (s.smoothing + currDist / o.origDist)
        end

        -- Set v modifiers
        if s.applyG and s.v.z < TERMINAL_VELOCITY and not isInWater(o.target) then
            s.v = Util.vector3(s.v.x, s.v.y, s.v.z - GRAVITY_MS2 * deltaSeconds)
        end
        if s.waterSlow and isInWater(o.target) then
            s.v = s.v * (1 - s.waterSlow * deltaSeconds)
        end

        -- Move & check terminations on collision
        if o.dtPrevPos >= PREV_POS_UPDATE_DT then
            o.prevPos = o.target.position
            o.dtPrevPos = 0
        else
            o.dtPrevPos = o.dtPrevPos + deltaSeconds
        end
        local speedV = s.v * deltaSeconds
        local newPos = o.target.position + speedV
        local reachedDestination = false
        if s.targetP then
            local posV = newPos - s.targetP
            -- If +ve, acute angle. Negative, obtuse angle i.e. we've reached out destination
            local isAcute = math.acos(
                math.max(-1, 
                    math.min(1, 
                        s.v:dot(posV) / (s.v:length() * posV:length())
                    )
                )
            )
            if isAcute <= 0 then
                newPos = s.targetP
                reachedDestination = true
            end
        end

        if tpWithCollision(o.target, o.boundingData, newPos, deltaSeconds, o.travelled, nil) then
            if not o.contOnHit and not s.contToTime then
                print("Removed by hit")
                return false
            elseif not s.contOnHit and not s.contToTime then
                print("Removed by hit")
                table.remove(o.seqs)
                o.seqInit = false
            end
        end

        if reachedDestination and not s.contToTime then
            print("Removed by arrival")
            table.remove(o.seqs)
            o.seqInit = false
        end
        return true
    end)
end

local function updateGrabbedObject(deltaSeconds)
    if grabbedObject then
        -- Throw object
        if grabData.release and grabData.v then
            -- This must be placed after updateRagdoll
            local dollV = grabData.v * math.min(GRAB_THROW_MULT_MAX, GRAB_THROW_MULT * GRAB_THROW_DIST_MULT / grabData.distance)
            dollV = dollV:normalize() * math.min(GRAB_THROW_MAX_SPD, dollV:length())
            -- print(dollV:length())
            table.insert(ragDollData, {
                target = grabbedObject,
                boundingData = grabData.boundingData,
                seqs = {{ v = dollV, timeout = MAX_TIMEOUT, waterSlow = PULL_WATERSLOW, applyG = true }}
            })

            resetGrabData()
        else
            local camPos, camV = getCameraDirData(delayCamData)
            if not grabDataInitialized() then initGrabData(camPos) end

            -- User interaction
            local newRotation = nil
            if isGrabCrushing() and isActor(grabbedObject) then
                if not useMP(manaCostDt(CRUSH_COST, deltaSeconds)) then grabData.release = true end
                local dmg = DMG_CRUSH * deltaSeconds * (0.5 + MYSTICISM_SKILL.modified / 100 + DESTRUCTION_SKILL.modified / 100)
                grabbedObject:sendEvent('TK_Damage', { damage = dmg, fatigueDamage = dmg })
                grabData.crushDmg = grabData.crushDmg + dmg
                -- It didn't have the "random effect" that I was going for, but funny enough LOL
                local randNum = math.random(GRAB_CRUSH_RAND_ROTA) - GRAB_CRUSH_RAND_ROTA / 2
                newRotation = addCToVector3(grabbedObject.rotation, randNum)
            elseif grabData.isPushing and grabData.distance < grabData.maxRange then
                grabData.distance = math.min(grabData.distance + GRAB_MOVE_SPD * deltaSeconds, grabData.maxRange)
            elseif grabData.isPulling and grabData.distance > GRAB_MIN_DIST then
                grabData.distance = math.max(grabData.distance - GRAB_MOVE_SPD * deltaSeconds, GRAB_MIN_DIST)
            end

            -- Rotate items
            if grabbedObject.type.baseType == Types.Item then
                if not useMP(manaCostDt(GRAB_ITEM_COST, deltaSeconds)) then grabData.release = true; Ui.showMessage("You're too exhausted to hold onto the object.") end
                newRotation = addToVector3(grabbedObject.rotation, 0, 0, ITEM_ROTA_SPD)
                grabData.spunRadians = grabData.spunRadians + ITEM_ROTA_SPD
            else
                if not useMP(manaCostDt(GRAB_ACTOR_COST, deltaSeconds)) then grabData.release = true; Ui.showMessage("You're too exhausted to hold onto the target.") end
            end

            -- Generate move object data
            local heightOffset = isActor(grabbedObject) and -grabData.boundingData.height/2 or 0
            local newPos = addToVector3(camPos, 0, 0, heightOffset) + camV * grabData.distance
            grabData.v = newPos - grabData.prevPos
            grabData.cumAvgV = grabData.cumAvgV + (grabData.v - grabData.cumAvgV) / (CUM_AVG_N + 1)

            -- Update object's params
            local deltaDistance = (grabbedObject.position - grabData.prevPos):length()
            grabData.prevPos = grabbedObject.position

            -- Move object. Always move because otherwise morrowind's gravity will take over
            -- Pass the param in for spun radians if it's an object
            local travelledDistanceParam = isItem(grabbedObject) and grabData.spunRadians or grabData.travelled
            local actualNewPos = tpWithCollision(grabbedObject, grabData.boundingData, newPos, deltaSeconds, travelledDistanceParam, newRotation)
            -- If set it means that there was a collision
            if actualNewPos then
                -- Reset travelled distance so that bump damage will not be per frame
                grabData.travelled = 0
                -- Reset if item req exceeded and damage was applied
                if grabData.spunRadians >= ITEM_ROTA_REQ then
                    grabData.spunRadians = 0
                end
            end
            grabData.travelled = grabData.travelled + deltaDistance
        end
    end
end

local function updateChargingData(deltaSeconds)
    if currChargingData.type then
        currChargingData.holdTime = currChargingData.holdTime + deltaSeconds
        local progressText = nil
        local currTierText = nil
        local nextTierText = nil
        local nextTier = currChargingData.list[currChargingData.tier + 1]
        if nextTier then
            local tierChargeTime = nextTier.chargeTime
            local progress = round(currChargingData.holdTime / tierChargeTime * 100)
            progressText = math.min(100, progress) .. "%"
            nextTierText = "Next Tier: " .. nextTier.name .. " (" .. manaCost(nextTier.baseCost) .. " MP)"
            if progress >= 100 then
                currChargingData.tier = currChargingData.tier + 1
                currChargingData.holdTime = 0
            end
        else
            progressText = "Fully Charged"
        end
        local currTier = currChargingData.list[currChargingData.tier]
        if currTier then
            currTierText = "Current Tier: " .. currTier.name .. " (" .. manaCost(currTier.baseCost) .. " MP)"
        end
        updateTxt(progressText, currTierText or nextTierText, currTierText and nextTierText or nil)
    end
end

local function onUpdate(deltaSeconds)
    updateRagdoll(deltaSeconds)
    updateGrabbedObject(deltaSeconds)
    updateDelayCam(deltaSeconds)
    updateChargingData(deltaSeconds)
end

-- ==============================================
-- INPUT ENGINE HANDLERS
-- ==============================================
local function onInputAction(id)
    if grabbedObject and id == Input.ACTION.Activate then
        grabData.release = true
    end
end

local function onKeyPress(key)
    if DELAY_CAMERA_KEY == key.symbol then toggleDelayCam()
    elseif grabbedObject then
        if      GRAB_KEY == key.symbol then grabData.release    = true; increaseSkill(MYSTICISM_SKILL, nil)
        elseif  PUSH_KEY == key.symbol then grabData.isPushing  = true; tryStartCrush()
        elseif  PULL_KEY == key.symbol then grabData.isPulling  = true; tryStartCrush()
        end
    else
        if GRAB_KEY == key.symbol then tryStartGrab(getObjInCrosshairs().hitObject)
        elseif not currChargingData.type then
            if PUSH_KEY == key.symbol then
                currChargingData.type = PUSH_TIER_TYPE
                currChargingData.list = PUSH_TIERS
            elseif PULL_KEY == key.symbol then
                currChargingData.type = PULL_TIER_TYPE
                currChargingData.list = PULL_TIERS
            elseif LIFT_KEY == key.symbol then
                currChargingData.type = LIFT_TIER_TYPE
                currChargingData.list = LIFT_TIERS
            end
        end
    end
end

local function tryPush(tierData, iterIdx, target, v)
    if tryDoAction(target, "push", nil, tierData.statIncrMult) then
        Ui.showMessage("Push!")
        -- Prevent double animation
        rmFromRagDollData(target)
        -- If target is grounded, push should propel object slightly off the ground
        local setNewZ = not isActor(target) or not Types.Actor.isSwimming(target)
        local newV = setNewZ and Util.vector3(v.x, v.y, math.max(MIN_PUSH_Z, v.z)) or v
        if tierData.knockdown then
            target:sendEvent('TK_EmptyFatigue', {})
        end
        -- Register it for animation
        table.insert(ragDollData, {
            target = target,
            boundingData = getBoundingData(target, PUSH_Z_OFFSET),
            seqs = {{ v = newV * PUSH_SPD * tierData.speedMult, timeout = MAX_TIMEOUT, waterSlow = PULL_WATERSLOW, applyG = true }}
        })
    end
end

local function tryPull(tierData, iterIdx, target, v)
    if tryDoAction(target, "pull", nil, tierData.statIncrMult) then
        Ui.showMessage("Pull!")
        rmFromRagDollData(target)
        local camZ = Camera.getPosition().z
        local newZ = isActor(target) and (camZ + Self.position.z) / 2 or camZ
        local targetPos = Util.vector3(Self.position.x, Self.position.y, newZ) + v * (PULL_OFFSET + (tierData.yOffset or 0))
        if tierData.knockdown then target:sendEvent('TK_EmptyFatigue', {}) end
        table.insert(ragDollData, {
            target = target,
            boundingData = getBoundingData(target, PULL_Z_OFFSET),
            seqs = {{ 
                targetP = targetPos, 
                spd = PULL_SPD * tierData.speedMult, 
                smoothing = PULL_SMOOTH, 
                timeout = tierData.contToTime or MAX_TIMEOUT,
                waterSlow = PULL_WATERSLOW,
                contToTime = tierData.contToTime
            }}
        })
    end
end

local function tryLift(tierData, iterIdx, target, v)
    if tryDoAction(target, "lift", nil, tierData.statIncrMult) then
        Ui.showMessage("Lift!")
        rmFromRagDollData(target)
        local newV = Util.vector3(0, 0, 1)
        if tierData.knockdown then target:sendEvent('TK_EmptyFatigue', {}) end
        table.insert(ragDollData, {
            target = target,
            boundingData = getBoundingData(target, PULL_Z_OFFSET),
            seqs = {{ v = newV * LIFT_SPD * tierData.speedMult, timeout = MAX_TIMEOUT, waterSlow = PULL_WATERSLOW, applyG = true }}
        })
    end
end

local function tierHandler(tryXHandler)
    if currChargingData.tier > 0 then
        local tierData = currChargingData.list[currChargingData.tier]
        if tierData.singleTarget then
            local result, v = getObjInCrosshairs()
            if result.hitObject then
                if useMP(manaCost(tierData.baseCost)) then
                    tryXHandler(tierData, nil, result.hitObject, v)
                else
                    Ui.showMessage("You are too exhausted to use " .. tierData.name)
                end
            else
                Ui.showMessage("Nothing in range to " .. tierData.name .. ".")
            end
        else
            local results = getAffectedObjects(tierData.radianThreshold, false, tierData.yOffset)
            local overrideV = nil
            -- 
            if tierData.yOffset and tierData.overrideOffsetV then
                local _, v = getCameraDirData(delayCamData) 
                overrideV = v
            end
            if results and #results > 0 then
                if useMP(manaCost(tierData.baseCost)) then
                    for i, res in ipairs(results) do
                        tryXHandler(tierData, i, res.hitObject, overrideV or res.v)
                    end
                else
                    Ui.showMessage("You are too exhausted to use " .. tierData.name)
                end
            else
                Ui.showMessage("Nothing in range to " .. tierData.name .. ".")
            end
        end
    end
    resetChargingData()
    updateTxt(nil, nil, nil)
end

local function onKeyRelease(key)
    if grabbedObject then
        if      PUSH_KEY == key.symbol then grabData.isPushing = false; tryStopCrush()
        elseif  PULL_KEY == key.symbol then grabData.isPulling = false; tryStopCrush()
        end
    elseif currChargingData.type then
        if PUSH_KEY == key.symbol and PUSH_TIER_TYPE == currChargingData.type then tierHandler(tryPush)
        elseif PULL_KEY == key.symbol and PULL_TIER_TYPE == currChargingData.type then tierHandler(tryPull)
        elseif LIFT_KEY == key.symbol and LIFT_TIER_TYPE == currChargingData.type then tierHandler(tryLift)
        end
    end
end

return {
    engineHandlers = { 
        onUpdate = onUpdate, 
        onKeyPress = onKeyPress, 
        onKeyRelease = onKeyRelease,
        onInputAction = onInputAction
    }
}
