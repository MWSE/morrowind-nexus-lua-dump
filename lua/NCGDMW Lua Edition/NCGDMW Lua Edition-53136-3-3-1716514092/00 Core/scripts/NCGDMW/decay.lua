local self = require('openmw.self')
local util = require('openmw.util')

local cfg = require('scripts.NCGDMW.configuration')
local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')

-- Time passed since last decay update
local lastDecayTime = 0
-- Time of last decay update
local lastDecayUpdateTime = 0
local lastUiRestData = { withActivator = false, time = 0, hasSleptOrWaited = false }
local lastTrainedSkillId
local noDecayTime = 0
local noDecayTimeStart = 0
local lastPlayerPos = 0
local lastOnFrameRefreshTime = 0
local jailTime = 0

local function init()
    lastDecayTime = 0
    lastDecayUpdateTime = C.totalGameTimeInHours()
    noDecayTime = C.totalGameTimeInHours()
    noDecayTimeStart = C.totalGameTimeInHours()
    lastPlayerPos = self.position
    C.debugPrint(string.format("Decay: Init no decay time to %s", noDecayTime))
end

-- This is used to calculate "decay memory" so we subtract "no decay time" to
-- ensure an accurate value which properly factors if the player disabled
-- decay for any period of time.
local function getDecayTime()
    return C.totalGameTimeInHours() - noDecayTime
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
local function logDecayTime()
    if S.skillsStorage:get("decayRate") == "none" then
        noDecayTimeStart = C.totalGameTimeInHours()
        C.debugPrint(string.format("Decay: Set no decay time start to %.3f", noDecayTimeStart))
    elseif noDecayTimeStart ~= 0 then
        noDecayTime = noDecayTime + (C.totalGameTimeInHours() - noDecayTimeStart)
        C.debugPrint(string.format("Decay: Updated no decay time to %.3f", noDecayTime))
        noDecayTimeStart = 0
        lastDecayTime = getDecayTime()
    end
end

local function updateDecay()
    lastOnFrameRefreshTime = 0
    if not C.hasStats() then return end
    local decayRate = S.skillsStorage:get("decayRate")
    if decayRate == "none" then return end

    local decayRateNum = S.getGrowthDecayRates(decayRate)
    local decayTime = getDecayTime()
    local passedTime = decayTime - lastDecayTime
    --C.debugPrint(string.format("Decay: Refreshing decay, %.3f hours have passed, decay time is %.3f", passedTime, decayTime));

    local longTimePassed = passedTime > 0.5
    if longTimePassed then
        -- More than half an hour passed, the player slept, waited, trained or took a transport
        C.debugPrint(string.format("A long time passed: %.2f hours", passedTime))
        if lastTrainedSkillId ~= nil then
            C.debugPrint("The player trained a skill")
        else
            local playerPos = self.position
            local traveledDistance = util.vector3(playerPos.x - lastPlayerPos.x, playerPos.y - lastPlayerPos.y, playerPos.z - lastPlayerPos.z)
            if traveledDistance:length() > 10000 then
                -- The player used a transport
                C.debugPrint("The player used a transport")
                passedTime = passedTime * cfg.decayTransportTimePassedFactor
            elseif not S.isLuaApiRecentEnough then
                -- On openmw 0.48, we cannot detect if the player slept (with or without a bed), waited, or trained a skill
                C.debugPrint("The player slept, waited or trained a skill")
                passedTime = passedTime * cfg.decayRestOrWaitOrTrainTimePassedFactorV48
            elseif lastUiRestData.hasSleptOrWaited and lastUiRestData.time > lastDecayUpdateTime then
                -- The player slept
                if lastUiRestData.withActivator then
                    -- The player used a bed
                    C.debugPrint("The player slept in a bed")
                    passedTime = passedTime * cfg.decayRestWithBedTimePassedFactor
                elseif not self.cell:hasTag("NoSleep") then
                    -- The player slept without a bed
                    C.debugPrint("The player slept without a bed")
                    passedTime = passedTime * cfg.decayRestWithoutBedTimePassedFactor
                else
                    -- The player just waited: No decay reduction
                    C.debugPrint("The player waited")
                end
            end
        end
    end

    local decayHappened = false;
    for skillId, _ in pairs(C.decaySkills()) do
        if C.baseSkills()[skillId] > cfg.decayMinSkill(C.maxSkills()[skillId]) then
            local skillPassedTime = passedTime
            if longTimePassed and lastTrainedSkillId ~= nil then
                if lastTrainedSkillId == skillId then
                    C.decaySkills()[skillId] = 0
                    skillPassedTime = 0
                else
                    if H.isInArray(skillId, C.skillsBySchool()[C.skillIdToSchool()[lastTrainedSkillId]]) then
                        skillPassedTime = passedTime * cfg.decayReducedHoursPerSkillTrainedSynergyFactor
                    end
                end
            end
            -- Increase decay by (time spent since last update) * (1, 2 or 4 depending on decay setting) * (skill base level / 100)
            C.decaySkills()[skillId] = C.decaySkills()[skillId] + skillPassedTime * (2 ^ (decayRateNum - 1)) * C.baseSkills()[skillId] / 100
            if C.decaySkills()[skillId] > cfg.decayTimeBaseInHours then
                C.debugPrint(string.format("Decay: Decay happening for \"%s\", reducing by half decay progress for this skill", skillId))
                C.decaySkills()[skillId] = C.decaySkills()[skillId] - cfg.decayTimeBaseInHours
                decayHappened = true
                C.modStat("skills", skillId, -1)

                C.maybePlaySound("skillraise", { pitch = 0.79 })
                C.maybePlaySound("skillraise", { pitch = 0.76 })

                -- Force a recheck of this skill's value
                C.baseSkills()[skillId] = nil
            end
        end
    end
    if longTimePassed then
        lastTrainedSkillId = nil
    end
    lastDecayTime = decayTime
    lastDecayUpdateTime = C.totalGameTimeInHours()
    lastPlayerPos = self.position
    return decayHappened
end

local function onFrame(deltaTime)
    lastOnFrameRefreshTime = lastOnFrameRefreshTime + deltaTime
    if lastOnFrameRefreshTime < 2 then return end

    local decayHappened = updateDecay()
    if decayHappened and S.isLuaApiRecentEnough then
        self:sendEvent('updatePlayerStats', false)
    end
end

local function checkJailTime(data)
    if S.skillsStorage:get("decayRate") == "none" then return end

    if data.newMode == "Jail" and not jailTime then
        jailTime = C.totalGameTimeInHours()
    elseif not data.newMode and jailTime then
        noDecayTime = noDecayTime + (C.totalGameTimeInHours() - jailTime)
        jailTime = nil
        lastDecayTime = getDecayTime()
    end
end

local function getSkillUsedHandler()
    return function(skillId, params)
        if S.skillsStorage:get("decayRate") ~= "none" then
            params.skillGain = params.skillGain * C.getSkillGainFactorIfDecay(skillId)
            C.slowDownSkillDecayOnSkillUsed(skillId, params.skillGain)
        end
    end
end

local function onLoad(data)
    noDecayTime = data.noDecayTime or 0
    lastDecayTime = data.lastDecayTime or getDecayTime()
    noDecayTimeStart = data.noDecayTimeStart or getDecayTime()
    lastPlayerPos = self.position
end

local function onSave(data)
    data.lastDecayTime = lastDecayTime
    data.noDecayTime = noDecayTime
    data.noDecayTimeStart = noDecayTimeStart
end

return {
    noDecayTime = function() return noDecayTime end,
    lastUiRestData = function() return lastUiRestData end,
    setLastTrainedSkillId = function(skillId) lastTrainedSkillId = skillId end,
    init = init,
    logDecayTime = logDecayTime,
    updateDecay = updateDecay,
    onFrame = onFrame,
    checkJailTime = checkJailTime,
    getSkillUsedHandler = getSkillUsedHandler,
    onLoad = onLoad,
    onSave = onSave,
}