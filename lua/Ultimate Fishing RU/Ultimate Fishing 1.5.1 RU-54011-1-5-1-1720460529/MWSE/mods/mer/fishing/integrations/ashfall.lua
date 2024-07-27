local FishRack = require("mer.fishing.FishRack")
local CraftingFramework = include("CraftingFramework")
local ashfall = include("mer.ashfall.interop")

---@type CraftingFramework.Material.data[]
local materials = {
    {
        id = "crabshell",
        ids = {
            "mer_crabshell"
        },
        name = "Панцирь грязекраба",
    }
}
if CraftingFramework then
    for _, material in ipairs(materials) do
        CraftingFramework.Material:new(material)
    end
end


---@type CraftingFramework.Recipe.data[]
local bushcraftingRecipes = {

    {
        id = "Fishing:mer_crabhat",
        craftableId = "mer_crabhat",
        previewMesh = "mer_fishing\\c\\crabhat.NIF",
        description = "Шляпа из панциря молодого грязекраба. Хорошо защищает глаза от солнца во время рыбалки.",
        materials = {
            { material = "crabshell", count = 1 },
            { material = "straw", count = 3 },
            { material = "rope", count = 1 }
        },
        category = "Рыбалка",
        soundType = "fabric",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10 }
        }
    },
    {
        id = "Fishing:mer_fishing_pole_01",
        craftableId = "mer_fishing_pole_01",
        description = "Простая деревянная удочка.",
        materials = {
            { material = "wood", count = 2 },
            { material = "fibre", count = 6 },
            { material = "resin", count = 1 }
        },
        category = "Рыбалка",
        soundType = "wood",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 15 }
        }
    },
    {
        id = "Fishing:mer_fishing_net",
        craftableId = "mer_fishing_net",
        description = "Подсачек позволяет поймать рыбу до того, как ее усталость полностью иссякнет.",
        materials = {
            { material = "wood", count = 3 },
            { material = "netting", count = 1 },
            { material = "rope", count = 1 },
        },
        category = "Рыбалка",
        soundType = "rope",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 40 }
        }
    },
    {
        id = "Fishing:mer_fish_rack",
        name = "Стойка для рыбы",
        craftableId = "mer_fish_rack",
        description = "Деревянная стойка для рыбы.",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 20 }
        },
        category = "Рыбалка",
        soundType = "wood",
        maxSteepness = 25,
        activateCallback = function (self, e)
            local fishRack = FishRack:new(e.reference)
            if fishRack then
                return fishRack:onActivate()
            end
            return false
        end,
        additionalUI = function (indicator, parentElement)
            if not indicator.reference then return end
            local fishRack = FishRack:new(indicator.reference)
            if fishRack then
                fishRack:doTooltip(parentElement, indicator.nodeLookingAt)
            end
        end,
        additionalMenuOptions = {
            {
                text = "Повесить рыбу",
                callback = function(e)
                    local fishRack = FishRack:new(e.reference)
                    if fishRack then
                        fishRack:openAddFishMenu()
                    end
                end,
                enableRequirements = function(e)
                    local fishRack = FishRack:new(e.reference)
                    return fishRack ~= nil
                        and fishRack:canAddFish()
                end,
                tooltipDisabled = function(e)
                    local fishRack = FishRack:new(e.reference)
                    if not fishRack then return nil end
                    if not FishRack.playerHasHangableFish() then
                        return { text = "У вас нет рыбы, чтобы повесить" }
                    end
                    if not fishRack:hasEmptyHook() then
                        return { text = "Эта стойка для рыбы заполнена" }
                    end
                end
            }
        }
    }
}


local function registerAshfallRecipes(e)
    ---@type CraftingFramework.MenuActivator
    local bushcraftingActivator = e.menuActivator
    if bushcraftingActivator then
        for _, recipe in ipairs(bushcraftingRecipes) do
            bushcraftingActivator:registerRecipe(recipe)
        end
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)


local carvingRecipes = {
    {
        id = "Fishing:mer_crab_bowl",
        craftableId = "mer_crab_bowl",
        description = "Миска, вырезанная из панциря молодого грязекраба.",
        materials = {
            { material = "crabshell", count = 1 }
        },
        toolRequirements = {
            {
                tool = "chisel",
                conditionPerUse = 4
            }
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10 }
        },
        category = "Посуда",
        soundType = "carve"
    },
}
event.register("Ashfall:EquipChisel:Registered", function(e)
    ---@type CraftingFramework.MenuActivator
    local carvingActivator = e.menuActivator
    if carvingActivator then
        for _, recipe in ipairs(carvingRecipes) do
            carvingActivator:registerRecipe(recipe)
        end
    end
end)

---@type table<string, Ashfall.waterContainerData>
local waterContainers = {
    mer_crab_bowl = {
        capacity = 80,
        holdsStew = true,
        waterMaxScale = 1.15,
        waterMaxHeight = 6.5,
        type = "cookingPot",
    }
}


if ashfall then
    if ashfall.registerSunshade then
        ashfall.registerSunshade{
            id = "mer_crabhat"
        }
    end

    ashfall.registerWaterContainers(waterContainers)
end