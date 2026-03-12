local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local storage = require('openmw.storage')
local common = require('scripts.DashDodge.common')

local generalSettings = storage.globalSection('Settings_DashDodge_General')
local npcSettings = storage.globalSection('Settings_DashDodge_NPC')

-- From settings (user-adjustable)
local isEnabled = true
local enableDashNPC = true
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
    enableDashNPC = npcSettings:get('enableDash_npc')
    buffSpeedMultiplier = npcSettings:get('buffSpeedMultiplier_npc')
    buffDurationMultiplier = npcSettings:get('buffDurationMultiplier_npc')
    fatigueCostMultiplier = npcSettings:get('fatigueCostMultiplier_npc')
    cooldownDurationMultiplier = npcSettings:get('cooldownDurationMultiplier_npc')
    enableEvasionEffect = npcSettings:get('enableEvasionEffect_npc')
    sfxVolumeMultiplier = npcSettings:get('sfxVolumeMultiplier_npc')

    baseSpeedBuffDuration = common.DEFAULT_SPEED_BUFF_DURATION_NPC * buffDurationMultiplier
    fatigueCost = common.DEFAULT_FATIGUE_COST_NPC * fatigueCostMultiplier
end

local function onActive()
    getCurrentSettings()
end

local function onUpdate()
    -- Mod disabled
    if isEnabled == false then
        return
    end

    if enableDashNPC == false then
        return
    end

    if common.checkCanDash(self, canApplySpeedBuff) == false then
        return
    end

    -- Not running
    local currentSpeed = types.Actor.getCurrentSpeed(self)
    local walk = types.Actor.getWalkSpeed(self)
    local run = types.Actor.getRunSpeed(self)
    local walkRunThreshold = (walk + run) * 0.5

    if currentSpeed < walkRunThreshold then
        return
    end

    local currentFatigue = dynamic.fatigue(self).current

    -- Not enough fatigue
    if currentFatigue <= fatigueCost then
        return
    end

    -- Chance to dash/dodge
    local npcLevel = types.Actor.stats.level(self).current

    -- Cap, just in case
    if npcLevel > 100 then
        npcLevel = 100
    end

    local randomRoll = math.random(0, 100)
    randomRoll = randomRoll - npcLevel -- The higher the NPC level, the higher the chance to dash/dodge
    
    if randomRoll < 0 then
        randomRoll = 0
    end

    if randomRoll >= common.NPC_DASH_CHANCE then
        return
    end

    -- Spend fatigue
    dynamic.fatigue(self).current = math.max(0, currentFatigue - fatigueCost)

    -- Get the skill modifier (capped at 100)
    local currentSkillValue = skills.athletics(self).modified

    if (currentSkillValue > 100) then
        currentSkillValue = 100
    end

    -- Calculate the buff value depending on the skill
    speedBuffValue
        = (common.BASE_SPEED_BUFF_NPC + (currentSkillValue * common.SKILL_BUFF_MAGNITUDE_FACTOR_NPC)) * buffSpeedMultiplier

    -- Actually buff speed
    common.modifySpeed(speedBuffValue, self)
    totalSpeedBuffValue = totalSpeedBuffValue + speedBuffValue

    -- Add the evasion effect
    if enableEvasionEffect then
        types.Actor.spells(self):add("Ros_dash_dodge_effect")
    end

    -- Play sfx
    if sfxVolumeMultiplier > 0.0 then
        core.sound.playSound3d("Ros_dash_dodge_sound", self, {
                volume = (common.SFX_VOLUME_NPC * sfxVolumeMultiplier),
                pitch = (1.75 + 0.1 * math.random())
            })
    end

    canApplySpeedBuff = false

    local speedBuffDuration = baseSpeedBuffDuration + (currentSkillValue / common.SKILL_BUFF_DURATION_FACTOR_NPC / 1000)

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
    local cooldownDuration = (common.DEFAULT_COOLDOWN_DURATION_NPC - (currentSkillValue / 100)) * cooldownDurationMultiplier

    -- Randomize cooldown, but clamp the random roll first
    if randomRoll < common.LOWER_COOLDOWN_THRESHOLD_NPC then
        randomRoll = common.LOWER_COOLDOWN_THRESHOLD_NPC
    elseif randomRoll > common.UPPER_COOLDOWN_THRESHOLD_NPC then
        randomRoll = common.UPPER_COOLDOWN_THRESHOLD_NPC
    end

    cooldownDuration = cooldownDuration * randomRoll

    -- Make sure the cooldown is never less than the buff itself to prevent instant re-buff
    if cooldownDuration <= speedBuffDuration then
        cooldownDuration = common.MIN_COOLDOWN_DURATION_NPC
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
    onUpdate = onUpdate,
}

return {
    engineHandlers = engineHandlers
}
