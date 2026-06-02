local self   = require("openmw.self")
local types  = require("openmw.types")
local AI     = require("openmw.interfaces").AI
local Actor  = types.Actor

-- forward declarations
local onUpdate, onInactive
local onDied, onHit, onWakeUp, onShutdown

local health     = Actor.stats.dynamic.health(self)
local fatigue    = Actor.stats.dynamic.fatigue(self)
local lastHealth = health.current
local wasHostile = false
local dead       = false
local awake      = false
local muted      = false

local heartbeatTimer = 0
local updateTimer    = 0
local HEARTBEAT_INTERVAL = 0.5
local UPDATE_INTERVAL    = 0.1

local rawId = tostring(self.object.id)
local id    = tonumber(rawId:match("0x([%da-fA-F]+)"), 16) or rawId

local player = nil

local function isTargetingPlayer()
    local ok, targets = pcall(function() return AI.getTargets("Combat") end)
    if not ok then return false end
    for _, t in ipairs(targets) do
        if t == player then return true end
    end
    return false
end

local function sendUpdate(stopped)
    player:sendEvent("HudEnemyUpdate", {
        id         = id,
        object     = self.object,
        health     = health.current,
        maxHealth  = health.base,
        fatigue    = fatigue.current,
        maxFatigue = fatigue.base,
        stopped    = stopped or false,
    })
end

local function wake(plr)
    if dead then return end
    if awake then return end
    player = plr
    awake = true
    updateTimer = UPDATE_INTERVAL
end

local function sleep()
    awake = false
    wasHostile = false
    heartbeatTimer = 0
    updateTimer = 0
end

-- engine handlers
onUpdate = function(dt)
    if not awake then return end

    updateTimer = updateTimer + dt
    if updateTimer < UPDATE_INTERVAL then return end
    updateTimer = 0

    if dead then return end

    if Actor.isDead(self.object) then
        if wasHostile then sendUpdate(true) end
        dead = true
        return
    end

    local hostile = isTargetingPlayer()
    if hostile then
        local healthChanged = health.current ~= lastHealth
        heartbeatTimer = heartbeatTimer + UPDATE_INTERVAL
        if not wasHostile or healthChanged or heartbeatTimer >= HEARTBEAT_INTERVAL then
            sendUpdate(false)
            heartbeatTimer = 0
        end
        wasHostile = true
    elseif wasHostile then
        sendUpdate(true)
        sleep()
    else
        sleep()
    end
    lastHealth = health.current
end

onInactive = function()
    if wasHostile and player then
        sendUpdate(true)
    end
    sleep()
end

-- event handlers
onDied = function()
    if not player then return end
    if wasHostile then sendUpdate(true) end
    dead  = true
    awake = false
end

onHit = function(attack)
    if not attack or not attack.attacker then return end
    if not types.Player.objectIsInstance(attack.attacker) then return end
    if dead then return end
    if muted then return end
    player = attack.attacker
    awake  = true
    sendUpdate(false)
    wasHostile     = true
    heartbeatTimer = 0
    lastHealth     = health.current
end

onWakeUp = function(data)
    if dead then return end
    if not data or not data.player then return end
    muted = false
    if awake then return end
    wake(data.player)
end

onShutdown = function()
    muted = true
    sleep()
end

return {
    engineHandlers = {
        onUpdate   = onUpdate,
        onInactive = onInactive,
    },
    eventHandlers = {
        Died        = onDied,
        Hit         = onHit,
        HudWakeUp   = onWakeUp,
        HudShutdown = onShutdown,
    },
}