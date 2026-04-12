local magickaExpanded = require("OperatorJack.MagickaExpanded")
local utility = require("NecroCraft.utility")
local config  = require("NecroCraft.config")
local id = require("NecroCraft.magic.id")

local edit = {}

---@class MagickaExpanded.Effects.Effect
---@field id tes3.effect
---@field min number?
---@field max number?
---@field rangeType tes3.effectRange?
---@field duration number?
---@field radius number?
---@field attribute tes3.attribute?
---@field skill tes3.skill?
---@field cost number?
---@field object tes3magicEffect?

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
	if not config.editSummonUndeadEffects and not config.replaceSummonUndeadSpells then
		return
	end
	mwse.log("NecroCraft: editSummonUndeadEffects: %s", config.editSummonUndeadEffects)
	mwse.log("NecroCraft: replaceSummonUndeadSpells: %s", config.replaceSummonUndeadSpells)
	if config.editSummonUndeadEffects then
		--[[for effect = tes3.effect.summonSkeletalMinion, tes3.effect.summonBonelord do
			effect.hasNoDuration = true
			effect.appliesOnce = true
		end]]

		for enchantment in tes3.iterateObjects(tes3.objectType.enchantment) do
			---@cast enchantment tes3enchantment
			for i, effect in pairs(enchantment.effects) do
				if effect.id == tes3.effect.summonSkeletalMinion then
					effect.id = tes3.effect.callSkeletonWarrior
					effect.duration = 0
				elseif effect.id == tes3.effect.summonBonewalker then
					effect.id = tes3.effect.callBonewalker
					effect.duration = 0
				elseif effect.id == tes3.effect.summonGreaterBonewalker then
					effect.id = tes3.effect.callGreaterBonewalker
					effect.duration = 0
				elseif effect.id == tes3.effect.summonBonelord then
					effect.id = tes3.effect.callBonelord
					effect.duration = 0
				end
			end
		end
	end
	for spell in tes3.iterateObjects(tes3.objectType.spell) do
		---@cast spell tes3spell
		local effect = getSummonUndeadEffect(spell)
		if effect then
			if config.editSummonUndeadEffects then
				spell.castType = 5
			end
			if config.replaceSummonUndeadSpells then
				for npc in tes3.iterateObjects(tes3.objectType.npc) do
					---@cast npc tes3npc
					if npc == tes3.player.object or npc == tes3.player.baseObject then
					elseif npc.spells:contains(spell) then
						local ref = npc.id:lower()
						if config.necromancers[ref] then
							-- Necromancers have summon undead and call undead spells
							-- They can both teach the player and "create" new undead once a day
							if effect == tes3.effect.summonSkeletalMinion then
								tes3.addSpell{actor = npc, spell = id.spell.callSkeletonWarrior, updateGUI = false}
							elseif effect == tes3.effect.summonBonewalker then
								tes3.addSpell{actor = npc, spell = id.spell.callBonewalker, updateGUI = false}
							elseif effect == tes3.effect.summonGreaterBonewalker then
								tes3.addSpell{actor = npc, spell = id.spell.callGreaterBonewalker, updateGUI = false}
							elseif effect == tes3.effect.summonBonelord then
								tes3.addSpell{actor = npc, spell = id.spell.callBonelord, updateGUI = false}
							end
						elseif config.summonTeachers[ref] then
							-- Summon teachers only teach player how to summon undead but don't do it themselves
							-- They have only call undead spells
							tes3.removeSpell{actor = npc, spell = spell, updateGUI = false}
							if effect == tes3.effect.summonSkeletalMinion then
								tes3.addSpell{actor = npc, spell = id.spell.callSkeletonWarrior, updateGUI = false}
							elseif effect == tes3.effect.summonBonewalker then
								tes3.addSpell{actor = npc, spell = id.spell.callBonewalker, updateGUI = false}
							elseif effect == tes3.effect.summonGreaterBonewalker then
								tes3.addSpell{actor = npc, spell = id.spell.callGreaterBonewalker, updateGUI = false}
							elseif effect == tes3.effect.summonBonelord then
								tes3.addSpell{actor = npc, spell = id.spell.callBonelord, updateGUI = false}
							end
						else
							-- Everyone else use summon daedra instead of summon undead
							-- skeleton -> scamp
							-- bonewalker -> scamp
							-- greater bonewalker -> clanfear
							-- bonelord -> fire atronach
							tes3.removeSpell{actor = npc, spell = spell, updateGUI = false}
							if effect == tes3.effect.summonSkeletalMinion or effect == tes3.effect.summonBonewalker then
								tes3.addSpell{actor = npc, spell = "summon scamp", updateGUI = false}
							elseif effect == tes3.effect.summonGreaterBonewalker then
								tes3.addSpell{actor = npc, spell = "summon clanfear", updateGUI = false}
							elseif effect == tes3.effect.summonBonelord then
								tes3.addSpell{actor = npc, spell = "summon flame atronach", updateGUI = false}
							end
						end
					end
				end
			end
		end
	end
end

edit.playerSummonUndead = function()
	if config.replaceSummonUndeadSpells then
		for _, spell in pairs(tes3.mobilePlayer.object.spells) do
			---@cast spell tes3spell
			local effect = getSummonUndeadEffect(spell)
			if effect then
				tes3.removeSpell{reference = tes3.mobilePlayer, spell = spell}
				if effect == tes3.effect.summonSkeletalMinion then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callSkeletonWarrior))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callSkeletonWarrior}
				elseif effect == tes3.effect.summonBonewalker then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callBonewalker))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callBonewalker}
				elseif effect == tes3.effect.summonGreaterBonewalker then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callGreaterBonewalker))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callGreaterBonewalker}
				elseif effect == tes3.effect.summonBonelord then
					--tes3.mobilePlayer.object.spells:add(tes3.getObject(id.spell.callBonelord))
					tes3.addSpell{reference = tes3.mobilePlayer, spell=id.spell.callBonelord}
				end
			end
		end
	end
end

edit.sharn = function(e)
	if e.topic ~= "MG_Sharn_Necro" or e.index < 10 then return end
	event.unregister("journal", edit.sharn)
	tes3.addSpell{reference="sharn gra-muzgob", spell=id.spell.raiseCorpse1}
	tes3.addSpell{reference="sharn gra-muzgob", spell=id.spell.raiseSkeleton1}
	tes3.addSpell{reference="sharn gra-muzgob", spell=id.spell.callBonewalker}
	tes3.addSpell{reference="sharn gra-muzgob", spell=id.spell.callSkeletonCripple}
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
	---@cast enchantment tes3enchantment
	if enchantment then
		local numEffects = enchantment:getActiveEffectCount()
		enchantment.effects[numEffects + 1] = enchantment.effects[numEffects]
		enchantment.effects[numEffects + 1].id = tes3.effect.concealUndead
	end
end

local alreadyEdited = {}


local function addFirstTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId) --[[@as tes3npc]]
	tes3.addSpell{actor = actor, spell = id.spell.raiseCorpse1, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseSkeleton1, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseBonespider, updateGUI = false}
	-- tes3.addSpell{actor = actor, spell = id.spell.blackSoulTrap1, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.callBonespider, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.callSkeletonCripple, updateGUI = false}
	alreadyEdited[actorId:lower()] = true
end

local function addSecondTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId) --[[@as tes3npc]]
	tes3.addSpell{actor = actor, spell = id.spell.raiseCorpse1, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseSkeleton1, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseBonespider, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseBonelord, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseCorpse2, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseSkeleton2, updateGUI = false}
	alreadyEdited[actorId:lower()] = true
	-- tes3.addSpell{actor = actor, spell = id.spell.blackSoulTrap2, updateGUI = false}
end

local function addThirdTierNecroSpells(actorId)
	local actor = tes3.getObject(actorId) --[[@as tes3npc]]
	tes3.addSpell{actor = actor, spell = id.spell.raiseCorpse2, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseCorpse3, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseSkeleton2, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseSkeleton3, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseBonelord, updateGUI = false}
	tes3.addSpell{actor = actor, spell = id.spell.raiseBoneoverlord, updateGUI = false}
	alreadyEdited[actorId:lower()] = true
	-- tes3.addSpell{actor = actor, spell = id.spell.blackSoulTrap2, updateGUI = false}
end

edit.necromancers = function()

	-- For Gedna Relvel casting spread disease
	local spell = tes3.getObject("relvel_damage")
	spell.effects[4] = spell.effects[3]
	spell.effects[4].id = tes3.effect.spreadDisease
	-- First tier
	local npc = tes3.getObject("Dedaenc") --[[@as tes3npc]]
	tes3.removeSpell{actor = npc, spell = "vivec's feast", updateGUI = false}
	tes3.removeSpell{actor = npc, spell = "sotha's mirror", updateGUI = false}
	tes3.removeSpell{actor = npc, spell = "invisibility", updateGUI = false}
	tes3.addSpell{actor = npc, spell = "calm humanoid", updateGUI = false}
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
	npc = tes3.getObject("sorkvild the raven") --[[@as tes3npc]]
	tes3.removeSpell{actor = npc, spell = id.spell.deathPact, updateGUI = false}
	addThirdTierNecroSpells("Goris the Maggot King")
	addThirdTierNecroSpells("Delvam Andarys")
	npc = tes3.getObject("Delvam Andarys") --[[@as tes3npc]]
	tes3.removeSpell{actor = npc, spell = id.spell.communeDead, updateGUI = false}

	for id, _ in pairs(config.necromancers) do
		if not alreadyEdited[id] then
			npc = tes3.getObject(id) --[[@as tes3npc]]
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
