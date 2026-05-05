G.onMgefAdded["us_scrib"] = function(key, eff, activeSpell, entry)
	core.sendGlobalEvent('TD_SpawnSummon', {
		spellId = activeSpell.id,
		effectId = "us_scrib",
		key = key,
		summoner = self,
		creatureId = "scrib_summon",
		activeSpellId = activeSpell.activeSpellId,
	})
end

G.onMgefRemoved["us_scrib"] = function(key, entry)
	core.sendGlobalEvent('TD_DespawnSummon', { key = key })
end