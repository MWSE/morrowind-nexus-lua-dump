local T = require('openmw.types')
local world = require('openmw.world')

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mStore = require('scripts.FairCare.config.store')
local mTypes = require('scripts.FairCare.config.types')
local mMagic = require('scripts.FairCare.util.magic')
local mTools = require('scripts.FairCare.util.tools')

mStore.registerGroups()

local state = {
    trackedActors = {},
    settingsKeys = {},
}

local areSettingsUpdated = false
local settingChanges = {}

local potionsStats = {}
for _, potionId in ipairs(mTypes.restoreHealthPotions) do
    potionsStats[potionId] = mMagic.getPotionStats(potionId)
end

local function getItemsValueSum(actor)
    local inventory = actor.type.inventory(actor)
    local sum = 0
    for _, item in ipairs(inventory:getAll()) do
        sum = sum + (item.type.record(item).value or 0)
    end
    return sum == 0 and 1 or sum
end

local function addPotions(actor)
    if actor.type == T.NPC and T.NPC.isWerewolf(actor) then
        log(string.format("%s won't get any potions because he's a werewolf", mTools.objectId(actor)))
        return
    end
    if actor.type.record(actor).mwscript == "slavescript" then
        log(string.format("%s won't get any potions because he's a slave", mTools.objectId(actor)))
        return
    end

    state.trackedActors[actor.id] = actor

    local actorBaseHealth = T.Actor.stats.dynamic.health(actor).base
    local expectedHealthRatio = math.random(
            mStore.settings.minRestoredHealthByPotions.value,
            mStore.settings.maxRestoredHealthByPotions.value) / 100
    local expectedHealth = actorBaseHealth * expectedHealthRatio

    local actorWealth = getItemsValueSum(actor)
    local expectedValueRatio = mStore.settings.maxPotionsTotalValueOverNpcWealth.value / 100
    local expectedValue = actorWealth * expectedValueRatio

    local restoredHealth = 0
    local valueSum = 0
    local messages = {}
    local needPotions = true
    while (needPotions) do
        needPotions = false
        for _, potionId in ipairs(mTypes.restoreHealthPotions) do
            local potionHealth = potionsStats[potionId].restoredHealth
            local potionValue = potionsStats[potionId].value
            if not needPotions and restoredHealth + potionHealth <= expectedHealth and potionHealth <= actorBaseHealth and valueSum + potionValue < expectedValue then
                table.insert(messages, string.format("\"%s\" (%s HP %d value)", T.Potion.records[potionId].name, potionHealth, potionValue))
                local potion = world.createObject(potionId, 1)
                potion:addScript(mDef.potionScriptPath, {})
                potion:moveInto(T.Actor.inventory(actor))
                restoredHealth = restoredHealth + potionHealth
                valueSum = valueSum + potionValue
                needPotions = true
            end
        end
    end

    if #messages > 0 then
        log(string.format("%s (%s HP) gained potions to restore %d%% of his HP up to %d total value:\n---- %s",
                mTools.objectId(actor), actorBaseHealth, expectedHealthRatio * 100, actorWealth, table.concat(messages, ", ")))
    else
        log(string.format("%s (%s HP) did not gained any potions to restore %d%% of his HP up to %d total value",
                mTools.objectId(actor), actorBaseHealth, expectedHealthRatio * 100, actorWealth))
    end
end

local function removePotions(actor)
    local count = 0
    for _, potion in ipairs(T.Actor.inventory(actor):getAll(T.Potion)) do
        if potion:hasScript(mDef.potionScriptPath) then
            count = count + potion.count
            potion:remove(potion.count)
        end
    end
    if count ~= 0 then
        log(string.format("Removed %d Fair Care potions from %s's inventory", count, mTools.objectId(actor)))
    end
    return count ~= 0
end

local function fixObjects()
    local invalidCt, changedCt = 0, 0
    for id, actor in pairs(state.trackedActors) do
        if mTools.isObjectInvalid(actor) then
            invalidCt = invalidCt + 1
            state.trackedActors[id] = nil
        elseif id ~= actor.id then
            changedCt = changedCt + 1
            state.trackedActors[id] = nil
            state.trackedActors[actor.id] = actor
        end
    end
    if invalidCt ~= 0 then
        log(string.format("Cleaned %d tracked actors (%d invalid, %d IDs updated)", invalidCt + changedCt, invalidCt, changedCt))
    end
end

local function clearActorData(actor, types, callback)
    local changed = false
    if types[mTypes.globalDataTypes.potions] then
        if removePotions(actor, callback) then
            changed = true
        end
        if not callback then
            actor:sendEvent(mDef.events.clearPotionsState)
        end
    end
    if callback then
        actor:sendEvent(callback)
    end
    return changed
end

local function clearState(types)
    fixObjects()
    local count = 0
    local actors = {}
    for _, actor in pairs(state.trackedActors) do
        actors[actor.id] = actor
    end
    for _, actor in ipairs(world.activeActors) do
        actors[actor.id] = actor
    end
    for _, actor in pairs(actors) do
        if clearActorData(actor, types) then
            count = count + 1
        end
    end
    for _, actor in ipairs(world.activeActors) do
        actor:sendEvent(mDef.events.onActorActive)
    end
    state.trackedActors = {}
    log(string.format("Cleared state of %d actors", count))
end

local function onSave()
    return state
end

local function onLoad(data)
    state = data or state
    fixObjects()
end

local function onUnpause()
    if not areSettingsUpdated then return end
    areSettingsUpdated = false

    local dataTypesToClear = {}
    for key, changes in pairs(settingChanges) do
        if mStore.settings[key].clearCategory and changes.old ~= changes.new then
            dataTypesToClear[mStore.settings[key].clearCategory] = true
        end
    end
    settingChanges = {}
    if next(dataTypesToClear) then
        clearState(dataTypesToClear)
    end
end

mStore.addTrackerCallback(function(key, oldValue)
    local newValue = mStore.settings[key].value
    if newValue ~= nil and oldValue ~= newValue then
        areSettingsUpdated = true
        if settingChanges[key] then
            settingChanges[key].new = newValue
        else
            settingChanges[key] = { old = oldValue, new = newValue }
        end
    end
end)

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Unpause = onUnpause,
        [mDef.events.addPotions] = addPotions,
        [mDef.events.clearState] = function(data) clearState(data.types) end,
        [mDef.events.clearActorData] = function(data) clearActorData(data.actor, data.types, data.callback) end,
    }
}
