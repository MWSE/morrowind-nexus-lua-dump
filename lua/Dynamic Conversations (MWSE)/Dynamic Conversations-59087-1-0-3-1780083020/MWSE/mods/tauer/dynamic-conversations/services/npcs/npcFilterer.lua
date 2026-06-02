local ruleLoader = require("tauer.dynamic-conversations.services.rules.ruleLoader")

local logger = mwse.Logger.new()

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Filters NPCs based on defined rules
---@class npcFilterer : initializedService
local this = {}

---@private
---@type npcFilteringRule[]
this.rules = {}

---@public
---@return boolean
function this.initialize()
	local rules = ruleLoader.loadRules("services\\npcs\\filtering-rules")
	if table.size(rules) == 0 then
		logger:error("No filtering rules found!")
		return false
	end

	this.rules = rules
	return true
end

--- Filters the provided NPCs based on filtering rules and the given conversation configuration
---@public
---@param npcs tes3npcInstance[] The NPCs to filter
---@param configuration conversationConfiguration The conversation configuration to use for filtering
---@return tes3npcInstance[] filtered The filtered NPCs
function this.filter(npcs, configuration)
	if not configuration.conditions then
		return npcs
	end
	---@type tes3npcInstance[]
	local filtered = {}
	for _, npc in pairs(npcs) do
		this.applyRules(npc, configuration, filtered)
	end
	return filtered
end

---@private
---@param npc tes3npcInstance
---@param configuration conversationConfiguration
---@param filtered tes3npcInstance[]
function this.applyRules(npc, configuration, filtered)
	for _, rule in ipairs(this.rules) do
		if not rule.isMet(npc, configuration) then
			logger:debug(string.format("'%s' violated rule '%s'", npc.baseObject.name, rule.name))
			return
		end
	end
	table.insert(filtered, npc)
end

return this
