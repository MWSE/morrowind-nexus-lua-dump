local T = require('openmw.types')
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local util = require('openmw.util')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mC = require('scripts.NCGDMW.common')
local mH = require('scripts.NCGDMW.helpers')

-- Time of last decay update
local lastDecayUpdateTime = mC.totalGameTimeInHours()
local lastUiRestData = { withActivator = false, time = 0, hasSleptOrWaited = false }
local lastTrainedSkillId
local lastOnFrameRefreshTime = 0
local jailTime = 0

local module = {}

-- Total time passed while decay is enabled
local function getDecayTime(state)
    return mC.totalGameTimeInHours() - state.decay.noDecayTime
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
local function logDecayTime(state)
    if mS.skillsStorage:get("skillDecayRate") == "skillDecayNone" then
        state.decay.noDecayTimeStart = mC.totalGameTimeInHours()
        state.skills.decay = mH.initNewTable(0, T.NPC.stats.skills)
        local baseStatsMods = mC.getBaseStatsModifiers()
        for skillId, getter in pairs(T.NPC.stats.skills) do
            getter(self).base = state.skills.max[skillId] + (baseStatsMods.skills[skillId] or 0)
        end
        log("Decay disabled, clearing decay progress and lost levels.")
    elseif state.decay.noDecayTimeStart ~= 0 then
        state.decay.noDecayTime = state.decay.noDecayTime + (mC.totalGameTimeInHours() - state.decay.noDecayTimeStart)
        log(string.format("Decay: Updated no decay time to %.3f", state.decay.noDecayTime))
        state.decay.noDecayTimeStart = 0
        state.decay.lastDecayTime = getDecayTime(state)
    end
end
module.logDecayTime = logDecayTime

local function updateDecay(state)
    lastOnFrameRefreshTime = 0
    local decayRate = mS.skillsStorage:get("skillDecayRate")
    if decayRate == "skillDecayNone" then return end

    local decayRateNum = mS.getSkillDecayRates(decayRate)
    local decayTime = getDecayTime(state)
    local passedTime = decayTime - state.decay.lastDecayTime
    --log(string.format("Decay: Refreshing decay, %.3f hours have passed, decay time is %.3f", passedTime, decayTime))

    local longTimePassed = passedTime > 0.5
    if longTimePassed then
        -- More than half an hour passed, the player slept, waited, trained or took a transport
        log(string.format("A long time passed: %.2f hours", passedTime))
        if lastTrainedSkillId ~= nil then
            log("The player trained a skill")
        else
            local playerPos = self.position
            local traveledDistance = util.vector3(
                    playerPos.x - state.decay.lastPlayerPos.x,
                    playerPos.y - state.decay.lastPlayerPos.y,
                    playerPos.z - state.decay.lastPlayerPos.z)
            if traveledDistance:length() > 10000 then
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
                    -- The player just waited: No decay reduction
                    log("The player waited")
                end
            end
        end
    end

    local intelligenceFactor = mS.skillsStorage:get("skillDecayIntelligenceFactor")
    if intelligenceFactor ~= 0 then
        local intelligence = T.NPC.stats.attributes.intelligence(self).modified
        if intelligence ~= 40 then
            local factor = intelligenceFactor * (intelligence - 40) / 100
            passedTime = math.max(0, passedTime * (1 - factor))
        end
    end

    local decayHappened = false;
    for skillId, _ in pairs(state.skills.decay) do
        if state.skills.base[skillId] > mCfg.decayMinSkill(state.skills.max[skillId]) then
            local skillPassedTime = passedTime
            if longTimePassed and lastTrainedSkillId ~= nil then
                if lastTrainedSkillId == skillId then
                    state.skills.decay[skillId] = 0
                    skillPassedTime = 0
                else
                    if mH.isInArray(skillId, mDef.skillsBySchool[mC.skillIdToSchool[lastTrainedSkillId]]) then
                        skillPassedTime = passedTime * mCfg.decayReducedHoursPerSkillTrainedSynergyFactor
                    end
                end
            end
            -- Increase decay by (time spent since last update) * (1, 2, 4 or 8 depending on decay setting) * (skill base level / 100)
            state.skills.decay[skillId] = state.skills.decay[skillId] + skillPassedTime * decayRateNum * state.skills.base[skillId] / 100
            if state.skills.decay[skillId] > mCfg.decayTimeBaseInHours then
                log(string.format("Decay: Decay happening for \"%s\", reducing by half decay progress for this skill", skillId))
                state.skills.decay[skillId] = state.skills.decay[skillId] - mCfg.decayTimeBaseInHours
                decayHappened = true
                mC.modStat(state, "skills", skillId, -1)
                ambient.playSound("skillraise", { pitch = 0.79 })
                ambient.playSound("skillraise", { pitch = 0.76 })
            end
        end
    end
    if longTimePassed then
        lastTrainedSkillId = nil
    end
    state.decay.lastDecayTime = decayTime
    lastDecayUpdateTime = mC.totalGameTimeInHours()
    state.decay.lastPlayerPos = self.position
    return decayHappened
end
module.updateDecay = updateDecay

local function onFrame(state, deltaTime)
    lastOnFrameRefreshTime = lastOnFrameRefreshTime + deltaTime
    if lastOnFrameRefreshTime < 2 then return end

    local decayHappened = updateDecay(state)
    if decayHappened then
        self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.skillChange)
    end
end
module.onFrame = onFrame

local function checkJailTime(state, data)
    if mS.skillsStorage:get("skillDecayRate") == "skillDecayNone" then return end

    if data.newMode == "Jail" and not jailTime then
        jailTime = mC.totalGameTimeInHours()
    elseif not data.newMode and jailTime then
        state.decay.noDecayTime = state.decay.noDecayTime + (mC.totalGameTimeInHours() - jailTime)
        jailTime = nil
        state.decay.lastDecayTime = getDecayTime(state)
    end
end

-- Slow down decay based on skill gain and gain scale
-- Not affected by skill gain reduction settings
local function slowDownSkillDecayOnSkillUsed(state, skillId, skillGain, scale)
    local decayReduction = mS.getSkillDecayReductionRates(mS.skillsStorage:get("skillDecayReductionRate"))
    local recover = skillGain * scale * decayReduction
    log(string.format("Decay handler: \"%s\" decay is reduced by (gain %.3f x scale %.3f x recover factor %.2f) / (time factor %d) = %.4f%%",
            skillId, skillGain, scale, decayReduction, mCfg.decayTimeBaseInHours, 100 * recover / mCfg.decayTimeBaseInHours))
    state.skills.decay[skillId] = math.max(0, state.skills.decay[skillId] - recover)
    if mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor ~= 0 then
        recover = recover * mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor
        log(string.format("Decay handler: Related skills decay \"%s\" is reduced by (gain %.3f x scale %.3f x recover factor %.2f x synergy factor %.3f) / (time factor %.3f) = %.4f%%",
                skillId, skillGain, scale, decayReduction, mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor, mCfg.decayTimeBaseInHours, 100 * recover / mCfg.decayTimeBaseInHours))
        for _, otherSkillId in ipairs(mDef.skillsBySchool[mC.skillIdToSchool[skillId]]) do
            if otherSkillId ~= skillId then
                state.skills.decay[otherSkillId] = math.max(0, state.skills.decay[otherSkillId] - recover)
            end
        end
    end
end

local function slowDownSkillDecayOnSkillLevelUp(state, skillId, levelUps)
    state.skills.decay[skillId] = state.skills.decay[skillId] * mCfg.slowDownSkillDecayOnSkillLevelUpFactor ^ levelUps
end
module.slowDownSkillDecayOnSkillLevelUp = slowDownSkillDecayOnSkillLevelUp

module.skillUsedHandler = function(state, skillId, params)
    if params.skillGain == 0 or mS.skillsStorage:get("skillDecayRate") == "skillDecayNone" then return end

    local skillLostLevels = state.skills.max[skillId] - state.skills.base[skillId]
    if skillLostLevels > 0 then
        local factor = mCfg.decayLostLevelsSkillGainFact(skillLostLevels)
        params.scale = params.scale * factor
        log(string.format("Decay handler: \"%s\" has lost levels, its gain is multiplied by %.3f", skillId, factor))
    end
    slowDownSkillDecayOnSkillUsed(state, skillId, params.skillGain, params.scale)
end

module.onUiModeChanged = function(state, data)
    checkJailTime(state, data)

    if data.oldMode == nil and data.newMode == "Rest" then
        lastUiRestData.withActivator = data.arg and data.arg.type == T.Activator
        lastUiRestData.time = mC.totalGameTimeInHours()
        lastUiRestData.hasSleptOrWaited = false
    elseif data.oldMode == "Rest" and data.newMode == "Loading" then
        lastUiRestData.hasSleptOrWaited = true
    end
end

module.setLastTrainedSkillId = function(skillId)
    lastTrainedSkillId = skillId
end

return module
