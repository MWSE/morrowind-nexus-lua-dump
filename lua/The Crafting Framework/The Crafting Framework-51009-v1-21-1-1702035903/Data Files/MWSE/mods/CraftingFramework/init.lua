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
CraftingFramework.ReferenceManager = require("CraftingFramework.components.ReferenceManager")
CraftingFramework.MerchantManager = require("CraftingFramework.components.MerchantManager")
CraftingFramework.MaterialStorage = require("CraftingFramework.components.MaterialStorage")
CraftingFramework.InventorySelectMenu = require("CraftingFramework.carryableContainers.components.InventorySelectMenu")

--Carryabe Containers
CraftingFramework.CarryableContainer =require("CraftingFramework.carryableContainers.components.CarryableContainer")
CraftingFramework.ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")
CraftingFramework.Util = require("CraftingFramework.util.Util")

return CraftingFramework