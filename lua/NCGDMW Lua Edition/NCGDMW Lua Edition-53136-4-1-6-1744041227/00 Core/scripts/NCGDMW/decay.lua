local types = require('openmw.types')
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local util = require('openmw.util')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mSettings = require('scripts.NCGDMW.settings')
local mCommon = require('scripts.NCGDMW.common')
local mHelpers = require('scripts.NCGDMW.helpers')

-- Time of last decay update
local lastDecayUpdateTime = mCommon.totalGameTimeInHours()
local lastUiRestData = { withActivator = false, time = 0, hasSleptOrWaited = false }
local lastTrainedSkillId
local lastOnFrameRefreshTime = 0
local jailTime = 0

local module = {}

-- This is used to calculate "decay memory" so we subtract "no decay time" to
-- ensure an accurate value which properly factors if the player disabled
-- decay for any period of time.
local function getDecayTime(state)
    return mCommon.totalGameTimeInHours() - state.decay.noDecayTime
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
local function logDecayTime(state)
    if mSettings.skillsStorage:get("skillDecayRate") == "skillDecayNone" then
        state.decay.noDecayTimeStart = mCommon.totalGameTimeInHours()
        log(string.format("Decay: Set no decay time start to %.3f", state.decay.noDecayTimeStart))
    elseif state.decay.noDecayTimeStart ~= 0 then
        state.decay.noDecayTime = state.decay.noDecayTime + (mCommon.totalGameTimeInHours() - state.decay.noDecayTimeStart)
        log(string.format("Decay: Updated no decay time to %.3f", state.decay.noDecayTime))
        state.decay.noDecayTimeStart = 0
        state.decay.lastDecayTime = getDecayTime(state)
    end
end
module.logDecayTime = logDecayTime

local function updateDecay(state)
    lastOnFrameRefreshTime = 0
    local decayRate = mSettings.skillsStorage:get("skillDecayRate")
    if decayRate == "skillDecayNone" then return end

    local decayRateNum = mSettings.getSkillDecayRates(decayRate)
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

    local decayHappened = false;
    for skillId, _ in pairs(state.skills.decay) do
        if state.skills.base[skillId] > mCfg.decayMinSkill(state.skills.max[skillId]) then
            local skillPassedTime = passedTime
            if longTimePassed and lastTrainedSkillId ~= nil then
                if lastTrainedSkillId == skillId then
                    state.skills.decay[skillId] = 0
                    skillPassedTime = 0
                else
                    if mHelpers.isInArray(skillId, mDef.skillsBySchool[mCommon.skillIdToSchool[lastTrainedSkillId]]) then
                        skillPassedTime = passedTime * mCfg.decayReducedHoursPerSkillTrainedSynergyFactor
                    end
                end
            end
            -- Increase decay by (time spent since last update) * (1, 2 or 4 depending on decay setting) * (skill base level / 100)
            state.skills.decay[skillId] = state.skills.decay[skillId] + skillPassedTime * (2 ^ (decayRateNum - 1)) * state.skills.base[skillId] / 100
            if state.skills.decay[skillId] > mCfg.decayTimeBaseInHours then
                log(string.format("Decay: Decay happening for \"%s\", reducing by half decay progress for this skill", skillId))
                state.skills.decay[skillId] = state.skills.decay[skillId] - mCfg.decayTimeBaseInHours
                decayHappened = true

                mCommon.modStat(state, "skills", skillId, -1)
                ambient.playSound("skillraise", { pitch = 0.79 })
                ambient.playSound("skillraise", { pitch = 0.76 })

                -- Force a recheck of this skill's value
                state.skills.base[skillId] = nil
            end
        end
    end
    if longTimePassed then
        lastTrainedSkillId = nil
    end
    state.decay.lastDecayTime = decayTime
    lastDecayUpdateTime = mCommon.totalGameTimeInHours()
    state.decay.lastPlayerPos = self.position
    return decayHappened
end
module.updateDecay = updateDecay

local function onFrame(state, deltaTime)
    lastOnFrameRefreshTime = lastOnFrameRefreshTime + deltaTime
    if lastOnFrameRefreshTime < 2 then return end

    local decayHappened = updateDecay(state)
    if decayHappened then
        self:sendEvent("updateProfile")
    end
end
module.onFrame = onFrame

local function checkJailTime(state, data)
    if mSettings.skillsStorage:get("skillDecayRate") == "skillDecayNone" then return end

    if data.newMode == "Jail" and not jailTime then
        jailTime = mCommon.totalGameTimeInHours()
    elseif not data.newMode and jailTime then
        state.decay.noDecayTime = state.decay.noDecayTime + (mCommon.totalGameTimeInHours() - jailTime)
        jailTime = nil
        state.decay.lastDecayTime = getDecayTime(state)
    end
end

-- Slow down decay based on skill gain
-- Will benefit from MBSP skill gain boost
-- Won't be affected by skill gain reduction settings
local function slowDownSkillDecayOnSkillUsed(state, skillId, skillGain)
    state.skills.decay[skillId] = math.max(0, state.skills.decay[skillId] - (skillGain * mCfg.decayRecoveredHoursPerSkillUsed))
    if mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor ~= 0 then
        for _, otherSkillId in ipairs(mDef.skillsBySchool[mCommon.skillIdToSchool[skillId]]) do
            if otherSkillId ~= skillId then
                state.skills.decay[otherSkillId] = math.max(0, state.skills.decay[otherSkillId]
                        - (skillGain * mCfg.decayRecoveredHoursPerSkillUsed * mCfg.decayRecoveredHoursPerSkillUsedSynergyFactor))
            end
        end
    end
end

local function slowDownSkillDecayOnSkillLevelUp(state, skillId)
    state.skills.decay[skillId] = state.skills.decay[skillId] * mCfg.slowDownSkillDecayOnSkillLevelUpFactor
end
module.slowDownSkillDecayOnSkillLevelUp = slowDownSkillDecayOnSkillLevelUp

local function getSkillGainFactorIfDecay(state, skillId)
    local skillLostLevels = state.skills.max[skillId] - state.skills.base[skillId]
    return skillLostLevels > 0 and mCfg.decayLostLevelsSkillGainFact(skillLostLevels) or 1
end

local function skillUsedHandler(state, skillId, params)
    if mSettings.skillsStorage:get("skillDecayRate") ~= "skillDecayNone" then
        params.skillGain = params.skillGain * getSkillGainFactorIfDecay(state, skillId)
        slowDownSkillDecayOnSkillUsed(state, skillId, params.skillGain)
    end
end
module.skillUsedHandler = skillUsedHandler

local function onUiModeChanged(state, data)
    checkJailTime(state, data)

    if data.oldMode == nil and data.newMode == "Rest" then
        lastUiRestData.withActivator = data.arg and data.arg.type == types.Activator
        lastUiRestData.time = mCommon.totalGameTimeInHours()
        lastUiRestData.hasSleptOrWaited = false
    elseif data.oldMode == "Rest" and data.newMode == "Loading" then
        lastUiRestData.hasSleptOrWaited = true
    end
end
module.onUiModeChanged = onUiModeChanged

local function setLastTrainedSkillId(skillId)
    lastTrainedSkillId = skillId
end
module.setLastTrainedSkillId = setLastTrainedSkillId

return module
