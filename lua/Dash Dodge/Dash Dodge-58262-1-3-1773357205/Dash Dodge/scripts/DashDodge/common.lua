local types = require('openmw.types')

-- Constants
local BASE_SPEED_BUFF_PLAYER = 500
local DEFAULT_SPEED_BUFF_DURATION_PLAYER = 0.05
local DEFAULT_FATIGUE_COST_PLAYER = 40
local SKILL_BUFF_MAGNITUDE_FACTOR_PLAYER = 2.5
local SKILL_BUFF_DURATION_FACTOR_PLAYER = 2.0
local DEFAULT_COOLDOWN_DURATION_PLAYER = 1.5
local MIN_COOLDOWN_DURATION_PLAYER = 0.5
local SFX_VOLUME_PLAYER = 1.0

local NPC_DASH_CHANCE = 10
local BASE_SPEED_BUFF_NPC = 350
local DEFAULT_SPEED_BUFF_DURATION_NPC = 0.035
local DEFAULT_FATIGUE_COST_NPC = 15
local SKILL_BUFF_MAGNITUDE_FACTOR_NPC = 2.5
local SKILL_BUFF_DURATION_FACTOR_NPC = 2.0
local DEFAULT_COOLDOWN_DURATION_NPC = 3.0
local LOWER_COOLDOWN_THRESHOLD_NPC = 1.0
local UPPER_COOLDOWN_THRESHOLD_NPC = 3.0
local MIN_COOLDOWN_DURATION_NPC = 0.5
local SFX_VOLUME_NPC = 100.0

local function checkCanDash(actor, canApplySpeedBuff)
    -- Can't move
    if types.Actor.canMove(actor) == false then
        return false
    end

    -- In the air/water
    if types.Actor.isOnGround(actor) == false or types.Actor.isSwimming(actor) then
        return false
    end

    -- Not in combat stance
    if types.Actor.getStance(actor) == types.Actor.STANCE.Nothing then
        return false
    end

    -- Still on cooldown
    if canApplySpeedBuff == false then
        return false
    end

    return true
end

-- Modifies actor's speed by changing the modifier value (positive for buffs, negative for debuffs).
-- Changed from applying a modifier/damage to the attribute, since it was causing a bug,
-- where the attribute would be permanently treated as damaged by the game and thus mess up with any restoring effects.
local function modifySpeed(modifierValue, actor)
    types.Actor.stats.attributes.speed(actor).modifier
        = math.max(0, types.Actor.stats.attributes.speed(actor).modifier + modifierValue)
end

return {
    BASE_SPEED_BUFF_PLAYER = BASE_SPEED_BUFF_PLAYER,
    DEFAULT_SPEED_BUFF_DURATION_PLAYER = DEFAULT_SPEED_BUFF_DURATION_PLAYER,
    DEFAULT_FATIGUE_COST_PLAYER = DEFAULT_FATIGUE_COST_PLAYER,
    SKILL_BUFF_MAGNITUDE_FACTOR_PLAYER = SKILL_BUFF_MAGNITUDE_FACTOR_PLAYER,
    SKILL_BUFF_DURATION_FACTOR_PLAYER = SKILL_BUFF_DURATION_FACTOR_PLAYER,
    DEFAULT_COOLDOWN_DURATION_PLAYER = DEFAULT_COOLDOWN_DURATION_PLAYER,
    MIN_COOLDOWN_DURATION_PLAYER = MIN_COOLDOWN_DURATION_PLAYER,
    SFX_VOLUME_PLAYER = SFX_VOLUME_PLAYER,

    NPC_DASH_CHANCE = NPC_DASH_CHANCE,
    BASE_SPEED_BUFF_NPC = BASE_SPEED_BUFF_NPC,
    DEFAULT_SPEED_BUFF_DURATION_NPC = DEFAULT_SPEED_BUFF_DURATION_NPC,
    DEFAULT_FATIGUE_COST_NPC = DEFAULT_FATIGUE_COST_NPC,
    SKILL_BUFF_MAGNITUDE_FACTOR_NPC = SKILL_BUFF_MAGNITUDE_FACTOR_NPC,
    SKILL_BUFF_DURATION_FACTOR_NPC = SKILL_BUFF_DURATION_FACTOR_NPC,
    DEFAULT_COOLDOWN_DURATION_NPC = DEFAULT_COOLDOWN_DURATION_NPC,
    LOWER_COOLDOWN_THRESHOLD_NPC = LOWER_COOLDOWN_THRESHOLD_NPC,
    UPPER_COOLDOWN_THRESHOLD_NPC = UPPER_COOLDOWN_THRESHOLD_NPC,
    MIN_COOLDOWN_DURATION_NPC = MIN_COOLDOWN_DURATION_NPC,
    SFX_VOLUME_NPC = SFX_VOLUME_NPC,

    checkCanDash = function (actor, canApplySpeedBuff)
        return checkCanDash(actor, canApplySpeedBuff)
    end,

    modifySpeed = function (modifierValue, actor)
        modifySpeed(modifierValue, actor)
    end
}