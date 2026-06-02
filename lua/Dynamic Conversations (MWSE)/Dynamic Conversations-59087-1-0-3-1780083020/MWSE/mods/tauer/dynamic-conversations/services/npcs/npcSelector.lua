local npcFilterer = require("tauer.dynamic-conversations.services.npcs.npcFilterer")

--- Selects NPCs for conversations
---@class npcSelector
local this = {}

--- Selects NPCs based on the provided configuration or randomly if no participants are specified
---@public
---@param npcs tes3npcInstance[] The NPCs to select from
---@param configuration conversationConfiguration The conversation configuration to use for selection
---@return tes3npcInstance|nil firstParticipant The first selected NPC, or nil if not found
---@return tes3npcInstance|nil secondParticipant The second selected NPC, or nil if not found
function this.select(npcs, configuration)
	local filtered = npcFilterer.filter(npcs, configuration)

	if table.size(filtered) < 2 then
		return nil, nil
	end

	if configuration.participants then
		return this.selectFromConfiguration(filtered, configuration)
	end

	return this.pickTwoDistinct(filtered)
end

---@private
---@param npcs tes3npcInstance[]
---@param configuration conversationConfiguration
---@return tes3npcInstance|nil, tes3npcInstance|nil
function this.selectFromConfiguration(npcs, configuration)
	if configuration.participants[1] == configuration.participants[2] then
		return this.selectParticipantsWithSameId(npcs, configuration.participants[1])
	end

	---@type tes3npcInstance[]
	local firstParticipantCandidates = {}
	---@type tes3npcInstance[]
	local secondParticipantCandidates = {}

	for _, npc in ipairs(npcs) do
		if npc.baseObject.id == configuration.participants[1] then
			table.insert(firstParticipantCandidates, npc)
		end
		if npc.baseObject.id == configuration.participants[2] then
			table.insert(secondParticipantCandidates, npc)
		end
	end

	if table.size(firstParticipantCandidates) < 1 or table.size(secondParticipantCandidates) < 1 then
		return nil, nil
	end

	local firstParticipant = table.choice(firstParticipantCandidates)
	local secondParticipant = table.choice(secondParticipantCandidates)

	return firstParticipant, secondParticipant
end

---@private
---@param npcs tes3npcInstance[]
---@param participantId string
---@return tes3npcInstance|nil, tes3npcInstance|nil
function this.selectParticipantsWithSameId(npcs, participantId)
	---@type tes3npcInstance[]
	local participantCandidates = {}

	for _, npc in ipairs(npcs) do
		if npc.baseObject.id == participantId then
			table.insert(participantCandidates, npc)
		end
	end

	if table.size(participantCandidates) < 2 then
		return nil, nil
	end

	return this.pickTwoDistinct(participantCandidates)
end

---@private
---@param npcs tes3npcInstance[]
---@return tes3npcInstance, tes3npcInstance
function this.pickTwoDistinct(npcs)
	local n = table.size(npcs)

	local i = math.random(n)
	local j = math.random(n - 1)

	if j >= i then
		j = j + 1
	end

	return npcs[i], npcs[j]
end

return this
