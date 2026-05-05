-- Fortify Casting using negative sound effect

local EFFECT_ID = "t_restoration_fortifycasting"

G.onMgefAdded[EFFECT_ID] = function(key, eff, activeSpell, entry)
	local mag = eff.magnitudeThisFrame or 0
	if mag <= 0 then return end
	activeEffects:modify(-mag, "sound")
	entry.magnitude = mag
	
	-- flag: removal onSave for safety
	entry.revertOnSave = true
end

G.onMgefRemoved[EFFECT_ID] = function(key, entry)
	if entry.magnitude then
		activeEffects:modify(entry.magnitude, "sound")
	end
end