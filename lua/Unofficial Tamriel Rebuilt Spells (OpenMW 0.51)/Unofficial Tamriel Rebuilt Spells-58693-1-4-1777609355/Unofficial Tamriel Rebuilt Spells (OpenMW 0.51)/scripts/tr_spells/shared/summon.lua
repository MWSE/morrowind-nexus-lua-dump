-- Summoned creatures 

for _, effectId in pairs(trData.SUMMON_EFFECTS) do
	G.onMgefAdded[effectId] = function(key, eff, activeSpell, entry)
		core.sendGlobalEvent('TD_SpawnSummon', {
			spellId = activeSpell.id,
			effectId = effectId,
			key = key,
			summoner = self,
			creatureId = trData.SUMMON_CREATURES[effectId],
			activeSpellId = activeSpell.activeSpellId,
		})
		
		-- how to replicate illegalDaedra in openmw
		if isPlayer
			and ILLEGAL_DAEDRA_TOGGLE
			and self.cell:hasTag("NoSleep")
		then
			core.sendGlobalEvent('TD_DaedricSummonCrime', { player = self.object })
		end
	end
	
	G.onMgefRemoved[effectId] = function(key, entry)
		core.sendGlobalEvent('TD_DespawnSummon', { key = key })
	end
end

