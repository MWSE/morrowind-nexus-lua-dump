local self = require("openmw.self")
local types = require("openmw.types")

local hitchance = require("scripts.MD_HitAndMissIndicators.lib.hitchance")
local tooltip = require("scripts.MD_HitAndMissIndicators.lib.tooltip")
local sounds = require("scripts.MD_HitAndMissIndicators.lib.sounds")
local Options = require("scripts.MD_HitAndMissIndicators.lib.options")

local Detection = {
	STATES = {
		WAITING = 0,
		IN_SWING = 1,
		SWING_FINISHED = 2,
		HEALTH_DAMAGE_DEALT = 3,
		FATIGUE_DAMAGE_DEALT = 4,
		DAMAGE_COOLDOWN = 5
	},
	current = {
		state = 0,
		target = nil,
		cooldown = 0,
		startedHealth = 0,
		startedFatigue = 0,
		chanceToHit = 0
	}
}
Detection[Detection.STATES.WAITING] = function(_dt)
	if sounds.isSwooshPlaying(self) then
		local currentTarget = tooltip.getCurrentTarget(self)
		if currentTarget ~= nil
			and (types.NPC.objectIsInstance(currentTarget) or types.Creature.objectIsInstance(currentTarget))
			and types.Actor.stats.dynamic.health(currentTarget).current > 0
		then
			Detection.current.target = currentTarget
			Detection.current.startedHealth = types.Actor.stats.dynamic.health(Detection.current.target).current
			Detection.current.startedFatigue = types.Actor.stats.dynamic.fatigue(Detection.current.target).current
			Detection.current.chanceToHit = hitchance.calculate(self, Detection.current.target)
			Detection.current.state = Detection.STATES.IN_SWING
		end
	end
end
Detection[Detection.STATES.IN_SWING] = function(_dt)
	local healthDamagePlaying = sounds.isHealthDamagePlaying(Detection.current.target)
	local fatigueDamagePlaying = sounds.isFatigueDamagePlaying(Detection.current.target)

	if healthDamagePlaying or fatigueDamagePlaying then
		if healthDamagePlaying then
			Detection.current.state = Detection.STATES.HEALTH_DAMAGE_DEALT
		elseif fatigueDamagePlaying then
			Detection.current.state = Detection.STATES.FATIGUE_DAMAGE_DEALT
		end
	elseif not sounds.isSwooshPlaying(self) then
		Detection.current.state = Detection.STATES.SWING_FINISHED
		Detection.current.cooldown = Options.DELAY_AFTER_SWISH_BEFORE_MISS
	end
end
Detection[Detection.STATES.SWING_FINISHED] = function(dt)
	local healthDamagePlaying = sounds.isHealthDamagePlaying(Detection.current.target)
	local fatigueDamagePlaying = sounds.isFatigueDamagePlaying(Detection.current.target)

	if healthDamagePlaying or fatigueDamagePlaying then
		if healthDamagePlaying then
			Detection.current.state = Detection.STATES.HEALTH_DAMAGE_DEALT
		elseif fatigueDamagePlaying then
			Detection.current.state = Detection.STATES.FATIGUE_DAMAGE_DEALT
		end
	else
		Detection.current.cooldown = Detection.current.cooldown - dt
		if Detection.current.cooldown <= 0.0 then
			Detection.current.state = Detection.STATES.WAITING
			self:sendEvent('MD_OnAttackMiss', {
				target = Detection.current.target,
				chanceToHit = Detection.current.chanceToHit
			})
		end
	end
end
Detection[Detection.STATES.HEALTH_DAMAGE_DEALT] = function(_dt)
	Detection.current.state = Detection.STATES.DAMAGE_COOLDOWN

	local attackFinishedHealth = types.Actor.stats.dynamic.health(Detection.current.target).current
	local healthDelta = attackFinishedHealth - Detection.current.startedHealth
	self:sendEvent('MD_OnAttackHit', {
		target = Detection.current.target,
		damage = healthDelta,
		chanceToHit = Detection.current.chanceToHit
	})
end
Detection[Detection.STATES.FATIGUE_DAMAGE_DEALT] = function(_dt)
	Detection.current.state = Detection.STATES.DAMAGE_COOLDOWN

	local attackFinishedFatigue = types.Actor.stats.dynamic.fatigue(Detection.current.target).current
	local fatigueDelta = attackFinishedFatigue - Detection.current.startedFatigue
	self:sendEvent('MD_OnPunchHit', {
		target = Detection.current.target,
		damage = fatigueDelta,
		chanceToHit = Detection.current.chanceToHit
	})
end
Detection[Detection.STATES.DAMAGE_COOLDOWN] = function(_dt)
	if not sounds.isAnyDamagePlaying(Detection.current.target) then
		Detection.current.state = Detection.STATES.WAITING
		Detection.current.target = nil
	end
end
Detection.update = function(dt)
	Detection[Detection.current.state](dt)
end

return {
	engineHandlers = {
		onFrame = Detection.update
	}
}
