local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local anim = require('openmw.animation')

local player = nil
local playerHealth = nil
local nextUpdate = 0
local hasVfx = false
local isNPC = types.NPC.objectIsInstance(self)
local actorHealth = types.Actor.stats.dynamic.health(self)
local actorLuck = types.Actor.stats.attributes["luck"](self)
local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.DamageHealth]
local model = types.Static.records[effect.hitStatic].model

local function onUpdate()
	if not player or types.Actor.isDead(self) then
		if hasVfx then
			anim.removeVfx(self, "rogueliteWitheringAuraVfx")
			hasVfx = false
		end
		return
	end
	local now = core.getSimulationTime()
	if now < nextUpdate then return end
	nextUpdate = now + 1

	local distance = (self.position - player.position):length()
	local mitigation = 0.25
	if isNPC then
		local luck = actorLuck.modified
		mitigation = math.max(mitigation, luck / (luck + 100))
	end
	if not playerHealth then
		playerHealth = types.Actor.stats.dynamic.health(player)
	end
	local damageAmount = playerHealth.current * 0.03 * math.max(0.2, 1 - distance / 1000) * (1 - mitigation)
	if damageAmount > 0 then
		actorHealth.current = math.max(0, actorHealth.current - damageAmount)
		if not hasVfx then
			anim.addVfx(self, model, {loop = true, vfxId = "rogueliteWitheringAuraVfx"})
			hasVfx = true
		end
	elseif hasVfx then
		anim.removeVfx(self, "rogueliteWitheringAuraVfx")
		hasVfx = false
	end
end

local function setPlayer(p)
	player = p
	playerHealth = nil
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
	},
	eventHandlers = {
		Roguelite_setWitherPlayer = setPlayer,
	}
}
