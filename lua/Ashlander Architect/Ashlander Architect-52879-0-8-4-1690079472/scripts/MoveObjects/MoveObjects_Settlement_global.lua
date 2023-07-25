local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation
local settlementList = {}
local time = require('openmw_aux.time')
local myModData = storage.globalSection("AASettlements")
local settingList = {
    { keyName = "allow_female", buttonText = "Allow Female Settlers: " },
    { keyName = "allow_male",   buttonText = "Allow Male Settlers: " },
    { keyName = "allow_bret",   buttonText = "Allow Breton Settlers: " },
    { keyName = "allow_arg",    buttonText = "Allow Argonian Settlers: " },
    { keyName = "allow_dunm",   buttonText = "Allow Dunmer Settlers: " },
    { keyName = "allow_helf",   buttonText = "Allow Allow High Elf Settlers: " },
    { keyName = "allow_imp",    buttonText = "Allow Imperial Settlers: " },
    { keyName = "allow_orc",    buttonText = "Allow Orcish Settlers: " },
    { keyName = "allow_khaj",   buttonText = "Allow Khajit Settlers: " },
    { keyName = "allow_nord",   buttonText = "Allow Nord Settlers: " },
    { keyName = "allow_redg",   buttonText = "Allow Redguard Settlers: " },
    { keyName = "allow_welf",   buttonText = "Allow Wood Elf Settlers: " }
}

local lastNPCSpawn = 0
local TypeTable = { {
    MarkerID = "zhac_jbmarker_alchemist",
    NPCPostfix = "al",
    FriendlyName = "Alchemist"
}, {
    MarkerID = "zhac_jbmarker_blacksmith",
    NPCPostfix = "bl",
    FriendlyName = "Blacksmith"
}, {
    MarkerID = "zhac_jbmarker_bookseller",
    NPCPostfix = "bo",
    FriendlyName = "Bookseller"
}, {
    MarkerID = "zhac_jbmarker_caravaneer",
    NPCPostfix = "ca",
    FriendlyName = "Caravaneer"
}, {
    MarkerID = "zhac_jbmarker_clothier",
    NPCPostfix = "cl",
    FriendlyName = "Clothier"
}, {
    MarkerID = "zhac_jbmarker_enchanter",
    NPCPostfix = "En",
    FriendlyName = "Enchanter"
}, {
    MarkerID = "zhac_jbmarker_gguide",
    NPCPostfix = "gg",
    FriendlyName = "Guild Guide"
}, {
    MarkerID = "zhac_jbmarker_healer",
    NPCPostfix = "he",
    FriendlyName = "Healer"
}, {
    MarkerID = "zhac_jbmarker_publican",
    NPCPostfix = "pu",
    FriendlyName = "Publican"
}, {
    MarkerID = "zhac_jbmarker_shipmaster",
    NPCPostfix = "sh",
    FriendlyName = "Shipmaster"
}, {
    MarkerID = "zhac_jbmarker_sorcerer",
    NPCPostfix = "so",
    FriendlyName = "Sorcerer"
}, {
    MarkerID = "zhac_jbmarker_trader",
    NPCPostfix = "tr",
    FriendlyName = "Trader"
} }
local raceList = { "bret", "arg", "dunm", "helf", "imp", "orc", "khaj", "nord", "redg", "welf" }
local function updateSettlementData()
    myModData:set("settlementList", settlementList)
    if (I.ZackUtilsAA ~= nil) then
        I.ZackUtilsAA.getPlayer():sendEvent("updateSettlerUi")
    end
end
local function checkChance(chance)
    math.randomseed(os.time() * 1000)
    local randomNumber = math.random(0, 100)
    return randomNumber <= chance
end

local function endsWith(str, ending)
    return ending == "" or string.sub(str, -2) == ending
end
local function CreateShopContainer(data)
    local actor = data.actor
    local shopcont = I.ZackUtilsAA.ZackUtilsCreateInterface("chest_small_02", actor.cell.name,
        util.vector3(actor.position.x, actor.position.y, actor.position.z - 1000))
    local ShopData = I.shopobjects_data.objectTypes
    shopcont.ownerRecordId = actor.recordId


    print("Creating shop cont")
    for index, shopItem in ipairs(ShopData) do
        for xindex, marker in ipairs(TypeTable) do
            if (shopItem.Class == marker.FriendlyName and endsWith(actor.recordId, marker.NPCPostfix:lower()) and checkChance(shopItem.Spawn_Chance)) then
                world.createObject(shopItem.Item_ID, math.random(shopItem.MinCount, shopItem.MaxCount)):moveInto(types
                    .Container.content(shopcont))
            end
        end
    end
end
local function UpdateShopContainer(data)
    local shopcont = data.shopcont
    local actor = data.actor
    local ShopData = I.shopobjects_data.objectTypes
    shopcont.ownerRecordId = actor.recordId
    for index, item in ipairs(types.Container.content(shopcont):getAll()) do
        item:remove()
    end
    print("Updating shop cont")

    for index, shopItem in ipairs(ShopData) do
        for xindex, marker in ipairs(TypeTable) do
            if (shopItem.Class == marker.FriendlyName and endsWith(actor.recordId, marker.NPCPostfix:lower()) and checkChance(shopItem.Spawn_Chance)) then
                world.createObject(shopItem.Item_ID, math.random(shopItem.MinCount, shopItem.MaxCount)):moveInto(types
                    .Container.content(shopcont))
            end
        end
    end
end

local function addSettlement(settlementName, settlementMarker, npcSpawnPosition)
    print("Trying")
    if (settlementMarker.cell.name ~= "" and settlementMarker.cell.name ~= nil) then
        -- we aren't allowed to make settlements where there are already other settlements, like cities.
        print("Cell is not nil named")
        return
    end
    if (not settlementMarker.cell.isExterior) then
        -- we aren't allowed to make settlements inside interiors.
        print("Cell is an int?")
        return
    end

    local settlementItem = {
        markerId = settlementMarker.id,
        gridX = settlementMarker.cell.gridX,
        gridY = settlementMarker.cell.gridY,
        settlementName = settlementName,
        settlementDiameter = 8192,
        settlementCenterx = settlementMarker.position.x,
        settlementCentery = settlementMarker.position.y,
        settlementCenterz = settlementMarker.position.z,
        settlementNPCs = {},
        settlementStructures = {},
        npcSpawnPosition = npcSpawnPosition,
        settlementTags = {},
        settlementBedIds = {},
    }
    table.insert(settlementList, settlementItem)
    updateSettlementData()
    print("Added settlement.")
end
local function addSettlementEvent(data)
    addSettlement(data.settlementName, data.settlementMarker, data.npcSpawnPosition)
end
local function findSettlement(settlementId)
    for x, structure in ipairs(settlementList) do
        if (structure.markerId == settlementId) then
            return structure
        end
    end
end
local function addStructureToSettlement(structureItem, settlementId)

end
local function replaceActorId(settlementId, oldActorId, newActorId)
    for x, structure in ipairs(settlementList) do
        if structure.markerId == settlementId then
            for i, npcId in ipairs(structure.settlementNPCs) do
                if npcId == oldActorId then
                    settlementList[x].settlementNPCs[i] = newActorId
                    break
                end
            end
        end
    end
end
local function printActorIds(settlementId)
    for x, structure in ipairs(settlementList) do
        if structure.markerId == settlementId then
            for i, npcId in ipairs(structure.settlementNPCs) do
                print(npcId)
            end
        end
    end
end

local function ActorSwap(currentActor, newActorId, settlementId)
    print("Swapping...")
    local newActor = I.ZackUtilsAA.ZackUtilsCreateInterface(newActorId, currentActor.cell.name, currentActor.position,
        currentActor.rotation)
    newActor:addScript("scripts/MoveObjects/MoveObjects_Settlement_actor.lua", { mySettlement = settlementId })
    local equip = types.Actor.getEquipment(currentActor)
    for i, record in ipairs(types.Actor.inventory(currentActor):getAll()) do
        record:moveInto(types.Actor.inventory(newActor))
    end
    replaceActorId(settlementId, currentActor.id, newActor.id)
    newActor:sendEvent("setEquipment", equip)
    --currentActor:remove()
    currentActor:sendEvent("migrateData", newActor)
    updateSettlementData()
end
local function ActorSwapEvent(data)
    ActorSwap(data.currentActor, data.newActorId, data.settlementId)
end

local function onInit()

    myModData:set("settlementList", settlementList)
end

local function printBedIds(settlementId)
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            for i, tag in ipairs(settlementList[x].settlementBedIds) do
                print(tag)
            end
        end
    end
end
local function addBedId(settlementId, bedId)
    local num = -1
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            num = x
            for i, tag in ipairs(settlementList[x].settlementBedIds) do
                if (tag == bedId) then
                    return
                end
            end
        end
    end
    if (settlementList[num].settlementBedIds) == nil then
        local newTable = {}
        table.insert(newTable, bedId)
        settlementList[num].settlementBedIds = newTable
    else
        table.insert(settlementList[num].settlementBedIds, bedId)
    end
    updateSettlementData()
end
local function addBedIdEvent(data)
    addBedId(data.settlementId, data.bedId)
end

local function removeBedId(settlementId, bedId)
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            for i, tag in ipairs(settlementList[x].settlementBedIds) do
                if tag == bedId then
                    table.remove(settlementList[x].settlementBedIds, i)
                    updateSettlementData()
                    return -- Tag found and removed successfully.
                end
            end
        end
    end
end
local function RemoveBedIdEvent(data)
    removeBedId(data.settlementId, data.bedId)
end


local function AddSettlementTag(settlementId, tagName)
    local num = -1
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            num = x
            for i, tag in ipairs(settlementList[x].settlementTags) do
                if (tag == tagName) then
                    return --already have the tag, no need to add it.
                end
            end
        end
    end
    -- Tag not found, insert it into the settlementTags table
    if (settlementList[num].settlementTags) == nil then
        local newTable = {}
        table.insert(newTable, tagName)
        settlementList[num].settlementTags = newTable
    else
        table.insert(settlementList[num].settlementTags, tagName)
    end
    updateSettlementData()
end
local function HasSettlementTag(settlementId, tagName)
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            if (settlementList[x].settlementTags == nil) then
                break
            end
            for i, tag in ipairs(settlementList[x].settlementTags) do
                if (tag == tagName) then
                    return true
                end
            end
        end
    end
    return false
end
local function addSettlementTagEvent(data)
    print(data.tagName)
    AddSettlementTag(data.settlementId, data.tagName)
end

local function RemoveSettlementTag(settlementId, tagName)
    for x, settlement in ipairs(settlementList) do
        if settlement.markerId == settlementId then
            for i, tag in ipairs(settlementList[x].settlementTags) do
                if tag == tagName then
                    table.remove(settlementList[x].settlementTags, i)
                    updateSettlementData()
                    return -- Tag found and removed successfully.
                end
            end
        end
    end
end
local function getRandomStringFromTable(tbl)
    local count = #tbl
    if count == 0 then
        return nil
    end

    local index = math.random(1, count)
    return tbl[index]
end
local function generateRandomNumber()
    local randomNumber = math.random(1, 20)
    if randomNumber < 10 then
        return "0" .. tostring(randomNumber)
    else
        return tostring(randomNumber)
    end
end
local skirtsToUse = { "common_skirt_01" ,"common_skirt_02","common_skirt_03","common_skirt_04"}
local shirtsToUse = { "common_shirt_01" ,"common_shirt_02","common_shirt_03","common_shirt_04"}
local shoesToUse = { "common_shoes_01" ,"common_shoes_02","common_shoes_03","common_shoes_04"}

local function getRandomItem(table)
    -- Get the number of items in the table
    local itemCount = #table

    -- Check if the table is empty
    if itemCount == 0 then
        return nil
    end

    -- Generate a random index
    local randomIndex = math.random(1, itemCount)

    -- Return the randomly selected item
    return table[randomIndex]
end
local function addActorToSettlement(settlementId, position)
    local mySettlement = findSettlement(settlementId)
    local allowRace = {}
    local genderString = ""
    local raceString = ""
    math.randomseed(os.time() * 1000)
    for x, race in ipairs(raceList) do
        if HasSettlementTag(settlementId, "allow_" .. race) then
            table.insert(allowRace, race)
        end
    end
    if (#allowRace == 0) then
        print("No valid races!")
        return
    end
    if (HasSettlementTag(settlementId, "allow_male") and HasSettlementTag(settlementId, "allow_female")) then
        local randInt = math.random(1000)
        if (randInt > 500) then
            genderString = "f"
        else
            genderString = "m"
        end
    elseif (HasSettlementTag(settlementId, "allow_male")) then
        genderString = "m"
    elseif (HasSettlementTag(settlementId, "allow_female")) then
        genderString = "f"
    else
        print("No valid genders!")
        return
    end
    raceString = getRandomStringFromTable(allowRace)
    local newNPCId = "zhac_snpc_" .. raceString .. "_" .. genderString .. "_" .. generateRandomNumber() .. "_ba"
    print(newNPCId)
    local newActor = I.ZackUtilsAA.ZackUtilsCreateInterface(newNPCId, "", position)

    core.sendGlobalEvent("ZackUtilsAddItems",
        { itemIds = {getRandomItem(skirtsToUse),getRandomItem(shirtsToUse),getRandomItem(shoesToUse)}, actor = newActor, equip = true })
     --   core.sendGlobalEvent("ZackUtilsAddItem",
     --       { itemId = getRandomItem(shoesToUse), count = 1, actor = newActor, equip = true })
    for x, structure in ipairs(settlementList) do
        if (structure.markerId == settlementId) then
            table.insert(settlementList[x].settlementNPCs, newActor.id)
        end
    end
    newActor:addScript("scripts/MoveObjects/MoveObjects_Settlement_actor.lua", { mySettlement = settlementId })
    newActor:sendEvent("goToPosition", I.ZackUtilsAA.getPlayer().position)
    updateSettlementData()
end
local function onObjectActive(object)
    if (object.recordId == "zhac_settlement_marker") then
        local mySettle = nil
        local bedCount = 0
        local settlerCount = 0
        for x, settlement in ipairs(settlementList) do
            if settlement.markerId == object.id then
                mySettle = settlement
                if (settlement.settlementBedIds ~= nil) then
                    for x, bed in ipairs(settlement.settlementBedIds) do
                        bedCount = bedCount + 1
                    end
                    for x, bed in ipairs(settlement.settlementNPCs) do
                        settlerCount = settlerCount + 1
                    end
                end
                if (lastNPCSpawn == nil) then
                    lastNPCSpawn = 0
                end
                
                if (bedCount > settlerCount and core.getGameTime() > lastNPCSpawn + time.day) then
                    print("It's time to bring someone new in!")
                    I.ZackUtilsAA.getPlayer():sendEvent("addActorToSettlement", object)
                    lastNPCSpawn = core.getGameTime()
                end
            end
        end
    end
end
local function addSettlerEvent(data)
    addActorToSettlement(data.settlementId, data.position)
end
local function removeSettlementTagEvent(data)
    print(data.tagName)
    RemoveSettlementTag(data.settlementId, data.tagName)
    print(data.tagName)
end

local function onLoad(data)
    if (data) then
        settlementList = data.settlementList
        lastNPCSpawn = data.lastNPCSpawn
        for x, settlement in ipairs(settlementList) do
            if (settlementList[x].settlementTags == nil) then
                settlementList[x].settlementTags = {}
            end
            if (settlementList[x].settlementBedIds == nil) then
                settlementList[x].settlementBedIds = {}
            end
        end
        updateSettlementData()
    else

    myModData:set("settlementList", settlementList)
    end
end
local function onSave()
    return { settlementList = settlementList, lastNPCSpawn = lastNPCSpawn }
end
return {
    interfaceName = "AA_Settlements",
    interface = {
        version = 1,
        addSettlement = addSettlement,
        settlementList = settlementList,
        addStructureToSettlement = addStructureToSettlement,
        findSettlement = findSettlement,
        addActorToSettlement = addActorToSettlement,
        ActorSwap = ActorSwap,
        printActorIds = printActorIds,
        RemoveSettlementTag = RemoveSettlementTag,
        AddSettlementTag = AddSettlementTag,
        HasSettlementTag = HasSettlementTag,
        removeBedId = removeBedId,
        addBedId = addBedId,
        printBedIds = printBedIds,
    },
    eventHandlers = {
        addSettlementEvent = addSettlementEvent,
        ActorSwapEvent = ActorSwapEvent,
        addActorToSettlement = addActorToSettlement,
        removeSettlementTagEvent = removeSettlementTagEvent,
        addSettlementTagEvent = addSettlementTagEvent,
        RemoveBedIdEvent = RemoveBedIdEvent,
        addBedIdEvent = addBedIdEvent,
        addSettlerEvent = addSettlerEvent,
        UpdateShopContainer = UpdateShopContainer,
        CreateShopContainer = CreateShopContainer,
    },
    engineHandlers = { onInit = onInit, onSave = onSave, onLoad = onLoad, onObjectActive = onObjectActive, }
}
