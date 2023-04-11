--[[
	controls 



]]

common = require("KBev.ProgressionMod.common")
mcm = require("KBev.ProgressionMod.mcm")
perkFramework = require("KBLib.PerkSystem.perkSystem")

local perks = {}

local boodMagicCast = false

local LArmMaster_spell
local MArmMaster_spell
local HArmMaster_spell

local unarmoredMasterActive
local lightArmorMasterActive
local mediumArmorMasterActive
local heavyArmorMasterActive
local blockMasterActive

local knifeJugglerTimer
local knifeJugglerCount = 0

--[[------=Functions=-------]]

--[[
	calcArmorMasterEffects():
	Calculates the state and magnitude of each of the armor mastery perks
]]
local function calcArmorMasterEffects()
	local armorCount = 0
	local lightArmorCount = 0
	local mediumArmorCount = 0
	local heavyArmorCount = 0
	unarmoredMasterActive = false
	lightArmorMasterActive = false
	mediumArmorMasterActive = false
	heavyArmorMasterActive = false
	blockMasterActive = false
	for _, stack in pairs(tes3.player.object.equipment) do
    -- stack is type tes3equipmentStack, as tes3.player.object.equipment is a list of tes3equipmentStack.
		if stack.object.objectType == tes3.objectType.armor then
		armorCount = armorCount + 1
			if stack.object.weightClass == tes3.armorWeightClass.light then
				lightArmorCount = lightArmorCount + 1
			elseif stack.object.weightClass == tes3.armorWeightClass.medium then
				mediumArmorCount = mediumArmorCount + 1
			elseif stack.object.weightClass == tes3.armorWeightClass.heavy then
				heavyArmorCount = heavyArmorCount + 1
			end
		end
	end
	if armorCount == 0 and perks.unarmoredMaster.activated then
		unarmoredMasterActive = true
	else
		if lightArmorCount > 0 and perks.lightArmorMaster.activated then
			lightArmorMasterActive = true
		end
		if mediumArmorCount > 0 and perks.mediumArmorMaster.activated then
			mediumArmorMasterActive = true
		end
		if heavyArmorCount > 0 and perks.heavyArmorMaster.activated then
			heavyArmorMasterActive = true
		end
	end
	if tes3.mobilePlayer.readiedShield and perks.blockMaster.activated then blockMasterActive = true end
	for i, ef in ipairs(LArmMaster_spell.effects) do
		ef.min = 5 * lightArmorCount
		ef.max = 5 * lightArmorCount
	end
	for i, ef in ipairs(MArmMaster_spell.effects) do
		ef.min = 5 * mediumArmorCount
		ef.max = 5 * mediumArmorCount
	end
	for i, ef in ipairs(HArmMaster_spell.effects) do
		ef.min = 5 * heavyArmorCount
		ef.max = 5 * heavyArmorCount
	end
	
	
end

--[[
	updateArmorMasterEffects():
	Controls the Mastery perks for the Armor skills (Light Armor, Medium Armor, Heavy Armor, Unarmored, Block)
	and ensures that they're properly activated and deactivated
]]
local function updateArmorMasterEffects(e)
	calcArmorMasterEffects()
	if unarmoredMasterActive then
		tes3.addSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_unarmMaster")})
	elseif tes3.hasSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_unarmMaster")} then
		tes3.removeSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_unarmMaster")})
	end
	if lightArmorMasterActive then
		tes3.addSpell({reference = tes3.player, spell = LArmMaster_spell})
	elseif tes3.hasSpell{reference = tes3.player, spell = LArmMaster_spell} then
		tes3.removeSpell({reference = tes3.player, spell = LArmMaster_spell})
	end
	if mediumArmorMasterActive then
		tes3.addSpell({reference = tes3.player, spell = MArmMaster_spell})
	elseif tes3.hasSpell{reference = tes3.player, spell = MArmMaster_spell} then
		tes3.removeSpell({reference = tes3.player, spell = MArmMaster_spell})
	end
	if heavyArmorMasterActive then
		tes3.addSpell({reference = tes3.player, spell = HArmMaster_spell})
	elseif tes3.hasSpell{reference = tes3.player, spell = HArmMaster_spell} then
		tes3.removeSpell({reference = tes3.player, HArmMaster_spell})
	end
	if blockMasterActive then
		tes3.addSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_blockMaster")})
	elseif tes3.hasSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_blockMaster")} then
		tes3.removeSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_blockMaster")})
	end
end


--[[------=Events=-------]]

local function onLoaded(e)
	if perks.deepPockets.activated or perks.deepPockets2.activated then
		tes3.mobilePlayer:updateDerivedStatistics()
	end
	bloodMagicCast = false
end

local function onHit(e)
	local favoredEnemyMult = 1.2
	if perks.favoredEnemy2.activated then favoredEnemyMult = 1.5 end
	if (e.attackerReference ~= tes3.player) then return end
	--common.info("damage before perk effects: " .. e.damage)
	
	if (e.mobile.actorType == tes3.actorType.creature) then
		if (e.reference.object.type == tes3.creatureType.normal) and (e.reference.object.blood == 0) then
			if perks.favoredBeast.activated then e.damage = e.damage * favoredEnemyMult end
		elseif(e.reference.object.type == tes3.creatureType.normal) then
			if perks.favoredConstruct.activated then e.damage = e.damage * favoredEnemyMult end
		elseif(e.reference.object.type == tes3.creatureType.daedra) then
			if perks.favoredDaedra.activated then e.damage = e.damage * favoredEnemyMult end
		elseif(e.reference.object.type == tes3.creatureType.undead) then
			if perks.favoredUndead.activated then e.damage = e.damage * favoredEnemyMult end
		elseif(e.reference.object.type == tes3.creatureType.humanoid) then
			if perks.favoredNPC.activated then e.damage = e.damage * favoredEnemyMult end
		end
	elseif (e.mobile.actorType == tes3.actorType.npc) then
		if perks.favoredNPC.activated then e.damage = e.damage * favoredEnemyMult end
		if perks.daeMephala.activated then e.damage = e.damage * (1 + (e.reference.object.disposition / 100)) end
	end
	
	if (e.source == tes3.damageSource.attack) then
		if tes3.mobilePlayer.readiedWeapon then
			if (tes3.mobilePlayer.readiedWeapon.object.skillId == tes3.skill.shortBlade) then 
			if (perks.quickStrike.activated) then
					e.damage = e.damage * ((tes3.mobilePlayer.speed.current / 200) + 1.0)
				end
			end
			
			if(tes3.mobilePlayer.readiedWeapon.object.skillId == tes3.skill.blunt) then
				if (perks.exhaustingBlows.activated) then
					e.mobile:applyFatigueDamage(e.damage)
				end
			end
			if(tes3.mobilePlayer.readiedWeapon.object.skillId == tes3.skill.axe) then
				if (perks.treeFeller.activated and (e.mobile.health.normalized > 0.5)) then
					e.damage = e.damage * 1.2
				end
			end
			if(tes3.mobilePlayer.readiedWeapon.object.skillId == tes3.skill.spear) then
				if (perks.powerfulLunge.activated) then
					local weaponReach = tes3.mobilePlayer.readiedWeapon.object.reach * tes3.findGMST(tes3.gmst.fCombatDistance).value
					
					e.damage = e.damage * (1 + ((e.mobile.playerDistance / weaponReach) / 2))
				end
			end
			if (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.marksmanThrown) and perks.knifeJuggler.activated then
				if not knifeJugglerTimer then knifeJugglerTimer = timer.start{
					duration = 5,
					persist = true,
					callback = function()
						knifeJugglerCount = 0
					end,
				}
				else 
					knifeJugglerTimer.duration = 5
					knifeJugglerCount = math.min(knifeJugglerCount + 1, 5)
				end
				e.damage = e.damage * (1 + (knifeJugglerCount * 0.1))
			end
			if (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.marksmanBow) and perks.longShot.activated then
				local dmgMult = 1.0 + math.min((e.mobile.playerDistance / 1000), 1.0)
				e.damage = e.damage * dmgMult
			end
		end
	end
	--common.info("damage after perk effects: " .. e.damage)
end

local function onHitHandToHand(e)
	if (e.attackerReference ~= tes3.player) then return end
	
	if perks.handToHandMaster.activated and (e.source ~= tes3.damageSource.script) and (not tes3.mobilePlayer.readiedWeapon) then
		if ((math.random % 100) + (tes3.mobilePlayer.luck.current / 2)) >= 90 then
			tes3.applyMagicSource({
				reference = e.reference,
				name = "Stunning Strike",
				effects = {{
					id = tes3.effect.paralyze,
					duration = 5
				}}
			})
		end
	end
end

local function onDamageResolved(e)
	if (e.attackerReference == tes3.player) and e.reference.object.soul and e.killingBlow and perks.soulSiphon.activated and e.source == tes3.damageSource.attack then
		local siphonMult = 0.2
		if perks.soulSiphon2.activated then siphonMult = 0.4 end
		local siphonAmount = math.ceil(e.reference.object.soul * siphonMult)
		if perks.soulDistributor.activated then 
			for _, stack in pairs(tes3.player.object.equipment) do
				if stack.itemData.charge then
					stack.itemData.charge = math.min(stack.itemData.charge + siphonAmount, stack.item.enchantment.maxCharge)
				end
			end
		elseif tes3.mobilePlayer.readiedWeapon.object.enchantment then
			tes3.mobilePlayer.readiedWeapon.itemData.charge =  math.min(tes3.mobilePlayer.readiedWeapon.itemData.charge + siphonAmount, tes3.mobilePlayer.readiedWeapon.object.enchantment.maxCharge)
		end
	end
end

local function onEquipped(e)
	if e.item.objectType == tes3.objectType.armor then
		updateArmorMasterEffects()
	end
	if perks.duelist.activated and (not tes3.mobilePlayer.readiedShield) and tes3.mobilePlayer.readiedWeapon and (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.longBladeOneHand) then
		tes3.addSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")}
	elseif tes3.hasSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")} then
		tes3.removeSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")}
	end
end
local function onUnequipped(e)
	if e.item.objectType == tes3.objectType.armor then
		updateArmorMasterEffects()
	end
	if perks.duelist.activated and (not tes3.mobilePlayer.readiedShield) and tes3.mobilePlayer.readiedWeapon and (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.longBladeOneHand) then
		tes3.addSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")})
	elseif tes3.hasSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")} then
		tes3.removeSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")}) 
	end
end

local function onPlayerPlayGroup(e)
	--[[
		Bulwark Code
		Checks for the Player to play the Shield Blocking animationGroup
		If mwse-lua ever gets access to the block chance calculation event, I will update this code to use that instead
	]]
	if (e.group == tes3.animationGroup.shield) and perks.bulwark.activated then
		tes3.applyMagicSource{
			reference = tes3.player,
			name = "Bulwark",
			effects = {{
				id = tes3.effect.sanctuary,
				duration = 5,
				min = tes3.mobilePlayer.block.current / 2,
				max = tes3.mobilePlayer.block.current / 2,
			}}
		}
	end
end

local function onEnchantChargeUse(e)
	if not e.isCast then return end
	--5% chance at base luck (40). since you need 60 luck to take this perk, minimum chance is 15%
	if perks.luckyEnchant.activated and ((math.random % 100) + (tes3.mobilePlayer.luck.current / 2) >= 115 ) then 
		e.charge = 0
	end
end

local function onSpellMagickaUse(e)
	if (e.caster == tes3.player) and (perks.bloodMage.activated) and (e.cost > tes3.mobilePlayer.magicka.current) and ((tes3.mobilePlayer.health.current - (e.cost - tes3.mobilePlayer.magicka.current)) > 0) then
		tes3.mobilePlayer:applyDamage{
			damage = tes3.mobilePlayer.health.current - (e.cost - tes3.mobilePlayer.magicka.current),
			applyArmor = false,
			applyDifficulty = false,
		}
		e.cost = tes3.mobilePlayer.magicka.current
		bloodMagicCast = true
	end
end

local function onSpellCast(e)
	if (e.caster == tes3.player) and bloodMagicCast then
		bloodMagicCast = false
		if perks.hemomancer.activated then
			e.castChance = 100
		end
	end
end

local function onSpellCasted(e)
	if (e.caster == tes3.player) and perks.elementalWarding.activated then
		for i, ef in ipairs(e.source.effects) do
			if (ef.id == tes3.effect.fireShield) or (ef.id == tes3.effect.lightningShield) or (ef.id == tes3.effect.frostShield) then
				tes3.applyMagicSource{
					reference = e.target,
					name = "Elemental Warding",
					effects = {
						{
							id = tes3.effect.shield,
							duration = ef.duration,
							min = e.sourceInstance:getMagnitudeForIndex(i),
							max = e.sourceInstance:getMagnitudeForIndex(i),
						},
					}
				}
			end
		end
	end
end


local function onSpellTick(e)
	if perks.trapWeaver.activated and (e.effectId == tes3.effect.open) and e.target.lockNode then
		if (e.target.lockNode.level < e.effectInstance.magnitude) and e.target.lockNode.trap then
			e.target.lockNode.trap = nil
		end
	end
	
	if perks.mysticismMaster.activated and (e.caster == player) then
		if (e.effectId == tes3.effect.absorbHealth) and (tes3.mobilePlayer.health.normalized >= 1.0) then
			tes3.applyMagicSource{
				reference = e.caster,
				name = "Overflow",
				effects = {
					{
						id = tes3.effect.fortifyHealth,
						duration = e.source.effects[e.effectIndex].duration - e.effectInstance.timeActive,
						min = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
						max = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
					},
				},
			}
		end
		
		if (e.effectId == tes3.effect.absorbMagicka) and (tes3.mobilePlayer.magicka.normalized >= 1.0) then
			tes3.applyMagicSource{
				reference = e.caster,
				name = "Overflow",
				effects = {
					{
						id = tes3.effect.fortifyMagicka,
						duration = e.source.effects[e.effectIndex].duration - e.effectInstance.timeActive,
						min = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
						max = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
					},
				},
			}
		end
		
		if (e.effectId == tes3.effect.absorbFatigue) and (tes3.mobilePlayer.fatigue.normalized >= 1.0) then
			tes3.applyMagicSource{
				reference = e.caster,
				name = "Overflow",
				effects = {
					{
						id = tes3.effect.fortifyFatigue,
						duration = e.source.effects[e.effectIndex].duration - e.effectInstance.timeActive,
						min = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
						max = e.sourceInstance:getMagnitudeForIndex(e.effectIndex),
					},
				},
			}
		end
	end
end

local function onLockPick(e)
	if e.picker ~= tes3.mobilePlayer then return end
	if not (tes3.hasCodePatchFeature(tes3.codePatchFeature.hiddenLocks) or e.lockPresent) then return end
	if e.lockPresent and perks.reliablePicking and (e.lockData.level < tes3.mobilePlayer.security.current) then
		e.chance = 100
	end
	if perks.luckySecurity.activated and ((math.random % 100) + (tes3.mobilePlayer.luck.current / 2) >= 115 ) then
		e.itemData.condition = e.itemData.condition + 1
	end
end
local function onTrapDisarm(e)
	if e.disarmer ~= tes3.mobilePlayer then return end
	if not (tes3.hasCodePatchFeature(tes3.codePatchFeature.hiddenTraps) or e.trapPresent) then return end
	if perks.luckySecurity.activated and ((math.random % 100) + (tes3.mobilePlayer.luck.current / 2) >= 115 ) then
		e.itemData.condition = e.itemData.condition + 1
	end
end

--handler for perk application effects
local function onPerkActivated(e)
	if (e.perk == "kb_perk_rigorousTraining") then
		KCP.playerData.modIncPoints({typ = "atr", mod = 3})
	end
	if (e.perk == "kb_perk_jackOfAllTrades") then
		KCP.playerData.modIncPoints({typ = "msc", mod = 5})
	end
	if (e.perk == "kb_perk_expertise") then
		KCP.playerData.modIncPoints({typ = "mjr", mod = 5})
	end
	if (e.perk == "kb_perk_wellRounded") then
		KCP.playerData.modIncPoints({typ = "mnr", mod = 5})
	end
	if (e.perk == "kb_perk_lightArmorMaster") or (e.perk == "kb_perk_mediumArmorMaster") or (e.perk == "kb_perk_heavyArmorMaster") then
		updateArmorMasterEffects()
	end
end
event.register("KBPerks:perkActivated", onPerkActivated)

local function registerPerks()
end
event.register("KCP:Initialized", registerPerks)