--- Validation rule for quest index conditions in conversation configurations
---@class questIndexRule : conversationValidationRule
local this = {}

this.allowedOperators = {
	["="] = true,
	[">"] = true,
	["<"] = true,
	[">="] = true,
	["<="] = true,
}

---@public
---@param configuration conversationConfiguration
---@return boolean, reason|nil
function this.isMet(configuration)
	local questIndexCondition = configuration.conditions and configuration.conditions.questIndex
	if not questIndexCondition then
		return true, nil
	end

	for _, index in pairs(questIndexCondition) do
		if not index.value then
			return false, "missing index value"
		end

		if not index.operator then
			return false, "missing operator"
		end

		if not this.allowedOperators[index.operator] then
			return false, string.format("invalid operator '%'", index.operator)
		end
	end

	return true, nil
end

return this
