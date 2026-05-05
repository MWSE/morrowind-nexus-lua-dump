local self   = require("openmw.self")
local types  = require("openmw.types")
local core   = require("openmw.core")
local async  = require("openmw.async")
local I      = require("openmw.interfaces")
local AI     = I.AI
local util   = require("openmw.util")
local time   = require("openmw_aux.time")

local shared   = require("scripts.bh_shared")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {}
for k, v in pairs(DEFAULTS) do cachedSettings[k] = v end

local state           = nil   -- nil | 'following' | 'awaiting_deportation' | 'escaped'
local player          = nil
local playerIsKhajiit = false
local fortId          = nil
local hoursPassed     = 0
local escapeTick      = false
local escortStartGameTime = nil
local lowHpTriggered  = false
local prisonerLevel   = 1     -- snapshot taken at escort start
local cleanupRequested = false

-- deportation data
local prisonCell   = nil
local prisonPos    = nil

-- constants used for cleanup-on-escape
local ESCAPED_FIGHT     = 100
local WANDER_DIST       = 256
local WANDER_DURATION   = 10800
local WANDER_IDLE       = {
    idle2 = 20, idle3 = 10, idle4 = 10, idle5 = 20,
    idle6 = 0,  idle7 = 10, idle8 = 5,  idle9 = 25,
}

local logEnabled = false
local function log(...)
    if logEnabled then print("[BH NPC]", self.object.recordId, ...) end
end

local stopEscapeTimer = function() end

local function pickMsg(pool)
    return pool[math.random(#pool)]
end

local function getNpcName()
    local rec = types.NPC.record(self.object)
    return rec and rec.name or self.object.recordId
end

local function isKhajiit()
    local rec  = types.NPC.record(self.object)
    local race = rec and rec.race or ""
    return shared.KHAJIIT_RACE[race:lower()] or false
end

-- run the escape cleanup on this actor
local function runEscapedCleanup()
    if cleanupRequested then return end
    cleanupRequested = true
    log("Running escaped cleanup")

    local fightStat = types.Actor.stats.ai.fight(self)
    fightStat.base = ESCAPED_FIGHT

    AI.removePackages("Follow")
    AI.startPackage({
        type     = "Wander",
        distance = WANDER_DIST,
        duration = WANDER_DURATION,
        idle     = WANDER_IDLE,
        isRepeat = true,
    })
end

-- in-cell escape: prisoner turns hostile while still with the player.
local function triggerEscape(reason)
    if state ~= 'following' then return end
    state      = 'escaped'
    escapeTick = false
    stopEscapeTimer()

    log("Escape triggered:", reason)

    AI.removePackages("Follow")

    local kh = isKhajiit()
    local pool
    if reason == "low_hp" then
        pool = kh and shared.MESSAGES.khajiit_low_hp_attack or shared.MESSAGES.low_hp_attack
    else
        pool = kh and shared.MESSAGES.khajiit_escape_attempt or shared.MESSAGES.escape_attempt
    end

    if player and player:isValid() then
        AI.startPackage({ type = "Combat", target = player })
        local msg = getNpcName() .. ": \"" .. pickMsg(pool) .. "\""
        player:sendEvent("BH_ShowMessage", { message = msg })
        player:sendEvent("BH_PrisonerEscaped", { npc = self.object })
    end

    -- disable gko knockdown for this NPC for the rest of their life
    self.object:sendEvent("GKD_DisableKnockdown", {})
    core.sendGlobalEvent("GKD_MarkDisableKnockdown", { npc = self.object })
end

-- hourly escape timer
local function getEscapeChance()
    local base = cachedSettings.ESCAPE_CHANCE or 10
    local lvl  = prisonerLevel or 1
    local bonus = math.max(0, lvl - 1)
    return base + bonus
end

-- roll escape once per game hour that has fully elapsed since escort start
local function rollEscapeIfDue()
    if not escapeTick then return end
    if state ~= 'following' then return end
    if not escortStartGameTime then return end
    if types.Actor.isDead(self.object) then return end

    local now = core.getGameTime()
    local elapsedHours = math.floor((now - escortStartGameTime) / time.hour)

    while hoursPassed < elapsedHours do
        hoursPassed = hoursPassed + 1
        log("Hour tick:", hoursPassed)
        if state ~= 'following' then return end
        if hoursPassed >= 4 then
            local chance = getEscapeChance()
            log("Rolling escape:", chance, "%")
            if math.random(100) <= chance then
                triggerEscape("escape")
                return
            end
        end
    end
end

-- periodic check on game time
stopEscapeTimer = time.runRepeatedly(rollEscapeIfDue, time.hour, { type = time.GameTime })

local hpTimer = 0
local HP_INTERVAL = 1.0 * time.second

local function onUpdate(dt)
    if state ~= 'following' then return end
    if not player or not player:isValid() then return end
    if types.Actor.isDead(self.object) then return end

    hpTimer = hpTimer + dt
    if hpTimer < HP_INTERVAL then return end
    hpTimer = 0

    -- low-HP check
    local hp = types.Actor.stats.dynamic.health(player)
    local hpRatio = (hp.base > 0) and (hp.current / hp.base) or 1
    if hpRatio >= 0.20 then
        lowHpTriggered = false
    end
    if not lowHpTriggered and hpRatio < 0.10 then
        lowHpTriggered = true
        triggerEscape("low_hp")
    end
end

local function onSave()
    return {
        state           = state,
        player          = player,
        playerIsKhajiit = playerIsKhajiit,
        fortId          = fortId,
        hoursPassed     = hoursPassed,
        escortStartGameTime = escortStartGameTime,
        prisonCell      = prisonCell,
        prisonPos       = prisonPos,
        lowHpTriggered  = lowHpTriggered,
        prisonerLevel   = prisonerLevel,
    }
end

local function onLoad(data)
    if not data then return end
    state           = data.state
    player          = data.player
    playerIsKhajiit = data.playerIsKhajiit or false
    fortId          = data.fortId
    hoursPassed     = data.hoursPassed or 0
    escortStartGameTime = data.escortStartGameTime
    prisonCell      = data.prisonCell
    prisonPos       = data.prisonPos
    lowHpTriggered  = data.lowHpTriggered or false
    prisonerLevel   = data.prisonerLevel or 1
    cleanupRequested = false
    log("Loaded state:", state or "nil")

    if state == 'following' then
        if player and player:isValid() then
            AI.removePackages("Combat")
            AI.startPackage({
                type        = "Follow",
                target      = player,
                isRepeat    = false,
                cancelOther = true,
            })
            escapeTick = true
            if not escortStartGameTime then
                escortStartGameTime = core.getGameTime() - (hoursPassed * time.hour)
            end
        else
            state = nil
        end
    elseif state == 'awaiting_deportation' then
        AI.startPackage({
            type     = "Wander",
            distance = 0,
            duration = 0,
            isRepeat = true,
        })
    end
end

local function onActive()
    if state == 'escaped' then
        runEscapedCleanup()
    end
end

local function onInactive()
    escapeTick = false
    if state == 'awaiting_deportation' and prisonCell and prisonPos then
        core.sendGlobalEvent("BH_DeportPrisoner", {
            npc  = self.object,
            cell = prisonCell,
            pos  = prisonPos
        })
    end
end

local function onSettingsUpdated(data)
    for k in pairs(cachedSettings) do
        if data[k] ~= nil then cachedSettings[k] = data[k] end
    end
    logEnabled = cachedSettings.ENABLE_LOGS
    log("Settings received: ESCAPE_CHANCE=", cachedSettings.ESCAPE_CHANCE)
end

local function onBHInit(data)
    if state then return end
    player          = data.player
    playerIsKhajiit = data.playerIsKhajiit or false
    prisonerLevel   = types.Actor.stats.level(self).current or 1
    hoursPassed     = 0
    escortStartGameTime = core.getGameTime()
    state           = 'following'
    escapeTick      = true

    AI.removePackages("Wander")
    AI.startPackage({
        type        = "Follow",
        target      = player,
        isRepeat    = false,
        cancelOther = true,
    })

    local orderPool  = playerIsKhajiit and shared.MESSAGES.khajiit_player_order or shared.MESSAGES.player_order
    local playerRec  = types.NPC.record(player)
    local playerName = playerRec and playerRec.name or "Hero"
    local orderMsg   = playerName .. ": \"" .. pickMsg(orderPool) .. "\""

    async:newUnsavableSimulationTimer(3 * time.second, function()
        if state ~= 'following' then return end
        if player and player:isValid() then
            player:sendEvent("BH_ShowMessage", { message = orderMsg })
        end
    end)

    if player and player:isValid() then
        player:sendEvent("BH_EscortStarted", {
            npc           = self.object,
            prisonerLevel = prisonerLevel,
        })
    end

    log("Escort started, level=", prisonerLevel)
end

local function onForceEscape()
    if state == 'awaiting_deportation' then return end
    state = 'escaped'
    escapeTick = false
    stopEscapeTimer()
    log("ForceEscape received")
    self.object:sendEvent("GKD_DisableKnockdown", {})
    core.sendGlobalEvent("GKD_MarkDisableKnockdown", { npc = self.object })
    runEscapedCleanup()
end

local function onWaitForDeportation(data)
    state      = 'awaiting_deportation'
    stopEscapeTimer()
    fortId     = data.fortId
    prisonCell = data.cell
    prisonPos  = util.vector3(data.pos.x, data.pos.y, data.pos.z)

    escapeTick = false
    AI.removePackages("Follow")
    AI.startPackage({
        type     = "Wander",
        distance = 0,
        duration = 0,
        isRepeat = true,
    })

    if data.player and data.player:isValid() then
        data.player:sendEvent("BH_EscortEnded", { reason = "delivered" })
    end
    log("Waiting for deportation to", prisonCell)
end

local function onDied()
    log("Died in state:", state or "nil")
    escapeTick = false
    stopEscapeTimer()
    local wasPrisoner = (state == 'following' or state == 'escaped')
    if wasPrisoner and player and player:isValid() then
        player:sendEvent("BH_EscortEnded", { reason = "died", npc = self.object })
    end
    state = nil
    core.sendGlobalEvent("BH_RequestRemoval", self.object)
end

local function onKillSelf()
    local hp = types.Actor.stats.dynamic.health(self)
    hp.current = 0
    log("KillSelf executed")
end

return {
    engineHandlers = {
        onSave     = onSave,
        onLoad     = onLoad,
        onActive   = onActive,
        onUpdate   = onUpdate,
        onInactive = onInactive,
    },

    eventHandlers = {
        BH_SettingsUpdated    = onSettingsUpdated,
        BH_Init               = onBHInit,
        BH_ForceEscape        = onForceEscape,
        BH_WaitForDeportation = onWaitForDeportation,
        Died                  = onDied,
        BH_KillSelf           = onKillSelf,
    },
}