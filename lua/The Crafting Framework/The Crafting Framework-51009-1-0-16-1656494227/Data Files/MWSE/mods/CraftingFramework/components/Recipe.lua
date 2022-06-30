local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("Recipe")
local Material = require("CraftingFramework.components.Material")
local Craftable = require("CraftingFramework.components.Craftable")
local SkillRequirement = require("CraftingFramework.components.SkillRequirement")
local CustomRequirement = require("CraftingFramework.components.CustomRequirement")
local ToolRequirement = require("CraftingFramework.components.ToolRequirement")
local config = require("CraftingFramework.config")

local MaterialRequirementSchema = {
    name = "MaterialRequirement",
    fields = {
        material = { type = "string", required = true },
        count = { type = "number", required = false, default = 1 }
    }
}


---@class craftingFrameworkRecipe
local Recipe = {
    schema = {
        name = "Recipe",
        fields = {
            id = { type = "string", required = false },
            craftableId = { type = "string", required = false },
            description = { type = "string", required = false },
            craftable = { type = Craftable.schema, required = false },
            materials = { type = "table", childType = MaterialRequirementSchema, required = false, default = {} },
            timeTaken = { type = "number", required = false },
            knownByDefault = { type = "boolean", required = false, default = true },
            customRequirements = { type = "table", childType = CustomRequirement.schema, required = false },
            skillRequirements = { type = "table", childType = SkillRequirement.schema, required = false },
            toolRequirements = { type = "table", childType = ToolRequirement.schema, required = false },
            category = { type = "string", required = false },
            persist = { type = "boolean", required = false, default = true },
        }
    }
}

Recipe.registeredRecipes = {}
---@param id string
---@return craftingFrameworkRecipe recipe
function Recipe.getRecipe(id)
    return Recipe.registeredRecipes[id:lower()]
end

---@param data craftingFrameworkRecipeData
---@return craftingFrameworkRecipe recipe
function Recipe:new(data)
    ---@type craftingFrameworkRecipe
    local recipe = table.copy(data, {})
    Util.validate(recipe, Recipe.schema)
    --Flatten the API so craftable is just part of the recipe
    local craftableFields = Craftable.schema.fields
    recipe.craftable = data.craftable or {}
    for field, _ in pairs(craftableFields) do
        if not recipe.craftable[field] then
            recipe.craftable[field] = data[field]
        end
    end
    if recipe.craftableId then
        recipe.craftable.id = recipe.craftableId
        recipe.craftableId = nil
    end

    --Set ID and make sure it's lower case
    recipe.id = data.id or recipe.craftable.id
    recipe.id = recipe.id:lower()

    recipe.category = recipe.category or "Other"
    recipe.toolRequirements = Util.convertListTypes(data.toolRequirements, ToolRequirement) or {}
    recipe.skillRequirements = Util.convertListTypes(data.skillRequirements, SkillRequirement) or {}
    recipe.customRequirements = Util.convertListTypes(data.customRequirements, CustomRequirement) or {}
    assert(recipe.id, "Validation Error: No id or craftable provided for Recipe")
    recipe.craftable = Craftable:new(recipe.craftable)
    setmetatable(recipe, self)
    self.__index = self
    if recipe.persist ~= false then
        Recipe.registeredRecipes[recipe.id] = recipe
    end
    return recipe
end


function Recipe:learn()
    config.persistent.knownRecipes[self.id] = true
end

function Recipe:unlearn()
    self.knownByDefault = false
    config.persistent.knownRecipes[self.id] = nil
end

function Recipe:isKnown()
    if self.knownByDefault then
        return true
    end
    local knownRecipe = config.persistent.knownRecipes[self.id]
    return knownRecipe
end

function Recipe:craft()
    log:debug("Crafting %s", self.id)
    local materialsUsed = {}
    for _, materialReq in ipairs(self.materials) do
        local material = Material.getMaterial(materialReq.material)
        local remaining = materialReq.count
        for id, _ in pairs(material.ids) do
            materialsUsed[id] = materialsUsed[id] or 0
            local item = tes3.getObject(id)
            if item then
                local inInventory = tes3.getItemCount{ reference = tes3.player, item = id}
                local numToRemove = math.min(inInventory, remaining)
                materialsUsed[id] = materialsUsed[id] + numToRemove
                tes3.removeItem{ reference = tes3.player, item = id, playSound = false, count = numToRemove}
                remaining = remaining - numToRemove
                if remaining == 0 then break end
            end
        end
    end
    for _, toolReq in ipairs(self.toolRequirements) do
        if toolReq.tool and toolReq.conditionPerUse then
            log:debug("Has conditionPerUse, using tool")
            toolReq.tool:use(toolReq.conditionPerUse)
        end
    end

    self.craftable:craft(materialsUsed)
    --progress skills
    for _, skillRequirement in ipairs(self.skillRequirements) do
        skillRequirement:progressSkill()
    end
end

---@return tes3object|tes3weapon|tes3armor|tes3misc|tes3light object
function Recipe:getItem()
    local id = self.craftable:getPlacedObjectId() or self.craftable.id
    if id then
        return tes3.getObject(id)
    end
end

---@return number
function Recipe:getAverageSkillLevel()
    local total = 0
    local count = 0
    for _, skillRequirement in ipairs(self.skillRequirements) do
        total = total + skillRequirement.requirement
        count = count + 1
    end
    if count == 0 then return 0 end
    return total / count
end

---@return boolean
---@return string reason
function Recipe:hasMaterials()
    for _, materialReq in ipairs(self.materials) do
        local material = Material.getMaterial(materialReq.material)
        if not material then
            log:error("Can not craft %s, required material '%s' has not been registered", self.id, materialReq.material)
            return false, "You do not have the required materials"
        end
        --Material requirements only count if at lease one of the ingredients registered to that
        --  material exists in the game
        if material:hasValidIngredient() then
            local numRequired = materialReq.count
            if not material:checkHasIngredient(numRequired) then
                return false, "You do not have the required materials"
            end
        end
    end
    return true
end

---@return boolean
---@return string reason
function Recipe:meetsToolRequirements()
    for _, toolRequirement in ipairs(self.toolRequirements) do
        local tool = toolRequirement.tool
        if not tool then
            log:error("For recipe %s, required tool has not been registered", self.id)
            return true
        end
        log:debug("Checking tool requirements met")
        if not toolRequirement:hasTool() then
            return false, "You do not have the required tools"
        end
    end

    return true
end

---@return boolean
---@return string reason
function Recipe:meetsSkillRequirements()
    for _, skillRequirement in ipairs(self.skillRequirements) do
        if not skillRequirement:check() then
            return false, "Your skill is not high enough"
        end
    end
    return true
end

---@return boolean
---@return string reason
function Recipe:meetsCustomRequirements()
    if self.customRequirements then
        for _, requirement in ipairs(self.customRequirements) do
            local meetsRequirements, reason = requirement:check()
            if not meetsRequirements then
                return false, reason
            end
        end
    end
    return true
end

---@return boolean
---@return string reason
function Recipe:meetsAllRequirements()
    local meetsCustomRequirements, reason = self:meetsCustomRequirements()
    if not meetsCustomRequirements then return false, reason end
    local hasMaterials, reason = self:hasMaterials()
    if not hasMaterials then return false, reason end
    local meetsToolRequirements, reason = self:meetsToolRequirements()
    if not meetsToolRequirements then return false, reason end
    local meetsSkillRequirements, reason = self:meetsSkillRequirements()
    if not meetsSkillRequirements then return false, reason end
    return true
end

Recipe.__tostring = function(self)
    return string.format("Recipe: %s", self.id)
end

return Recipe