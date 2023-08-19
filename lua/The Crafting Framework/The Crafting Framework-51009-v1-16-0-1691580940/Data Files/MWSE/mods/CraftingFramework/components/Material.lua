local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Material")
local MaterialStorage = require("CraftingFramework.components.MaterialStorage")

---@class CraftingFramework.Material.data
---@field id string **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `material`.
---@field name string The name of the material. Used in various UIs.
---@field ids table<number, string> **Required.**  This is the list of item ids that are considered as identical material.


---@class CraftingFramework.Material : CraftingFramework.Material.data
---@field ids table<string, boolean>
local Material = {
    schema = {
        name = "Material",
        fields = {
            id = { type = "string", required = true },
            name = { type = "string", required = false },
            ids = { type = "table", childType = "string", required = true },
        }
    }
}

Material.registeredMaterials = {}

---@param id string The id of the material
---@return CraftingFramework.Material material
function Material.getMaterial(id)
    local material = Material.registeredMaterials[id:lower()]
    if not material then
        logger:debug("no material found, checking object for %s", id)
        --if the material id is an actual in-game object
        -- create a new material for this object
        -- the object is the only item in the list
        local matObj = tes3.getObject(id)
        if matObj then
            logger:debug("Found object, creating new material")
            material = Material:new{
                id = id,
                name = matObj.name,
                ids = { id }
            }
        else
            logger:debug("No object found")
        end
    end
    return material
end

--- Returns the material that the item belongs to
---@param itemId string The id of the item
---@return CraftingFramework.Material|nil material
function Material.getMaterialOfItem(itemId)
    for _, material in pairs(Material.registeredMaterials) do
        if material:isMaterial(itemId) then
            return material
        end
    end
    --not a material
    return nil
end

---@param data CraftingFramework.Material.data
---@return CraftingFramework.Material material
function Material:new(data)
    Util.validate(data, Material.schema)
    data = table.copy(data)
    if not Material.registeredMaterials[data.id] then
        Material.registeredMaterials[data.id] = {
            id = data.id,
            name = data.name,
            ids = {}
        }
    end
    local material = Material.registeredMaterials[data.id]
    --add material ids
    for _, id in ipairs(data.ids) do
        logger:debug("registered %s as %s", id, material.id)
        material.ids[id:lower()] = true
    end
    setmetatable(material, self)
    self.__index = self
    return material
end

---@param materialList CraftingFramework.Material.data[]
function Material:registerMaterials(materialList)
    if materialList.id then ---@diagnostic disable-line: undefined-field
        logger:error("You passed a single material to registerMaterials, use registerMaterial instead or pass a list of materials")
    end
    logger:debug("Registering materials")
    for _, data in ipairs(materialList) do
        logger:debug("Material: %s", data.id)
        for _, id in ipairs(data.ids) do
            logger:debug("  - %s", id)
        end
        Material:new(data)
    end
end

---@param itemId string
---@return boolean isMaterial
function Material:itemIsMaterial(itemId)
    return self.ids[itemId:lower()]
end

---@return string name
function Material:getName()
    return self.name
end


--Checks if at least one ingredient in the list is valid
function Material:hasValidIngredient()
    for id, _ in pairs(self.ids) do
        local item = tes3.getObject(id)
        if item then
            return true
        end
    end
    return false
end


--Removes the required number of ingredients from the player
-- or any nearby containers
---@return table<string, number> itemsUsed - A table of item ids and the number of items used
function Material:use(count)
    local itemsUsed = {}
    local remaining = count
    for id, _ in pairs(self.ids) do
        local item = tes3.getObject(id)
        if item then
            local storedMaterials = MaterialStorage.getNearbyMaterials{
                maxDistance = 1000,
                searchAllContainers = false,
            }
            for _, storedMaterial in ipairs(storedMaterials) do
                local num = storedMaterial.storageInstance:removeItem{
                    reference = storedMaterial.storedIn,
                    item = item,
                    count = remaining
                }
                if num > 0 then
                    logger:debug("Removed %s %s from %s", num, item.name, storedMaterial.storedIn.object.name)
                    remaining = remaining - num
                    itemsUsed[item.id] = (itemsUsed[item.id] or 0) + num
                end
            end
            if remaining > 0 then
                local num = tes3.removeItem{ reference = tes3.player, item = item, count = remaining }
                logger:debug("Removed %s %s from player", num, item.name)
                remaining = remaining - num
                itemsUsed[item.id] = (itemsUsed[item.id] or 0) + num
            end
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
    return itemsUsed
end

---Get how many items are available for each ingredient
function Material:getItemCount(id)
    id = id:lower()
    logger:assert(self.ids[id], "Material %s does not contain %s", self.id, id)
    local item = tes3.getObject(id)
    if item then
        local count = tes3.getItemCount{ reference = tes3.player, item = item }
        local storedMaterials = MaterialStorage.getNearbyMaterials{
            maxDistance = 1000,
            searchAllContainers = false,
        }
        for _, storedMaterial in ipairs(storedMaterials) do
            if storedMaterial.item.id:lower() == id then
                count = count + storedMaterial.count
            end
        end
        return count
    end
    return 0
end

---@param numRequired number
---@return boolean hasEnough
function Material:checkHasIngredient(numRequired)
    local count = 0
    for id, _ in pairs(self.ids) do
        count = count + self:getItemCount(id)
    end
    return count >= numRequired
end
return Material