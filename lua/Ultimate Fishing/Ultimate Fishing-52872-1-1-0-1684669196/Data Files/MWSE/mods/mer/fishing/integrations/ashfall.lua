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
        category = "Fishing"
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
        category = "Fishing"
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
