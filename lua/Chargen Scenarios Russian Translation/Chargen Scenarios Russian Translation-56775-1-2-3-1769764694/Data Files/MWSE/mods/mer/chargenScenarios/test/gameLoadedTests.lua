local Scenario = require "mer.chargenScenarios.component.Scenario"
local common = require "mer.chargenScenarios.common"
local mcmConfig = common.config.mcm
if not mcmConfig.doTests then return end
local Tester = require("mer.chargenScenarios.test.Tester")
if not Tester then return end

--Basic scenario with just required fields
---@type ChargenScenariosScenarioInput
local successfulScenarioInput = {
    name = "Test Scenario",
    description = "Test scenario description",
    location = {
        position = { 0, 0, 0 },
        orientation = { 0, 0, 0 },
        cell = "West Gash Region",
        introMessage = "Test location intro message",
    },
}

local function runLoadedTests()
    if not Tester then return end
    if not mcmConfig.doTests then return end

    Tester:start("Chargen Scenarios Loaded Tests")
    Tester:test("Adds single item to the player's inventory", function()
        local input = table.deepcopy(successfulScenarioInput)
        input.items = {
            {
                id = "misc_com_plate_06",
                count = math.random(1, 10),
            },
        }
        local successfulScenario = Scenario:new(input)
        local itemCountBefore = tes3.getItemCount{
            reference = tes3.player,
            item = input.items[1].id,
        }
        successfulScenario:doItems()
        local itemCountAfter = tes3.getItemCount{
            reference = tes3.player,
            item = input.items[1].id,
        }
        Tester:expect(itemCountAfter - itemCountBefore).toBe(input.items[1].count)
    end)
    Tester:finish()
end
event.register("loaded", runLoadedTests, { priority = -1000 })