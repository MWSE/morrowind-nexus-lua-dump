local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local enchancedDetection = include("OperatorJack.EnhancedDetection.spells")
local cortexBlink = include("OperatorJack.MagickaExpanded-CortexPack.effects.blinkEffect")
local cortexDarkness = include("OperatorJack.MagickaExpanded-CortexPack.effects.darknessEffect")
local cortextScrye = include("OperatorJack.MagickaExpanded-CortexPack.effects.soulScryeEffect")
--local boundWeapon = include("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects.basicBoundWeaponEffects")
local banishDaedra = include("OperatorJack.MagickaExpanded-LoreFriendlyPack.effects.banishDaedraEffect")

local spells = {
	id = {
		slowFall = "css_slow_fall",
		jump = "css_jump",
		unlock = "open",
		feather = "css_feather",
		burden = "css_burden",
		light = "css_light",
		calmHumanoid = "calming touch",
		calmCreature = "css_calm_crature",
		sound = "scc_sound",
		charm = "css_charm",
		demoralizeCreature = "css_demoralizeCreature",
		demoralizeHumanoid = "css_demoralizeHumanoid",
		sanctuary = "css_sanctuary", 
		chameleon = "css_chameleon",
		nightEye = "night-eye",
		darkness = cortexDarkness and "OJ_ME_DarknessSpell" or "blind",
		restoreMagicka = "css_restore_magicka",
		restoreFatigue = "css_restoreFatigue",
		restoreHealth = "css_restoreHealth",
		restoreMagicka = "css_restoreMagicka", 	
		fortifyAttack = "css_fortify_attack",
		fortifyHealth = "css_fortify_health",
		dummyFortifyStrength = "css_dfortify_strength",
		dummyFortifyAgility = "css_dfortify_agility",
		dummyFortifyIntelligence = "css_dfortify_intelligence",
		dummyFortifyPersonality = "css_dfortify_personality",
		fortifyStrength = "css_fortify_strength",
		fortifyAgility = "css_fortify_agility",
		fortifyIntelligence = "css_fortify_intelligence",
		fortifyPersonality = "css_fortify_personality",
		resistMagicka = "css_resist_magicka",
		cureDisease = "cure common disease",
		rallyHumanoid = "css_rallyHumanoid",
		turnUndead = "turn undead",
		summonScamp = "summon scamp",
		swiftSwim = "css_swift_swim",
		shield = "shield",
		waterWalking = "water walking",
		commandHumanoid = "css_commandHumanoid",
		commandCreature = "css_commandCreature",
		boundDagger = "bound dagger",
		boundAxe = "bound battle-axe", --boundWeapon and "OJ_ME_BoundWarAxe" or "bound battle-axe",
		boundMace = "bound mace",
		boundSword = "bound longsword",
		boundBow = "bound longbow",
		boundShield = "bound shield",
		boundSpear = "bound spear",
		banishDaedra = banishDaedra and "css_banishDaedra" or "css_commandCreature",
		fire = "fire bite",
		shockTarget = "spark",
		damageHealth = "css_damage_heath", 
		damageFatigue = "hornhand",
		poison = "poisonous touch",
		poisonTarget = "poison",
		weaknesstoMagicka = "css_weakness_magicka",
		weaknesstoPoison = "css_weakness_poison",
		disintegrateWeapon = "css_disintegrateWeapon",
		soulTrap = "soul trap",
		detectEnchantment = "detect enchantment",
		detectCreature = "detect_creature",
		detectUndeadDaedra = enchancedDetection and "css_detectUndeadDaedra" or "detect_creature",
		detectTrap = enchancedDetection and "detect_key" or "detect enchantment",
		spellAbsorbtion = "spell absorption",
		dispel = "css_dispel",
		telekinesis = "telekinesis",
		soulScrye = cortexScrye and "OJ_ME_SoulScrye" or "telekinesis",
		blink = cortexBlink and "OJ_ME_BlinkSpell" or "spell absorption"
		
	}
}

local dummySpells = {
	[spells.id.dummyFortifyStrength] = spells.id.fortifyStrength,
	[spells.id.dummyFortifyAgility] = spells.id.fortifyAgility,
	[spells.id.dummyFortifyIntelligence] = spells.id.fortifyIntelligence,
	[spells.id.dummyFortifyPersonality] = spells.id.fortifyPersonality,
}

spells.fixFortifyAttribute = function()
	for dummy, spell in pairs(dummySpells) do
		if tes3.player.baseObject.spells:contains(tes3.getObject(dummy)) then
			mwscript.removeSpell{reference = tes3.player, spell = dummy}
			mwscript.addSpell{reference = tes3.player, spell = spell}
		end
	end
end

spells.addToStarting = function(spell)
	if spell.flags ~= 2 and spell.flags ~= 3 and spell.flags < 6 then
		spell.flags = spell.flags + 2
	end
end

spells.removeFromStarting = function(spell)
	if spell.flags == 2 or spell.flags == 3 or spell.flags > 5 then
		spell.flags = spell.flags - 2
	end
end

local function registerSpells()

	if enchancedDetection then
		magickaExpanded.spells.createComplexSpell({
			id = spells.id.detectUndeadDaedra,
			name = "Detect Evil",
			magickaCost = 15,
			effects = {
				[1] = {
					id = tes3.effect.detectUndead,
					range = tes3.effectRange.self,
					duration = 10,
					min = 100,
					max = 100
				},
				[2] = {
					id = tes3.effect.detectDaedra,
					range = tes3.effectRange.self,
					duration = 10,
					min = 100,
					max = 100
				},
			}
		})
	end
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.dispel,
		name = "Minor Dispel",
		effect = tes3.effect.dispel,
		range = tes3.effectRange.self,
		min = 50,
		max = 50,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.damageHealth,
		name = "Smite",
		effect = tes3.effect.damageHealth,
		range = tes3.effectRange.touch,
		min = 15,
		max = 25,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.weaknesstoMagicka,
		name = "Suggestibility",
		effect = tes3.effect.weaknesstoMagicka,
		range = tes3.effectRange.touch,
		duration = 30,
		min = 15,
		max = 15,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.weaknesstoPoison,
		name = "Slow Metabolism",
		effect = tes3.effect.weaknesstoPoison,
		range = tes3.effectRange.touch,
		duration = 30,
		min = 15,
		max = 15,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.disintegrateWeapon,
		name = "Disarmament",
		effect = tes3.effect.disintegrateWeapon,
		range = tes3.effectRange.touch,
		min = 100,
		max = 100,
		duration = 5,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.burden,
		name = "Burden Touch",
		effect = tes3.effect.burden,
		range = tes3.effectRange.touch,
		min = 100,
		max = 100,
		duration = 15,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.slowFall,
		name = "Soft Landing",
		effect = tes3.effect.slowFall,
		range = tes3.effectRange.self,
		min = 15,
		max = 15,
		duration = 5,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.jump,
		name = "High Jump",
		effect = tes3.effect.jump,
		range = tes3.effectRange.self,
		min = 15,
		max = 15,
		duration = 5,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.feather,
		name = "Light Step",
		effect = tes3.effect.feather,
		range = tes3.effectRange.self,
		min = 30,
		max = 30,
		duration = 30,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.swiftSwim,
		name = "Swift Swim",
		effect = tes3.effect.swiftSwim,
		range = tes3.effectRange.self,
		min = 30,
		max = 30,
		duration = 30,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.calmCreature,
		name = "Petting Touch",
		effect = tes3.effect.calmCreature,
		range = tes3.effectRange.touch,
		min = 30,
		max = 30,
		duration = 10,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.light,
		name = "Light",
		effect = tes3.effect.light,
		range = tes3.effectRange.self,
		min = 20,
		max = 20,
		duration = 30,
		radius = 30
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.rallyHumanoid,
		name = "Taunt",
		effect = tes3.effect.rallyHumanoid,
		range = tes3.effectRange.touch,
		min = 50,
		max = 50,
		duration = 10,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.charm,
		name = "Impression",
		effect = tes3.effect.charm,
		range = tes3.effectRange.touch,
		min = 5,
		max = 10,
		duration = 10,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.sound,
		name = "Distraction",
		effect = tes3.effect.sound,
		range = tes3.effectRange.touch,
		min = 60,
		max = 60,
		duration = 15,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.demoralizeHumanoid,
		name = "Impose Fear",
		effect = tes3.effect.demoralizeHumanoid,
		range = tes3.effectRange.touch,
		min = 70,
		max = 70,
		duration = 10,
		magickaCost = 10,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.demoralizeCreature,
		name = "Scare Away",
		effect = tes3.effect.demoralizeCreature,
		range = tes3.effectRange.touch,
		min = 70,
		max = 70,
		duration = 10,
		magickaCost = 10,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.sanctuary,
		name = "Sanctuary",
		effect = tes3.effect.sanctuary,
		range = tes3.effectRange.self,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.chameleon,
		name = "Chameleon",
		effect = tes3.effect.chameleon,
		range = tes3.effectRange.self,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.restoreFatigue,
		name = "Short Rest",
		effect = tes3.effect.restoreFatigue,
		range = tes3.effectRange.self,
		min = 10,
		max = 10,
		duration = 10,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.restoreHealth,
		name = "Minor Heal",
		effect = tes3.effect.restoreHealth,
		range = tes3.effectRange.self,
		min = 5,
		max = 5,
		duration = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.restoreMagicka,
		name = "Meditation",
		effect = tes3.effect.restoreMagicka,
		range = tes3.effectRange.self,
		min = 1,
		max = 1,
		duration = 30,
		magickaCost = 20,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.resistMagicka,
		name = "Strong Will",
		effect = tes3.effect.resistMagicka,
		range = tes3.effectRange.self,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.fortifyHealth,
		name = "Fortitude",
		effect = tes3.effect.fortifyHealth,
		range = tes3.effectRange.self,
		min = 25,
		max = 25,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.dummyFortifyAgility,
		name = "Nimbleness",
		effect = tes3.effect.fortifyAgility,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.agility,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.fortifyAgility,
		name = "Nimbleness",
		effect = tes3.effect.fortifyAttribute,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.agility,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.dummyFortifyStrength,
		name = "Might",
		effect = tes3.effect.fortifyStrength,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.strength,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.fortifyStrength,
		name = "Might",
		effect = tes3.effect.fortifyAttribute,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.strength,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.dummyFortifyIntelligence,
		name = "Wisdom",
		effect = tes3.effect.fortifyIntelligence,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.intelligence,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.fortifyIntelligence,
		name = "Wisdom",
		effect = tes3.effect.fortifyAttribute,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.intelligence,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.dummyFortifyPersonality,
		name = "Charisma",
		effect = tes3.effect.fortifyPersonality,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.personality,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.fortifyPersonality,
		name = "Charisma",
		effect = tes3.effect.fortifyAttribute,
		range = tes3.effectRange.self,
		attribute = tes3.attribute.personality,
		min = 10,
		max = 10,
		duration = 15,
		magickaCost = 5,
	})
	
	if banishDaedra then
		spells.id.banishDaedra = "css_banishDaedra"
		magickaExpanded.spells.createBasicSpell({
			id = spells.id.banishDaedra,
			name = "Weak Banishment",
			effect = tes3.effect.banishDaedra,
			range = tes3.effectRange.touch,
			min = 5,
			max = 5,
		})
	end
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.commandHumanoid,
		name = "Manipulation",
		effect = tes3.effect.commandHumanoid,
		range = tes3.effectRange.touch,
		min = 5,
		max = 5,
		duration = 15,
		magickaCost = 15,
	})
	
	magickaExpanded.spells.createBasicSpell({
		id = spells.id.commandCreature,
		name = "Domination",
		effect = tes3.effect.commandCreature,
		range = tes3.effectRange.touch,
		attribute = tes3.attribute.intelligence,
		min = 5,
		max = 5,
		duration = 15,
		magickaCost = 15,
	})

end

event.register("MagickaExpanded:Register", registerSpells)



return spells