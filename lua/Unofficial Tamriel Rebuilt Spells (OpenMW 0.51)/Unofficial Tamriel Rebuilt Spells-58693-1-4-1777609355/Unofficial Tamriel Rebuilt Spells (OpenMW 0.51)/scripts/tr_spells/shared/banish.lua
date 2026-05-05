-- Banish Daedra does dmg to daedra, sends them back to oblivion, and spawns a sigil with their worldly possessions

local EFFECT_ID = "t_mysticism_banishdae"

-- check if daedra has a summoner
local function findSummoner()
	local summoner
	I.AI.forEachPackage(function(p)
		if p and p.type == "Follow" and p.target then
			summoner = p.target
		end
	end)
	if not summoner then return nil end
	for _, spell in pairs(types.Actor.activeSpells(summoner)) do
		if spell.caster and types.Player.objectIsInstance(spell.caster) then
			for _, eff in pairs(spell.effects) do
				if eff.id and eff.id:find("summon") then
					return summoner
				end
			end
		end
	end
	return nil
end

-- init spell data: target validation, summoner bonus and start accumulating magnitude
G.onMgefAdded[EFFECT_ID] = function(key, eff, activeSpell, entry)
	if not types.Creature.objectIsInstance(self) then return end
	local rec = types.Creature.record(self)
	if not rec or rec.type ~= types.Creature.TYPE.Daedra then return end
	
	entry.isTarget = true
	entry.totalMagnitude = 0
	
	-- own-summon bonus
	local caster = activeSpell and activeSpell.caster or nil
	local summoner = findSummoner()
	local isOwnSummon = summoner and caster and summoner == caster
	entry.mult = isOwnSummon and 2 or 1
	if isOwnSummon then
		entry.totalMagnitude = 10
	end
	
	-- area burst VFX for extra wumms
	local area = eff.area or 0
	if area > 0 then
		local areaStatic = eff.effect and eff.effect.areaStatic or nil
		local areaRec = areaStatic and types.Static.records[areaStatic] or nil
		if areaRec then
			core.sendGlobalEvent('SpawnVfx', {
				model = areaRec.model,
				position = self.position,
				options = { scale = area * 1.1 },
			})
		end
	end
end

-- dmg per tick, magnitude accumulates for banishing chance
G.onMgefTick[EFFECT_ID] = function(key, eff, activeSpell, entry, interval)
	if not entry.isTarget then return end
	if entry.banished then return end
	
	local baseMag = eff.magnitudeThisFrame or entry.avgMagnitude or 10
	local tickMag = baseMag * interval * entry.mult
	
	local health = types.Actor.stats.dynamic.health(self)
	health.current = health.current - tickMag * 0.9
	
	-- accumulate banishing threshold
	entry.totalMagnitude = entry.totalMagnitude + tickMag
	
	local myLevel = types.Actor.stats.level(self).current
	local healthMod = health.current / math.max(health.base, 1)
	local threshold = (myLevel / 2) + ((myLevel / 2) * healthMod)
	
	if entry.totalMagnitude >= threshold then
		entry.banished = true
		types.Actor.stats.dynamic.health(self).current = 0
		local banishVfx = types.Static.records["t_vfx_banish"]
		if banishVfx then animation.addVfx(self, banishVfx.model) end
		core.sound.playSound3d("mysticism area", self)
		async:newUnsavableSimulationTimer(0.8, function()
			core.sendGlobalEvent('TD_BanishDelete', { actor = self.object, caster = activeSpell.caster })
		end)
	end
end