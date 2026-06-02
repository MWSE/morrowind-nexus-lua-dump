local packageRule = require("tauer.dynamic-conversations.services.npcs.filtering-rules.packageRule")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm

--- Filtering rule for conversation participants
---@class participantsRule : conversationFilteringRule
local this = {}

---@public
---@param npcs tes3npcInstance[]
---@param configuration conversationConfiguration
function this.isMet(npcs, configuration)
	if not configuration.participants then
		return true
	end

	local participantsFound = 0

	for _, npc in ipairs(npcs) do
		if this.isValidParticipant(npc, configuration) then
			participantsFound = participantsFound + 1
		end
		if participantsFound == 2 then
			return true
		end
	end

	return false
end

---@private
---@param npc tes3npcInstance
---@param configuration conversationConfiguration
---@return boolean
function this.isValidParticipant(npc, configuration)
	if mcm.blacklistedNpcs[npc.baseObject.id] then
		return false
	end

	if not packageRule.isMet(npc, configuration) then
		return false
	end

	if npc.mobile and (npc.mobile.inCombat or npc.mobile.isDead) then
		return false
	end

	local participants = configuration.participants
	if not participants then
		return false
	end

	if npc.baseObject.id:lower() == participants[1]:lower() then
		return true
	elseif npc.baseObject.id:lower() == participants[2]:lower() then
		return true
	end

	return false
end

return this
