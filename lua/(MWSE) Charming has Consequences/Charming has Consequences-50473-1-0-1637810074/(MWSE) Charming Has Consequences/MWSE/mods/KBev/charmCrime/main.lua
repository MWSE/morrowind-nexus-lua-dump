--Functions
---reportCrime: Sends a crime event in which the caster is the criminal, and their target is the victim. Force
local function reportCrime(effect)
	tes3.triggerCrime({ 
		criminal = effect.caster,
		type = tes3.crimeType.attack, 
		value = 30, 
		victim = effect.target 
	})
end

---isTargetNPC: Checks if the effect's target is an NPC
local function isTargetNPC(effect)
	--Failsafe in case effect is broken
	if (effect.target == nil) then
		return false
	end
	
	return (effect.target.object.objectType == tes3.objectType.npc)
end

--isEffectExpired: checks to see if an effect has expired (elapsed time >= effect duration)
local function isEffectExpired(e)
	eList = e.source.effects
	eIndex = e.effectIndex + 1
	return (e.effectInstance.timeActive >= eList[eIndex].duration)
end

--Events
---onSpellTick: checks to validate effect state, then reports crime if necessary
local function onSpellTick(e)
	if (not(e.target == e.caster)) and (isTargetNPC(e)) and (e.effectId == tes3.effect.charm) and (isEffectExpired(e)) then
		reportCrime(e)
	end
end

local function onInit()
	event.register("spellTick", onSpellTick)
end

--initialization
event.register("initialized", onInit)