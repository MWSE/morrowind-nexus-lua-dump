local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local debug = require('openmw.debug')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local common = require('scripts.DashDodge.common')

local generalSettings = storage.globalSection('Settings_DashDodge_General')
local playerSettings = storage.globalSection('Settings_DashDodge_Player')

-- From settings (user-adjustable)
local isEnabled = true
local buffSpeedMultiplier = 1.0
local buffDurationMultiplier = 1.0
local fatigueCostMultiplier = 1.0
local cooldownDurationMultiplier = 1.0
local enableEvasionEffect = true
local sfxVolumeMultiplier = 1.0

local baseSpeedBuffDuration = 0.0
local fatigueCost = 0.0
local speedBuffValue = 0
local canApplySpeedBuff = true
local totalSpeedBuffValue = 0
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- Get user settings
local function getCurrentSettings()
    isEnabled = generalSettings:get('isEnabled')
    buffSpeedMultiplier = playerSettings:get('buffSpeedMultiplier_player')
    buffDurationMultiplier = playerSettings:get('buffDurationMultiplier_player')
    fatigueCostMultiplier = playerSettings:get('fatigueCostMultiplier_player')
    cooldownDurationMultiplier = playerSettings:get('cooldownDurationMultiplier_player')
    enableEvasionEffect = playerSettings:get('enableEvasionEffect_player')
    sfxVolumeMultiplier = playerSettings:get('sfxVolumeMultiplier_player')

    baseSpeedBuffDuration = common.DEFAULT_SPEED_BUFF_DURATION_PLAYER * buffDurationMultiplier
    fatigueCost = common.DEFAULT_FATIGUE_COST_PLAYER * fatigueCostMultiplier
end

local function onActive()
    getCurrentSettings()
end

local function onSave()
    return {
        totalSpeedBuffValue = totalSpeedBuffValue
    }
end

local function onLoad(data)
    if not data then
        return
    end

    totalSpeedBuffValue = data.totalSpeedBuffValue
    common.modifySpeed(totalSpeedBuffValue * -1, self)
    totalSpeedBuffValue = 0

    if enableEvasionEffect then
        types.Actor.spells(self):remove("Ros_dash_dodge_effect")
    end
end

local function onUpdate()
    -- Mod disabled
    if isEnabled == false then
        return
    end

    if common.checkCanDash(self, canApplySpeedBuff) == false then
        return
    end

    -- No input
    if input.getBooleanActionValue("DashDodgeAction") == false then
        return
    end

    -- Standing still
    local currentSpeed = types.Actor.getCurrentSpeed(self)
    local walk = types.Actor.getWalkSpeed(self)

    if currentSpeed < walk then
        return
    end

    local currentFatigue = dynamic.fatigue(self).current

    -- Not enough fatigue
    if currentFatigue <= fatigueCost then
        return
    end

    -- Spend fatigue
    if not debug.isGodMode() then
        dynamic.fatigue(self).current = math.max(0, currentFatigue - fatigueCost)
    end

    -- Get the skill modifier (capped at 100)
    local currentSkillValue = skills.athletics(self).modified

    if (currentSkillValue > 100) then
        currentSkillValue = 100
    end

    -- Calculate the buff value depending on the skill
    speedBuffValue
        = (common.BASE_SPEED_BUFF_PLAYER + (currentSkillValue * common.SKILL_BUFF_MAGNITUDE_FACTOR_PLAYER)) * buffSpeedMultiplier

    -- Actually buff speed
    common.modifySpeed(speedBuffValue, self)
    totalSpeedBuffValue = totalSpeedBuffValue + speedBuffValue

    -- Add the evasion effect
    if enableEvasionEffect then
        types.Actor.spells(self):add("Ros_dash_dodge_effect")
    end

    -- Play sfx
    if ambient and (sfxVolumeMultiplier > 0.0) then
        ambient.playSound("Ros_dash_dodge_sound", {
                volume = (common.SFX_VOLUME_PLAYER * sfxVolumeMultiplier),
                pitch = (1.75 + 0.1 * math.random())
            })
    end

    canApplySpeedBuff = false

    local speedBuffDuration = baseSpeedBuffDuration + (currentSkillValue / common.SKILL_BUFF_DURATION_FACTOR_PLAYER / 1000)

    -- Set debuff timer
    async:newUnsavableSimulationTimer(
        speedBuffDuration,
        function()
            common.modifySpeed(totalSpeedBuffValue * -1, self)
            totalSpeedBuffValue = 0
            
            if enableEvasionEffect then
                types.Actor.spells(self):remove("Ros_dash_dodge_effect")
            end
        end
    )

    -- Calculate the cooldown depending on the skill
    local cooldownDuration = (common.DEFAULT_COOLDOWN_DURATION_PLAYER - (currentSkillValue / 100)) * cooldownDurationMultiplier

    -- Make sure the cooldown is never less than the buff itself to prevent instant re-buff
    if cooldownDuration <= speedBuffDuration then
        cooldownDuration = common.MIN_COOLDOWN_DURATION_PLAYER
    end

    -- Set cooldown timer
    async:newUnsavableSimulationTimer(
        cooldownDuration,
        function()
            canApplySpeedBuff = true
        end
    )
end

-- Make sure settings are up to date
generalSettings:subscribe(async:callback(getCurrentSettings))

---@type EngineHandlers
local engineHandlers = {
    onActive = onActive,
    onSave = onSave,
    onLoad = onLoad,
    onUpdate = onUpdate,
}

return {
    engineHandlers = engineHandlers
}
