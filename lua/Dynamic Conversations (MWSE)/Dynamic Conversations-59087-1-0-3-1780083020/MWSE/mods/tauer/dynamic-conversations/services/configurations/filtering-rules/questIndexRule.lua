--- Filtering rule for quest index conditions in conversation configurations
---@class questIndexFilteringRule : conversationFilteringRule
local this = {}

---@type { [operator]: fun(actual: number, expected: number) : boolean }
this.operations = {
	["="] = function(actual, expected)
		return actual == expected
	end,
	[">"] = function(actual, expected)
		return actual > expected
	end,
	["<"] = function(actual, expected)
		return actual < expected
	end,
	[">="] = function(actual, expected)
		return actual >= expected
	end,
	["<="] = function(actual, expected)
		return actual <= expected
	end,
}

---@public
---@param _ tes3npcInstance
---@param configuration conversationConfiguration
---@return boolean
function this.isMet(_, configuration)
	local questIndexConditions = configuration.conditions and configuration.conditions.questIndex
	if not questIndexConditions then
		return true
	end

	for quest, condition in pairs(questIndexConditions) do
		local index = tes3.getJournalIndex({ id = quest }) or 0
		if not this.operations[condition.operator](index, condition.value) then
			return false
		end
	end

	return true
end

return this
