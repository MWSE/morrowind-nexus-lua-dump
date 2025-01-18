local FishRack = require("mer.fishing.FishRack")
local CraftingFramework = include("CraftingFramework")
local ashfall = include("mer.ashfall.interop")
local FishType = require("mer.fishing.Fish.FishType")
---@type CraftingFramework.Material.data[]
local materials = {
    {
        id = "crabshell",
        ids = {
            "mer_crabshell"
        },
        name = "Crab Shell",
    }
}
if CraftingFramework then
    for _, material in ipairs(materials) do
        CraftingFramework.Material:new(material)
    end
end

---@type CarryableContainers.ItemFilter.new.data[]
local itemFilters = {
    {
        id = "fish",
        name = "Fish",
        isValidItem = function(item)
            mwse.log("Checking if %s is fish", item.id)
            local fishType = FishType.get(item.id)
            return fishType and fishType.class ~= "loot"
        end
    }
}

if CraftingFramework then
    for _, itemFilter in ipairs(itemFilters) do
        CraftingFramework.ItemFilter.register(itemFilter)
    end
end


---@type CraftingFramework.Recipe.data[]
local bushcraftingRecipes = {
    {
        id = "Fishing:mer_crabhat",
        craftableId = "mer_crabhat",
        previewMesh = "mer_fishing\\c\\crabhat.NIF",
        description = "A hat made from the shell of a juvenile mudcrab. Good for keeping the sun out of your eyes while fishing.",
        materials = {
            { material = "crabshell", count = 1 },
            { material = "straw", count = 3 },
            { material = "rope", count = 1 }
        },
        category = "Fishing",
        soundType = "fabric",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 10 }
        }
    },
    {
        id = "Fishing:mer_fishing_pole_01",
        craftableId = "mer_fishing_pole_01",
        description = "A simple wooden fishing pole.",
        materials = {
            { material = "wood", count = 2 },
            { material = "fibre", count = 6 },
            { material = "resin", count = 1 }
        },
        category = "Fishing",
        soundType = "wood",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 15 }
        }
    },
    {
        id = "Fishing:mer_fishbasket",
        craftableId = "mer_fishbasket",
        description = "A basket for carrying fish.",
        materials = {
            { material = "straw", count = 8 },
            { material = "rope", count = 1 }
        },
        category = "Fishing",
        soundType = "straw",
        containerConfig = {
            capacity = 100,
            weightModifier = 0.6,
            filter = "fish",
            hasCollision = true,
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 20 }
        }
    },
    {
        id = "Fishing:mer_fishing_net",
        craftableId = "mer_fishing_net",
        description = "A fishing net allows you to catch a fish before its fatigue has completely run out.",
        materials = {
            { material = "wood", count = 3 },
            { material = "netting", count = 1 },
            { material = "rope", count = 1 },
        },
        category = "Fishing",
        soundType = "rope",
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 40 }
        }
    },
    {
        id = "Fishing:mer_fish_rack",
        name = "Fish Rack",
        craftableId = "mer_fish_rack",
        description = "A wooden fish rack.",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {
            { skill = "Bushcrafting", requirement = 20 }
        },
        category = "Fishing",
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
                text = "Hang Fish",
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
                        return { text = "You don't have any fish to hang" }
                    end
                    if not fishRack:hasEmptyHook() then
                        return { text = "This fish rack is full" }
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
        description = "A bowl carved from the shell of a juvenile mudcrab.",
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
        category = "Utensils",
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