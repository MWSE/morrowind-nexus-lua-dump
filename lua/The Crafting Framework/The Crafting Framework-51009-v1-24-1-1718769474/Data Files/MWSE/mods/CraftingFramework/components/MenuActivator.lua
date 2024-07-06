local CraftingMenu = require("CraftingFramework.components.CraftingMenu")
local Recipe = require("CraftingFramework.components.Recipe")
local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("MenuActivator")


---@alias CraftingFramework.MenuActivator.Type
---| '"activate"' # These Stations are objects in the game world, and their Crafting Menu is opened when they are activated.
---| '"equip"' # These Stations are used by equipping them. Suitable for carriable Crafting Stations.
---| '"event"' # These Stations are used when a certain event is triggered. Typically used with custom events triggered by your mod.

---@alias CraftingFramework.MenuActivator.Filter
---| '"all"' # This filter will make all the recipes that can possibly be crafted on this Crafting Station appear in the Crafting Menu.
---| '"canCraft"' # This filter will make only the recipes that the player can currently craft appear in the Crafting Menu.
---| '"materials"' # This filter will make only the recipes that the player has enough materials for, and has the required tools, appear in the Crafting Menu.
---| '"skill"' # This filter will make only the recipes that the player's skills allow crafting appear in the Crafting Menu.


---@alias CraftingFramework.MenuActivator.Sorter
---| '"name"' # This will sort the recipe list in the Crafting Menu by name of the craftable item alphabetically.
---| '"skill"' # This will sort the recipe list in the Crafting Menu by the average skill level required to craft the recipe (ascending).
---| '"canCraft"' # This will sort the recipe list in the Crafting Menu by putting the recipes the player can craft at the top.

---@class CraftingFramework.MenuActivator.RegisteredEvent
---@field menuActivator CraftingFramework.MenuActivator The MenuActivator that was just registered

---@class CraftingFramework.MenuActivator.data
---@field id string **Required** Usually, this is the in-game id of the object used as this Crafting Station. If your `menuActivator.type == 'event'`, then the `id` needs to be the id of the event on which this Crafting Station's crafting menu will be opened. Typically a custom event triggered by your mod.
---@field name string The name appears on the Crafting Menu when this Crafting Station is used. If no name is given for activator Crafting Stations, the in-game name of the associated object will be used.
---@field type CraftingFramework.MenuActivator.Type **Required** The type controls how the Crafting Station can be interacted with.
---@field recipes CraftingFramework.Recipe.data[] A list of recipes that will appear (if known) when the menu is activated.
---@field defaultFilter? CraftingFramework.MenuActivator.Filter *Default*: `"all"`. The filter controls which recipes will appear in the Crafting Menu.
---@field defaultSort? CraftingFramework.MenuActivator.Sorter *Default*: `"name"`. This controls how the recipe list in the Crafting Menu is sorted.
---@field defaultShowCategories? boolean *Default*: `true`. This controls whether by default the recipes will be grouped in categories or not.
---@field blockEvent? boolean *Default*: `true`. This controls whether the event callback will be blocked or not (the event being "activate" or "equip" for those MenuActivator types, or the custom event for the "event" MenuActivator type).
---@field closeCallback? fun(self: CraftingFramework.CraftingMenu) *Default*: `nil`. This callback is called when the menu is closed.
---@field collapseByDefault? boolean *Default*: `false`. This controls whether the categories will be collapsed by default or not.
---@field craftButtonText? string *Default*: `"Craft"`. This controls the text of the craft button.
---@field recipeHeaderText? string *Default*: `"Recipes"`. This controls the text of the header of the recipe list.
---@field skillsHeaderText? string *Default*: `"Skills"`. This controls the text of the header of the skills list.
---@field customRequirementsHeaderText? string *Default*: `"Requirements"`. This controls the text of the header of the custom requirements list.
---@field toolsHeaderText? string *Default*: `"Tools"`. This controls the text of the header of the tools list.
---@field materialsHeaderText? string *Default*: `"Materials"`. This controls the text of the header of the materials list.
---@field menuWidth? number *Default*: `720`. This controls the width of the crafting menu.
---@field menuHeight? number *Default*: `800`. This controls the height of the crafting menu.
---@field previewHeight? number *Default*: `270`. This controls the height of the preview area.
---@field previewWidth? number *Default*: `270`. This controls the width of the preview area.
---@field previewYOffset? number *Default*: `-200`. This controls the y-offset of the preview area.
---@field showCollapseCategoriesButton? boolean *Default*: `true`. This controls whether the collapse categories button will be shown or not.
---@field showCategoriesButton? boolean *Default*: `true`. This controls whether the categories button will be shown or not.
---@field showFilterButton? boolean *Default*: `true`. This controls whether the filter button will be shown or not.
---@field showSortButton? boolean *Default*: `true`. This controls whether the sort button will be shown or not.

---@class CraftingFramework.MenuActivator : CraftingFramework.MenuActivator.data This object is usually used to represent a Crafting Station. It can be a carriable or a static Station.
---@field recipes CraftingFramework.Recipe[] A list of recipes that will appear (if known) when the menu is activated.
---@field registeredMenuActivators table<string, CraftingFramework.MenuActivator> A list of all the MenuActivators that have been registered.
local MenuActivator = {
    schema = {
        name = "MenuActivator",
        fields = {
            id = { type = "string", required = true },
            name = { type = "string", required = false },
            type = { type = "string", values = {"activate", "equip", "event" }, required = true },
            recipes = { type = "table", childType = Recipe.schema, required = false },
            defaultFilter = { type = "string", values = {"all", "canCraft", "materials", "skill"}, default = "all", required = false },
            defaultSort = { type = "string", values = {"name", "skill", "canCraft"}, default = "name", required = false },
            defaultShowCategories = { type = "boolean", default = true, required = false },
            blockEvent = { type = "boolean", default = true, required = false },
            closeCallback = { type = "function", required = false },
            collapseByDefault = { type = "boolean", default = false, required = false },
            craftButtonText = { type = "string", default = "Craft", required = false },
            recipeHeaderText = { type = "string", default = "Recipes", required = false },
            skillsHeaderText = { type = "string", default = "Skills", required = false },
            customRequirementsHeaderText = { type = "string", default = "Requirements", required = false },
            toolsHeaderText = { type = "string", default = "Tools", required = false },
            materialsHeaderText = { type = "string", default = "Materials", required = false },
            menuWidth = { type = "number", default = 720, required = false },
            menuHeight = { type = "number", default = 800, required = false },
            previewHeight = { type = "number", default = 270, required = false },
            previewWidth = { type = "number", default = 270, required = false },
            previewYOffset = { type = "number", default = -200, required = false },
            showCollapseCategoriesButton = { type = "boolean", default = true, required = false },
            showCategoriesButton = { type = "boolean", default = true, required = false },
            showFilterButton = { type = "boolean", default = true, required = false },
            showSortButton = { type = "boolean", default = true, required = false },
        }
    },
    registeredMenuActivators = {}
}

function MenuActivator.get(id)
    return MenuActivator.registeredMenuActivators[id]
end

---@param data CraftingFramework.MenuActivator.data
---@return CraftingFramework.MenuActivator menuActivator
function MenuActivator:new(data)
    Util.validate(data, MenuActivator.schema)
    data = table.copy(data)
    data.equipStationIds = data.equipStationIds or {}
    data.activateStationIds = data.activateStationIds or {}
    data.triggers = data.triggers or {}
    setmetatable(data, self)
    self.__index = self

    -- For activators, set name to object name if not already set
    if (data.type ~= "event") and (not data.name) then
        local obj = tes3.getObject(data.id)
        if obj then
            data.name = obj.name
        end
    end
    if not data.name then
        log:error("MenuActivator:new - no name specified for menu activator %s", data.id)
    end
    --Convert to objects
    data.recipes = Util.convertListTypes(data.recipes, Recipe) or {}

    ---@cast data CraftingFramework.MenuActivator

    --Merge with existing or register new Menu Activator
    ---@type CraftingFramework.MenuActivator
    local menuActivator = MenuActivator.registeredMenuActivators[data.id]
    if not menuActivator then
        MenuActivator.registeredMenuActivators[data.id] = data
        menuActivator = data
        menuActivator:registerEvents()

        local eventId = menuActivator.id .. ":Registered"
        log:info("Registered MenuActivator: " .. menuActivator.id)
        ---@type CraftingFramework.MenuActivator.RegisteredEvent
        local eventData = {
            menuActivator = menuActivator
        }
        event.trigger(eventId, eventData)
    else
        for _, recipe in pairs(data.recipes) do
            if not table.find(menuActivator.recipes, recipe) then
                table.insert(menuActivator.recipes, recipe)
            end
        end
    end
    return menuActivator
end

function MenuActivator:registerEvents()
    if self.type == "activate" then
        event.register("activate", function(e)
            if e.target.baseObject.id:lower() == self.id:lower() then
                if not tes3.mobilePlayer.controlsDisabled then
                    self:openMenu()
                end
                if self.blockEvent ~= false then
                    return false
                end
            end
        end)
    elseif self.type == "equip" then
        event.register("equip", function(e)
            if e.item.id:lower() == self.id:lower() then
                self:openMenu()
                if self.blockEvent ~= false then
                    return false
                end
                return false
            end
        end)
    elseif self.type == "event" then
        event.register(self.id, function()
            self:openMenu()
            if self.blockEvent ~= false then
                return false
            end
        end)
    end
end


function MenuActivator:openMenu()
    log:debug("MenuActivator:openMenu()")
    local knowsRecipe = false
    for _, recipe in pairs(self.recipes) do
        if recipe:isKnown() then
            log:debug("knows %s, so menu can open", recipe.id)
            knowsRecipe = true
            break
        end
    end
    if knowsRecipe then
        local menu = CraftingMenu:new(self)
        menu:openCraftingMenu()
    else
        tes3.messageBox("You don't know any recipes")
    end
end

-- Adds a list of recipes to the menu activator from recipe schemas
---@param recipes CraftingFramework.Recipe.data[]
function MenuActivator:registerRecipes(recipes)
    log:debug("MenuActivator:registerRecipes")
    local recipes = Util.convertListTypes(recipes, Recipe)
    if recipes == nil then
        log:error("MenuActivator:registerRecipes - recipes is nil")
        return
    end
    for _, recipe in ipairs(recipes) do
        log:debug("Recipe: %s", recipe.id)
        if self:hasRecipe(recipe.id) then
            log:warn("MenuActivator:registerRecipes - recipe %s already registered", recipe.id)
        else
            log:debug("Registering Recipe %s", recipe)
            table.insert(self.recipes, recipe)
        end
    end
end

--Adds a recipe to the menu activator from recipe schema
---@param data CraftingFramework.Recipe.data
function MenuActivator:registerRecipe(data)
    self:registerRecipes({data})
end

--Adds a list of recipes to the menu activator
---@param recipes CraftingFramework.Recipe[]
function MenuActivator:addRecipes(recipes)
    for _, recipe in ipairs(recipes) do
        table.insert(self.recipes, recipe)
    end
end

--Adds an already registered recipe to the menu activator
---@param recipe CraftingFramework.Recipe
function MenuActivator:addRecipe(recipe)
    table.insert(self.recipes, recipe)
end

function MenuActivator:hasRecipe(id)
    for _, recipe in pairs(self.recipes) do
        if recipe.id:lower() == id:lower() then
            return true
        end
    end
    return false
end

return MenuActivator