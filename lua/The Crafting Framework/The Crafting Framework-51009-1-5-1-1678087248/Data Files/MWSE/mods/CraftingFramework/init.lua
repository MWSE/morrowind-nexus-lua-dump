---@class CraftingFramework
local CraftingFramework = {}

CraftingFramework.interop = require("CraftingFramework.interop")
CraftingFramework.Tool = require("CraftingFramework.components.Tool")
CraftingFramework.SkillRequirement = require("CraftingFramework.components.SkillRequirement")
CraftingFramework.Material = require("CraftingFramework.components.Material")
CraftingFramework.Craftable = require("CraftingFramework.components.Craftable")
CraftingFramework.Recipe = require("CraftingFramework.components.Recipe")
CraftingFramework.MenuActivator = require("CraftingFramework.components.MenuActivator")
CraftingFramework.Indicator = require("CraftingFramework.components.Indicator")
CraftingFramework.Positioner = require("CraftingFramework.components.Positioner")
CraftingFramework.StaticActivator = require("CraftingFramework.components.StaticActivator")

return CraftingFramework