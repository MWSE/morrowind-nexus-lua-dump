local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("Recipe")
local Material = require("CraftingFramework.components.Material")
local Craftable = require("CraftingFramework.components.Craftable")
local SkillRequirement = require("CraftingFramework.components.SkillRequirement")
local CustomRequirement = require("CraftingFramework.components.CustomRequirement")
local ToolRequirement = require("CraftingFramework.components.ToolRequirement")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")
local config = require("CraftingFramework.config")

---@alias craftingFrameworkRotationAxis
---| '"x"'
---| '"y"'
---| '"z"'
---| '"-x"'
---| '"-y"'
---| '"-z"'

---@class CraftingFramework.MaterialRequirement
---@field material string **Required.** The id of either a Crafting Framework Material, or an object id. Using an object id will register it as its own Material where the object itself is the only item in the list.
---@field count number *Default*: `1`. The required amount of the material.


---@class CraftingFramework.Recipe.containerConfig : CarryableContainer.containerConfig
---@field itemId? string This is provided by the recipe and should not be set manually

---@class CraftingFramework.Recipe.data
---@field id string **Required** This is the unique identifier used to identify this `recipe`. This id is used when fetching an existing Recipe from the `Recipe` API.
---@field craftableId nil|string **Required.** The id of the object crafted by this recipe
---@field description nil|string **Required.** The description of the recipe, displayed in the crafting menu.
---@field persist nil|boolean *Default*: `true`. If `false`, the recipe will not be saved to the global recipe list and can't be accessed with Recipe.getRecipe.
---@field noResult nil|boolean *Defualt*: `false`. If `true`, no object or item will actually be crafted. Instead, use craftCallback to implement a custom result.
---@field craftable nil|CraftingFramework.Craftable.data
---@field materials nil|CraftingFramework.MaterialRequirement[] A table with the materials required by this recipe.
---@field timeTaken nil|number The time taken to craft the associated object. Currently, doesn't serve a purpose within Crafting Framework, but it can be used to implement custom mechanics.
---@field knownByDefault nil|boolean *Default*: `true`. Controls whether the player knows this recipe from the game start.
---@field knowledgeRequirement nil|fun(self: CraftingFramework.Recipe): boolean A callback which determines whether the player should know how to craft this recipe at the time the menu is opened. This is an alternative approach to using the knownByDefault/learn/unlearn params, and will override their functionality.
---@field skillRequirements nil|CraftingFramework.SkillRequirement.data[] A table with the skill requirements needed to craft the associated item.
---@field toolRequirements nil|CraftingFramework.ToolRequirement.data[] A table with the tool requirements needed to craft the associated item.
---@field category nil|string *Default*: `"Other"`. This is the category in which the recipe will appear in the crafting menu.
---@field name nil|string The name of the craftable displayed in the menu. If not set, it will use the name of the craftable object
---@field placedObject nil|string If the object being placed is different from the object that is picked up by the player, use `id` for the held object id and `placedObject` for the id of the object that is placed in the world
---@field containerConfig nil|CraftingFramework.Recipe.containerConfig If provided, crafted item will be registered as a carryable container.
---@field uncarryable nil|boolean Treats the crafted item as uncarryable even if the object type otherwise would be carryable. This will make the object be crafted immediately into the world and remove the Pick Up button from the menu. Not required if the crafted object is already uncarryable, such as a static or activator
---@field additionalMenuOptions nil|craftingFrameworkMenuButtonData[] A list of additional menu options that will be displayed in the craftable menu
---@field soundId nil|string Provide a sound ID (for a sound registered in the CS) that will be played when the craftable is crafted
---@field soundPath nil|string Provide a custom sound path that will be played when an craftable is crafted
---@field soundType nil|CraftingFramework.Craftable.SoundType Determines the crafting sound used, using sounds from the framework or added by interop. These include: "fabric", "wood", "leather", "rope", "straw", "metal" and "carve."
---@field materialRecovery nil|number The percentage of materials used to craft the item that will be recovered. Overrides the default amount set in the Crafting Framework MCM
---@field maxSteepness nil|number The max angle a crafted object will be oriented to while repositioning
---@field resultAmount nil|number The amount of the item to be crafted
---@field scale nil|number *Default*: `1.0`. The scale the item will be set to when placed.
---@field recoverEquipmentMaterials nil|boolean When set to true, and the craftable is an armor or weapon item, equipping it when it has 0 condition will destroy it and salvage its materials
---@field activateCallback nil|fun(self : CraftingFramework.Craftable, e: CraftingFramework.Craftable.callback.params): boolean Optional function that is called when the object is activated. To revert to default behaviour, return false from this function.
---@field destroyCallback nil|fun(self : CraftingFramework.Craftable, e: CraftingFramework.Craftable.callback.params) Called when the object is destroyed
---@field placeCallback nil|fun(self : CraftingFramework.Craftable, e: CraftingFramework.Craftable.callback.params) Called when the object is placed
---@field positionCallback nil|fun(self : CraftingFramework.Craftable, e: CraftingFramework.Craftable.callback.params) Called when the object is positioned
---@field craftCallback nil|fun(self: CraftingFramework.Craftable, e: CraftingFramework.Craftable.craftCallback.params) Called when the object is crafted
---@field quickActivateCallback nil|fun(self: CraftingFramework.Craftable, e: CraftingFramework.Craftable.callback.params) Called when the object is shift-activated
---@field successMessageCallback nil|fun(self: CraftingFramework.Craftable, e: CraftingFramework.Craftable.SuccessMessageCallback.params): string #A function that returns a string to be displayed when the craftable is crafted. If not set, the default message will be used.
---@field previewMesh nil|string This is the mesh override for the preview pane in the crafting menu. If no mesh is present, the 3D model of the associated item will be used.
---@field previewImage nil|string The path to the image that will be displayed in the preview pane in the crafting menu. If no image is present, the 3D model of the associated item will be used.
---@field rotationAxis nil|craftingFrameworkRotationAxis **Default "z"** Determines about which axis the preview mesh will rotate around. Defaults to the z axis.
---@field previewScale nil|number **Default 1** Determines the scale of the preview mesh.
---@field previewHeight nil|number **Default 1** Determines the height of the mesh in the preview window.
---@field additionalUI nil|fun(self: CraftingFramework.Indicator, parent: tes3uiElement) A function that adds additional UI elements to the tooltip.
---@field craftedOnly nil|boolean **Default true** If true, the object must be crafted in order have the functionality and tooltips registered by the recipe. If false, any object of this type will have the position menu and tooltips etc applied. You should only set this to false for objects that are unique to your mod.
---@field keepMenuOpen nil|boolean **Default false** If true, the menu will not close after the object is crafted. This is useful for objects that have additional options in the menu.
---@field placementSetting nil|CraftingFramework.Positioner.PlacementSetting **Default "default"** Determines the placement setting used by the positioner. This can be used to override the default placement setting for a specific recipe.
---@field blockPlacementSettingToggle nil|boolean **Default false** If true, the placement setting toggle will be disabled for this recipe. This is useful for recipes that have a specific placement setting.
---@field pinToWall nil|boolean **Default false** If true, the object will be pinned to the wall when placed. This is useful for objects that are intended to be placed on walls.
---@field floats nil|boolean **Default false** If true, the object will float when placed. This is useful for objects that are intended to be placed in water.
---@field floatOffset nil|number **Default 0** The offset from the water level that the object will float at. This is useful for objects that are intended to float at a specific height in water.

local MaterialRequirementSchema = {
    name = "MaterialRequirement",
    fields = {
        material = { type = "string", required = true },
        count = { type = "number", required = false, default = 1 }
    }
}

---@class CraftingFramework.Recipe : CraftingFramework.Recipe.data
---@field craftable CraftingFramework.Craftable
---@field private craftableId string deprecated
---@field customRequirements CraftingFramework.CustomRequirement[]
---@field skillRequirements CraftingFramework.SkillRequirement[]
---@field toolRequirements CraftingFramework.ToolRequirement[]
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
---@return CraftingFramework.Recipe recipe
function Recipe.getRecipe(id)
    return Recipe.registeredRecipes[id:lower()]
end

---@param data CraftingFramework.Recipe.data
---@return CraftingFramework.Recipe recipe
function Recipe:new(data)
    ---@type CraftingFramework.Recipe
    Util.validate(data, Recipe.schema)
    local recipe = table.copy(data) --[[@as CraftingFramework.Recipe]]
    --Flatten the API so craftable is just part of the recipe
    local craftableFields = Craftable.schema.fields

    ---@cast data CraftingFramework.Recipe
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
    log:assert(recipe.id ~= nil, "Validation Error: No id or craftable provided for Recipe")
    recipe.id = recipe.id:lower()

    --Register as carryable container
    if recipe.containerConfig then
        ---@type CarryableContainer.containerConfig
        local carryableContainerConfig = table.copy(recipe.containerConfig)
        carryableContainerConfig.itemId = recipe.craftable.id
        carryableContainerConfig.scale = recipe.containerConfig.scale or recipe.scale
        CarryableContainer.register(carryableContainerConfig)
    end

    recipe.category = recipe.category or "Другое"
    recipe.toolRequirements = Util.convertListTypes(data.toolRequirements, ToolRequirement) or {}
    recipe.skillRequirements = Util.convertListTypes(data.skillRequirements, SkillRequirement) or {}
    recipe.customRequirements = Util.convertListTypes(data.customRequirements, CustomRequirement) or {}

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
    if self.knowledgeRequirement then
        return self:knowledgeRequirement()
    end
    if self.knownByDefault then
        return true
    end
    local knownRecipe = config.persistent.knownRecipes[self.id]
    return knownRecipe
end

--[[
    Check if has a previewMesh, a previewImage,
    or a result
]]
function Recipe:hasPreview()
    return self.previewMesh ~= nil
    or self.previewImage ~= nil
    or self.noResult ~= true
end



function Recipe:craft()
    log:debug("Crafting %s", self.id)
    ---@type table<string, number>
    local materialsUsed = {}
    for _, materialReq in ipairs(self.materials) do
        local material = Material.getMaterial(materialReq.material)
        local itemsUsed = material:use(materialReq.count)
        for id, count in pairs(itemsUsed) do
            if count > 0 then
                materialsUsed[id] = (materialsUsed[id] or 0) + count
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

---@return tes3object|nil object
function Recipe:getItem()
    local id = self.craftable:getPlacedObjectId() or self.craftable.id
    if id then
        return tes3.getObject(id) --[[@as tes3object]]
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
---@return string|nil reason
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
---@return string|nil reason
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
---@return string|nil reason
function Recipe:meetsSkillRequirements()
    for _, skillRequirement in ipairs(self.skillRequirements) do
        if not skillRequirement:check() then
            return false, "Your skill is not high enough"
        end
    end
    return true
end

---@return boolean
---@return string|nil reason
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
---@return string|nil reason
function Recipe:meetsAllRequirements()
    local reqs = {
        self.meetsCustomRequirements,
        self.hasMaterials,
        self.meetsToolRequirements,
        self.meetsSkillRequirements
    }
    for _, req in ipairs(reqs) do
        local meetsRequirements, reason = req(self)
        if not meetsRequirements then
            return false, reason
        end
    end
    return true
end

Recipe.__tostring = function(self)
    return string.format("Чертеж: %s", self.id)
end

return Recipe