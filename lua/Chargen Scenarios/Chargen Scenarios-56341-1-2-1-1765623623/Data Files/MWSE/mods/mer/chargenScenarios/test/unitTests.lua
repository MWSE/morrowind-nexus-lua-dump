
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

Tester:start("Chargen Scenarios Unit Tests")
Tester:test("Canary test", function()
    Tester:expect(true).toBe(true)
end)
--interop
Tester:log("Testing Interop:")
Tester:test("Chargen Scenarios Interop is found", function()
    local interop = include('mer.chargenScenarios.interop')
    Tester:expect(interop).NOT.toBe(nil)
end)
Tester:test("registerScenario interop returns valid scenario", function()
    local interop = include('mer.chargenScenarios.interop')
    local input = table.deepcopy(successfulScenarioInput)
    local successfulScenario = interop.registerScenario(input)
    Tester:expect(successfulScenario).NOT.toBe(nil)
end)
--Scenario
Tester:log("Testing Scenario:")
Tester:test("Scenario has all expected methods", function()
    local scenario = Scenario:new(successfulScenarioInput)
    Tester:expect(scenario).NOT.toBe(nil)
    Tester:expect(scenario.addLocation).toBeType("function")
    Tester:expect(scenario.getStartingLocation).toBeType("function")
    Tester:expect(scenario.doItems).toBeType("function")
    Tester:expect(scenario.checkRequirements).toBeType("function")
    Tester:expect(scenario.moveToLocation).toBeType("function")
    Tester:expect(scenario.doClutter).toBeType("function")
    Tester:expect(scenario.doSpells).toBeType("function")
    Tester:expect(scenario.start).toBeType("function")
end)

--name
Tester:log("Testing Name:")
Tester:test("Scenario has correct name", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.name = "Test Scenario"
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario.name).toBe(input.name)
end)
Tester:test("Scenario:new() fails when name is missing", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.name = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)

--description
Tester:log("Testing Description:")
Tester:test("Scenario has correct description", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.description = "Test scenario description"
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario.description).toBe(input.description)
end)
Tester:test("Scenario:new() fails when description is missing", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.description = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)

--location
Tester:log("Testing Location:")
Tester:test("A single input location is moved to a list", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location = {
        position = { 0, 0, 0 },
        orientation = { 0, 0, 0 },
        cell = "West Gash Region",
        introMessage = "Test location intro message",
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(#successfulScenario.locations).toBe(1)
end)

Tester:test("A location added using :addLocation is registered correctly", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location = nil
    input.locations = nil
    local successfulScenario = Scenario:new(input)
    local locationInput = {
        position = { 0, 0, 0 },
        orientation = { 0, 0, 0 },
        cell = "West Gash Region",
        introMessage = "Test location intro message",
    }
    successfulScenario:addLocation(locationInput)
    Tester:expect(#successfulScenario.locations).toBe(1)
    Tester:expect(successfulScenario:getIntroMessage()).toBe(locationInput.introMessage)
end)

Tester:test("A list of locations are registered correctly", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location = nil
    input.locations = {
        {
            position = { 0, 0, 0 },
            orientation = { 0, 0, 0 },
            cell = "West Gash Region",
            introMessage = "Test location intro message",
        },
        {
            position = { 0, 0, 0 },
            orientation = { 0, 0, 0 },
            cell = "West Gash Region",
            introMessage = "Test location intro message",
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(#successfulScenario.locations).toBe(2)
end)
Tester:test("Scenario:getStartingLocation returns the location", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.locations = {
        {
            position = { 0, 0, 0 },
            orientation = { 0, 0, 0 },
            cell = "West Gash Region",
            introMessage = "Test location intro message",
        },
    }
    local successfulScenario = Scenario:new(input)
    local location = successfulScenario:getStartingLocation() --[[@as ChargenScenariosLocation]]
    Tester:expect(location).NOT.toBe(nil)
    Tester:expect(location.cell).toBe(input.locations[1].cell)
    Tester:expect(location:getIntroMessage()).toBe(input.locations[1].introMessage)
end)
Tester:test("Scenario:new() fails when location is missing", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location = nil
    input.locations = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)
Tester:test("Scenario:new() fails when location does not have a position", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location.position = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)
Tester:test("Scenario:new() fails when location does not have an orientation", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location.orientation = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)
Tester:test("Scenario:new() fails when location does not have a cell", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.location.cell = nil
    Tester:expect(function()
        Scenario:new(input)
    end).toFail()
end)

--items
Tester:log("Testing Items:")
Tester:test("Scenario has correct itemList", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.items = {
        {
            id = "testItem",
            count = 1,
        },
        {
            id = "testItem2",
            count = 2,
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(#successfulScenario.itemList.items).toBe(2)
    Tester:expect(successfulScenario.itemList.doItems).toBeType("function")
    Tester:expect(successfulScenario.itemList.items[1].ids[1]).toBe(input.items[1].id)
end)

--introMessage
Tester:log("Testing Intro: Message")
Tester:test("Scenario has correct intro message", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.introMessage = "Test scenario intro message"
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario.introMessage).toBe(input.introMessage)
end)
Tester:test("Scenario:getIntroMessage returns location.introMessage if it exists", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.introMessage = "Test scenario intro message"
    input.location.introMessage = "Test location intro message"
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:getIntroMessage()).toBe(input.location.introMessage)
end)
Tester:test("Scenario:getIntroMessage returns the scenario intro message when the location.introMessage is nil", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.introMessage = "Test scenario intro message"
    input.location.introMessage = nil
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:getIntroMessage()).toBe(input.introMessage)
end)
--requirements
Tester:log("Testing Requirements:")
Tester:test("Scenario:checkRequirements returns true when there are no requirements", function()
    local input = table.deepcopy(successfulScenarioInput)
    input.requirements = nil
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(true)
end)
Tester:test("Scenario:checkRequirements returns true when an existing plugin is required", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
            plugin = "Morrowind.ESP",
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(true)
end)
Tester:test("Scenario:checkRequirements returns true when an existing plugin with different casing is required", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
            plugin = "Morrowind.eSp",
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(true)
end)
Tester:test("Scenario:checkRequirements returns false when a non-existent plugin is required", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
        plugins = {"ThisPluginDoesNotExist"},
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(false)
end)
Tester:test("Scenario:checkRequirements returns true when a valid player class is required, regardless of casing", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
        classes = {"VaLiDcLasS"},
    }
    tes3.player = {
        testPlayerObject = true,
        object = {
            class = {
                id = "validClass",
            }
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(true)
    tes3.player = nil
end)
Tester:test("Scenario:checkRequirements returns false when an invalid player class is required", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
        classes = {"InvalidClass"},
    }
    tes3.player = {
        testPlayerObject = true,
        object = {
            class = {
                id = "ValidClass",
            }
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(false)
    tes3.player = nil
end)
Tester:test("Scenario:checkRequirements returns true when the player race does exist in the race list, regardless of casing", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
        races = { "DarK Elf", "BreTon" },
    }
    tes3.player = {
        testPlayerObject = true,
        object = {
            race = {
                id = "Dark Elf",
            }
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(true)
    tes3.player = nil
end)
Tester:test("Scenario:checkRequirements returns false when the player race does not exist in the race list", function()
    local input = table.deepcopy(successfulScenarioInput)
    ---@type ChargenScenariosRequirementsInput
    input.requirements = {
        races = { "Dark Elf", "Breton" },
    }
    tes3.player = {
        testPlayerObject = true,
        object = {
            race = {
                id = "High Elf",
            }
        },
    }
    local successfulScenario = Scenario:new(input)
    Tester:expect(successfulScenario:checkRequirements()).toBe(false)
    tes3.player = nil
end)

Tester:finish(mcmConfig.exitAfterUnitTests)

