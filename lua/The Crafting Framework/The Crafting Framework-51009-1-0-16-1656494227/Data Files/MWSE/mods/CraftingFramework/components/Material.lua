local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Material")
---@class craftingFrameworkMaterial
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
---@param id string
---@return craftingFrameworkMaterial material
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

---@param data craftingFrameworkMaterialData
---@return craftingFrameworkMaterial material
function Material:new(data)
    Util.validate(data, Material.schema)
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
        material.ids[id:lower()] = true
    end
    setmetatable(material, self)
    self.__index = self
    return material
end

---@param materialList craftingFrameworkMaterialData[]
function Material:registerMaterials(materialList)
    for _, data in ipairs(materialList) do
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

---@param numRequired number
---@return boolean hasEnough
function Material:checkHasIngredient(numRequired)
    local count = 0
    for id, _ in pairs(self.ids) do
        local item = tes3.getObject(id)
        if item then
            count = count + tes3.getItemCount{ reference = tes3.player, item = item }
        end
    end
    return count >= numRequired
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

return Material