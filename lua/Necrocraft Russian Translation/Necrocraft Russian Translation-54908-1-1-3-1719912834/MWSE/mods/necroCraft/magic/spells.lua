local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local strings = require("NecroCraft.strings")
local utility = require("NecroCraft.utility")
local edit = require("NecroCraft.magic.edit")
local id = require("NecroCraft.magic.id")

spells = {}

local function registerSpells()

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.corruptSoulgem,
		name = strings.corruptSoulgem,
		effect = tes3.effect.corruptSoulgem,
		range = tes3.effectRange.target,
		min = 20,
		max = 20,
		radius = 3
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.spreadDisease,
		name = strings.spreadDisease1,
		effect = tes3.effect.spreadDisease,
		range = tes3.effectRange.target,
	})

  	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callSkeletonCripple,
		name = strings.callSkeletonCripple,
		effect = tes3.effect.callSkeletonCripple,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callSkeletonWarrior,
		name = strings.callSkeletonWarrior,
		effect = tes3.effect.callSkeletonWarrior,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callSkeletonChampion,
		name = strings.callSkeletonChampion,
		effect = tes3.effect.callSkeletonChampion,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callBonespider,
		name = strings.callBonespider,
		effect = tes3.effect.callBonespider,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callBonelord,
		name = strings.callBonelord,
		effect = tes3.effect.callBonelord,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callBoneoverlord,
		name = strings.callBoneoverlord,
		effect = tes3.effect.callBoneoverlord,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callBonewalker,
		name = strings.callBonewalker,
		effect = tes3.effect.callBonewalker,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.callGreaterBonewalker,
		name = strings.callGreaterBonewalker,
		effect = tes3.effect.callGreaterBonewalker,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseSkeleton1,
		name = strings.raiseSkeletonCripple,
		effect = tes3.effect.raiseSkeleton,
		range = tes3.effectRange.target,
		min = 3,
		max = 3
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseSkeleton2,
		name = strings.raiseSkeletonWarrior,
		effect = tes3.effect.raiseSkeleton,
		range = tes3.effectRange.target,
		min = 7,
		max = 7
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseSkeleton3,
		name = strings.raiseSkeletonChampion,
		effect = tes3.effect.raiseSkeleton,
		range = tes3.effectRange.target,
		min = 10,
		max = 10
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.lichResurrection,
		name = strings.lichResurrection,
		effect = tes3.effect.raiseSkeleton,
		range = tes3.effectRange.touch,
		min = 100,
		max = 100
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseCorpse1,
		name = strings.raiseCorpse1,
		effect = tes3.effect.raiseCorpse,
		range = tes3.effectRange.target,
		min = 5,
		max = 5
	})
	
	magickaExpanded.spells.createBasicSpell({	
		id = id.spell.raiseCorpse2,
		name = strings.raiseCorpse2,
		effect = tes3.effect.raiseCorpse,
		range = tes3.effectRange.target,
		min = 8,
		max = 8
	})
	
	magickaExpanded.spells.createBasicSpell({	
		id = id.spell.raiseCorpse3,
		name = strings.raiseCorpse3,
		effect = tes3.effect.raiseCorpse,
		range = tes3.effectRange.target,
		min = 25,
		max = 25
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseBonespider,
		name = strings.raiseBoneSpider,
		effect = tes3.effect.raiseBoneConstruct,
		range = tes3.effectRange.target,
		min = 3,
		max = 3
	})

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseBonelord,
		name = strings.raiseBonelord,
		effect = tes3.effect.raiseBoneConstruct,
		range = tes3.effectRange.target,
		min = 8,
		max = 8
	})

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.raiseBoneoverlord,
		name = strings.raiseBoneoverlord,
		effect = tes3.effect.raiseBoneConstruct,
		range = tes3.effectRange.target,
		min = 20,
		max = 20
	})

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.deathPact,
		name = strings.deathPact1,
		effect = tes3.effect.deathPact,
		range = tes3.effectRange.self,
		duration = 60
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = "dispelO",
		name = "развеять",
		effect = tes3.effect.dispel,
		range = tes3.effectRange.touch,
		radius = 10,
		min = 100,
		max = 100
	})

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.communeDead,
		name = strings.communeDead1,
		effect = tes3.effect.communeDead,
		range = tes3.effectRange.self,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.heartAttack,
		name = strings.heartAttack,
		effect = tes3.effect.drainHealth,
		range = tes3.effectRange.target,
		duration = 1,
		min = 120,
		max = 120
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.convulsion,
		name = strings.convulsion,
		effect = tes3.effect.drainFatigue,
		range = tes3.effectRange.target,
		duration = 3,
		min = 180,
		max = 180
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.feintDeath1,
		name = strings.feintDeath1,
		effect = tes3.effect.feintDeath,
		range = tes3.effectRange.self,
		duration = 10,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = id.spell.feintDeath2,
		name = strings.feintDeath2,
		effect = tes3.effect.feintDeath,
		range = tes3.effectRange.touch,
		duration = 10,
	})

	magickaExpanded.spells.createBasicSpell({
		id = id.spell.concealUndead,
		name = strings.concealUndead1,
		effect = tes3.effect.concealUndead,
		range = tes3.effectRange.touch,
		duration = 60,
	})
	
	--[[magickaExpanded.spells.createBasicSpell({
		id = "ritual",
		name = "Darkest Ritual",
		effect = tes3.effect.darkRitual,
		range = tes3.effectRange.self,
		duration = 10,
	})]]
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.darkestRitual,
		name = strings.darkestRitual,
		magickaCost = 250,
		effects = {
			{
				id = tes3.effect.darkRitual,
				range = tes3.effectRange.self,
				duration = 20000
			},
			{
				id = tes3.effect.damageHealth,
				range = tes3.effectRange.self,
				min = 10,
				max = 10,
				duration = 20000
			},
			{
				id = tes3.effect.poison,
				range = tes3.effectRange.self,
				min = 10,
				max = 10,
				duration = 20000
			},
			{
				id = tes3.effect.frostDamage,
				range = tes3.effectRange.self,
				min = 10,
				max = 10,
				duration = 20000
			},
		}
	})

	magickaExpanded.spells.createComplexSpell({
		id = id.spell.touchOfPain,
		name = strings.touchOfPain,
		effects = {
			{
				id = tes3.effect.damageFatigue,
				range = tes3.effectRange.touch,
				min = 5,
				max = 10,
				duration = 5
			},
			{
				id = tes3.effect.damageHealth,
				range = tes3.effectRange.touch,
				min = 5,
				max = 10,
				duration = 5
			},
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.touchOfAgony,
		name = strings.touchOfAgony,
		effects = {
			{
				id = tes3.effect.damageFatigue,
				range = tes3.effectRange.touch,
				min = 10,
				max = 20,
				duration = 5
			},
			{
				id = tes3.effect.damageHealth,
				range = tes3.effectRange.touch,
				min = 10,
				max = 20,
				duration = 5
			},
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.pain,
		name = strings.pain,
		effects = {
			{
				id = tes3.effect.damageFatigue,
				range = tes3.effectRange.target,
				min = 5,
				max = 10,
				duration = 5
			},
			{
				id = tes3.effect.damageHealth,
				range = tes3.effectRange.target,
				min = 5,
				max = 10,
				duration = 5
			},
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.agony,
		name = strings.agony,
		effects = {
			{
				id = tes3.effect.damageFatigue,
				range = tes3.effectRange.target,
				min = 10,
				max = 10,
				duration = 5
			},
			{
				id = tes3.effect.damageHealth,
				range = tes3.effectRange.target,
				min = 10,
				max = 10,
				duration = 5
			},
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.souldrinker,
		name = strings.souldrinker,
		effects = {
			{
				id = tes3.effect.soulTrap,
				range = tes3.effectRange.target,
				duration = 15
			},
			{
				id = tes3.effect.absorbHealth,
				range = tes3.effectRange.target,
				min = 5,
				max = 10,
				duration = 15
			},
			{
				id = tes3.effect.absorbMagicka,
				range = tes3.effectRange.target,
				min = 5,
				max = 10,
				duration = 15
			},
			{
				id = tes3.effect.absorbFatigue,
				range = tes3.effectRange.target,
				min = 5,
				max = 10,
				duration = 15
			}
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.massReanimation,
		name = strings.massReanimation,
		magickaCost = 50,
		effects = {
			{
				id = tes3.effect.raiseCorpse,
				range = tes3.effectRange.target,
				min = 50,
				max = 50,
				radius = 50
			},
			{
				id = tes3.effect.raiseSkeleton,
				range = tes3.effectRange.target,
				min = 50,
				max = 50,
				radius = 50
			},
			{
				id = tes3.effect.raiseBoneConstruct,
				range = tes3.effectRange.target,
				min = 100,
				max = 100,
				radius = 50
			},
		}
	})
	
	magickaExpanded.spells.createComplexSpell({
		id = id.spell.massSkeletal,
		name = strings.massReanimation,
		magickaCost = 30,
		effects = {
			{
				id = tes3.effect.raiseSkeleton,
				range = tes3.effectRange.target,
				min = 50,
				max = 50,
				radius = 50
			},
			{
				id = tes3.effect.raiseBoneConstruct,
				range = tes3.effectRange.target,
				min = 5,
				max = 5,
				radius = 50
			},
		}
	})
	edit.necromancers()
	edit.enchantments()
	edit.playerSummonUndead()
	edit.summonUndead()
end

event.register("MagickaExpanded:Register", registerSpells)

return spells