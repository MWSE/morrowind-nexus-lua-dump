local CraftingFramework = require("CraftingFramework")

local recipes = require("Syanide.HammerAndProngs.smelt")

-- Crafting menu activator
CraftingFramework.MenuActivator:new{
    id = "HammerAndProngs:OpenMenu",
    type = "event",
    name = "Crafting Menu",
    recipes = recipes
}

CraftingFramework.StaticActivator.register{
    objectId = "furn_de_bellows_01",
    name = "Bellow",
    onActivate = function(reference)
        event.trigger("HammerAndProngs:OpenMenu", { reference = reference })
        return false
    end
}

CraftingFramework.MenuActivator:new{
    id = "AB_Misc_File",
    type = "equip",
    name = "Jewelry Smithing Menu",
    recipes = {}
}