local interFaceLoaded, I = pcall(require, "openmw.interfaces")

local utilLoaded, util = pcall(require, "openmw.util")
local coreLoaded, core = pcall(require, "openmw.core")
local typesLoaded, types = pcall(require, "openmw.types")
local storageLoaded, storage = pcall(require, "openmw.storage")
local worldLoaded, world = pcall(require, "openmw.world")


local mwse = true--not coreLoaded
local ZackBridge = {}

local ZackBridgeEngineHandlers = nil
local allTypes = {

}
if (mwse) then
    ZackBridgeEngineHandlers = require("SmoothMasterIndex.scripts.SmoothMasterIndex.ZackBridgeEngineHandlers")
    allTypes = {
        ["Container"] = tes3.objectType.container,
        ["Activator"] = tes3.objectType.activator,
        ["Apparatus"] = tes3.objectType.apparatus,
        ["Ingredient"] = tes3.objectType.ingredient,
        ["NPC"] = tes3.objectType.npc,
        ["Miscellaneous"] = tes3.objectType.miscItem
    }
else
    allTypes = {
        ["Apparatus"] = types.Apparatus,
        ["Armor"] = types.Armor,
        ["Book"] = types.Book,
        ["Clothing"] = types.Clothing,
        ["Ingredient"] = types.Ingredient,
        ["Light"] = types.Light,
        ["Lockpick"] = types.Lockpick,
        ["Miscellaneous"] = types.Miscellaneous,
        ["Potion"] = types.Potion,
        ["Probe"] = types.Probe,
        ["Repair"] = types.Repair,
        ["Weapon"] = types.Weapon,
        ["Creature"] = types.Creature,
        ["Door"] = types.Door,
        ["NPC"] = types.NPC,
        ["Player"] = types.Player,
        ["Static"] = types.Static,
        ["Container"] = types.Container
    }
end
--get specific objects



function ZackBridge.getPlayer()
    if (mwse) then
        return tes3.player
    end
    for index, value in ipairs(world.activeActors) do
        if (value.type == types.Player) then
            return value
        end
    end
end
function ZackBridge.vector3(x,y,z)
return tes3vector3.new(x,y,z)
end
function ZackBridge.getObjectRecordId(object)
if(mwse) then
    if(object.id ~= nil) then
        
return object.id
    elseif(object.object.id ~= nil) then
        return object.object.id
    end
    return
end
return object.recordId

end
function ZackBridge.getOwnerId(object)
    if (mwse) then
        if(tes3.getOwner(object) ~= nil) then
        return tes3.getOwner(object).id
        end
        
        return
    end
    return object.ownerRecordId
end

--work with items and inventories
function ZackBridge.getInventory(object)
    if (mwse) then
        if (object.object ~= nil) then
            return object.object.inventory
        else
            return object.inventory
        end
    end
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
end

function ZackBridge.SplitStack(item, count)
    if (mwse) then
        return
    end
    return item:split(count)
end

function ZackBridge.TransferItem(to, itemToTransfer, count)
    if (mwse) then
        return
    end
    itemToTransfer:moveInto(ZackBridge.getInventory(to), count)
end
function ZackBridge.TeleportItem(object,newCell,newPos,newRot)
    if(newRot == nil) then
        newRot = 0
    end
if(mwse) then
    tes3.positionCell({
        object = object,
        cell = newCell,
        position = newPos,
        orientation = newRot
    })
    return
end
object:teleport(newCell, newPos)

end
function ZackBridge.getInventoryTable(object, obType)
    if (mwse) then
        return
    end
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object):getAll(allTypes[obType])
    elseif (object.type == types.Container) then
        return types.Container.content(object):getAll(allTypes[obType])
    end
end

function ZackBridge.RemoveItem(itemId, count, actor)
    if (mwse) then
        return
    end
    ZackBridge.getInventory(actor):find(itemId):remove(count)
end

function ZackBridge.AddItem(itemId, count, actor)
    if (mwse) then
        tes3.addItem({ reference = actor, item = itemId, playSound = false, count = count })
        return
    end
    local item = world.createObject(itemId, count)

    local inv = ZackBridge.getInventory(actor)
    item:moveInto(types.Actor.inventory(actor))
    return item
end

--work with record data
local miscConsts = {}

if (mwse == false) then
    miscConsts = {
        ["Alembic"] = types.Apparatus.TYPE.Alembic,
        ["Calcinator"] = types.Apparatus.TYPE.Calcinator,
        ["MortarPestle"] = types.Apparatus.TYPE.MortarPestle,
        ["Retort"] = types.Apparatus.TYPE.Retort,
    }
else
    miscConsts = {
        ["Alembic"] = tes3.apparatusType.alembic,
        ["Calcinator"] = tes3.apparatusType.calcinator,
        ["MortarPestle"] = tes3.apparatusType.mortarPestle,
        ["Retort"] = tes3.apparatusType.retort,
    }
end

function ZackBridge.getConst(constName)
    if (mwse) then
        return
    end
    return miscConsts[constName]
end

function ZackBridge.isWorldPaused()
    if (mwse) then
        return false
    end
    return core.isWorldPaused()
end

function ZackBridge.getObjectsInCell(cellOrCellname, obType)
    if (mwse) then
        local myType = allTypes[obType]
        local cell = cellOrCellname
        if (cell.id == nil) then
            cell = ZackBridge.getCell(cell)
        end
        local refs = {}
        for ref in cell:iterateReferences(myType) do
            table.insert(refs, ref)
        end
        return refs
    end
    local cell = cellOrCellname
    if (cell.name == nil) then
        cell = world.getCellByName(cell)
    else
        cell = cellOrCellname
    end
    local myType = allTypes[obType]
    return cell:getAll(myType)
end

function ZackBridge.getObjectRecordData(item)
    if (mwse) then
        if (item.object ~= nil) then
            return {
                quality = item.object.quality,
                type = item.object.type
            }
        else
            return {
                quality = item.quality,
                type = item.type
            }
        end
    end
    local quality = nil
    local type = nil
    if (item.type.TYPE ~= nil) then
        quality = item.type.record(item).quality
        type = item.type.record(item).type
    end
    return {
        quality = quality,
        type = type
    }
end

--handle events
local function AddEngineHandlerMWSE(functionName, func)

end
function ZackBridge.AddEngineHandler(functionName, func)
    if (mwse) then
        ZackBridgeEngineHandlers.addFunction(functionName, func)
        return
    end
    I.ZackBridgeEngineHandlers.addFunction(functionName, func)
end

local function AddObjectTypeActivationHandlerMWSE(typeName, handler)

end
function ZackBridge.AddObjectTypeActivationHandler(typeName, handler)
    if (allTypes[typeName] == nil) then
        print("No type found", #allTypes, typeName)
        return
    end
    if (mwse) then
        ZackBridgeEngineHandlers.RegisterActivateByType(handler, allTypes[typeName])
        return
    end
    I.Activation.addHandlerForType(allTypes[typeName], handler)
end

function ZackBridge.AddObjectActivationHandler(object, handler)
    if (mwse) then
        return
    end
    I.Activation.addHandlerForObject(object, handler)
end

function ZackBridge.getCell(cellName)
    if (mwse) then
        return tes3.getCell({ id = cellName })
    end
    return world.getCellByName(cellName)
end

return ZackBridge
