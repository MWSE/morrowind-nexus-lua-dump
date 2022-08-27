---@meta

---@alias craftingFrameworkMenuActivatorType
---| '"activate"' # These Stations are objects in the game world, and their Crafting Menu is opened when they are activated.
---| '"equip"' # These Stations are used by equipping them. Suitable for carriable Crafting Stations.
---| '"event"' # These Stations are used when a certain event is triggered. Typically used with custom events triggered by your mod.


---@alias craftingFrameworkMenuActivatorDefaultFilter
---| '"all"' # This filter will make all the recipes that can possibly be crafted on this Crafting Station appear in the Crafting Menu.
---| '"canCraft"' # This filter will make only the recipes that the player can currently craft appear in the Crafting Menu.
---| '"materials"' # This filter will make only the recipes that the player has enough materials for, and has the required tools, appear in the Crafting Menu.
---| '"skill"' # This filter will make only the recipes that the player's skills allow crafting appear in the Crafting Menu.


---@alias craftingFrameworkMenuActivatorDefaultSort
---| '"name"' # This will sort the recipe list in the Crafting Menu by name of the craftable item alphabetically.
---| '"skill"' # This will sort the recipe list in the Crafting Menu by the average skill level required to craft the recipe (ascending).
---| '"canCraft"' # This will sort the recipe list in the Crafting Menu by putting the recipes the player can craft at the top.

---@class MenuActivatorRegisteredEvent
---@field menuActivator craftingFrameworkMenuActivator The MenuActivator that was just registered

---@class craftingFrameworkMenuActivatorData
---@field id string **Required** Usually, this is the in-game id of the object used as this Crafting Station. If your `menuActivator.type == 'event'`, then the `id` needs to be the id of the event on which this Crafting Station's crafting menu will be opened. Typically a custom event triggered by your mod.
---@field name string The name appears on the Crafting Menu when this Crafting Station is used. If no name is given for activator Crafting Stations, the in-game name of the associated object will be used.
---@field type craftingFrameworkMenuActivatorType **Required** The type controls how the Crafting Station can be interacted with.
---@field recipes craftingFrameworkRecipeData[] A list of recipes that will appear (if known) when the menu is activated.
---@field defaultFilter craftingFrameworkMenuActivatorDefaultFilter *Default*: `"all"`. The filter controls which recipes will appear in the Crafting Menu.
---@field defaultSort craftingFrameworkMenuActivatorDefaultSort *Default*: `"name"`. This controls how the recipe list in the Crafting Menu is sorted.
---@field defaultShowCategories boolean *Default*: `true`. This controls whether by default the recipes will be grouped in categories or not.
---@field blockEvent boolean *Default*: `true`. This controls whether the event callback will be blocked or not (the event being "activate" or "equip" for those MenuActivator types, or the custom event for the "event" MenuActivator type).
---@field closeCallback function *Default*: `nil`. This callback is called when the menu is closed.
---@field collapseByDefault boolean *Default*: `false`. This controls whether the categories will be collapsed by default or not.
---@field craftButtonText string *Default*: `"Craft"`. This controls the text of the craft button.
---@field recipeHeaderText string *Default*: `"Recipes"`. This controls the text of the header of the recipe list.
---@field menuWidth number *Default*: `720`. This controls the width of the crafting menu.
---@field menuHeight number *Default*: `800`. This controls the height of the crafting menu.
---@field previewHeight number *Default*: `270`. This controls the height of the preview area.
---@field previewWidth number *Default*: `270`. This controls the width of the preview area.
---@field previewYOffset number *Default*: `-200`. This controls the y-offset of the preview area.
---@field showCollapseCategoriesButton boolean *Default*: `true`. This controls whether the collapse categories button will be shown or not.
---@field showCategoriesButton boolean *Default*: `true`. This controls whether the categories button will be shown or not.
---@field showFilterButton boolean *Default*: `true`. This controls whether the filter button will be shown or not.
---@field showSortButton boolean *Default*: `true`. This controls whether the sort button will be shown or not.

---@class craftingFrameworkMenuActivator This object is usually used to represent a Crafting Station. It can be a carriable or a static Station.
---@field id string Usually, this is the in-game id of the object used as this Crafting Station. If your `menuActivator.type == "event"`, then the `id` needs to be the id of the event on which this Crafting Station's crafting menu will be opened. Typically a custom event triggered by your mod.
---@field name string The name appears on the Crafting Menu when this Crafting Station is used.
---@field type craftingFrameworkMenuActivatorType The type controls how the Crafting Station can be interacted with.
---@field recipes craftingFrameworkRecipe[] A list of recipes that will appear (if known) when the menu is activated.
---@field defaultFilter craftingFrameworkMenuActivatorDefaultFilter The filter controls which recipes will appear in the Crafting Menu.
---@field defaultSort craftingFrameworkMenuActivatorDefaultSort This controls how the recipe list in the Crafting Menu is sorted.
---@field defaultShowCategories boolean This controls whether by default the recipes will be grouped in categories or not.
---@field blockEvent boolean *Default*: `true`. This controls whether the event callback will be blocked or not (the event being "activate" or "equip" for those MenuActivator types, or the custom event for the "event" MenuActivator type).
---@field registeredMenuActivators table<string, craftingFrameworkMenuActivator>
---@field closeCallback function *Default*: `nil`. This callback is called when the menu is closed.
---@field collapseByDefault boolean *Default*: `false`. This controls whether the categories will be collapsed by default or not.
---@field craftButtonText string *Default*: `"Craft"`. This controls the text of the craft button.
---@field recipeHeaderText string *Default*: `"Recipes"`. This controls the text of the header of the recipe list.
---@field menuWidth number *Default*: `720`. This controls the width of the crafting menu.
---@field menuHeight number *Default*: `800`. This controls the height of the crafting menu.
---@field previewHeight number *Default*: `270`. This controls the height of the preview area.
---@field previewWidth number *Default*: `270`. This controls the width of the preview area.
---@field previewYOffset number *Default*: `-200`. This controls the y-offset of the preview area.
---@field showCollapseCategoriesButton boolean *Default*: `true`. This controls whether the collapse categories button will be shown or not.
---@field showCategoriesButton boolean *Default*: `true`. This controls whether the categories button will be shown or not.
---@field showFilterButton boolean *Default*: `true`. This controls whether the filter button will be shown or not.
---@field showSortButton boolean *Default*: `true`. This controls whether the sort button will be shown or not.
craftingFrameworkMenuActivator = {}

---This method is used to create a new Crafting Station.
---@param data craftingFrameworkMenuActivatorData This table accepts following values:
---
--- `id`: string —  **Required** Usually, this is the in-game id of the object used as this Crafting Station. If your `menuActivator.type == 'event'`, then the `id` needs to be the id of the event on which this Crafting Station's crafting menu will be opened. Typically a custom event triggered by your mod.
---
--- `name`: string —  The name appears on the Crafting Menu when this Crafting Station is used. If no name is given for activator Crafting Stations, the in-game name of the associated object will be used.
---
--- `type`: "activate"|"equip"|"event" —  **Required** The type controls how the Crafting Station can be interacted with.
---
--- `recipes`: craftingFrameworkRecipeData[] —  A list of recipes that will appear (if known) when the menu is activated.
---
--- `defaultFilter`: `"all"|"canCraft"|"materials"|"skill"` — *Default*: `"all"`. The filter controls which recipes will appear in the Crafting Menu.
---
--- `defaultSort`: `"name"|"skill"|"canCraft"` — *Default*: `"name"`. This controls how the recipe list in the Crafting Menu is sorted.
---
--- `defaultShowCategories`: boolean — *Default*: `true`. This controls whether by default the recipes will be grouped in categories or not.
---
--- `blockEvent`: boolean — *Default*: `true`. This controls whether the event callback will be blocked or not (the event being "activate" or "equip" for those MenuActivator types, or the custom event for the "event" MenuActivator type).
---@return craftingFrameworkMenuActivator menuActivator The newly constructed Crafting Station object.
function craftingFrameworkMenuActivator:new(data) end

---This method will register the `self:openMenu()` method to the appropriate event. This is used during initialization for each `menuActivator` within Crafting Framework.
function craftingFrameworkMenuActivator:registerEvents() end

---Calling this method will open the Crafting Menu for this `menuActivator` if the player knows at least one recipe that can be crafted on this Crafting Station.
function craftingFrameworkMenuActivator:openMenu() end

---This method creates new `craftingFrameworkRecipe` objects from provided list of `craftingFrameworkRecipeData` and adds it to this `menuActivator`. Provided list of `recipe`s will be available for crafting on this Crafting Station.
---@param recipes craftingFrameworkRecipeData[]
function craftingFrameworkMenuActivator:registerRecipes(recipes) end

---This method creates a new `craftingFrameworkRecipe` object from provided `data` and adds it to this `menuActivator`. This will make the `recipe` available for crafting on this Crafting Station.
---@param data craftingFrameworkRecipeData
function craftingFrameworkMenuActivator:registerRecipe(data) end

---Adds a list of `recipe` objects to this `menuActivator`. Provided list of `recipe`s will be available for crafting on this Crafting Station.
---@param recipes craftingFrameworkRecipe[]
function craftingFrameworkMenuActivator:addRecipes(recipes) end

---Adds a `recipe` object to this `menuActivator`. This will make the `recipe` available for crafting on this Crafting Station.
---@param recipe craftingFrameworkRecipe
function craftingFrameworkMenuActivator:addRecipe(recipe) end
