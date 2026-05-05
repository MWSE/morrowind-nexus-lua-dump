-- Kyne's Intervention teleports the player to the nearest Kyne marker when in skyrim.

G.onMgefAdded["t_intervention_kyne"] = function(key, eff, activeSpell)
	core.sendGlobalEvent('TD_KyneIntervention', self)
end
