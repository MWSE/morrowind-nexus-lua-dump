local core = require('openmw.core')
local T = require('openmw.types')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')

local mDef = require('scripts.HBFS.config.definition')
if not mDef.isOpenMW49OrAbove then return end

local mS = require('scripts.HBFS.config.settings')
local log = require('scripts.HBFS.util.log')
local mStore = require('scripts.HBFS.config.store')
local mWorld = require('scripts.HBFS.util.world')
local mItems = require('scripts.HBFS.util.items')
local mTools = require('scripts.HBFS.util.tools')

mStore.registerGroups()

local l10n = core.l10n(mDef.MOD_NAME)

local lastUpdateTime = 0
local settingsChanged = false

local state = {
    playerLevel = 1,
    playerConjuration = 1,
    playerEnchant = 1,
    settingsKey = "",
    settings = {},
    openedContainers = {},
    actors = {},
    lastConjurationData = nil,
    actualSettings = {
        attributes = {},
        dynamicStats = {},
        followerPercent = 1,
        noBackRunningActors = nil,
        key = "",
    },
}

local eventTypes = {
    set = "set",
    reset = "reset",
    rescale = "rescale",
}

local function initActorData(actor, newData)
    if newData.playerSummon and state.lastConjurationData then
        local delay = core.getSimulationTime() - state.lastConjurationData.time
        -- max delay for spell cast animation
        if delay < 3 then
            newData.conjurationSource = state.lastConjurationData.source
        else
            log(string.format("Summon %s of source %s spawned too late (delay=%.2fs)", mTools.objectId(actor), state.lastConjurationData.source, delay), true)
        end
        newData.playerSummon = nil
        state.lastConjurationData = nil
    end
    if newData.isCorpse and mStore.settings.conditionalItemDegradation.value then
        log(string.format("%s is a corpse, his equipment will be degraded", mTools.objectId(actor)))
        mItems.degradeLootItems(actor, newData)
    end
    if not next(newData) then
        return
    end
    local data = state.actors[actor.id]
    if not data then
        data = { object = actor }
        state.actors[actor.id] = data
    end
    for key, value in pairs(newData) do
        if not data[key] then
            log(string.format("%s has new data: %s = %s", mTools.objectId(actor), key, value))
            data[key] = value
        end
    end
end

local function onActorActive(actor)
    actor:sendEvent(mDef.events.setActorStats, {
        settings = mS.getActorSettings(state, actor),
        type = eventTypes.set,
    })
end

local function onActorDied(actor)
    if not mStore.settings.conditionalItemDegradation.value then return end
    local data = state.actors[actor.id] or {}
    log(string.format("%s died, his equipment will be degraded", mTools.objectId(actor)))
    mItems.degradeLootItems(actor, data)
end

local function updateAllActorsStats(isLevelUp)
    local actualSettingsKey = state.actualSettings.key
    mS.setActualSettings(state)
    if actualSettingsKey == state.actualSettings.key then return end

    log(string.format("Actors settings updated: %s", aux_util.deepToString(state.actualSettings, 3)))
    for _, player in ipairs(world.players) do
        if not isLevelUp and T.Player.isCharGenFinished(player) then
            player:sendEvent(mDef.events.showMessage, l10n("updateActorsStats"))
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if actor.type ~= T.Player then
            actor:sendEvent(mDef.events.setActorStats, {
                settings = mS.getActorSettings(state, actor),
                type = isLevelUp and eventTypes.rescale or eventTypes.reset,
            })
        end
    end
end

local function applySettings()
    if not settingsChanged then return end
    settingsChanged = false
    updateAllActorsStats(false)
end

local function setPlayerStats()
    local prevLevel, prevConjuration, prevEnchant = state.playerLevel, state.playerConjuration, state.playerEnchant
    state.playerLevel = mTools.average(world.players, function(player) return T.Actor.stats.level(player).current end)
    state.playerConjuration = mTools.average(world.players, function(player) return T.NPC.stats.skills.conjuration(player).modified end)
    state.playerEnchant = mTools.average(world.players, function(player) return T.NPC.stats.skills.enchant(player).modified end)
    return prevLevel ~= state.playerLevel or prevConjuration ~= state.playerConjuration or prevEnchant ~= state.playerEnchant
end

local function onInit()
    setPlayerStats()
    mS.updateSettings(state)
    updateAllActorsStats(false)
end

local function onUpdate(deltaTime)
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 1 then return end
    deltaTime = lastUpdateTime
    lastUpdateTime = 0

    if setPlayerStats() then
        mS.updateSettings(state)
        updateAllActorsStats(true)
    end
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version < 2.52 then
            data.state.openedContainers = {}
        end
        if data.version < 2.6 then
            data.state.actors = {}
        end
        if data.version == 2.6 then
            local newActors = {}
            for id, actorData in pairs(data.state.actors) do
                actorData.baseFightValue = nil
                if actorData.isCorpse then
                    newActors[id] = actorData
                end
            end
            data.state.actors = newActors
        end
        if data.version < 2.8 then
            data.state.playerConjuration = 1
            data.state.playerEnchant = 1
        end
        state = data.state
    end
    mWorld.fixObjects({ openedContainers = state.openedContainers, actors = state.actors })
    onInit()
end

mStore.addTrackerCallback(function(key, oldValue)
    settingsChanged = true
    mS.updateSetting(key, oldValue)
end)

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getSettings = function() return state.actualSettings end,
        getState = function() return state end,
    },
    eventHandlers = {
        Unpause = applySettings,
        [mDef.events.forwardToPlayers] = function(data) mWorld.forwardToPlayers(data.data, data.event) end,
        [mDef.events.updatePercentSetting] = function(key) mS.updatePercentSetting(state, mStore.settings[key]) end,
        [mDef.events.updatePercentSettings] = function() mS.updatePercentSettings(state) end,
        [mDef.events.updateRangeSettings] = function() mS.updateRangeSettings(state) end,
        [mDef.events.moveItem] = function(data) mWorld.moveItem(data.item, data.actor) end,
        [mDef.events.modItemCondition] = function(data) mWorld.modItemCondition(data.updates, data.refreshUi) end,
        [mDef.events.commitTheft] = function(data) mItems.commitTheft(data.player, data.value) end,
        [mDef.events.onActorDied] = onActorDied,
        [mDef.events.onOpenContainer] = function(container) mItems.onOpenContainer(state, container) end,
        [mDef.events.initActorData] = function(data) initActorData(data.actor, data.data) end,
        [mDef.events.conjurationCast] = function(data) state.lastConjurationData = data end,
    },
    engineHandlers = {
        onInit = onInit,
        onActorActive = onActorActive,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}