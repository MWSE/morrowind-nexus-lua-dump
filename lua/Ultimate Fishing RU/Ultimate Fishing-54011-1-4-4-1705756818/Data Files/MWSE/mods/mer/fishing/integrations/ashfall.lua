local FishRack = require("mer.fishing.FishRack")

---@type CraftingFramework.Recipe.data[]
local bushcraftingRecipes = {
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
