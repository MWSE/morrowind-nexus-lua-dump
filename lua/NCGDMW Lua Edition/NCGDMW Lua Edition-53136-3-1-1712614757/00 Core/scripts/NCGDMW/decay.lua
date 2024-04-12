local core = require('openmw.core')
local self = require('openmw.self')
local Player = require('openmw.types').Player

local S = require('scripts.NCGDMW.settings')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')

local L = core.l10n(S.MOD_NAME)

local timePassed = 0
local noDecayTime = 0
local noDecayTimeStart = 0
local minSkill = 15
local lastDecayRefreshTime = 0
local decayMemory = 0
local decaySkills = {}
local jailTime

local function init()
    for id, _ in pairs(Player.stats.skills) do
        decaySkills[id] = math.floor(H.randInt(0, 359) / 30)
    end
    decayMemory = 100
end

-- Log how long the player's played without decay so an accurate number can be
-- used in the decay maths below.
if S.playerSkillsStorage:get("decayRate") == "none" then
    noDecayTimeStart = C.totalGameTimeInHours()
end

local function logDecayTime()
    if S.playerSkillsStorage:get("decayRate") == "none" then
        noDecayTimeStart = C.totalGameTimeInHours()
    elseif noDecayTimeStart ~= 0 then
        noDecayTime = noDecayTime + (C.totalGameTimeInHours() - noDecayTimeStart)
        noDecayTimeStart = 0
    end
end

-- This is used to calculate "decay memory" so we subtract "no decay time" to
-- ensure an accurate value which properly factors if the player disabled
-- decay for any period of time.
local function getDecayTime()
    return C.totalGameTimeInHours() - noDecayTime
end

local function getDecayRateNum()
    return C.rateMap()[L(S.playerSkillsStorage:get("decayRate"))]
end

local function decreaseRate(skillId)
    -- Decrease decay rates when skills increase
    C.debugPrint("Decay: Skill increase for %s; halving decay progress from %s to %s", skillId, decaySkills[skillId], decaySkills[skillId] / 2)
    decaySkills[skillId] = decaySkills[skillId] / 2
end

local function recalculateDecayMemory()
    local decayRate = getDecayRateNum()
    if decayRate <= C.rateValues().none then return end

    local baseINT = Player.stats.attributes.intelligence(self).base
    local currentLevel = Player.stats.level(self).current

    C.debugPrint("Decay: Recalculating decay memory for: %s", C.rateMap()[decayRate])
    C.debugPrint("Decay: decayMemory is: %s", decayMemory)

    local twoWeeks = 336
    local oneWeek = 168
    local threeDays = 72
    local oneDay = 24
    local halfDay = 12

    local oldMemory = decayMemory
    decayMemory = (baseINT * baseINT) / (currentLevel * currentLevel)

    if decayRate == C.rateValues().slow then
        decayMemory = decayMemory * twoWeeks + threeDays
    elseif decayRate == C.rateValues().standard then
        decayMemory = decayMemory * oneWeek + oneDay
    elseif decayRate == C.rateValues().fast then
        decayMemory = decayMemory * threeDays + halfDay
    end

    if decayMemory ~= oldMemory then
        C.debugPrint("Decay: decayMemory modified to: %s", decayMemory)
    end
end

local function onFrame(deltaTime)
    if getDecayRateNum() == C.rateValues().none then return end

    lastDecayRefreshTime = lastDecayRefreshTime + deltaTime
    if lastDecayRefreshTime < 5 then return end
    lastDecayRefreshTime = 0

    --debugPrint("Decay: Refreshing decay...");
    timePassed = getDecayTime() - timePassed

    local decayHappened = false;
    for skill, _ in pairs(decaySkills) do
        decaySkills[skill] = decaySkills[skill] + timePassed
        if decaySkills[skill] > decayMemory then
            C.debugPrint("Decay: Decay happening for %s; resetting decay progress for this skill to 0", skill)
            decaySkills[skill] = 0
            local skillBase = Player.stats["skills"][skill](self).base
            if skillBase > C.maxSkills()[skill] / 2 and skillBase > minSkill then
                decayHappened = true
                C.modStat("skills", skill, -1)

                C.maybePlaySound("skillraise", { pitch = 0.79 })
                C.maybePlaySound("skillraise", { pitch = 0.76 })

                -- Force a recheck of this skill's value
                C.baseSkills()[skill] = 0
            end
        end
    end
    if S.isLuaApiRecentEnough and decayHappened then
        self:sendEvent('updatePlayerStats')
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
    getDecayRateNum = getDecayRateNum,
    decreaseRate = decreaseRate,
    recalculateDecayMemory = recalculateDecayMemory,
    onFrame = onFrame,
    checkJailTime = checkJailTime,
    onLoad = onLoad,
    onSave = onSave,
}