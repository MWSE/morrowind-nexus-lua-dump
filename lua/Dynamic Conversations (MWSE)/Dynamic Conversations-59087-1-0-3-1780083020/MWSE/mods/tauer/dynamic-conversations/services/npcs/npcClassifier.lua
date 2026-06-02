local SEX = require("tauer.dynamic-conversations.services.npcs.enums.SEX")

--- Encapsulates logic for identifying NPC characteristics
---@class npcClassifier
local this = {}

--- Determines the sex of a given NPC
---@public
---@param npc tes3npcInstance The NPC to determine the sex for
---@return SEX sex The sex of the NPC
function this.getSex(npc)
	if npc.baseObject.female then
		return SEX.female
	else
		return SEX.male
	end
end

--- Determines
---@public
---@param npc tes3npcInstance The NPC to determine then race for
---@return string The race of the NPC
function this.getRace(npc)
	return npc.baseObject.race.id:lower()
end

return this
