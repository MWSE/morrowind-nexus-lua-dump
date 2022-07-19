local Recipe = require("CraftingFramework.components.Recipe")
local Material = require("CraftingFramework.components.Material")
local Tool = require("CraftingFramework.components.Tool")


local doUnitTests = false
local UnitWind = include("unitwind")
if not UnitWind then return end
UnitWind = UnitWind.new{
    enabled = doUnitTests,
    highlight = true,
    exitAfter = true
}

UnitWind:start("Crafting Framework: On Initialised Tests")
UnitWind:test("Canary", function()
    UnitWind:expect(true).toBe(true)
end)

Material:new{
    id = "testMaterial",
    name = "Test Material",
    ids = {
        "misc_clothbolt_01"
    },
}

Tool:new{
    id = "testTool",
    name = "Test Tool",
    ids = {
        "ashfall_woodaxe"
    }
}

local validRecipe = {
    id = "testRecipe",
    craftableId = "testCraftable",
    materials = {
        {material = "testMaterial"}
    },
    skillRequirement = {
        skill = "speechcraft",
        requirement = 10
    },
    toolRequirements = {
        {
            tool = "testTool",
            count = 1
        }
    }
}

UnitWind:test("A valid recipe gets created successfully", function()
    local recipe = Recipe:new(validRecipe)
    UnitWind:expect(recipe).NOT.toBe(nil)
    UnitWind:log(json.encode(recipe, { indent = true}))
end)

UnitWind:finish()
