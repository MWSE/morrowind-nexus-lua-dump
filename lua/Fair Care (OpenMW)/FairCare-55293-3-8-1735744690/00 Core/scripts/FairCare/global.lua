local T = require('openmw.types')
local world = require('openmw.world')
local async = require('openmw.async')

local mSettings = require('scripts.FairCare.settings')
local mMagic = require('scripts.FairCare.magic')
local mData = require('scripts.FairCare.data')
local mTools = require('scripts.FairCare.tools')

local state = {
    trackedActors = {},
    settingsKeys = {},
}

local areSettingsUpdated = false

local potionsAverageRestoredHealth = {}
for _, potionId in ipairs(mData.restoreHealthPotions) do
    potionsAverageRestoredHealth[potionId] = mMagic.getPotionAverageRestoredHealth(potionId)
end

local function addPotions(actor)
    state.trackedActors[actor.id] = actor

    local actorBaseHealth = T.Actor.stats.dynamic.health(actor).base
    local expectedHealthRatio = math.random(
            mSettings.getSection(mSettings.potionSettingsKey):get("minRestoredHealthByPotions"),
            mSettings.getSection(mSettings.potionSettingsKey):get("maxRestoredHealthByPotions")) / 100
    local expectedHealth = actorBaseHealth * expectedHealthRatio
    local restoredHealth = 0
    local messages = {}
    local needPotions = true
    local potions = {}
    while (needPotions) do
        needPotions = false
        for _, potionId in ipairs(mData.restoreHealthPotions) do
            local potionHealth = potionsAverageRestoredHealth[potionId]
            if not needPotions and restoredHealth + potionHealth <= expectedHealth and potionHealth <= actorBaseHealth then
                table.insert(messages, string.format("\"%s\" (%s HP)", T.Potion.records[potionId].name, potionHealth))
                local potion = world.createObject(potionId, 1)
                potion:addScript(mSettings.potionScriptPath, {})
                potion:moveInto(T.Actor.inventory(actor))
                table.insert(potions, potion)
                restoredHealth = restoredHealth + potionHealth
                needPotions = true
            end
        end
    end

    mTools.debugPrint(string.format("%s (%s HP) gained potions to restore %d%% of his HP:\n---- %s",
            mTools.objectId(actor), actorBaseHealth, expectedHealthRatio * 100, table.concat(messages, ", ")))
end

local function removePotions(actor)
    local count = 0
    for _, potion in ipairs(T.Actor.inventory(actor):getAll(T.Potion)) do
        if potion:hasScript(mSettings.potionScriptPath) then
            count = count + potion.count
            potion:remove(potion.count)
        end
    end
    if count ~= 0 then
        mTools.debugPrint(string.format("Removed %d Fair Care potions from %s's inventory", count, mTools.objectId(actor)))
    end
    return count ~= 0
end

local function cleanState()
    local count = 0
    for id, actor in pairs(state.trackedActors) do
        if mTools.isObjectInvalid(actor) then
            count = count + 1
            state.trackedActors[id] = nil
        end
    end
    if count ~= 0 then
        mTools.debugPrint(string.format("Removed %d invalid tracked actors", count))
    end
end

local function clearActorData(actor, types, callback)
    local changed = false
    if types[mData.globalDataTypes.potions] then
        if removePotions(actor, callback) then
            changed = true
        end
        if not callback then
            actor:sendEvent("fairCare_clearPotionsState")
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
        actor:sendEvent("fairCare_onActorActive")
    end
    state.trackedActors = {}
    mTools.debugPrint(string.format("Cleared state of %d actors", count))
end

local function onSave()
    return state
end

local function onLoad(data)
    state = data or state
    cleanState()
end

local settingsKeyFunctions = {
    [mData.globalDataTypes.potions] = function()
        local potionSection = mSettings.getSection(mSettings.potionSettingsKey)
        return table.concat({
            tostring(mSettings.getSection(mSettings.globalKey):get("addingPotionsEnabled")),
            tostring(potionSection:get("potionsForHealers")),
            tostring(potionSection:get("minRestoredHealthByPotions")),
            tostring(potionSection:get("maxRestoredHealthByPotions")),
        }, ",")
    end
}

mSettings.getSection(mSettings.globalKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.creaturesKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.healingTweaksKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.regenSettingsKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.potionSettingsKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.woundedImpactsKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))
mSettings.getSection(mSettings.healingTweaksKey):subscribe(async:callback(function(_, _) areSettingsUpdated = true end))

local function onUnpause()
    if not areSettingsUpdated then return end
    areSettingsUpdated = false

    local typesToClear = {}
    for key in pairs(mData.globalDataTypes) do
        local getSettingsKey = settingsKeyFunctions[key]
        if getSettingsKey then
            local settingsKey = getSettingsKey()
            if settingsKey ~= state.settingsKeys[key] then
                state.settingsKeys[key] = settingsKey
                typesToClear[key] = true
                mTools.debugPrint(string.format("Settings \"%s\" have been updated", key))
            end
        end
    end
    if next(typesToClear) then
        clearState(typesToClear)
    end
end

local function onInit()
    for key in pairs(mData.globalDataTypes) do
        state.settingsKeys[key] = settingsKeyFunctions[key]()
    end
end

return {
    interfaceName = mSettings.MOD_NAME,
    interface = {
        version = mSettings.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Unpause = onUnpause,
        fairCare_addPotions = addPotions,
        fairCare_clearState = function(data) clearState(data.types) end,
        fairCare_clearActorData = function(data) clearActorData(data.actor, data.types, data.callback) end,
    }
}
