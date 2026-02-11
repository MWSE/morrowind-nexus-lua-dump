--[[
    Scenarios specific to other Merlord Mods
]]

local Scenario = require("mer.chargenScenarios.component.Scenario")

---@type ChargenScenariosScenarioInput[]
local scenarios = {

}

for _, scenario in ipairs(scenarios) do
    Scenario:register(scenario)
end