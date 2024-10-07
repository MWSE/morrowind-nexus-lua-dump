---@param e magicEffectRemovedEventData
event.register(tes3.event.magicEffectRemoved, function(e)
	if e.effect.id == tes3.effect.fireShield or e.effect.id == tes3.effect.frostShield or e.effect.id == tes3.effect.lightningShield then
		e.mobile.shield = e.mobile.shield - e.effectInstance.magnitude
		e.effectInstance.cumulativeMagnitude = 0	-- The event *might* trigger when it shouldn't, so this ensures that the effect can be reapplied if that actually happens
	end
end)

---@param e spellTickEventData
event.register(tes3.event.spellTick, function(e)
	if e.effectInstance.cumulativeMagnitude ~= -1 and e.effectInstance.magnitude > 0 then	-- Just checking whether no time has passed since the effect began doesn't work, since the magnitude isn't actually calculated until after the first tick
		if e.effect.id == tes3.effect.fireShield or e.effect.id == tes3.effect.frostShield or e.effect.id == tes3.effect.lightningShield then
			e.target.mobile.shield = e.target.mobile.shield + e.effectInstance.magnitude
			e.effectInstance.cumulativeMagnitude = -1	-- cumulativeMagnitude doesn't (shouldn't) do anything for custom effects, so it is used to track whether the effect has been applied to the target's shield value
		end
	end
end)