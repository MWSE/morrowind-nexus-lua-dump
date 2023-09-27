---@type CraftingFramework.Recipe.data[]
local bushcraftingRecipes = {
    {
        id = "bushcraft:tr_wooden_guar_01",
        craftableId = "T_De_WoodenGuar_01",
        description = "Carved wooden guar figurine.",
        materials = {
            { material = "wood", count = 1 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 30,
                maxProgress = 30,
            },
        },
        toolRequirements = {
            {
                tool = "chisel",
                conditionPerUse = 10,
            },
        },
        category = "Other",
        soundType = "carve",
    },
    {
        id = "bushcraft:tr_wooden_kagouti_01",
        craftableId = "T_De_WoodenKagouti_01",
        description = "Carved wooden kagouti figurine.",
        materials = {
            { material = "wood", count = 1 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 40,
                maxProgress = 40,
            },
        },
        toolRequirements = {
            {
                tool = "chisel",
                conditionPerUse = 12,
            },
        },
        category = "Other",
        soundType = "carve",
    },
    {
        id = "bushcraft:tr_wooden_scrib_01",
        craftableId = "T_De_WoodenScrib_01",
        description = "Carved wooden scrib figurine.",
        materials = {
            { material = "wood", count = 1 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 40,
                maxProgress = 40,
            },
        },
        toolRequirements = {
            {
                tool = "chisel",
                conditionPerUse = 12,
            },
        },
        category = "Other",
        soundType = "carve",
    },
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
event.register("Ashfall:EquipChisel:Registered", registerAshfallRecipes)
