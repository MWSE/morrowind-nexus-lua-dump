local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local sorterData = {}
local messageEventName = "showMessageHestatur"

local hestaturData = require("scripts.Hestatur.sortData.spokDatak")
if core.API_REVISION == 29 then 
  return
    end
local sortType = { sortByContName = 0, SortByPartialName = 1, sortByRecordFilter = 2 }
local function registerSortingCategory(catName, cell)
    sorterData[catName] = { cell = cell, sorts = {} }
end
local function getPlayerInv()
    return types.Actor.inventory(world.players[1])
end
local function registerSortByContainerName(catName, typeFilter)
    if not sorterData[catName] then
        error("Missing Sorting Category")
    end
    table.insert(sorterData[catName].sorts, { type = sortType.sortByContName, typeFilter = typeFilter })
end
local function getNameContainer(cell, contName)
    for index, value in ipairs(cell:getAll(types.Container)) do
        if value.recordId == contName then
            return value
        end
    end
end
local function registerSortByPartialName(catName, typeFilter, nameFilter, targetContainer)
    if not sorterData[catName] then
        error("Missing Sorting Category")
    end
    table.insert(sorterData[catName].sorts,
        {
            type = sortType.SortByPartialName,
            typeFilter = typeFilter,
            nameFilter = nameFilter,
            targetContainer = targetContainer
        })
end
local function registerSortByRecordFilter(catName, typeFilter, recordField, recordValue, targetContainer, invert)
    if not sorterData[catName] then
        error("Missing Sorting Category")
    end
    table.insert(sorterData[catName].sorts,
        {
            type = sortType.sortByRecordFilter,
            typeFilter = typeFilter,
            recordField = recordField,
            recordValue = recordValue,
            targetContainer = targetContainer,
            invert = invert
        })
end
local function stringContains(mainString, subString)
    return string.find(mainString, subString, 1, true) ~= nil
end
local function registerSortActivator(catName, actId)
    sorterData[catName].activatorName = actId:lower()
end
local function isNotEquipped(item)
    for index, value in pairs(types.Actor.getEquipment(world.players[1])) do
        if value == item then
            return false
        end
    end
    return true
end
local function findContainerByName(catCell, containerName)
    for _, cont in ipairs(catCell:getAll(types.Container)) do
        local contName = cont.type.record(cont).name:lower()
        if contName == containerName then
            return cont
        end
    end
end
local function findContainerById(catCell, containerName)
    for _, cont in ipairs(catCell:getAll(types.Container)) do
        local contId = cont.recordId
        if contId == containerName then
            return cont
        end
    end
end

local function moveItemsToContainer(items, targetContainer)
    local sortCount = 0
    for _, plrItem in ipairs(items) do
        if isNotEquipped(plrItem) then
            sortCount = sortCount + plrItem.count
            plrItem:moveInto(types.Container.content(targetContainer))
        end
    end
    return sortCount
end
local function sortManually(itemId,containerId)
    local sortCount = 0
    local itemLs = types.Actor.inventory(world.players[1]):findAll(itemId)
    local cell = world.getCellById("hestatur, laboratory")
    local container =findContainerById(cell,containerId)
    if itemLs and container then
        for index, item in ipairs(itemLs) do
            sortCount = sortCount + item.count
        item:moveInto(types.Container.content(container))
        end
    end
    return sortCount
end
local function runSort(catName,num)
    local sortCount = num or 0
    local catCell = world.getCellByName(sorterData[catName].cell)

    for _, value in ipairs(sorterData[catName].sorts) do
        if value.type == sortType.sortByContName then
            for _, plrItem in ipairs(getPlayerInv():getAll(value.typeFilter)) do
                local itemName = plrItem.type.record(plrItem).name:lower()
                local targetContainer = findContainerByName(catCell, itemName)
                if targetContainer then
                    sortCount = sortCount + moveItemsToContainer({ plrItem }, targetContainer)
                end
            end
        elseif value.type == sortType.SortByPartialName then
            local targetContainer = getNameContainer(catCell, value.targetContainer)
            if not targetContainer then
                error("Container not found!")
            end
            local items = {}
            for _, plrItem in ipairs(getPlayerInv():getAll(value.typeFilter)) do
                local itemName = plrItem.type.record(plrItem).name:lower()
                if stringContains(itemName, value.nameFilter:lower()) then
                    table.insert(items, plrItem)
                end
            end
            sortCount = sortCount + moveItemsToContainer(items, targetContainer)
        elseif value.type == sortType.sortByRecordFilter then
            local targetContainer = getNameContainer(catCell, value.targetContainer)
            if not targetContainer then
                error("Container not found!")
            end
            local items = {}
            for _, plrItem in ipairs(getPlayerInv():getAll(value.typeFilter)) do
                local recordValue
                if value.recordField == "soul" then
                    recordValue = types.Miscellaneous.getSoul(plrItem)
                else
                    recordValue = plrItem.type.record(plrItem)[value.recordField]
                end
                if (recordValue == value.recordValue and not value.invert) or (recordValue ~= value.recordValue and value.invert) then
                    table.insert(items, plrItem)
                end
            end
            sortCount = sortCount + moveItemsToContainer(items, targetContainer)
        end
    end
    sortCount = sortCount + I.ItemSortHestatur.runItemSort()
    if sortCount == 0 then
        world.players[1]:sendEvent(messageEventName, string.format("You have no sortable items", sortCount))
    elseif sortCount == 1 then
        world.players[1]:sendEvent(messageEventName, string.format("You sort %g item", sortCount))
    else
        world.players[1]:sendEvent(messageEventName, string.format("You sort %g items", sortCount))
    end
end
local function exampleUse()
    local catName = "HestaturIngred"
    registerSortingCategory(catName, "Hestatur, Laboratory")
    registerSortByContainerName(catName, types.Ingredient)
    registerSortActivator(catName, "spok_ht_sorter")
    catName = "HestaturMisc"
    registerSortingCategory(catName, "Hestatur, Laboratory")
    registerSortByRecordFilter(catName, types.Clothing, "type", types.Clothing.TYPE.Ring, "aa_rings")
    registerSortByRecordFilter(catName, types.Clothing, "type", types.Clothing.TYPE.Amulet, "aa_amulets")
    registerSortByRecordFilter(catName, types.Book, "enchant", "", "aa_chest_scrolls", true)
    registerSortByPartialName(catName, types.Clothing, "Expensive", "Hestatur_clothing_exp")
    registerSortByPartialName(catName, types.Clothing, "Extravagant", "Hestatur_clothing_extrav")
    registerSortByPartialName(catName, types.Clothing, "Common", "Hestatur_clothing_com")
    registerSortByPartialName(catName, types.Clothing, "Imperial", "Hestatur_clothing_com")
    registerSortByPartialName(catName, types.Clothing, "Exquisite", "Hestatur_clothing_exq")

    registerSortByPartialName(catName, types.Miscellaneous, "Cloth", "zhac_Hestatur_sort_sewing")
    registerSortByPartialName(catName, types.Miscellaneous, "Shears", "zhac_Hestatur_sort_sewing")
    registerSortByPartialName(catName, types.Miscellaneous, "Spool", "zhac_Hestatur_sort_sewing")

    registerSortByPartialName(catName, types.Miscellaneous, "Jug", "zhac_Hestatur_sort_drinki")
    registerSortByPartialName(catName, types.Miscellaneous, "Bottle", "zhac_Hestatur_sort_drinki")
    registerSortByPartialName(catName, types.Miscellaneous, "Goblet", "zhac_Hestatur_sort_drinki")

    registerSortByRecordFilter(catName, types.Miscellaneous, "soul", nil, "zhac_Hestatur_sort_fsoul", true)
    registerSortByPartialName(catName, types.Miscellaneous, "Soul Gem", "zhac_Hestatur_sort_esoul")
    registerSortByPartialName(catName, types.Miscellaneous, "Azura's Star", "zhac_Hestatur_sort_esoul")

    registerSortByPartialName(catName, types.Potion, "Bargain", "spok_ht_pb_all")
    registerSortByPartialName(catName, types.Potion, "Cheap", "spok_ht_pc_all")
    registerSortByPartialName(catName, types.Potion, "Standard", "spok_ht_ps_etc")
    registerSortByPartialName(catName, types.Potion, "Quality", "spok_ht_pq_etc")
    registerSortByPartialName(catName, types.Potion, "Exclusive", "spok_ht_pe_etc")

    registerSortByRecordFilter(catName, types.Miscellaneous, "isKey", true, "zhac_hest_cont_keys")
    registerSortByPartialName(catName, types.Miscellaneous, "key", "zhac_hest_cont_keys")

--    registerSortActivator(catName, "aaaa_sorter1")

    -- I.ZUtilsSorter_Hestatur.registerSortingCategory(catName, "Hestatur, Laboratory")
    --I.ZUtilsSorter_Hestatur.registerSortByContainerName(catName, types.Ingredient)
    -- I.ZUtilsSorter_Hestatur.registerSortActivator(catName, "aaaa_sorter2")
end
exampleUse()
local function onActivate(object, Actor)
    local isSorter = false
    if object.recordId  == "spok_ht_sorter" then
        isSorter = true
    end
    local sortCount = 0
    if isSorter then
    for index, value in ipairs(hestaturData.ingredient_container_pairs) do
        sortCount = sortCount + sortManually(value.item,value.container)
    end
    for index, value in ipairs(hestaturData.scrollData) do
        sortCount = sortCount +  sortManually(value.item,value.container)
    end
    for index, value in ipairs(hestaturData.potionLs) do
        sortCount = sortCount +   sortManually(value.item,value.container)
    end
end
    for index, sort in pairs(sorterData) do
        if sort.activatorName == object.recordId then
            runSort(index,sortCount)
        end
    end
    if isSorter then
        return false
    end
end
return {
    interfaceName = "ZUtilsSorter_Hestatur",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
        registerSortingCategory = registerSortingCategory,
        registerSortByContainerName = registerSortByContainerName,
        registerSortByRecordFilter = registerSortByRecordFilter,
        runSort = runSort,
        registerSortActivator = registerSortActivator,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onActivate = onActivate
    }
}
