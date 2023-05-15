local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation
local settlementList = {}
local myModData = storage.globalSection("AASettlements")
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
        npcSpawnPosition = npcSpawnPosition
    }
    table.insert(settlementList, settlementItem)
    myModData:set("settlementList", settlementList)
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
    local newActor = I.ZackUtilsG.ZackUtilsCreateInterface(newActorId, currentActor.cell.name, currentActor.position,
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
    myModData:set("settlementList", settlementList)
end
local function ActorSwapEvent(data)
    ActorSwap(data.currentActor, data.newActorId, data.settlementId)
end

local function addActorToSettlement(settlementId)
    local mySettlement = findSettlement(settlementId)
    local newActor = I.ZackUtilsG.ZackUtilsCreateInterface("zhac_aa_f_01_b", "", mySettlement.npcSpawnPosition)
    for x, structure in ipairs(settlementList) do
        if (structure.markerId == settlementId) then
            table.insert(settlementList[x].settlementNPCs, newActor.id)
        end
    end
    newActor:addScript("scripts/MoveObjects/MoveObjects_Settlement_actor.lua", { mySettlement = settlementId })
    myModData:set("settlementList", settlementList)
end
local function onInit()

end
local function onLoad(data)
    if (data) then
        settlementList = data.settlementList
        myModData:set("settlementList", settlementList)
        for x, structure in ipairs(settlementList) do
            print(structure.settlementCenterx)
        end
    end
end
local function onSave()
    return { settlementList = settlementList }
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
    },
    eventHandlers = {
        addSettlementEvent = addSettlementEvent,
        ActorSwapEvent = ActorSwapEvent,
        addActorToSettlement = addActorToSettlement,

    },
    engineHandlers = { onInit = onInit, onSave = onSave, onLoad = onLoad }
}
