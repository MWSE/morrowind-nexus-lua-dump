---@class CraftingFramework
local CraftingFramework = {}

--Crafting
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
CraftingFramework.SoundType = require("CraftingFramework.components.SoundType")
CraftingFramework.RefDropper = require("CraftingFramework.components.RefDropper")
CraftingFramework.MerchantManager = require("CraftingFramework.components.MerchantManager")

--Carryabe Containers
CraftingFramework.CarryableContainer =require("CraftingFramework.carryableContainers.components.CarryableContainer")
CraftingFramework.ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")

return CraftingFramework