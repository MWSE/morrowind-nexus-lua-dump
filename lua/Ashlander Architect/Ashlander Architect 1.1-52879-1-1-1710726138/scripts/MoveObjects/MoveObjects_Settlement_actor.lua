local storage = require("openmw.storage")
local self = require("openmw.self")
local I = require("openmw.interfaces")

local types = require("openmw.types")

local util = require("openmw.util")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local settlementModData = storage.globalSection("AASettlements")
local CellGenData = storage.globalSection("MoveObjectsCellGen")
local cellGenStorage = storage.globalSection("AACellGen2")


local currentCell = nil

local mySettlement = nil

local houseId = nil
local bedId = nil
local houseEntryPoint = nil

local role = nil
local exiting = false
local targetStructure = nil
local targetDoor
local jobSiteId = nil
local jobSiteOb = nil
local desiredRotation = -1
local function getJobSiteOb()
    if not jobSiteOb and jobSiteId then
        for index, value in ipairs(nearby.activators) do
            if value.recordId == jobSiteId then
                jobSiteOb = value

                return value
            end
        end
    else
        if jobSiteOb then
            return jobSiteOb
        end
    end
end
local shufflePos = false
local shuffleCell = nil
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
local function getMyShopCont()
    for index, cont in ipairs(nearby.containers) do
        if (cont.owner.recordId == self.recordId and cont.recordId == "chest_small_02") then
            return cont
        end
    end
    return nil
end
local function UpdateShopInv()
    local myShopCont = getMyShopCont()

    if (myShopCont == nil) then
        core.sendGlobalEvent("CreateShopContainer", { actor = self })
    else
        core.sendGlobalEvent("UpdateShopContainer", { actor = self, shopcont = myShopCont })
    end
end
local function onInit(initdata)
    if (initdata ~= nil and initdata.mySettlement ~= nil) then
        mySettlement = initdata.mySettlement
        I.AI.startPackage({ type = "Wander", distance = 500 })
        return
    end
    for x, structure in ipairs(settlementModData:get("settlementList")) do
        print("Found one")
        local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
            (self.position.y - structure.settlementCentery) ^ 2 +
            (self.position.z - structure.settlementCenterz) ^ 2)
        if (dist < structure.settlementDiameter / 2) then
            mySettlement = structure.markerId
        end
    end
end
local function migrateData(target)
    if (getMyShopCont() ~= nil) then
        core.sendGlobalEvent("ZackUtilsDelete", getMyShopCont())
    end
    target:sendEvent("recieveMigration",
        { mySettlement = mySettlement, desiredRotation = desiredRotation, jobSiteId = jobSiteId, jobSiteOb = jobSiteOb })
    core.sendGlobalEvent("ZackUtilsDelete", self)
end
local function recieveMigration(data)
    mySettlement = data.mySettlement
    desiredRotation = data.desiredRotation
    jobSiteId = data.jobSiteId
    I.AI.startPackage({ type = "Travel", destPosition = data.jobSiteOb.position })
    local myShopCont = getMyShopCont()

    if (myShopCont == nil) then
        core.sendGlobalEvent("CreateShopContainer", { actor = self })
    else
        core.sendGlobalEvent("UpdateShopContainer", { actor = self, shopcont = myShopCont })
    end
end
local function addItemEquip(actor, itemId)
    local count = 1

    core.sendGlobalEvent("ZackUtilsAddItem", { actor = actor, itemId = itemId, count = count, equip = true })
end
local function attackTarget(target)
    I.AI.startPackage({ type = "Combat", target = target })
end
local function replaceLastChar(str, replacement)
    if #str > 0 then
        local lastCharIndex = #str
        local newStr = string.sub(str, 1, lastCharIndex - 1) .. replacement
        return newStr
    else
        return str
    end
end
local function replaceLastTwoChars(str, replacement)
    if #str > 1 then
        local lastTwoCharsIndex = #str - 2
        local newStr = string.sub(str, 1, lastTwoCharsIndex) .. replacement
        return newStr
    else
        return str
    end
end

local function myIDForJobBlock(blockId)
    for index, value in ipairs(TypeTable) do
        if (value.MarkerID:lower() == blockId:lower()) then
            return replaceLastTwoChars(self.recordId, value.NPCPostfix:lower())
        end
    end
end
local function setJobSite(ref)
    jobSiteId = ref.id
    jobSiteOb = ref
    I.AI.startPackage({ type = "Travel", destPosition = ref.position })
    desiredRotation = ref.rotation.z
    -- if(true) then
    --return
    --  end
    if (myIDForJobBlock(jobSiteOb.recordId) ~= self.recordId) then
        core.sendGlobalEvent("ActorSwapEvent",
            { currentActor = self, newActorId = myIDForJobBlock(jobSiteOb.recordId), settlementId = mySettlement })
    end
end
local function findSlot(item)
    if item.type == types.Armor then
        return types.Armor.record(item).enchant
    elseif item.type == types.Book then
        return types.Book.record(item).enchant
    elseif item.type == types.Clothing then
        if (types.Clothing.record(item).type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.record(item).type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        end
    elseif item.type == types.Weapon then
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    end
    print("Couldn't find slot for " .. item.recordId)
    return false
end
local function equipItem(itemId)
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end

local function addItemEquipReturn(data)
    equipItem(data.recordId)
end
local function equipItems(itemTable)
    local inv = types.Actor.inventory(self)

    local equip = types.Actor.getEquipment(self)
    for index, itemId in ipairs(itemTable) do
        local item = inv:find(itemId)
        local slot = findSlot(item)
        if (slot) then
            equip[slot] = item
        end
    end

    types.Actor.setEquipment(self, equip)
end

local function addItemEquipReturn(data)
    equipItem(data.recordId)
end
local function shufflePosInCell()
    local newPos = nearby.findRandomPointAroundCircle(self.position, 100)
    print("Shuffling")
    core.sendGlobalEvent("ZackUtilsTeleport", { item = self, position = newPos, rotation = self.rotation })
end

local function onUpdate()
    if (shuffleCell ~= nil and shuffleCell == self.cell.name) then
        shufflePosInCell()

        shuffleCell = nil
    elseif (shuffleCell ~= nil) then
        print(shuffleCell)
    end
    if jobSiteId then
        local jOb = getJobSiteOb()
        if jOb then
            local dist = math.sqrt((self.position.x - jOb.position.x) ^ 2 +
                (self.position.y - jOb.position.y) ^ 2 +
                (self.position.z - jOb.position.z) ^ 2)
        if dist < 10 then
            local jZ = jOb.rotation:getAnglesZYX() --- math.rad(90)
            local mZ = self.rotation:getAnglesZYX()
            local diff = math.abs(math.deg(jZ - mZ))
            if diff < -15 then
                self.controls.yawChange = 0.01
            elseif diff > 15 then
                self.controls.yawChange = -0.01
            end
        end
    end
end
    if (currentCell == nil) then
        --  print("Looking")

        local intData = cellGenStorage:get("CellGenData")
        for x, structure in ipairs(intData) do
            --   print(structure.InsideCellName)
            if (self.cell.name == structure.cellName) then
                --      print(self.cell.name)
                currentCell = self.cell.name
            end
        end
    end
    if (targetStructure ~= nil and targetDoor ~= nil) then
        if (exiting) then
            local dist = math.sqrt((self.position.x - targetDoor.position.x) ^ 2 +
                (self.position.y - targetDoor.position.y) ^ 2 +
                (self.position.z - targetDoor.position.z) ^ 2)
            if (dist < 500) then
                currentCell = targetStructure.targetCell
                print("entering: " .. targetStructure.targetCell)
                --util.vector3(targetStructure.InsidePos.x, targetStructure.InsidePos.y,
                --     targetStructure.InsidePos.z))
                shuffleCell = targetStructure.InsideCellName
                core.sendGlobalEvent("ZackUtilsTeleportToCell",
                    {
                        item = self,
                        cellname = targetStructure.targetCell,
                        position = util.vector3(targetStructure.targetPosition.x, targetStructure.targetPosition.y,
                            targetStructure.targetPosition.z),
                        rotation = util.vector3(0, 0, targetStructure.targetRotation)
                    })
                targetStructure = nil
            else
                print(dist)
            end
        else
            local dist = math.sqrt((self.position.x - targetDoor.position.x) ^ 2 +
                (self.position.y - targetDoor.position.y) ^ 2 +
                (self.position.z - targetDoor.position.z) ^ 2)
            if (dist < 500) then
                currentCell = targetStructure.targetCell
                print("entering: " .. targetStructure.targetCell)
                --util.vector3(targetStructure.InsidePos.x, targetStructure.InsidePos.y,
                --     targetStructure.InsidePos.z))
                shuffleCell = targetStructure.InsideCellName
                core.sendGlobalEvent("ZackUtilsTeleportToCell",
                    {
                        item = self,
                        cellname = targetStructure.targetCell,
                        position = util.vector3(targetStructure.targetPosition.x, targetStructure.targetPosition.y,
                            targetStructure.targetPosition.z),
                        rotation = util.vector3(0, 0, targetStructure.targetRotation)
                    })
                targetStructure = nil
            end
        end
    end
end
local function startWander()
    I.AI.startPackage({ type = "Wander", distance = 500 })
end
local function goToHouse()
    for x, structure in ipairs(CellGenData:get("generatedStructures")) do
        if (structure.settlementId == mySettlement) then
            I.AI.startPackage({ type = "Travel", destPosition = structure.OutsidePos })
            targetStructure = structure
            return
        end
    end
end
---{
-- sourceObj = copiedObject.id,
--=--  targObj = exteriorNewDoor.id,
--  targetPosition = exteriorPos,
-- targetRotation =
--    exteriorNewDoor.rotation:getAnglesZYX() + math.rad(180) + math.rad(rotOffset),
--targetCell = world.players[1].cell.name,
--targetLabel = exteriorCellLabel,
-- intIndex = posIndex

--}
local function getTargetStructure(id)
    for index, value in pairs(cellGenStorage:get("doorData")) do
        if index == id then
            local doorOb
            local retData
            for indexx, value in ipairs(nearby.activators) do
                if value.id == index then
                    doorOb = value
                end
            end
            if not doorOb then
                print(id)
                error("Unable to find door")
            end
            for index, valuex in pairs(cellGenStorage:get("doorData")) do
                if index == value.targObj then
                    retData = valuex
                end
            end
            if not retData then
                error("Unable to find return door")
            end

            return value, doorOb, retData
        end
    end
end
local function enterBuilding(data)
    local doorId = data.doorId
    exiting = false
    local targStruct, doorOb, returnData = getTargetStructure(doorId)
    targetStructure = targStruct
    targetDoor = doorOb
    if not targetStructure then return end
    I.AI.startPackage({ type = "Travel", destPosition = returnData.targetPosition })
end


local function exitBuilding(data)
    local doorId = data.doorId
    exiting = true
    for x, structure in ipairs(CellGenData:get("generatedStructures")) do
        if (structure.InsideDoorID == doorId) then
            I.AI.startPackage({ type = "Travel", destPosition = structure.InsidePos })
            targetStructure = structure
            return
        end
    end
end
local function onLoad(data)
    if (data) then
        mySettlement = data.mySettlement
        desiredRotation = data.desiredRotation
        jobSiteId = data.jobSiteId
    end
end

local function goToPosition(pos)
    --    self:enableAI(false)


    --  self:enableAI(true)

    I.AI.removePackages()
    print("Recived Order")
    I.AI.startPackage({ type = "Travel", destPosition = pos, cancelOther = true })
end
local function setEquipment(equip)
    types.Actor.setEquipment(self, equip)
end
local function onSave()
    return { mySettlement = mySettlement, desiredRotation = desiredRotation, jobSiteId = jobSiteId }
end
local function onLoadEvent()
end

local function onActive()
    UpdateShopInv()
end

local function onActivated(actor)
    --   actor:sendEvent("activated", self)
    --print("I was activated")
    local jobSiteOb = getJobSiteOb()
    local jobSiteData
    if jobSiteOb then
        for index, value in ipairs(TypeTable) do
            if (value.MarkerID:lower() == jobSiteOb.recordId:lower()) then
                jobSiteData = value
            end
        end
    end
    actor:sendEvent("processGreeting", { npc = self.object, jobSiteData = jobSiteData })
    --return false
end
return {
    interfaceName = "AA_Settlements",
    interface = {
        getJobSiteOb = getJobSiteOb
    },
    engineHandlers = {
        onInit = onInit,
        onActive = onActive,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate,
        onActivated = onActivated,
    },
    eventHandlers = {
        onLoadEvent = onLoadEvent,
        goToHouse = goToHouse,
        startWander = startWander,
        addItemEquipReturn = addItemEquipReturn,
        addItemEquip = addItemEquip,
        setEquipment = setEquipment,
        goToPosition = goToPosition,
        enterBuilding = enterBuilding,
        exitBuilding = exitBuilding,
        attackTarget = attackTarget,
        setJobSite = setJobSite,
        migrateData = migrateData,
        recieveMigration = recieveMigration,
        shufflePosInCell = shufflePosInCell,
        UpdateShopInv = UpdateShopInv,
        equipItems = equipItems,
    }
}
