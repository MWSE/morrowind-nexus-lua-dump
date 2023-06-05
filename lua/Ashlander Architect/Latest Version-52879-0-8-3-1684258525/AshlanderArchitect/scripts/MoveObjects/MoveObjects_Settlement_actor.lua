local storage = require("openmw.storage")
local self = require("openmw.self")
local I = require("openmw.interfaces")

local types = require("openmw.types")

local util = require("openmw.util")
local core = require("openmw.core")
local settlementModData = storage.globalSection("AASettlements")
local CellGenData = storage.globalSection("MoveObjectsCellGen")

local currentCell = nil

local mySettlement = nil

local houseId = nil
local bedId = nil
local houseEntryPoint = nil

local role = nil
local exiting = false
local targetStructure = nil

local jobSiteId = nil
local jobSiteOb = nil
local desiredRotation = -1



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
        print(dist)
        if (dist < structure.settlementDiameter / 2) then
            mySettlement = structure.markerId
        end
    end
end
local function migrateData(target)
    target:sendEvent("recieveMigration",
        { mySettlement = mySettlement, desiredRotation = desiredRotation, jobSiteId = jobSiteId, jobSiteOb = jobSiteOb })
    core.sendGlobalEvent("ZackUtilsDelete", self)
end
local function recieveMigration(data)
    mySettlement = data.mySettlement
    desiredRotation = data.desiredRotation
    jobSiteId = data.jobSiteId
    I.AI.startPackage({ type = "Travel", destPosition = data.jobSiteOb.position })
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

local function setJobSite(ref)
    jobSiteId = ref.id
    jobSiteOb = ref
    I.AI.startPackage({ type = "Travel", destPosition = ref.position })
    desiredRotation = ref.rotation.z
    if (jobSiteOb.recordId == "zhac_settlement_marker1" and types.NPC.record(self).class ~= "caravaner") then
        core.sendGlobalEvent("ActorSwapEvent",
            { currentActor = self, newActorId = replaceLastChar(self.recordId, "t"), settlementId = mySettlement })
    elseif (jobSiteOb.recordId == "zhac_settlement_marker_c" and types.NPC.record(self).class ~= "clothier") then
                core.sendGlobalEvent("ActorSwapEvent",
                    { currentActor = self, newActorId = replaceLastChar(self.recordId, "c"), settlementId = mySettlement })
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


local function onUpdate()

    if (currentCell == nil) then
        --  print("Looking")
        for x, structure in ipairs(CellGenData:get("generatedStructures")) do
            --   print(structure.InsideCellName)
            if (self.cell.name == structure.InsideCellName) then
                --      print(self.cell.name)
                currentCell = self.cell.name
            end
        end
    end
    if (targetStructure ~= nil) then
        if (exiting) then
            local dist = math.sqrt((self.position.x - targetStructure.InsidePos.x) ^ 2 +
                (self.position.y - targetStructure.InsidePos.y) ^ 2 +
                (self.position.z - targetStructure.InsidePos.z) ^ 2)
            if (dist < 100) then
                if (targetStructure.OutsideCellExt == false) then
                    currentCell = targetStructure.OutsideCellInt
                else
                    currentCell = ""
                end
                print("exiting to : " .. currentCell,
                    util.vector3(targetStructure.OutsidePos.x, targetStructure.OutsidePos.y,
                        targetStructure.OutsidePos.z))
                core.sendGlobalEvent("ZackUtilsTeleportToCell",
                    {
                        item = self,
                        cellname = currentCell,
                        position = util.vector3(targetStructure.OutsidePos.x, targetStructure.OutsidePos.y,
                            targetStructure.OutsidePos.z),
                        rotation = util.vector3(0, 0, targetStructure.OutsideZRot)
                    })
                targetStructure = nil
            end
        else
            local dist = math.sqrt((self.position.x - targetStructure.OutsidePos.x) ^ 2 +
                (self.position.y - targetStructure.OutsidePos.y) ^ 2 +
                (self.position.z - targetStructure.OutsidePos.z) ^ 2)
            if (dist < 100) then
                currentCell = targetStructure.InsideCellName
                print("entering: " .. targetStructure.InsideCellName,
                    util.vector3(targetStructure.InsidePos.x, targetStructure.InsidePos.y,
                        targetStructure.InsidePos.z))
                core.sendGlobalEvent("ZackUtilsTeleportToCell",
                    {
                        item = self,
                        cellname = targetStructure.InsideCellName,
                        position = util.vector3(targetStructure.InsidePos.x, targetStructure.InsidePos.y,
                            targetStructure.InsidePos.z),
                        rotation = util.vector3(0, 0, targetStructure.InsideZRot)
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
local function enterBuilding(data)
    local doorId = data.doorId
    exiting = false
    for x, structure in ipairs(CellGenData:get("generatedStructures")) do
        if (structure.OutsideDoorID == doorId) then
            I.AI.startPackage({ type = "Travel", destPosition = structure.OutsidePos })
            targetStructure = structure
            return
        end
    end
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
    I.AI.startPackage({ type = "Travel", destPosition = pos })
end
local function setEquipment(equip)
    types.Actor.setEquipment(self, equip)
end
local function onSave()
    return { mySettlement = mySettlement, desiredRotation = desiredRotation, jobSiteId = jobSiteId }
end
local function onLoadEvent()
end

local function onActivated(actor)
    actor:sendEvent("activated", self)
end
return {
    engineHandlers = {
        onInit = onInit,
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
    }
}
