local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.store')
local mSettings = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mHelpers = require('scripts.skill-evolution.util.helpers')
local log = require('scripts.skill-evolution.util.log')

-- Time of last decay update
local paused = false
local lastDecayUpdateTime = mCore.totalGameTimeInHours()
local lastUiRestData = { withActivator = false, time = 0, hasSleptOrWaited = false }
local trainedSkillId
local passedTimePerSkill = {}
local lastOnFrameRefreshTime = 0
local jailTime = 0

local module = {}

-- Total time passed while decay is enabled
local function getDecayTime(state)
    return mCore.totalGameTimeInHours() - state.decay.noDecayTime
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
module.onDecayRateChanged = function(state)
    if not mSettings.isDecayEnabled() then
        state.decay.noDecayTimeStart = mCore.totalGameTimeInHours()
        log("Decay disabled, clearing decay progress and lost levels...")
        state.skills.decay = mHelpers.newMap(0, mCore.getSkillStats())
        local baseSkillMods = mCore.getBaseSkillMods()
        for skillId, props in pairs(mCore.getSkillStats()) do
            props.base = state.skills.max[skillId] + (baseSkillMods[skillId] or 0)
        end
    elseif state.decay.noDecayTimeStart ~= 0 then
        state.decay.noDecayTime = state.decay.noDecayTime + (mCore.totalGameTimeInHours() - state.decay.noDecayTimeStart)
        log(string.format("Decay: updated no decay time to %.3f", state.decay.noDecayTime))
        state.decay.noDecayTimeStart = 0
        state.decay.lastDecayTime = getDecayTime(state)
    end
end

local function handleLongTimes(state, passedTime)
    -- More than 2 minutes passed, the player slept, waited, took a transport, trained or used a time consuming skill
    log(string.format("A long time passed: %.2f hours", passedTime))
    if trainedSkillId then
        log(string.format("The player trained the skill \"%s\"", trainedSkillId))
        return passedTime, 0
    end
    local passedTimeBySkills = 0
    for _, hours in pairs(passedTimePerSkill) do
        passedTimeBySkills = passedTimeBySkills + hours
    end
    if passedTimeBySkills > 0 then
        log(string.format("The player spent %.2f over %.2f hours with time consuming skills", passedTimeBySkills, passedTime))
    end
    passedTime = passedTime - passedTimeBySkills
    if passedTime <= 0 then
        return 0, passedTimeBySkills
    end
    if (self.position - state.lastPlayerPos):length() > 10000 then
        -- The player used a transport
        log("The player used a transport")
        passedTime = passedTime * mCfg.decayTransportTimePassedFactor
    elseif lastUiRestData.hasSleptOrWaited and lastUiRestData.time > lastDecayUpdateTime then
        -- The player slept
        if lastUiRestData.withActivator then
            -- The player used a bed
            log("The player slept in a bed")
            passedTime = passedTime * mCfg.decayRestWithBedTimePassedFactor
        elseif not self.cell:hasTag("NoSleep") then
            -- The player slept without a bed
            log("The player slept without a bed")
            passedTime = passedTime * mCfg.decayRestWithoutBedTimePassedFactor
        else
            -- The player just waited: no decay reduction
            log("The player waited")
        end
    end
    return passedTime, passedTimeBySkills
end

module.updateDecay = function(state)
    lastOnFrameRefreshTime = 0
    if paused then return end
    local decayRate = mS.settings.skillDecayRate.get()
    if decayRate == mS.enums.skillDecayRates.None then return end

    local decayTime = getDecayTime(state)
    local passedTime = decayTime - state.decay.lastDecayTime
    local passedTimeBySkills = 0
    --log(string.format("Decay: refreshing decay, %.3f hours have passed, decay time is %.3f", passedTime, decayTime))

    local longTimePassed = passedTime > 1 / 30
    if longTimePassed then
        passedTime, passedTimeBySkills = handleLongTimes(state, passedTime)
    end

    local intelligenceFactor = mS.settings.skillDecayIntelligenceFactor.get()
    if intelligenceFactor ~= 0 then
        local intelligence = T.NPC.stats.attributes.intelligence(self).modified
        if intelligence ~= 40 then
            local factor = intelligenceFactor * (intelligence - 40) / 100
            passedTime = math.max(0, passedTime * (1 - factor))
        end
    end

    local hasDecayed = false
    passedTime = passedTime + passedTimeBySkills
    local Skills = mCore.getSkillRecords()
    for skillId, _ in pairs(state.skills.decay) do
        if state.skills.base[skillId] > mCfg.decayMinSkill(state.skills.max[skillId]) then
            local skillPassedTime = passedTime
            if longTimePassed then
                if trainedSkillId then
                    if trainedSkillId == skillId then
                        state.skills.decay[skillId] = 0
                        skillPassedTime = 0
                    else
                        if Skills[skillId].specialization == Skills[trainedSkillId].specialization then
                            skillPassedTime = passedTime * mCfg.decayReducedHoursPerSkillTrainedSynergyFactor
                        end
                    end
                elseif passedTimePerSkill[skillId] then
                    skillPassedTime = passedTime - passedTimePerSkill[skillId]
                    log(string.format("The player spent %.2f hours using skill \"%s\", %.2f doing something else",
                            passedTimePerSkill[skillId], skillId, skillPassedTime))
                end
            end
            if skillPassedTime > 0 then
                -- Increase decay by (time spent since last update) * (1, 2, 4 or 8 depending on decay setting) * (skill base level / 100) ^ 2
                state.skills.decay[skillId] = state.skills.decay[skillId] + skillPassedTime * decayRate * math.min(1, state.skills.base[skillId] / 100) ^ 2
                local decayedLevels = 0
                while state.skills.decay[skillId] > mCfg.decayTimeBaseInHours do
                    state.skills.decay[skillId] = state.skills.decay[skillId] - mCfg.decayTimeBaseInHours
                    decayedLevels = decayedLevels + 1
                end
                if decayedLevels > 0 then
                    log(string.format("Decay: \"%s\" decayed %d level(s)", skillId, decayedLevels))
                    hasDecayed = true
                    mCore.modSkill(skillId, -decayedLevels)
                end
            end
        end
    end
    if longTimePassed then
        trainedSkillId = nil
        passedTimePerSkill = {}
    end
    state.decay.lastDecayTime = decayTime
    lastDecayUpdateTime = mCore.totalGameTimeInHours()
    if hasDecayed then
        self:sendEvent(mDef.events.updateStats)
    end
end

module.setTrainedSkillId = function(skillId)
    trainedSkillId = skillId
end

module.passTimeForSkillUse = function(skillId, hours)
    passedTimePerSkill[skillId] = (passedTimePerSkill[skillId] or 0) + hours
    paused = true
    core.sendGlobalEvent(mDef.events.passHours, hours)
end

local function checkJailTime(state, data)
    if not mSettings.isDecayEnabled() then return end

    if data.newMode == "Jail" and not jailTime then
        jailTime = mCore.totalGameTimeInHours()
    elseif not data.newMode and jailTime then
        state.decay.noDecayTime = state.decay.noDecayTime + (mCore.totalGameTimeInHours() - jailTime)
        jailTime = nil
        state.decay.lastDecayTime = getDecayTime(state)
    end
end

-- Slow down decay based on skill gain and gain scale
-- Not affected by skill gain reduction settings
local function slowDownSkillDecayOnSkillUsed(state, skillId, skillGain, scale)
    local decayReduction = mS.settings.skillDecayReductionRate.get()
    local recover = skillGain * scale * decayReduction
    log(string.format("Decay handler: \"%s\" decay is reduced by (gain %.3f x scale %.3f x recover factor %.2f) / (time factor %d) = %.4f%%",
            skillId, skillGain, scale, decayReduction, mCfg.decayTimeBaseInHours, 100 * recover / mCfg.decayTimeBaseInHours))
    state.skills.decay[skillId] = math.max(0, state.skills.decay[skillId] - recover)
    if mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor ~= 0 then
        recover = recover * mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor
        log(string.format("Decay handler: related skills decay \"%s\" is reduced by (gain %.3f x scale %.3f x recover factor %.2f x synergy factor %.3f) / (time factor %.3f) = %.4f%%",
                skillId, skillGain, scale, decayReduction, mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor, mCfg.decayTimeBaseInHours, 100 * recover / mCfg.decayTimeBaseInHours))
        local Skills = mCore.getSkillRecords()
        local specialization = Skills[skillId].specialization
        for i = 1, #Skills do
            local otherSkill = Skills[i]
            if otherSkill.id ~= skillId and otherSkill.specialization == specialization then
                state.skills.decay[otherSkill.id] = math.max(0, state.skills.decay[otherSkill.id] - recover)
            end
        end
    end
end

module.slowDownSkillDecayOnSkillLevelUp = function(state, skillId)
    if not mSettings.isDecayEnabled() then return end
    state.skills.decay[skillId] = state.skills.decay[skillId] * mCfg.slowDownSkillDecayOnSkillLevelUpFactor
end

module.skillUsedHandler = function(state, skillId, params)
    if params.skillGain == 0 or not mSettings.isDecayEnabled() then return end

    local skillLostLevels = state.skills.max[skillId] - state.skills.base[skillId]
    if skillLostLevels > 0 then
        local factor = mCfg.decayLostLevelsSkillGainFact(skillLostLevels)
        local scale = params.scale
        params.scale = scale * factor
        log(string.format("Decay handler: \"%s\" has lost levels, scale %.5f x %s -> %.5f", skillId, scale, factor, params.scale))
    end
    slowDownSkillDecayOnSkillUsed(state, skillId, params.skillGain, params.scale)
end

module.onUiModeChanged = function(state, data)
    checkJailTime(state, data)

    if data.oldMode == nil and data.newMode == "Rest" then
        lastUiRestData.withActivator = data.arg and data.arg.type == T.Activator
        lastUiRestData.time = mCore.totalGameTimeInHours()
        lastUiRestData.hasSleptOrWaited = false
    elseif data.oldMode == "Rest" then
        lastUiRestData.hasSleptOrWaited = true
    end
end

module.onUpdate = function(state, deltaTime)
    lastOnFrameRefreshTime = lastOnFrameRefreshTime + deltaTime
    if lastOnFrameRefreshTime < 5 then return end

    module.updateDecay(state)
end

module.setIsPaused = function(isPaused)
    paused = isPaused
end

return module
