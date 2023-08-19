local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("MaterialStorage")
local ReferenceManager = require("CraftingFramework.components.ReferenceManager")

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

function MaterialStorage.getStorageForRef(reference)
    for _, materialStorage in ipairs(MaterialStorage.registeredMaterialStorages) do
        if materialStorage:isStorage(reference) then
            return materialStorage
        end
    end
end


--[[
    The list of nearby storage refs is cached for one simulation frame
]]
---@param maxDistance number The distance to search for nearby material storages
function MaterialStorage.getNearbyStorageRefs(maxDistance)
    if tes3.player.tempData.nearbyStorageRefs then
        return tes3.player.tempData.nearbyStorageRefs
    end
    ---@type tes3reference[]
    local storageRefs = {}
    MaterialStorage.referenceManager:iterateReferences(function(storageRef)
        local closeEnough = tes3.player.position:distance(storageRef.position) <= maxDistance
        if not closeEnough then return end
        if storageRef.disabled or storageRef.deleted then return end
        table.insert(storageRefs, storageRef)
    end)
    tes3.player.tempData.nearbyStorageRefs = storageRefs
    timer.delayOneFrame(function()
        tes3.player.tempData.nearbyStorageRefs = nil
    end)
    return storageRefs
end


function MaterialStorage:isStorage(reference)
    logger:assert(self.ids ~= nil, "MaterialStorage %s has no ids", reference.object.id)
    return self.ids[reference.baseObject.id:lower()] == true
end

---@class CraftingFramework.MaterialStorage.getNearbyMaterials.params
---@field maxDistance number The maximum distance to search for nearby material storages
---@field searchAllContainers boolean? `Default: false` If true, will search all containers for materials, not just registered material storages

---@param e CraftingFramework.MaterialStorage.getNearbyMaterials.params
---@return CraftingFramework.MaterialStorage.storedMaterial[]
function MaterialStorage.getNearbyMaterials(e)
    logger:debug("Getting nearby Materials")
    local storageRefs = MaterialStorage.getNearbyStorageRefs(e.maxDistance)
    ---@type CraftingFramework.MaterialStorage.storedMaterial[]
    local nearbyMaterials = {}
    for _, ref in ipairs(storageRefs) do
        local materialStorage = MaterialStorage.getStorageForRef(ref)
        logger:assert(materialStorage~=nil, "No material storage registered for %s", ref.baseObject.id)
        local storedMaterials = materialStorage:getMaterials(ref)
        for _, storedMaterial in ipairs(storedMaterials) do
            table.insert(nearbyMaterials, storedMaterial)
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
    logger:debug("Found %s nearby materials", #nearbyMaterials)
    return nearbyMaterials
end

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
        table.insert(materials, storedMaterial)
    end
    return materials
end

---@param params CraftingFramework.MaterialStorage.removeItem.params
---@return number The amount of items removed
function MaterialStorage:removeItem(params)
    logger:assert(params.reference.object.inventory ~= nil, "MaterialStorage %s has no inventory", params.reference.object.id)
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