local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local BedRoll = require("mer.ashfall.items.bedroll")

local bushcraftingRecipes = {

    ---
    --- BEDS
    ---
    {
        id = "bushcraft:dim_bedroll0",
        craftableId = "dim_bedroll0",
        name = "Bedroll",
        description = "A serviceable fabric bedroll.",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 10 },
            { material = "fabric", count = 4 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20,
                maxProgress = 20,
            },
        },
        category = "Beds",
        soundType = "straw",
    },
    {
        id = "bushcraft:dim_bedroll1",
        craftableId = "dim_bedroll1",
        name = "Bedroll",
        description = "A serviceable fabric bedroll.",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 10 },
            { material = "fabric", count = 4 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20,
                maxProgress = 20,
            },
        },
        category = "Beds",
        soundType = "straw",
    },
    {
        id = "bushcraft:dim_bedroll_wide",
        craftableId = "dim_bedroll_wide",
        name = "Bedroll (Double)",
        description = "Serviceable fabric bedroll - big enough for two!",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "fabric", count = 6 },
            { material = "straw", count = 16 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 30,
                maxProgress = 35,
            },
        },
        category = "Beds",
        soundType = "straw",
    },
    {
        id = "bushcraft:dim_bedroll_nord_fur",
        craftableId = "dim_bedroll_nord_fur",
        name = "Bedroll (Fur)",
        description = "A cosy fur bedroll.",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 15 },
            { material = "fur", count = 2 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20,
                maxProgress = 20,
            },
        },
        category = "Beds",
        soundType = "straw",
    },
    {
        id = "bushcraft:dim_strawbed_wide",
        craftableId = "dim_strawbed_wide",
        name = "Straw Bed (Double)",
        description = "A simple straw bed. Not very comfortable but it beats sleeping on the ground. This one sleeps two.",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 15 },
            { material = "wood", count = 7 },
            { material = "rope", count = 2 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 10,
                maxProgress = 20,
            },
        },
        category = "Beds",
        soundType = "straw",
    },
    {
        id = "bushcraft:dim_straw_wide",
        craftableId = "dim_straw_wide",
        name = "Straw Pile (Double)",
        description = "A simple straw pile.",
        quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
        additionalMenuOptions = {
            BedRoll.buttons.sleep,
            BedRoll.buttons.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 15 },
        },
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 5,
                maxProgress = 10,
            },
        },
        category = "Beds",
        soundType = "wood",
    },
    
    --
    -- TENTS
    --

    {
        id = "bushcraft:dim_smalltent",
        craftableId = "dim_smalltent",
        name = "Tent (Small, Blue & White)",
        description = "A small but cheery tent to keep the rain off.",
        materials = {
            { material = "fabric", count = 4 },
            { material = "wood", count = 4 },
            { material = "rope", count = 2 },
        },
        category = "Structures",
        soundType = "wood",
    },
    {
        id = "bushcraft:dim_medtent",
        craftableId = "dim_medtent",
        name = "Tent (Medium, Blue & White)",
        description = "A medium sized tent to keep the rain off.",
        materials = {
            { material = "fabric", count = 8 },
            { material = "wood", count = 8 },
            { material = "rope", count = 4 },
        },
        category = "Structures",
        soundType = "wood",
    },
    {
        id = "bushcraft:dim_bigtent",
        craftableId = "dim_bigtent",
        name = "Tent (Big, Blue & White)",
        description = "A big tent to keep the rain off you AND your friends.",
        materials = {
            { material = "fabric", count = 14 },
            { material = "wood", count = 12 },
            { material = "rope", count = 8 },
        },
        category = "Structures",
        soundType = "wood",
    },
}

local recipes = {}
for _, recipe in ipairs(bushcraftingRecipes) do
    table.insert(recipes, recipe)
end

local function registerRecipes(e)
    if e.menuActivator then e.menuActivator:registerRecipes(recipes) end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerRecipes)