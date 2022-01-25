local common = require("Neph.Power Fantasy.common")
local p, pMob

-- power timer registration and callbacks
local function bsPowerRecharge()
	pMob:rechargePower(tes3.getObject(p.data.neph[50]))
	tes3.messageBox("Your birthsign power has recharged.")
end
local function racePowerRecharge()
	pMob:rechargePower(tes3.getObject(p.data.neph[51]))
	tes3.messageBox("Your racial power has recharged.")
end
if common.rbs then
	timer.register("powerFantasy:racePowerTimer", racePowerRecharge)
	timer.register("powerFantasy:bsPowerTimer", bsPowerRecharge)
end


local function onEffect(e)

	local tRef		= e.target
	local tMob		= tRef.mobile
	local spell		= e.source

	-- Paralysis nerf
	if spell:getFirstIndexOfEffect(45) >= 0 and not spell.id == "_neph_perk_10_freeze" then
		if 0.0075*tMob.willpower.current >= math.random() then
			e.resistedPercent = 100
		end
	elseif spell.id == "_neph_perk_10_freeze" then
		if 0.01*tMob.resistFrost >= math.random() then
			e.resistedPercent = 100
		end
	end

	if e.sourceInstance.sourceType == 3 then return end
	
	local aRef		= e.caster
	if not aRef then return end
	local aMob		= aRef.mobile
	local effectId	= e.effect.id
	local spellDur
	local spellMax
	local spellMin
	local index		= 0
	local temp		= 0
	
	if common.rbs then
	
		-- Lord Star Guardian: Gain +90% reistance to all magic
		if tMob:isAffectedByObject(tes3.getObject("_neph_bs_lor_pwGuardian")) and aRef ~= tRef then
			e.resistedPercent = e.resistedPercent + 90
		end
		
		-- Nord: Storm Voice knockdown
		if spell.id == "_neph_race_no_pwBattleCry" then
			if math.min(0.01*tMob.sanctuary, 1) <= math.random() and tRef.data.neph[96] == 0 then
				common.scriptDmg.aRef	= aRef
				common.scriptDmg.aMob	= aMob
				common.scriptDmg.tMob	= tMob
				common.scriptDmg.dir	= 2
				common.scriptDmg.swing	= 1
				common.scriptDmg.weap	= -2
				tMob:applyDamage{damage = 20 + 2*aRef.object.level, applyArmor = false}
				if math.min(0.01*tMob.sanctuary, 1) <= math.random() then
					tRef.data.neph[96] = 1
				end
			end
		end
		
		-- Apprentice: doubled spell effects during Zeal power
		if aMob:isAffectedByObject(tes3.getObject("_neph_bs_app_pwZeal")) and spell.castType ~= 5 then
			local selfEffect = spell.effects
			for i = 1, #selfEffect do
				temp = 0
				for id in pairs(common.apprBlacklist) do
					if selfEffect[i].id == id then temp = 1 end
				end
				if temp == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Apprentice's Zeal Bonus",
						effects = {{
							id			= selfEffect[i].id,
							duration	= selfEffect[i].duration,
							rangeType	= tes3.effectRange.self,
							min			= selfEffect[i].min,
							max			= selfEffect[i].max
						}}
					}
				end
			end
		end
		
		-- Ritual prolonged summons		
		if aRef.data.neph[99] == "Ritual" then
			for effect, name in pairs(common.summonID) do
				for i = 1, #spell.effects do
					if spell.effects[i].id == effect then
						timer.delayOneFrame(function()
							tes3.removeEffects{reference = aRef, effect = effect}
							tes3.applyMagicSource{
								reference = aRef,
								name = "Summon " .. name,
								effects = {{id = effect, duration = e.source.effects[i].duration*2}}
							}
						end)
					end
				end
			end
		end
	end
	
	-- Block 60: Resist magic damage while raising shield (player only)
	if common.skills and aRef ~= p and tRef == p then
		if pMob.block.base >= 60 and p.data.neph[94] == 1 and p.data.neph[11] >= 0 then
			local hit = tes3.rayTest{
				position = tes3.getCameraPosition(),
				direction = {
					-1*tes3.getCameraVector().x,
					-1*tes3.getCameraVector().y,
					-1*tes3.getCameraVector().z
				}
			}
			if hit.intersection:distance(aRef.position) > hit.intersection:distance(tRef.position) then
				e.resistedPercent = e.resistedPercent + pMob.block.base
			end
		end
	end
	
	-- Skill stuff
	--------------
	if aMob.actorType > 0 then
			
		-- Conjuration summon restriction (player-only)
		---------------------------------		
		if tRef == p then
		
			-- restricted to one summon
			if pMob.conjuration.base < 90 and p.data.neph[99] ~= "Ritual" then
				for toDelete in pairs(common.summonID) do
					if tes3.isAffectedBy{reference = p, effect = toDelete} then
						tes3.removeEffects{reference = p, effect = toDelete}
					end
				end
			end
			
			-- spell names used to store persistent string data (LOL)
			local data1 = tes3.getObject("_neph_data_SummonRestriction_1")
			local data2 = tes3.getObject("_neph_data_SummonRestriction_2")
			local data3 = tes3.getObject("_neph_data_SummonRestriction_3")
			
			for effect, lastSummon in pairs(common.summonID) do
				for i = 1, #spell.effects do
					if spell.effects[i].id == effect then
						data3.name = data2.name
						data3.modified = true
						data2.name = data1.name
						data2.modified = true
						data1.name = lastSummon
						data1.modified = true
					end
				end
			end
			
			-- restricted to two summons
			if (pMob.conjuration.base >= 90 and p.data.neph[99] ~= "Ritual") or (pMob.conjuration.base < 90 and p.data.neph[99] == "Ritual") then
				for toDelete, lastSummon in pairs(common.summonID) do
					if data2.name == lastSummon or data1.name == data2.name then
					else
						if tes3.isAffectedBy{reference = p, effect = toDelete} then
							tes3.removeEffects{reference = p, effect = toDelete}
						end
					end
				end
			end
			
			-- restricted to three summons
			if pMob.conjuration.base >= 90 and p.data.neph[99] == "Ritual" then
				for toDelete, lastSummon in pairs(common.summonID) do
					if data2.name == lastSummon or data3.name == lastSummon or data1.name == data2.name or data2.name == data3.name or data1.name == data3.name then -- do nothing
					else
						if tes3.isAffectedBy{reference = p, effect = toDelete} then
							tes3.removeEffects{reference = p, effect = toDelete}
						end
					end
				end
			end
		end			
							
		-- Illusion: Level-dependent effects
		------------
		-- Command crime
		for i = 1, #spell.effects do
			if spell.effects[i].id == 119 then
				if aRef.data.neph[99] ~= "Lover" then
					tes3.triggerCrime{type = 1, victim = tMob, forceDetection = false}
				end
			end
			if spell.effects[i].id == 118 then
				if aRef.data.neph[99] ~= "Lover" and tMob.aiPlanner:getActivePackage().type == 3 then
					tes3.triggerCrime{type = 1, victim = tMob, forceDetection = false}
				end
			end
		end
		
		temp = 0
		local loverBonus = 1
		if aRef.data.neph[99] == "Lover" then
			loverBonus = 1.25
		end
		-- Illusion 90: Can mind control daedra, undead and automatons
		if ((common.skills and aMob.illusion.base < 90) or not common.skills)
		and (tRef.object.type == tes3.creatureType.daedra or tRef.object.type == tes3.creatureType.undead or string.find(tRef.object.id, "centurion")) then
			temp = 1
		end

		-- Calm
		index = spell:getFirstIndexOfEffect(49) + 1
		if index > 0 then
			spellMin = spell.effects[index].min
			spellMax = spell.effects[index].max
			if temp == 0 and math.random(spellMin, spellMax) * (1 - 0.01*tMob.resistMagicka) * loverBonus >= tRef.object.level then
				spellDur = spell.effects[index].duration
				if tMob.actorType == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "calm",
						effects = {{id = 50, duration = spellDur, min = 100, max = 100}}
					}
				else
					tes3.applyMagicSource{
						reference = tRef,
						name = "calm",
						effects = {{id = 49, duration = spellDur, min = 100, max = 100}}
					}
				end
				if common.skills and aMob.illusion.base >= 60 then
					local weaken = tes3.getObject("_neph_perk_12_weaken").effects
					for i = 1, 8 do
						weaken[i].duration	= spellDur
						weaken[i].min		= 0.5*spellMin
						weaken[i].max		= 0.5*spellMax
					end
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_perk_12_weaken"
					}
				end
			else
				e.resistedPercent = 100
			end
		end
		
		-- Frenzy
		index = spell:getFirstIndexOfEffect(51) + 1
		if index > 0 then
			if (tMob.actorType > 0 or (tMob.actorType == 0 and tMob.aiPlanner:getActivePackage().type == 3)) and aRef.data.neph[99] ~= "Lover" then
				tes3.triggerCrime{type = 1, victim = tMob, forceDetection = false}
			end
			spellMin = spell.effects[index].min
			spellMax = spell.effects[index].max
			if temp == 0 and math.random(spellMin, spellMax) * (1 - 0.01*tMob.resistMagicka) * loverBonus >= tRef.object.level then
				for _, cell in pairs(tes3.getActiveCells()) do
					for actor in tes3.iterate(cell.actors) do
						if actor.mobile and not actor.disabled then
							if not actor.mobile.isDead and actor ~= tRef and tRef.position:distance(actor.position) < 884 then
								mwscript.startCombat{reference = tRef, target = actor}
							end
						end
					end
				end
				spellDur = spell.effects[index].duration
				if tMob.actorType == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "frenzy",
						effects = {{id = 52, duration = spellDur, min = 100, max = 100}}
					}
				else
					tes3.applyMagicSource{
						reference = tRef,
						name = "frenzy",
						effects = {{id = 51, duration = spellDur, min = 100, max = 100}}
					}
				end
				if common.skills and aMob.illusion.base >= 60 then
					local weaken = tes3.getObject("_neph_perk_12_weaken").effects
					for i = 1, 8 do
						weaken[i].duration	= spellDur
						weaken[i].min		= 0.5*spellMin
						weaken[i].max		= 0.5*spellMax
					end
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_perk_12_weaken"
					}
				end
			else
				e.resistedPercent = 100
			end
		end
		
		-- Demoralize
		index = index + spell:getFirstIndexOfEffect(53) + 1
		if index > 0 then
			spellMin = spell.effects[index].min
			spellMax = spell.effects[index].max
			if temp == 0 and math.random(spellMin, spellMax) * (1 - 0.01*tMob.resistMagicka) * loverBonus >= tRef.object.level then
				spellDur = spell.effects[index].duration
				if tMob.actorType == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "demoralize",
						effects = {{id = 54, duration = spellDur, min = 100, max = 100}}
					}
				else
					tes3.applyMagicSource{
						reference = tRef,
						name = "demoralize",
						effects = {{id = 53, duration = spellDur, min = 100, max = 100}}
					}
				end
				if common.skills and aMob.illusion.base >= 60 then
					local weaken = tes3.getObject("_neph_perk_12_weaken").effects
					for i = 1, 8 do
						weaken[i].duration	= spellDur
						weaken[i].min		= 0.5*spellMin
						weaken[i].max		= 0.5*spellMax
					end
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_perk_12_weaken"
					}
				end
			else
				e.resistedPercent = 100
			end
		end
		
		-- Rally
		index = spell:getFirstIndexOfEffect(55) + 1
		if index > 0 then
			spellMin = spell.effects[index].min
			spellMax = spell.effects[index].max
			if temp == 0 and math.random(spellMin, spellMax) * (1 - 0.01*tMob.resistMagicka) * loverBonus >= tRef.object.level then
				spellDur = spell.effects[index].duration
				if tMob.actorType == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "rally",
						effects = {{id = 56, duration = spellDur, min = 100, max = 100}}
					}
				else
					tes3.applyMagicSource{
						reference = tRef,
						name = "rally",
						effects = {{id = 55, duration = spellDur, min = 100, max = 100}}
					}
				end
				if common.skills and aMob.illusion.base >= 60 then
					local strengthenR = tes3.getObject("_neph_perk_12_strengthen").effects
					for i = 1, 8 do
						strengthenR[i].duration	= spellDur
						strengthenR[i].min		= 0.5*spellMin
						strengthenR[i].max		= 0.5*spellMax
					end
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_perk_12_strengthen"
					}
				end
			else
				e.resistedPercent = 100
			end
		end
		
		if common.skills then
		
			-- Mysticism 60: Teleportation heals
			if aMob.mysticism.base >= 60 then
			
				-- Recall
				if spell:getFirstIndexOfEffect(61) >= 0 then
					tes3.applyMagicSource{
						reference = aRef,
						name = "Recall Refreshment",
						effects = {
							{id = 75, min = 0.25*aMob.health.base, max = 0.25*aMob.health.base},
							{id = 77, min = 0.25*aMob.fatigue.base, max = 0.25*aMob.fatigue.base},
							{id = 76, min = 0.25*aMob.magicka.base, max = 0.25*aMob.magicka.base}
						}
					}
				end
				
				-- Divine and Almsivi Intervention
				for i = 62, 63 do
					if spell:getFirstIndexOfEffect(i) >= 0 then
						tes3.applyMagicSource{
							reference = aRef,
							name = "Divine Cleansing",
							effects = {
								{id = 75, min = aMob.health.base, max = aMob.health.base},
								{id = 77, min = aMob.fatigue.base, max = aMob.fatigue.base},
								{id = 76, min = aMob.magicka.base, max = aMob.magicka.base},
								{id = 69},
								{id = 70}
							}
						}
					end
				end
			end
			
			-- Unarmored 30: Shields grant up to +20% extra protection per unarmored body part (double for chest and head)
			if aMob:getSkillValue(17) >= 30 and spell.castType ~= 5 then
			
				local alt = aMob:getSkillValue(17)

				index = spell:getFirstIndexOfEffect(3) + 1
				if index > 0 then
					if e.sourceInstance.sourceType == 2 then
						if spell.castType == tes3.enchantmentType.constant then
							return
						end
					end
					temp = 0
					for i = 0, 10 do
						if i ~= 8 and tRef.data.neph[i] == -1 then
							temp = temp + 0.1
							if i <= 1 then
								temp = temp + 0.1
							end
							if i == 9 and tRef.data.neph[6] == -1 then
								temp = temp - 0.1
							end
							if i == 10 and tRef.data.neph[7] == -1 then
								temp = temp - 0.1
							end
						end
					end
					spellDur = spell.effects[index].duration
					spellMax = spell.effects[index].max * 0.02*alt * temp
					spellMin = spell.effects[index].min * 0.02*alt * temp
					tes3.applyMagicSource{
						reference = aRef,
						name = "Unarmored Shield Bonus",
						effects = {{id = 3, duration = spellDur, min = spellMin, max = spellMax}}
					}
				end
			end
		end
		
		-- Restoration 30: Restore and absorb spells are up to twice as strong the lower the corresponding resource
		if aMob:getSkillValue(15) >= 30 and spell.castType ~= 5 and spell.id ~= "_neph_perk_08_combatBonus" then
		
			local rest = 0.01*aMob:getSkillValue(15)
			
			-- Restore Health
			index = spell:getFirstIndexOfEffect(75) + 1
			if index > 0 and tMob.health.normalized < 1 then
				if e.sourceInstance.sourceType == 2 then
					if spell.castType == tes3.enchantmentType.constant then
						return
					end
				end
				spellDur = spell.effects[index].duration
				spellMax = spell.effects[index].max * (1 - tMob.health.normalized) * rest
				spellMin = spell.effects[index].min * (1 - tMob.health.normalized) * rest
				tes3.applyMagicSource{
					reference = tRef,
					name = "Extra Health Restoration",
					effects = {{id = 75, duration = spellDur, min = spellMin, max = spellMax}}
				}
			end
			
			-- Restore Fatigue
			index = spell:getFirstIndexOfEffect(77) + 1
			if index > 0 and tMob.fatigue.normalized < 1 then
				if e.sourceInstance.sourceType == 2 then
					if spell.castType == tes3.enchantmentType.constant then
						return
					end
				end
				spellMax = spell.effects[index].max * (1 - tMob.fatigue.normalized) * rest
				spellMin = spell.effects[index].min * (1 - tMob.fatigue.normalized) * rest
				spellDur = spell.effects[index].duration
				tes3.applyMagicSource{
					reference = tRef,
					name = "Extra Fatigue Restoration",
					effects = {{id = 77, duration = spellDur, min = spellMin, max = spellMax}}
				}
			end
			
			-- Absorb Health
			index = spell:getFirstIndexOfEffect(86) + 1
			if index > 0 and tMob.health.normalized < 1 then
				spellDur = spell.effects[index].duration
				spellMax = spell.effects[index].max * (1 - tMob.health.normalized) * rest
				spellMin = spell.effects[index].min * (1 - tMob.health.normalized) * rest
				tes3.applyMagicSource{
					reference = aRef,
					name = "Extra Health Absorption",
					effects = {{id = 75, duration = spellDur, min = spellMin, max = spellMax}}
				}
			end
			
			-- Absorb Magicka
			index = spell:getFirstIndexOfEffect(87) + 1
			if index > 0 and tMob.magicka.normalized < 1 then
				spellDur = spell.effects[index].duration
				spellMax = spell.effects[index].max * (1 - tMob.magicka.normalized) * rest
				spellMin = spell.effects[index].min * (1 - tMob.magicka.normalized) * rest
				tes3.applyMagicSource{
					reference = aRef,
					name = "Extra Magicka Absorption",
					effects = {{id = 76, duration = spellDur, min = spellMin, max = spellMax}}
				}
			end
			
			-- Absorb Fatigue
			index = spell:getFirstIndexOfEffect(88) + 1
			if index > 0 and tMob.fatigue.normalized < 1 then
				spellDur = spell.effects[index].duration
				spellMax = spell.effects[index].max * (1 - tMob.fatigue.normalized) * rest
				spellMin = spell.effects[index].min * (1 - tMob.fatigue.normalized) * rest
				tes3.applyMagicSource{
					reference = aRef,
					name = "Extra Fatigue Absorption",
					effects = {{id = 77, duration = spellDur, min = spellMin, max = spellMax}}
				}
			end
		end
	end
	
	-- Spell evasion
	if common.skills and tMob.object.objectType == tes3.objectType.npc and tMob.lightArmor.base >= 30 and tMob.hasFreeAction and aRef ~= tRef then
		
		local lAFac	= 0	-- Factor for light armor 30
		local temp = 0

		-- Light Armor 30: Harder to hit, jumping and/or dashing per piece (double for helmet and cuirass)
		if tMob.isRunning then
			temp = temp + 1
		end
		if tMob.isJumping or tMob.isFalling then
			temp = temp + 1
		end
		if tRef == p and p.data.neph[98] == 3 then
			temp = temp + 1
		end
		-- LA 60: Harder to hit when low
		if tMob.lightArmor.base >= 60 and tMob.health.normalized < 1 then
			temp = temp + 3 * (1 - tMob.health.normalized)
		end
		for i = 0, 10 do
			if i == 9 and tRef.data.neph[6] <= 0 then -- do nothing
			elseif i == 10 and tRef.data.neph[7] <= 0 then -- do nothing
			elseif i ~= 8 and tRef.data.neph[i] <= 0 then
				lAFac = lAFac + 0.0001*tMob.lightArmor.current*temp
				if i <= 1 then
					lAFac = lAFac + 0.0001*tMob.lightArmor.current*temp
				end
			end
		end
		if lAFac - 0.005*aMob.attackBonus >= math.random() then
			e.resistedPercent = 100
			--tes3.messageBox("actor evasion chance: %f", lAFac - 0.005*aMob.attackBonus)
		end
		
	elseif common.config.creaPerks and tMob.actorType == 0 and tMob.hasFreeAction then
		if string.find(tRef.object.id, "scamp") or tRef.object.id == "lustidrike" then
			if 0.65 + 0.005*aMob.attackBonus <= math.random() then
				e.resistedPercent = 100
			end
		end
	end
end
event.register("spellResist", onEffect)


local function onCast(e)
		
	local ref		= e.caster
	local mob		= ref.mobile
	if not mob then return end
	local spell		= e.source
	local id		= spell.id
	local effects	= spell.effects
	local lvl		= ref.object.level
	
	-- Fortify Attack cast chance increase
	if mob.attackBonus > 0 then
		e.castChance = e.castChance + mob.attackBonus
	end
	
	if common.rbs then
	
		-- Altmer: +25% cast chance
		if ref.object.race and ref.object.race.id:lower() == "high elf" then
			e.castChance = e.castChance + 25
		end
	
		-- Mage: Magicka Surge, can't fail spells for 20s
		if mob:isAffectedByObject(tes3.getObject("_neph_bs_mag_pwSurge")) then
			e.castChance = 100
		end
		
		-- scaling powers
		-----------------
		if spell.castType == 5 then
		
			-- High Elf
			if id == "_neph_race_he_pwRush" then
				effects[1].min = 0.1*mob.magicka.base
				effects[1].max = 0.1*mob.magicka.base
			-- Argonian
			elseif id == "_neph_race_ar_pwHistCall" then
				effects[1].min = 0.1*mob.health.base
				effects[1].max = 0.1*mob.health.base
				effects[2].min = 0.1*mob.magicka.base
				effects[2].max = 0.1*mob.magicka.base
				effects[3].min = 0.1*mob.fatigue.base
				effects[3].max = 0.1*mob.fatigue.base
			-- Bosmer and Imperial
			elseif id == "_neph_race_we_pwTongue" or id == "_neph_race_im_pwVoiceEmp" then
				effects[1].duration = math.ceil(28800/tes3.worldController.timescale.value)
				effects[1].min = lvl + 5
				effects[1].max = lvl + 5
			-- Lover and Nord
			elseif id == "_neph_bs_lov_pwPresence" or id == "_neph_race_no_pwBattleCry" then
				effects[1].max = 5 + lvl
				effects[1].min = 5 + lvl
				effects[1].duration = math.ceil(7200/tes3.worldController.timescale.value)
				effects[2].duration = math.ceil(7200/tes3.worldController.timescale.value)
			-- Redguard
			elseif id == "_neph_race_rg_pwAdrenaline" then
				effects[2].max = 0.1 * mob.fatigue.base
				effects[2].min = 0.1 * mob.fatigue.base
			-- Breton
			elseif id == "_neph_race_br_pwDragonSkin" then
				effects[1].min = 25 + lvl
				effects[1].max = 25 + lvl
				effects[2].min = math.min(5 + 0.2*lvl, 15)
				effects[2].max = math.min(5 + 0.2*lvl, 15)
				effects[3].min = math.min(20 + 0.8*lvl, 60)
				effects[3].min = math.min(20 + 0.8*lvl, 60)
				for i = 4, 5 do
					effects[i].min = math.min(25 + lvl, 75)
					effects[i].max = math.min(25 + lvl, 75)
				end
			-- Dunmer
			elseif id == "_neph_race_de_pwAncGuardP" then
				local AncGuardP = tes3.getObject("_neph_race_de_pwGuardianAbP").effects
				AncGuardP[1].max = 2*p.object.level
				AncGuardP[1].min = 2*p.object.level
				for i = 2, 7 do
					AncGuardP[i].min = p.object.level
					AncGuardP[i].max = p.object.level
				end
			elseif id == "_neph_race_de_pwAncGuardNPC" then
			-- this one gets reset by every other dunmer NPC casting the power, so it might weaken/strengthen already existing NPC Ancestor Guardians
			-- that's why we made two separate versions of this power in the first place (that and checking aiPackageFollow didn't provide satisfying results...)
				local AncGuardNPC = tes3.getObject("_neph_race_de_pwGuardianAb").effects
				AncGuardNPC[1].max = 2*ref.object.level
				AncGuardNPC[1].min = 2*ref.object.level
				for i = 2, 7 do
					AncGuardNPC[i].min = ref.object.level
					AncGuardNPC[i].max = ref.object.level
				end
			-- Thief
			elseif id == "_neph_bs_thi_pwHeist" then
				for i = 1, 4 do
					effects[i].duration = math.ceil(7200/tes3.worldController.timescale.value)
				end
			-- Lord
			elseif id == "_neph_bs_lor_pwGuardian" then
				effects[1].min = 0.1*mob.health.base
				effects[1].max = 0.1*mob.health.base
			-- Warrior, Serpent and Orc
			elseif id == "_neph_bs_war_pwMight" or id == "_neph_bs_ser_pwFangs" or id == "_neph_race_or_pwBerserk" or id == "_neph_bs_mag_pwSurge" then
				effects[1].min = 10 + lvl
				effects[1].max = 10 + lvl
			-- Lady
			elseif id == "_neph_bs_lad_pwGift" then
				for i = 1, 3 do
					effects[i].max = 20 + 2*lvl
					effects[i].min = 20 + 2*lvl
				end
			-- Atronach
			elseif id == "_neph_bs_atr_pwOverload" then
				effects[1].max = mob.magicka.base
				effects[1].min = mob.magicka.base
				local overload = tes3.getObject("_neph_bs_atr_pwOverloadOnHit").effects
				overload[1].max = 0.2*mob.magicka.base
				overload[1].min = 0.2*mob.magicka.base
			end
			
			-- scaling power cooldown timers
			if ref == p then
				if p.data.neph[50] and id == p.data.neph[50] then
					timer.start{
						type = timer.game,
						persist = true,
						duration = math.max(24 - 0.24*lvl, 8),
						callback = "powerFantasy:bsPowerTimer"
					}
				end
				if p.data.neph[51] and id == p.data.neph[51] then
					timer.start{
						type = timer.game,
						persist = true,
						duration = math.max(24 - 0.24*lvl, 8),
						callback = "powerFantasy:racePowerTimer"
					}
				end
			end
		end
		
		-- Dunmer Combat Stance toggle
		if id == "_neph_race_de_togConvMag" then
			if not mob:isAffectedByObject(tes3.getObject("_neph_race_de_togConvMagAb")) then
				tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_race_de_togConvMagAb")}
			else
				tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_race_de_togConvMagAb")}
			end	
		-- Khajiit Cat Eyes toggle
		elseif id == "_neph_race_kh_togCatEyes" then
			if not mob:isAffectedByObject(tes3.getObject("_neph_race_kh_togCatEyesAb")) then
				tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_race_kh_togCatEyesAb")}
			else
				tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_race_kh_togCatEyesAb")}
			end
		-- Tower Sentry Toggle
		elseif id == "_neph_bs_tow_splSentry" then
			if not mob:isAffectedByObject(tes3.getObject("_neph_bs_tow_splSentryAb")) then
				tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_bs_tow_splSentryAb")}
			else
				tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_bs_tow_splSentryAb")}
			end
		end
	end
	
	if common.skills then
	
		-- H2H 90: Toggleable elemental damage on hit
		if mob:getSkillValue(26) >= 90 then
			if id == "_neph_perk_26_shockToggle" then
				if not mob:isAffectedByObject(tes3.getObject("_neph_perk_26_shockToggleAb")) then
					tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_shockToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_fireToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_frostToggleAb")}
				else
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_shockToggleAb")}
				end
			elseif id == "_neph_perk_26_fireToggle" then
				if not mob:isAffectedByObject(tes3.getObject("_neph_perk_26_fireToggleAb")) then
					tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_fireToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_shockToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_frostToggleAb")}
				else
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_fireToggleAb")}
				end
			elseif id == "_neph_perk_26_frostToggle" then
				if not mob:isAffectedByObject(tes3.getObject("_neph_perk_26_frostToggleAb")) then
					tes3.addSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_frostToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_shockToggleAb")}
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_fireToggleAb")}
				else
					tes3.removeSpell{reference = ref, spell = tes3.getObject("_neph_perk_26_frostToggleAb")}
				end
			end
		end
		
		-- Acrobatics 30: Can cast while jumping (this handles blocking it before)
		if pMob.acrobatics.base < 30 and (pMob.isJumping or pMob.isFalling) then
			e.castChance = 0
		end
	end
	
	-- spell cast speed (adapted/somewhat wonky version of 4NM Fast Cast)
	if spell.castType == 0 or spell.castType == 5 then
		if (mob.actorType > 0 or ref.object.biped) and mob.actionData.animationAttackState == 11 then
			timer.start{duration = math.max(1.5 - 0.013*mob.intelligence.current, 0.2), callback = function()
				if ref == p and tes3.worldController.inputController:keybindTest(tes3.keybind.readyMagic) then
					timer.start{duration = 0.1, callback = function()
						mob.actionData.animationAttackState = 0
					end}
				elseif ref ~= p then
					timer.start{duration = 0.1, callback = function()
						mob.actionData.animationAttackState = 0
					end}
				end
			end}
		end
	end
end
event.register("spellCast", onCast)


local function onCasted(e)
		
	local ref = e.caster
	local mob = ref.mobile
	local spell = e.source
	
	if common.rbs then
	
		-- Atronach: Overload area on hit
		if spell.id == "_neph_bs_atr_pwOverload" then
			for hostile in tes3.iterate(mob.hostileActors) do
				if hostile.position:distance(mob.position) < 442 then
					local hRef = hostile.reference
					if hRef.data.neph[96] == 0 and math.min(0.01*hostile.sanctuary, 1) <= math.random() then
						hRef.data.neph[96] = 1
					end
					tes3.applyMagicSource{
						reference = hRef,
						source = "_neph_bs_atr_pwOverloadOnHit"
					}
				end
			end
		end
		
		-- Tower Key: Unlock and disarm EVERYTHING
		if spell.id == "_neph_bs_tow_pwKey" then
			for _, cell in pairs(tes3.getActiveCells()) do
				for ref in cell:iterateReferences(tes3.objectType.door) do
					tes3.unlock{reference = ref}
					tes3.setTrap{reference = ref, spell = nil}
				end
				for ref in cell:iterateReferences(tes3.objectType.container) do
					tes3.unlock{reference = ref}
					tes3.setTrap{reference = ref, spell = nil}
				end
			end
		end
		
		-- magicka-related NPC powers
		if mob.actorType == 1 and mob.magicka.normalized < 0.2 and 0.05 + 0.45 * ref.object.level/60 >= math.random() then
			-- Altmer
			if ref.data.neph[51] == "_neph_race_he_pwRush" then
				ref.data.neph[51] = "done"
				tes3.cast{
					reference = ref,
					target = ref,
					spell = "_neph_race_he_pwRush",
					instant = true
				}
				if common.config.NPCpowerMsg then
					tes3.messageBox("Magicka Rush has been casted.")
				end
			end
			-- Atronach
			if ref.data.neph[50] == "_neph_bs_atr_pwOverload" then
				ref.data.neph[50] = "done"
				tes3.cast{
					reference = ref,
					target = ref,
					spell = "_neph_bs_atr_pwOverload",
					instant = true
				}
				if common.config.NPCpowerMsg then
					tes3.messageBox("Overload has been casted.")
				end
			end
		end
	end
	
	-- Bound items
	--------------
	if common.skills then

		local oldItem
		local oldEnch
		local newItem
		local newEnch
		local MEfac = 1
		local conj = mob:getSkillValue(13)
		local conjFac
		
		if conj < 30 then
			conjFac = 0.15
		else
			conjFac = 0.01*conj
		end
		
		-- adjusting Magicka Expanded bound items; Basically assuming that only the player uses them
		if common.MEexists then
		
			MEfac = 0.75
			
			for item, props in pairs(common.MEboundWeapon) do
				if spell:getFirstIndexOfEffect(props[1]) >= 0 and not tes3.isAffectedBy{reference = ref, effect = props[1]} then
					if conj < 60 then
						newEnch = tes3.getObject(props[2]).enchantment
					else
						newEnch = tes3.getObject(props[3]).enchantment
					end
					oldItem = tes3.getObject(item)
					oldItem.enchantment = newEnch
					oldItem.chopMin		= props[4] * conjFac
					oldItem.chopMax		= props[5] * conjFac
					oldItem.slashMin	= props[6] * conjFac
					oldItem.slashMax	= props[7] * conjFac
					oldItem.thrustMin	= props[8] * conjFac
					oldItem.thrustMax	= props[9] * conjFac
					oldItem.modified	= true
				end
			end
			for item, props in pairs(common.MEboundArmor) do
				if spell:getFirstIndexOfEffect(props[1]) >= 0 and not tes3.isAffectedBy{reference = ref, effect = props[1]} then
					if conj < 60 then
						newEnch = tes3.getObject(props[2])
					else
						newEnch = tes3.getObject(props[3])
					end
					newEnch.effects[1].max	= math.ceil(props[4] * conjFac)
					newEnch.effects[1].min	= math.ceil(props[4] * conjFac)
					oldItem = tes3.getObject(item)
					oldItem.enchantment	= newEnch
					oldItem.armorRating	= 0
					oldItem.weight		= 0.1
					oldItem.modified	= true
				end
			end
		end
		
		-- vanilla bound weapons
		for item, props in pairs(common.boundWeapon) do
			if spell:getFirstIndexOfEffect(props[1]) >= 0 and not tes3.isAffectedBy{reference = ref, effect = props[1]} then
				if conj < 60 then
					oldItem = tes3.getObject(item)
				else
					oldItem = tes3.getObject(props[3])
				end
				newItem	= tes3.getObject(string.format("%i", conj) .. oldItem.id) or tes3.createObject{
					objectType 						= tes3.objectType.weapon,
					id 								= string.format("%i", conj) .. oldItem.id,
					name							= oldItem.name,
					type							= oldItem.type,
					mesh							= oldItem.mesh,
					icon							= oldItem.icon,
					enchantment 					= oldItem.enchantment,
					weight							= oldItem.weight,
					materialFlags					= oldItem.flags,
					value							= oldItem.value,
					maxCondition					= oldItem.maxCondition,
					enchantCapacity 				= oldItem.enchantCapacity,
					ignoresNormalWeaponResistance	= oldItem.ignoresNormalWeaponResistance,
					reach							= oldItem.reach,
					isOneHanded						= oldItem.isOneHanded,
					isTwoHanded						= oldItem.isTwoHanded,
					isMelee							= oldItem.isMelee,
					isRanged						= oldItem.isRanged,
					speed							= oldItem.speed,
					chopMin							= oldItem.chopMin * conjFac,
					chopMax							= oldItem.chopMax * conjFac,
					slashMin						= oldItem.slashMin * conjFac,
					slashMax						= oldItem.slashMax * conjFac,
					thrustMin						= oldItem.thrustMin * conjFac,
					thrustMax						= oldItem.thrustMax * conjFac
				}
				newItem.modified = true
				tes3.findGMST(props[2]).value = newItem.id
				--tes3.messageBox("bound weapon id: %s", tes3.findGMST(props[2]).value)
			end
		end
		
		-- vanilla bound armor
		for item, props in pairs(common.boundArmor) do
			--if tes3.getObject(props[3]) == nil or tes3.getObject(props[4]) == nil then tes3.messageBox("Found incorrect bound dummy spell!") return end
			if spell:getFirstIndexOfEffect(props[1]) >= 0 and not tes3.isAffectedBy{reference = ref, effect = props[1]} then
				if ref.object.race and ref.object.race.isBeast and (props[1] == 128 or props[1] == 129) then -- do nothing
				else
					if ref ~= p then
						tes3.findGMST(props[2]).value = item
						if conj < 60 then
							oldEnch = tes3.getObject(props[3])
						else
							oldEnch = tes3.getObject(props[4])
						end	
						newEnch = tes3.createObject{
							objectType 		= tes3.objectType.spell,
							id 				= string.format("%i", conjFac) .. oldEnch.id,
							name			= oldEnch.name,
							effects			= oldEnch.effects,
							castType		= oldEnch.castType,
							isActiveCast	= false
						}
						newEnch.effects[1].max	= math.ceil(oldEnch.effects[1].max * conjFac * MEfac)
						newEnch.effects[1].min	= math.ceil(oldEnch.effects[1].min * conjFac * MEfac)
						newEnch.effects[1].duration = spell.effects[1].duration
						tes3.applyMagicSource{reference = ref, source = newEnch}
						--tes3.messageBox("bound armor NPC spell: %s", newEnch.id)
					else -- player
						if conj < 60 then
							tes3.findGMST(props[2]).value = props[5]
							oldEnch = tes3.getObject(props[5]).enchantment
						else
							tes3.findGMST(props[2]).value = props[6]
							oldEnch = tes3.getObject(props[6]).enchantment
						end
						oldEnch.effects[1].max	= math.ceil(oldEnch.effects[1].max * conjFac * MEfac)
						oldEnch.effects[1].min	= math.ceil(oldEnch.effects[1].min * conjFac * MEfac)
						--tes3.messageBox("bound player armor: %s", tes3.findGMST(props[2]).value)
					end
				end
			end
		end
	end
end
event.register("spellCasted", onCasted)


local function magickaUse(e)
	if e.caster.data.neph[99] == "Warrior" then
		e.cost = e.cost * 1.25
	end
	if e.caster.mobile and e.caster.mobile:isAffectedByObject(tes3.getObject("_neph_bs_mag_pwSurge")) then
		e.cost = e.cost * 0.35
	elseif e.caster.mobile and e.caster.mobile:isAffectedByObject(tes3.getObject("_neph_bs_app_pwZeal")) then
		e.cost = e.cost * 1.5
	end
end
if common.rbs then
	event.register("spellMagickaUse", magickaUse)
end


local function onTick(e)

	local tRef		= e.target
	local aRef		= e.caster
	if not aRef then return end
	local aMob		= aRef.mobile
	local tMob		= tRef.mobile
	if not tMob then return end
	local spell		= e.source
	local effect	= e.effect.id
	local temp

	if common.rbs then
	
		-- Khajiit Skooma effects
		if tRef == p and p.object.race.id:lower() == "khajiit" then
			if spell and spell.name and spell.name:lower() == "skooma" then
				if e.effectInstance.state ~= tes3.spellState.ending then
					tes3.worldController.simulationTimeScalar = math.max(0.8 - 0.01*p.object.level, 0.2)
					pMob.animationController.weaponSpeed = 4
					p.data.neph[58] = 1
				else
					tes3.worldController.simulationTimeScalar = 1
					p.data.neph[58] = 0
				end
			end
		end
	end
	
	-- Fortify + Drain workaround (to prevent permanent damage to skills or attributes when stacking those effects)
	if e.effectInstance.state == 6 then
		local mag
		if effect == 79 then
			for i = 0, 7 do
				mag = tes3.getEffectMagnitude{reference = tRef, effect = 79, attribute = i}
				if mag > 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Correct Attribute",
						effects = {{id = 74, attribute = i, min = mag, max = mag}}
					}
				end
			end
		end
		if effect == 83 then
			for i = 0, 26 do
				mag = tes3.getEffectMagnitude{reference = tRef, effect = 83, skill = i}
				if mag > 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Correct Skill",
						effects = {{id = 78, skill = i, min = mag, max = mag}}
					}
				end
			end
		end
	end
	
	-- Knock out limit (due to fatigue loss)
	if (effect == 20 or effect == 25 or effect == 88) and tRef.data.neph[95] == 1 then
		e.block = true
	end
	
	-- block vanilla mind control effects
	for i = 49, 56 do
		if effect == i then
			e.block = true
		end
	end
	
	-- Restoration 60: Dispel rework
	if common.skills then
		if aMob then
			if aMob:getSkillValue(15) >= 60 then
				if effect == 57 then
					temp = 0
					if aRef == tRef then
						temp = 1
						for neg in pairs(this.negativeEffects) do
							if tes3.isAffectedBy{reference = tRef, effect = neg} then
								tes3.removeEffects{reference = tRef, effect = neg}
							end
						end
						for i = 0, 7 do -- attribute effects
							if tes3.isAffectedBy{reference = tRef, effect = 17, attribute = i} then
								tes3.removeEffects{reference = tRef, effect = 17, attribute = i}
							end
							if tes3.isAffectedBy{reference = tRef, effect = 22, attribute = i} then
								tes3.removeEffects{reference = tRef, effect = 22, attribute = i}
							end
							if tes3.isAffectedBy{reference = tRef, effect = 85, attribute = i} then
								tes3.removeEffects{reference = tRef, effect = 85, attribute = i}
							end
						end
						for i = 0, 26 do -- skill effects
							if tes3.isAffectedBy{reference = tRef, effect = 21, skill = i} then
								tes3.removeEffects{reference = tRef, effect = 21, skill = i}
							end
							if tes3.isAffectedBy{reference = tRef, effect = 26, skill = i} then
								tes3.removeEffects{reference = tRef, effect = 26, skill = i}
							end
							if tes3.isAffectedBy{reference = tRef, effect = 89, skill = i} then
								tes3.removeEffects{reference = tRef, effect = 89, skill = i}
							end
						end
					else
						for hostile in tes3.iterate(aMob.hostileActors) do
							if tMob == hostile then
								temp = 1
								for pos in pairs(common.positiveEffects) do
									if tes3.isAffectedBy{reference = tRef, effect = pos} then
										tes3.removeEffects{reference = tRef, effect = pos}
									end
								end
								for i = 0, 7 do -- attribute effects
									if tes3.isAffectedBy{reference = tRef, effect = 74, attribute = i} then
										tes3.removeEffects{reference = tRef, effect = 74, attribute = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 79, attribute = i} then
										tes3.removeEffects{reference = tRef, effect = 79, attribute = i}
									end
								end
								for i = 0, 26 do -- skill effects
									if tes3.isAffectedBy{reference = tRef, effect = 78, skill = i} then
										tes3.removeEffects{reference = tRef, effect = 78, skill = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 83, skill = i} then
										tes3.removeEffects{reference = tRef, effect = 83, skill = i}
									end
								end
								break
							end
						end
						for friendly in tes3.iterate(aMob.friendlyActors) do
							if tMob == friendly then
								temp = 1
								for neg in pairs(this.negativeEffects) do
									if tes3.isAffectedBy{reference = tRef, effect = neg} then
										tes3.removeEffects{reference = tRef, effect = neg}
									end
								end
								for i = 0, 7 do -- attribute effects
									if tes3.isAffectedBy{reference = tRef, effect = 17, attribute = i} then
										tes3.removeEffects{reference = tRef, effect = 17, attribute = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 22, attribute = i} then
										tes3.removeEffects{reference = tRef, effect = 22, attribute = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 85, attribute = i} then
										tes3.removeEffects{reference = tRef, effect = 85, attribute = i}
									end
								end
								for i = 0, 26 do -- skill effects
									if tes3.isAffectedBy{reference = tRef, effect = 21, skill = i} then
										tes3.removeEffects{reference = tRef, effect = 21, skill = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 26, skill = i} then
										tes3.removeEffects{reference = tRef, effect = 26, skill = i}
									end
									if tes3.isAffectedBy{reference = tRef, effect = 89, skill = i} then
										tes3.removeEffects{reference = tRef, effect = 89, skill = i}
									end
								end
								break
							end
						end
					end
					if temp == 1 then
						e.block = true -- (neutral actors still get the old dispel effect)
					end
				end
			end
		end
		
		-- Illusion 30: Set up damage bonus marker when breaking invisibility by casting
		if aMob.invisibility > 0 and aRef.data.neph[17] == 0 then
			aRef.data.neph[17] = 1
		end
		if aMob.invisibility == 0 and aRef.data.neph[17] == 1 then
			aRef.data.neph[17] = 2
			timer.start{duration = 2.5, callback = function()
				aRef.data.neph[17] = 0
			end}
		end
		
		-- Alteration 90 cloak effects
		if tMob:getSkillValue(11) >= 90 then
			if tMob.hostileActors and tRef.data.neph[33] == 0 then
				
				local effects = tes3.getObject("_neph_perk_11_eleCloak").effects
				
				local fireShield = tes3.getEffectMagnitude{reference = tRef, effect = 4}
				if fireShield >= 5 then
					effects[1].id = 14
					effects[1].duration = 3
					effects[1].max = 0.2*fireShield
					effects[1].min = 0.2*fireShield
				else
					effects[1].id = -1
				end
				
				local lightningShield = tes3.getEffectMagnitude{reference = tRef, effect = 5}
				if lightningShield >= 5 then
					effects[2].id = 15
					effects[2].duration = 3
					effects[2].max = 0.2*lightningShield
					effects[2].min = 0.2*lightningShield
				else
					effects[2].id = -1
				end
				
				local frostShield = tes3.getEffectMagnitude{reference = tRef, effect = 6}
				if frostShield >= 5 then
					effects[3].id = 16
					effects[3].duration = 3
					effects[3].max = 0.2*frostShield
					effects[3].min = 0.2*frostShield
				else
					effects[3].id = -1
				end
				
				if fireShield + lightningShield + frostShield >= 3 then
					tRef.data.neph[33] = 1
					for hostile in tes3.iterate(tMob.hostileActors) do
						if hostile.position:distance(tMob.position) < 221 then
							tes3.applyMagicSource{
								reference = hostile.reference,
								source = "_neph_perk_11_eleCloak"
							}
						end
					end
					timer.start{
						duration = 3,
						callback = function()
							tRef.data.neph[33] = 0
						end
					}
				end
			end
		end
	end
end
event.register("spellTick", onTick)


local function spellTooltips(e)

	local main = e.tooltip:findChild("PartHelpMenu_main")
	if not main then return end
	local effects = main:findChild(tes3ui.registerID("effect"))
	if not effects then return end
	local sText
	local spell = e.spell.id
	local sEffects = e.spell.effects
	local lvl = p.object.level
	
	e.claim = true -- avoids UI Expansion power recharge tooltip (let's hope it doesn't steam-roll anything else)
	
	-- new mind control tooltips; Why does this not work? D;
--[[if spell.castType ~= 5 then
		for i = 1, #sEffects do
			if sEffects[i].id == 49 then
				effects.children[i].children[2].children[1].text =
					"Calm lvl " .. string.format("%i", sEffects[i].min) .. " - " .. string.format("%i", sEffects[i].max)
					.. " for " .. string.format("%i", sEffects[i].duration) .. " secs in "
					.. string.format("%i", sEffects[i].radius) .. " ft on " .. string.format("%i", sEffects[i].rangeType) .. "."
			elseif sEffects[i].id == 51 then
				effects.children[i].children[2].children[1].text =
					"Frenzy lvl " .. string.format("%i", sEffects[i].min) .. " - " .. string.format("%i", sEffects[i].max)
					.. " for " .. string.format("%i", sEffects[i].duration) .. " secs in "
					.. string.format("%i", sEffects[i].radius) .. " ft on " .. string.format("%i", sEffects[i].rangeType) .. "."
			elseif sEffects[i].id == 53 then
				effects.children[i].children[2].children[1].text =
					"Demoralize lvl " .. string.format("%i", sEffects[i].min) .. " - " .. string.format("%i", sEffects[i].max)
					.. " for " .. string.format("%i", sEffects[i].duration) .. " secs in "
					.. string.format("%i", sEffects[i].radius) .. " ft on " .. string.format("%i", sEffects[i].rangeType) .. "."
			elseif sEffects[i].id == 55 then
				effects.children[i].children[2].children[1].text =
					"Rally lvl " .. string.format("%i", sEffects[i].min) .. " - " .. string.format("%i", sEffects[i].max)
					.. " for " .. string.format("%i", sEffects[i].duration) .. " secs in "
					.. string.format("%i", sEffects[i].radius) .. " ft on " .. string.format("%i", sEffects[i].rangeType) .. "."
			end
		end
	end ]]--
	
	-- Altmer
	if spell == "_neph_race_he_pwRush" then
		effects.children[1].children[2].children[1].text = "Restore 10% maximum Magicka for 20 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Double critical spell chance."}
	-- Argonian
	elseif spell == "_neph_race_ar_pwHistCall" then
		effects.children[1].children[2].children[1].text = "Restore 10% maximum Health for 20 secs on Self"
		effects.children[2].children[2].children[1].text = "Restore 10% maximum Magicka for 20 secs on Self"
		effects.children[3].children[2].children[1].text = "Restore 10% maximum Fatigue for 20 secs on Self"
	-- Bosmer
	elseif spell == "_neph_race_we_pwTongue" then
		effects.children[1].children[2].children[1].text = "Command lvl " .. string.format("%i", lvl+5) .. " Creature for 8 hours on Touch."
	-- Breton
	elseif spell == "_neph_race_br_pwDragonSkin" then
		effects.children[1].children[2].children[1].text = string.format("%i", lvl+25) .. " pts Shield for 30 secs on Self"
		effects.children[2].children[2].children[1].text = string.format("%i", math.abs(0.2*lvl+5)) .. " pts Fire Shield for 30 secs on Self"
		effects.children[3].children[2].children[1].text = "Resist Fire " .. string.format("%i", math.abs(0.8*lvl+20)) .. "% for 30 secs on Self"
		effects.children[4].children[2].children[1].text = "Resist Frost " .. string.format("%i", lvl+25) .. "% for 30 secs on Self"
		effects.children[5].children[2].children[1].text = "Resist Shock " .. string.format("%i", lvl+25) .. "% for 30 secs on Self"
	-- Dunmer
	elseif spell == "_neph_race_de_pwAncGuardP" then
		effects:createDivider()
		sText = effects:createLabel{text =
			"Ignores summoning restrictions and the Ritual duration bonus and will become more powerful the higher the caster's level. "
			.."If the caster would die, instead, the Ancestor Guardian restores their Health and vanishes."
		}
		sText.wrapText = true
	elseif spell == "_neph_race_de_togConvMag" then
		effects:createDivider()
		sText = effects:createLabel{text = "Attacks drain 10% maximum Magicka and deal half that amount as irresistible damage."}
		sText.wrapText = true
	-- Imperial
	elseif spell == "_neph_race_im_pwVoiceEmp" then
		effects.children[1].children[2].children[1].text = "Command lvl " .. string.format("%i", lvl+5) .. " Humanoid for 8 hours on Touch."
	-- Nord
	elseif spell == "_neph_race_no_pwBattleCry" then
		effects.children[1].children[2].children[1].text = "Demoralize lvl " .. string.format("%i", lvl+5) .. " for 20 secs in 15 ft on Target"
		effects:createDivider()
		effects:createLabel{text = "Targets take damage and are knocked down."}
	-- Orc
	elseif spell == "_neph_race_or_pwBerserk" then
		effects.children[1].children[2].children[1].text = "Fortify Speed " .. string.format("%i", lvl+10) .. " pts for 30 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Take double damage and deal double melee damage."}
	-- Redguard
	elseif spell == "_neph_race_rg_pwAdrenaline" then
		effects.children[2].children[2].children[1].text = "Restore 10% maximum Fatigue for 20 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Increased attack speed."}
	-- Apprentice
	elseif spell == "_neph_bs_app_pwZeal" then
		effects:createDivider()
		effects:createLabel{text = "Spells cost 1.5x as much Magicka, but are applied twice."}
	-- Lord
	elseif spell == "_neph_bs_lor_pwGuardian" then
		effects.children[1].children[2].children[1].text = "Restore 10% maximum Health for 10 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Take 90% less damage and gain +90% resistance to all magic."}
	-- Mage
	elseif spell == "_neph_bs_mag_pwSurge" then
		effects.children[1].children[2].children[1].text = "Levitation " .. string.format("%i", lvl+10) .. " pts for 20 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Spells cost 65% less magicka and cannot fail."}
	-- Shadow
	elseif spell == "_neph_bs_sha_pwShroud" then
		effects:createDivider()
		sText = effects:createLabel{text = "Emanate an aura of 95% Blind and Noise in 100 ft."}
		sText.wrapText = true
	-- Atronach
	elseif spell == "_neph_bs_atr_pwOverload" then
		effects.children[1].children[2].children[1].text = "Restore Magicka to full"
		effects:createDivider()
		sText = effects:createLabel{text = "Knockdown and Shock Damage equal to 20% maximum Magicka for 5 secs in 20 ft around."}
		sText.wrapText = true
	-- Warrior
	elseif spell == "_neph_bs_war_pwMight" then
		effects.children[1].children[2].children[1].text = "Fortify Strength " .. string.format("%i", lvl+10) .. " pts for 20 secs on Self"
		effects:createDivider()
		effects:createLabel{text = "Gain double critical attack chance."}
	-- Serpent
	elseif spell == "_neph_bs_ser_pwFangs" then
		effects.children[1].children[2].children[1].text = "Fortify Agility " .. string.format("%i", lvl+10) .. " pts for 30s on Self"
		effects:createDivider()
		sText = effects:createLabel{text = "Attacks inflict Slow, Weakness to Poison and Poison Damage."}
		sText.wrapText = true
	-- Steed
	elseif spell == "_neph_bs_ste_pwTrample" then
		effects:createDivider()
		sText = effects:createLabel{text = "Targets you are running or jumping into take damage and are knocked down."}
		sText.wrapText = true
	-- Thief
	elseif spell == "_neph_bs_thi_pwHeist" then
		effects.children[1].children[2].children[1].text = "Jump 10 pts for 2 hours on Self"
		effects.children[2].children[2].children[1].text = "Slowfall 10 pts for 2 hours on Self"
		effects.children[3].children[2].children[1].text = "Fortify Sneak 50 pts for 2 hours on Self"
		effects.children[4].children[2].children[1].text = "Fortify Security 50 pts for 2 hours on Self"
	-- Lover
	elseif spell == "_neph_bs_lov_pwPresence" then
		effects.children[1].children[2].children[1].text = "Calm lvl " .. string.format("%i", lvl+5) .. " for 2 hours in 100 ft on Target"
		effects.children[2].children[2].children[1].text = "Charm 100 pts for 2 hours in 100 ft on Target"
	-- Lady
	elseif spell == "_neph_bs_lad_pwGift" then
		effects.children[1].children[2].children[1].text = "Fortify Health " .. string.format("%i", 2*lvl+20) .. " pts for 30 secs on Self"
		effects.children[2].children[2].children[1].text = "Fortify Magicka " .. string.format("%i", 2*lvl+20) .. " pts for 30 secs on Self"
		effects.children[3].children[2].children[1].text = "Fortify Stamina " .. string.format("%i", 2*lvl+20) .. " pts for 30 secs on Self"
		effects:createDivider()
		sText = effects:createLabel{text = "Deal 1.5x more damage and take only 0.65x."}
	-- Ritual
	elseif spell == "_neph_bs_rit_pwMark" then
		effects:createDivider()
		sText = effects:createLabel{text = "Targets take double damage from summons and bound weapons."}
		sText.wrapText = true
	elseif spell == "_neph_bs_tow_pwKey" then
		effects.children[1].children[2].children[1].text = "Unlock everything and disarm all traps in the area. Can be targeted anywhere."	
	end
	
	-- Actual snippet to override power recharge tooltips from UI Expansion
	if e.spell.castType == 5 then
		if pMob:getPowerUseTimestamp(e.spell) then
			local castTimestamp = pMob:getPowerUseTimestamp(e.spell)
			local timeToRecharge = math.abs(math.max(24 - 0.24*lvl, 8) - (tes3.getSimulationTimestamp() - castTimestamp))
			local label = e.tooltip:createLabel{
				id = "neph:PowerRechargeCooldown",
				text = string.format("%.0f hours until recharge.", timeToRecharge),
			}
			label.borderBottom = 4
			label.color = tes3ui.getPalette("disabled_color")
		end
	end
end
if common.rbs then
	event.register("uiSpellTooltip", spellTooltips, {priority = -99})
end


-- Wiggly spell projectiles
---------------------------
local projTable = {}

local function simSpellProj(e)
	local dt = tes3.worldController.deltaTime	
	for _, t in pairs(projTable) do
		t.liv = t.liv + dt
		if t.liv >= 0.1 then
			t.sMob.impulseVelocity = tes3vector3.new(
				t.amp*t.liv*math.cos(10*t.liv),
				t.correctum*t.amp*t.liv*math.cos(10*t.liv),
				t.amp*t.liv*math.sin(10*t.liv)
			)
		end
	end
	if table.size(projTable) == 0 then
		event.unregister("simulate", simSpellProj)
		Sim = nil
	end
end

local function spellProjectile(e)
	local sMob = e.mobile
	if sMob and sMob.spellInstance and sMob.firingMobile then
		local ref = e.reference
		ref.position = ref.position - ref.sceneNode.velocity:normalized()*100
		local amp = 1500 - math.min(12.5*sMob.firingMobile.willpower.base, 1250)
		local projId = sMob.reference.object.id
		
		projTable[ref] = {
			aMob = sMob.firingMobile,
			sMob = sMob,
			amp = amp,
			correctum = 1,
			proj,
			liv = 0
		}
		
		if (tes3.getPlayerEyeVector().x * tes3.getPlayerEyeVector().y > 0) then projTable[ref].correctum = -1 end
		--[[When looking northeast or southwest (+x*+y or -x*-y), projectiles would otherwise only have a sine trajectory. This doesn't account
			for NPC casted projectiles, but should be unnoticeable enough, as they often cast stuff, when the player is looking at them.]] 
		
		projTable[ref].amp = 0.5*math.random(-amp, amp)
		
		if not Sim then
			event.register("simulate", simSpellProj)
			Sim = 0
		end
	end
end

local function projExpired(e)
	if projTable[e.object] then
		projTable[e.object] = nil
	end
end

if common.config.spellProjWiggle then
	event.register("mobileActivated", spellProjectile)
	event.register("objectInvalidated", projExpired)
end


local function playerVars()

	p = tes3.player
	pMob = tes3.mobilePlayer

end
event.register("loaded", playerVars)