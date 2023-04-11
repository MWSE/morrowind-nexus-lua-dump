local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local menuactivator = CraftingFramework.MenuActivator:new{
    id = "BSG_Gem_Cutters",
    type = "equip",
    name = "Crafting Menu",
    recipes = {
        {
            id = "Recipe_SoulGemBlack",
            craftableId = "AB_Misc_SoulGemBlack",
            materials = {
                { material = "Ingred_Daedras_Heart_01", count = 1},
                { material = "Ingred_Ash_Salts_01", count = 2},
                { material = "Misc_SoulGem_Grand", count = 1},
            },
            skillRequirements = {
                { skill = "conjuration", requirement = 30},
                { skill = "enchant", requirement = 30}
            }
        }
    }
}
