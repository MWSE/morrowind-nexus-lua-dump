---@meta

---@alias craftingFrameworkRotationAxis
---| '"x"'
---| '"y"'
---| '"z"'
---| '"-x"'
---| '"-y"'
---| '"-z"'

---@class craftingFrameworkMaterialRequirementData
---@field material string **Required.** The id of either a Crafting Framework Material, or an object id. Using an object id will register it as its own Material where the object itself is the only item in the list.
---@field count number *Default*: `1`. The required amount of the material.
---@class craftingFrameworkRecipeData
---@field id string **Required** This is the unique identifier used to identify this `recipe`. This id is used when fetching an existing Recipe from the `Recipe` API.
---@field craftableId string **Required.** The id of the object crafted by this recipe
---@field description string The description of the recipe, displayed in the crafting menu.
---@field persist boolean *Default*: `true`. If `false`, the recipe will not be saved to the global recipe list and can't be accessed with Recipe.getRecipe.
---@field craftable craftingFrameworkCraftableData
---@field materials craftingFrameworkMaterialRequirementData[] **Required.** A table with the materials required by this recipe.
---@field timeTaken number The time taken to craft the associated object. Currently, doesn't serve a purpose within Crafting Framework, but it can be used to implement custom mechanics.
---@field knownByDefault boolean *Default*: `true`. Controls whether the player knows this recipe from the game start.
---@field customRequirements craftingFrameworkCustomRequirementData[] A table with the custom requirements that need to be met in order to craft the associated item.
---@field skillRequirements craftingFrameworkSkillRequirementData[] A table with the skill requirements needed to craft the associated item.
---@field toolRequirements craftingFrameworkToolRequirementData[] A table with the tool requirements needed to craft the associated item.
---@field category string *Default*: `"Other"`. This is the category in which the recipe will appear in the crafting menu.
---@field name string The name of the craftable displayed in the menu. If not set, it will use the name of the craftable object
---@field placedObject string If the object being placed is different from the object that is picked up by the player, use `id` for the held object id and `placedObject` for the id of the object that is placed in the world
---@field uncarryable boolean Treats the crafted item as uncarryable even if the object type otherwise would be carryable. This will make the object be crafted immediately into the world and remove the Pick Up button from the menu. Not required if the crafted object is already uncarryable, such as a static or activator
---@field additionalMenuOptions craftingFrameworkMenuButtonData[] A list of additional menu options that will be displayed in the craftable menu
---@field soundId string Provide a sound ID (for a sound registered in the CS) that will be played when the craftable is crafted
---@field soundPath string Provide a custom sound path that will be played when an craftable is crafted
---@field soundType craftingFrameworkCraftableSoundType Determines the crafting sound used, using sounds from the framework or added by interop. These include: "fabric", "wood", "leather", "rope", "straw", "metal" and "carve."
---@field materialRecovery number The percentage of materials used to craft the item that will be recovered. Overrides the default amount set in the Crafting Framework MCM
---@field maxSteepness number The max angle a crafted object will be oriented to while repositioning
---@field resultAmount number The amount of the item to be crafted
---@field recoverEquipmentMaterials boolean When set to true, and the craftable is an armor or weapon item, equipping it when it has 0 condition will destroy it and salvage its materials
---@field destroyCallback function Custom function called after a craftable has been destroyed
---@field placeCallback function Custom function called after a craftable has been placed
---@field positionCallback function
---@field craftCallback function Custom function called after a craftable has been crafted
---@field previewMesh string This is the mesh override for the preview pane in the crafting menu. If no mesh is present, the 3D model of the associated item will be used.
---@field rotationAxis craftingFrameworkRotationAxis **Default "z"** Determines about which axis the preview mesh will rotate around. Defaults to the z axis.
---@field previewScale number **Default 1** Determines the scale of the preview mesh.
---@field previewHeight number **Default 1** Determines the height of the mesh in the preview window.


---@class craftingFrameworkRecipe
---@field id string The id of the object crafted by this recipe.
---@field description string The description of the recipe, displayed in the crafting menu.
---@field persist boolean *Default*: `true`. If `false`, the recipe will not be saved to the global recipe list and can't be accessed with Recipe.getRecipe.
---@field craftable craftingFrameworkCraftable The object that can be crafted with this recipe.
---@field materials craftingFrameworkMaterialRequirementData|craftingFrameworkMaterialRequirementData[] **Required.** A table with the materials required by this recipe.
---@field timeTaken number The time taken to craft the associated object. Currently, doesn't serve a purpose within Crafting Framework, but it can be used to implement custom mechanics.
---@field knownByDefault boolean *Default*: `true`. Controls whether the player knows this recipe from the game start.
---@field customRequirements craftingFrameworkCustomRequirement[] A table with the custom requirements that need to be met in order to craft the associated item.
---@field skillRequirements craftingFrameworkSkillRequirement[] A table with the skill requirements needed to craft the associated item.
---@field toolRequirements craftingFrameworkToolRequirement[] A table with the tool requirements needed to craft the associated item.
---@field category string *Default*: `"Other"`. This is the category in which the recipe will appear in the crafting menu.
---@field registeredRecipes table<string, craftingFrameworkRecipe>
craftingFrameworkRecipe = {}

---@param id string The recipe's unique identifier.
---@return craftingFrameworkRecipe recipe The recipe requested.
function craftingFrameworkRecipe.getRecipe(id) end

---This method creates a new recipe.
---@param data craftingFrameworkRecipeData This table accepts following values:
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
---@return craftingFrameworkRecipe recipe The newly constructed recipe.
function craftingFrameworkRecipe:new(data) end

---This method will make the recipe available to the player.
function craftingFrameworkRecipe:learn() end

---This method will make the recipe unavailable for the player. If the recipe has `knownByDefault` set to `true`, calling this method will change it to `false`.
function craftingFrameworkRecipe:unlearn() end

---This method will return `true` if the player knows the recipe.
---@return boolean
function craftingFrameworkRecipe:isKnown() end

---This method will perform crafting of the related craftable object. It will perform the following:
---
--- - The required amount of materials will be removed from the player's inventory.
---
--- - The condition of the used tool(s) will be reduced, by amount specified in the toolRequirement.
---
--- - A new craftable object is created by invoking its `craft` method.
---
--- - The appropriate skills will be awarded experience.
function craftingFrameworkRecipe:craft() end

---This method returns the item that can be crafted with this recipe.
---@return tes3object object
function craftingFrameworkRecipe:getItem() end

---This method returns the average of the skill levels required to craft the item associated with this recipe.
---@return number
function craftingFrameworkRecipe:getAverageSkillLevel() end

---This method will return `true` if the player has the materials required to craft the item. Otherwise, `false` and reason (string) why the item can't be crafted is returned.
---@return boolean
---@return string reason
function craftingFrameworkRecipe:hasMaterials() end

---This method will return `true` if the player has the tools required to craft the item. Otherwise, `false` and reason (string) why the item can't be crafted is returned.
---@return boolean
---@return string reason
function craftingFrameworkRecipe:meetsToolRequirements() end

---This method will return `true` if the player's skills meet the requirements to craft the item. Otherwise, `false` and reason (string) why the item can't be crafted is returned.
---@return boolean
---@return string reason
function craftingFrameworkRecipe:meetsSkillRequirements() end

---This method will return `true` if the player meets custom requirements needed to craft the item. Otherwise, `false` and reason (string) why the item can't be crafted is returned.
---@return boolean
---@return string reason
function craftingFrameworkRecipe:meetsCustomRequirements() end

---This method will return `true` if the player meets all the requirements needed to craft the item. Otherwise, `false` and reason (string) why the item can't be crafted is returned.
---@return boolean
---@return string reason
function craftingFrameworkRecipe:meetsAllRequirements() end
