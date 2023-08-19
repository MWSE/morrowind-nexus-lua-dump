local sorterData = {}
local messageEventName = "showMessageMundis"
local sortType = { sortByContName = 0, SortByPartialName = 1, sortByRecordFilter = 2 }
local isMwse = true
local function registerSortingCategory(catName, cell)
    sorterData[catName] = { cell = cell, sorts = {} }
end
local types = {
    ["Container"] = tes3.objectType.container,
    ["Activator"] = tes3.objectType.activator,
    ["Apparatus"] = tes3.objectType.apparatus,
    ["Ingredient"] = tes3.objectType.ingredient,
    ["NPC"] = tes3.objectType.npc,
    ["Miscellaneous"] = tes3.objectType.miscItem,
    ["Clothing"] = tes3.objectType["clothing"],
    ["Book"] = tes3.objectType["book"],
    ["Potion"] = tes3.objectType["alchemy"]
}
local function getPlayerInv()
    if isMwse then
        return tes3.player.object.inventory.items
    end
    return types.Actor.inventory(world.players[1])
end
local function registerSortByContainerName(catName, typeFilter)
    if not sorterData[catName] then
        error("Missing Sorting Category")
    end
    table.insert(sorterData[catName].sorts, { type = sortType.sortByContName, typeFilter = typeFilter })
end
local function getNameContainer(cell, contName)
    if isMwse then
        return tes3.getReference(contName)
    end
    for index, value in ipairs((cell:getAll(types.Container))) do
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
    if isMwse then
        return not tes3.player.object:hasItemEquipped(item)
    end
    for index, value in pairs(types.Actor.getEquipment(world.players[1])) do
        if value == item then
            return false
        end
    end
    return true
end
local function findContainerByName(catCell, containerName)
    for cont in catCell:iterateReferences() do
        local contName = cont.object.name
        if contName and contName:lower() == containerName:lower() then
            return cont
        end
    end
end

local function moveItemsToContainer(items, targetContainer)
    local sortCount = 0
    for _, plrItem in ipairs(items) do
        if isNotEquipped(plrItem.object) then
            sortCount = sortCount + plrItem.count
            --    plrItem:moveInto(types.Container.content(targetContainer))
            tes3.transferItem({ from = tes3.player, to = targetContainer, item = plrItem.object, playSound = false,
                count = plrItem.count, updateGUI = false })
        end
    end
    return sortCount
end
local function getPlayerCell()
    return tes3.player.cell
end
local function runSort(catName)
    local sortCount = 0
    local catCell = getPlayerCell()

    for _, value in ipairs(sorterData[catName].sorts) do
        if value.type == sortType.sortByContName then
            for _, plrItem in ipairs(getPlayerInv()) do
                if plrItem.object.objectType == value.typeFilter then
                    local itemName = plrItem.object.name
                    local targetContainer = findContainerByName(catCell, itemName)
                    if targetContainer then
                        sortCount = sortCount + moveItemsToContainer({ plrItem }, targetContainer)
                    end
                end
            end
        elseif value.type == sortType.SortByPartialName then
            local targetContainer = getNameContainer(catCell, value.targetContainer)
            if not targetContainer then
                error("Container not found!")
            end
            local items = {}
            for _, plrItem in ipairs(getPlayerInv()) do
                if plrItem.object.objectType == value.typeFilter then
                    local itemName = plrItem.object.name:lower()
                    if stringContains(itemName, value.nameFilter:lower()) then
                        table.insert(items, plrItem)
                    end
                end
            end
            sortCount = sortCount + moveItemsToContainer(items, targetContainer)
        elseif value.type == sortType.sortByRecordFilter then
            local targetContainer = getNameContainer(catCell, value.targetContainer)
            if not targetContainer then
                error("Container not found!")
            end
            local items = {}
            for _, plrItem in ipairs(getPlayerInv()) do
                if plrItem.object.objectType == value.typeFilter then
                    local recordValue = value.recordField
                    print(recordValue)
                    if recordValue == "clothingSlot" then
                        recordValue = plrItem.object.slot
                    elseif recordValue == "isKey" then
                        recordValue = plrItem.object.isKey
                    elseif recordValue == "enchant" and plrItem.object.enchantment then
                        recordValue = plrItem.object.enchantment.id
                    elseif recordValue == "enchant" and not plrItem.object.enchantment then
                        recordValue = ""
                    elseif plrItem.variables and recordValue == "soul" and plrItem.variables[1].soul then
                        recordValue = plrItem.variables[1].soul
                        print("Found a soul")
                    elseif plrItem.variables and recordValue == "soul" and not plrItem.variables[1].soul then
                        recordValue = nil
                    elseif plrItem.variables and recordValue == "soul"  then
                        print("It exists")
                    elseif not plrItem.variables and recordValue == "soul" then
                        recordValue = nil
                    end
                    print(recordValue)
                    if (recordValue == value.recordValue and not value.invert) or (recordValue ~= value.recordValue and value.invert) then
                        table.insert(items, plrItem)
                    end
                end
            end
            sortCount = sortCount + moveItemsToContainer(items, targetContainer)
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
    if sortCount == 0 then
        tes3.messageBox(string.format("You have no sortable items", sortCount))
    elseif sortCount == 1 then
        tes3.messageBox(string.format("You sort %g item", sortCount))
    else
        tes3.messageBox(string.format("You sort %g items", sortCount))
    end
end
local function exampleUse()
    local catName = "MundisIngred"
    registerSortingCategory(catName, "MUNDIS Private Quarters")
    registerSortByContainerName(catName, types.Ingredient)
    registerSortActivator(catName, "aaaa_sorter2")
    catName = "MundisMisc"
    registerSortingCategory(catName, "MUNDIS Private Quarters")
    registerSortByRecordFilter(catName, types.Clothing, "clothingSlot", tes3.clothingSlot.ring, "aa_rings")
    registerSortByRecordFilter(catName, types.Clothing, "clothingSlot", tes3.clothingSlot["amulet"], "aa_amulets")
    registerSortByRecordFilter(catName, types.Book, "enchant", "", "aa_chest_scrolls", true)
    registerSortByPartialName(catName, types.Clothing, "Expensive", "mundis_clothing_exp")
    registerSortByPartialName(catName, types.Clothing, "Extravagant", "mundis_clothing_extrav")
    registerSortByPartialName(catName, types.Clothing, "Common", "mundis_clothing_com")
    registerSortByPartialName(catName, types.Clothing, "Imperial", "mundis_clothing_com")
    registerSortByPartialName(catName, types.Clothing, "Exquisite", "mundis_clothing_exq")


    registerSortByPartialName(catName, types.Miscellaneous, "Cloth", "zhac_mundis_sort_sewing")
    registerSortByPartialName(catName, types.Miscellaneous, "Shears", "zhac_mundis_sort_sewing")
    registerSortByPartialName(catName, types.Miscellaneous, "Spool", "zhac_mundis_sort_sewing")

    registerSortByPartialName(catName, types.Miscellaneous, "Jug", "zhac_mundis_sort_drinki")
    registerSortByPartialName(catName, types.Miscellaneous, "Bottle", "zhac_mundis_sort_drinki")
    registerSortByPartialName(catName, types.Miscellaneous, "Goblet", "zhac_mundis_sort_drinki")

    registerSortByRecordFilter(catName, types.Miscellaneous, "soul", nil, "zhac_mundis_sort_fsoul", true)
    registerSortByPartialName(catName, types.Miscellaneous, "Soul Gem", "zhac_mundis_sort_esoul")
    registerSortByPartialName(catName, types.Miscellaneous, "Azura's Star", "zhac_mundis_sort_esoul")

    registerSortByPartialName(catName, types.Potion, "Bargain", "aa_bargainpot")
    registerSortByPartialName(catName, types.Potion, "Cheap", "aa_cheappot")
    registerSortByPartialName(catName, types.Potion, "Standard", "aa_standardpot")
    registerSortByPartialName(catName, types.Potion, "Quality", "aa_qualitypot")
    registerSortByPartialName(catName, types.Potion, "Exclusive", "aa_exclusivep")
    registerSortByPartialName(catName, types.Potion, "", "aa_standardpot")

    registerSortByRecordFilter(catName, types.Miscellaneous, "isKey", true, "aa_keys")
    registerSortByPartialName(catName, types.Miscellaneous, "key", "aa_keys")

    registerSortActivator(catName, "aaaa_sorter1")

    -- I.ZUtilsSorter_Mundis.registerSortingCategory(catName, "MUNDIS Private Quarters")
    --I.ZUtilsSorter_Mundis.registerSortByContainerName(catName, types.Ingredient)
    -- I.ZUtilsSorter_Mundis.registerSortActivator(catName, "aaaa_sorter2")
end
exampleUse()
local function onActivate(e)
    for index, sort in pairs(sorterData) do
        if sort.activatorName:lower() == e.target.object.id:lower() then
            runSort(index)
        end
    end
end
if isMwse then
    event.register(tes3.event.activate, onActivate)
end

return {
    interfaceName = "ZUtilsSorter_Mundis",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
        registerSortingCategory = registerSortingCategory,
        registerSortByContainerName = registerSortByContainerName,
        registerSortByRecordFilter = registerSortByRecordFilter,
        isNotEquipped = isNotEquipped,
        runSort = runSort,
        registerSortActivator = registerSortActivator,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onActivate = onActivate
    }
}
