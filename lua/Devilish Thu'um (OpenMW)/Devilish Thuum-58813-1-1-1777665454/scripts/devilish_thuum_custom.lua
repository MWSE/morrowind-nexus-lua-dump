-- scripts/devilish_thuum_custom.lua

local self  = require('openmw.self')
local anim  = require('openmw.animation')
local AI    = require('openmw.interfaces').AI
local core  = require('openmw.core')
local types = require('openmw.types')

local player = nil

local DISTANCE_MAX = 1000
local DISTANCE_MAX_SQ = DISTANCE_MAX * DISTANCE_MAX

local AI_CHECK_DT = 0.20
local SHOUT_DELAY = 1.0

local COOLDOWN_MIN = 5.0
local COOLDOWN_MAX = 16.0

local ANIM_ID = 'thuum2'
local FATIGUE_SPELL_ID = 'detd_thuum_fatigue'
local FATIGUE_SPELL_DURATION = 1.0

local CASTER_STAT_LOCK_DURATION = 2.0

local STAGE_IDLE = 0
local STAGE_WAIT_TO_SHOUT = 1

local stage = STAGE_IDLE
local timer = 0.0
local cooldown = 0.0
local aiCheckTimer = 0.0
local currentTier = 0
local currentTarget = nil

local fatigueTargets = {}

local casterStatsLocked = false
local casterStatLockTimer = 0.0

local savedCasterAgilityBase = nil
local savedCasterStrengthBase = nil

local VOICE_LINES = {
    {
        file = "Sound\\vo\\Thuum\\Shout_NM001.mp3",
        text = "",
    },

    {
        file = "Sound\\vo\\Thuum\\Shout_NM002.mp3",
        text = "",
    },
}

local function getSelfLevel()
    local level = 1

    pcall(function()
        local levelStat = types.Actor.stats.level(self)

        if levelStat and type(levelStat.base) == "number" then
            level = levelStat.base
        elseif levelStat and type(levelStat.current) == "number" then
            level = levelStat.current
        end
    end)

    if type(level) ~= "number" then
        level = 1
    end

    return level
end

local npcLevel = getSelfLevel()

local knockChance = 0

if npcLevel < 10 then
    knockChance = 45
elseif npcLevel < 20 then
    knockChance = 60
elseif npcLevel < 30 then
    knockChance = 75
elseif npcLevel < 40 then
    knockChance = 85
elseif npcLevel < 50 then
    knockChance = 93
else
    knockChance = 98
end

-- =============================================================
-- HELPERS
-- =============================================================
local function isValidObject(obj)
    return obj and obj:isValid()
end

local function playerValid()
    return isValidObject(player)
end

local function isSelfDead()
    local dead = false

    pcall(function()
        local health = types.Actor.stats.dynamic.health(self)
        dead = health and health.current <= 0
    end)

    return dead
end

local function getCurrentCombatTarget()
    local target = nil

    pcall(function()
        target = AI.getActiveTarget('Combat')
    end)

    if isValidObject(target) then
        return target
    end

    return nil
end

local function distSqToObject(obj)
    if not isValidObject(obj) then
        return math.huge
    end

    local d = self.position - obj.position
    return d.x * d.x + d.y * d.y + d.z * d.z
end

local function isPlayerTarget(target)
    return playerValid() and target == player
end

local function canStartAgainstTarget(target)
    return not isSelfDead()
        and isValidObject(target)
        and target ~= self
        and distSqToObject(target) < DISTANCE_MAX_SQ
end

local function rollTier()
    local r = math.random(100)

    if r <= 33 then
        return 1
    elseif r <= 66 then
        return 2
    end

    return 3
end

local function getShakeScale()
    if npcLevel < 20 then
        return 1.0
    elseif npcLevel < 30 then
        return 1.25
    else
        return 1.6
    end
end

local function shouldKnock()
    if knockChance <= 0 then
        return false
    end

    return math.random(100) <= knockChance
end

local function getRandomVoiceLine()
    if #VOICE_LINES <= 0 then
        return nil
    end

    return VOICE_LINES[math.random(#VOICE_LINES)]
end

local function getRandomCooldown()
    return COOLDOWN_MIN + math.random() * (COOLDOWN_MAX - COOLDOWN_MIN)
end

-- =============================================================
-- CASTER TEMPORARY STAT LOCK
-- =============================================================
local function lockCasterStats()
    if casterStatsLocked then
        casterStatLockTimer = CASTER_STAT_LOCK_DURATION
        return
    end

    local agility = nil
    local strength = nil

    pcall(function()
        agility = types.Actor.stats.attributes.agility(self)
        strength = types.Actor.stats.attributes.strength(self)
    end)

    if agility then
        savedCasterAgilityBase = agility.base
        agility.base = 0
    end

    if strength then
        savedCasterStrengthBase = strength.base
        strength.base = 0
    end

    casterStatsLocked = true
    casterStatLockTimer = CASTER_STAT_LOCK_DURATION
end

local function restoreCasterStats()
    if not casterStatsLocked then
        return
    end

    local agility = nil
    local strength = nil

    pcall(function()
        agility = types.Actor.stats.attributes.agility(self)
        strength = types.Actor.stats.attributes.strength(self)
    end)

    if agility and savedCasterAgilityBase ~= nil then
        agility.base = savedCasterAgilityBase
    end

    if strength and savedCasterStrengthBase ~= nil then
        strength.base = savedCasterStrengthBase
    end

    casterStatsLocked = false
    casterStatLockTimer = 0.0

    savedCasterAgilityBase = nil
    savedCasterStrengthBase = nil
end

local function updateCasterStatLock(dt)
    if not casterStatsLocked then
        return
    end

    local agility = nil
    local strength = nil

    pcall(function()
        agility = types.Actor.stats.attributes.agility(self)
        strength = types.Actor.stats.attributes.strength(self)
    end)

    if agility then
        agility.base = 0
    end

    if strength then
        strength.base = 0
    end

    casterStatLockTimer = casterStatLockTimer - dt

    if casterStatLockTimer <= 0 then
        restoreCasterStats()
    end
end

local function addFatigueSpellToTarget(target)
    if not isValidObject(target) then
        return
    end

    pcall(function()
        types.Actor.spells(target):add(FATIGUE_SPELL_ID)
    end)

    fatigueTargets[target] = FATIGUE_SPELL_DURATION
end

local function removeFatigueSpellFromTarget(target)
    if not isValidObject(target) then
        fatigueTargets[target] = nil
        return
    end

    pcall(function()
        types.Actor.spells(target):remove(FATIGUE_SPELL_ID)
    end)

    fatigueTargets[target] = nil
end

local function updateFatigueTargets(dt)
    for target, timeLeft in pairs(fatigueTargets) do
        if not isValidObject(target) then
            fatigueTargets[target] = nil
        else
            timeLeft = timeLeft - dt

            if timeLeft <= 0 then
                removeFatigueSpellFromTarget(target)
            else
                fatigueTargets[target] = timeLeft
            end
        end
    end
end

-- =============================================================
-- CORE ACTIONS
-- =============================================================
local function playAnimation()
    if isSelfDead() then
        return
    end

    anim.playBlended(self, ANIM_ID, {
        priority = anim.PRIORITY.Scripted
    })
end

local function playVoice()
    if isSelfDead() then
        return
    end

    local line = getRandomVoiceLine()
    if not line then
        return
    end

    pcall(function()
        core.sound.say(line.file, self, line.text or "")
    end)
end

local function sendShoutToPlayer(targetIsPlayer)
    if isSelfDead() then
        return
    end

    if not playerValid() then
        return
    end

    player:sendEvent('DETD_ThuumShout', {
        tier = currentTier,
        shakeScale = getShakeScale(),

        -- Player only suffers fatigue/knockdown if they are the actual combat target.
        affectPlayer = targetIsPlayer,
        knockdown = targetIsPlayer and shouldKnock() or false,
    })
end

local function applyFatigueToNonPlayerTarget(target)
    if isSelfDead() then
        return
    end

    if not isValidObject(target) then return end

    target:sendEvent('DETD_ThuumFatigueHit', {
        duration = FATIGUE_SPELL_DURATION
    })
end

local function applyShoutToTarget(target)
    if isSelfDead() then
        return
    end

    local targetIsPlayer = isPlayerTarget(target)

    if not targetIsPlayer then
        applyFatigueToNonPlayerTarget(target)
    end

    sendShoutToPlayer(targetIsPlayer)
end

local function reset()
    stage = STAGE_IDLE
    timer = 0.0
    currentTier = 0
    currentTarget = nil
end

local function start(target)
    if isSelfDead() then
        return
    end

    currentTarget = target
    currentTier = rollTier()

    lockCasterStats()
    playAnimation()

    timer = SHOUT_DELAY
    stage = STAGE_WAIT_TO_SHOUT
end

-- =============================================================
-- EVENTS
-- =============================================================
local function onPlayerRef(data)
    player = data and data.player or nil
end

-- =============================================================
-- ENGINE
-- =============================================================
return {
    eventHandlers = {
        DETD_ThuumPlayerRef = onPlayerRef,
    },

    engineHandlers = {
        onUpdate = function(dt)
            updateCasterStatLock(dt)
            updateFatigueTargets(dt)

            if isSelfDead() then
                restoreCasterStats()
                reset()
                return
            end

            if cooldown > 0 then
                cooldown = cooldown - dt
                if cooldown < 0 then
                    cooldown = 0
                end
                return
            end

            if stage == STAGE_IDLE then
                aiCheckTimer = aiCheckTimer + dt
                if aiCheckTimer < AI_CHECK_DT then
                    return
                end

                aiCheckTimer = 0.0

                local target = getCurrentCombatTarget()
                if canStartAgainstTarget(target) then
                    start(target)
                end

                return
            end

            if stage == STAGE_WAIT_TO_SHOUT then
                timer = timer - dt

                if timer <= 0 then
                    if isValidObject(currentTarget) and not isSelfDead() then
                        playVoice()
                        applyShoutToTarget(currentTarget)
                    end

                    reset()
                    cooldown = getRandomCooldown()
                end
            end
        end
    }
}