local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("MaterialStorage")
local ReferenceManager = require("CraftingFramework.components.ReferenceManager")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")

---@class CraftingFramework.MaterialStorage.storedMaterial
---@field item tes3item The stored item
---@field itemDatas? tes3itemData[] The item datas of the stored item
---@field count number The amount of the item
---@field storedIn tes3reference The reference that the item is stored in
---@field storageInstance CraftingFramework.MaterialStorage The MaterialStorage instance that the item is stored in

---@class CraftingFramework.MaterialStorage.removeItem.params
---@field reference tes3reference The reference to remove the item from
---@field item tes3item|tes3misc The item to remove
---@field count number The amount of the item to remove
---@field itemData tes3itemData? The item data to remove

---@class CraftingFramework.MaterialStorage.data
---@field ids? table<string, boolean>
---@field isStorage? fun(self: CraftingFramework.MaterialStorage, reference: tes3reference): boolean A callback that returns true if the given reference is a storage container. Required if `ids` is not defined
---@field getMaterials? fun(self: CraftingFramework.MaterialStorage, reference: tes3reference): CraftingFramework.MaterialStorage.storedMaterial[] A callback that returns a list of materials stored in the given reference. Required if MaterialStorage is not a container
---@field removeItem? fun(self: CraftingFramework.MaterialStorage, params: CraftingFramework.MaterialStorage.removeItem.params): number A callback that removes the given item from the storage. Returns how many were actually removed. Required if MaterialStorage is not a container

--- Defines an object which stores materials that can be
--- used in crafting recipes when nearby.
--- Can be a container, or a reference with
--- a callback that determines what materials
--- are available
---@class CraftingFramework.MaterialStorage : CraftingFramework.MaterialStorage.data
local MaterialStorage = {
    registeredMaterialStorages = {}
}

MaterialStorage.referenceManager = ReferenceManager:new{
    id = "MaterialStorage",
    logger = logger,
    requirements = function(self, reference)
        for _, materialStorage in ipairs(MaterialStorage.registeredMaterialStorages) do
            if materialStorage:isStorage(reference) then
                return true
            end
        end
        return false
    end
}

---@param data CraftingFramework.MaterialStorage.data
function MaterialStorage:new(data)
    logger:assert((data.ids ~= nil) or (data.isStorage ~= nil),
        "MaterialStorage must have either ids table or isStorage callback")
    local materialStorage = table.copy(data)
    setmetatable(materialStorage, self)
    self.__index = self
    table.insert(MaterialStorage.registeredMaterialStorages, materialStorage)
    return materialStorage
end

---@return CraftingFramework.MaterialStorage?
function MaterialStorage.getStorageForRef(reference)
    for _, materialStorage in ipairs(MaterialStorage.registeredMaterialStorages) do
        if materialStorage:isStorage(reference) then
            return materialStorage
        end
    end
end

---Check if the stored material is valid for use
--- - if it is a carryable container, check that it is empty
---@param storedMaterial CraftingFramework.MaterialStorage.storedMaterial
---@return boolean isValid
function MaterialStorage.isValidStoredMaterial(storedMaterial)
    local carryable = CarryableContainer:new{ item = storedMaterial.item }
    if carryable then
        local containerRef = carryable:getContainerRef()
        if containerRef then
            if #containerRef.object.inventory.items > 0 then
                logger:warn("Found non-empty carryable container material")
                return false
            end
        end
    end
    return true
end

--[[
    The list of nearby storage refs is cached for one simulation frame
]]
---@param maxDistance number The distance to search for nearby material storages
function MaterialStorage.getNearbyStorageRefs(maxDistance)
    logger:trace("Getting nearby storage refs")
    ---@type tes3reference[]
    local storageRefs = {}
    MaterialStorage.referenceManager:iterateReferences(function(storageRef)
        logger:trace("- Found %s", storageRef.object.name)
        local closeEnough = tes3.player.position:distance(storageRef.position) <= maxDistance
        if not closeEnough then
            logger:trace("Ignoring %s because it is too far away", storageRef.object.name)
            return
        end
        if storageRef.deleted then return end
        table.insert(storageRefs, storageRef)
    end)
    return storageRefs
end


---@return CraftingFramework.MaterialStorage.storedMaterial[]?
function MaterialStorage.getNearbyMaterialsCache()
    return tes3.player.tempData.nearbyMaterials
end

---@param materials CraftingFramework.MaterialStorage.storedMaterial[]
function MaterialStorage.setNearbyMaterialsCache(materials)
    logger:trace("Setting nearby materials cache")
    tes3.player.tempData.nearbyMaterials = materials
    --Log all cached materials
    for _, storedMaterial in ipairs(materials) do
        logger:trace("Cached %s %s in %s",
        storedMaterial.count,
        storedMaterial.item.id,
        storedMaterial.storedIn.object.name
    )
    end
    timer.delayOneFrame(function()
        MaterialStorage.clearNearbyMaterialsCache()
    end)
end

function MaterialStorage.clearNearbyMaterialsCache()
    logger:trace("Clearing nearby materials cache")
    tes3.player.tempData.nearbyMaterials = nil
end

---@class CraftingFramework.MaterialStorage.getNearbyMaterials.params
---@field maxDistance number The maximum distance to search for nearby material storages
---@field searchAllContainers boolean? `Default: false` If true, will search all containers for materials, not just registered material storages
---@field ignoreNearbyContainers boolean? `Default: false` If true, will not search nearby containers for materials

---@param e CraftingFramework.MaterialStorage.getNearbyMaterials.params
---@return CraftingFramework.MaterialStorage.storedMaterial[]
function MaterialStorage.getNearbyMaterials(e)
    logger:trace("Getting nearby materials")

    local cache = MaterialStorage.getNearbyMaterialsCache()
    if cache then
        logger:trace("Using cached nearby materials")
        return cache
    end

    local nearbyMaterials = {}

    if not e.ignoreNearbyContainers then
        logger:trace("- Searching nearby containers")

        local storageRefs = MaterialStorage.getNearbyStorageRefs(e.maxDistance)
        ---@type CraftingFramework.MaterialStorage.storedMaterial[]
        for _, ref in ipairs(storageRefs) do
            local materialStorage = MaterialStorage.getStorageForRef(ref)
            if materialStorage then
                logger:assert(materialStorage~=nil, "No material storage registered for %s", ref.baseObject.id)
                local storedMaterials = materialStorage:getMaterials(ref)
                for _, storedMaterial in ipairs(storedMaterials) do
                    logger:trace("Found %s %s in %s", storedMaterial.count, storedMaterial.item, ref.object.name)
                    table.insert(nearbyMaterials, storedMaterial)
                end
            end
        end
        if e.searchAllContainers then
            ---find all containers which aren't already storages
            for _, cell in pairs(tes3.getActiveCells()) do
                for containerRef in cell:iterateReferences(tes3.objectType.container) do
                    local isValid = containerRef.object.organic ~= true
                        and tes3.getOwner{ reference = containerRef } == nil
                        and not MaterialStorage.referenceManager.references[containerRef]
                    if isValid then
                        local storedMaterials = MaterialStorage:getMaterials(containerRef)
                        for _, storedMaterial in ipairs(storedMaterials) do
                            table.insert(nearbyMaterials, storedMaterial)
                        end
                    end
                end
            end
        end
    end

    --Search carryable containers in player inventory
    for _, carryable in ipairs(CarryableContainer.getCarryableContainersInInventory()) do
        local carryableRef = carryable:getContainerRef()
        if carryableRef then
            local storedMaterials = MaterialStorage:getMaterials(carryableRef)
            for _, storedMaterial in ipairs(storedMaterials) do
                table.insert(nearbyMaterials, storedMaterial)
            end
        end
    end

    --Search the player's inventory itself
    for _, itemStack in pairs(tes3.player.object.inventory) do
        local storedMaterial = {
            item = itemStack.object,
            itemDatas = itemStack.variables,
            count = itemStack.count,
            storedIn = tes3.player,
            storageInstance = MaterialStorage
        }
        if MaterialStorage.isValidStoredMaterial(storedMaterial) then
            table.insert(nearbyMaterials, storedMaterial)
        end
    end

    logger:trace("Found %s nearby materials", #nearbyMaterials)
    MaterialStorage.setNearbyMaterialsCache(nearbyMaterials)
    return nearbyMaterials
end



---Can be overridden by implementations of MaterialStorage
function MaterialStorage:isStorage(reference)
    logger:assert(self.ids ~= nil, "MaterialStorage %s has no ids", reference.object.id)
    return self.ids[reference.baseObject.id:lower()] == true
end

---Can be overridden by implementations of MaterialStorage
---@param reference tes3reference
function MaterialStorage:getMaterials(reference)
    logger:assert(reference.object.inventory ~= nil, "MaterialStorage %s has no inventory", reference.object.id)
    ---@type CraftingFramework.MaterialStorage.storedMaterial[]
    local materials = {}
    for _, itemStack in pairs(reference.object.inventory) do
        local storedMaterial = {
            item = itemStack.object,
            itemDatas = itemStack.variables,
            count = itemStack.count,
            storedIn = reference,
            storageInstance = self
        }
        if MaterialStorage.isValidStoredMaterial(storedMaterial) then
            table.insert(materials, storedMaterial)
        end
    end
    return materials
end

---Can be overridden by implementations of MaterialStorage
---@param params CraftingFramework.MaterialStorage.removeItem.params
---@return number The amount of items removed
function MaterialStorage:removeItem(params)
    logger:assert(params.reference.object.inventory ~= nil, "MaterialStorage %s has no inventory", params.reference.object.id)

    logger:trace("Removing %s %s", params.count, params.item.name)
    local numRemoved = tes3.removeItem{
        reference = params.reference,
        item = params.item,
        itemData = params.itemData,
        count = params.count,
        playSound = false,
        updateGUI = false
    }
    return numRemoved
end

return MaterialStorage