local MenuActivator = require("CraftingFramework.components.MenuActivator")
local Recipe = require("CraftingFramework.components.Recipe")
local Material = require("CraftingFramework.components.Material")
local Tool = require("CraftingFramework.components.Tool")
---@class craftingFrameworkInterop
local interop = {}

--MenuActivator APIs

---@param menuActivator craftingFrameworkMenuActivatorData
---@return craftingFrameworkMenuActivator
function interop.registerMenuActivator(menuActivator)
    local catalogue = MenuActivator:new(menuActivator)
    return catalogue
end
---@param id string
---@return craftingFrameworkMenuActivator menuActivator
function interop.getMenuActivator(id)
    return MenuActivator.registeredMenuActivators[id]
end

--Recipe APIs

---@param data craftingFrameworkRecipeData[]
function interop.registerRecipes(data)
    for _, recipe in ipairs(data) do
        interop.registerRecipe(recipe)
    end
end
---@param recipe craftingFrameworkRecipeData
function interop.registerRecipe(recipe)
    Recipe:new(recipe)
end
---@param id string
---@return craftingFrameworkRecipe recipe
function interop.getRecipe(id)
    return Recipe.registeredRecipes[id]
end
---@param id string
function interop.learnRecipe(id)
    local recipe = interop.getRecipe(id)
    recipe:learn()
end
---@param id string
function interop.unlearnRecipe(id)
    local recipe = interop.getRecipe(id)
    recipe:unlearn()
end

--Material APIs

---@param data craftingFrameworkMaterialData[]
function interop.registerMaterials(data)
    for _, material in ipairs(data) do
        interop.registerMaterial(material)
    end
end
---@param data craftingFrameworkMaterialData
function interop.registerMaterial(data)
    Material:new(data)
end
---@param id string
---@return craftingFrameworkMaterial material
function interop.getMaterials(id)
    return Material.registeredMaterials[id]
end

--Tool APIs

---@param data craftingFrameworkToolData[]
function interop.registerTools(data)
    for _, tool in ipairs(data) do
        interop.registerTool(tool)
    end
end
---@param data craftingFrameworkToolData
function interop.registerTool(data)
    Tool:new(data)
end

---@param id string
---@return craftingFrameworkTool tool
function interop.getTools(id)
    return Tool.registeredTools[id]
end

return interop