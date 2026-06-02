local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

--- Encapsulates logic for loading NPCs from a cell
---@class npcLoader
local this = {}

--- Loads NPCs from the provided cell that have valid AI packages for conversations
---@public
---@return tes3npcInstance[]|nil npcs The loaded NPCs, or nil if none found
function this.load()
	local cell = tes3.getPlayerCell()
	if mcm.exteriorsOnly and cell.isInterior then
		return nil
	end

	local references = arrays.fromReferenceList(cell.actors)
	if table.size(references) < 2 then
		return nil
	end

	return this.getNpcsWithPackagesFromReferences(references)
end

---@private
---@param references tes3reference[]
---@return tes3npcInstance[]
function this.getNpcsWithPackagesFromReferences(references)
	---@type tes3npcInstance[]
	local npcs = {}
	for _, reference in pairs(references) do
		if reference.baseObject.objectType == tes3.objectType.npc then
			local npc = this.tryGetNpcWithValidPackage(reference --[[@as tes3npcInstance]])
			if npc then
				table.insert(npcs, npc)
			end
		end
	end
	return npcs
end

---@private
---@param npc tes3npcInstance
---@return tes3npcInstance|nil
function this.tryGetNpcWithValidPackage(npc)
	if not npc.mobile or not npc.mobile.aiPlanner then
		return nil
	end
	local package = npc.mobile.aiPlanner:getActivePackage()
	if not package then
		return nil
	end

	return npc
end

return this
