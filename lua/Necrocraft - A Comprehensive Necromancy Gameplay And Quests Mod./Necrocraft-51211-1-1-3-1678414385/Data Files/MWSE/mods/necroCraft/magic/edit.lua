local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local utility = require("NecroCraft.utility")
local common  = require("NecroCraft.common")
local id = require("NecroCraft.magic.id")

local edit = {}

-- Changing the behaviour of the original summon undead effects

local effectsResolved = {}

edit.createUndead = function(e)
	local caster = e.caster
	local spell = e.source
	local creature = nil
	e.source.effects[e.effectIndex + 1].duration = 0
	
	-- prevents from firing the same event twice for the same caster and effect
	if effectsResolved[caster] == nil then
		effectsResolved[caster] = {}
	elseif effectsResolved[caster][e.effectId] then 
		return
	end
	effectsResolved[caster][e.effectId] = true
	timer.start{duration = 0.1, callback = function()
		effectsResolved[caster] = nil
	end}

	if e.effectId == tes3.effect.summonSkeletalMinion then
		creature = "skeleton"
	elseif e.effectId == tes3.effect.summonBonewalker then
		creature = "bonewalker"
	elseif e.effectId == tes3.effect.summonGreaterBonewalker then
		creature = "Bonewalker_Greater"
	elseif e.effectId == tes3.effect.summonBonelord then
		creature = "bonelord"
	end
	
	creature = utility.placeInFront(caster, creature, 150)
	tes3.setAIFollow{reference = creature, target = caster}
end

local function getSummonUndeadEffect(spell)
	for i, effect in pairs(spell.effects) do
		if effect.id > 106 and effect.id < 111 then
			return effect.id
		end
	end
end

edit.summonUndead = function()
	if not common.config.editSummonUndeadEffects and not common.config.replaceSummonUndeadSpells then 
		return 
	end
	mwse.log("NecroCraft: editSummonUndeadEffects: %s", common.config.editSummonUndeadEffects)
	mwse.log("NecroCraft: replaceSummonUndeadSpells: %s", common.config.replaceSummonUndeadSpells)
	if common.config.editSummonUndeadEffects then
		--[[for effect = tes3.effect.summonSkeletalMinion, tes3.effect.summonBonelord do
			effect.hasNoDuration = true
			effect.appliesOnce = true
		end]]
		for enchantment in tes3.iterateObjects(tes3.objectType.enchantment) do
			for i, effect in pairs(enchantment.effects) do
				if effect.id == tes3.effect.summonSkeletalMinion then
					effect.id = tes3.effect.callSkeletonWarrior
					effect.duration = 0
				elseif effect.id == tes3.effect.summonBonewalker then
					effect.id = tes3.effect.callBonewalker
					effect.duration = 0 
				elseif effect.id == tes3.effect.summonGreaterBonewalker then
					effect.id = tes3.effect.callGreaterBonewalkerBonewalker
					effect.duration = 0
				elseif effect.id == tes3.effect.summonBonelord then
					effect.id = tes3.effect.callBonelord
					effect.duration = 0
				end
			end 
		end
	end
	for spell in tes3.iterateObjects(tes3.objectType.spell) do
		local effect = getSummonUndeadEffect(spell)
		if effect then
			if common.config.editSummonUndeadEffects then
				spell.castType = 5
			end
			if common.config.replaceSummonUndeadSpells then
				for npc in tes3.iterateObjects(tes3.objectType.npc) do
					if npc == tes3.player.object then
					elseif npc == tes3.player.baseObject then
					end
					if npc.spells:contains(spell) then
						ref = npc.id:lower()
						if common.config.necromancers[ref] then
							-- Necromancers have summon undead and call undead spells
							-- They can both teach the player and "create" new undead once a day
							if effect == tes3.effect.summonSkeletalMinion then
								npc.spells:add(tes3.getObject(id.spell.callSkeletonWarrior))
							elseif effect == tes3.effect.summonBonewalker then
								npc.spells:add(tes3.getObject(id.spell.callBonewalker))
							elseif effect == tes3.effect.summonGreaterBonewalker then
								npc.spells:add(tes3.getObject(id.spell.callGreaterBonewalker))
							elseif effect == tes3.effect.summonBonelord then
								npc.spells:add(tes3.getObject(id.spell.callBonelord))
							end
						elseif common.config.summonTeachers[ref] then
							-- Summon teachers only teach player how to summon undead but don't do it themselves
							-- They have only call undead spells
							npc.spells:remove(spell)
							if effect == tes3.effect.summonSkeletalMinion then
								npc.spells:add(tes3.getObject(id.spell.callSkeletonWarrior))
							elseif effect == tes3.effect.summonBonewalker then
								npc.spells:add(tes3.getObject(id.spell.callBonewalker))
							elseif effect == tes3.effect.summonGreaterBonewalker then
								npc.spells:add(tes3.getObject(id.spell.callGreaterBonewalker))
							elseif effect == tes3.effect.summonBonelord then
								npc.spells:add(tes3.getObject(id.spell.callBonelord))
							end
						else
							-- Everyone else use summon daedra instead of summon undead
							-- skeleton -> scamp
							-- bonewalker -> scamp
							-- greater bonewalker -> clanfear
							-- bonelord -> fire atronach
							npc.spells:remove(spell)
							if effect == tes3.effect.summonSkeletalMinion or effect == tes3.effect.summonBonewalker then
								npc.spells:add(tes3.getObject("summon scamp"))
							elseif effect == tes3.effect.summonGreaterBonewalker then
								npc.spells:add(tes3.getObject("summon clanfear"))
							elseif effect == tes3.effect.summonBonelord then
								npc.spells:add(tes3.getObject("summon flame atronach"))
							end
						end
					end
				end
			end
		end
	end
end

edit.playerSummonUndead = function()
	if common.config.replaceSummonUndeadSpells then
		for _, spell in pairs(tes3.mobilePlayer.object.spells) do
			local effect = getSummonUndeadEffect(spell)
			if effect then
				tes3.mobilePlayer.object.spells:remove(spell)
				if effect == tes3.effect.summonSkeletalMinion then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callSkeletonWarrior))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callSkeletonWarrior}
				elseif effect == tes3.effect.summonBonewalker then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callBonewalker))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callBonewalker}
				elseif effect == tes3.effect.summonGreaterBonewalker then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callGreaterBonewalker))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.id.spell.callGreaterBonewalker}
				elseif effect == tes3.effect.summonBonelord then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callBonelord))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.id.spell.callBonelord}
				end
			end
		end
	end
end 

edit.sharn = function(e)
	if e.topic ~= "MG_Sharn_Necro" and e.index < 10 then return end
	event.unregister("journal", edit.sharn)
	mwscript.addSpell{reference="sharn gra-muzgob", spell=id.spell.raiseCorpse1}
	mwscript.addSpell{reference="sharn gra-muzgob", spell=id.spell.raiseSkeleton1}
	mwscript.addSpell{reference="sharn gra-muzgob", spell=id.spell.callBonewalker}
	mwscript.addSpell{reference="sharn gra-muzgob", spell=id.spell.callSkeletonCripple}
end

edit.enchantments = function()
	local enchantment = tes3.getObject("nc_sc_faramexperiment_en")
	if enchantment then
		enchantment.effects[1].id = tes3.effect.feintDeath
	end
	enchantment = tes3.getObject("nc_sc_sharncommune_en")
	if enchantment then
		enchantment.effects[1].id = tes3.effect.communeDead
	end
	enchantment = tes3.getObject("NC_ConcealUndead_EN")
	if enchantment then
		enchantment.effects[1].id = tes3.effect.concealUndead
	end
	enchantment = tes3.getObject("Masque of Clavicus")
	if enchantment then
		local numEffects = enchantment:getActiveEffectCount()
		enchantment.effects[numEffects + 1] = enchantment.effects[numEffects]
		enchantment.effects[numEffects + 1].id = tes3.effect.concealUndead
	end
end

local alreadyEdited = {}


local function addFirstTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId)
	actor.spells:add(tes3.getObject(id.spell.raiseCorpse1))
	actor.spells:add(tes3.getObject(id.spell.raiseSkeleton1))
	actor.spells:add(tes3.getObject(id.spell.raiseBonespider))
	-- actor.spells:add(tes3.getObject(id.spell.blackSoulTrap1))
	actor.spells:add(tes3.getObject(id.spell.callBonespider))
	actor.spells:add(tes3.getObject(id.spell.callSkeletonCripple))
	alreadyEdited[actorId:lower()] = true
end

local function addSecondTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId)
	actor.spells:add(tes3.getObject(id.spell.raiseCorpse1))
	actor.spells:add(tes3.getObject(id.spell.raiseSkeleton1))
	actor.spells:add(tes3.getObject(id.spell.raiseBonespider))
	actor.spells:add(tes3.getObject(id.spell.raiseBonelord))
	actor.spells:add(tes3.getObject(id.spell.raiseCorpse2))
	actor.spells:add(tes3.getObject(id.spell.raiseSkeleton2))
	alreadyEdited[actorId:lower()] = true
	-- actor.spells:add(tes3.getObject(id.spell.blackSoulTrap2))
end

local function addThirdTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId)
	actor.spells:add(tes3.getObject(id.spell.raiseCorpse2))
	actor.spells:add(tes3.getObject(id.spell.raiseCorpse3))
	actor.spells:add(tes3.getObject(id.spell.raiseSkeleton2))
	actor.spells:add(tes3.getObject(id.spell.raiseSkeleton3))
	actor.spells:add(tes3.getObject(id.spell.raiseBonelord))
	actor.spells:add(tes3.getObject(id.spell.raiseBoneoverlord))
	alreadyEdited[actorId:lower()] = true
	-- actor.spells:add(tes3.getObject(id.spell.blackSoulTrap2))
end

edit.necromancers = function()

	-- For Gedna Relvel casting spread disease
	local spell = tes3.getObject("relvel_damage")
	spell.effects[4] = spell.effects[3]
	spell.effects[4].id = tes3.effect.spreadDisease
	-- First tier
	local npc = tes3.getObject("Dedaenc")
	npc.spells:remove(tes3.getObject("vivec's feast"))
	npc.spells:remove(tes3.getObject("sotha's mirror"))
	npc.spells:remove(tes3.getObject("invisibility"))
	npc.spells:add(tes3.getObject("calm humanoid"))
	addFirstTierNecroSpells(npc.id)
	addFirstTierNecroSpells("daris adram")
	addFirstTierNecroSpells("treras dres")
	-- Second tier
	addSecondTierNecroSpells("telura ulver")
	addSecondTierNecroSpells("tirer belvayn")
	addSecondTierNecroSpells("milyn faram")
	addSecondTierNecroSpells("Koffutto Gilgar")
	-- Third tier
	addThirdTierNecroSpells("sorkvild the raven")
	npc = tes3.getObject("sorkvild the raven")
	npc.spells:remove(tes3.getObject(id.spell.deathPact))
	addThirdTierNecroSpells("Goris the Maggot King")
	addThirdTierNecroSpells("Delvam Andarys")
	npc = tes3.getObject("Delvam Andarys")
	npc.spells:remove(tes3.getObject(id.spell.communeDead))

	for id, _ in pairs(common.config.necromancers) do
		if not alreadyEdited[id] then
			npc = tes3.getObject(id)
			if npc then
				if npc.level  < 10 then
					-- mwse.log("Adding first tier to %s", npc.id)
					addFirstTierNecroSpells(npc.id)
				elseif npc.level < 20 then
					-- mwse.log("Adding second tier to %s", npc.id)
					addSecondTierNecroSpells(npc.id)
				else
					-- mwse.log("Adding third tier to %s", npc.id)
					addThirdTierNecroSpells(npc.id)
				end
			end
		end
	end
end

return edit