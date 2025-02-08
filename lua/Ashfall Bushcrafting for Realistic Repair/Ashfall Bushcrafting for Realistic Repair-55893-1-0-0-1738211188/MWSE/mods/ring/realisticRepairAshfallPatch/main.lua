--[[
    Ashfall Bushcrafting for Realistic Repair
    v1.0
    by codering

    Adds crafting recipes for makeshift stone anvils, grindstones, and forges
    in Ashfall's bushcrafting menu for use with Realistic Repair. Appropriate
    skill in both Armorer and Bushcrafting is needed, as well as both a chisel
    and hammer.
    Requires:
    - Ashfall: https://www.nexusmods.com/morrowind/mods/49057
    - Realistic Repair: https://www.nexusmods.com/morrowind/mods/46673

    TODO:
    - Logging
    - Translation
    - MCM
    - Stone Forge
]]

-- Interops --
local ashfallInterop = require("mer.ashfall.interop") -- Will need this later to register the Stone Forge as a heat source
local realisticRepairInterop = require("mer.RealisticRepair.interop")

-- Variables --
local newWorkbenchRecipes = {}
local newChiselRecipes = {}

-- Stone Anvil
---@class CraftingFramework.Recipe.data
local anvilRecipe =  {
    id = "recipe_cr_stone_anvil",
    craftableId = "cr_stone_anvil",
    name = "Stone Anvil",
    description = "An anvil chiseled from stone. Can be used to repair items with a repair hammer.",
    category = "Structures",
    soundType = "carve",
    materials = {
        {material = "stone", count = 15}
    },
    skillRequirements = {
        {
            skill = "armorer",
            requirement = 25,
            maxProgress = 20
        }
    },
    toolRequirements = {
        {
            tool = "chisel",
            conditionPerUse = 30
        },
        {
            tool = "hammer",
            conditionPerUse = 15
        }
    },
    additionalMenuOptions = {
        {
            text = "Repair",
            callback = function (e)
                event.register("menuExit",
                    function ()
                        tes3.tapKey(tes3.getInputBinding(tes3.keybind.activate).code)
                        tes3.tapKey(tes3.scanCode.leftShift)
                    end,
                    {
                        doOnce = true
                    }
                )
            end,
            enableRequirements = function (e)
                return mge.enabled()
            end,
            tooltipDisabled = "Button non-functional when MGE XE is disabled. Hold shift while activating the Anvil to open repair menu."
        }
    },
    additionalUI = function(indicator)
        indicator.disable()
    end,
    quickActivateCallback = function () event.trigger("BlockScriptedActivate", { doBlock = false }) end
}
table.insert(newWorkbenchRecipes, anvilRecipe)

-- Add to Realistic Repair interop
realisticRepairInterop.addStation({ id = "cr_stone_anvil", name = "Stone Anvil", toolIdPattern = "hammer" })


-- Stone Prongs
-- Needs: 3 firewood, 2 stone, chisel, 25 Armorer
local prongsRecipe =  {
    id = "recipe_stone_prongs",
    craftableId = "cr_stone_prongs",
    name = "Stone Prongs",
    description = "A set of prongs chiseled from stone with wood fittings. Can be used to repair items at a forge.",
    category = "Tools",
    soundType = "carve",
    materials = {
        {material = "stone", count = 2},
        {material = "wood", count = 3}
    },
    skillRequirements = {
        {
            skill = "armorer",
            requirement = 25,
            maxProgress = 20
        }
    },
    toolRequirements = {
        {
            tool = "chisel",
            conditionPerUse = 10
        },
        {
            tool = "hammer",
            conditionPerUse = 5
        }
    }
}
table.insert(newChiselRecipes, prongsRecipe)


-- Stone Forge
-- COMING SOON


-- Register recipes to Ashfall crafting menus
event.register("Ashfall:EquipChisel:Registered", function(e) e.menuActivator:registerRecipes(newChiselRecipes) end)
event.register("Ashfall:ActivateWorkbench:Registered", function (e) e.menuActivator:registerRecipes(newWorkbenchRecipes)
end)