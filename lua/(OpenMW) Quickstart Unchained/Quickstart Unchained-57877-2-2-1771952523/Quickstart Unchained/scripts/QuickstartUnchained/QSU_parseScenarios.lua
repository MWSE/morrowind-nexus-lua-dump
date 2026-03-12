local vfs = require('openmw.vfs')

-- Indexed by name for fast lookup
scenarios = {}

-- Temporary lists for ordering
local orderedScenarios = {}
local unorderedScenarios = {}

-- Register a scenario (called by scenario files)
function registerScenario(scenario)
	scenarios[scenario.name] = scenario
	if scenario.order then
		table.insert(orderedScenarios, scenario)
	else
		table.insert(unorderedScenarios, scenario.name)
	end
end

-- Load all scenarios from the scenarios folder
local scenarioPath = "scripts/quickstartunchained/scenarios/"
for filePath in vfs.pathsWithPrefix(scenarioPath) do
	local filename = filePath:match("([^/]+)$")
	
	-- Skip macOS metadata files and non-lua files
	if filename and not filename:match("^%._") and filename:match("%.lua$") then
		local requirePath = filePath:gsub("%.lua$", ""):gsub("/", ".")
		local success, err = pcall(function()
			require(requirePath)
		end)
		if not success then
			print("Failed to load scenario: " .. filePath .. " - " .. tostring(err))
		end
	end
end

-- Build final order: sorted ordered scenarios first, then unordered
table.sort(orderedScenarios, function(a, b) return a.order < b.order end)

scenarioOrder = {}
for _, scenario in ipairs(orderedScenarios) do
	table.insert(scenarioOrder, scenario.name)
end
for _, name in ipairs(unorderedScenarios) do
	table.insert(scenarioOrder, name)
end

