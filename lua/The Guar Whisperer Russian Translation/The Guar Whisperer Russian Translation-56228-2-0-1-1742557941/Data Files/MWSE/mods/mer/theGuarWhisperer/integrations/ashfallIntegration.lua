-- Define the recipe for the leather ball
---@type CraftingFramework.Recipe.data[]
local bushcraftingRecipes = {
    {
        id = "TGW_LeatherBall",
        craftableId = "mer_tgw_ball_02",
        description = "Мяч из ткани, набитый соломой. Идеально подходит для игры в мяч.",
        materials = {
            { material = "fabric", count = 1 },
            { material = "straw", count = 2 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 15,
            }
        },
        category = "Экипировка Гуара",
        rotationAxis = "z",
        previewScale = 0.7,
    },
    {
        id = "mer_tgw_guarpack",
        craftableId = "mer_tgw_guarpack",
        description = "Седельная сумка для Гуара, в которой можно хранить свои вещи. Может использоваться как седло для верховой езды.",
        materials = {
            { material = "fabric", count = 2 },
            { material = "leather", count = 2 },
            { material = "straw", count = 6 },
            { material = "sack", count = 2 }
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 25,
            }
        },
        category = "Экипировка Гуара",
    }
}

local carvingRecipes = {
    {
        id = "TGW_Flute",
        craftableId = "mer_tgw_flute",
        description = "Простая деревянная флейта, которую можно использовать для вызова гуара компаньона.",
        materials = {
            { material = "wood", count = 1 },
        },
        toolRequirements = {
            {
                tool = "chisel",
                conditionPerUse = 5
            }
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 15,
            }
        },
        category = "Экипировка Гуара",
        rotationAxis = "y",
        previewScale = 1.2
    }
}

event.register("Ashfall:EquipChisel:Registered", function(e)
    ---@type CraftingFramework.MenuActivator
    local menuActivator = e.menuActivator
    menuActivator:registerRecipes(carvingRecipes)
end)

event.register("Ashfall:ActivateBushcrafting:Registered", function(e)
    ---@type CraftingFramework.MenuActivator
    local menuActivator = e.menuActivator
    menuActivator:registerRecipes(bushcraftingRecipes)
end)