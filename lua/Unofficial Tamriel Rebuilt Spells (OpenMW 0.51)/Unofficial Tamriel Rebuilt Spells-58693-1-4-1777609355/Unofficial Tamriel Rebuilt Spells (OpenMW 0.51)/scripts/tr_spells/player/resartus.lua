-- Resartus: armor/weapon repair

G.onMgefTick["t_restoration_armorresartus"] = function(key, eff, activeSpell, entry, interval)
	local mag = eff.magnitudeThisFrame * interval
	if math.random() < mag%1 then
		mag = mag + 1
	end
	core.sendGlobalEvent('TD_Resartus', {
		actor = self,
		kind = "armor",
		magnitude = math.floor(mag),
	})
end

G.onMgefTick["t_restoration_weaponresartus"] = function(key, eff, activeSpell, entry, interval)
	local mag = eff.magnitudeThisFrame * interval
	if math.random() < mag%1 then
		mag = mag + 1
	end
	core.sendGlobalEvent('TD_Resartus', {
		actor = self,
		kind = "weapon",
		magnitude = math.floor(mag),
	})
end