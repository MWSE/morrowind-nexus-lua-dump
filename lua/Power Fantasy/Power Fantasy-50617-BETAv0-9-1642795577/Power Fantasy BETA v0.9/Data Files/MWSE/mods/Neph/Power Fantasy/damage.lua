local common = require("Neph.Power Fantasy.common")
local p, pMob, d, healthMeter, healthMeterT
local V = {}
local t = 0
local dmgBundle = 0

local function h2hDamage(e)

	-- H2H Dmg Conversion
	---------------------

	common.scriptDmg.aRef	= e.attackerReference
	common.scriptDmg.aMob	= e.attacker
	common.scriptDmg.tMob	= e.mobile
	common.scriptDmg.dir	= e.attacker.actionData.physicalAttackType
	common.scriptDmg.swing	= e.attacker.actionData.attackSwing
	common.scriptDmg.weap	= -1

	e.mobile:applyDamage{damage = 0.25*e.fatigueDamage * common.scriptDmg.swing, applyArmor = true}
	
	-- just a bit of fatigue damage (not much attached...)
	if e.reference.data.neph[95] == 0 then
		e.fatigueDamage = 0.25*e.fatigueDamage * common.scriptDmg.swing
	else
		e.fatigueDamage = 0
	end
end
event.register("damageHandToHand", h2hDamage)


local function damage(e)

	local src = e.source
	local mGate
	
	---------------------------------
	--[[ UNIVERSAL DMG MODIFIERS ]]--
	---------------------------------
		
	-- block elemental shield reflect damage beyond 10 ft
	if src == "shield" then
		if e.attacker.position:distance(e.reference.position) > 221 then
			e.block = true
			return
		end
	end
	
	-- bundling together magic damage of 1 second for better handling (triggers on every frame,
	-- however, it also triggers for every seperate instance...); Keep an eye out for weird behavior
	if src == "magic" then
		if e.magicSourceInstance.sourceType ~= 3 then
		
			t = t + d
			dmgBundle = dmgBundle + e.damage
			
			if t >= 1 then
				mGate		= true
				t			= 0
				e.damage	= dmgBundle
				dmgBundle	= 0
			else
				mGate = false
			end
		else
			mGate = false
		end
	end
	
	-----------------------------------------------------------------------------------------
	if not (src == "attack" or src == "script" or (src == "magic" and mGate)) then return end
	-----------------------------------------------------------------------------------------
	
	local aRef, aMob, tRef, tMob, skill, critChance, critDmg, onhit, temp
	
	if src ~= "script" then
		aRef		= e.attackerReference
		aMob		= e.attacker
		tMob		= e.mobile
	else
		aRef		= common.scriptDmg.aRef
		aMob		= common.scriptDmg.aMob
		tMob		= common.scriptDmg.tMob
	end
	
	local tRef		= e.reference
	
	if not aMob or not tMob then return end
	
	local aLuck		= aMob.luck.current
	
	if src == "magic" then
		critChance	= 0.001*aLuck + 0.0015*aMob.willpower.current
		critDmg		= 1.5 + 0.01*aMob.intelligence.current
	else
		critChance	= 0.001*aLuck + 0.0015*aMob.agility.current
		critDmg		= 1.5 + 0.01*aMob.strength.current
	end
	
	local aBS		= aRef.data.neph[99]
	local tBS		= tRef.data.neph[99]
	local aID		= aRef.object.id
	local tID		= tRef.object.id
	local aFat		= 0.5 + 0.5*aMob.fatigue.normalized
	local tFat		= 2 - tMob.fatigue.normalized
	local hA50		= 1
	local hATemp	= 0
	local critRoll	= math.random()
	local onHitMarker
	local tRace
	local aRace
	
	--if aRef == p then tes3.messageBox("Raw Damage: %f", e.damage) end
	
	-- NPC Defensive Perks
	----------------------
	if tRef.object.objectType == tes3.objectType.npc then
	
		if common.rbs then
		
			tRace = tRef.object.race.id:lower()
			
			-- Imperial: Reduce total physical damage by 15% at 100 PER
			if tRace == "imperial" then
				e.damage = e.damage * (1 - 0.0015*tMob.personality.current)
			end
		
			-- Orc: Take double damage while enraged and extra damage reduction from armor
			if tRace == "orc" then
				temp = 1
				for i = 0, 10 do
					if i ~= 8 and tRef.data.neph[i] >= 0 then
						temp = temp - 0.02
						if i <= 1 then
							temp = temp - 0.02
						end
					end
				end
				e.damage = e.damage * temp
				if tMob:isAffectedByObject(tes3.getObject("_neph_race_or_pwBerserk")) then
					e.damage = e.damage * 2
				end
			end
			
			-- Redguard: Less def. fatigue penalty
			if tRace == "redguard" then
				tFat = 1.5 - 0.5*tMob.fatigue.normalized
			end
			
			-- Lord: Take down to half as much damage the lower your health
			if tBS == "Lord" then
				e.damage = e.damage * (0.5 + 0.5*tMob.health.normalized)
				-- Lord Star Guardian: Take 90% less damage for 10 secs
				if tMob:isAffectedByObject(tes3.getObject("_neph_bs_lor_pwGuardian")) then
					e.damage = 0.1 * e.damage
				end
			end
			
			-- Lover: Weakness to NPCs
			if tBS == "Lover" and aMob.actorType > 0 then
				e.damage = e.damage * 1.25
			end
			
			-- Lady: 0.65X damage while affected by Celestial Gift
			if tMob:isAffectedByObject(tes3.getObject("_neph_bs_lad_pwGift")) then
				e.damage = e.damage * 0.65
			end
			
			-- Ritual: Take 1.5x more damage while having no summon around
			if tBS == "Ritual" then
				temp = 0
				for summon in pairs(common.summonID) do
					if tes3.isAffectedBy{reference = tRef, effect = summon} then
						temp = 1
					end
				end
				if temp == 0 then
					e.damage = e.damage * 1.5
				end
			end
			
			-- Shadow: Take more damage while outdoors during the day
			if tBS == "Shadow" then
				local hour = tes3.worldController.hour.value
				if hour < 20 and hour > 6 and (tRef.cell.behavesAsExterior or not tRef.cell.isInterior) then
					e.damage = e.damage * 1.25
				end
			end
		end
		
		if common.skills then
		
			-- Medium Armor 30: Take less damage while dashing
			if tMob.mediumArmor.base >= 30 then
				temp = 0
				for i = 0, 10 do
					if i ~= 8 and tRef.data.neph[i] == 1 then
						temp = temp + 0.1
						if i <= 1 then
							temp = temp + 0.1
						end
					end
				end
				if tRef.data.neph[98] == 3 then
					e.damage = e.damage * (1 - 0.005*tMob.mediumArmor.base*temp)
				end
				
				-- MA 60: Chance per piece to restore up to 5% stamina per second
				if tMob.mediumArmor.base >= 60 and tRef.data.neph[22] == 0 and temp >= math.random() then
					tRef.data.neph[22] = 1
					tes3.modStatistic{
						reference = tRef,
						name = "fatigue",
						current = 0.05*aMob.fatigue.base,
						limitToBase = true
					}
					timer.start{
						duration = 1,
						callback = function()
							tRef.data.neph[22] = 0
						end
					}
				end
			end
			
			-- Heavy Armor 60: Critical damage bonus up to halved the more pieces you wear (just the variable)
			for i = 0, 10 do
				if i ~= 8 and tRef.data.neph[i] == 2 then
					hATemp = hATemp + 0.05
					if i <= 1 then
						hATemp = hATemp + 0.05
					end
				end
			end
			if tMob.heavyArmor.base >= 60 then
				hA50 = hA50 - hATemp + math.min(0.005*aMob.attackBonus, 0.5)
			end
			
			-- Bound Armor: take up to 10% less damage per active effect (7.5% with Magicka Expanded lore-friendly pack)
			temp = 0
			if common.MEexists then
				for effectID in pairs(common.boundArmorEff) do
					if tes3.isAffectedBy{reference = tRef, effect = effectID} then
						temp = temp + 1
						if effectID >= 240 then -- pauldrons aren't paired like gauntlets
							temp = temp - 0.5
						end
					end
				end
				if temp > 0 then
					e.damage = e.damage * (1 - 0.00075*temp*tMob:getSkillValue(13))
				end
			else
				for i = 127, 131 do
					if tes3.isAffectedBy{reference = tRef, effect = i} then
						temp = temp + 1
					end
				end
				if temp > 0 then
					e.damage = e.damage * (1 - 0.001*temp*tMob:getSkillValue(13))
				end
			end
		end
		
	-- Creature Defensive Perks
	---------------------------
	else
		if common.config.creaPerks then
		
			-- Lesser Dagoths take up to 35% less damage with missing health
			if tRef.data.neph[72] then
				e.damage = e.damage * (1 - 0.35*(1 - tMob.health.normalized))
			end
			
			-- Tribunal gods, Dagoth Ur, Karstaag, Grahls, Ogrims, Hircine Aspects and Udyrfrykte take down to half damage with missing health
			if tRef.data.neph[73] then
				e.damage = e.damage * (1 - 0.5*(1 - tMob.health.normalized))
			end
		end

		-- Huge creature soul values...
		for crea in pairs(common.hugeSouls) do
			if string.find(tID, crea) and tRef.object.soul ~= 500 then
				tRef.object.soul = 500
			end
		end
	end
	
	-- NPC Offensive Perks
	----------------------
	if aRef.object.objectType == tes3.objectType.npc then
	
		if common.rbs then
	
			aRace = aRef.object.race.id:lower()
			
			-- Imperial: 1.3x weapon damage on 100 PER
			if aRace == "imperial" then
				e.damage = e.damage * (1 + 0.003*aMob.personality.current)
			end
			
			-- Redguard: Less fatigue penalty on weapon damage and +35% attack damage per enemy, beginning from 2
			if aRace == "redguard" then
				aFat = 0.75 + 0.25*aMob.fatigue.normalized
				if #aMob.hostileActors >= 2 then
					temp = 0
					for hostile in tes3.iterate(aMob.hostileActors) do
						if not (hostile.object.race and string.find(hostile.object.name:lower(), "guard")) then
							temp = temp + 1
						end
					end
					e.damage = e.damage * (1 + math.min(0.35 * math.max(temp - 1, 0), 1))
				end
			end
			
			-- Steed: up to 1.3x more damage on 100 SPD and SPD bonus on hit
			if aBS == "Steed" then
				e.damage = e.damage * (1 + 0.003*aMob.speed.current)
				if aRef.data.neph[57] == 0 then
					aRef.data.neph[57] = 1
					tes3.applyMagicSource{
						reference = aRef,
						name = "Haste",
						effects = {{id = 79, attribute = 4, duration = 5, min = 5, max = 5}}
					}
					timer.start{
						duration = 1,
						callback = function()
							aRef.data.neph[57] = 0
						end
					}
				end
			end
			
			-- Thief: +15% to all crit chance
			if aBS == "Thief" then
				critChance = critChance + 0.15
			end
			
			-- Serpent: up to 1.5x damage the lower the target's health
			if aBS == "Serpent" and tMob.health.normalized < 1 then
				e.damage = e.damage * (1.5 - 0.5*tMob.health.normalized)
			end
			
			-- Lady: 1.5x damage while affected by Celestial Gift
			if aMob:isAffectedByObject(tes3.getObject("_neph_bs_lad_pwGift")) then
				e.damage = e.damage * 1.5
			end
			
			-- Shadow: Deal more damage while outdoors at night or indoors
			if aBS == "Shadow" then
				local hour = tes3.worldController.hour.value
				if (hour >= 20 and hour <= 6 and (tRef.cell.behavesAsExterior or not tRef.cell.isInterior)) or tRef.cell.isInterior then
					e.damage = e.damage * 1.35
				end
			end
		end
		
		if common.skills then
				
			-- Medium Armor 90: Up to +100% crit dmg the lower your health while wearing cuirass
			if aMob:getSkillValue(2) >= 90 and aRef.data.neph[1] == 1 and aMob.health.normalized < 1 then
				critDmg = critDmg + 1 - aMob.health.normalized
			end
		
			-- Light Armor 90: Deal more damage the longer you haven't been hit while wearing cuirass
			if aMob:getSkillValue(21) >= 90 and aRef.data.neph[1] == 0 and aRef.data.neph[19] > 0 then
				e.damage = e.damage * (1 + 0.05*aRef.data.neph[19])
			end
		end
	
	-- Creature Offensive Perks
	---------------------------
	else
		critChance = critChance + 0.0025*aMob.stealth.base
		critDmg = critDmg + 0.01*aMob.stealth.base
		
		if common.rbs then
			-- Tower: Weakness to creatures
			if tBS == "Tower" then
				e.damage = e.damage * 1.25
			end
			
			-- Ritual's Mark bonus damage from summons
			if tMob:isAffectedByObject(tes3.getObject("_neph_bs_rit_pwMark")) and string.find(aID, "summon") then
				e.damage = e.damage * 2
			end
		end
		
		if common.config.creaPerks then
		
			-- Dagoths (excl. Dagoth Ur) gain +25% crit chance with missing health
			if aRef.data.neph[72] then
				critChance = critChance + 0.25*(1 - aMob.health.normalized)
			end
			
			-- Tribunal gods + Dagoth Ur gain +50% crit chance with missing health
			if aRef.data.neph[74] then
				critChance = critChance + 0.5*(1 - aMob.health.normalized)
			end
			
			-- Pack creatures
			if string.find(aID, "riekling") then
				temp = 0
				for _, cell in pairs(tes3.getActiveCells()) do
					for ref in tes3.iterate(cell.actors) do
						if string.find(ref.object.id, "riekling") then
							temp = temp + 1
						end
					end
				end
				e.damage = e.damage * 1 + math.min(0.35 * math.max(temp - 1, 0), 2)
			end
			
			if string.find(aID, "goblin") then
				temp = 0
				for _, cell in pairs(tes3.getActiveCells()) do
					for ref in tes3.iterate(cell.actors) do
						if string.find(ref.object.id, "goblin") then
							temp = temp + 1
						end
					end
				end
				e.damage = e.damage * 1 + math.min(0.35 * math.max(temp - 1, 0), 2)
			end
			
			if string.find(aID, "BM_wolf") then
				temp = 0
				for _, cell in pairs(tes3.getActiveCells()) do
					for ref in tes3.iterate(cell.actors) do
						if string.find(ref.object.id, "BM_wolf") then
							temp = temp + 1
						end
					end
				end
				e.damage = e.damage * 1 + math.min(0.35 * math.max(temp - 1, 0), 2)
			end
		end
	end
	
	-- Illusion 30: Up to 1.5x damage for 2.5s after breaking invisibility
	if common.skills and aMob:getSkillValue(12) >= 30 and aRef.data.neph[17] == 2 then
		e.damage = e.damage * (1 + 0.005*aMob:getSkillValue(12))
	end
	
	-- Imperial ally buff
	if common.rbs then
		if aRef.data.neph[53] == 1 then
			e.damage = e.damage * 1.35
		end
		if tRef.data.neph[53] == 1 then
			e.damage = e.damage * 0.75
		end
	end
	
	-- Dmg depending on fatigue
	---------------------------------
	e.damage = e.damage * aFat * tFat
	---------------------------------
	
	-------------------
	--[[ MAGIC DMG ]]--
	-------------------

	if src == "magic" then
		
		local spell = e.magicSourceInstance.sourceEffects
		local skill = aMob:getSkillValue(10)
		
		-- Resist 20% of incoming magical damage and reduce spell critical chance by 20% per 100 WIL
		local wilFac = math.clamp(1 - 0.002*tMob.willpower.current + 0.002*aMob.attackBonus, 0.2, 1)
		
		-- Noise decreases magic damage
		local noiseFac = math.clamp(1 - 0.01*aMob.sound + 0.01*aMob.attackBonus, 0.05, 1)
		
		---------------------------------------
		e.damage = e.damage * wilFac * noiseFac
		---------------------------------------
		
		-- Offensive NPC stuff
		----------------------
		if aMob.actorType > 0 then
			
			-- Apprentice: +25% spell crit chance and chance to deal half damage
			if aBS == "Apprentice" then
				critChance = critChance + 0.25
				if 0.25 >= math.random() then
					e.damage = 0.5*e.damage
				end
			end
			
			-- Mage: 1.25x spell damage
			if aBS == "Mage" then
				e.damage = e.damage * 1.25
			end

			-- Altmer: bonus damage with missing magicka and double crit chance while affected by Magicka Rush
			if aRace == "high elf" then
				if aMob.magicka.normalized < 0 then
					e.damage = e.damage * (1.5 - 0.5*aMob.magicka.normalized)
				end
				if aMob:isAffectedByObject(tes3.getObject("_neph_race_he_pwRush")) then
					critChance = critChance * 2
				end
			end
			
			-- Destruction 30: extra scaling critical spell damage
			if common.skills and skill >= 30 then
				critDmg = critDmg + 0.01*skill
			end
			
			-- Magic sneak attack and Sneak 30: Extra damage while crouching (seems only really useable by the player...)
			if aMob.isSneaking then
			
				temp			= 0
				local temp2		= 0
				local atkMod	= 1
				local sneak30	= 1
				
				if aRef == p and p.data.neph[91] == 1 then
					atkMod = atkMod + 0.005*pMob.sneak.base
					if common.rbs then
						if p.object.race.id:lower() == "khajiit" then
							atkMod = atkMod + 0.25
						end
						if p.data.neph[99] == "Shadow" then
							atkMod = atkMod + 0.25
						end
					end
				end
				
				for i = 1, #spell do
					if spell[i].rangeType == tes3.effectRange.target then
						temp = 1
					elseif spell[i].rangeType == tes3.effectRange.touch then
						temp2 = 1
					end
				end
				
				if temp == 1 then
					if aRef == p and p.data.neph[91] == 1 then
						atkMod = 1.5 * atkMod
						tes3.messageBox("Magic Sneak Attack: %.2f" .. "x!", atkMod)
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if common.skills and aRef.data.neph[98] >= 1 and aMob.sneak.base >= 30 then
						sneak30 = 2
					end
				elseif temp == 0 and temp2 == 1 then
					if aRef == p and p.data.neph[91] == 1 then
						atkMod = 2 * atkMod
						tes3.messageBox("Magic Sneak Attack: %.2f" .. "x!", atkMod)
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if common.skills and aMob.sneak.base >= 30 then
						sneak30 = sneak30 * 1.5
					end
				end
				
				e.damage = e.damage * atkMod * sneak30
			end
			
		-- Creature stuff
		-----------------
		else
			-- Creatures with increased critical spell chance: Ascended Sleepers (incl. Dagoths), Daedroth, Atronachs
			if aRef.data.neph[83] then
				critChance = critChance + 0.25
			end
		end
		
		------------------------------------------------------------------------------------------------------------
		e.damage = e.damage * (0.5 + 0.005*skill + 0.0025*aMob.willpower.current + 0.0025*aMob.intelligence.current)
		------------------------------------------------------------------------------------------------------------
		critChance = critChance * wilFac
		if critChance >= critRoll then
			e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
		end
		
		-- Destruction perks: on-hit stuff
		---------------------
		if aRef ~= tRef and aMob then -- avoid triggering perk effects on some applied perk effects :P
		
			if common.skills then
				onHitMarker = tes3.createReference{
					object = "_neph_acti_castMarker",
					position = tMob.position,
					cell = tMob.cell
				}
				onHitMarker.sceneNode.appCulled = true
			end
			
			local alt = tMob:getSkillValue(11)
			
			for i = 1, #spell do
				
				if common.skills then
				
					-- Fire Damage
					if spell[i].id == 14 and tMob.resistFire < 100 then
						-- Shattering
						if tMob.paralyze > 0 and tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_freeze")) and spell[i].max > 10 then
							local shatter = tes3.getObject("_neph_onhit_Shatter").effects[1]
							shatter.max = math.ceil(0.2*tMob.health.base)
							shatter.min = math.ceil(0.2*tMob.health.base)
							if aRef.position:distance(tRef.position) < 221 then
								tes3.applyMagicSource{
									reference = aRef,
									name = "Instant Frost Resist",
									effects = {{id = 91, duration = 1, min = 100, max = 100}}
								}
							end
							tes3.cast{
								reference = onHitMarker,
								target = tMob,
								spell = "_neph_onhit_Shatter",
								instant = true
							}
							if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
								tRef.data.neph[96] = 1
							end
							tes3.removeEffects{reference = tRef, effect = 45}
						end
						-- Alteration 30: Take less corresponding damage the lower your health
						if alt >= 30 then
							if tMob.health.normalized < 1 and tMob.resistFire > 0 then
								e.damage = e.damage * (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
							end
						end
						if skill >= 30 and (0.0009*skill + 0.0006*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistFire, 0) >= math.random() then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_onhit_Daze"}
						end
						if skill >= 60 and (0.006*skill + 0.004*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistFire, 0) >= math.random()
						and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_burn")) then
							local burn = tes3.getObject("_neph_perk_10_burn").effects[1]
							burn.min = math.max(math.abs(0.2*e.damage), 1)
							burn.max = math.max(math.abs(0.2*e.damage), 1)
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_burn"
							}
							if tes3.isAffectedBy{reference = tRef, effect = 75} then
								tes3.removeEffects{reference = tRef, effect = 75}
							end
						end
						if skill >= 90 and critChance * wilFac * math.max(1 - 0.01*tMob.resistFire, 0) >= critRoll
						and tes3.isAffectedBy{reference = tRef, effect = 14} then
							local detonate = tes3.getObject("_neph_perk_10_detonate").effects[1]
							detonate.min = math.max(math.abs(e.damage), 1)
							detonate.max = math.max(math.abs(e.damage), 1)
							if aRef.position:distance(tRef.position) < 221 then
								tes3.applyMagicSource{
									reference = aRef,
									name = "Instant Fire Resist",
									effects = {{id = 90, duration = 1, min = 100, max = 100}}
								}
							end
							tes3.cast{
								reference = onHitMarker,
								target = tRef,
								spell = "_neph_perk_10_detonate",
								instant = true
							}
						end
					
					-- Shock Damage
					elseif spell[i].id == 15 and tMob.resistShock < 100 then
						-- Shattering
						if tMob.paralyze > 0 and tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_freeze")) and spell[i].max > 10 then
							local shatter = tes3.getObject("_neph_onhit_Shatter").effects[1]
							shatter.max = math.ceil(0.2*tMob.health.base)
							shatter.min = math.ceil(0.2*tMob.health.base)
							if aRef.position:distance(tRef.position) < 221 then
								tes3.applyMagicSource{
									reference = aRef,
									name = "Instant Frost Resist",
									effects = {{id = 91, duration = 1, min = 100, max = 100}}
								}
							end
							tes3.cast{
								reference = onHitMarker,
								target = tMob,
								spell = "_neph_onhit_Shatter",
								instant = true
							}
							if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
								tRef.data.neph[96] = 1
							end
							tes3.removeEffects{reference = tRef, effect = 45}
						end
						-- Alteration Scaling: Take less corresponding damage the lower your health
						if alt >= 30 then
							if tMob.health.normalized < 1 and tMob.resistShock > 0 then
								e.damage = e.damage * (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
							end
						end
						if skill >= 30 and (0.0009*skill + 0.0006*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistShock, 0) >= math.random() then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_onhit_Daze"
							}
						end
						if skill >= 60 and tRef.data.neph[96] == 0 and (0.003*skill + 0.002*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistShock, 0) >= math.random() then
							tRef.data.neph[96] = 1
						end
						if skill >= 90 and critChance * wilFac * math.max(1 - 0.01*tMob.resistShock, 0) >= critRoll then
							for _, actor in pairs(tes3.findActorsInProximity{reference = tRef, range = 442}) do
								if actor ~= aMob and actor ~= tMob then
									if aMob.position:distance(actor.position) <= spell[i].radius*22.1 then
										tes3.applyMagicSource{
											reference = aRef,
											name = "Instant Shock Resist",
											effects = {{id = 92, duration = 1, min = 100, max = 100}}
										}
									end
									tes3.cast{
										reference = onHitMarker,
										target = actor,
										spell = e.magicSourceInstance.source,
										instant = true
									}
									if not actor.inCombat then
										tes3.triggerCrime{type = 1, victim = actor}
										actor:startCombat(aMob)
									end
									break -- should limit chaining to 1
								end
							end
						end
					
					-- Frost Damage
					elseif spell[i].id == 16 and tMob.resistFrost < 100 then
						-- Alteration Scaling: Take less corresponding damage the lower your health
						if alt >= 30 then
							if tMob.health.normalized < 1 and tMob.resistFrost > 0 then
								e.damage = e.damage * (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
							end
						end
						if skill >= 60 and tRef.data.neph[31] == 0
						and (0.006*skill + 0.004*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistFrost, 0) >= math.random() then
							tRef.data.neph[31] = 1
							tes3.applyMagicSource{
								reference = tRef,
								name = "Chill",
								effects = {
									{id = 17, attribute = 4, duration = 5, min = 100, max = 100},
									{id = 21, skill = 8, duration = 5, min = 100, max = 100},
									{id = 21, skill = 20, duration = 5, min = 100, max = 100}
								}							
							}
							timer.start{
								duration = 5,
								callback = function()
									tRef.data.neph[31] = 0
								end
							}
						end
						if skill >= 90 and critChance * wilFac * math.max(1 - 0.01*tMob.resistFrost, 0) >= critRoll
						and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_freeze")) then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_freeze"
							}
						end
					
					-- Damage Health
					elseif spell[i].id == 23 and tMob.resistMagicka < 100 then
						-- Alteration Scaling: Take less corresponding damage the lower your health
						if alt >= 30 then
							if tMob.health.normalized < 1 and tMob.resistMagicka > 0 then
								e.damage = e.damage * (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
							end
						end
						if skill >= 60 and (0.006*skill + 0.004*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistMagicka, 0) >= math.random()
						and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_bleed")) then
							local bleed = tes3.getObject("_neph_perk_10_bleed").effects[1]
							bleed.min = math.max(math.abs(0.2*e.damage), 1)
							bleed.max = math.max(math.abs(0.2*e.damage), 1)
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_bleed"
							}
							if tes3.isAffectedBy{reference = tRef, effect = 75} then
								tes3.removeEffects{reference = tRef, effect = 75}
							end
						end
						if skill >= 90 and critChance * wilFac * math.max(1 - 0.01*tMob.resistMagicka, 0) >= critRoll and tRef.data.neph[30] == 0 then
							local lacerate = tes3.getObject("_neph_perk_10_lacerate").effects[1]
							lacerate.min = math.max(math.abs(0.002*tMob.health.base*e.damage), 1)
							lacerate.max = math.max(math.abs(0.002*tMob.health.base*e.damage), 1)
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_lacerate"
							}
							tRef.data.neph[30] = 1
							timer.start{
								duration = 1,
								callback = function()
									tRef.data.neph[30] = 0
								end
							}
						end
					end
				end
				
				-- Poison
				if spell[i].id == 27 then
					if common.rbs then
						-- Serpent: Poison Weakness to poisoned targets
						if aBS == "Serpent" then
							if tRef.data.neph[52] == 0 then
								tes3.applyMagicSource{
									reference = tRef,
									name = "Serpent's Curse",
									effects = {{id = 35, duration = 5, min = math.max(math.abs(0.5*e.damage), 1), max = math.max(math.abs(0.5*e.damage), 1)}}
								}
								tRef.data.neph[52] = 1
								timer.start{
									duration = 1,
									callback = function()
										tRef.data.neph[52] = 0
									end
								}
							end
							-- extra poison damage the lower the target's health
							if tMob.health.normalized < 1 then
								e.damage = e.damage * (1.5 - 0.5*tMob.health.normalized)
							end
						end
					end
					if common.skills then
						-- Alteration 30: Take less corresponding damage the lower your health
						if alt >= 30 then
							if tMob.health.normalized < 1 and tMob.resistPoison > 0 then
								e.damage = e.damage * (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
							end
						end
						if skill >= 60 and (0.006*skill + 0.004*aLuck) * wilFac * math.max(1 - 0.01*tMob.resistPoison, 0)
						and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_cont")) then
							local contaminate = tes3.getObject("_neph_perk_10_cont").effects[1]
							contaminate.min = math.max(math.abs(0.2*e.damage), 1)
							contaminate.max = math.max(math.abs(0.2*e.damage), 1)
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_cont"
							}
							if tes3.isAffectedBy{reference = tRef, effect = 75} then
								tes3.removeEffects{reference = tRef, effect = 75}
							end
						end
						if skill >= 90 and critChance * wilFac * math.max(1 - 0.01*tMob.resistMagicka, 0) >= critRoll
						and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_weaken")) then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_weaken"
							}
						end
					end
				end
			end
			if onHitMarker then
				timer.start{
					duration = 0.1,
					callback = function()
						onHitMarker:delete()
					end
				}
			end
		end
		--if aRef == tes3.player then tes3.messageBox("damage: %f, chance: %f, crite.damage: %f", e.damage, critChance, critDmg) end
	
	-------------------------	
	--[[ PHYSICAL DAMAGE ]]--
	-------------------------
	
	else
	
		local swing, dir, weap
		
		if src ~= "script" then
			swing		= aMob.actionData.attackSwing
			dir			= aMob.actionData.physicalAttackType
			weap		= aRef.data.neph[11]
		else
			swing		= common.scriptDmg.swing
			dir			= common.scriptDmg.dir
			weap		= common.scriptDmg.weap
		end
		--if aRef == tes3.player then tes3.messageBox("Raw Damage: %f", e.damage) end
		local aStr		= aMob.strength.current
		local aAgi		= aMob.agility.current
		
		-- Resist 20% of incoming physical damage and reduce critical chance by 20% per 100 END
		local endFac = math.clamp(1 - 0.002*tMob.endurance.current + 0.002*aMob.attackBonus, 0.2, 1)
		
		-- Blind decreases weapon damage, counteracted by fortify attack
		local blindFac = math.clamp(1 - 0.01*aMob.blind + 0.01*aMob.attackBonus, 0.05, 1)
		
		---------------------------------------
		e.damage = e.damage * endFac * blindFac
		---------------------------------------
		
		-- Freenze-Shatter combo
		if common.skills then
			if tMob.paralyze > 0 and tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_freeze")) and swing == 1 then
			
				onHitMarker = tes3.createReference{
					object = "_neph_acti_castMarker",
					position = tMob.position,
					cell = tMob.cell
				}
				onHitMarker.sceneNode.appCulled = true
				
				local shatter = tes3.getObject("_neph_onhit_Shatter").effects[1]
				shatter.max = math.ceil(0.2*tMob.health.base)
				shatter.min = math.ceil(0.2*tMob.health.base)
				tes3.applyMagicSource{
					reference = aRef,
					name = "Instant Frost Resist",
					effects = {{id = 91, duration = 1, min = 100, max = 100}}
				}
				tes3.cast{
					reference = onHitMarker,
					target = tMob,
					spell = "_neph_onhit_Shatter",
					instant = true
				}
				if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
					tRef.data.neph[96] = 1
				end
				tes3.removeEffects{reference = tRef, effect = tes3.effect.paralyze}
				timer.start{
					duration = 0.1,
					callback = function()
						onHitMarker:delete()
					end
				}
			end
		end

		-- NPC defensive perks
		----------------------
		if tMob.actorType > 0 then		
			-- Argonian: Scales reduce total physical damage by 10%
			if common.rbs and tRace == "argonian" then
				e.damage = e.damage * 0.9
			end

		-- Defensive creature perks
		---------------------------
		else	
			-- Skeleton creatures are weak to unarmed and blunt attacks, but resist everything else
			if tRef.data.neph[75] then
				if weap < 0 or (weap >= 3 and weap <= 5) then
					e.damage = e.damage * 1.5
				else
					e.damage = e.damage * 0.65
				end
			end
			
			-- Creature pseudo-armor rating (using vanilla formula)
			if tRef.data.neph[69] > 0 and p.data.neph[91] == 0 then
				e.damage = e.damage/math.min(1 + tRef.data.neph[69]/e.damage, 4)
			end
		end
		
		-- NPC Offensive Stuff
		----------------------
		if aMob.actorType > 0 then
			
			if common.rbs then

				-- Khajiit: Melee jump and dash attacks deal 1.5x damage
				if aRace == "khajiit" and weap < 9 and (aRef.data.neph[93] >= 1 or aRef.data.neph[98] >= 2) then
					e.damage = e.damage * 1.5
				end
			
				-- Bosmer: 1.25x damage and +15% crit chance with ranged weapons while crouching
				if aRace == "wood elf" and aMob.isSneaking and weap >= 9 and weap <= 11 then
					e.damage = e.damage * 1.25
					critChance = critChance + 0.15
				end
				
				-- Dunmer: Restore Magicka on hit and on-hit damage while affected by toggle
				if aRace == "dark elf" then
					tes3.modStatistic{
						reference = aRef,
						name = "magicka",
						current = 0.05*aMob.magicka.base,
						limitToBase = true
					}
					if aMob:isAffectedByObject(tes3.getObject("_neph_race_de_togConvMagAb")) and aMob.magicka.normalized >= 0.1 then
						tes3.modStatistic{
							reference = aRef,
							name = "magicka",
							current = -0.1*aMob.magicka.base
						}
						tes3.modStatistic{
							reference = tRef,
							name = "health",
							current = -0.05*aMob.magicka.base
						}
					end
				end
				
				-- Nord: STR and AGI bonus on attack
				if aRace == "nord" then
					if weap == 2 or (weap >= 4 and weap <= 6) or (weap >= 8 and weap <= 10) then
						tes3.applyMagicSource{
							reference = aRef,
							name = "Nord Fury",
							effects = {
								{id = 79, attribute = 0, duration = 5, min = 5, max = 5},
								{id = 79, attribute = 3, duration = 5, min = 5, max = 5}
							}
						}
					else
						tes3.applyMagicSource{
							reference = aRef,
							name = "Nord Fury",
							effects = {
								{id = 79, attribute = 0, duration = 3, min = 5, max = 5},
								{id = 79, attribute = 3, duration = 3, min = 5, max = 5}
							}
						}
					end
					-- damage bonus on high fatigue in return for increased fatigue costs
					e.damage = e.damage * (1 + 0.35*aMob.fatigue.normalized)
				end
				
				-- Orc: Increased damage on low health and Berserk Rage offensive effects (melee physical only)
				if aRace == "orc" then
					if aMob:isAffectedByObject(tes3.getObject("_neph_race_or_pwBerserk")) and weap < 9 then
						e.damage = e.damage * 2
					end
					if weap < 9 and aMob.health.normalized < 1 then
						e.damage = e.damage * (1.5 - 0.5*aMob.health.normalized)
					end
				end
				
				-- Warrior: 1.25x weapon damage
				if aBS == "Warrior" then
					e.damage = e.damage * 1.25
				end
			end
			
			-- Sneak 30: Extra damage while crouching
			if common.skills and aMob.sneak.base >= 30 and aMob.isSneaking then
				if weap >= 9 then
					e.damage = e.damage * 1.5
				else
					if aRef.data.neph[98] >= 1 then
						e.damage = e.damage * 2
					end
				end
			end
		
		-- Offensive creature perks
		---------------------------
		else			
			-- Dreugh and Old Blue Fin gain +25% crit chance
			if common.config.creaPerks and aRef.data.neph[76] then
				critChance = critChance + 0.25
			end
		end
		
		-- Stuff including (potentially) all actors
		-------------------------------------------
		if common.skills then
		
			-- Athletics 90: Running attacks always deal +100% increased crit damage, every 10s
			if aMob:getSkillValue(8) >= 90 and aMob.isRunning and aMob.isMovingForward and aRef.data.neph[21] == 0 and weap >= -1 then
				critDmg = critDmg + 1
				critChance = 5
				aRef.data.neph[21] = 1
				timer.start{
					duration = 10,
					callback = function()
						aRef.data.neph[21] = 0
					end
				}
				if common.config.comboMsg and aRef == p then
					tes3.messageBox("Critical sprint attack!")
				end
			end
			
			-- Acrobatics 90: Jump or dash attacks always deal +100% increased crit damage, every 10s
			if aMob:getSkillValue(20) >= 90 and (aRef.data.neph[93] >= 1 or aRef.data.neph[98] >= 2) and aRef.data.neph[20] == 0 and weap >= -1 then
				critDmg = critDmg + 1
				critChance = 5
				aRef.data.neph[20] = 1
				timer.start{
					duration = 10,
					callback = function()
						aRef.data.neph[20] = 0
					end
				}
				if common.config.comboMsg and aRef == p then
					if p.data.neph[93] >= 1 then
						tes3.messageBox("Critical jump attack!")
					elseif p.data.neph[98] >= 2 then
						tes3.messageBox("Critical dash attack!")
					end
				end
			end
					
			-- Hand-to-Hand
			if aMob.actorType > 0 and weap == -1 then
				skill = aMob:getSkillValue(26)
				if skill >= 60 and dir == 3 and swing == 1 then
					if aRef == p and tMob.paralyze == 0 then
						V.KIK()
					end
					if (0.0012*aMob.handToHand.current + 0.0008*aLuck)*endFac >= math.random() and tMob.readiedWeapon and not string.find(tMob.readiedWeapon.object.id, "bound") then
						tes3.dropItem{reference = tRef, item = tMob.readiedWeapon.object}
					end
				end
				if skill >= 30 then
					for i = 6, 7 do
						if aRef.data.neph[i] == 1 then
							critDmg = critDmg + 0.005*skill
						elseif aRef.data.neph[i] == 0 then
							critChance = critChance + 0.0015*skill
						end
					end
				end
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
				if skill >= 30 then
					for i = 6, 7 do
						if aRef.data.neph[i] == 2 then
							local arPen = tes3.getObject("_neph_perk_26_30ArPen").effects[1]
							arPen.max = 0.02 * e.damage * skill
							arPen.min = 0.02 * e.damage * skill
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_26_30ArPen"
							}
							if (0.0015*skill + 0.001*aLuck)*endFac >= math.random() then
								tes3.applyMagicSource{
									reference = tRef,
									source = "_neph_onhit_Daze"
								}
							end
						end
					end
				end
				if aRef.object.race.isBeast and aRef.data.neph[6] == -1 and aRef.data.neph[7] == -1 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Bleeding",
						effects = {{id = 23, duration = 5, min = math.max(0.2*e.damage, 1), max = math.max(0.2*e.damage, 1)}}
					}
					if tes3.isAffectedBy{reference = tRef, effect = 75} then
						tes3.removeEffects{reference = tRef, effect = 75}
					end
				end
				if skill >= 90 and swing == 1 then
				
					local eleFist
					local altFac = 1
					local wilFac = math.max(1 - 0.002*tMob.willpower.current, 0.2)
									
					if aMob:isAffectedByObject(tes3.getObject("_neph_perk_26_fireToggleAb")) then
						if tMob.health.normalized < 1 and tMob.resistFire > 0 and tMob.resistFire < 100 then
							altFac = (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
						end
						eleFist = tes3.getObject("_neph_perk_26_fireFist").effects[1]
						eleFist.min = math.ceil(0.5*e.damage*altFac)
						eleFist.max = math.ceil(0.5*e.damage*altFac)
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_perk_26_fireFist",
						}
						if 0.001*aLuck*wilFac >= math.random() then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_onhit_Daze"
							}
						end
						if critChance*wilFac >= critRoll then
							onHitMarker = onHitMarker or tes3.createReference{
								object = "_neph_acti_castMarker",
								position = tMob.position,
								cell = tMob.cell
							}
							onHitMarker.sceneNode.appCulled = true
							local detonate = tes3.getObject("_neph_perk_10_detonate").effects[1]
							detonate.min = math.ceil(e.damage*altFac)
							detonate.max = math.ceil(e.damage*altFac)
							if aRef.position:distance(tRef.position) < 221 then
								tes3.applyMagicSource{
									reference = aRef,
									name = "Instant Fire Resist",
									effects = {{id = 90, duration = 1, min = 100, max = 100}}
								}
							end
							tes3.cast{
								reference = onHitMarker,
								target = tRef,
								spell = "_neph_perk_10_detonate",
								instant = true
							}
						end
					
					elseif aMob:isAffectedByObject(tes3.getObject("_neph_perk_26_shockToggleAb")) then
						if tMob.health.normalized < 1 and tMob.resistShock > 0 and tMob.resistShock < 100 then
							altFac = (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
						end
						eleFist = tes3.getObject("_neph_perk_26_stormFist").effects[1]
						eleFist.min = math.ceil(0.5*e.damage*altFac)
						eleFist.max = math.ceil(0.5*e.damage*altFac)
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_perk_26_stormFist"
						}
						if 0.001*aLuck*wilFac >= math.random() then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_onhit_Daze"
							}
						end
						if critChance*wilFac*math.max(1 - 0.01*tMob.sanctuary, 0) >= critRoll and tRef.data.neph[96] == 0 then
							tRef.data.neph[96] = 1
						end
						
					elseif aMob:isAffectedByObject(tes3.getObject("_neph_perk_26_frostToggleAb")) then
						if tMob.health.normalized < 1 and tMob.resistFrost > 0 and tMob.resistFrost < 100 then
							altFac = (1 - 0.0035*tMob:getSkillValue(11) * (1 - tMob.health.normalized))
						end
						eleFist = tes3.getObject("_neph_perk_26_frostFist").effects[1]
						eleFist.min = math.ceil(0.5*e.damage*altFac)
						eleFist.max = math.ceil(0.5*e.damage*altFac)
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_perk_26_frostFist"
						}
						if critChance*wilFac >= critRoll and not tMob:isAffectedByObject(tes3.getObject("_neph_perk_10_freeze")) then
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_perk_10_freeze"
							}
							if common.config.comboMsg and aRef == p and tMob.paralyze > 0 then
								tes3.messageBox("Target frozen!")
							end
						end
					end
					if onHitMarker then
						timer.start{
							duration = 0.1,
							callback = function()
								onHitMarker:delete()
							end
						}
					end
				end
			
			-- Short Blade
			elseif weap == 0 then
				skill = aMob:getSkillValue(22)
				if skill >= 30 and aRef.data.neph[18] > 0 then
					for i = 1, 5 do
						if aRef.data.neph[18] == i then
							aRef.data.neph[18] = i - 1
							critChance = critChance + 0.2*i
							break
						end
					end
				end
				if skill >= 60 and aRef.data.neph[98] >= 2 then
					e.damage = e.damage * 1.5
				end
				-- Short Blade 90 handled by onAttack
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
				if skill >= 60 and aRef.data.neph[98] >= 2 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Bleeding",
						effects = {{id = 25, duration = 5, min = math.max(0.2*e.damage, 1), max = math.max(0.2*e.damage, 1)}}
					}
					if tes3.isAffectedBy{reference = tRef, effect = 75} then
						tes3.removeEffects{reference = tRef, effect = 75}
					end
				end

			-- Long Blade
			elseif weap == 1 or weap == 2 then
				skill = aMob:getSkillValue(5)
				if skill >= 30 then
					critChance = critChance + 0.0025*skill
				end
				if skill >= 90 then
					if dir == 1 and tRef.data.neph[12] < 3 then
						for i = 0, 2 do
							if tRef.data.neph[12] == i then
								tRef.data.neph[12] = i + 1
								break
							end
						end
					end
					if swing == 1 then
						if dir == 2 and tRef.data.neph[12] > 0 then
							for i = 1, 3 do
								if tRef.data.neph[12] == i then
									critChance = 5
									critDmg = critDmg + 0.5 * i
									tRef.data.neph[12] = 0
									if common.config.comboMsg then
										tes3.messageBox("Long blade Combo Attack!")
									end
									break
								end
							end
						end
						if dir == 3 and tRef.data.neph[12] == 3 then
							if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
								tRef.data.neph[96] = 1
							end
							if tRef.data.neph[11] >= 0 and not string.find(tMob.readiedWeapon.object.id, "bound") and 0.002*aLuck*endFac >= math.random() then
								tes3.dropItem{reference = tRef, item = tMob.readiedWeapon.object}
							end
							tRef.data.neph[12] = 0
							if common.config.comboMsg then
								tes3.messageBox("Long blade Combo Attack!")
							end
						end
					end
				end
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.2*e.damage, max = 0.2*e.damage}}
						}
					end
				end
				if skill >= 60 and dir == 3 and swing == 1 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Bleeding",
						effects = {
							{id = 23, duration = 5, min = math.max(0.2*e.damage, 1), max = math.max(0.2*e.damage, 1)},
							{id = 17, attribute = 4, duration = 5, min = tMob.speed.current, max = tMob.speed.current},
							{id = 21, skill = 8, duration = 5, min = tMob:getSkillValue(8), max = tMob:getSkillValue(8)},
							{id = 21, skill = 20, duration = 5, min = tMob:getSkillValue(20), max = tMob:getSkillValue(20)}
						}
					}
					if tes3.isAffectedBy{reference = tRef, effect = 75} then
						tes3.removeEffects{reference = tRef, effect = 75}
					end
				end
			
			-- Blunt Weapon
			elseif weap >= 3 and weap <= 5 then
				skill = aMob:getSkillValue(4)
				if skill >= 90 and swing == 1 then
					if dir == 3 and tRef.data.neph[13] < 1 then
						tRef.data.neph[13] = 1
						if aRef == p and tMob.paralyze == 0 then
							V.KIK()
						end
					end
					if dir == 1 and tRef.data.neph[13] == 1 then
						tRef.data.neph[13] = 0
						if tRef.data.neph[11] >= 0 and 0.002*aLuck*endFac >= math.random() then
							if not string.find(tMob.readiedWeapon.object.id, "bound") then 
								tes3.dropItem{reference = tRef, item = tMob.readiedWeapon.object}
							end
						end
						if tRef.data.neph[8] >= 0 then
							if not string.find(tMob.readiedShield.object.id, "bound") then 
								tes3.dropItem{reference = tRef, item = tMob.readiedShield.object}
							end
						end
						for i = 3, 6 do
							if tes3.isAffectedBy{reference = tRef, effect = i} then
								tes3.removeEffects{reference = tRef, effect = i}
							end
						end
						if common.config.comboMsg then
							tes3.messageBox("Blunt Weapon Combo Attack!")
						end
					end
				end
				if skill >= 60 and swing == 1 and dir == 2 then
					critChance = critChance * 2
					if aRef.data.neph[93] == 2 then
						e.damage = e.damage * (1 + 0.01*aMob:getSkillValue(20))
					end
				end
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
				if skill >= 30 then
					if (0.006*skill + 0.004*aLuck)*endFac >= math.random() then
						local arPen = tes3.getObject("_neph_perk_26_30ArPen").effects[1]
						arPen.max = 2 * e.damage
						arPen.min = 2 * e.damage
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_perk_26_30ArPen"
						}
					end
					if (0.0015*skill + 0.001*aLuck)*endFac >= math.random() then
						timer.delayOneFrame(function()
							tes3.applyMagicSource{
								reference = tRef,
								source = "_neph_onhit_Daze"
							}
						end)
					end
				end
			
			-- Spear
			elseif weap == 6 then
				skill = aMob:getSkillValue(7)
				if skill >= 30 then
					critDmg = critDmg + 0.01*skill
				end
				if skill >= 60 and dir <= 2 and swing == 1 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Slow",
						effects = {
							{id = 23, duration = 5, min = 0.2*e.damage*(((critDmg - 1) * hA50) + 1), max = 0.2*e.damage*(((critDmg - 1) * hA50) + 1)},
							{id = 17, attribute = 4, duration = 5, min = tMob.speed.current, max = tMob.speed.current},
							{id = 21, skill = 8, duration = 5, min = tMob:getSkillValue(8), max = tMob:getSkillValue(8)},
							{id = 21, skill = 20, duration = 5, min = tMob:getSkillValue(20), max = tMob:getSkillValue(20)}
						}
					}
				end
				if skill >= 90 and dir == 3 and swing == 1 and (aRef.data.neph[93] >= 1 or aRef.data.neph[98] >= 2) then
					critChance = critChance * 2
				end
				-----------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				-----------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
			
			-- Axe
			elseif weap == 7 or weap == 8 then
				e.damage = e.damage * 0.9 -- axe nerf
				skill = aMob:getSkillValue(6)
				if skill >= 90 then
					if tRef.data.neph[14] < 3 then
						for i = 0, 2 do
							if tRef.data.neph[14] == i then
								tRef.data.neph[14] = i + 1
								break
							end
						end
					else
						if swing == 1 and dir < 3 then
							if weap == 7 then
								temp = 0.05
							else
								temp = 0.1
							end
							tes3.applyMagicSource{
								reference = tRef,
								name = "Maximum Health Damage",
								effects = {{id = 23, min = temp*tMob.health.base, max = temp*tMob.health.base}}
							}
							tRef.data.neph[14] = 0
							if common.config.comboMsg then
								tes3.messageBox("Axe Combo Attack!")
							end
						end
					end 
				end
				if skill >= 60 and swing == 1 and dir == 1 and tRef.data.neph[96] == 0 and 0.01*aLuck*endFac >= math.random() then
					tRef.data.neph[96] = 1
				end
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
				if skill >= 30 and (0.006*skill + 0.004*aLuck)*endFac >= math.random() then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Bleeding",
						effects = {{id = 23, duration = 5, min = math.max(0.1*e.damage, 1), max = math.max(0.1*e.damage, 1)}}
					}
					if tes3.isAffectedBy{reference = tRef, effect = 75} then
						tes3.removeEffects{reference = tRef, effect = 75}
					end
				end
			
			-- Marksman
			elseif weap >= 9 and weap <= 11 then
				skill = aMob:getSkillValue(23)
				if skill >= 30 and aRef.data.neph[24] < 5 then
					aRef.data.neph[24] = aRef.data.neph[24] + 1
				end
				if skill >= 90 then
					if tRef.data.neph[15] < 3 then
						for i = 0, 2 do
							if tRef.data.neph[15] == i then
								tRef.data.neph[15] = i + 1
								break
							end
						end
					else
						if swing == 1 then
							critChance = 5
							critDmg = critDmg + 1
							tes3.applyMagicSource{
								reference = tRef,
								name = "Bleeding",
								effects = {{
									id = 23,
									duration = 5,
									min = math.max(0.1*e.damage*(((critDmg - 1) * hA50) + 1)),
									max = math.max(0.1*e.damage*(((critDmg - 1) * hA50) + 1))
								}}
							}
							if tes3.isAffectedBy{reference = tRef, effect = 75} then
								tes3.removeEffects{reference = tRef, effect = 75}
							end
							if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
								tRef.data.neph[96] = 1
							end
							tRef.data.neph[15] = 0
							if common.config.comboMsg then
								tes3.messageBox("Marksman Combo Shot!")
							end
						end
					end
				end
				---------------------------------------------------------------------
				e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
				---------------------------------------------------------------------
				if aMob:isAffectedByObject(tes3.getObject("_neph_bs_war_pwMight")) then
					critChance = 2*critChance
				end
				if critChance*endFac >= critRoll then
					e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
					if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
					if tRef.data.neph[95] == 0 then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockdown",
							effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
						}
					end
				end
			end
			
		else -- standard crit damage w/o skills module
			if weap >= -1 then
				for weaponID, skillID in pairs(common.weaponSkill) do
					if weap == weaponID then
						-------------------------------------------------------------------------------------------
						e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + aMob:getSkillValue(skillID)*0.005)
						-------------------------------------------------------------------------------------------
						if critChance*endFac >= critRoll then
							e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
							tes3.playSound{sound = "critical damage", reference = tRef}
							if tRef.data.neph[95] == 0 then
								tes3.applyMagicSource{
									reference = tRef,
									name = "Knockdown",
									effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
								}
							end
						end
						break
					end
				end
			end
		end
			
		-- Unarmed Creatures
		if weap == -3 then
			skill = aMob.combat.current
			critChance = critChance + 0.0025*aMob.stealth.current
			critDmg = critDmg + 0.01*aMob.stealth.current

			---------------------------------------------------------------------
			e.damage = e.damage * (0.5 + aStr*0.0025 + aAgi*0.0025 + skill*0.005)
			---------------------------------------------------------------------
			if critChance*endFac >= critRoll then
				e.damage = e.damage * (((critDmg - 1) * hA50) + 1)
				if common.config.critSound then
						tes3.playSound{sound = "critical damage", reference = tRef}
					end
				if tRef.data.neph[95] == 0 then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Knockdown",
						effects = {{id = 25, duration = 1, min = 0.1*e.damage, max = 0.1*e.damage}}
					}
				end
			end
			
			if common.config.creaPerks then
			
				-- Flame Atronachs: Fire on hit
				if string.find(aID, "atronach_flame") then
					onhit = tes3.getObject("_neph_crea_onHit_fire").effects[1]
					onhit.max = math.max(0.1*e.damage, 1)
					onhit.min = math.max(0.1*e.damage, 1)
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_crea_onHit_fire"
					}
				end
				
				-- Frost on hit: Bonelord, Lich, Ghosts, Frost Atronach
				if aRef.data.neph[78] then
					onhit = tes3.getObject("_neph_crea_onHit_frost").effects[1]
					onhit.max = math.max(0.5*e.damage, 1)
					onhit.min = math.max(0.5*e.damage, 1)
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_crea_onHit_frost"
					}
				end
				
				-- Storm Atronachs: Shock on hit
				if string.find(aID, "atronach_storm") then
					onhit = tes3.getObject("_neph_crea_onHit_shock").effects[1]
					onhit.max = math.max(0.5*e.damage, 1)
					onhit.min = math.max(0.5*e.damage, 1)
					tes3.applyMagicSource{
						reference = tRef,
						source = "_neph_crea_onHit_shock"
					}
				end
				
				-- Winged Twilights: Fatigue and Magicka damage on hit
				if string.find(aID, "winged twilight") then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Twilight Claws",
						effects = {
							{id = 24, min = 0.5*e.damage, max = 0.5*e.damage},
							{id = 25, min = 0.5*e.damage, max = 0.5*e.damage}
						}
					}
				end
				
				if 0.01*aLuck >= math.random() then
				
					-- Paralyze on hit: Netch and Hunger
					if string.find(aID:lower(), "netch") or string.find(aID, "hunger") then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Paralysis",
							effects = {{id = 45, duration = 5}}
						}
					end
				
					-- Knockdown on hit: lots of bulky creatures...
					if aRef.data.neph[79] then
						if tRef.data.neph[96] == 0 and math.min(0.01*tMob.sanctuary, 1) <= math.random() then
							tRef.data.neph[96] = 1
						end
					end
				
					-- Ash Ghouls, Zombies and Slaves (incl. Dagoths): "Enfeeble" on hit
					if aRef.data.neph[80] then
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_crea_onHit_weaken"
						}
					end
					
					-- Bleeding: Wolf, Slaughterfish, Dreugh, Nix-Hound, Horker, Fabricants, Boar, Bear, Hircine Aspects, Ash Vampires
					if aRef.data.neph[81] then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Bleeding",
							effects = {{id = 23, duration = 5, min = math.max(0.1*e.damage, 1), max = math.max(0.1*e.damage, 1)}}
						}
						if tes3.isAffectedBy{reference = tRef, effect = 75} then
							tes3.removeEffects{reference = tRef, effect = 75}
						end
					end
								
					-- Poison on hit: Cliff Racer, Aggressive Kwama, Hunger, Netch
					if aRef.data.neph[82] then
						onhit = tes3.getObject("_neph_crea_onHit_poison").effects[1]
						onhit.max = math.max(0.1*e.damage, 1)
						onhit.min = math.max(0.1*e.damage, 1)
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_crea_onHit_poison"
						}
						if tes3.isAffectedBy{reference = tRef, effect = 75} then
							tes3.removeEffects{reference = tRef, effect = 75}
						end
					end
					
					-- Shock on hit: Automatons
					if string.find(aID, "centurion") or string.find(aID:lower(), "imperfect") then
						onhit = tes3.getObject("_neph_crea_onHit_shock").effects[1]
						onhit.max = 0.5*e.damage
						onhit.min = 0.5*e.damage			
						tes3.applyMagicSource{
							reference = tRef,
							source = "_neph_crea_onHit_shock"
						}
					end
				end
			end
		end
			
		-- More on-hit stuff
		--------------------
		
		-- Serpent: Physical hits deal extra poison damage, weakness and slow
		if aMob:isAffectedByObject(tes3.getObject("_neph_bs_ser_pwFangs")) then
			local fangs = tes3.getObject("_neph_bs_ser_pwFangsOnHit").effects
			fangs[1].max = math.max(0.5*e.damage, 1)
			fangs[1].min = math.max(0.5*e.damage, 1)
			fangs[2].max = math.max(0.2*e.damage, 1)
			fangs[2].min = math.max(0.2*e.damage, 1)
			fangs[3].max = tMob.speed.current
			fangs[3].min = tMob.speed.current
			fangs[4].max = tMob:getSkillValue(8)
			fangs[4].min = tMob:getSkillValue(8)
			fangs[5].max = tMob:getSkillValue(20)
			fangs[5].min = tMob:getSkillValue(20)
			tes3.applyMagicSource{
				reference = tRef,
				source = "_neph_bs_ser_pwFangsOnHit"
			}
			if tes3.isAffectedBy{reference = tRef, effect = 75} then
				tes3.removeEffects{reference = tRef, effect = 75}
			end
		end
		
		-- Sneak attacks
		if aMob.isSneaking then
			if aRef == p and p.data.neph[91] == 1 and weap > -2 then
			
				local atkMod = 1
				
				-- Sneak Attack perks...
				atkMod = 1 + 0.005*pMob.sneak.base
				if common.rbs then
					if aBS == "Shadow" then
						atkMod = atkMod + 0.25
					end
					if aRace == "khajiit" then
						atkMod = atkMod + 0.25
					elseif aRace == "wood elf" and weap >= 9 and weap <= 11 then
						atkMod = atkMod + 0.25
					end
				end
				
				-- 2H weapons
				if weap == 2 or weap == 4 or weap == 8 then
					atkMod = 1.25 * atkMod
				-- Ranged Weapons
				elseif weap >= 9 then
					atkMod = 1.5 * atkMod
				-- Spears
				elseif weap == 6 then
					atkMod = 1.75 * atkMod
				-- 1H weapons
				elseif weap == 1 or weap == 3 or weap == 5 or weap == 7 then
					atkMod = 2 * atkMod
				-- H2H and short blades
				elseif weap <= 0 then
					atkMod = 4 * atkMod
				end
				
				common.scriptDmg.aRef	= aRef
				common.scriptDmg.aMob	= aMob
				common.scriptDmg.tMob	= tMob
				common.scriptDmg.dir	= dir
				common.scriptDmg.swing	= swing
				common.scriptDmg.weap	= -2
				
				if common.skills and pMob.sneak.base >= 60 then
					tMob:applyDamage{damage = e.damage * atkMod - e.damage, applyArmor = false, playSound = false}
				else
					tMob:applyDamage{damage = e.damage * atkMod - e.damage, applyArmor = true, playSound = false}
				end
				
				if weap == -1 then
					if 0.01*aMob:getSkillValue(26) * math.max(1 - 0.01*tMob.sanctuary, 0) >= math.random() then
						tes3.applyMagicSource{
							reference = tRef,
							name = "Knockout",
							effects = {{id = 20, duration = 1, min = tMob.fatigue.current, max = tMob.fatigue.current}}
						}
					end
				end
				
				tes3.messageBox("Sneak Attack: %.2f" .. "x!", atkMod)
				tes3.playSound{sound = "critical damage", reference = tRef}
				
			end
		end
		
		-- Bound weapons deal magic health damage instead of normal attack damage
		if weap >= 0 and string.find(aMob.readiedWeapon.object.id:lower(), "bound") then
			if common.rbs and tMob:isAffectedByObject(tes3.getObject("_neph_bs_rit_pwMark")) then
				e.damage = e.damage * 2
			end
			if common.skills then
				tes3.applyMagicSource{
					reference = tRef,
					name = "Bound Weapon Magic Damage",
					effects = {{id = 23, min = e.damage, max = e.damage}}
				}	
				e.damage = 0 -- bound weapons ignore defensive on-hit effects below
			end
		end
		
		-- Creature defensive on-hit
		if tMob.actorType == 0 and e.damage ~= 0 then
		
			if common.config.creaPerks then
			
				-- Corprus creatures heal when hit
				if string.find(tID, "corprus") then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Corprus Healing",
						effects = {{id = 75, duration = 5, min = 0.1*e.damage, max = 0.1*e.damage}}
					}
				end
				
				if 0.01*tMob.luck.current >= math.random() and weap < 9 then
				
					-- Crabs have a chance to reflect melee damage (should support Crab Diversity)
					if string.find(tID, "crab") then
						common.scriptDmg.aRef	= tRef
						common.scriptDmg.aMob	= tMob
						common.scriptDmg.tMob	= aMob
						common.scriptDmg.dir	= dir
						common.scriptDmg.swing	= swing
						common.scriptDmg.weap	= -2
						aMob:applyDamage{damage = 0.2*e.damage, applyArmor = true}
						e.damage = e.damage * 0.8
					end
					
					-- Automatons can zap a melee attacker
					if string.find(tID, "centurion") or string.find(tID:lower(), "imperfect") then
						onhit = tes3.getObject("_neph_crea_onHit_shock").effects[1]
						onhit.max = tRef.object.attacks[1].max
						onhit.min = tRef.object.attacks[1].min
						tes3.applyMagicSource{
							reference = aRef,
							source = "_neph_crea_onHit_shock"
						}
					end
				end
			end
			
		-- NPC defensive on-hit
		-----------------------
		elseif tMob.actorType > 0 and e.damage ~= 0 then
			
			if common.rbs then
			
				-- Atronach: Getting hit restores Magicka equal to 35% of incoming damage
				if tBS == "Atronach" and tMob.magicka.normalized < 1 then
					tes3.modStatistic{
						reference = tRef,
						name = "magicka",
						current = 0.35*e.damage,
						limitToBase = true
					}
				end
				
				-- Tower: 25% chance to reflect melee damage or ignore ranged damage
				if tBS == "Tower" and 0.25 >= math.random() then
					if weap < 9 then
						common.scriptDmg.aRef	= tRef
						common.scriptDmg.aMob	= tMob
						common.scriptDmg.tMob	= aMob
						common.scriptDmg.dir	= dir
						common.scriptDmg.swing	= swing
						common.scriptDmg.weap	= -2
						aMob:applyDamage{damage = e.damage, applyArmor = false}
					end
					e.damage = 0
				end
			end

			if common.skills then
			
				-- Heavy Armor 30: chance (per piece) to disintegrate the attacker's weapon when getting hit
				if tMob.heavyArmor.base >= 30 and 2*hATemp >= math.random() then
					tes3.applyMagicSource{
						reference = aRef,
						name = "Damage Weapon",
						effects = {{id = 37, min = 0.1*tMob.heavyArmor.base, max = 0.1*tMob.heavyArmor.base}}
					}
				end
				-- HA 90: Chance to reflect melee damage while wearing cuirass
				if tMob.heavyArmor.base >= 90 and weap < 9 and tRef.data.neph[1] == 2 and 0.002*tMob.luck.current >= math.random() then
					common.scriptDmg.aRef	= tRef
					common.scriptDmg.aMob	= tMob
					common.scriptDmg.tMob	= aMob
					common.scriptDmg.dir	= dir
					common.scriptDmg.swing	= swing
					common.scriptDmg.weap	= -2
					aMob:applyDamage{damage = e.damage, applyArmor = false}
					e.damage = e.damage * 0.8
				end
					
				-- Pseudo-active blocking
				if tRef == p and p.data.neph[11] >= 0 and p.data.neph[94] == 1 and pMob.block.base >= 30 then
					local hit = tes3.rayTest{
						position = tes3.getCameraPosition(),
						direction = {
							-1*tes3.getCameraVector().x,
							-1*tes3.getCameraVector().y,
							-1*tes3.getCameraVector().z
						}
					}
					if hit.intersection:distance(aRef.position) > hit.intersection:distance(tRef.position) then
						tes3.findGMST("iBlockMaxChance").value = 50 + 0.5*pMob.block.base
						tes3.findGMST("iBlockMinChance").value = 50 + 0.5*pMob.block.base
						if pMob.block.base >= 60 then
							e.damage = e.damage * math.max(1 - 0.01*pMob.block.base, 0)
						end
					end
				end
			end
		end
			
		-- Alteration shield effects (this needs to be last)
		if common.skills and tMob.shield > 0 then
			local alt = tMob:getSkillValue(11)
			-- Alteration 30: Take less corresponding damage the lower your health
			if tMob.health.normalized < 1 then
				e.damage = e.damage * (1 - 0.0035*alt * (1 - tMob.health.normalized))
			end
			-- Alteration 90: Shields reflect 10% melee damage
			if weap < 9 and alt >= 90 then
				common.scriptDmg.aRef	= tRef
				common.scriptDmg.aMob	= tMob
				common.scriptDmg.tMob	= aMob
				common.scriptDmg.dir	= dir
				common.scriptDmg.swing	= swing
				common.scriptDmg.weap	= -2
				aMob:applyDamage{damage = 0.1*tMob.shield, applyArmor = false}
			end
			-- Shields redirect incoming damage to magicka, depending on your current magicka
			if alt >= 60 and tMob.magicka.current >= e.damage*tMob.magicka.normalized then
				tes3.modStatistic{
					reference = tRef,
					name = "magicka",
					current = -e.damage*tMob.magicka.normalized
				}
				e.damage = e.damage * (1 - tMob.magicka.normalized)
			end
		end
		--if aRef == p then tes3.messageBox("Final Damage: %f", e.damage) end
		--if aRef == p then tes3.messageBox("Final Chance: %f", endFac*critChance) end
		--if aRef == p and critChance >= critRoll then tes3.messageBox("Critical Hit!") end
	end
	
	if common.rbs then
	
		-- Steed: Weakness to fall damage
		if src == "fall" and e.reference.data.neph[99] == "Steed" then
			e.damage = e.damage * 2
		end
		
		-- Dunmer Ancestor Guardian: If damage would kill, block damage, dispel ghost and heal
		if e.reference.object.race and e.reference.object.race.id:lower() == "dark elf" then
			local dmg
			if src == "attack" then
				dmg = math.max(2.5 * e.damage, 2)
			else
				dmg = math.max(math.abs(e.damage), 2)
			end
			--mwse.log("damage: %f, health: %f", dmg, e.mobile.health.current)
			if dmg >= e.mobile.health.current then
				for i = 430, 431 do
					if tes3.isAffectedBy{reference = e.reference, effect = i} then
						e.block = true
						tes3.removeEffects{reference = e.reference, effect = i}
						tes3.setStatistic{
							reference = e.reference,
							name = "health",
							current = e.mobile.health.base
						}
					end
				end
			end
		end
	end
end
event.register("damage", damage)


local function damaged(e)

	local tRef = e.reference
	local tMob, aMob, aRef
	
	if e.source ~= "script" then
		aRef		= e.attackerReference
		aMob		= e.attacker
		tMob		= e.mobile
	else
		aRef		= common.scriptDmg.aRef
		aMob		= common.scriptDmg.aMob
		tMob		= common.scriptDmg.tMob
	end
	
	--if aRef == p and e.source ~= "magic" then tes3.messageBox("incoming damage: %f", e.damage) end

	-- Knockdown
	if tRef.data.neph[96] == 1 and tMob.hasFreeAction then
		tRef.data.neph[96] = 2
		tMob.actionData.animationAttackState = 14		
		timer.start{
			duration = common.config.knockDownLimit,
			callback = function()
				tRef.data.neph[96] = 0
			end
		}
	end
		
	-- resetting LA 90 bonus
	if common.skills and tRef.object.objectType == tes3.objectType.npc and tMob:getSkillValue(21) >= 90 and tRef.data.neph[19] > 0 then
		tRef.data.neph[19] = 0
	end
	
	-- health-related NPC powers
	if common.rbs and tMob.actorType == 1 and tMob.health.current > 0 and 0.05 + 0.45 * tRef.object.level/60 >= math.random() then
		if tMob.health.normalized < 0.5 then
			-- Lord
			if tRef.data.neph[50] == "_neph_bs_lor_pwGuardian" then
				tRef.data.neph[50] = "done"
				tes3.cast{
					reference = tRef,
					target = tRef,
					spell = "_neph_bs_lor_pwGuardian",
					instant = true
				}
				if common.config.NPCpowerMsg then
					tes3.messageBox("Star Guardian has been casted.")
				end
			end
		end
		if tMob.health.normalized < 0.2 then
			-- Dunmer
			if tRef.data.neph[51] == "_neph_race_de_pwAncGuardNPC" then
				tRef.data.neph[51] = "done"
				tes3.cast{
					reference = tRef,
					target = tRef,
					spell = "_neph_race_de_pwAncGuardNPC",
					instant = true
				}
				if common.config.NPCpowerMsg then
					tes3.messageBox("Ancestor Guardian has been casted.")
				end
			end
			-- Argonian
			if tRef.data.neph[51] == "_neph_race_ar_pwHistCall" then
				tRef.data.neph[51] = "done"
				tes3.cast{
					reference = tRef,
					target = tRef,
					spell = "_neph_race_ar_pwHistCall",
					instant = true
				}
				if common.config.NPCpowerMsg then
					tes3.messageBox("Call of the Hist has been casted.")
				end
			end
		end
	end
	
	-- HP meter update (thanks to the example of Next Generation Combat)
	if not lfs.fileexists("Data Files/MWSE/mods/Seph/EnemyBars/main.lua") then
		if pMob.hostileActors then
			for hostile in tes3.iterate(tMob.hostileActors) do
				if hostile == pMob then
					local menu_multi = tes3ui.registerID("MenuMulti")
					local health_bar = tes3ui.registerID("MenuMulti_npc_health_bar")
					healthMeter = tes3ui.findMenu(menu_multi):findChild(health_bar)
					if not healthMeterT or healthMeterT.state == timer.expired then
						healthMeter.visible = true
						healthMeter:setPropertyFloat("PartFillbar_current", tMob.health.current)
						healthMeter:setPropertyFloat("PartFillbar_max", tMob.health.base)
						healthMeter = timer.start{
							duration = 3,
							callback = function ()
								healthMeter = tes3ui.findMenu(menu_multi):findChild(health_bar)
								healthMeter.visible = false
							end
						}
					elseif healthMeterT.state == timer.active then
						healthMeterT:reset()
					end
				end
			end
		end
	end
	
	if e.killingBlow then
		if aMob then
			if aRef.object.objectType == tes3.objectType.npc then
				-- Enchant 90: On killing blow, recharge equipped items by 5% of the victim's soul value (or 25 when killing humanoids)
				if common.skills and aMob:getSkillValue(9) >= 90 then
					local ench
					local recharge
					local stack = tes3.getEquippedItem{
						actor = aRef,
						objectType = tes3.objectType.weapon
					}
					if stack then
						ench = stack.object.enchantment
						if ench and (ench.castType == tes3.enchantmentType.onUse or ench.castType == tes3.enchantmentType.onStrike) then
							if stack.variables.charge < ench.maxCharge then
								if tMob.actorType == 0 then
									recharge = math.max(0.05*tRef.object.soul, 1)
								else
									recharge = 25
								end
								if stack.variables.charge + recharge > ench.maxCharge then
									recharge = stack.variables.charge + recharge - ench.maxCharge
								end
								stack.variables.charge = stack.variables.charge + recharge
							end
						end
					end
					for i = 0, 10 do
						stack = tes3.getEquippedItem{
							actor = aRef,
							objectType = tes3.objectType.armor,
							slot = i
						}
						if stack then
							ench = stack.object.enchantment
							if ench and ench.castType == tes3.enchantmentType.onUse then
								if stack.variables.charge < ench.maxCharge then
									if tMob.actorType == 0 then
										recharge = math.max(0.05*tRef.object.soul, 1)
									else
										recharge = 25
									end
									if stack.variables.charge + recharge > ench.maxCharge then
										recharge = stack.variables.charge + recharge - ench.maxCharge
									end
									stack.variables.charge = stack.variables.charge + recharge
								end
							end
						end
					end
					for i = 0, 9 do
						stack = tes3.getEquippedItem{
							actor = aRef,
							objectType = tes3.objectType.clothing,
							slot = i
						}
						if stack then
							ench = stack.object.enchantment
							if ench and ench.castType == tes3.enchantmentType.onUse then
								if stack.variables.charge < ench.maxCharge then
									if tMob.actorType == 0 then
										recharge = math.max(0.05*tRef.object.soul, 1)
									else
										recharge = 25
									end
									if stack.variables.charge + recharge > ench.maxCharge then
										recharge = stack.variables.charge + recharge - ench.maxCharge
									end
									stack.variables.charge = stack.variables.charge + recharge
								end
							end
						end
					end
				end
				
				-- Bosmer: Restore part of target resources on killing blow
				if common.rbs and aRef.object.race.id:lower() == "wood elf" then
					if tMob.actorType == 0 then
						if tRef.object.type == 2 or string.find(tRef.object.id, "atronach") or string.find(tRef.object.id, "centurion") then return end
					end
					tes3.applyMagicSource{
						reference = aRef,
						name = "Green Pact",
						effects = {
							{id = 75, min = 0.2*tMob.health.base, max = 0.2*tMob.health.base},
							{id = 76, min = 0.2*tMob.magicka.base, max = 0.2*tMob.magicka.base},
							{id = 77, min = 0.2*tMob.fatigue.base, max = 0.2*tMob.fatigue.base}
						}
					}
				end
			end
		end
	end
end
event.register("damaged", damaged)


local function onCollision(e)

	local tRef = e.target
	if not tRef then return end

	if tRef.object.objectType ~= tes3.objectType.npc and tRef.objectType ~= tes3.objectType.creature then return end
	
	local aMob = e.mobile
	if not aMob then return end
	local aRef = e.reference
	local tMob = tRef.mobile
	
	if tRef.data.neph[96] == 0 then
			
		-- Steed Power: Trample enemies for 20s
		if common.rbs and aMob:isAffectedByObject(tes3.getObject("_neph_bs_ste_pwTrample")) then
			if aMob.isMovingForward and aMob.isRunning and not (aMob.block.base >= 90 and aRef.data.neph[94] == 1) then
				common.scriptDmg.aRef	= p
				common.scriptDmg.aMob	= aMob
				common.scriptDmg.tMob	= tRef.mobile
				common.scriptDmg.dir	= 3
				common.scriptDmg.swing	= 1
				common.scriptDmg.weap	= -2
				tMob:applyDamage{damage = 0.1*aMob.encumbrance.current + 0.1*aMob.health.base, applyArmor = true}
				if tRef.data.neph[96] == 0 and tMob.hasFreeAction then
					tRef.data.neph[96] = 2
					tMob.actionData.animationAttackState = 14
					timer.start{
						duration = common.config.knockDownLimit,
						callback = function()
							tRef.data.neph[96] = 0
						end
					}
				end
			end
		end
		
		-- (Player) Block 90: Dashing forwards into enemies with your shield raised deals damage and knocks them back, every 10s
		if common.skills and aRef == p and pMob.block.base >= 90 and p.data.neph[94] == 1 then
			if pMob.isMovingForward and p.data.neph[98] >= 2 and p.data.neph[25] == 0 then
				p.data.neph[25]			= 1
				common.scriptDmg.aRef	= p
				common.scriptDmg.aMob	= pMob
				common.scriptDmg.tMob	= tMob
				common.scriptDmg.dir	= 3
				common.scriptDmg.swing	= 1
				common.scriptDmg.weap	= -2
				tRef.mobile:applyDamage{damage = pMob.readiedShield.object.weight, applyArmor = true}
				if tMob.hasFreeAction then
					V.KIK()
				end
				timer.start{
					duration = 10,
					callback = function()
						p.data.neph[25] = 0
						if common.config.comboMsg then
							tes3.messageBox("You may shield-charge again!")
						end
					end
				}
			end
		end
	end
end
event.register("collision", onCollision)

-------------------------
--[[ 4NM KICK MASTER ]]--
-------------------------
-- used for knock back mechanics
-- adaptations: not triggered on keyDown, no damage applied or fatigue lost, added knockdown

local KSR = {}
local T = timer
local Matr = tes3matrix33.new()

local function GetArmor(m)
	if m.actorType == 0 then
		return m.shield
	else
		local st = tes3.getEquippedItem{
			actor = m.reference,
			objectType = tes3.objectType.armor,
			slot = math.random(4) == 1 and 1 or math.random(0,8)
		}
		return m.shield + (st and st.object:calculateArmorRating(m) or m:getSkillValue(17)*0.3)
	end
end


local function Nokout(ag)
	return ag == 34 or ag == 35
end


V.BLAST = function(e)

	local r = e.reference
	
	if KSR[r] then
		e.mobile.impulseVelocity = KSR[r].v*(1/30/tes3.worldController.deltaTime) * math.clamp(KSR[r].f/30,0.2,1)
		KSR[r].f = KSR[r].f - 1
		e.speed = 0
		if KSR[r].f <= 0 then
			KSR[r] = nil
			if table.size(KSR) == 0 then
				local mob = r.mobile
				if r.data.neph[96] == 0 and not mob.isDead and math.min(0.01*mob.sanctuary, 1) <= math.random() then
					mob.actionData.animationAttackState = 14
					r.data.neph[96] = 2
					timer.start{
						duration = common.config.knockDownLimit,
						callback = function()
							r.data.neph[96] = 0
						end
					}
				end
				event.unregister("calcMoveSpeed", V.BLAST)		
			end
		end
	end
end


V.KIK = function()

	if not T.timeLeft and pMob.hasFreeAction then
	
		local s = pMob:getSkillValue(26)
		local maxd = 50 + math.min(pMob.agility.current/2, 50) + s/2
		local vdir = tes3.getPlayerEyeVector()
		local hit = tes3.rayTest{
			position = tes3.getPlayerEyePosition(),
			direction = vdir,
			maxDistance = 150,
			ignore={p}
		}
		local dist, r, m
		
		if hit then
			dist = hit.distance
			r = hit.reference
			m = r and r.mobile else dist = 10000
		end
		if dist > maxd then
		
			local ori = p.orientation
			
			Matr:fromEulerXYZ(ori.x, ori.y, ori.z)
			hit = tes3.rayTest{
				position = p.position + tes3vector3.new(0,0,15),
				direction = Matr:transpose().y,
				maxDistance = 150,
				ignore={p}
			}
			if hit then
				dist = hit.distance
				r = hit.reference
				m = r and r.mobile or m else dist = 10000
			end
			if dist > maxd then
				hit = pMob.isMovingLeft and 1 or (pMob.isMovingRight and -1)
				if hit then
					Matr:fromEulerXYZ(ori.x, ori.y, ori.z)
					vdir = Matr:transpose().x * hit
					hit = tes3.rayTest{
						position = p.position + tes3vector3.new(0,0,10),
						direction = vdir,
						ignore={p}
					}
					if hit then
						dist = hit.distance
						r = hit.reference
						m = r and r.mobile or m
					end
				end
			end
		end
		if m and m.isDead == false and dist < maxd then
		
			local arm = GetArmor(m)
			local ko = Nokout(m.actionData.currentAnimationGroup)
			local cd = math.max(1.5 - pMob.speed.current/100 + pMob.encumbrance.normalized, 0.5)
			local Koef = 100 + pMob.attackBonus/5 + pMob.strength.current + s/2 - 50 * (1 - math.min(pMob.fatigue.normalized,1))
			
			vdir.z = math.min(vdir.z + 0.5, 1)
			T = timer.start{
				duration = cd,
				callback = function()
			end}
			if not m.inCombat then
				tes3.triggerCrime{type = 1, victim = m}
				m:startCombat(pMob)
			end
			
			local mass = math.max(m.height, 50)
			mass = mass * mass * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + arm/2)/5000
			
			local imp = math.min((Koef - m.endurance.current) * 1000/mass, 10000)
			if imp > 100 then
				if table.size(KSR) == 0 then
					event.register("calcMoveSpeed", V.BLAST)
				end
				tes3.applyMagicSource{
					reference = r,
					name = "4nm",
					effects = {{id = 10, min = 1, max = 1, duration = 0.1}}
				}
				KSR[r] = {v = vdir * imp, f = 30}
			end
		end
	end
end


local function loaded(e)

	p		= tes3.player
	pMob	= tes3.mobilePlayer
	d		= tes3.worldController.deltaTime

	if table.size(KSR) ~= 0 then
		event.unregister("calcMoveSpeed", V.BLAST)
		KSR = {}
	end
end
event.register("loaded", loaded)