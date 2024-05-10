local seph = require("seph")
local blackSoulGem = require("seph.npcSoulTrapping.blackSoulGem")
local interop = require("seph.npcSoulTrapping.interop")

local creatureSoulTrap = seph.Module()

---@param creatureId string
function creatureSoulTrap.requiresBlackSoulGem(creatureId)
	local config = creatureSoulTrap.mod.config.current
	return config.blackSoulGem.required and (config.creatureExceptions[creatureId:lower()] or interop.creatureExceptions[creatureId:lower()])
end

---@param eventData filterSoulGemTargetEventData
function creatureSoulTrap.onFilterSoulGemTarget(eventData)
	local canSoulTrapCreatures = creatureSoulTrap.mod.config.current.blackSoulGem.canSoulTrapCreatures
	local isBlackSoulGem = blackSoulGem.isBlackSoulGem(eventData.soulGem)
	if creatureSoulTrap.requiresBlackSoulGem(eventData.reference.baseObject.id) then
		eventData.filter = isBlackSoulGem
	elseif not canSoulTrapCreatures and isBlackSoulGem then
		eventData.filter = false
	end
end

function creatureSoulTrap:onEnabled()
	event.register(tes3.event.filterSoulGemTarget, self.onFilterSoulGemTarget)
end

function creatureSoulTrap:onDisabled()
	event.unregister(tes3.event.filterSoulGemTarget, self.onFilterSoulGemTarget)
end

return creatureSoulTrap