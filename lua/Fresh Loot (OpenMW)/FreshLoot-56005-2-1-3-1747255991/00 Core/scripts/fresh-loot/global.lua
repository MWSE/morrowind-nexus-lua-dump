local core = require("openmw.core")
local T = require("openmw.types")
local I = require("openmw.interfaces")
local async = require("openmw.async")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mWorld = require("scripts.fresh-loot.util.world")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mTest = require("scripts.fresh-loot.util.test")
local mMod = require("scripts.fresh-loot.loot.modifier")
local mStats = require("scripts.fresh-loot.loot.stats")
local mCell = require("scripts.fresh-loot.loot.cell")
local mConvert = require("scripts.fresh-loot.loot.convert")

local l10n = core.l10n(mDef.MOD_NAME);
local settingChanges = {}
local lastCheckTime = 0
local notSavedStateKeys = { settings = true, cache = true }

local state = {
    settings = {},
    cache = mTypes.new.cache(),
    containers = {},
    actors = {},
    items = {},
    cellsAnalyzed = {},
    cellsToRefresh = {},
    validItems = {},
    npcsWealth = {},
    npcLevels = {},
    factionRanksLevel = {},
    playerLevel = 1,
}

local function onLootOpen(loot, actor)
    if actor.type == T.Player
            and (mTypes.hasWares(state.containers[loot.id]) or not mTypes.isAccessed(mObj.getLootData(state, loot))) then
        mConvert.onContainerOpen(state, loot, false)
    end
end

for _, type in ipairs({ T.NPC, T.Creature, T.Container }) do
    I.Activation.addHandlerForType(type, function(loot, actor)
        onLootOpen(loot, actor)
    end)
end

local function onCellChanged(player)
    if not state.cellsToRefresh[player.cell.id]
            or #mWorld.getActiveCells()[player.cell.id].players ~= 1 then return end

    log(string.format("Some items of cell \"%s\" may be refreshed", player.cell.id))
    mConvert.restoreItems(state, state.cellsToRefresh[player.cell.id], true)
    state.cellsToRefresh[player.cell.id] = nil
    state.cellsAnalyzed[player.cell.id] = false
    lastCheckTime = 0
end

local function fixObjects()
    local dataLists = { containers = state.containers, actors = state.actors, items = state.items }
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if mObj.isObjectInvalid(data.object) or data.object.count == 0 then
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

local function updateSettingRequirement()
    for key, setting in pairs(mStore.cfg) do
        local argument = setting.argument
        if setting.requires and argument.disabled ~= not state.settings[setting.requires] then
            argument.disabled = not state.settings[setting.requires]
            if argument.disabled then
                state.settings[key] = false
            else
                state.settings[key] = setting.get()
            end
            I.Settings.updateRendererArgument(setting.section.key, key, argument)
            return true
        end
    end
    return false
end

local function updateSettingsRequirements()
    -- for loop because an empty "while" produces an IDE warning...
    for _ = 1, 100 do
        if not updateSettingRequirement() then return end
    end
end

local function trackSettingChanges(key)
    if key == mStore.cfg.itemLists.key then
        -- event because otherwise OpenMW complains about possible infinite recursion on settings changes
        if #state.cache.itemLists > 0 and mStore.cfg.itemLists.get() == "" then
            core.sendGlobalEvent(mDef.events.setItemListsSetting)
        end
    end
    local newValue = mStore.cfg[key].get()
    if not settingChanges[key] then
        settingChanges[key] = { old = state.settings[key] }
    end
    state.settings[key] = newValue
    updateSettingsRequirements()
    settingChanges[key].new = state.settings[key]
end

for _, section in pairs(mStore.section) do
    section.get():subscribe(async:callback(function(_, key) trackSettingChanges(key) end))
end

local function checkSettings()
    local restoreTypes = {}
    local refreshActiveCells = false
    for key, values in pairs(settingChanges) do
        if values.old ~= values.new and mStore.cfg[key].triggerRestoreTypes then
            refreshActiveCells = true
            mHelpers.addAllToHashset(restoreTypes, mStore.cfg[key].triggerRestoreTypes)
        end
    end
    settingChanges = {}
    if refreshActiveCells then
        lastCheckTime = 0
        for cellId in pairs(mWorld.getActiveCells()) do
            state.cellsAnalyzed[cellId] = nil
        end
        mConvert.restoreItems(state, mTypes.new.itemRestoreFilter(restoreTypes), false)
    end
end

local function loadSettings()
    for _, setting in pairs(mStore.cfg) do
        state.settings[setting.key] = setting.get()
    end
    updateSettingsRequirements()
end

local function setItemListsSetting()
    mStore.cfg.itemLists.set(table.concat(state.cache.itemLists, "\n"))
end

local function onActorActive(actor)
    if not state.settings[mStore.cfg.enabled.key] or not state.cellsAnalyzed[actor.cell.id] then return end
    local activeCells = mWorld.getActiveCells()[actor.cell.id]
    if activeCells then
        mCell.analyseActor(state, actor, activeCells.players[1])
    end
end

local function onUpdate(deltaTime)
    if not state.settings[mStore.cfg.enabled.key] then return end
    lastCheckTime = lastCheckTime + deltaTime
    if lastCheckTime < 1 then return end
    lastCheckTime = 0

    local activeCells = mWorld.getActiveCells()

    for cellId, cellStat in pairs(activeCells) do
        if not state.cellsAnalyzed[cellId] then
            state.cellsAnalyzed[cellId] = true
            mCell.analyseCell(state, cellStat.cell, cellStat.players[1])
        end
    end

    local prevLevel = state.playerLevel
    state.playerLevel = mWorld.getPlayerLevel()
    if state.playerLevel ~= prevLevel
            and state.settings[mStore.cfg.playerLevelScaling.key] ~= 0
            and state.settings[mStore.cfg.doEquippedItems.key] then
        log(string.format("Player level just increased (from %s to %s), actors' equipments will be refreshed next time the cell is active again",
                prevLevel, state.playerLevel))
        local restoreTypes = { [mTypes.itemRestoreTypes.Equipped] = true }
        for cellId in pairs(activeCells) do
            state.cellsToRefresh[cellId] = mTypes.new.itemRestoreFilter(restoreTypes, { [cellId] = true })
        end
        mConvert.restoreItems(
                state,
                mTypes.new.itemRestoreFilter({ [mTypes.itemRestoreTypes.Equipped] = true }, nil, activeCells),
                true)
    end
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

local function onInit()
    if not checkCompatibility() then return end
    state.playerLevel = mWorld.getPlayerLevel()
    loadSettings()
    mMod.init(state, require("scripts.fresh-loot.modifiers.main"))
    local ids = require("scripts.fresh-loot.item-lists.main")
    state.cache.validItems = ids.itemIds
    state.cache.itemLists = ids.listIds
    setItemListsSetting()
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
    end
    state.settings = {}
    state.cache = mTypes.new.cache()
    fixObjects()
    onInit()
end

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
        onUpdate = onUpdate,
        onActorActive = onActorActive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Unpause = checkSettings,
        [mDef.events.sendPlayersEvent] = mWorld.sendPlayersEvent,
        [mDef.events.setItemListsSetting] = setItemListsSetting,
        [mDef.events.onCellChanged] = onCellChanged,
        [mDef.events.setContainersStats] = function(stats) mStats.setContainersStats(state, stats) end,
        [mDef.events.filterConvertedItems] = function(event) event.object:sendEvent(event.name, mConvert.filterConvertedItems(state, event.data)) end,
        [mDef.events.revertLoot] = function(loot) mConvert.restoreItems(state, mTypes.new.itemRestoreFilter({ [mTypes.itemRestoreTypes.InLoot] = true }, nil, nil, loot.id)) end,
        [mDef.events.convertTestItem] = function(data) mTest.convertTestItem(state, data.item, data.count, data.modId1, data.lvl1, data.modId2, data.lvl2) end,
    }
}