-- Declarations --
local core = require("openmw.core")
local types = require('openmw.types')
local world = require('openmw.world')
local interfaces = require('openmw.interfaces')
local vfs = require('openmw.vfs')

local excludeList = {}

-- Startup Check --
if (core.API_REVISION < 71) then
    error("OpenMW 0.49.0 RC6 or newer is required.")
end
if (core.contentFiles ~= nil and not core.contentFiles.has("portable_autosorter.omwaddon")) then
    error("Portable Autosorter omwaddon is not enabled.")
end

-- Internal Functions --
local function checkDoNotUse(container)
    for _, item in ipairs(types.Container.inventory(container):getAll(types.Miscellaneous)) do
        if item.recordId == "autosort_target_donotuse" then
            return true
        end
    end
    return false
end

local function checkIfEquipped(actor, recordId)
    for i, x in pairs(types.Actor.getEquipment(actor)) do
        if x.recordId == recordId then return true end
    end
    return false
end

local function buildExcludeList()
    if vfs.fileExists("exclusions.txt")
    then
        local file = vfs.open("exclusions.txt")
        for line in file:lines() do
            line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
            if line ~= "" and not line:match("^%-%-")
            then
                print(line)
                table.insert(excludeList, line)
            end
        end
        file:close()
    end
end

local function isExcluded(itemName)
    for _, value in ipairs(excludeList) do
        if value == itemName then
            return true
        end
    end
    return false
end

local function movetoContainer(item, container)
    if not isExcluded(item.type.records[item.recordId].name)
    then
        item:moveInto(types.Container.inventory(container))
    end
end

-- CCC compatibility --
local function joinContainerLists(...)
    local result = {}
    for _, list in ipairs({...}) do
        for i = 1, #list do
            table.insert(result, list[i])
        end
    end
    return result
end

local function getAutosortContainers(containers)
    if interfaces.CCC_cont ~= nil then
        print("CCC_cont interface found!")
        return joinContainerLists(containers, world.getCellByName("ToddTest"):getAll(types.Container))
    else
        return containers
    end
end

-- Autosort --
local function moveItems(actor, container, list)
    if not checkDoNotUse(container) then
        for _, item in ipairs(list)
        do
            if not (types.Actor.hasEquipped(actor, item) or string.find(item.recordId, "autosort_"))
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveClothing(actor, container, list)
    if not checkDoNotUse(container) then
        for _, item in ipairs(list)
        do
            if not (types.Actor.hasEquipped(actor, item) or string.find(item.recordId, "autosort_"))
            then
                if not (item.type == types.Clothing.TYPE.Ring or item.type == types.Clothing.TYPE.Amulet)
                then
                    movetoContainer(item, container)
                end
            end
        end
    end
end

local function moveJewelry(actor, container, list)
    if not checkDoNotUse(container) then
        for _, item in ipairs(list)
        do
            if not (types.Actor.hasEquipped(actor, item) or string.find(item.recordId, "autosort_"))
            then
                if (item.type == types.Clothing.TYPE.Ring or item.type == types.Clothing.TYPE.Amulet)
                then
                    movetoContainer(item, container)
                end
            end
        end
    end
end

local function moveBooks(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book))
        do
            if string.len(item.type.records[item.recordId].enchant or '') == 0
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveGold(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
        do
            if string.find(item.recordId, "gold_")
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveKeys(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
        do
            if item.type.records[item.recordId].isKey
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveMisc(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
        do
            if not (
                item.type.records[item.recordId].isKey 
                or string.find(item.recordId, "autosort_") 
                or string.find(item.recordId, "gold_") 
                or string.find(item.recordId, "misc_soulgem_") 
            )
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveScrolls(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book))
        do
            if string.len(item.type.records[item.recordId].enchant or '') > 0
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveSoulGems(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous))
        do
            if string.find(item.recordId, "misc_soulgem_")
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function moveOverflow(actor, container)
    if not checkDoNotUse(container) then
        for _, item in ipairs(types.Actor.inventory(actor):getAll())
        do
            -- Never move Gold, autosort items, or equipped stuff to the overflow container.
            if not (
                string.find(item.recordId, "autosort_")
                or types.Actor.hasEquipped(actor, item)
                or string.find(item.recordId, "gold_")
            )
            then
                movetoContainer(item, container)
            end
        end
    end
end

local function autoSortVisualEffect(position)
    local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Jump]
    local model = types.Static.record(effect.castStatic).model
    core.sendGlobalEvent('SpawnVfx', {model = model, position = position})
end

-- Engine Handlers --
local function onItemActive(item)
    if item.recordId == "autosort_master_sorter"
    then
        local autosortScript = "scripts/portable_autosorter/autosort.lua"
        if item:hasScript(autosortScript)
        then
            item:removeScript(autosortScript)
        end
        item:addScript(autosortScript)
        print('Auto Sort script baked on to autosort_master_sorter.')
    end
end

-- Event Handlers --
local function runAutoSort(data)
    local actor = data.actor
    local containers = data.containers
    local autoSortObject = data.autoSortObject
    local posInfo = data.posInfo

    if types.Player.objectIsInstance(actor) and not (world.isWorldPaused() or checkIfEquipped(actor, "autosort_pickup_ring"))
    then
        buildExcludeList()
        local overflowContainer = nil
        for _, container in ipairs(getAutosortContainers(containers))
        do
            for _, item in ipairs(types.Container.inventory(container):getAll(types.Miscellaneous))
            do
                if item.recordId == "autosort_target_apparatus" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Apparatus))
                elseif item.recordId == "autosort_target_armor" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Armor))
                elseif item.recordId == "autosort_target_book" then
                    moveBooks(actor, container, types.Actor.inventory(actor):getAll(types.Book))
                elseif item.recordId == "autosort_target_clothing" then
                    moveClothing(actor, container, types.Actor.inventory(actor):getAll(types.Clothing))
                elseif item.recordId == "autosort_target_jewelry" then
                    moveJewelry(actor, container, types.Actor.inventory(actor):getAll(types.Clothing))
                elseif item.recordId == "autosort_target_gold" then
                    moveGold(actor, container)
                elseif item.recordId == "autosort_target_ingredient" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Ingredient))
                elseif item.recordId == "autosort_target_key" then
                    moveKeys(actor, container)
                elseif item.recordId == "autosort_target_misc" then
                    moveMisc(actor, container)
                elseif item.recordId == "autosort_target_potion" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Potion))
                elseif item.recordId == "autosort_target_scroll" then
                    moveScrolls(actor, container, types.Actor.inventory(actor):getAll(types.Book))
                elseif item.recordId == "autosort_target_security" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Lockpick))
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Probe))
                elseif item.recordId == "autosort_target_soulgem" then
                    moveSoulGems(actor, container)
                elseif item.recordId == "autosort_target_repair" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Repair))
                elseif item.recordId == "autosort_target_weapon" then
                    moveItems(actor, container, types.Actor.inventory(actor):getAll(types.Weapon))
                elseif item.recordId == "autosort_target_overflow" then
                    overflowContainer = container -- Mark the Overflow container as found
                end
            end
        end

        -- If we found the Overflow container, use it
        if overflowContainer ~= nil
        then
            moveOverflow(actor, overflowContainer)
        end
        actor:sendEvent("sortingComplete")
        autoSortVisualEffect(posInfo.position)
        autoSortObject:teleport(posInfo.cell, posInfo.position, posInfo.rotation)
    end
end

-- Return --
return {
    interfaceName = 'portable_autosorter',
    interface = {
        version = 2.0
    },
    engineHandlers = {
        onItemActive = onItemActive
    },
    eventHandlers = {
        runAutoSort = runAutoSort
    }
}