local world = require('openmw.world')

local mDef = require('scripts.skill-evolution.config.definition')

if not mDef.isOpenMW50 then return end

local lastUpdateTime = 0

local function sendWerewolfClawMult()
    for _, player in ipairs(world.players) do
        player:sendEvent(mDef.events.setWerewolfClawMult, world.mwscript.getGlobalVariables()[mDef.mwscriptGlobalVars.werewolfClawMult])
    end
end

local function skipGameHours(player, hours)
    world.mwscript.getGlobalVariables(player)[mDef.mwscriptGlobalVars.skipGameHours] = hours
end

local function onGameUnpaused()
    for _, player in ipairs(world.players) do
        player:sendEvent(mDef.events.onGameUnpaused)
    end
end

local function onInit()
    sendWerewolfClawMult()
end

local function onLoad()
    onInit()
end

local function onUpdate(deltaTime)
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 5 then return end
    lastUpdateTime = 0
    onInit()
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        [mDef.events.skipGameHours] = function(data) skipGameHours(data.player, data.hours) end,
        Unpause = onGameUnpaused,
    }
}