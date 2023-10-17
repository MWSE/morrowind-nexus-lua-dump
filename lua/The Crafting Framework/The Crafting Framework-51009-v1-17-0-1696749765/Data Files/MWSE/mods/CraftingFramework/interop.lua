local MenuActivator = require("CraftingFramework.components.MenuActivator")
local Recipe = require("CraftingFramework.components.Recipe")
local Material = require("CraftingFramework.components.Material")
local Tool = require("CraftingFramework.components.Tool")
local Positioner = require("CraftingFramework.components.Positioner")
local StaticActivator = require("CraftingFramework.components.StaticActivator")
local Indicator = require("CraftingFramework.components.Indicator")
---@class craftingFrameworkInterop
---Deprecated. Use `require("CraftingFramework")` instead
local interop = {}

--MenuActivator APIs

---@param menuActivator CraftingFramework.MenuActivator.data
---@return CraftingFramework.MenuActivator
function interop.registerMenuActivator(menuActivator)
    local catalogue = MenuActivator:new(menuActivator)
    return catalogue
end
---@param id string
---@return CraftingFramework.MenuActivator menuActivator
function interop.getMenuActivator(id)
    return MenuActivator.registeredMenuActivators[id]
end

--Recipe APIs

---@param data CraftingFramework.Recipe.data[]
function interop.registerRecipes(data)
    for _, recipe in ipairs(data) do
        interop.registerRecipe(recipe)
    end
end
---@param recipe CraftingFramework.Recipe.data
function interop.registerRecipe(recipe)
    Recipe:new(recipe)
end
---@param id string
---@return CraftingFramework.Recipe recipe
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

---@param data CraftingFramework.Material.data[]
function interop.registerMaterials(data)
    for _, material in ipairs(data) do
        interop.registerMaterial(material)
    end
end
---@param data CraftingFramework.Material.data
function interop.registerMaterial(data)
    Material:new(data)
end
---@param id string
---@return CraftingFramework.Material material
function interop.getMaterials(id)
    return Material.registeredMaterials[id]
end

--Tool APIs

---@param data CraftingFramework.Tool.data[]
function interop.registerTools(data)
    for _, tool in ipairs(data) do
        interop.registerTool(tool)
    end
end
---@param data CraftingFramework.Tool.data
function interop.registerTool(data)
    Tool:new(data)
end

-- Activator APIs
function interop.registerStaticActivator(data)
    StaticActivator:new(data)
end

-- Indicator APIs
function interop.registerIndicator(data)
    Indicator:new(data)
end

---@param id string
---@return CraftingFramework.Tool tool
function interop.getTools(id)
    return Tool.registeredTools[id]
end

--[[
    Activates the Positioner mechanic for the given reference
]]
---@class CraftingFramework.interop.activatePositionerParams
---@field reference tes3reference
---@field pinToWall boolean
---@field placementSetting string
---@field blockToggle boolean

---@param e CraftingFramework.interop.activatePositionerParams
function interop.activatePositioner(e)
    Positioner.startPositioning{
        target = e.reference,
        nonCrafted = true,
        pinToWall = e.pinToWall,
        placementSetting = e.placementSetting,
        blockToggle = e.blockToggle,
    }
end

return interop ---@deprecated