local self = require('openmw.self')
local Player = require('openmw.types').Player

local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')

local timePassed = 0
local noDecayTime = 0
local noDecayTimeStart = 0
local minSkill = 15
local lastDecayRefreshTime = 0
local decayMemory = 0
local decaySkills = {}
local jailTime

local function init()
    for skillId, _ in pairs(Player.stats.skills) do
        decaySkills[skillId] = math.floor(H.randInt(0, 359) / 30)
    end
    decayMemory = 100
    timePassed = 0
    noDecayTime = C.totalGameTimeInHours()
    noDecayTimeStart = C.totalGameTimeInHours()
    C.debugPrint(string.format("Decay: Init no decay time to %s", noDecayTime))
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
local function logDecayTime()
    if S.playerSkillsStorage:get("decayRate") == "none" then
        noDecayTimeStart = C.totalGameTimeInHours()
        C.debugPrint(string.format("Decay: Set no decay time start to %.3f", noDecayTimeStart))
    elseif noDecayTimeStart ~= 0 then
        noDecayTime = noDecayTime + (C.totalGameTimeInHours() - noDecayTimeStart)
        C.debugPrint(string.format("Decay: Updated no decay time to %.3f", noDecayTime))
        noDecayTimeStart = 0
    end
end

-- This is used to calculate "decay memory" so we subtract "no decay time" to
-- ensure an accurate value which properly factors if the player disabled
-- decay for any period of time.
local function getDecayTime()
    return C.totalGameTimeInHours() - noDecayTime
end

local function getDecayRate()
    return S.playerSkillsStorage:get("decayRate")
end

local function decreaseRate(skillId)
    -- Decrease decay rates when skills increase
    C.debugPrint(string.format("Decay: Skill \"%s\" increased; halving decay progress from %.3f to %.3f",
            skillId, decaySkills[skillId], decaySkills[skillId] / 2))
    decaySkills[skillId] = decaySkills[skillId] / 2
end

local function recalculateDecayMemory()
    local decayRateNum = C.rateMap()[getDecayRate()]
    if decayRateNum <= C.rateValues().none then return end

    local intelligence = Player.stats.attributes.intelligence(self).base
    local currentLevel = Player.stats.level(self).current

    C.debugPrint(string.format("Decay: Recalculating decay memory for: %d", decayRateNum))
    C.debugPrint(string.format("Decay: decayMemory is: %.3f", decayMemory))

    local twoWeeks = 336
    local oneWeek = 168
    local threeDays = 72
    local oneDay = 24
    local halfDay = 12

    local oldMemory = decayMemory
    decayMemory = (intelligence * intelligence) / (currentLevel * currentLevel)

    if decayRateNum == C.rateValues().slow then
        decayMemory = decayMemory * twoWeeks + threeDays
    elseif decayRateNum == C.rateValues().standard then
        decayMemory = decayMemory * oneWeek + oneDay
    elseif decayRateNum == C.rateValues().fast then
        decayMemory = decayMemory * threeDays + halfDay
    end

    if decayMemory ~= oldMemory then
        C.debugPrint(string.format("Decay: decayMemory modified to: %.3f", decayMemory))
    end
end

local function onFrame(deltaTime)
    if getDecayRate() == "none" then return end

    lastDecayRefreshTime = lastDecayRefreshTime + deltaTime
    if lastDecayRefreshTime < 5 then return end
    lastDecayRefreshTime = 0

    timePassed = getDecayTime() - timePassed
    --C.debugPrint(string.format("Decay: Refreshing decay, %.3f hours have passed", timePassed));

    local decayHappened = false;
    for skillId, _ in pairs(decaySkills) do
        decaySkills[skillId] = decaySkills[skillId] + timePassed
        if C.baseSkills()[skillId] ~= nil and decaySkills[skillId] > decayMemory then
            C.debugPrint(string.format("Decay: Decay happening for \"%s\"; resetting decay progress for this skill to 0", skillId))
            decaySkills[skillId] = 0
            local skillBase = C.baseSkills()[skillId]
            if skillBase > C.maxSkills()[skillId] / 2 and skillBase > minSkill then
                decayHappened = true
                C.modStat("skills", skillId, -1)

                C.maybePlaySound("skillraise", { pitch = 0.79 })
                C.maybePlaySound("skillraise", { pitch = 0.76 })

                -- Force a recheck of this skill's value
                C.baseSkills()[skillId] = nil
            end
        end
    end
    if S.isLuaApiRecentEnough and decayHappened then
        self:sendEvent('updatePlayerStats', false)
    end
end

local function checkJailTime(data)
    if S.playerSkillsStorage:get("decayRate") ~= "none" then
        if data.newMode == "Jail" and not jailTime then
            jailTime = C.totalGameTimeInHours()
        elseif not data.newMode and jailTime then
            noDecayTime = noDecayTime + (C.totalGameTimeInHours() - jailTime)
            jailTime = nil
        end
    end
end

local function onLoad(data)
    decayMemory = data.decayMemory
    decaySkills = data.decaySkills
    timePassed = data.timePassed
    noDecayTime = data.noDecayTime or 0
    noDecayTimeStart = data.noDecayTimeStart
end

local function onSave(data)
    data.decayMemory = decayMemory
    data.decaySkills = decaySkills
    data.timePassed = timePassed
    data.noDecayTime = noDecayTime
    data.noDecayTimeStart = noDecayTimeStart
end

return {
    noDecayTime = function() return noDecayTime end,
    decaySkills = function() return decaySkills end,
    decayMemory = function() return decayMemory end,
    logDecayTime = logDecayTime,
    init = init,
    getDecayRate = getDecayRate,
    decreaseRate = decreaseRate,
    recalculateDecayMemory = recalculateDecayMemory,
    onFrame = onFrame,
    checkJailTime = checkJailTime,
    onLoad = onLoad,
    onSave = onSave,
}