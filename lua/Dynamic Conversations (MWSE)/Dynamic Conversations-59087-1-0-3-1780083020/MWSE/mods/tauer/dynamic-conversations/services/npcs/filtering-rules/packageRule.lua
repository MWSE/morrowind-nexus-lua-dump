---@class statNpcRule : npcFilteringRule
local this = {}

this.name = "Package"

---@public
---@param npc tes3npcInstance
---@param configuration conversationConfiguration
function this.isMet(npc, configuration)
	local package = npc.mobile.aiPlanner:getActivePackage()

	if configuration.static then
		return this.isStatic(package)
	end

	return this.isWander(package)
end

---@private
---@param package tes3aiPackage
---@return boolean
function this.isStatic(package)
	local packageIsNone = package.type == tes3.aiPackage.none
	local packageIsWanderWithZeroDistance = package.type == tes3.aiPackage.wander and package.distance == 0

	return packageIsNone or packageIsWanderWithZeroDistance
end

---@private
---@param package tes3aiPackage
---@return boolean
function this.isWander(package)
	return package.type == tes3.aiPackage.wander and package.distance > 0
end

return this
