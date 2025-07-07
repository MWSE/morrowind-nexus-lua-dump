local CraftingFramework = require("CraftingFramework")

local recipes = require("Syanide.HammerAndProngs.recipes")
local smelt = require("Syanide.HammerAndProngs.smelt")

-- Crafting menu activator
CraftingFramework.MenuActivator:new{
    id = "HammerAndProngs:OpenMenu",
    type = "event",
    name = "Smithing Menu",
    recipes = recipes
}

CraftingFramework.StaticActivator.register{
    objectId = "furn_anvil00",
    name = "Anvil",
    onActivate = function(reference)
        event.trigger("HammerAndProngs:OpenMenu", { reference = reference })
        return false
    end
}

-- Smelting menu activator
CraftingFramework.MenuActivator:new{
    id = "HammerAndProngs:SmeltMenu",
    type = "event",
    name = "Smelting Menu",
    recipes = smelt
}

CraftingFramework.StaticActivator.register{
    objectId = "furn_de_forge_01",
    name = "Smelter",
    onActivate = function(reference)
        event.trigger("HammerAndProngs:SmeltMenu", { reference = reference })
        return false
    end
}

CraftingFramework.MenuActivator:new{
    id = "AB_Misc_File",
    type = "equip",
    name = "Jewelry Smithing Menu",
    recipes = recipes
}