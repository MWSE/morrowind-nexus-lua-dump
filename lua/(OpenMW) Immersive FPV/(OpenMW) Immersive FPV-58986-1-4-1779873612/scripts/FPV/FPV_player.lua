local camera  = require('openmw.camera')
local input   = require('openmw.input')
local util    = require('openmw.util')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local I       = require('openmw.interfaces')
local types   = require('openmw.types')
local core    = require('openmw.core')

local Actor = types.Actor

local EYE_HEIGHT      = 125
local FORWARD_OFFSET        = 20.0
local STRAFE_WALK_Y_OFFSET  = 5.0   
local STRAFE_RUN_Y_OFFSET   = 12.0  
local moveForwardTimer  = 0.0
local MOVE_FORWARD_TIME = 0.001
local MOVE_FORWARD_Y    = 38.0
local BACK_RUN_EXTRA      = 35.0  
local BACK_WALK_EXTRA     = 5.0 
local BACK_ATK_RUN_EXTRA  = 50.0  
local BACK_ATK_WALK_EXTRA = 65.0  

local smoothedFwdFrac    = 0.0
local smoothedStrafeFrac = 0.0

local smoothedAirFwdFrac    = 0.0
local smoothedAirStrafeFrac = 0.0
local JUMP_FORWARD_Y        = 25.0
local JUMP_STRAFE_X         = 5.0

local OFFSETS = {
    NARROW = {
        WALK_Y_OFFSET  = 10.0,
        WALK_EYE_DROP  = 0.0,
        RUN_Y_OFFSET   = 46.0,
        RUN_EYE_DROP   = 2.0,
        SNEAK_Y_OFFSET = 22.0,
        SNEAK_EYE_DROP = 18.0,
        RUN_X_OFFSET   = 32.0,  
        WALK_X_OFFSET  = 6.0,   
    },
    WIDE = {
        WALK_Y_OFFSET  = 15.0,
        WALK_EYE_DROP  = 2.0,
        RUN_Y_OFFSET   = 50.0,
        RUN_EYE_DROP   = 3.0,
        SNEAK_Y_OFFSET = 28.0,
        SNEAK_EYE_DROP = 20.0,
        RUN_X_OFFSET   = 32.0,  
        WALK_X_OFFSET  = 6.0,   
    },
}

local MOV = {
    WALK_Y_OFFSET  = OFFSETS.NARROW.WALK_Y_OFFSET,
    WALK_EYE_DROP  = OFFSETS.NARROW.WALK_EYE_DROP,
    RUN_Y_OFFSET   = OFFSETS.NARROW.RUN_Y_OFFSET,
    RUN_EYE_DROP   = OFFSETS.NARROW.RUN_EYE_DROP,
    SNEAK_Y_OFFSET = OFFSETS.NARROW.SNEAK_Y_OFFSET,
    SNEAK_EYE_DROP = OFFSETS.NARROW.SNEAK_EYE_DROP,
    RUN_X_OFFSET   = OFFSETS.NARROW.RUN_X_OFFSET,
    WALK_X_OFFSET  = OFFSETS.NARROW.WALK_X_OFFSET,
}

local waitEyeDropOverride = 0

local SP = {}
local WEAPON_SUBTYPE_OFFSETS = {}
local currentWeaponSub = "onehanded"

local PITCH_FACTORS_BY_EYEPOS = {
    Hands = {
        standing = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        walking = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        running = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        sneaking = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        casting_spell = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        weapon_drawn = {
            default    = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            bow        = { y = { upShift = 0.0,  downShift = 7.0 }, drop = { upShift = -10.0, downShift = 7.0 } },
            crossbow   = { y = { upShift = 10.0, downShift = 5.0 }, drop = { upShift = -11.0, downShift = 7.0 } },
            thrown     = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = -6.0,  downShift = 0.5 } },
            spell      = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
        },
        weapon_drawn_walk = {
            default    = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            bow        = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            crossbow   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            thrown     = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            spell      = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        weapon_drawn_run = {
            default    = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            bow        = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            crossbow   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            thrown     = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            spell      = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
    },
    Eyes = {
        standing = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        walking = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        running = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        sneaking = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        casting_spell = {
            default   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        weapon_drawn = {
            default    = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            bow        = { y = { upShift = 0.0,  downShift = 7.0 }, drop = { upShift = -11.0, downShift = 7.0 } },
            crossbow   = { y = { upShift = 10.0, downShift = 5.0 }, drop = { upShift = -5.0,  downShift = 7.0 } },
            thrown     = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = -6.0,  downShift = 0.5 } },
            spell      = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0,  downShift = 0.0 }, drop = { upShift = 0.0,   downShift = 0.0 } },
        },
        weapon_drawn_walk = {
            default    = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            bow        = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            crossbow   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            thrown     = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            spell      = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
        weapon_drawn_run = {
            default    = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            onehanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            twohanded  = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            bow        = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            crossbow   = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            thrown     = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            spell      = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
            handhanded = { y = { upShift = 0.0, downShift = 0.0 }, drop = { upShift = 0.0, downShift = 0.0 } },
        },
    },
}

local PITCH_FACTORS = PITCH_FACTORS_BY_EYEPOS.Hands

local pendingHelmEquip      = false
local helmEquipDelay        = 0
local HELM_EQUIP_DELAY_TIME = 0.15

local SAFE_PITCH_MAX =  math.rad(90)
local SAFE_PITCH_MIN = -math.rad(90)

local PITCH_PIXEL_SCALE = 0.006

local INVIS_HELM_ID = "invis_helm"

local RACE_EYE_HEIGHTS = {
    ["Argonian"]  = 125, ["Breton"]   = 125, ["Dark Elf"] = 125,
    ["High Elf"]  = 137, ["Imperial"] = 125, ["Khajiit"]  = 121,
    ["Nord"]      = 133, ["Orc"]      = 130, ["Redguard"] = 127,
    ["Wood Elf"]  = 112,
}

local FORWARD_OFFSETS = {
    ["Argonian"]  = 32.0, ["Breton"]   = 20.0, ["Dark Elf"] = 20.0,
    ["High Elf"]  = 20.0, ["Imperial"] = 20.0, ["Khajiit"]  = 28.0,
    ["Nord"]      = 20.0, ["Orc"]      = 20.0, ["Redguard"] = 20.0,
    ["Wood Elf"]  = 20.0,
}

local SENSITIVITY_PROFILES = {
    Vanilla = {
        STANDING = 0.65, MOVING = 0.65, RUNNING = 0.65, WEAPON = 0.65, SPELL = 0.65,
    },
    Medium = {
        STANDING = 0.5, MOVING = 0.5, RUNNING = 0.5, WEAPON = 0.5, SPELL = 0.5,
    },
    Sensitive = {
        STANDING = 0.20, MOVING = 0.20, RUNNING = 0.20, WEAPON = 0.20, SPELL = 0.20,
    },
}

local active        = false
local lastKnownRace = nil

local lastPosZ        = nil
local verticalSpeed   = 0
local FALL_DROP_SCALE = 0.008
local MAX_FALL_DROP   = 75.0
local FALL_MIN_SPEED  = 300.0
local FALL_POWER      = 1.5
local FALL_ACCUM_RATE = 50.0
local FALL_DECAY_RATE = 300.0
local fallAccumulator = 0.0
local wasGrounded     = true
local LAND_DECAY_RATE = 500.0

local landDrop         = 0.0
local landYOffset      = 0.0
local LAND_DROP_AMOUNT = 25.0  
local LAND_Y_AMOUNT    = 8.0   
local LAND_DROP_DECAY  = 25.0  

local descentDrop      = 0.0
local DESCENT_MAX_DROP = 22.0
local DESCENT_RAMP_SPD = 28.0
local DESCENT_DECAY_SPD = 50.0

local stairDrop               = 0.0
local lastStairPosZ           = nil
local stairZAccum             = 0.0
local stairZWindow            = 0.15
local stairZTimer             = 0.0
local STAIR_MAX_DROP          = 15.0
local STAIR_MAX_RISE          = 15.0
local STAIR_RAMP_SPEED        = 16.0
local STAIR_DECAY_SPEED       = 10.0
local STAIR_ASCEND_DECAY      = 16.0
local STAIR_DESCEND_THRESHOLD = -8.0
local STAIR_ASCEND_THRESHOLD  =  1.0

local BOB = {
    WALK_AMP_Z          = 5.0,
    RUN_AMP_Z           = 8.0,
    SNEAK_AMP_Z         = 5.0,
    PHASE_SPEED_WALK_Z  = 0.06,
    PHASE_SPEED_RUN_Z   = 0.085,
    PHASE_SPEED_SNEAK_Z = 0.06,
    SMOOTH_IN           = 5.0,
    SMOOTH_OUT_Z        = 5.0,
    PHASE_SPEED_WALK_ROT  = 0.04,
    PHASE_SPEED_RUN_ROT   = 0.07,
    PHASE_SPEED_SNEAK_ROT = 0.04,
    WALK_YAW    = 0.008,
    RUN_YAW     = 0.014,
    SNEAK_YAW   = 0.005,
    WALK_PITCH  = 0.004,
    RUN_PITCH   = 0.008,
    SNEAK_PITCH = 0.003,
    WALK_ROLL   = 0.003,
    RUN_ROLL    = 0.006,
    SNEAK_ROLL  = 0.002,
    SPEED_ATTR_MAX   = 100.0,
    SPEED_ATTR_MIN   = 10.0,
    SPEED_CURVE      = 0.6,
    STRENGTH_WEIGHT  = 0.20,
    ATTR_MIN_STR     = 10.0,
    ATTR_MAX_STR     = 100.0,
    ATHLETICS_REDUCE = 1.00,
    SKILL_MIN_ATH    = 0.0,
    SKILL_MAX_ATH    = 100.0,
    pitchAmp = 0.0,
    rollAmp  = 0.0,
    phaseZ   = 0.0,
    ampZ     = 0.0,
    phaseRot = 0.0,
    yawAmp   = 0.0,
}

local ATK = {
    timer    = 0,
    TIME     = 0.6,
    movState = "stand",
}

local movementState = "standing"

local trackedPitch = 0

local pendingFPVActivation = false
local activationDelay      = 0

local savedDistance  = 192
local savedOffsetX   = 0
local savedOffsetY   = 0
local savedCollision = nil
local savedFOV       = nil

local previousHelm = nil

local wasPressed   = false
local wasAttacking = false

local currentCamPos    = nil
local CAM_SMOOTH_SPEED = 15.0
local MAX_CAM_LAG_XY   = 1.0

local smoothedExtra        = nil
local EXTRA_SMOOTH_SPEED   = 12.0   
local EXTRA_SMOOTH_FAST    = 25.0   
local EXTRA_SMOOTH_RELEASE = 8.0    

local settingsGroup = storage.playerSection('Settings_tt_FPVBody')

local alwaysRunActive      = false
local wasAlwaysRunPressed  = false

local autorunActive        = false
local wasAutorunPressed    = false

local function isPlayerGrounded()
    local ok, grounded = pcall(function() return Actor.isOnGround(self) end)
    return ok and grounded
end

local function getFPVFov()
    local fovStr = settingsGroup:get("ChooseFOV") or "85"
    return math.rad(tonumber(fovStr) or 85)
end

local function isWideFOV()
    local fovStr = settingsGroup:get("ChooseFOV") or "90"
    local fov    = tonumber(fovStr) or 90
    return fov >= 100
end

local lastAppliedWide   = nil   
local lastAppliedEyePos = nil  

local function applyFOVOffsets()
    local wide = isWideFOV()
    if wide == lastAppliedWide then return end   
    lastAppliedWide = wide
    local g = wide and OFFSETS.WIDE or OFFSETS.NARROW
    MOV.WALK_Y_OFFSET  = g.WALK_Y_OFFSET
    MOV.WALK_EYE_DROP  = g.WALK_EYE_DROP
    MOV.RUN_Y_OFFSET   = g.RUN_Y_OFFSET
    MOV.RUN_EYE_DROP   = g.RUN_EYE_DROP
    MOV.SNEAK_Y_OFFSET = g.SNEAK_Y_OFFSET
    MOV.SNEAK_EYE_DROP = g.SNEAK_EYE_DROP
    MOV.RUN_X_OFFSET   = g.RUN_X_OFFSET
    MOV.WALK_X_OFFSET  = g.WALK_X_OFFSET
end

local function updateCombatEyeDrops()
    local eyePos = settingsGroup:get("ChooseCombatEyePos") or "Hands"
    local wide   = isWideFOV()
    local cacheKey = eyePos .. (wide and "|wide" or "|narrow")
    if cacheKey == lastAppliedEyePos then return end
    lastAppliedEyePos = cacheKey
    local eyes   = (eyePos == "Eyes")

    PITCH_FACTORS = PITCH_FACTORS_BY_EYEPOS[eyePos] or PITCH_FACTORS_BY_EYEPOS.Hands

    if wide then
        SP.Y_OFFSET          = eyes and  5.0  or  -3.0
        SP.EYE_DROP          = eyes and 10.0  or  20.0
        SP.Y_WALK_OFFSET     = eyes and 15.0  or  15.0
        SP.EYE_WALK_DROP     = eyes and 10.0  or  15.0
        SP.Y_RUN_OFFSET      = eyes and 40.0  or  35.0
        SP.EYE_RUN_DROP      = eyes and 10.0  or  15.0
        SP.SNEAK_Y_OFFSET    = eyes and 15.0  or  15.0
        SP.SNEAK_EYE_DROP    = eyes and 35.0  or  35.0
        SP.Y_ATK_OFFSET      = eyes and  5.0  or   5.0
        SP.EYE_ATK_DROP      = eyes and 15.0  or  15.0
        SP.Y_ATK_RUN_OFFSET  = eyes and 40.0  or  40.0
        SP.EYE_ATK_RUN_DROP  = eyes and 10.0  or  15.0
        SP.Y_ATK_WALK_OFFSET = eyes and 15.0  or  10.0
        SP.EYE_ATK_WALK_DROP = eyes and 10.0  or  15.0
        SP.Y_ANIM_OFFSET     = eyes and 30.0  or  30.0
        SP.EYE_ANIM_DROP     = eyes and 10.0  or  15.0
    else
        SP.Y_OFFSET          = eyes and  5.0  or  -3.0
        SP.EYE_DROP          = eyes and 10.0  or  20.0
        SP.Y_WALK_OFFSET     = eyes and 15.0  or  15.0
        SP.EYE_WALK_DROP     = eyes and 10.0  or  15.0
        SP.Y_RUN_OFFSET      = eyes and 40.0  or  35.0
        SP.EYE_RUN_DROP      = eyes and 10.0  or  15.0
        SP.SNEAK_Y_OFFSET    = eyes and 15.0  or  15.0
        SP.SNEAK_EYE_DROP    = eyes and 35.0  or  35.0
        SP.Y_ATK_OFFSET      = eyes and  5.0  or   5.0
        SP.EYE_ATK_DROP      = eyes and 15.0  or  15.0
        SP.Y_ATK_RUN_OFFSET  = eyes and 40.0  or  40.0
        SP.EYE_ATK_RUN_DROP  = eyes and 10.0  or  15.0
        SP.Y_ATK_WALK_OFFSET = eyes and 15.0  or  10.0
        SP.EYE_ATK_WALK_DROP = eyes and 10.0  or  15.0
        SP.Y_ANIM_OFFSET     = eyes and 30.0  or  30.0
        SP.EYE_ANIM_DROP     = eyes and 10.0  or  15.0
    end

    if wide then
        WEAPON_SUBTYPE_OFFSETS = {
            onehanded = {
                stand     = eyes and { y =  2.0, drop =  5.0 }        or { y =  -5.0, drop = 25.0 },
                walk      = eyes and { y = 15.0, drop =  5.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y = 36.0, drop = 25.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop = 15.0 }        or { y =  -5.0, drop = 30.0 },
                atk_walk  = eyes and { y = 15.0, drop = 15.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                atk_run   = eyes and { y = 45.0, drop = 15.0, x = 25.0 } or { y = 36.0, drop = 25.0, x = 25.0 },
                anim      = eyes and { y = 50.0, drop = 15.0 }        or { y =  -1.0, drop = 30.0 },
                anim_walk = eyes and { y = 15.0, drop = 15.0, x = 3.0  } or { y =  5.0, drop = 25.0, x = 3.0  },
                anim_run  = eyes and { y = 50.0, drop = 15.0, x = 25.0 } or { y = 35.0, drop = 25.0, x = 25.0 },
            },
            twohanded = {
                stand     = eyes and { y =  1.0, drop = 15.0 }        or { y =  1.0, drop = 15.0 },
                walk      = eyes and { y = 12.0, drop = 15.0, x = 3.0  } or { y = 12.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y = 40.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop = 15.0 }        or { y =  1.0, drop = 15.0 },
                atk_walk  = eyes and { y =  7.0, drop = 15.0, x = 3.0  } or { y =  7.0, drop = 15.0, x = 3.0  },
                atk_run   = eyes and { y = 45.0, drop = 15.0, x = 25.0 } or { y = 25.0, drop = 15.0, x = 25.0 },
                anim      = eyes and { y = 52.0, drop = 15.0 }        or { y = 52.0, drop = 15.0 },
                anim_walk = eyes and { y = 52.0, drop = 15.0, x = 3.0  } or { y = 52.0, drop = 15.0, x = 3.0  },
                anim_run  = eyes and { y = 55.0, drop = 15.0, x = 25.0 } or { y = 52.0, drop = 15.0, x = 25.0 },
            },
            bow = {
                stand     = eyes and { y =  5.0, drop = 10.0 }        or { y =  5.0, drop = 25.0 },
                walk      = eyes and { y = 18.0, drop = 10.0, x = 3.0  } or { y = 12.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y = 36.0, drop = 20.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  2.0, drop =  5.0 }        or { y =  2.0, drop =  5.0 },
                atk_walk  = eyes and { y =  8.0, drop =  5.0, x = 3.0  } or { y =  8.0, drop =  5.0, x = 3.0  },
                atk_run   = eyes and { y = 25.0, drop =  2.0, x = 25.0 } or { y = 25.0, drop =  2.0, x = 25.0 },
                anim      = eyes and { y = 20.0, drop = 22.0 }        or { y = 20.0, drop = 22.0 },
                anim_walk = eyes and { y = 20.0, drop = 22.0, x = 3.0  } or { y = 20.0, drop = 22.0, x = 3.0  },
                anim_run  = eyes and { y = 36.0, drop = 22.0, x = 25.0 } or { y = 36.0, drop = 22.0, x = 25.0 },
            },
            crossbow = {
                stand     = eyes and { y =  2.0, drop =  0.0 }        or { y =  0.0, drop = 15.0 },
                walk      = eyes and { y = 12.0, drop = 10.0, x = 3.0  } or { y = 12.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 40.0, drop =  5.0, x = 25.0 } or { y = 35.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  2.0, drop =  5.0 }        or { y =  2.0, drop =  5.0 },
                atk_walk  = eyes and { y = 12.0, drop =  5.0, x = 3.0  } or { y = 12.0, drop =  5.0, x = 3.0  },
                atk_run   = eyes and { y = 30.0, drop =  5.0, x = 25.0 } or { y = 30.0, drop =  5.0, x = 25.0 },
                anim      = eyes and { y = 60.0, drop = 85.0 }        or { y = 60.0, drop = 85.0 },
                anim_walk = eyes and { y = 20.0, drop =  5.0, x = 3.0  } or { y = 20.0, drop =  5.0, x = 3.0  },
                anim_run  = eyes and { y = 35.0, drop =  5.0, x = 25.0 } or { y = 35.0, drop =  5.0, x = 25.0 },
            },
            thrown = {
                stand     = eyes and { y =  5.0, drop = 10.0 }        or { y =  5.0, drop = 25.0 },
                walk      = eyes and { y = 20.0, drop = 10.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y = 35.0, drop = 25.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  5.0, drop = 25.0 }        or { y =  5.0, drop = 25.0 },
                atk_walk  = eyes and { y = 15.0, drop = 25.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                atk_run   = eyes and { y = 40.0, drop = 25.0, x = 25.0 } or { y = 40.0, drop = 25.0, x = 25.0 },
                anim      = eyes and { y =  5.0, drop = 35.0 }        or { y =  5.0, drop = 35.0 },
                anim_walk = eyes and { y = 15.0, drop = 30.0, x = 3.0  } or { y = 15.0, drop = 30.0, x = 3.0  },
                anim_run  = eyes and { y = 35.0, drop = 30.0, x = 25.0 } or { y = 35.0, drop = 30.0, x = 25.0 },
            },
            handhanded = {
                stand     = eyes and { y =  2.0, drop = 10.0 }        or { y =   1.0, drop = 18.0 },
                walk      = eyes and { y = 15.0, drop = 10.0, x = 3.0  } or { y =  20.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y =  60.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop = 18.0 }        or { y =   1.0, drop = 18.0 },
                atk_walk  = eyes and { y = 15.0, drop = 15.0, x = 3.0  } or { y =  15.0, drop = 15.0, x = 3.0  },
                atk_run   = eyes and { y = 50.0, drop = 12.0, x = 25.0 } or { y =  50.0, drop = 12.0, x = 25.0 },
                anim      = eyes and { y =  2.0, drop = 12.0 }        or { y =   2.0, drop = 12.0 },
                anim_walk = eyes and { y = 15.0, drop =  5.0, x = 3.0  } or { y =  15.0, drop =  5.0, x = 3.0  },
                anim_run  = eyes and { y = 50.0, drop =  5.0, x = 25.0 } or { y =  50.0, drop =  5.0, x = 25.0 },
            },
        }
    else
        WEAPON_SUBTYPE_OFFSETS = {
            onehanded = {
                stand     = eyes and { y =  2.0, drop =  5.0 }        or { y =  -5.0, drop = 25.0 },
                walk      = eyes and { y = 15.0, drop =  5.0, x = 3.0  } or { y = 10.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 40.0, drop = 10.0, x = 25.0 } or { y = 36.0, drop = 25.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop = 15.0 }        or { y =  -5.0, drop = 30.0 },
                atk_walk  = eyes and { y = 15.0, drop = 15.0, x = 3.0  } or { y = 15.0, drop = 30.0, x = 3.0  },
                atk_run   = eyes and { y = 40.0, drop = 15.0, x = 25.0 } or { y = 30.0, drop = 30.0, x = 25.0 },
                anim      = eyes and { y = 12.0, drop = 15.0 }        or { y =  -1.0, drop = 30.0 },
                anim_walk = eyes and { y = 10.0, drop = 15.0, x = 3.0  } or { y =  5.0, drop = 30.0, x = 3.0  },
                anim_run  = eyes and { y = 35.0, drop = 15.0, x = 25.0 } or { y = 35.0, drop = 30.0, x = 25.0 },
            },
            twohanded = {
                stand     = eyes and { y =  1.0, drop = 15.0 }        or { y =  1.0, drop = 15.0 },
                walk      = eyes and { y = 12.0, drop = 15.0, x = 3.0  } or { y = 12.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 40.0, drop = 15.0, x = 25.0 } or { y = 40.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop = 15.0 }        or { y =  1.0, drop = 15.0 },
                atk_walk  = eyes and { y =  7.0, drop = 15.0, x = 3.0  } or { y =  7.0, drop = 15.0, x = 3.0  },
                atk_run   = eyes and { y = 25.0, drop = 15.0, x = 25.0 } or { y = 25.0, drop = 15.0, x = 25.0 },
                anim      = eyes and { y = 52.0, drop = 15.0 }        or { y = 52.0, drop = 15.0 },
                anim_walk = eyes and { y = 52.0, drop = 15.0, x = 3.0  } or { y = 52.0, drop = 15.0, x = 3.0  },
                anim_run  = eyes and { y = 52.0, drop = 15.0, x = 25.0 } or { y = 52.0, drop = 15.0, x = 25.0 },
            },
            bow = {
                stand     = eyes and { y =  5.0, drop = 10.0 }        or { y =  5.0, drop = 25.0 },
                walk      = eyes and { y = 18.0, drop = 10.0, x = 3.0  } or { y = 12.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 45.0, drop = 10.0, x = 25.0 } or { y = 36.0, drop = 20.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  1.0, drop =  5.0 }        or { y =  1.0, drop =  5.0 },
                atk_walk  = eyes and { y =  8.0, drop =  5.0, x = 3.0  } or { y =  8.0, drop =  5.0, x = 3.0  },
                atk_run   = eyes and { y = 25.0, drop =  2.0, x = 25.0 } or { y = 25.0, drop =  2.0, x = 25.0 },
                anim      = eyes and { y = 20.0, drop = 22.0 }        or { y = 20.0, drop = 22.0 },
                anim_walk = eyes and { y = 20.0, drop = 22.0, x = 3.0  } or { y = 20.0, drop = 22.0, x = 3.0  },
                anim_run  = eyes and { y = 36.0, drop = 22.0, x = 25.0 } or { y = 36.0, drop = 22.0, x = 25.0 },
            },
            crossbow = {
                stand     = eyes and { y =  2.0, drop =  0.0 }        or { y =  0.0, drop = 15.0 },
                walk      = eyes and { y = 12.0, drop = 10.0, x = 3.0  } or { y = 12.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 35.0, drop = 10.0, x = 25.0 } or { y = 35.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  2.0, drop =  5.0 }        or { y =  2.0, drop =  5.0 },
                atk_walk  = eyes and { y = 12.0, drop =  5.0, x = 3.0  } or { y = 12.0, drop =  5.0, x = 3.0  },
                atk_run   = eyes and { y = 30.0, drop =  5.0, x = 25.0 } or { y = 30.0, drop =  5.0, x = 25.0 },
                anim      = eyes and { y = 45.0, drop = 55.0 }        or { y = 45.0, drop = 55.0 },
                anim_walk = eyes and { y = 20.0, drop =  5.0, x = 3.0  } or { y = 20.0, drop =  5.0, x = 3.0  },
                anim_run  = eyes and { y = 35.0, drop =  5.0, x = 25.0 } or { y = 35.0, drop =  5.0, x = 25.0 },
            },
            thrown = {
                stand     = eyes and { y =  5.0, drop = 10.0 }        or { y =  5.0, drop = 25.0 },
                walk      = eyes and { y = 20.0, drop = 10.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                run       = eyes and { y = 40.0, drop = 10.0, x = 25.0 } or { y = 35.0, drop = 25.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  5.0, drop = 25.0 }        or { y =  5.0, drop = 25.0 },
                atk_walk  = eyes and { y = 15.0, drop = 25.0, x = 3.0  } or { y = 15.0, drop = 25.0, x = 3.0  },
                atk_run   = eyes and { y = 40.0, drop = 25.0, x = 25.0 } or { y = 40.0, drop = 25.0, x = 25.0 },
                anim      = eyes and { y =  5.0, drop = 35.0 }        or { y =  5.0, drop = 35.0 },
                anim_walk = eyes and { y = 15.0, drop = 30.0, x = 3.0  } or { y = 15.0, drop = 30.0, x = 3.0  },
                anim_run  = eyes and { y = 35.0, drop = 30.0, x = 25.0 } or { y = 35.0, drop = 30.0, x = 25.0 },
            },
            handhanded = {
                stand     = eyes and { y =  2.0, drop = 10.0 }        or { y =  -7.0, drop = 18.0 },
                walk      = eyes and { y = 15.0, drop = 10.0, x = 3.0  } or { y =  20.0, drop = 15.0, x = 3.0  },
                run       = eyes and { y = 40.0, drop = 10.0, x = 25.0 } or { y =  40.0, drop = 15.0, x = 25.0 },
                sneak     = { y = 22.0, drop = 18.0 },
                atk       = eyes and { y =  -7.0, drop = 18.0 }       or { y =  -7.0, drop = 18.0 },
                atk_walk  = eyes and { y =  10.0, drop = 15.0, x = 3.0  } or { y =  10.0, drop = 15.0, x = 3.0  },
                atk_run   = eyes and { y =  32.0, drop = 12.0, x = 25.0 } or { y =  32.0, drop = 12.0, x = 25.0 },
                anim      = eyes and { y =   2.0, drop = 12.0 }       or { y =   2.0, drop = 12.0 },
                anim_walk = eyes and { y =   6.0, drop = 10.0, x = 3.0  } or { y =   6.0, drop = 10.0, x = 3.0  },
                anim_run  = eyes and { y =  38.0, drop =  9.0, x = 25.0 } or { y =  38.0, drop =  9.0, x = 25.0 },
            },
        }
    end
end

local function getEyeHeightForRace()
    local race = settingsGroup:get("ChooseRace") or "Dark Elf"
    return RACE_EYE_HEIGHTS[race] or 125
end

local function getForwardOffsetForRace()
    local race = settingsGroup:get("ChooseRace") or "Dark Elf"
    return FORWARD_OFFSETS[race] or 22.0
end

local function updateRaceDerivedValues()
    local currentRace = settingsGroup:get("ChooseRace") or "Dark Elf"
    if currentRace ~= lastKnownRace then
        lastKnownRace  = currentRace
        EYE_HEIGHT     = getEyeHeightForRace()
        FORWARD_OFFSET = getForwardOffsetForRace()
    end
end

local function getCurrentSensitivity()
    local profile = settingsGroup:get("ChooseSensitivity") or "Vanilla"
    return SENSITIVITY_PROFILES[profile] or SENSITIVITY_PROFILES.Vanilla
end

local function isPlayerAttacking()
    local ok, result = pcall(function()
        return input.isActionPressed(input.ACTION.Attack)
    end)
    if not ok then
        local ok2, result2 = pcall(function()
            return input.isActionPressed(input.ACTION.Use)
        end)
        return ok2 and result2
    end
    return result
end

local function isPlayerSneaking()
    local ok, sneaking = pcall(function()
        return input.isActionPressed(input.ACTION.Sneak)
    end)
    return ok and sneaking
end

local function isMoving()
    return input.isActionPressed(input.ACTION.MoveForward)
        or input.isActionPressed(input.ACTION.MoveBackward)
        or input.isActionPressed(input.ACTION.MoveLeft)
        or input.isActionPressed(input.ACTION.MoveRight)
        or autorunActive  
end

local function isRunning()
    return input.isActionPressed(input.ACTION.Run)
        or alwaysRunActive
end

local function resolvePitchFactors(movState, sub)
    local byState = PITCH_FACTORS[movState or "standing"]
    if not byState then
        if movState == "weapon_drawn_walk" or movState == "weapon_drawn_run" then
            byState = PITCH_FACTORS["weapon_drawn"]
        else
            byState = PITCH_FACTORS["standing"]
        end
    end
    local pf = byState[sub or "default"] or byState["default"]
    return pf
end

local function getPitchYFactor(movState, sub)
    local pf = resolvePitchFactors(movState, sub).y
    if trackedPitch < 0 then
        local upRange = -SAFE_PITCH_MIN
        if upRange <= 0 then return 1.0 end
        local t = -trackedPitch / upRange
        return 1.0 + t * pf.upShift
    elseif trackedPitch > 0 then
        local downRange = SAFE_PITCH_MAX
        if downRange <= 0 then return 1.0 end
        local t = trackedPitch / downRange
        return 1.0 + t * pf.downShift
    end
    return 1.0
end

local function getPitchDropFactor(movState, sub)
    if not isPlayerAttacking() then return 1.0 end
    local pf = resolvePitchFactors(movState, sub).drop
    if trackedPitch < 0 then
        local upRange = -SAFE_PITCH_MIN
        if upRange <= 0 then return 1.0 end
        local t = -trackedPitch / upRange
        return 1.0 + t * pf.upShift
    elseif trackedPitch > 0 then
        local downRange = SAFE_PITCH_MAX
        if downRange <= 0 then return 1.0 end
        local t = trackedPitch / downRange
        return 1.0 + t * pf.downShift
    end
    return 1.0
end

local function updateVerticalSpeed(dt)
    local pos = self.position
    if not pos then verticalSpeed = 0; return end

    local grounded   = isPlayerGrounded()
    local justLanded = grounded and not wasGrounded
    wasGrounded      = grounded

    if lastPosZ then
        local dz    = pos.z - lastPosZ
        local newVZ = dz / dt

        if newVZ < -FALL_MIN_SPEED and not grounded then
            verticalSpeed = newVZ
            local excess  = (-newVZ - FALL_MIN_SPEED)
            local target  = math.min(MAX_FALL_DROP, (excess ^ FALL_POWER) * FALL_DROP_SCALE)
            if target > fallAccumulator then
                fallAccumulator = math.min(target, fallAccumulator + FALL_ACCUM_RATE * dt)
            end
        elseif justLanded then
            verticalSpeed   = 0
            fallAccumulator = 0.0
            landDrop        = LAND_DROP_AMOUNT
            landYOffset     = LAND_Y_AMOUNT
        else
            verticalSpeed   = 0
            fallAccumulator = math.max(0.0, fallAccumulator - FALL_DECAY_RATE * dt)
            landDrop        = math.max(0.0, landDrop    - LAND_DROP_DECAY * dt)
            landYOffset     = math.max(0.0, landYOffset - LAND_DROP_DECAY * dt)
        end

        if not grounded and dz < 0.0 then
            descentDrop = DESCENT_MAX_DROP   
        else
            local decayRate = justLanded and DESCENT_DECAY_SPD * 2.0 or DESCENT_DECAY_SPD
            descentDrop = math.max(0.0, descentDrop - decayRate * dt)
        end

    end
    lastPosZ = pos.z
end


local function updateStairDrop(dt)
    if verticalSpeed < -FALL_MIN_SPEED then
        stairDrop     = math.max(0.0, stairDrop - STAIR_DECAY_SPEED * dt)
        stairZAccum   = 0.0
        stairZTimer   = 0.0
        lastStairPosZ = nil
        return
    end

    if not isPlayerGrounded() or input.isActionPressed(input.ACTION.Jump) then
        stairZAccum   = 0.0
        stairZTimer   = 0.0
        lastStairPosZ = nil
        stairDrop     = stairDrop + (0.0 - stairDrop) * math.min(1.0, STAIR_DECAY_SPEED * dt)
        return
    end

    local pos = self.position
    if not pos then return end

    if not lastStairPosZ then
        lastStairPosZ = pos.z
        return
    end

    stairZAccum   = stairZAccum + (pos.z - lastStairPosZ)
    lastStairPosZ = pos.z
    stairZTimer   = stairZTimer + dt

    if stairZTimer < stairZWindow then return end

    local netZ  = stairZAccum
    stairZAccum = 0.0
    stairZTimer = 0.0

    if netZ < STAIR_DESCEND_THRESHOLD and isMoving() then
        local t      = math.min(1.0, ((-netZ) - (-STAIR_DESCEND_THRESHOLD)) / 20.0)
        local target = STAIR_MAX_DROP * t
        stairDrop    = stairDrop + (target - stairDrop) * math.min(1.0, STAIR_RAMP_SPEED * stairZWindow)
    elseif netZ > STAIR_ASCEND_THRESHOLD and isMoving() then
        local t      = math.min(1.0, (netZ - STAIR_ASCEND_THRESHOLD) / 20.0)
        local target = -STAIR_MAX_RISE * t
        stairDrop    = stairDrop + (target - stairDrop) * math.min(1.0, STAIR_ASCEND_DECAY * stairZWindow)
    else
        stairDrop = stairDrop + (0.0 - stairDrop) * math.min(1.0, STAIR_DECAY_SPEED * stairZWindow)
    end
end

local function getWeaponSubtype()
    local carriedRight = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
    if not carriedRight then return "handhanded" end

    local ok, wtype = pcall(function()
        return types.Weapon.record(carriedRight).type
    end)
    if not ok or type(wtype) ~= "number" then return "onehanded" end

    if     wtype == 9  then return "bow"
    elseif wtype == 10 then return "crossbow"
    elseif wtype == 11 then return "thrown"
    elseif wtype == 2 or wtype == 4 or wtype == 5 or wtype == 6 or wtype == 8 then
        return "twohanded"
    else
        return "onehanded"
    end
end

local function getPlayerStanceState()
    local stance = Actor.getStance(self)
    if stance == Actor.STANCE.Weapon then return "weapon_drawn"  end
    if stance == Actor.STANCE.Spell  then return "casting_spell" end
    return "normal"
end

local function computeMovementState()
    local stance = getPlayerStanceState()

    if stance == "weapon_drawn" then
        currentWeaponSub = getWeaponSubtype()
        return "weapon_drawn"
    end

    if ATK.timer <= 0 then
        currentWeaponSub = "onehanded"
    end

    if stance == "casting_spell" then return "casting_spell" end

    if not isMoving() then return "standing" end
    if isRunning()    then return "running"  end
    return "walking"
end

local lastStableYaw = 0
local atPitchClamp  = false
local YAW_LEN_ENTER = 0.20
local YAW_LEN_EXIT  = 0.10

local function getCharYaw(baseSens, pitchLimit_up, pitchLimit_down)
    local eps     = math.rad(0.5)
    local clamped = (trackedPitch >= pitchLimit_down - eps)
                 or (trackedPitch <= pitchLimit_up   + eps)

    local q   = self.object.rotation
    local len = 0

    if q.w == nil then
        local fwd = q * util.vector3(0, 1, 0)
        len = math.sqrt(fwd.x * fwd.x + fwd.y * fwd.y)
    end

    if atPitchClamp then
        if not clamped and (q.w ~= nil or len > YAW_LEN_ENTER) then
            atPitchClamp = false
        end
    else
        if clamped and (q.w == nil and len < YAW_LEN_EXIT) then
            atPitchClamp = true
        end
    end

    if not atPitchClamp then
        if q.w ~= nil then
            lastStableYaw = math.atan2(
                2.0 * (q.w * q.z + q.x * q.y),
                1.0 - 2.0 * (q.y * q.y + q.z * q.z)
            )
        else
            local fwd = q * util.vector3(0, 1, 0)
            if len > YAW_LEN_EXIT then
                lastStableYaw = math.atan2(fwd.x / len, fwd.y / len)
            end
        end
        return lastStableYaw, false
    else
        local mouseMoveX = input.getMouseMoveX() or 0
        if math.abs(mouseMoveX) > 0.5 then
            lastStableYaw = lastStableYaw + mouseMoveX * PITCH_PIXEL_SCALE * baseSens
            while lastStableYaw >  math.pi do lastStableYaw = lastStableYaw - 2 * math.pi end
            while lastStableYaw < -math.pi do lastStableYaw = lastStableYaw + 2 * math.pi end
        end
        return lastStableYaw, true
    end
end

local function calculateCameraPosition(ctx)
    local pos           = ctx.pos
    local yaw           = ctx.yaw
    local movState      = ctx.movementState
    local isRunningFast = ctx.isRunningFast
    local isWalkingFast = ctx.isWalkingFast
    local isSneaking    = ctx.isSneaking
    local isAttacking   = ctx.isAttacking
    local isAttackAnim  = ctx.isAttackAnim
    local weaponSub     = ctx.weaponSub
    local animMovState  = ctx.animMovState
    local mov           = ctx.mov
    local sp            = ctx.sp
    local wso           = ctx.wso
    local pitchY        = ctx.pitchY
    local pitchDrop     = ctx.pitchDrop
    local eyeHeight     = ctx.eyeHeight
    local fwdOffset     = ctx.fwdOffset
    local fallAccum     = ctx.fallAccum
    local waitOverride  = ctx.waitOverride
    local stairDr       = ctx.stairDrop
    local fwdFrac       = ctx.fwdFrac
    local strafeFrac    = ctx.strafeFrac
    local anticipate    = ctx.anticipate or 0.0
    local isGrounded    = ctx.isGrounded
    local airFwdFrac    = ctx.airFwdFrac    or 0.0
    local airStrafeFrac = ctx.airStrafeFrac or 0.0
    local descentDr     = ctx.descentDrop  or 0.0
    local landDr        = ctx.landDrop     or 0.0
    local landY         = ctx.landYOffset  or 0.0

    local isBackward       = fwdFrac < 0
    local backBoostRun     = isBackward and (BACK_RUN_EXTRA      * (-fwdFrac)) or 0.0
    local backBoostWalk    = isBackward and (BACK_WALK_EXTRA     * (-fwdFrac)) or 0.0
    local backBoostAtkRun  = isBackward and (BACK_ATK_RUN_EXTRA  * (-fwdFrac)) or 0.0
    local backBoostAtkWalk = isBackward and (BACK_ATK_WALK_EXTRA * (-fwdFrac)) or 0.0
    local sinYaw = math.sin(yaw)
    local cosYaw = math.cos(yaw)

    local base  = util.vector3(sinYaw * fwdOffset, cosYaw * fwdOffset, 0)
    local extra = util.vector3(0, 0, 0)

    local function sd(sub, key)
        local t = wso[sub] or wso.onehanded
        return t[key] or t.stand
    end

    if anticipate > 0.0 and movState == "standing" and not isSneaking then
        extra = util.vector3(
            sinYaw * MOVE_FORWARD_Y * anticipate,
            cosYaw * MOVE_FORWARD_Y * anticipate, 0)
    end

    if isSneaking then
        if movState == "weapon_drawn" then
            local d  = sd(weaponSub, "sneak")
            local df = pitchDrop.sneak_weapon
            extra = util.vector3(sinYaw * d.y, cosYaw * d.y, -d.drop * df)

        elseif movState == "casting_spell" then
            local df = pitchDrop.sneak_spell
            extra = util.vector3(
                sinYaw * sp.SNEAK_Y_OFFSET,
                cosYaw * sp.SNEAK_Y_OFFSET,
                -sp.SNEAK_EYE_DROP * df)
        else
            local df = pitchDrop.sneak_default
            extra = util.vector3(
                sinYaw * mov.SNEAK_Y_OFFSET,
                cosYaw * mov.SNEAK_Y_OFFSET,
                -mov.SNEAK_EYE_DROP * df)
        end

    elseif movState == "running" then
        local df      = pitchDrop.running
        local scaledY = mov.RUN_Y_OFFSET  * fwdFrac + backBoostRun + STRAFE_RUN_Y_OFFSET * math.abs(strafeFrac)
        local scaledX = mov.RUN_X_OFFSET  * strafeFrac
        extra = util.vector3(
            sinYaw * scaledY + cosYaw * scaledX,
            cosYaw * scaledY - sinYaw * scaledX,
            -mov.RUN_EYE_DROP * df)

    elseif movState == "walking" then
        local df      = pitchDrop.walking
        local scaledY = mov.WALK_Y_OFFSET * fwdFrac + backBoostWalk + STRAFE_WALK_Y_OFFSET * math.abs(strafeFrac)
        local scaledX = mov.WALK_X_OFFSET * strafeFrac
        extra = util.vector3(
            sinYaw * scaledY + cosYaw * scaledX,
            cosYaw * scaledY - sinYaw * scaledX,
            -mov.WALK_EYE_DROP * df)

    elseif movState == "weapon_drawn" then
        local sub = weaponSub

        if isAttacking then
            local pf    = pitchY.weapon_drawn
            local df    = pitchDrop.weapon_drawn
            local baseD = isRunningFast and sd(sub, "atk_run")
                       or isWalkingFast and sd(sub, "atk_walk")
                       or sd(sub, "atk")
            local animD = isRunningFast and sd(sub, "anim_run")
                       or isWalkingFast and sd(sub, "anim_walk")
                       or sd(sub, "anim")
            local animY  = isAttackAnim and animD.y   or 0
            local animDr = isAttackAnim and animD.drop or 0
            local strafeYOff  = isRunningFast and STRAFE_RUN_Y_OFFSET or STRAFE_WALK_Y_OFFSET
            local backBoostAtk = isRunningFast and backBoostAtkRun
                              or (isAttackAnim and backBoostAtkWalk or 0.0)
            local scaledY = (baseD.y + animY) * pf * fwdFrac + backBoostAtk + strafeYOff * math.abs(strafeFrac)
            local scaledX = ((baseD.x or 0) + (isAttackAnim and (animD.x or 0) or 0)) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -(baseD.drop + animDr) * df)

        elseif isAttackAnim then
            local d = (animMovState == "run"  and sd(sub, "anim_run"))
                   or (animMovState == "walk" and sd(sub, "anim_walk"))
                   or sd(sub, "anim")
            local df      = pitchDrop.weapon_drawn_anim
            local movFrac = (animMovState ~= "stand") and fwdFrac or 1.0
            local backBoostAtk = (animMovState == "run") and backBoostAtkRun
                              or (animMovState == "walk") and backBoostAtkWalk or 0.0
            local scaledY = d.y * pitchY.weapon_drawn_stand * movFrac + backBoostAtk
            local scaledX = (d.x or 0) * (animMovState ~= "stand" and strafeFrac or 0)
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -d.drop * df)

        elseif isRunningFast then
            local d       = sd(sub, "run")
            local df      = pitchDrop.weapon_drawn_run
            local scaledY = d.y * pitchY.weapon_drawn_run * fwdFrac + backBoostRun + STRAFE_RUN_Y_OFFSET * math.abs(strafeFrac)
            local scaledX = (d.x or 0) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -d.drop * df)

        elseif isWalkingFast then
            local d       = sd(sub, "walk")
            local df      = pitchDrop.weapon_drawn_walk
            local scaledY = d.y * pitchY.weapon_drawn_walk * fwdFrac + backBoostWalk + STRAFE_WALK_Y_OFFSET * math.abs(strafeFrac)
            local scaledX = (d.x or 0) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -d.drop * df)
        else
            local d       = sd(sub, "stand")
            local df      = pitchDrop.weapon_drawn_stand
            local scaledY = d.y * pitchY.weapon_drawn_stand + MOVE_FORWARD_Y * anticipate
            extra = util.vector3(sinYaw * scaledY, cosYaw * scaledY, -d.drop * df)
        end

    elseif movState == "casting_spell" then
        if isAttacking then
            local pf    = pitchY.casting_spell
            local df    = pitchDrop.casting_spell
            local baseY = isRunningFast and sp.Y_ATK_RUN_OFFSET
                       or isWalkingFast and sp.Y_ATK_WALK_OFFSET
                       or sp.Y_ATK_OFFSET
            local baseDr = isRunningFast and sp.EYE_ATK_RUN_DROP
                        or isWalkingFast and sp.EYE_ATK_WALK_DROP
                        or sp.EYE_ATK_DROP
            local animY  = isAttackAnim and sp.Y_ANIM_OFFSET or 0
            local animDr = isAttackAnim and sp.EYE_ANIM_DROP  or 0
            local strafeYOff  = isRunningFast and STRAFE_RUN_Y_OFFSET or STRAFE_WALK_Y_OFFSET
            local backBoostAtk = isRunningFast and backBoostAtkRun
                              or (isAttackAnim and backBoostAtkWalk or 0.0)
            local scaledY = (baseY + animY) * pf * fwdFrac + backBoostAtk + strafeYOff * math.abs(strafeFrac)
            local scaledX = (sp.X_ATK_OFFSET or 0) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -(baseDr + animDr) * df)

        elseif isAttackAnim then
            local pf      = pitchY.casting_spell
            local df      = pitchDrop.casting_spell_anim
            local scaledY = sp.Y_ANIM_OFFSET * pf
            extra = util.vector3(sinYaw * scaledY, cosYaw * scaledY, -sp.EYE_ANIM_DROP * df)

        elseif isRunningFast then
            local df      = pitchDrop.casting_spell_run
            local scaledY = sp.Y_RUN_OFFSET  * fwdFrac + backBoostRun + STRAFE_RUN_Y_OFFSET * math.abs(strafeFrac)
            local scaledX = (sp.X_RUN_OFFSET or 0) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -sp.EYE_RUN_DROP * df)

        elseif isWalkingFast then
            local df      = pitchDrop.casting_spell_walk
            local scaledY = sp.Y_WALK_OFFSET * fwdFrac + backBoostWalk + STRAFE_WALK_Y_OFFSET * math.abs(strafeFrac)
            local scaledX = (sp.X_WALK_OFFSET or 0) * strafeFrac
            extra = util.vector3(
                sinYaw * scaledY + cosYaw * scaledX,
                cosYaw * scaledY - sinYaw * scaledX,
                -sp.EYE_WALK_DROP * df)
        else
            local df      = pitchDrop.casting_spell_stand
            local scaledY = sp.Y_OFFSET + MOVE_FORWARD_Y * anticipate
            extra = util.vector3(sinYaw * scaledY, cosYaw * scaledY, -sp.EYE_DROP * df)
        end
    end

    if not isGrounded and (math.abs(airFwdFrac) > 0.01 or math.abs(airStrafeFrac) > 0.01) then
        local jumpY = airFwdFrac >= 0
            and JUMP_FORWARD_Y * airFwdFrac
            or  JUMP_FORWARD_Y * 0.3 * airFwdFrac 
        local jumpX = JUMP_STRAFE_X  * airStrafeFrac
        extra = util.vector3(
            extra.x + sinYaw * jumpY + cosYaw * jumpX,
            extra.y + cosYaw * jumpY - sinYaw * jumpX,
            extra.z
        )
    end

    local camZ = pos.z + eyeHeight + base.z + extra.z + waitOverride - fallAccum - stairDr - descentDr - landDr
    local minCamZ = pos.z + eyeHeight * 0.40
    camZ = math.max(camZ, minCamZ)

    return util.vector3(
        pos.x + base.x + extra.x + sinYaw * landY,
        pos.y + base.y + extra.y + cosYaw * landY,
        camZ
    ), extra   
end

local function enterFPV()
    active   = true
    savedFOV = camera.getFieldOfView()
    camera.setFieldOfView(getFPVFov())

    local ok, basePitch = pcall(function() return camera.getPitch() end)
    if ok and type(basePitch) == "number" then
        trackedPitch = math.max(SAFE_PITCH_MIN, math.min(SAFE_PITCH_MAX, basePitch))
    else
        trackedPitch = 0
    end

    savedDistance  = camera.getThirdPersonDistance()
    local off      = camera.getFocalPreferredOffset()
    savedOffsetX   = off.x
    savedOffsetY   = off.y
    savedCollision = camera.getCollisionType()

    I.Camera.disableZoom('fpvbody')
    I.Camera.disableModeControl('fpvbody')
    I.Camera.disableStandingPreview('fpvbody')

    local showHead = (settingsGroup:get("ShowHead") or "Yes") == "Yes"
    if not showHead then
        previousHelm = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.Helmet)
        core.sendGlobalEvent('FPV_AddInvisHelm', {})
        pendingHelmEquip = true
    end

    currentCamPos = nil
    smoothedExtra  = nil
    camera.setMode(camera.MODE.Static)
    camera.instantTransition()
end

local function exitFPV()
    active        = false
    currentCamPos = nil
    smoothedExtra  = nil

    if savedFOV then
        camera.setFieldOfView(savedFOV)
    else
        camera.setFieldOfView(
            camera.getDefaultFieldOfView and camera.getDefaultFieldOfView() or math.rad(60))
    end
    savedFOV = nil

    camera.setExtraPitch(0)

    I.Camera.enableZoom('fpvbody')
    I.Camera.enableModeControl('fpvbody')
    I.Camera.enableStandingPreview('fpvbody')

    local showHead = (settingsGroup:get("ShowHead") or "Yes") == "Yes"
    if not showHead then
        local allEquip = Actor.getEquipment(self)
        allEquip[Actor.EQUIPMENT_SLOT.Helmet] = previousHelm
        Actor.setEquipment(self, allEquip)
        previousHelm = nil
        core.sendGlobalEvent('FPV_RemoveInvisHelm', {})
    end

    camera.setMode(camera.MODE.ThirdPerson)
    camera.setPreferredThirdPersonDistance(savedDistance)
    camera.setFocalPreferredOffset(util.vector2(savedOffsetX, savedOffsetY))

    if savedCollision then
        camera.setCollisionType(savedCollision)
    end

    camera.instantTransition()
end

local function tickHelmEquip(dt)
    if not pendingHelmEquip then return end
    helmEquipDelay = helmEquipDelay + dt
    if helmEquipDelay >= HELM_EQUIP_DELAY_TIME then
        pendingHelmEquip = false
        helmEquipDelay   = 0
        local showHead = (settingsGroup:get("ShowHead") or "Yes") == "Yes"
        if not showHead then
            local allEquip = Actor.getEquipment(self)
            allEquip[Actor.EQUIPMENT_SLOT.Helmet] = INVIS_HELM_ID
            Actor.setEquipment(self, allEquip)
        end
    end
end

local function smoothExtra(targetExtra, dt, isAttacking)
    if not smoothedExtra then
        smoothedExtra = targetExtra
        return smoothedExtra
    end

    local speed
    if isAttacking then
        speed = EXTRA_SMOOTH_FAST       
    elseif smoothedExtra ~= targetExtra then
        speed = EXTRA_SMOOTH_RELEASE    
    else
        speed = EXTRA_SMOOTH_SPEED
    end

    local alpha = 1.0 - math.exp(-speed * dt)
    smoothedExtra = util.vector3(
        smoothedExtra.x + (targetExtra.x - smoothedExtra.x) * alpha,
        smoothedExtra.y + (targetExtra.y - smoothedExtra.y) * alpha,
        smoothedExtra.z + (targetExtra.z - smoothedExtra.z) * alpha
    )
    return smoothedExtra
end

local function smoothCameraPos(targetPos, dt)
    if not currentCamPos then
        currentCamPos = targetPos
        return currentCamPos
    end

    local dx  = targetPos.x - currentCamPos.x
    local dy  = targetPos.y - currentCamPos.y
    local dz  = targetPos.z - currentCamPos.z
    local dxy = math.sqrt(dx*dx + dy*dy)

    if dxy > MAX_CAM_LAG_XY then
        local push = dxy - MAX_CAM_LAG_XY
        local nx   = dx / dxy
        local ny   = dy / dxy
        currentCamPos = util.vector3(
            currentCamPos.x + nx * push,
            currentCamPos.y + ny * push,
            currentCamPos.z
        )
        dx  = targetPos.x - currentCamPos.x
        dy  = targetPos.y - currentCamPos.y
        dxy = math.sqrt(dx*dx + dy*dy)
    end

    local dist         = math.sqrt(dxy*dxy + dz*dz)
    local SNAP_THRESHOLD = 40.0
    local dynamicSpeed   = CAM_SMOOTH_SPEED + math.max(0.0, dist - SNAP_THRESHOLD) * 1.2
    local alpha          = 1 - math.exp(-dynamicSpeed * dt)
    local alphaZ = dz < 0
        and (1 - math.exp(-dynamicSpeed * 4.0 * dt))
        or  alpha

    currentCamPos = util.vector3(
        currentCamPos.x + dx * alpha,
        currentCamPos.y + dy * alpha,
        currentCamPos.z + dz * alphaZ
    )
    return currentCamPos
end

local function applyBobAndSetCamera(dt, smoothPos, charYaw,
                                    movState, isRunningFast,
                                    isWalkingFast, isSneaking,
                                    pitchUp, pitchDown, baseSens)
    local targetAmpZ, targetYawAmp, targetPitchAmp, targetRollAmp
    local moving   = isMoving()
    local grounded = isPlayerGrounded()

    if not grounded or not moving then
        targetAmpZ     = 0.0
        targetYawAmp   = 0.0
        targetPitchAmp = 0.0
        targetRollAmp  = 0.0
    elseif isSneaking then
        targetAmpZ     = BOB.SNEAK_AMP_Z
        targetYawAmp   = BOB.SNEAK_YAW
        targetPitchAmp = BOB.SNEAK_PITCH
        targetRollAmp  = BOB.SNEAK_ROLL
    elseif movState == "running"
        or (isRunningFast and (movState == "weapon_drawn" or movState == "casting_spell"))
    then
        targetAmpZ     = BOB.RUN_AMP_Z
        targetYawAmp   = BOB.RUN_YAW
        targetPitchAmp = BOB.RUN_PITCH
        targetRollAmp  = BOB.RUN_ROLL
    elseif movState == "walking" or isWalkingFast then
        targetAmpZ     = BOB.WALK_AMP_Z
        targetYawAmp   = BOB.WALK_YAW
        targetPitchAmp = BOB.WALK_PITCH
        targetRollAmp  = BOB.WALK_ROLL
    else
        targetAmpZ     = 0.0
        targetYawAmp   = 0.0
        targetPitchAmp = 0.0
        targetRollAmp  = 0.0
    end

    if moving and grounded and targetAmpZ > 0.0 then
        local speedAttr      = types.Actor.stats.attributes.speed(self).modified
        local strengthAttr   = types.Actor.stats.attributes.strength(self).modified
        local athleticsSkill = types.NPC.stats.skills.athletics(self).modified

        local speedFrac = (speedAttr - BOB.SPEED_ATTR_MIN)
                        / math.max(1.0, BOB.SPEED_ATTR_MAX - BOB.SPEED_ATTR_MIN)
        speedFrac = math.max(0.0, math.min(1.0, speedFrac))

        local strFrac = (strengthAttr - BOB.ATTR_MIN_STR)
                      / math.max(1.0, BOB.ATTR_MAX_STR - BOB.ATTR_MIN_STR)
        strFrac = math.max(0.0, math.min(1.0, strFrac))
        local strBonus = strFrac * BOB.STRENGTH_WEIGHT

        local athFrac = (athleticsSkill - BOB.SKILL_MIN_ATH)
                      / math.max(1.0, BOB.SKILL_MAX_ATH - BOB.SKILL_MIN_ATH)
        athFrac = math.max(0.0, math.min(1.0, athFrac))
        local invFrac    = (1.0 - athFrac) ^ 2.0
        local athPenalty = invFrac * BOB.ATHLETICS_REDUCE

        local frac = math.max(0.0, math.min(1.0, speedFrac + strBonus - athPenalty))
        frac = frac ^ BOB.SPEED_CURVE

        targetAmpZ     = targetAmpZ     * frac
        targetYawAmp   = targetYawAmp   * frac
        targetPitchAmp = targetPitchAmp * frac
        targetRollAmp  = targetRollAmp  * frac
    end

    if not settingsGroup:get("ToggleHeadBob") then
        targetAmpZ     = 0.0
        targetYawAmp   = 0.0
        targetPitchAmp = 0.0
        targetRollAmp  = 0.0
    end

    local rateZ     = (targetAmpZ     > BOB.ampZ)     and BOB.SMOOTH_IN or BOB.SMOOTH_OUT_Z
    local rateYaw   = (targetYawAmp   > BOB.yawAmp)   and BOB.SMOOTH_IN or BOB.SMOOTH_OUT_Z
    local ratePitch = (targetPitchAmp > BOB.pitchAmp) and BOB.SMOOTH_IN or BOB.SMOOTH_OUT_Z
    local rateRoll  = (targetRollAmp  > BOB.rollAmp)  and BOB.SMOOTH_IN or BOB.SMOOTH_OUT_Z

    BOB.ampZ     = BOB.ampZ     + (targetAmpZ     - BOB.ampZ)     * (1.0 - math.exp(-rateZ     * dt))
    BOB.yawAmp   = BOB.yawAmp   + (targetYawAmp   - BOB.yawAmp)   * (1.0 - math.exp(-rateYaw   * dt))
    BOB.pitchAmp = BOB.pitchAmp + (targetPitchAmp - BOB.pitchAmp) * (1.0 - math.exp(-ratePitch * dt))
    BOB.rollAmp  = BOB.rollAmp  + (targetRollAmp  - BOB.rollAmp)  * (1.0 - math.exp(-rateRoll  * dt))

    if moving and grounded then
        local isRun = movState == "running"
                   or (isRunningFast and (movState == "weapon_drawn" or movState == "casting_spell"))

        local psZ = isRun and BOB.PHASE_SPEED_RUN_Z
                 or (isSneaking and BOB.PHASE_SPEED_SNEAK_Z or BOB.PHASE_SPEED_WALK_Z)
        local psRot = isRun and BOB.PHASE_SPEED_RUN_ROT
                   or (isSneaking and BOB.PHASE_SPEED_SNEAK_ROT or BOB.PHASE_SPEED_WALK_ROT)

        local refSpeed = isRun and 200.0 or (isSneaking and 80.0 or 130.0)
        BOB.phaseZ   = BOB.phaseZ   + refSpeed * psZ   * dt
        BOB.phaseRot = BOB.phaseRot + refSpeed * psRot * dt
    end

    local bobOffsetZ     = BOB.ampZ     * (-math.abs(math.sin(BOB.phaseZ)))
    local bobYawOffset   = BOB.yawAmp   *   math.sin(BOB.phaseRot)
    local bobPitchOffset = BOB.pitchAmp *   math.sin(2.0 * BOB.phaseRot)
    local bobRollOffset  = BOB.rollAmp  * (-math.sin(BOB.phaseRot))

    camera.setStaticPosition(util.vector3(
        smoothPos.x,
        smoothPos.y,
        smoothPos.z + bobOffsetZ
    ))
    camera.setYaw(charYaw + bobYawOffset)

    local mouseMoveY = input.getMouseMoveY() or 0
    local invertY    = (settingsGroup:get("VerticalInversion") or "normal") == "inverted"
    if invertY then mouseMoveY = -mouseMoveY end
    if math.abs(mouseMoveY) > 0.5 then
        trackedPitch = trackedPitch + mouseMoveY * PITCH_PIXEL_SCALE * baseSens
    end
    local safeUp   = math.max(pitchUp,  SAFE_PITCH_MIN)
    local safeDown = math.min(pitchDown, SAFE_PITCH_MAX)
    if safeUp > safeDown then safeUp = safeDown end
    trackedPitch = math.max(safeUp, math.min(safeDown, trackedPitch))

    camera.setExtraPitch(trackedPitch + bobPitchOffset)
    pcall(function() camera.setRoll(bobRollOffset) end)
end

local function updateFracs(dt, grounded, fwdHeld, backHeld, leftHeld, rightHeld)
    local effectiveFwdHeld = fwdHeld or (autorunActive and not backHeld)

    local rawFwdFrac
    if effectiveFwdHeld and not backHeld then
        rawFwdFrac = 1.0
    elseif backHeld and not effectiveFwdHeld then
        rawFwdFrac = -1.0
    else
        rawFwdFrac = 0.0
    end

    local rawStrafeFrac
    if rightHeld and not leftHeld then
        rawStrafeFrac = 1.0
    elseif leftHeld and not rightHeld then
        rawStrafeFrac = -1.0
    else
        rawStrafeFrac = 0.0
    end

    local airAlpha = 1.0 - math.exp(-8.0 * dt)
    smoothedAirFwdFrac    = smoothedAirFwdFrac    + (rawFwdFrac    - smoothedAirFwdFrac)    * airAlpha
    smoothedAirStrafeFrac = smoothedAirStrafeFrac + (rawStrafeFrac - smoothedAirStrafeFrac) * airAlpha

    local fwdFrac    = grounded and rawFwdFrac    or 0.0
    local strafeFrac = grounded and rawStrafeFrac or 0.0

    local fracSmoothIn  = 6.0
    local fracSmoothOut = 12.0
    local fracAlphaFwd    = 1.0 - math.exp(-(fwdFrac > smoothedFwdFrac and fracSmoothIn or fracSmoothOut) * dt)
    local fracAlphaStrafe = 1.0 - math.exp(-(math.abs(strafeFrac) > math.abs(smoothedStrafeFrac) and fracSmoothIn or fracSmoothOut) * dt)
    smoothedFwdFrac    = smoothedFwdFrac    + (fwdFrac    - smoothedFwdFrac)    * fracAlphaFwd
    smoothedStrafeFrac = smoothedStrafeFrac + (strafeFrac - smoothedStrafeFrac) * fracAlphaStrafe

    if effectiveFwdHeld then
        moveForwardTimer = MOVE_FORWARD_TIME
    else
        moveForwardTimer = math.max(0.0, moveForwardTimer - dt)
    end
end

local function onUpdate(dt)
    if dt == 0 then return end

    updateRaceDerivedValues()
    applyFOVOffsets()
    updateCombatEyeDrops()

    local alwaysRunPressed = input.getBooleanActionValue('AlwaysRun')
    if alwaysRunPressed and not wasAlwaysRunPressed then
        alwaysRunActive = not alwaysRunActive
    end
    wasAlwaysRunPressed = alwaysRunPressed

    local autorunPressed = input.getBooleanActionValue('Autorun')
    if autorunPressed and not wasAutorunPressed then
        autorunActive = not autorunActive
    end
    wasAutorunPressed = autorunPressed

    local pressed = input.getBooleanActionValue('togglefpv')
    if pressed and not wasPressed then
        if active then
            exitFPV()
        else
            camera.setMode(camera.MODE.FirstPerson)
            camera.instantTransition()
            pendingFPVActivation = true
            activationDelay      = 0
        end
    end
    wasPressed = pressed

    if pendingFPVActivation then
        activationDelay = activationDelay + dt
        if activationDelay >= 0.1 then
            pendingFPVActivation = false
            activationDelay      = 0
            enterFPV()
        end
    end

    tickHelmEquip(dt)

    if not active then return end
    if camera.getMode() ~= camera.MODE.Static then return end

    local fwdHeld   = input.isActionPressed(input.ACTION.MoveForward)
    local backHeld  = input.isActionPressed(input.ACTION.MoveBackward)
    local leftHeld  = input.isActionPressed(input.ACTION.MoveLeft)
    local rightHeld = input.isActionPressed(input.ACTION.MoveRight)
    local grounded  = isPlayerGrounded()

    updateFracs(dt, grounded, fwdHeld, backHeld, leftHeld, rightHeld)

    updateVerticalSpeed(dt)
    updateStairDrop(dt)

    movementState = computeMovementState()

    local pos = self.position
    if not pos then return end

    local isRunningFast = (movementState == "running")
                       or ((movementState == "weapon_drawn" or movementState == "casting_spell")
                           and isRunning() and isMoving())
    local isWalkingFast = (movementState == "walking")
                       or ((movementState == "weapon_drawn" or movementState == "casting_spell")
                           and isMoving() and not isRunningFast)

    local isSneaking  = isPlayerSneaking()
    local isAttacking = isPlayerAttacking()

	if isAttacking then
		ATK.movState = isRunningFast and "run" or isWalkingFast and "walk" or "stand"
	end
	if not isAttacking and wasAttacking then
		ATK.timer = ATK.TIME
	end
	wasAttacking = isAttacking
    if ATK.timer > 0 then
        ATK.timer = ATK.timer - dt
        if ATK.timer <= 0 then
            ATK.movState = "stand"  
        end
    end
    local isAttackAnim = ATK.timer > 0

    local pitchUp   = -math.rad(85)
    local pitchDown =  math.rad(85)
    if movementState == "running"
       or ((movementState == "weapon_drawn" or movementState == "casting_spell") and isRunningFast)
    then
        pitchUp   = -math.rad(85)
        pitchDown =  math.rad(85)
    elseif movementState == "walking" then
        pitchUp = -math.rad(85)
    elseif movementState == "weapon_drawn" then
        pitchUp = -math.rad(75)
    elseif movementState == "casting_spell" then
        pitchUp = -math.rad(70)
    end

    local sens     = getCurrentSensitivity()
    local baseSens = sens.STANDING
    if     movementState == "walking"       then baseSens = sens.MOVING
    elseif movementState == "running"       then baseSens = sens.RUNNING
    elseif movementState == "weapon_drawn"  then baseSens = sens.WEAPON
    elseif movementState == "casting_spell" then baseSens = sens.SPELL
    end

    local charYaw, decoupled = getCharYaw(baseSens, pitchUp, pitchDown)

    local sub = currentWeaponSub
    local pitchY = {
        weapon_drawn       = getPitchYFactor("weapon_drawn",      sub),
        weapon_drawn_run   = getPitchYFactor("weapon_drawn_run",  sub),
        weapon_drawn_walk  = getPitchYFactor("weapon_drawn_walk", sub),
        weapon_drawn_stand = getPitchYFactor("weapon_drawn",      sub),
        casting_spell      = getPitchYFactor("casting_spell",     "spell"),
    }
    local pitchDrop = {
        sneak_weapon        = getPitchDropFactor("sneaking",          sub),
        sneak_spell         = getPitchDropFactor("sneaking",          "spell"),
        sneak_default       = getPitchDropFactor("sneaking",          "default"),
        running             = getPitchDropFactor("running",           "default"),
        walking             = getPitchDropFactor("walking",           "default"),
        weapon_drawn        = getPitchDropFactor("weapon_drawn",      sub),
        weapon_drawn_anim   = getPitchDropFactor("weapon_drawn",      sub),
        weapon_drawn_run    = getPitchDropFactor("weapon_drawn_run",  sub),
        weapon_drawn_walk   = getPitchDropFactor("weapon_drawn_walk", sub),
        weapon_drawn_stand  = getPitchDropFactor("weapon_drawn",      sub),
        casting_spell       = getPitchDropFactor("casting_spell",     "spell"),
        casting_spell_anim  = getPitchDropFactor("casting_spell",     "spell"),
        casting_spell_run   = getPitchDropFactor("casting_spell",     "spell"),
        casting_spell_walk  = getPitchDropFactor("casting_spell",     "spell"),
        casting_spell_stand = getPitchDropFactor("casting_spell",     "spell"),
    }

    local ctx = {
        pos           = pos,
        yaw           = charYaw,
        movementState = movementState,
        isRunningFast = isRunningFast,
        isWalkingFast = isWalkingFast,
        isSneaking    = isSneaking,
        isAttacking   = isAttacking,
        isAttackAnim  = isAttackAnim,
        weaponSub     = sub,
        animMovState  = ATK.movState,
        mov           = MOV,
        sp            = SP,
        wso           = WEAPON_SUBTYPE_OFFSETS,
        pitchY        = pitchY,
        pitchDrop     = pitchDrop,
        eyeHeight     = EYE_HEIGHT,
        fwdOffset     = FORWARD_OFFSET,
        fallAccum     = fallAccumulator,
        waitOverride  = waitEyeDropOverride,
        stairDrop     = stairDrop,
        fwdFrac       = smoothedFwdFrac,
        strafeFrac    = smoothedStrafeFrac,
        anticipate    = moveForwardTimer / MOVE_FORWARD_TIME,
        isGrounded    = grounded,
        airFwdFrac    = smoothedAirFwdFrac,
        airStrafeFrac = smoothedAirStrafeFrac,
        descentDrop   = descentDrop,
        landDrop      = landDrop,
        landYOffset   = landYOffset,
    }

    local targetPos, targetExtra = calculateCameraPosition(ctx)

    local sExtra     = smoothExtra(targetExtra, dt, isAttacking)
    local dEx = util.vector3(
        sExtra.x - targetExtra.x,
        sExtra.y - targetExtra.y,
        sExtra.z - targetExtra.z
    )
    local blendedPos = util.vector3(
        targetPos.x + dEx.x,
        targetPos.y + dEx.y,
        targetPos.z + dEx.z
    )
    local smoothPos  = smoothCameraPos(blendedPos, dt)

    camera.setPitch(0)
    applyBobAndSetCamera(dt, smoothPos, charYaw,
                         movementState, isRunningFast,
                         isWalkingFast, isSneaking,
                         pitchUp, pitchDown, baseSens)

    if not decoupled then
        core.sendGlobalEvent('FPV_SetPlayerYaw', {
            player = self.object,
            yaw    = charYaw,
            pitch  = trackedPitch,
        })
    end
end

local function onSave()
    return {
        active          = active,
        trackedPitch    = trackedPitch,
        savedDistance   = savedDistance,
        savedOffsetX    = savedOffsetX,
        savedOffsetY    = savedOffsetY,
        savedCollision  = savedCollision,
        previousHelm    = previousHelm,
        savedFOV        = savedFOV,
        alwaysRunActive = alwaysRunActive,
        autorunActive   = autorunActive,
    }
end

local function onLoad(data)
    lastKnownRace = nil
    updateRaceDerivedValues()
    FORWARD_OFFSET = getForwardOffsetForRace()

    if data then
        if type(data.trackedPitch) == "number" then
            trackedPitch = math.max(SAFE_PITCH_MIN, math.min(SAFE_PITCH_MAX, data.trackedPitch))
        else
            trackedPitch = 0
        end

        previousHelm    = data.previousHelm
        alwaysRunActive = data.alwaysRunActive or false
        autorunActive   = data.autorunActive   or false

        if data.active then
            savedDistance  = data.savedDistance  or 192
            savedOffsetX   = data.savedOffsetX   or 0
            savedOffsetY   = data.savedOffsetY   or 0
            savedCollision = data.savedCollision
            savedFOV       = data.savedFOV
            currentCamPos  = nil
            smoothedExtra  = nil
            camera.setMode(camera.MODE.FirstPerson)
            camera.instantTransition()
            pendingFPVActivation = true
            activationDelay      = 0
        end
    end
end

local function onInputAction(id)
    if not active then return end
    if id == input.ACTION.TogglePOV
    or id == input.ACTION.ZoomIn
    or id == input.ACTION.ZoomOut then
        return true
    end
end

local function onSettingsChanged(key, _value)
    if key == "ChooseRace" then
        updateRaceDerivedValues()
        FORWARD_OFFSET = getForwardOffsetForRace()
    elseif key == "ChooseCombatEyePos" or key == "ChooseFOV" then
        lastAppliedWide   = nil
        lastAppliedEyePos = nil
        applyFOVOffsets()
        updateCombatEyeDrops()
    elseif key == "ShowHead" then
        if active then
            local showHead = (_value or "Yes") == "Yes"
            local allEquip = Actor.getEquipment(self)
            if not showHead then
                previousHelm = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.Helmet)
                allEquip[Actor.EQUIPMENT_SLOT.Helmet] = INVIS_HELM_ID
                core.sendGlobalEvent('FPV_AddInvisHelm', {})
            else
                allEquip[Actor.EQUIPMENT_SLOT.Helmet] = previousHelm
                core.sendGlobalEvent('FPV_RemoveInvisHelm', {})
            end
            Actor.setEquipment(self, allEquip)
        end
    end
end

return {
    engineHandlers = {
        onUpdate      = onUpdate,
        onSave        = onSave,
        onLoad        = onLoad,
        onInputAction = onInputAction,
    },
    eventHandlers = {
        SettingsChanged = onSettingsChanged,
        FPV_SetEyeDropOverride = function(data)
            waitEyeDropOverride = (data and type(data.offset) == "number") and data.offset or 0
        end,
    },
}