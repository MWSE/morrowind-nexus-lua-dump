local T = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')

local mDef = require('scripts.skill-evolution.config.definition')

if not mDef.isOpenMW50 then return end

local lastUpdateTime = 0
local hoursToSkip = 0
local hoursTpSkipEvents = {}

local function sendWerewolfClawMult()
    for _, player in ipairs(world.players) do
        player:sendEvent(mDef.events.setWerewolfClawMult, world.mwscript.getGlobalVariables()[mDef.mwscriptGlobalVars.werewolfClawMult])
    end
end

local function skipGameHours(hours, event)
    hoursToSkip = hoursToSkip + hours
    if event then
        hoursTpSkipEvents[event.name] = event
    end
end

local removeObject = function(object, count)
    object:remove(count)
end

local addObject = function(player, recordId, count)
    local newObject = world.createObject(recordId, count)
    newObject:moveInto(player.type.inventory(player))
end

local addNewPotion = function(player, basePotion, recordPatch, count)
    recordPatch.template = basePotion.type.record(basePotion)
    local record = world.createRecord(T.Potion.createRecordDraft(recordPatch))
    addObject(player, record.id, count)
end

local function onInit()
    sendWerewolfClawMult()
end

local function onLoad()
    onInit()
end

local function onUpdate(deltaTime)
    if hoursToSkip > 0 and not core.isWorldPaused() then
        world.mwscript.getGlobalVariables()[mDef.mwscriptGlobalVars.skipGameHours] = hoursToSkip
        hoursToSkip = 0
        for _, event in pairs(hoursTpSkipEvents) do
            event.object:sendEvent(event.name, event.data)
        end
        hoursTpSkipEvents = {}
    end
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
        [mDef.events.skipGameHours] = function(data) skipGameHours(data.hours, data.event) end,
        [mDef.events.removeObject] = function(data) removeObject(data.object, data.count) end,
        [mDef.events.addObject] = function(data) addObject(data.player, data.recordId, data.count) end,
        [mDef.events.addNewPotion] = function(data) addNewPotion(data.player, data.basePotion, data.recordPatch, data.count) end,
    }
}