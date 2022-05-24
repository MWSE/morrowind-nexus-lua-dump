---@meta

---@class craftingFrameworkInterop
interop = {}


---This function is used to create a new Crafting Station.
---@param menuActivator craftingFrameworkMenuActivatorData This table accepts following values:
---
--- `id`: string —  **Required** Usually, this is the in-game id of the object used as this Crafting Station. If your `menuActivator.type == 'event'`, then the `id` needs to be the id of the event on which this Crafting Station's crafting menu will be opened. Typically a custom event triggered by your mod.
---
--- `name`: string —  The name appears on the Crafting Menu when this Crafting Station is used. If no name is given for activator Crafting Stations, the in-game name of the associated object will be used.
---
--- `type`: `"activate"|"equip"|"event"` —  **Required** The type controls how the Crafting Station can be interacted with.
---
--- `recipes`: craftingFrameworkRecipeData[] —  A list of recipes that will appear (if known) when the menu is activated.
---
--- `defaultFilter`: `"all"|"canCraft"|"materials"|"skill"` — *Default*: `"all"`. The filter controls which recipes will appear in the Crafting Menu.
---
--- `defaultSort`: `"name"|"skill"|"canCraft"` — *Default*: `"name"`. This controls how the recipe list in the Crafting Menu is sorted.
---
--- `defaultShowCategories`: boolean — *Default*: `true`. This controls whether by default the recipes will be grouped in categories or not.
---@return craftingFrameworkMenuActivator menuActivator The newly constructed Crafting Station object.
function interop.registerMenuActivator(menuActivator) end

---This function will return the `menuActivator` object of the provided id.
---@param id string The menuActivator's unique identifier. The one used within Crafting Framework, not to be confused with game id.
---@return craftingFrameworkMenuActivator menuActivator The requested menuActivator.
function interop.getMenuActivator(id) end


---This function is used to create new recipes.
---@param data craftingFrameworkRecipeData[]
function interop.registerRecipes(data) end

---This function is used to create a new recipe.
---@param recipe craftingFrameworkRecipeData This table accepts following values:
---
--- `id`: string —  This is the unique identifier used internally by Crafting Framework to identify this `recipe`. If none is provided, the id of the associated craftable object will be used.
---
--- `description`: string —  The description of the recipe. Used in various UIs.
---
--- `craftable`: craftingFrameworkCraftableData — The object that can be crafted with this recipe.
---
--- `materials`: craftingFrameworkMaterialRequirementData[] — **Required.**  A table with the materials required by this recipe.
---
--- `timeTaken`: string — The time taken to craft the associated object. Currently, doesn't serve a purpose within Crafting Framework, but it can be used to implement custom mechanics.
---
--- `knownByDefault`: boolean — *Default*: `true`. Controls whether the player knows this recipe from the game start.
---
--- `customRequirements`: craftingFrameworkCustomRequirementData[] — A table with the custom requirements that need to be met in order to craft the associated item.
---
--- `skillRequirements`: craftingFrameworkSkillRequirementData[] — A table with the skill requirements needed to craft the associated item.
---
--- `tools`: craftingFrameworkToolRequirementData[] — A table with the tool requirements needed to craft the associated item.
---
--- `category`: string — *Default*: `"Other"`. This is the category in which the recipe will appear in the crafting menu.
---
--- `mesh`: string — This is the mesh override for the preview pane in the crafting menu. If no mesh is present, the 3D model of the associated item will be used.
---
--- `rotationAxis`: boolean — **Default "z"** Determines about which axis the preview mesh will rotate around. Adding a `-` prefix will flip the mesh 180 degrees. Valid values: "x", "y", "z", "-x", "-y", "-z".
---
--- `previewScale`: number — **Default "1"** Determines the scale of the preview mesh.
function interop.registerRecipe(recipe) end

---This function will return the `recipe` object of the provided id.
---@param id string The recipe's unique identifier. The one used within Crafting Framework, not to be confused with game id.
---@return craftingFrameworkRecipe recipe The requested recipe.
function interop.getRecipe(id) end

---This function will teach the player the provided recipe.
---@param id string The recipe's unique identifier. The one used within Crafting Framework, not to be confused with game id.
function interop.learnRecipe(id) end

---This function will remove the recipe from the player.
---@param id string The recipe's unique identifier. The one used within Crafting Framework, not to be confused with game id.
function interop.unlearnRecipe(id) end


---This function is used to create new materials.
---@param data craftingFrameworkMaterialData[]
function interop.registerMaterials(data) end

---This function is used to create a new material.
---@param data craftingFrameworkMaterialData This table accepts following values:
---
--- `id`: string — **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `material`.
---
--- `name`: string — The name of the material. Used in various UIs.
---
--- `ids`: table<number, string> — **Required.**  This is the list of item ids that are considered as identical material.
function interop.registerMaterial(data) end

---This function will return the `material` object of the provided id.
---@param id string The material's unique identifier. The one used within Crafting Framework, not to be confused with game id.
---@return craftingFrameworkMaterial material The requested material.
function interop.getMaterials(id) end


---This function is used to create new tools.
---@param data craftingFrameworkToolData[]
function interop.registerTools(data) end

---This function is used to create a new tool.
---@param data craftingFrameworkToolData This table accepts following values:
---
--- `id`: string — **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `tool`.
---
--- `name`: string — The name of the tool. Used in various UIs.
---
--- `ids`: table<number, string> — **Required.**  This is the list of item ids that are considered identical tool.
---
--- `requirement`: fun(stack : tes3itemStack): boolean —  Optionally, you can provide a function that will be used to evaluate if a certain item in the player's inventory can be used as a tool. It will be called with a `tes3itemStack` parameter, that it needs to evaluate if it should be recognized as a tool. When that is the case the function needs to return `true`, `false` otherwise. Used when no `ids` are provided.
function interop.registerTool(data) end

---This function will return the `material` object of the provided id.
---@param id string The tool's unique identifier. The one used within Crafting Framework, not to be confused with game id.
---@return craftingFrameworkTool tool The requested tool.
function interop.getTools(id) end
