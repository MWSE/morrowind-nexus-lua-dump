local core = require("openmw.core")
local async = require('openmw.async')
local T = require("openmw.types")
local I = require("openmw.interfaces")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mSTracker = require("scripts.fresh-loot.settings.tracker")
local mMod = require("scripts.fresh-loot.loot.modifier")
local mStats = require("scripts.fresh-loot.loot.stats")
local mCell = require("scripts.fresh-loot.loot.cell")
local mConvert = require("scripts.fresh-loot.loot.convert")
local mWorld = require("scripts.fresh-loot.util.world")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mInterop = require("scripts.fresh-loot.util.interop")
local mTest = require("scripts.fresh-loot.util.test")

local l10n = core.l10n(mDef.MOD_NAME);
local lastCheckTime = 0
local notSavedStateKeys = { settings = true, cache = true }

local state = {
    settings = {},
    cache = mTypes.new.cache(),
    containers = {},
    actors = {},
    items = {},
    cellsAnalyzed = {},
    actorsToRefresh = {},
    validItems = {},
    npcsWealth = {},
    npcLevels = {},
    factionRanksLevel = {},
    playerLevel = 1,
}

local function onLootOpen(loot, actor)
    if actor.type == T.Player then
        mConvert.onContainerOpen(state, loot, true)
    end
end

local function fixObjects()
    local dataLists = { containers = state.containers, actors = state.actors, items = state.items, actorsToRefresh = state.actorsToRefresh }
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if mObj.isObjectInvalid(data.object) then
                invalidCt = invalidCt + 1
                dataList[id] = nil
            elseif id ~= data.object.id then
                changedIdCt = changedIdCt + 1
                dataList[id] = nil
                dataList[data.object.id] = data
            end
        end
        if invalidCt + changedIdCt > 0 then
            log(string.format("Cleared %d invalid references and fixed %d changed IDs for %s", invalidCt, changedIdCt, key))
        end
    end
end

local function onActorActive(actor)
    if not state.settings[mStore.cfg.enabled.key] then return end

    if state.actorsToRefresh[actor.id] then
        async:newSimulationTimer(0.5 + math.random() / 2,
                async:registerTimerCallback(mDef.callbacks.onActorActive .. actor.id, function(restoreTypes)
                    log(string.format("Actor \"%s\" may be refreshed", actor.recordId))
                    mConvert.restoreItems(state, mTypes.new.itemRestoreFilter(restoreTypes, actor), true)
                    onActorActive(actor)
                end),
                state.actorsToRefresh[actor.id].restoreTypes)
        state.actorsToRefresh[actor.id] = nil
        return
    end

    local player = mWorld.getClosestPlayer(actor)
    if not player then return end
    if not state.cellsAnalyzed[actor.cell.id] then
        state.cellsAnalyzed[actor.cell.id] = true
        mCell.analyseCell(state, actor.cell, player)
    else
        mCell.analyseActor(state, actor, player)
    end
end

local function onUpdate(deltaTime)
    if not state.settings[mStore.cfg.enabled.key] then return end

    lastCheckTime = lastCheckTime + deltaTime
    if lastCheckTime < 1 then return end
    lastCheckTime = 0

    local prevLevel = state.playerLevel
    state.playerLevel = mWorld.getPlayerLevel()

    if state.playerLevel == prevLevel
            or state.settings[mStore.cfg.playerLevelScaling.key] == 0
            or not state.settings[mStore.cfg.doEquippedItems.key] then
        return
    end

    log(string.format("Player level just increased (from %s to %s), actors' equipments will be refreshed next time the cell is active again",
            prevLevel, state.playerLevel))
    for _, actor in ipairs(mWorld.getActiveActors()) do
        local restoreTypes = { [mTypes.itemRestoreTypes.Equipped] = true }
        if state.actorsToRefresh[actor.id] then
            mHelpers.addAllToMap(restoreTypes, state.actorsToRefresh[actor.id].restoreTypes)
        end
        state.actorsToRefresh[actor.id] = mTypes.new.actorsToRefreshData(actor, restoreTypes)
    end
    mConvert.restoreItems(
            state,
            mTypes.new.itemRestoreFilter({ [mTypes.itemRestoreTypes.Equipped] = true }, nil, state.actorsToRefresh),
            true)
end

local function disableMod(message)
    I.Settings.updateRendererArgument(mStore.section.global.key, mStore.cfg.enabled.key, { disabled = true })
    mStore.cfg.enabled.set(false)
    core.sendGlobalEvent(mDef.events.sendPlayersEvent, mTypes.new.playersEvent(mDef.events.showMessage, mTypes.new.message(message)))
end

local function checkCompatibility(saveVersion)
    if not mDef.isLuaApiRecentEnough then
        disableMod(l10n(mDef.getMessageKeyIfOpenMWTooOld("")))
        return false
    end
    if saveVersion and saveVersion < 2.0 then
        disableMod(l10n("requiresNewGame"))
        return false
    end
    return true
end

local function onPlayerAdded()
    mInterop.onPlayerAdded(state)
end

local function onInit()
    if not checkCompatibility() then return end
    state.playerLevel = mWorld.getPlayerLevel()
    mSTracker.loadSettings(state)
    mMod.init(state, require("scripts.fresh-loot.modifiers.main"))
    local ids = require("scripts.fresh-loot.item-lists.main")
    state.cache.validItems = ids.itemIds
    state.cache.itemLists = ids.listIds
    mSTracker.setItemListsSetting(state)
    if #state.validItems ~= 0 then
        log(string.format("Loading %d learned valid item ids...", #state.validItems))
        mHelpers.addAllToHashset(state.cache.validItems, state.validItems)
    end
    log(string.format("Loaded a total of %d valid item ids.", mHelpers.mapSize(state.cache.validItems)))
    state.cache.excluded = require("scripts.fresh-loot.exclusions.main")
end

local function onSave()
    if not state.settings[mStore.cfg.enabled.key] then return end
    return {
        state = mHelpers.addAllToMap({}, state, function(key, _) return not notSavedStateKeys[key] end),
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if not checkCompatibility(data and data.version) then return end
    if data then
        state = data.state
        log(string.format("Loading Fresh Loot save v%s...", data.version))
        if data.version < 2.1 then
            state.npcLevels = {}
        end
        if data.version < 2.3 then
            state.cellsToRefresh = nil
            state.actorsToRefresh = {}
        end
    end
    state.settings = {}
    state.cache = mTypes.new.cache()
    fixObjects()
    onInit()
end

local function onUnpause()
    local restoreTypes = mSTracker.checkSettings()
    if restoreTypes then
        state.cellsAnalyzed = {}
        mConvert.restoreItems(state, mTypes.new.itemRestoreFilter(restoreTypes), false)

        local activeCells = mWorld.getActiveCells()
        for _, activeCell in ipairs(activeCells) do
            if activeCell.player then
                state.cellsAnalyzed[activeCell.cell.id] = true
                mCell.analyseCell(state, activeCell.cell, activeCell.player)
            end
        end
    end
end

for _, type in ipairs({ T.NPC, T.Creature, T.Container }) do
    I.Activation.addHandlerForType(type, function(loot, actor)
        onLootOpen(loot, actor)
    end)
end

mSTracker.trackSettings(state)

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
        processLoot = function(loot, actor) onLootOpen(loot, actor) end,
        test = {
            pickModifiers = function(lootLevel, alpha, beta) mTest.testPickModifiers(state, lootLevel, alpha, beta) end,
            itemModifiers = function(itemId, lootLevel) mTest.testItemModifiers(state, itemId, lootLevel) end,
            showActorStats = function() mTest.showFactionRankStats(state) end,
            showWealthStats = function() mTest.showWealthStats(state) end,
            createItem = mTest.createItem,
        },
    },
    engineHandlers = {
        onInit = onInit,
        onPlayerAdded = onPlayerAdded,
        onUpdate = onUpdate,
        onActorActive = onActorActive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Unpause = onUnpause,
        [mDef.events.onActorActive] = onActorActive,
        [mDef.events.sendPlayersEvent] = mWorld.sendPlayersEvent,
        [mDef.events.setItemListsSetting] = function() mSTracker.setItemListsSetting(state) end,
        [mDef.events.setContainersStats] = function(stats) mStats.setContainersStats(state, stats) end,
        [mDef.events.filterConvertedItems] = function(event) event.object:sendEvent(event.name, mConvert.filterConvertedItems(state, event.data)) end,
        [mDef.events.revertLoot] = function(loot) mConvert.restoreItems(state, mTypes.new.itemRestoreFilter({ [mTypes.itemRestoreTypes.InLoot] = true }, loot)) end,
        [mDef.events.convertTestItem] = function(data) mTest.convertTestItem(state, data.item, data.count, data.modId1, data.lvl1, data.modId2, data.lvl2, data.actor) end,
        PB_equipped = function(data) mInterop.onPBArmorEquipped(state, data.actor, data.oldItem, data.newItem, data.pbRecordId) end,
    },
}