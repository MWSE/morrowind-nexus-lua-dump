local common = require("Neph.Power Fantasy.common")
local p, pMob
local t1 = 1
local t2 = 0.05
local seconds = 0

local function simStuff(e)

	local d = e.delta
	local temp
	
	t1 = t1 + d
	if t1 >= 1 then t1 = 0
	
		if common.skills then
		
			--tes3.messageBox("detection: %i", p.data.neph[91])
			--tes3.messageBox("ench item recharge: %f", tes3.findGMST("fMagicItemRechargePerSecond").value)
			
			-- Armorer 30: Condition of items recharges over time
			if pMob.armorer.base >= 30 and not pMob.inCombat then
				local stack = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.weapon}
				if stack and stack.variables and stack.variables.condition < stack.object.maxCondition then
					stack.variables.condition = stack.variables.condition + 0.01*pMob.armorer.base
				end
				for i = 0, 10 do
					stack = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i}
					if stack and stack.variables and stack.variables.condition < stack.object.maxCondition then
						stack.variables.condition = stack.variables.condition + 0.01*pMob.armorer.base
					end
				end
			end
				
			-- Acrobatics nerf
			tes3.findGMST("fJumpAcroMultiplier").value = 4 - 0.01*pMob.acrobatics.base
			
			-- Speechcraft
			if pMob.speechcraft.base >= 30 and tes3.findGMST("fDispBargainFailMod").value ~= 0 then
				tes3.findGMST("fDispBargainFailMod").value = 0
			end
			if pMob.speechcraft.base >= 60 and tes3.findGMST("fDispDiseaseMod").value ~= 0 then
				tes3.findGMST("fDispDiseaseMod").value = 0
				tes3.findGMST("fDispWeaponDrawn").value	= 10
			end
			
			-- Mysticism Scaling: Restore up to 10 of all while swimming and affected by Waterbreathing or Swift Swim
			if pMob.mysticism.base >= 30 and (pMob.swiftSwim > 0 or pMob.waterBreathing > 0) and pMob.isSwimming then
				local myst = 0.1*pMob.mysticism.base
				tes3.applyMagicSource{
					reference = p,
					name = "Water Regeneration",
					effects = {
						{id = 75, min = myst, max = myst},
						{id = 76, min = myst, max = myst},
						{id = 77, min = myst, max = myst}
					}
				}
			end
			
			-- Enchant 30: Recharge over time
			if pMob:getSkillValue(9) >= 30 then
				tes3.findGMST("fMagicItemRechargePerSecond").value = 0.005*pMob.enchant.base
			end
		end
	
		-- Khajiit Trip fatigue regen
		if common.rbs and p.data.neph[58] == 1 then
			tes3.applyMagicSource{
				reference = p,
				name = "Skooma Fatigue Restoration",
				effects = {{id = 77, duration = 1, min = 3, max = 3}}
			}
		end
	end
	
	t2 = t2 + d
	if t2 >= 0.05 then t2 = 0 -- lightens it up a bit
	
		-- Player-only stuff
		--------------------
		
		-- Sneak 90: 8s Invisibility when sneaking, every 20s
		if common.skills and pMob.sneak.base >= 90 then
			if pMob.invisibility == 0 and pMob.isSneaking and p.data.neph[26] == 0 then
				tes3.applyMagicSource{
					reference = p,
					source = "_neph_perk_19_invis"
				}
				p.data.neph[26] = 1
				timer.start{
					duration = 30,
					callback = function()
						p.data.neph[26] = 0
						if common.config.comboMsg then
							tes3.messageBox("You may become invisible when sneaking again.")
						end
					end
				}
			end
		end
		
		-- Shadow Birthsign: 20% Chameleon while sneaking
		if common.rbs and p.data.neph[99] == "Shadow" then
			if pMob.isSneaking and not pMob:isAffectedByObject(tes3.getObject("_neph_bs_sha_pssvVeil")) then
				mwscript.addSpell{reference = p, spell = "_neph_bs_sha_pssvVeil"}
			end
			if not pMob.isSneaking and pMob:isAffectedByObject(tes3.getObject("_neph_bs_sha_pssvVeil")) then
				mwscript.removeSpell{reference = p, spell = "_neph_bs_sha_pssvVeil"}
			end
		end
		
		-- Jump attack setup and AoE effects of Mysticism 90 and Steed Trample Power
		if (pMob.isJumping or pMob.isFalling) and p.data.neph[93] == 0 then
			p.data.neph[93] = 1
		end
		if p.data.neph[93] == 1 and not (pMob.isJumping or pMob.isFalling) then
			p.data.neph[93] = 2
			if (common.skills and pMob.mysticism.base >= 90 and (tes3.isAffectedBy{reference = p, effect = 9}))
			or (common.rbs and pMob:isAffectedByObject(tes3.getObject("_neph_bs_ste_pwTrample"))) then
				for actor in tes3.iterate(pMob.hostileActors) do
					local actorRef = actor.reference
					if actor ~= pMob and actor.position:distance(pMob.position) < 221 then
						common.scriptDmg.aRef		= p
						common.scriptDmg.aMob		= pMob
						common.scriptDmg.tMob		= actor
						common.scriptDmg.dir		= 3
						common.scriptDmg.swing		= 1
						common.scriptDmg.weap		= -2
						actor:applyDamage{damage = 0.1*pMob.encumbrance.current + 0.1*pMob.health.base, applyArmor = true}
						if actorRef.data.neph[96] == 0 and math.min(0.01*actor.sanctuary, 1) <= math.random() and actor.health.current > 0 and actor.hasFreeAction then
							tes3.playAnimation{
								reference = actorRef,
								group = 0x22,
								loopCount = 0,
								startFlag = 1
							}
							actorRef.data.neph[96] = 2
							timer.start{
								duration = 3,
								callback = function()
									tes3.playAnimation{
										reference = actorRef,
										group = 0x0,
										startFlag = 0
									}
								end
							}
							timer.start{ -- can't effectively be knocked down for 3 secs
								duration = common.config.knockDownLimit,
								callback = function()
									actorRef.data.neph[96] = 0
								end
							}
						end
					end
				end
			end
			timer.start{duration = 1, callback = function()
				p.data.neph[93] = 0
			end}
		end
		
		-- Stuff including other actors (incl. creatures)
		-------------------------------
		for _, cell in pairs(tes3.getActiveCells()) do
			for ref in tes3.iterate(cell.actors) do
				if ref.mobile and not ref.disabled and ref.data.neph then
					local mob = ref.mobile
					if not mob.isDead then
					
						-- Sneak 90: Stop combat with surrounding actors
						if common.skills and pMob.illusion.base >= 90 and pMob.invisibility > 0 and pMob.inCombat then
							temp = 0
							for id in pairs(common.illu90Blacklist) do
								if ref.object.id == id then
									temp = 1
									break
								end
							end
							if temp == 0 then
								mwscript.stopCombat{reference = ref, target = p}
							end
						end
						
						-- Dunmer: Toggle ability
						if ref.object.race and ref.object.race.id:lower() == "dark elf" then
							if mob.magicka.normalized >= 0.5 and not mob:isAffectedByObject(tes3.getObject("_neph_race_de_togConvMagAb")) then
								mwscript.addSpell{reference = ref, spell = "_neph_race_de_togConvMagAb"}
							end
							if mob.magicka.normalized < 0.5 and mob:isAffectedByObject(tes3.getObject("_neph_race_de_togConvMagAb")) then
								mwscript.removeSpell{reference = ref, spell = "_neph_race_de_togConvMagAb"}
							end
						end
						
						-- player inclusion
						if math.random() > 0.8 then
							ref = p
							mob = pMob
						end
						
						-- debug
						if not ref.data.neph then
							mwse.log("[Power Fantasy] uninitialized object: %s", ref.object.id)
							return
						end
												
						-- knock out limit (from fatigue loss)
						if common.config.knockOutLimit > 0 and mob.fatigue.current <= 0 and ref.data.neph[95] == 0 then
							ref.data.neph[95] = 1
							timer.start{
								duration = common.config.knockDownLimit,
								callback = function()
									ref.data.neph[95] = 0
								end
							}
						end
						
						-- Imperial allies buff
						if #mob.friendlyActors >= 2 then
							temp = 0
							for friendly in tes3.iterate(mob.friendlyActors) do
								if friendly.object and friendly.object.race and friendly.object.race.id:lower() == "imperial" then
									if not (string.find(friendly.object.name:lower(), "guard") or friendly == mob) then
										temp = 1
									end
								end
							end
							if temp == 1 then
								ref.data.neph[53] = 1
							else
								ref.data.neph[53] = 0
							end										
						else
							ref.data.neph[53] = 0
						end
												
						-- NPC-only stuff
						-----------------
						if ref.object.objectType == tes3.objectType.npc then
							
							if common.rbs then
							
								-- Shadow: Dark Shroud Aura
								if mob:isAffectedByObject(tes3.getObject("_neph_bs_sha_pwShroud")) and ref.data.neph[54] == 0 then
									local shroud = tes3.getObject("_neph_bs_sha_pwShroudAura").effects
									for i = 1, 2 do
										shroud[i].max = math.min(45 + ref.object.level, 95)
										shroud[i].min = math.min(45 + ref.object.level, 95)
									end
									ref.data.neph[54] = 1
									for _, c in pairs(tes3.getActiveCells()) do
										for actor in tes3.iterate(c.actors) do
											if actor.mobile and not actor.disabled and actor ~= ref and actor.position:distance(mob.position) < 2210 then
												tes3.applyMagicSource{
													reference = actor,
													source = "_neph_bs_sha_pwShroudAura"
												}
											end
										end
									end
									timer.start{
										duration = 3,
										callback = function()
											ref.data.neph[54] = 0
										end
									}
								end
								
								-- Breton: effects on low health or magicka
								if ref.object.race.id:lower() == "breton" then
									if mob.health.normalized <= 0.25 and not mob:isAffectedByObject(tes3.getObject("_neph_race_br_pssvEmShield")) then
										local shield = tes3.getObject("_neph_race_br_pssvEmShield").effects
										shield[1].max = 25 + ref.object.level
										shield[1].min = 25 + ref.object.level
										mwscript.addSpell{reference = ref, spell = "_neph_race_br_pssvEmShield"}
									end
									if mob.health.normalized > 0.25 and mob:isAffectedByObject(tes3.getObject("_neph_race_br_pssvEmShield")) then
										mwscript.removeSpell{reference = ref, spell = "_neph_race_br_pssvEmShield"}
									end
									if mob.magicka.normalized <= 0.25 and not mob:isAffectedByObject(tes3.getObject("_neph_race_br_pssvEmAbsorb")) then
										mwscript.addSpell{reference = ref, spell = "_neph_race_br_pssvEmAbsorb"}
									end
									if mob.magicka.normalized > 0.25 and mob:isAffectedByObject(tes3.getObject("_neph_race_br_pssvEmAbsorb")) then
										mwscript.removeSpell{reference = ref, spell = "_neph_race_br_pssvEmAbsorb"}
									end
								end
							end
							
							if common.skills then
														
								-- Light Armor 90: Increment damage bonus marker
								if mob.lightArmor.base >= 90 and ref.data.neph[1] == 0 and ref.data.neph[19] < 10 then
									ref.data.neph[19] = ref.data.neph[19] + 0.05
								end

								-- Unarmored 60: +0.3x Magicka while wearing no cuirass
								if mob.unarmored.base >= 60 then
									if ref.data.neph[1] == -1 and not ref.mobile:isAffectedByObject(tes3.getObject("_neph_perk_17_MagickaBonus")) then
										mwscript.addSpell{reference = ref, spell = "_neph_perk_17_MagickaBonus"}
									end
									if ref.data.neph[1] ~= -1 and ref.mobile:isAffectedByObject(tes3.getObject("_neph_perk_17_MagickaBonus")) then
										mwscript.removeSpell{reference = ref, spell = "_neph_perk_17_MagickaBonus"}
									end
								end

								-- Restoration 90: Heal completely in 5s when falling below 15% health, every 10 minutes
								if mob.restoration.base >= 90 and not pMob:isAffectedByObject(tes3.getObject("_neph_perk_15_90marker")) and mob.health.normalized <= 0.15 then
									tes3.applyMagicSource{
										reference = ref,
										name = "Emergency Healing",
										effects = {
											{id = 75, duration = 5, min = 0.2*mob.health.base, max = 0.2*mob.health.base},
											{id = 76, duration = 5, min = 0.2*mob.magicka.base, max = 0.2*mob.magicka.base},
											{id = 77, duration = 5, min = 0.2*mob.fatigue.base, max = 0.2*mob.fatigue.base}
										}
									}
									tes3.applyMagicSource{reference = ref, source = "_neph_perk_15_90marker"}			
								end
							end
							
							if (ref.data.neph[56] == 1 or (common.skills and mob.unarmored.base >= 90 and ref.data.neph[1] == -1)) and ref.data.neph[55] == 0 then
								
								ref.data.neph[55] = 1
								
								if common.rbs then
								
									-- Argonian: Restore while swimming
									if ref.object.race.id:lower() == "argonian" then
										tes3.applyMagicSource{
											reference = ref,
											name = "Argonian Health Restoration",
											effects = {{id = 75, duration = 1, min = 0.01*mob.health.base, max = 0.01*mob.health.base}}
										}
										if mob.isSwimming then
											tes3.applyMagicSource{
												reference = ref,
												name = "Reptiloid Restoration",
												effects = {
													{id = 75, duration = 1, min = 0.03*mob.health.base, max = 0.03*mob.health.base},
													{id = 76, duration = 1, min = 0.03*mob.magicka.base, max = 0.03*mob.magicka.base},
													{id = 77, duration = 1, min = 0.03*mob.fatigue.base, max = 0.03*mob.fatigue.base}}
												}
										end									
									-- Redguard: Restore 1% of maximum fatigue
									elseif ref.object.race.id:lower() == "redguard" then
										tes3.applyMagicSource{
											reference = ref,
											name = "Redguard Fatigue Restoration",
											effects = {{id = 77, duration = 1, min = math.max(0.005*mob.fatigue.base, 1), max = math.max(0.005*mob.fatigue.base, 1)}}
										}
									-- Nord: Restore 2% of maximum fatigue and up to 1% magicka with missing health
									elseif ref.object.race.id:lower() == "nord" and mob.health.normalized < 0.5 then
										tes3.applyMagicSource{
											reference = ref,
											name = "Nord Restoration",
											effects = {
												{
													id = 76,
													duration = 1,
													min = math.max(0.01*mob.magicka.base, 1),
													max = math.max(0.01*mob.magicka.base, 1)
												},
												{
													id = 77,
													duration = 1,
													min = math.max(0.01*mob.fatigue.base, 1),
													max = math.max(0.01*mob.fatigue.base, 1)
												}
											}
										}
									end
									-- Lord: Restore 1% of maximum health
									if ref.data.neph[99] == "Lord" then
										tes3.applyMagicSource{
											reference = ref,
											name = "Lord Health Restoration",
											effects = {{id = 75, duration = 1, min = math.max(0.01*mob.health.base, 1), max = math.max(0.01*mob.health.base, 1)}}
										}
									-- Warrior fatigue Restoration
									elseif ref.data.neph[99] == "Warrior" then
										tes3.applyMagicSource{
											reference = ref,
											name = "Warrior Fatigue Restoration",
											effects = {{id = 77, duration = 1, min = math.max(0.005*mob.fatigue.base, 1), max = math.max(0.005*mob.fatigue.base, 1)}}
										}
									end
								end

								-- Unarmored 90
								if not tes3.isAffectedBy{reference = ref, effect = 136} and mob.unarmored.base >= 90 and ref.data.neph[1] == -1 then
									local unarmFac = 0.02*mob.magicka.base*(1 - mob.magicka.normalized)
									tes3.applyMagicSource{
										reference = ref,
										name = "Unarmored Magicka Restoration",
										effects = {{id = 76, duration = 1, min = math.max(unarmFac, 1), max = math.max(unarmFac, 1)}}
									}
								end
								timer.start{
									duration = 1,
									callback = function()
										ref.data.neph[55] = 0
									end
								}
							end
							
						-- Creature-only stuff
						----------------------
						else
							if common.config.creaPerks then
							
								-- Ascended Sleeper Aura
								if ref.data.neph[84] then
									if mob.hostileActors and ref.data.neph[71] == 0 then
										ref.data.neph[71] = 1
										for hostile in tes3.iterate(mob.hostileActors) do
											if hostile.position:distance(mob.position) < 442 and not hostile:isAffectedByObject(tes3.getObject("_neph_crea_aura_ascSleeper")) then
												tes3.applyMagicSource{
													reference = hostile.reference,
													source = "_neph_crea_aura_ascSleeper"
												}
											end
										end
										timer.start{
											duration = 3,
											callback = function()
												ref.data.neph[71] = 0
											end
										}
									end
								end
							
								-- Undead self healers
								if ref.data.neph[70] == 1 then
									if mob.health.normalized <= 0.2 then
										ref.data.neph[70] = 2 -- should only happen once...
										tes3.applyMagicSource{
											reference = ref,
											name = "Undead Healing",
											effects = {{id = 75, duration = 5, min = 0.2*mob.health.base, max = 0.2*mob.health.base}}
										}
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
event.register("simulate", simStuff)


-- Simple dash built from scratch.
local function dashKey(e)	
	if e.keyCode == common.config.dashKey.keyCode and not tes3ui.menuMode() and pMob.hasFreeAction and p.data.neph[98] == 0 then
	
		local fatCost = 10 + (10*pMob.encumbrance.normalized*(1 - 0.01*pMob.acrobatics.base))
		
		if pMob.fatigue.current >= fatCost then
			tes3.modStatistic{
				current = -fatCost,
				name = "fatigue",
				reference = pMob
			}
		else
			return
		end
		
		pMob:exerciseSkill(20, 0.2)
		
		local athl60 = 0
		if common.skills and pMob.athletics.base >= 60 then
			athl60 = 0.5
		end
		
		-- for relatively normal dash behavior during khajiit skooma trip
		local skoomaCat = 1
		if p.data.neph[58] == 1 then
			skoomaCat = math.max(0.8 - 0.01*p.object.level, 0.2)
		end
		
		p.data.neph[98] = 3
		timer.start{ -- actual dash
			duration = 0.3*skoomaCat,
			callback = function()
				p.data.neph[98] = 2
			end
		}
		timer.start{ -- time window for dash attack
			duration = 1*skoomaCat,
			callback = function()
				p.data.neph[98] = 1
			end
		}
		timer.start{ -- cooldown
			duration = math.max((2.5 - athl60 - 0.005*pMob.acrobatics.base - 0.005*pMob.agility.base) + 0.1*p.data.neph[97], 1) * skoomaCat,
			callback = function()
				p.data.neph[98] = 0
			end
		}
	end
end
event.register("keyDown", dashKey)


local function moveSpeed(e)

	local mob = e.mobile
	local ref = e.reference
	
	-- debug
	if not ref.data.neph then
		mwse.log("[Power Fantasy] uninitialized object: %s", ref.object.id)
		return
	end
	
	-- General movespeed calcs
	e.speed = e.speed * (0.8 + 0.2*mob.fatigue.normalized) * math.max(1.25 - 0.35*(0.005*mob:getSkillValue(8) + 0.005*mob.speed.current), 0.9)
	if mob.isMovingBack then
		e.speed = e.speed * 0.7
	end
	
	-- Khajiit Skooma Trip 
	if common.rbs and mob == pMob and p.data.neph[58] == 1 then
		e.speed = e.speed * 1/math.max(0.8 - 0.01*p.object.level, 0.2)
	end
	
	-- NPC dashing
	if common.config.NPCdash and mob ~= pMob and mob.inCombat and ref.data.neph[98] == 0 then
	
		local fatCost = 10 + (10*mob.encumbrance.normalized*(1 - 0.01*mob:getSkillValue(20)))
		local athl60 = 0
		
		-- random combat dash
		if mob.isMovingBack or mob.isMovingRight or mob.isMovingLeft then
			if 0.00025*(mob.speed.current + mob.agility.current) >= math.random() then
				if mob.fatigue.current >= fatCost then
					tes3.modStatistic{
						current = -fatCost,
						name = "fatigue",
						reference = mob
					}
					ref.data.neph[98] = 3
					if common.skills and mob:getSkillValue(8) >= 60 then
						athl60 = 0.5
					end
					timer.start{
						duration = 0.3,
						callback = function()
							ref.data.neph[98] = 2
						end
					}
					timer.start{
						duration = 1,
						callback = function()
							ref.data.neph[98] = 1
						end
					}
					timer.start{
						duration = (2.5 - athl60 - 0.005*mob:getSkillValue(20) - 0.005*mob.agility.base) + 0.1*ref.data.neph[97],
						callback = function()
							ref.data.neph[98] = 0
						end
					}
				end
			end
		end
		
		-- aggressive forward dash to close distance to the player
		if mob.isMovingForward and mob.isRunning and ref.data.neph[11] < 9 then
			if 0.00005*(mob.strength.current + mob.agility.current) >= math.random() then
				local dist = (mob.speed.current + mob:getSkillValue(8) + mob:getSkillValue(20))*1.5
				if mob.position:distance(pMob.position) <= dist + 100 and mob.position:distance(pMob.position) >= dist then
					if mob.fatigue.current >= fatCost then
						tes3.modStatistic{
							current = -fatCost,
							name = "fatigue",
							reference = mob
						}
						ref.data.neph[98] = 3
						if common.skills and mob:getSkillValue(8) >= 60 then
							athl60 = 0.5
						end
						timer.start{
							duration = 0.3,
							callback = function()
								ref.data.neph[98] = 2
							end
						}
						timer.start{
							duration = 1,
							callback = function()
								ref.data.neph[98] = 1
							end
						}
						timer.start{
							duration = (2.5 - athl60 - 0.005*mob:getSkillValue(20) - 0.005*mob.agility.base) + 0.1*ref.data.neph[97],
							callback = function()
								ref.data.neph[98] = 0
							end
						}
					end
				end
			end
		end
	end
	
	-- actual dashing
	if mob == pMob and (pMob.isJumping or pMob.isFalling) and pMob.acrobatics.base < 90 then return end
	
	if ref.data.neph[98] == 3 then
		local acro60 = 0
		if common.skills and mob:getSkillValue(20) >= 60 then
			acro60 = 0.5
		end
		e.speed = e.speed * (2 + acro60 + 0.005*pMob:getSkillValue(20) - 0.025*ref.data.neph[97])
		for sound in pairs(common.stepSound) do
			if tes3.getSoundPlaying{sound = sound, reference = ref} then
				tes3.removeSound{sound = sound, reference = ref}
			end
		end
	end
end
event.register("calcMoveSpeed", moveSpeed)


-- Alchemy Scaling: Chance to brew two potions at once
local function extraPotions(e)
	if pMob.alchemy.base >= 30 then
		local pCount = 1
		if 0.01*pMob.alchemy.base >= math.random() then
			pCount = 2
		end
		if pCount == 2 then
			tes3.addItem{
				reference = p,
				item = e.object,
				playSound = false
			}
		end
	end
end
if common.skills then
	event.register("potionBrewed", extraPotions)
end


local function detection(e)
	for _, cell in pairs(tes3.getActiveCells()) do
		for actor in tes3.iterate(cell.actors) do
			if actor.mobile and not actor.disabled then
				if not actor.mobile.isDead and e.detector == actor.mobile and e.target == pMob then
					if not e.isDetected then
						p.data.neph[91] = 1
					else
						p.data.neph[91] = 0
					end
				end
			end
		end
	end
end
event.register("detectSneak", detection)


-- Lady: 10% more skill exp
local function ladyWisdom(e)
	if p.data.neph[99] == "Lady" then
		e.progress = e.progress * 1.1
	end
end
if common.rbs then
	event.register("exerciseSkill", ladyWisdom)
end


-- Imperial and Lady: Discounts for training, traveling and repair services
local function discounts(e)

	local discount = 1
	
	if p.object.race.id:lower() == "imperial" then
		discount = discount - 0.25
	end
	if p.data.neph[99] == "Lady" then
		discount = discount - 0.25
	end
	e.price = e.price * discount
end
if common.rbs then
	event.register("calcTrainingPrice", discounts)
	event.register("calcTravelPrice", discounts)
	event.register("calcRepairPrice", discounts)
end


local function activate(e)

	local ref = e.target
	local obj = ref.object
	
	-- Security 30: Chests yield additional gold (scaling amount)
	if common.skills and string.find(obj.name:lower(), "chest") then
		if pMob.security.base >= 30 then
			local goldStack = ref.object.inventory:findItemStack(tes3.getObject("Gold_001"))
			if not goldStack or goldStack.count < math.ceil(5 + p.object.level/2) then
				tes3.addItem{
					reference = ref,
					item = "Gold_001",
					count = math.ceil(5 + p.object.level/2)
				}
			end
		end
	end
	
	if obj.objectType ~= tes3.objectType.npc and obj.objectType ~= tes3.objectType.creature then return end
		
	-- birthsign disposition
	if common.rbs and not ref.mobile:isAffectedByObject(tes3.getObject("_neph_bs_thi_pssvDisp")) then
		if p.data.neph[99] == "Thief" then
			mwscript.addSpell{reference = ref, spell = "_neph_bs_thi_pssvDisp"}
			obj.baseDisposition = obj.baseDisposition - 10
		elseif p.data.neph[99] == "Lover" then
			mwscript.addSpell{reference = ref, spell = "_neph_bs_thi_pssvDisp"}
			obj.baseDisposition = obj.baseDisposition + 10
		end
	end
	
	if common.skills then
	
		local id = obj.id
		local c
		
		if obj.objectType == tes3.objectType.npc then
			c = obj.class.id
		else
			c = "Creature"
		end
		
		-- Mercantile Stuff
		if string.find(c, "Service") or id == "mudcrab_unique" or id == "scamp_creeper" or c == "Smith" or c == "Publican" or c == "Pawnbroker"
		or c == "Trader" or c == "Clothier" or c == "Bookseller" or id == "ranosa gilvayn" or id == "fenas madach" or id == "baren alen"
		or id == "tarhiel" or id == "hetman abelmawia" or id == "areas" or id == "mororurg" or id == "hecerinde" or id == "germia" then
		
			if pMob.mercantile.base >= 30 and not ref.mobile:isAffectedByObject(tes3.getObject("_neph_perk_24_barterMarker1")) then
				mwscript.addSpell{reference = ref, spell = "_neph_perk_24_barterMarker1"}
				ref.mobile.barterGold = ref.mobile.barterGold + 500
			end
			if pMob.mercantile.base >= 60 then
				local npc = obj.aiConfig
				npc.bartersAlchemy = true
				npc.bartersApparatus = true
				npc.bartersArmor = true
				npc.bartersBooks = true
				npc.bartersClothing = true
				npc.bartersEnchantedItems = true
				npc.bartersIngredients = true
				npc.bartersLights = true
				npc.bartersLockpicks = true
				npc.bartersMiscItems = true
				npc.bartersProbes = true
				npc.bartersRepairTools = true
				npc.bartersWeapons = true
			end
			if pMob.mercantile.base >= 90 and not ref.mobile:isAffectedByObject(tes3.getObject("_neph_perk_24_barterMarker2")) then
				mwscript.addSpell{reference = ref, spell = "_neph_perk_24_barterMarker2"}
				ref.mobile.barterGold = ref.mobile.barterGold * 2
			end
		end
	end
end
event.register("activate", activate)


local function utilityItems(e)
	
	-- Armorer
	if e.skill == 1 then
		if e.level == 60 then
			for id, props in pairs(common.armo_items) do
				tes3.getObject(id).maxCondition = props[1]
				tes3.getObject(id).modified = true
			end
		end
		if e.level == 90 then
			local orcFactor
			if p.object.race.id:lower() == "orc" then orcFactor = 2 else orcFactor = 1 end
			for id, props in pairs(common.armo_items) do
				tes3.getObject(id).quality = props[2] * orcFactor
				tes3.getObject(id).modified = true
			end
		end
	end
	
	-- Alchemy
	if e.skill == 16 then
		if e.level == 60 then
			for id, props in pairs(common.retorts) do
				tes3.getObject(id).quality = props[2]
				tes3.getObject(id).modified = true
			end
		end
		if e.level == 90 then
			for id, props in pairs(common.alembics) do
				tes3.getObject(id).quality = props[2]
				tes3.getObject(id).modified = true
			end
		end
	end
	
	-- Security
	if e.skill == 18 then
		if e.level == 60 then
			for id, props in pairs(common.secu_items) do
				tes3.getObject(id).maxCondition = props[1]
				tes3.getObject(id).modified = true
			end
		end
		if e.level == 90 then
			for id, props in pairs(common.secu_items) do
				tes3.getObject(id).quality = props[2]
				tes3.getObject(id).modified = true
			end
		end
	end
	
	-- H2H 90
	if e.skill == 26 then
		if e.level == 90 then
			mwscript.addSpell{reference = p, spell = "_neph_perk_26_shockToggle"}
			mwscript.addSpell{reference = p, spell = "_neph_perk_26_fireToggle"}
			mwscript.addSpell{reference = p, spell = "_neph_perk_26_frostToggle"}
		end
	end
end
if common.skills then
	event.register("skillRaised", utilityItems)
end


local function ingestion(e)
	if e.item.objectType ~= tes3.objectType.alchemy or e.reference.object.objectType ~= tes3.objectType.npc then return end
	
	local ref = e.reference
	local alch = e.item
	
	-- Bosmer Stomach
	if common.rbs and ref.object.race.id:lower() == "wood elf" then
		for i = 1, #alch.effects do
			tes3.applyMagicSource{
				reference = ref,
				name = "Bosmer Stomach",
				effects = {{
					id = alch.effects[i].id,
					duration = alch.effects[i].duration,
					attribute = alch.effects[i].attribute or nil,
					skill = alch.effects[1].skill or nil,
					min = math.max(0.35*alch.effects[i].min, 1) or nil,
					max = math.max(0.35*alch.effects[i].max, 1) or nil
				}}
			}
		end
	end
end
event.register("equip",	ingestion)


local function death(e)
	
	local ref = e.reference
	
	-- Automatons explode briefly after death
	if string.find(ref.object.id, "centurion") or string.find(ref.object.id:lower(), "imperfect") then
		timer.start{
			duration = 1,
			callback = function()
				if ref.position:distance(p.position) <= 221 then
					local onHitMarker = tes3.createReference{
						object = "_neph_acti_castMarker",
						position = ref.position,
						cell = ref.cell
					}
					local onhit = tes3.getObject("_neph_crea_onHit_centurionExp").effects[1]
					onhit.max = math.ceil(10*ref.object.attacks[1].max)
					onhit.min = math.ceil(10*ref.object.attacks[1].max)
					tes3.cast{
						reference = onHitMarker,
						target = p,
						spell = "_neph_crea_onHit_centurionExp",
						instant = true
					}
					timer.start{
						duration = 0.1,
						callback = function()
							onHitMarker:delete()
						end
					}
					--tes3.messageBox("Centurion exploding.")
				end
			end
		}
	end
end
if common.config.creaPerks then
	event.register("death", death)
end


local function playerVars()

	p = tes3.player
	pMob = tes3.mobilePlayer
	
	if common.skills then
	
		for id, props in pairs(common.retorts) do
			if pMob.alchemy.base >= 60 then
				tes3.getObject(id).quality = props[2]
				tes3.getObject(id).modified = true
			else
				tes3.getObject(id).quality = props[1]
				tes3.getObject(id).modified = true
			end
		end
		
		for id, props in pairs(common.alembics) do
			if pMob.alchemy.base >= 90 then
				tes3.getObject(id).quality = props[2]
				tes3.getObject(id).modified = true
			else
				tes3.getObject(id).quality = props[1]
				tes3.getObject(id).modified = true
			end
		end
		
		for id, props in pairs(common.armo_items) do
			if pMob.armorer.base >= 60 then
				tes3.getObject(id).maxCondition = props[1]
			else
				tes3.getObject(id).maxCondition = 0.5*props[1]
			end
			tes3.getObject(id).modified = true
		end
	end
end
event.register("loaded", playerVars)