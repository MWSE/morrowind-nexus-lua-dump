local T = require('openmw.types')
local world = require('openmw.world')
local async = require('openmw.async')

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mStore = require('scripts.FairCare.config.store')
local mTypes = require('scripts.FairCare.config.types')
local mMagic = require('scripts.FairCare.util.magic')
local mTools = require('scripts.FairCare.util.tools')

local state = {
    trackedActors = {},
    settingsKeys = {},
}

local areSettingsUpdated = false

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
            mStore.groups.potions.get("minRestoredHealthByPotions"),
            mStore.groups.potions.get("maxRestoredHealthByPotions")) / 100
    local expectedHealth = actorBaseHealth * expectedHealthRatio

    local actorWealth = getItemsValueSum(actor)
    local expectedValueRatio = mStore.groups.potions.get("maxPotionsTotalValueOverNpcWealth") / 100
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

local function cleanState()
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
    cleanState()
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
    cleanState()
end

local settingsKeyFunctions = {
    [mTypes.globalDataTypes.potions] = function()
        return table.concat({
            tostring(mStore.groups.global.get("addingPotionsEnabled")),
            tostring(mStore.groups.potions.get("potionsForHealers")),
            tostring(mStore.groups.potions.get("minRestoredHealthByPotions")),
            tostring(mStore.groups.potions.get("maxRestoredHealthByPotions")),
            tostring(mStore.groups.potions.get("maxPotionsTotalValueOverNpcWealth")),
        }, ",")
    end
}

for _, group in pairs(mStore.groups) do
    group.get():subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
end

local function onUnpause()
    if not areSettingsUpdated then return end
    areSettingsUpdated = false

    local typesToClear = {}
    for key in pairs(mTypes.globalDataTypes) do
        local getSettingsKey = settingsKeyFunctions[key]
        if getSettingsKey then
            local settingsKey = getSettingsKey()
            if settingsKey ~= state.settingsKeys[key] then
                state.settingsKeys[key] = settingsKey
                typesToClear[key] = true
                log(string.format("Settings \"%s\" have been updated", key))
            end
        end
    end
    if next(typesToClear) then
        clearState(typesToClear)
    end
end

local function onInit()
    for key in pairs(mTypes.globalDataTypes) do
        state.settingsKeys[key] = settingsKeyFunctions[key]()
    end
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onInit = onInit,
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
