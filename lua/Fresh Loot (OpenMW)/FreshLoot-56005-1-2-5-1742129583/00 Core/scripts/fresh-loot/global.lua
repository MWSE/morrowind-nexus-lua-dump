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

local settingChanges = {}
local lastCheckTime = 0

local state = {
    settings = {},
    cache = mTypes.new.cache(),
    processed = {
        cells = {},
        actors = {},
        equipments = {},
        containers = {},
        items = {},
    },
    jobs = { cellsToRefresh = {} },
    learned = {
        validItemIds = {},
        validItemListIds = {},
        npcsWealth = {},
        inventoryWealthLevel = mTypes.new.averageStat(),
        factionRanksLevel = {},
        containers = { levelStats = {}, boosts = {} },
    },
    excluded = mTypes.new.exclusionLists(),
    playerLevel = 1,
}

local function getSerializableState()
    return {
        processed = state.processed,
        jobs = state.jobs,
        learned = state.learned,
        playerLevel = state.playerLevel,
    }
end

local function onLootOpen(loot, actor)
    if not state.settings[mStore.cfg.enabled.key] then return end
    if actor.type == T.Player and not state.processed.containers[loot.id] then
        state.processed.containers[loot.id] = true
        mConvert.onContainerOpen(state, loot, false)
    end
end

I.Activation.addHandlerForType(T.NPC, function(npc, actor)
    onLootOpen(npc, actor)
end)

I.Activation.addHandlerForType(T.Creature, function(creature, actor)
    onLootOpen(creature, actor)
end)

I.Activation.addHandlerForType(T.Container, function(container, actor)
    if T.Lockable.isLocked(container) then return end
    onLootOpen(container, actor)
end)

local function onCellChanged(player)
    if not state.settings[mStore.cfg.enabled.key]
            or not state.jobs.cellsToRefresh[player.cell.id]
            or mWorld.getActiveCells()[player.cell.id].playerCount ~= 1 then return end

    log(string.format("Some items of cell \"%s\" may be refreshed", player.cell.id))
    mConvert.restoreItems(state, state.jobs.cellsToRefresh[player.cell.id], true)
    state.jobs.cellsToRefresh[player.cell.id] = nil
    state.processed.cells[player.cell.id] = false
    lastCheckTime = 0
end

local function clearInvalidObjects()
    local itemCount = 0
    for id, convertedItem in pairs(state.processed.items) do
        if mObj.isObjectInvalid(convertedItem.item) or convertedItem.item.count == 0 then
            itemCount = itemCount + 1
            state.processed.items[id] = nil
        end
    end
    if itemCount > 0 then
        log(string.format("Clear %d invalid referenced items", itemCount))
    end
    local koActorCount = 0
    for id, actor in pairs(state.processed.actors) do
        if mObj.isObjectInvalid(actor) or actor.count == 0 then
            koActorCount = koActorCount + 1
            state.processed.actors[id] = nil
            state.processed.equipments[id] = nil
        end
    end
    if koActorCount > 0 then
        log(string.format("Clear %d invalid referenced actors", koActorCount))
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

local function setItemListsSetting()
    mStore.cfg.itemLists.set(table.concat(state.cache.validItemListIds, "\n"))
end

local function trackSettingChanges(key)
    if key == mStore.cfg.itemLists.key then
        -- event because otherwise OpenMW complains about possible infinite recursion on settings changes
        if #state.cache.validItemListIds > 0 and mStore.cfg.itemLists.get() == "" then
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
        if values.old ~= values.new and mStore.cfg[key].triggerRestoreType then
            refreshActiveCells = true
            if type(values.new) ~= "boolean" or not values.new then
                restoreTypes[mStore.cfg[key].triggerRestoreType] = true
            end
        end
    end
    settingChanges = {}
    if refreshActiveCells then
        lastCheckTime = 0
        for cellId in pairs(mWorld.getActiveCells()) do
            state.processed.cells[cellId] = nil
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

local function onInit()
    state.playerLevel = mWorld.getPlayerLevel()
    loadSettings()
    mMod.init(state, require("scripts.fresh-loot.modifiers.main"))
    local ids = require("scripts.fresh-loot.item-lists.main")
    state.cache.validItemIds = ids.itemIds
    state.cache.validItemListIds = ids.listIds
    setItemListsSetting()
    if #state.learned.validItemIds ~= 0 then
        log(string.format("Loading %d learned valid item ids...", #state.learned.validItemIds))
        mHelpers.addAllToHashset(state.cache.validItemIds, state.learned.validItemIds)
    end
    log(string.format("Loaded a total of %d valid item ids.", mHelpers.mapSize(state.cache.validItemIds)))
    state.excluded = require("scripts.fresh-loot.exclusions.main")
end

local function onUpdate(deltaTime)
    lastCheckTime = lastCheckTime + deltaTime
    if lastCheckTime < 1 then return end
    lastCheckTime = 0

    local activeCells = mWorld.getActiveCells()

    for cellId, cellStat in pairs(activeCells) do
        if not state.processed.cells[cellId] then
            state.processed.cells[cellId] = true
            mCell.analyseCell(state, cellStat.cell)
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
            state.jobs.cellsToRefresh[cellId] = mTypes.new.itemRestoreFilter(restoreTypes, { [cellId] = true })
        end
        mConvert.restoreItems(
                state,
                mTypes.new.itemRestoreFilter({ [mTypes.itemRestoreTypes.Equipped] = true }, nil, activeCells),
                true)
    end
end

local function onActorActive(actor)
    if state.processed.cells[actor.cell.id] and mWorld.getActiveCells()[actor.cell.id] then
        mCell.analyseActor(state, actor)
    end
end

local function onSave()
    return {
        state = getSerializableState(),
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version == mDef.saveVersion then
            state = data.state
        else
            -- update data
        end
    end
    state.settings = {}
    state.cache = mTypes.new.cache()
    clearInvalidObjects()
    onInit()
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
        test = {
            pickModifiers = function(lootLevel, alpha, beta) mTest.testPickModifiers(state, lootLevel, alpha, beta) end,
            itemModifiers = function(itemId, lootLevel) mTest.testItemModifiers(state, itemId, lootLevel) end,
            showActorStats = function() mTest.showStats(state.stats) end,
            createItem = function(recordId, count, modId1, lvl1, modId2, lvl2) mTest.createItem(state, recordId, count, modId1, lvl1, modId2, lvl2) end
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
        [mDef.events.setItemListsSetting] = setItemListsSetting,
        [mDef.events.onCellChanged] = onCellChanged,
        [mDef.events.setLootsLevel] = function(lootsStats) mStats.setLootsLevelStats(state, lootsStats) end,
        [mDef.events.filterConvertedItems] = function(event) event.object:sendEvent(event.name, mConvert.filterConvertedItems(state, event.data)) end,
        [mDef.events.sendPlayersEvent] = mWorld.sendPlayersEvent,
    }
}