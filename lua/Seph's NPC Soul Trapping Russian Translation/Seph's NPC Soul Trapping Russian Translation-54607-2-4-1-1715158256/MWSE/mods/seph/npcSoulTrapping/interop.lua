local seph = require("seph")

local interop = seph.Module()

interop.blackSoulGems = {}
interop.npcSouls = {}
interop.npcExceptions = {}
interop.creatureExceptions = {}

--- Adds a black soul gem. These soul gems can be used to trap NPC souls. Only has any effect if black soul gems have been set as a requirement for trapping NPC souls in the config menu by the user.
---@param soulGem tes3misc|string The soul gem to be added. This must be a misc item.
---@return boolean success Returns true if the black soul gem has been added successfully. Returns false if the provided soulGem is not a misc item.
function interop.addBlackSoulGem(soulGem)
	if type(soulGem) == "string" then
		soulGem = tes3.getObject(soulGem)
	end

	if not soulGem or soulGem.objectType ~= tes3.objectType.miscItem then
		return false
	end

	if not soulGem.isSoulGem then
		tes3.addSoulGem{item = soulGem}
	end

	interop.blackSoulGems[soulGem.id:lower()] = true
	return true
end

--- Adds a custom soul value for an NPC. This will bypass regular calculation of the soul value for NPCs and use the soul value provided instead.
---@param npcId string The base object ID of the NPC.
---@param soul number The soul value to use for the NPC.
function interop.addNpcSoul(npcId, soul)
	interop.npcSouls[npcId:lower()] = soul
end

--- Adds an NPC exception. These NPCs will not require a black soul gem to be soul trapped. This does not change their soul value. Only has any effect if black soul gems have been set as a requirement for trapping NPC souls in the config menu by the user. These exceptions will not be shown to the user in the MCM.
---@param npcId string The base object ID of the NPC.
function interop.addNpcException(npcId)
	interop.npcExceptions[npcId:lower()] = true
end

--- Adds a creature exception. These creatures will require a black soul gem to be soul trapped. This does not change their soul value. Only has any effect if black soul gems have been set as a requirement for trapping NPC souls in the config menu by the user. These exceptions will not be shown to the user in the MCM.
---@param creatureId string The base object ID of the creature.
function interop.addCreatureException(creatureId)
	interop.creatureExceptions[creatureId:lower()] = true
end

return interop