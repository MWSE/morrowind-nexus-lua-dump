--[[
----=Kirbonated Progression Overhaul: Basic Perks=----
This is a collection of basic perks that don't require any other mods to function. It can also serve as an example of how to design perks using this framework


0.5 perks per level = 10 perks at level 20
]]


KCP = include("KBev.ProgressionMod.interop")
perkFramework = include("KBLib.PerkSystem.perkSystem")
common = require("KBev.ProgressionMod.common") --don't include this in your mods, I only include it here for my logging functions

local perks = {}

local savedDataDefault = { armorWeights = {},}
local savedData = table.copy(savedDataDefault)
local bloodMagicCast = false

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
		if tes3.hasSpell{reference = tes3.player, spell = LArmMaster_spell} then
			tes3.removeSpell({reference = tes3.player, spell = LArmMaster_spell})
		end
		tes3.addSpell({reference = tes3.player, spell = LArmMaster_spell})
	elseif tes3.hasSpell{reference = tes3.player, spell = LArmMaster_spell} then
		tes3.removeSpell({reference = tes3.player, spell = LArmMaster_spell})
	end
	if mediumArmorMasterActive then
		if tes3.hasSpell{reference = tes3.player, spell = MArmMaster_spell} then
			tes3.removeSpell({reference = tes3.player, spell = MArmMaster_spell})
		end
		tes3.addSpell({reference = tes3.player, spell = MArmMaster_spell})
	elseif tes3.hasSpell{reference = tes3.player, spell = MArmMaster_spell} then
		tes3.removeSpell({reference = tes3.player, spell = MArmMaster_spell})
	end
	if heavyArmorMasterActive then
		if tes3.hasSpell{reference = tes3.player, spell = HArmMaster_spell} then
			tes3.removeSpell({reference = tes3.player, HArmMaster_spell})
		end
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
			if(tes3.mobilePlayer.readiedWeapon.object.skillId == tes3.skill.bluntWeapon) then
				common.dbg("Blunt Weapon Hit")
				if (perks.exhaustingBlows.activated) then
					common.dbg("Apply Exhausting Blows")
					e.mobile:applyFatigueDamage(e.damage * 5, 1)
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
	common.dbg("Fatigue Damage = " .. e.fatigueDamage)
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
		if savedData.armorWeights[e.item.id] then
			e.item.weight = savedData.armorWeights[e.item.id]
			savedData.armorWeights[e.item.id] = nil
		end
		updateArmorMasterEffects()
	end
	if perks.duelist.activated and (not tes3.mobilePlayer.readiedShield) and tes3.mobilePlayer.readiedWeapon and (tes3.mobilePlayer.readiedWeapon.object.type == tes3.weaponType.longBladeOneHand) then
		tes3.addSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")})
	elseif tes3.hasSpell{reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")} then
		tes3.removeSpell({reference = tes3.player, spell = tes3.getObject("kb_ability_duelist")}) 
	end
end

local function onCalcBlockChance(e)
	--[[
		Block Perk Code
	]]
	if not (e.target == tes3.player) then return end
	
	if (perks.bulwark.activated) then
		e.blockChance = e.blockChance + (tes3.mobilePlayer.endurance.current / 2)
	end
	local maxBlock = tes3.findGMST(tes3.gmst.iBlockMaxChance).value
	if e.blockChance > maxBlock then e.blockChance = maxBlock end
	common.dbg("Player Block Chance = " .. e.blockChance)
	
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
			damage = (e.cost - tes3.mobilePlayer.magicka.current),
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

local function onLoaded(e)
	if not tes3.player.data.kb_basicPerks then 
		tes3.player.data.kb_basicPerks = table.copy(savedDataDefault)
	end
	if perks.deepPockets.activated or perks.deepPockets2.activated then
		tes3.mobilePlayer:updateDerivedStatistics()
	end
	savedData = tes3.player.data.kb_basicPerks
	bloodMagicCast = false
	updateArmorMasterEffects()
end

--perk register code
local function registerPerks()

	LArmMaster_spell = tes3.getObject("kb_ability_LArmMaster")
	MArmMaster_spell = tes3.getObject("kb_ability_MArmMaster")
	HArmMaster_spell = tes3.getObject("kb_ability_HArmMaster")
	
	if (not LArmMaster_spell) or (not MArmMaster_spell) or (not HArmMaster_spell) then
		common.err("KBProgression.esp not loaded, basic perks will not be initialized")
		return false
	end
	--[[
	v1.2
		Expertise: You gain 5 additional Major Skill Points per level
		-Mutually Exclusive with Jack of All Trades and Well Rounded
		
		Well Rounded: You gain 5 additional Misc Skill Points per level
		-Mutually Exclusive with Jack of All Trades and Well Rounded
	
		Favored Enemy: Beast - Gain Bonus Damage against Creatures
		Favored Enemy: Daedra - Gain Bonus Damage against Daedra
		Favored Enemy: Humanoid - Gain Bonus Damage against Humanoids
		Favored Enemy: Animunculi - Gain Bonus Damage against Machine Constructs
		Favored Enemy: Undead - Gain Bonus Damage against Undead
		
		Webspinner's Kiss - Gain Bonus Damage to NPCs based on their disposition with you.
	
	]]
	--[Non-Skill related perks]
	perks.rigorousTraining = perkFramework.createPerk({
		id = "kb_perk_rigorousTraining",
		name = "Rigorous Training",
		description = "Starting next level, you now gain an additional 3 attribute points per level",
		lvlReq = 4
	})
	perks.magickaWell = perkFramework.createPerk({
		id = "kb_perk_magickaWell",
		name = "Magicka Well",
		description = "Your Maximum Magicka increases by 0.5x Intelligence",
		attributeReq = {intelligence = 50},
		spells = {tes3.getObject("kb_ability_magickaWell")}
	})
	perks.magickaWell2 = perkFramework.createPerk({
		id = "kb_perk_magickaWell2",
		name = "Magicka Reservoir",
		description = "Your Maximum Magicka increases by 0.5x Intelligence",
		lvlReq = 4,
		attributeReq = {intelligence = 70},
		perkReq = {perks.magickaWell.id},
		spells = {tes3.getObject("kb_ability_magickaWell2")},
		hideInMenu = function() return not perks.magickaWell.activated end --perk shows up in menu after you acquire the first rank
	})
	perks.deepPockets = perkFramework.createPerk({
		id = "kb_perk_deepPockets",
		name = "Deep Pockets",
		description = "Your carrying capacity increases by 15",
		spells = {tes3.getObject("kb_ability_deepPockets")}
	})
	perks.deepPockets2 = perkFramework.createPerk({
		id = "kb_perk_deepPockets2",
		name = "Deeper Pockets",
		description = "Your carrying capacity further increases by 30",
		lvlReq = 4,
		perkReq = {perks.deepPockets.id},
		spells = {tes3.getObject("kb_ability_deepPockets2")},
		hideInMenu = function() return not perks.deepPockets.activated end --perk shows up in menu after you acquire the first rank
	})
	perks.jackOfAllTrades = perkFramework.createPerk({
		id = "kb_perk_jackOfAllTrades",
		name = "Jack of All Trades",
		description = "Starting Next level, You gain an additonal 5 Misc skill points per level",
		lvlReq = 4,
		perkExclude = {"kb_perk_expertise", "kb_perk_wellRounded"},
		customReqText = "Must not have Expertise or Well Rounded",
	})
	perks.expertise = perkFramework.createPerk({
		id = "kb_perk_expertise",
		name = "Expertise",
		description = "Starting Next level, You gain an additonal 5 Major skill points per level",
		lvlReq = 4,
		perkExclude = {"kb_perk_jackOfAllTrades", "kb_perk_wellRounded"},
		customReqText = "Must not have Jack of All Trades or Well Rounded",
	})
	perks.wellRounded = perkFramework.createPerk({
		id = "kb_perk_wellRounded",
		name = "Well Rounded",
		description = "Starting Next level, You gain an additonal 5 Minor skill points per level",
		lvlReq = 4,
		perkExclude = {"kb_perk_jackOfAllTrades", "kb_perk_expertise"},
		customReqText = "Must not have Jack of All Trades or Expertise",
	})
	perks.favoredBeast = perkFramework.createPerk({
		id = "kb_perk_favoredBeast",
		name = "Favored Enemy: Beast",
		description = 
		[[You have trained extensively in combat against Beasts, granting you a 20% damage bonus against them.
		You may only have one favored enemy]],
		perkExclude = {"kb_perk_favoredDaedra", "kb_perk_favoredNPC", "kb_perk_favoredUndead", "kb_perk_favoredConstruct",},
	})
	perks.favoredDaedra = perkFramework.createPerk({
		id = "kb_perk_favoredDaedra",
		name = "Favored Enemy: Daedra",
		description = 
		[[You have trained extensively in combat against Daedra, granting you a 20% damage bonus against them.
		You may only have one favored enemy]],
		perkExclude = {"kb_perk_favoredBeast", "kb_perk_favoredNPC", "kb_perk_favoredUndead", "kb_perk_favoredConstruct",},
	})
	perks.favoredNPC = perkFramework.createPerk({
		id = "kb_perk_favoredNPC",
		name = "Favored Enemy: Humanoid",
		description = 
		[[You have trained extensively in combat against Humanoids, granting you a 20% damage bonus against them.
		You may only have one favored enemy]],
		perkExclude = {"kb_perk_favoredDaedra", "kb_perk_favoredBeast", "kb_perk_favoredUndead", "kb_perk_favoredConstruct",},
	})
	perks.favoredUndead = perkFramework.createPerk({
		id = "kb_perk_favoredUndead",
		name = "Favored Enemy: Undead",
		description = 
		[[You have trained extensively in combat against Undead, granting you a 20% damage bonus against them.
		You may only have one favored enemy]],
		perkExclude = {"kb_perk_favoredDaedra", "kb_perk_favoredNPC", "kb_perk_favoredBeast", "kb_perk_favoredConstruct",},
	})
	perks.favoredConstruct = perkFramework.createPerk({
		id = "kb_perk_favoredConstruct",
		name = "Favored Enemy: Animunculi",
		description = 
		[[You have trained extensively in combat against Dwemer Animunculi, granting you a 20% damage bonus against them.
		You may only have one favored enemy]],
		perkExclude = {"kb_perk_favoredDaedra", "kb_perk_favoredNPC", "kb_perk_favoredUndead", "kb_perk_favoredBeast",},
	})
	perks.favoredEnemy2 = perkFramework.createPerk({
		id = "kb_perk_favoredEnemy2",
		name = "Improved Favored Enemy",
		description ="Your damage bonus against your favored enemy increases to 50%",
		lvlReq = 10,
		customReq = function() return perks.favoredBeast.activated or perks.favoredDaedra.activated or perks.favoredNPC.activated or perks.favoredUndead.activated or perks.favoredConstruct.activated end,
		hideInMenu = true
	})
		
	perks.daeMephala = perkFramework.createPerk({
		id = "kb_perk_daeMephala",
		name = "Webspinner's Kiss",
		description = "You have learned to channel the essence of Mephala, the Daedric Prince of Lies. You gain a damage bonus against NPCs proportional to your dispostion with them (Max 100%)",
		lvlReq = 15
	})
	
	--[Block perks]
	perks.blockMaster = perkFramework.createPerk({
		id = "kb_perk_blockMaster",
		name = "Expert of Deflection",
		description = "While you have a shield equipped, you gain 50 points of sanctuary and 10 points of reflect",
		
		lvlReq = 20,
		skillReq = {block = 100},
		hideInMenu = true
	})
	perks.bulwark = perkFramework.createPerk({
		id = "kb_perk_bulwark",
		name = "Bulwark",
		description = "You gain an additional bonus to your chance to block equal to 1/5 of your endurance",
		lvlReq = 4,
		attributeReq = {endurance = 60},
		skillReq = {block = 30}
	})
	--[Armorer Perks]
	--[Medium Armor Perks]
	perks.mediumArmorMaster = perkFramework.createPerk({
		id = "kb_perk_mediumArmorMaster",
		name = "Shell of Skar",
		description = "For each piece of Medium Armor you have equipped, gain 5 points of Fire, Frost, Shock, Poison, and Magicka resistance",
		
		lvlReq = 20,
		skillReq = {mediumArmor = 100},
		hideInMenu = true
	})
	--[Heavy Armor Perks]
	perks.heavyArmorMaster = perkFramework.createPerk({
		id = "kb_perk_heavyArmorMaster",
		name = "Insurmountable",
		description = "For Each piece of Heavy armor you have equipped, gain 5 points of Normal Weapon and Paralysis resistance",
		
		lvlReq = 20,
		skillReq = {heavyArmor = 100},
		hideInMenu = true
	})
	--[Blunt Weapon Perks]
	perks.exhaustingBlows = perkFramework.createPerk({
		id = "kb_perk_exhaustingBlows",
		name = "Exhausting Blows",
		description = "Succesful attacks with Blunt weapons deal additional fatigue damage equal to twice their normal damage",
		skillReq = {bluntWeapon = 25},
		hideInMenu = true
	})
	--[Long Blade Perks]

	perks.duelist = perkFramework.createPerk({
		id = "kb_perk_duelist",
		name = "Duelist",
		description = "When wielding a one handed long blade without a shield, your agility is increased by 10",
		skillReq = {longBlade = 25},
		hideInMenu = true
	})
	--[Axe Perks])
	perks.treeFeller = perkFramework.createPerk({
		id = "kb_perk_treeFeller",
		name = "Tree Feller",
		description = "Axes do 20% additional damage to targets above 50% health",
		skillReq = {axe = 25},
		hideInMenu = true
	})
	--[Spear Perks]
	perks.powerfulLunge = perkFramework.createPerk({
		id = "kb_perk_powerfulLunge",
		name = "Powerful Lunge",
		description = "Spears do up to 50% more damage the farther the target is from you",
		skillReq = {spear = 25}
	})
	--[Athletics Perks]
	--[Enchant Perks]
	perks.soulSiphon = perkFramework.createPerk({
		id = "kb_perk_soulSiphon",
		name = "Soul Siphon",
		description = "Death Blows from weapons to creatures trap 20% of the creatures soul, recharging the weapon",
		lvlReq = 4,
		skillReq = {enchant = 50}
	})
	perks.soulSiphon2 = perkFramework.createPerk({
		id = "kb_perk_soulSiphon2",
		name = "Improved Soul Siphon",
		description = "Death Blows now trap 40% of the creatures soul, rather than 20%",
		lvlReq = 10,
		skillReq = {enchant = 70},
		perkReq = {"kb_perk_soulSiphon"},
		hideInMenu = true
	})
	perks.soulDistributor = perkFramework.createPerk({
		id = "kb_perk_soulDistributor",
		name = "Soul Distributor",
		description = "Death Blows now recharge all equipped enchanted items, instead of just your equipped weapon",
		lvlReq = 15,
		skillReq = {enchant = 70},
		perkReq = {"kb_perk_soulSiphon"},
		hideInMenu = true
	})
	perks.luckyEnchant = perkFramework.createPerk({
		id = "kb_perk_luckyEnchant",
		name = "Lucky Charge",
		description = "Enchanted Items have a chance to not consume any charge, based on your Luck",
		attributeReq = {luck = 60},
		skillReq = {enchant = 40}
	})
	--[Destruction Perks] TODO
	--[Alteration Perks]
	perks.trapWeaver = perkFramework.createPerk({
		id = "kb_perk_trapWeaver",
		name = "Trap Weaver",
		description = "Unlock spells also disarm traps",
		lvlReq = 10,
		skillReq = {alteration = 60}
	})
	perks.elementalWarding = perkFramework.createPerk({
		id = "kb_perk_elementalWarding",
		name = "Elemental Warding",
		description = "Elemental Shield Effects also increase your Armor rating by half their magnitude",
		lvlReq = 10,
		skillReq = {alteration = 60}
	})
	--[Illusion Perks]
	--[Conjuration Perks]
	--[Mysticism Perks]
	perks.bloodMage = perkFramework.createPerk({
		id = "kb_perk_bloodMage",
		name = "Blood Mage",
		description = "Casting a Spell when you don't have enough Magicka will draw from your health instead",
		lvlReq = 6,
		skillReq = {mysticism = 60},
	})
	perks.hemomancer = perkFramework.createPerk({
		id = "kb_perk_hemomancer",
		name = "Hemomancer",
		description = "Spells cast using Health always succeed",
		lvlReq = 15,
		skillReq = {mysticism = 80},
		perkReq = {"kb_perk_bloodMage"},
		hideInMenu = true
	})
	perks.mysticismMaster = perkFramework.createPerk({
		id = "kb_perk_mysticismMaster",
		name = "Overflow",
		description = "Absorb Health, Magicka, and Fatigue Effects grant cumulative fortification effects when your attributes are at their maximum",
		lvlReq = 20,
		skillReq = {mysticism = 100},
		hideInMenu = true
	})
	--[Restoration Perks] Probably not going to make any restoration perks other than a capstone, it's already arguably the most powerful magic school
	--[Alchemy Perks] Similar situation to Restoration, you aren't going to need perks to motivate you to level this skill up
	--[Unarmored Perks]
	perks.unarmoredMaster = perkFramework.createPerk({
		id = "kb_perk_unarmoredMaster",
		name = "Slippery Target",
		description = "While you are wearing no armor, you gain 50 points of Sanctuary, 25 points of Reflect, and immunity to Paralysis",
		lvlReq = 20,
		skillReq = {unarmored = 100},
		hideInMenu = true
	})
	--[Security Perks]
	perks.reliablePicking = perkFramework.createPerk({
		id = "kb_perk_reliablePicking",
		name = "Reliable Picking",
		description = "Lockpicking automatically succeeds on locks with a difficulty lower than halfyour security skill",
		lvlReq = 12,
		skillReq = {security = 40},
	})
	perks.luckySecurity = perkFramework.createPerk({
		id = "kb_perk_luckySecurity",
		name = "Lucky Lockpicker",
		description = "Lockpicks and Probes have a chance to not lose durability on hit, based on your luck",
		
		attributeReq = {luck = 60},
		skillReq = {security = 40},
	})
	--[Sneak Perks]
	--[Acrobatics Perks]
	--[Light Armor Perks]
	perks.lightArmorMaster = perkFramework.createPerk({ --is this overpowered? maybe. Getting to 100 light armor in this mod means sacrificing points from other, arguably more important skills
		id = "kb_perk_lightArmorMaster",
		name = "Uncanny Dodge",
		description = "You gain 5 points of Sanctuary and 5 points of reflect for each piece of light armor you have equipped",
		lvlReq = 20,
		skillReq = {lightArmor = 100},
		hideInMenu = true
	})
	--[Short Blade Perks]
	perks.quickStrike = perkFramework.createPerk({
		id = "kb_perk_quickStrike",
		name = "Quick Strike",
		description = "Short Blades gain a bonus to damage based on your Speed attribute",
		skillReq = {shortBlade = 25},
	})
	--[Marksman Perks]
	perks.knifeJuggler = perkFramework.createPerk({
		id = "kb_perk_knifeJuggler",
		name = "Knife Juggler",
		description = "Landing hits with throwing weapons in rapid succession grants a stacking 10% damage bonus, up to 50%. lasts 5 seconds, and refreshes on each successful hit",
		skillReq = {marksman = 25},
	})
	perks.longShot = perkFramework.createPerk({
		id = "kb_perk_longShot",
		name = "Long Shot",
		description = "Bows (not crossbows) gain a 1% damage bonus for every 10 units you are from your target, up to a maximum of 100% at 1000 units (aprox. 2km)",
		skillReq = {marksman = 25},
	})
	--[Mercantile Perks]
	--[Speechcraft Perks]
	--[Hand to Hand Perks]
	perks.handToHandMaster = perkFramework.createPerk{
		id = "kb_perk_h2hMaster",
		name = "Stunning Strike",
		description = "Hand to Hand attacks have a chance to paralyze the target for 5 seconds",
		lvlReq = 20,
		skillReq = {handToHand = 100},
		hideInMenu = true,
	}
	
	event.register("loaded", onLoaded)
	event.register("damage", onHit)
	event.register("damageHandToHand", onHitHandToHand)
	event.register("damaged", onDamageResolved)
	event.register("enchantChargeUse", onEnchantChargeUse, {filter = tes3.player})
	event.register(tes3.event.calcBlockChance, onCalcBlockChance)
	event.register("equipped", onEquipped)
	event.register("unequipped", onUnequipped)
	event.register("spellTick", onSpellTick)
	event.register("spellMagickaUse", onSpellMagickaUse, {filter = tes3.player})
	event.register("spellCasted", onSpellCasted)
	event.register("spellCast", onSpellCast)
	event.register("lockPick", onLockPick)
	event.register("trapDisarm", onTrapDisarm)
end
event.register("KCP:Initialized", registerPerks)