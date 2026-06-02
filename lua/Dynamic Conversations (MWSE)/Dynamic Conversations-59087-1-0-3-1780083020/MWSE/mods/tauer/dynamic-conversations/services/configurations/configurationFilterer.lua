local ruleLoader = require("tauer.dynamic-conversations.services.rules.ruleLoader")

local logger = mwse.Logger.new()

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Filters conversation configurations based on defined rules
---@class configurationFilterer : initializedService
local this = {}

---@private
---@type conversationFilteringRule[]
this.rules = {}

---@public
---@return boolean
function this.initialize()
	local rules = ruleLoader.loadRules("services\\configurations\\filtering-rules")
	if not rules or table.size(rules) == 0 then
		logger:error("No filtering rules found!")
		return false
	end

	this.rules = rules
	return true
end

--- Filters the provided conversation configurations based on the given rules and candidate NPCs
---@public
---@param configurations conversationConfiguration[] The list of conversation configurations to filter
---@param npcs tes3npcInstance[] The NPC candidates for conversations
---@return conversationConfiguration[]|nil configurations The filtered list of viable conversation configurations, or nil if none are viable
function this.filter(configurations, npcs)
	---@type conversationConfiguration[]
	local filtered = {}
	for _, configuration in pairs(configurations) do
		this.applyRules(configuration, npcs, filtered)
	end
	if table.size(filtered) == 0 then
		return nil
	end
	logger:debug("Found %d viable configurations", table.size(filtered))
	return filtered
end

---@private
---@param configuration conversationConfiguration
---@param npcs tes3npcInstance[]
---@param filtered conversationConfiguration[]
function this.applyRules(configuration, npcs, filtered)
	for _, rule in ipairs(this.rules) do
		if not rule.isMet(npcs, configuration) then
			logger:debug(string.format("'%s' violated rule '%s'", configuration.name, rule.name))
			return
		end
	end
	table.insert(filtered, configuration)
end

return this
