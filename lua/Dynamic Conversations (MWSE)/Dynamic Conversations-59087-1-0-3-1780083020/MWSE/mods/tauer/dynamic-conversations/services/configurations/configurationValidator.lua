local ruleLoader = require("tauer.dynamic-conversations.services.rules.ruleLoader")

local logger = mwse.Logger.new()

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Validates conversation configurations based on defined rules
---@class configurationValidator : initializedService
local this = {}

---@private
---@type conversationValidationRule[]
this.rules = {}

---@public
---@return boolean
function this.initialize()
	local rules = ruleLoader.loadRules("services\\configurations\\validation-rules")
	if not rules or table.size(rules) == 0 then
		logger:error("No validation rules found!")
		return false
	end

	this.rules = rules
	return true
end

--- Validates the provided conversation configuration against the defined rules
---@public
---@param configuration conversationConfiguration The conversation configuration to validate
---@return boolean valid Whether the configuration is valid, and the reason if it is not
---@return string|nil reason The reason the configuration is invalid, or nil if it is valid
function this.validate(configuration)
	for _, rule in ipairs(this.rules) do
		local isMet, reason = rule.isMet(configuration)
		if not isMet then
			return false, string.format("'%s' violated with reason '%s'", rule.name, reason)
		end
	end

	return true, nil
end

return this
