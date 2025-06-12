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
        orientation = 0,
        cell = "West Gash Region",
        introMessage = "Test location intro message",
    },
}

local function runInitializedTests()
    if not Tester then return end
    if not mcmConfig.doTests then return end

    Tester:start("Chargen Scenarios Initialised Tests")
    --Spells
    Tester:log("Testing Spells:")
    Tester:test("Populates the spellList with the provided spells", function()
        ---@type ChargenScenariosScenarioInput
        local input = table.deepcopy(successfulScenarioInput)
        input.spells = {
            {
                id = "testspell_restorefatigue",
                name = "TEST_SPELL",
                effects = {
                    {
                        id = tes3.effect.restoreFatigue,
                        duration = 10,
                        min = 5,
                        max = 5
                    },
                }
            },
            {id = "chills"},
        }
        local successfulScenario = Scenario:new(input)
        Tester:expect(successfulScenario.doSpells).toBeType("function")
        local spell1 = successfulScenario.spellList.spells[1]
        Tester:expect(spell1.ids[1]).toBe(input.spells[1].id)
        Tester:expect(spell1.name).toBe(input.spells[1].name)
        Tester:expect(spell1.effects[1].id).toBe(input.spells[1].effects[1].id)

        local spell2 = successfulScenario.spellList.spells[2]
        Tester:expect(spell2.ids[1]).toBe(input.spells[2].id)
    end)

    Tester:finish(mcmConfig.exitAfterIntegrationTests)
end
event.register("initialized", runInitializedTests, { priority = mcmConfig.exitAfterIntegrationTests and 1000 or -1000 })
