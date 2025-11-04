KCP = include("KBev.ProgressionMod.interop")
perkFramework = include("KBLib.PerkSystem.perkSystem")
common = require("KBev.ProgressionMod.common")

local perks = {}
local saveData = {}
local function wayspellsloaded()
	if not tes3.player.data.basicPerks then
		tes3.player.data.basicPerks = {}
		saveData = tes3.player.data.basicPerks
		saveData.bleedingActors = {}
		saveData.executeTargets = {}
		saveData.crushActors = {}
		saveData.slowlyActors = {}
		saveData.burdenActors = {}
		saveData.silenceActors = {}
		saveData.soundActors = {}
		saveData.blindActors = {}
		saveData.absorbfatActors = {}
		saveData.disintegratearActors = {}
		saveData.absorbHPActors = {}
		saveData.burnActors = {}
		saveData.repaireditems = {}
		saveData.traderActors = {}
		saveData.onlyTwoJumps = true
		saveData.fullSet = false
		saveData.noDie = false
		saveData.timeToBlock = false
		saveData.dodge = false
		saveData.inCombatMark = false
		saveData.speedUp = 0
		saveData.newPotion = 0
		saveData.absorbFatigueCount = 0
		saveData.absorbHPCount = 0
		saveData.doOnceArmor = 0
		saveData.doOnceWeapon = 0
		saveData.doOnceWarriorWay = 0
		saveData.doOnceWarMage = 0
		saveData.resCount = 0
		saveData.onYbutton = 0
		saveData.onUbutton = 0
		saveData.attackBonus = 0
		saveData.maximumMagickaBonus = 0
		saveData.luckbonus = 15
		saveData.heavyArmorBonus = 10
		saveData.catEyeBonus = 10
		saveData.lightShineBonus = 10
		saveData.frogBonus = 10
		saveData.reflectBonus = 10
		saveData.heavyResistBonus = 10
		saveData.sanctuaryBonus = 10
		saveData.frostResistBonus = 10
		saveData.fireResistBonus = 10
		saveData.keyBonus = 25
		saveData.enchantBonus = 25
	else
		saveData = tes3.player.data.basicPerks
	end
	if not warmagespell then
		warmagespell = tes3.createObject({id = "kb_perk_warmagespell", name = "Воин-Маг", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.fortifyMaximumMagicka, rangeType = tes3.effectRange.self, min = saveData.maximumMagickaBonus, max = saveData.maximumMagickaBonus, duration = 0}}})
	end
	if not warriorwayspell then
		warriorwayspell = tes3.createObject({id = "kb_perk_warriorwayspell", name = "Путь Воина", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.fortifyAttack, rangeType = tes3.effectRange.self, min = saveData.attackBonus, max = saveData.attackBonus, duration = 0}}})
	end
	if not silencespell then
		silencespell = tes3.createObject({id = "kb_perk_silencespell", name = "Немота Врага", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.silence, rangeType = tes3.effectRange.target, min = 1, max = 1, duration = 30}}})
	end
	if not soundspell then
		soundspell = tes3.createObject({id = "kb_perk_soundspell", name = "Звук", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.sound, rangeType = tes3.effectRange.target, min = 50, max = 50, duration = 60}}})
	end
	if not blindspell then
		blindspell = tes3.createObject({id = "kb_perk_blindspell", name = "Слепота", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.blind, rangeType = tes3.effectRange.target, min = 50, max = 50, duration = 60}}})
	end
	if not absorbfatiguespell then
		absorbfatiguespell = tes3.createObject({id = "kb_absorbfatiguespell", name = "Поглощение стамины", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.absorbFatigue, rangeType = tes3.effectRange.target, min = saveData.absorbFatigueCount, max = saveData.absorbFatigueCount, duration = 2}}})
	end
	if not absorbHPspell then
		absorbHPspell = tes3.createObject({id = "kb_absorbHPspell", name = "Поглощение ХП", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.absorbHealth, rangeType = tes3.effectRange.target, min = saveData.absorbHPCount, max = saveData.absorbHPCount, duration = 2}}})
	end
	if not disintegratearspell then
		disintegratearspell = tes3.createObject({id = "kb_disintegratearspell", name = "Уничтожение доспехов", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.disintegrateArmor, rangeType = tes3.effectRange.target, min = 50, max = 50, duration = 2}}})
	end
	if not burnspell then
		burnspell = tes3.createObject({id = "kb_perk_burnspell", name = "Уязвимость к огню", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.weaknesstoFire, rangeType = tes3.effectRange.target, min = 50, max = 50, duration = 10}}})
	end
	if not shockspell then
		shockspell = tes3.createObject({id = "kb_perk_shockspell", name = "Уязвимость к электричеству", objectType = tes3.objectType.spell, castType = tes3.spellType.spell, effects = {{id = tes3.effect.weaknesstoShock, rangeType = tes3.effectRange.target, min = 50, max = 50, duration = 10}}})
	end
	if not heavyarmorshieldspell then
		heavyarmorshieldspell = tes3.createObject({id = "kb_perk_heavyarmorshieldspell", name = "Магический щит", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.shield, rangeType = tes3.effectRange.self, min = saveData.heavyArmorBonus, max = saveData.heavyArmorBonus, duration = 0}}})
	end
	if not lightarmorsanctuaryspell then
		lightarmorsanctuaryspell = tes3.createObject({id = "kb_lightarmorsanctuaryspell", name = "Светоч", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.sanctuary, rangeType = tes3.effectRange.self, min = saveData.sanctuaryBonus, max = saveData.sanctuaryBonus, duration = 0}}})
	end
	if not nonshieldsanctuaryspell then
		nonshieldsanctuaryspell = tes3.createObject({id = "kb_nonshieldsanctuaryspell", name = "Светоч", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.sanctuary, rangeType = tes3.effectRange.self, min = 25, max = 25, duration = 0}}})
	end
	if not lightarmorfrostresistspell then
		lightarmorfrostresistspell = tes3.createObject({id = "kblightarmorfrostresistspell", name = "Сопротивление холоду", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.resistFrost, rangeType = tes3.effectRange.self, min = saveData.frostResistBonus, max = saveData.frostResistBonus, duration = 0}}})
	end
	if not lightarmorfrogspell then
		lightarmorfrogspell = tes3.createObject({id = "kb_lightarmorfrogspell", name = "Жаба", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.jump, rangeType = tes3.effectRange.self, min = saveData.frogBonus, max = saveData.frogBonus, duration = 0}}})
	end
	if not heavyarmornighteyespell then
		heavyarmornighteyespell = tes3.createObject({id = "kb_heavyarmornighteyespell", name = "Кошачий глаз", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.nightEye, rangeType = tes3.effectRange.self, min = saveData.catEyeBonus, max = saveData.catEyeBonus, duration = 0}}})
	end
	if not heavyarmorreflectspell then
		heavyarmorreflectspell = tes3.createObject({id = "kb_heavyarmorreflectspell", name = "Отражение", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.reflect, rangeType = tes3.effectRange.self, min = saveData.reflectBonus, max = saveData.reflectBonus, duration = 0}}})
	end
	if not heavyarmorresistspell then
		heavyarmorresistspell = tes3.createObject({id = "kb_heavyarmorresistspell", name = "Сопротивление магии", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.resistMagicka, rangeType = tes3.effectRange.self, min = saveData.heavyResistBonus, max = saveData.heavyResistBonus, duration = 0}}})
	end
	if not lightarmorkeyspell then
		lightarmorkeyspell = tes3.createObject({id = "kb_lightarmorkeyspell", name = "Найти ключ", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.detectKey, rangeType = tes3.effectRange.self, min = saveData.keyBonus, max = saveData.keyBonus, duration = 0}}})
	end
	if not mediumarmorlightspell then
		mediumarmorlightspell = tes3.createObject({id = "kb_mediumarmorlightspell", name = "Свет", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.light, rangeType = tes3.effectRange.self, min = saveData.lightShineBonus, max = saveData.lightShineBonus, duration = 0}}})
	end
	if not madetectenchantspell then
		madetectenchantspell = tes3.createObject({id = "kb_madetectenchantspell", name = "Найти чары", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.detectEnchantment, rangeType = tes3.effectRange.self, min = saveData.enchantBonus, max = saveData.enchantBonus, duration = 0}}})
	end
	if not mafireresistspell then
		mafireresistspell = tes3.createObject({id = "kb_mafireresistspell", name = "Сопротивление огню", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.resistFire, rangeType = tes3.effectRange.self, min = saveData.fireResistBonus, max = saveData.fireResistBonus, duration = 0}}})
	end
	if not antronahspell1 then
		antronahspell1 = tes3.createObject({id = "kb_antronahspell1", name = "Огненный антронах", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.summonFlameAtronach, rangeType = tes3.effectRange.self, min = 1, max = 1, duration = 0}}})
	end
	if not antronahspell2 then
		antronahspell2 = tes3.createObject({id = "kb_antronahspell2", name = "Ледяной антронах", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.summonFrostAtronach, rangeType = tes3.effectRange.self, min = 1, max = 1, duration = 0}}})
	end
	if not antronahspell3 then
		antronahspell3 = tes3.createObject({id = "kb_antronahspell3", name = "Грозовой антронах", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.summonStormAtronach, rangeType = tes3.effectRange.self, min = 1, max = 1, duration = 0}}})
	end
	if not speechluck then
		speechluck = tes3.createObject({id = "kb_speechluck", name = "Продуктивная беседа", objectType = tes3.objectType.spell, castType = tes3.spellType.ability, effects = {{id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.luck, rangeType = tes3.effectRange.self, min = saveData.luckbonus, max = saveData.luckbonus, duration = 0}}})
	end
end
event.register(tes3.event.loaded, wayspellsloaded)

local function perksAfterlevelup()
	if (perks.heavyarmor.activated or perks.lightarmor.activated or perks.mediumarmor.activated) and saveData.doOnceArmor == 0 then
		local armorSlotsUnequipp = {
			tes3.armorSlot.helmet,
			tes3.armorSlot.cuirass,
			tes3.armorSlot.leftPauldron,
			tes3.armorSlot.rightPauldron,
			tes3.armorSlot.greaves,
			tes3.armorSlot.boots,
			tes3.armorSlot.leftGauntlet,
			tes3.armorSlot.rightGauntlet,
			tes3.armorSlot.shield,
			tes3.armorSlot.leftBracer,
			tes3.armorSlot.rightBracer
		}
		for _, slot in ipairs(armorSlotsUnequipp) do
			if tes3.getEquippedItem{actor = tes3.player, slot = slot, objectType = tes3.objectType.armor} then
				tes3.mobilePlayer:unequip({armorSlot = slot, type = tes3.objectType.armor})
			end
		end
		saveData.doOnceArmor = 1
	end
	if (perks.longblade.activated or perks.axe.activated or perks.bluntweapon.activated) and saveData.doOnceWeapon == 0 then
		if tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.weapon} then
			tes3.mobilePlayer:unequip({type = tes3.objectType.weapon})
		end
		saveData.doOnceWeapon = 1
	end
	if perks.warriorwayTwo.activated and saveData.doOnceWarriorWay == 1 then
		tes3.removeSpell{reference = tes3.player, spell = warriorwayspell}
		saveData.attackBonus = 20
		warriorwayspell.effects[1].min = saveData.attackBonus
		warriorwayspell.effects[1].max = saveData.attackBonus
		tes3.addSpell{reference = tes3.player, spell = warriorwayspell}
		saveData.doOnceWarriorWay = 2
	elseif perks.warriorway.activated and saveData.doOnceWarriorWay == 0 then
		saveData.attackBonus = 10
		warriorwayspell.effects[1].min = saveData.attackBonus
		warriorwayspell.effects[1].max = saveData.attackBonus
		tes3.addSpell{reference = tes3.player, spell = warriorwayspell}
		saveData.doOnceWarriorWay = 1
	end
	if perks.warmageTwo.activated and saveData.doOnceWarMage == 1 then
		tes3.removeSpell{reference = tes3.player, spell = warmagespell}
		saveData.maximumMagickaBonus = 10
		warmagespell.effects[1].min = saveData.maximumMagickaBonus
		warmagespell.effects[1].max = saveData.maximumMagickaBonus
		tes3.addSpell{reference = tes3.player, spell = warmagespell}
		saveData.doOnceWarMage = 2
	elseif perks.warmage.activated and saveData.doOnceWarMage == 0 then
		saveData.maximumMagickaBonus = 5
		warmagespell.effects[1].min = saveData.maximumMagickaBonus
		warmagespell.effects[1].max = saveData.maximumMagickaBonus
		tes3.addSpell{reference = tes3.player, spell = warmagespell}
		saveData.doOnceWarMage = 1
	end
end
event.register(tes3.event.levelUp, perksAfterlevelup)

local function combatStartCallback(e)
	if saveData.inCombatMark == true then
		return
	end
	if (perks.heavyarmorshield.activated or perks.heavyarmorreflect.activated or perks.heavyarmorresist.activated) and saveData.fullSet == true then
		if perks.heavyarmorshieldTwo.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorshieldspell} then
			if saveData.heavyArmorBonus ~= 15 then
				saveData.heavyArmorBonus = 15
				heavyarmorshieldspell.effects[1].min = saveData.heavyArmorBonus
				heavyarmorshieldspell.effects[1].max = saveData.heavyArmorBonus
			end
			tes3.addSpell{reference = tes3.player, spell = heavyarmorshieldspell}
		elseif perks.heavyarmorshield.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorshieldspell} then
			tes3.addSpell{reference = tes3.player, spell = heavyarmorshieldspell}
		end
		if perks.heavyarmorreflectTwo.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorreflectspell} then
			if saveData.reflectBonus ~= 15 then
				saveData.reflectBonus = 15
				heavyarmorreflectspell.effects[1].min = saveData.reflectBonus
				heavyarmorreflectspell.effects[1].max = saveData.reflectBonus
			end
			tes3.addSpell{reference = tes3.player, spell = heavyarmorreflectspell}
		elseif perks.heavyarmorreflect.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorreflectspell} then
			tes3.addSpell{reference = tes3.player, spell = heavyarmorreflectspell}
		end
		if perks.heavyarmorresistTwo.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorresistspell} then
			if saveData.heavyResistBonus ~= 15 then
				saveData.heavyResistBonus = 15
				heavyarmorresistspell.effects[1].min = saveData.heavyResistBonus
				heavyarmorresistspell.effects[1].max = saveData.heavyResistBonus
			end
			tes3.addSpell{reference = tes3.player, spell = heavyarmorresistspell}
		elseif perks.heavyarmorresist.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorresistspell} then
			tes3.addSpell{reference = tes3.player, spell = heavyarmorresistspell}
		end
		tes3.playSound({ reference = tes3.player, sound = "spellmake success" })
		saveData.inCombatMark = true
	elseif (perks.lightarmorsanctuary.activated or perks.lightarmorfrostresist.activated) and saveData.fullSet == true then
		if perks.lightarmorsanctuaryTwo.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorsanctuaryspell} then
			if saveData.sanctuaryBonus ~= 15 then
				saveData.sanctuaryBonus = 15
				lightarmorsanctuaryspell.effects[1].min = saveData.sanctuaryBonus
				lightarmorsanctuaryspell.effects[1].max = saveData.sanctuaryBonus
			end
			tes3.addSpell{reference = tes3.player, spell = lightarmorsanctuaryspell}
		elseif perks.lightarmorsanctuary.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorsanctuaryspell} then
			tes3.addSpell{reference = tes3.player, spell = lightarmorsanctuaryspell}
		end
		if perks.lightarmorfrostresistTwo.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorfrostresistspell} then
			if saveData.frostResistBonus ~= 15 then
				saveData.frostResistBonus = 15
				lightarmorfrostresistspell.effects[1].min = saveData.frostResistBonus
				lightarmorfrostresistspell.effects[1].max = saveData.frostResistBonus
			end
			tes3.addSpell{reference = tes3.player, spell = lightarmorfrostresistspell}
		elseif perks.lightarmorfrostresist.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorfrostresistspell} then
			tes3.addSpell{reference = tes3.player, spell = lightarmorfrostresistspell}
		end
		tes3.playSound({ reference = tes3.player, sound = "spellmake success" })
		saveData.inCombatMark = true
	elseif perks.mafireresist.activated and not tes3.hasSpell{reference = tes3.player, spell = mafireresistspell} and saveData.fullSet == true then
		if perks.mafireresistTwo.activated then
			if saveData.fireResistBonus ~= 15 then
				saveData.fireResistBonus = 15
				mafireresistspell.effects[1].min = saveData.fireResistBonus
				mafireresistspell.effects[1].max = saveData.fireResistBonus
			end
			tes3.addSpell{reference = tes3.player, spell = mafireresistspell}
		elseif perks.mafireresist.activated then
			tes3.addSpell{reference = tes3.player, spell = mafireresistspell}
		end
		tes3.playSound({ reference = tes3.player, sound = "spellmake success" })
		saveData.inCombatMark = true
	end
end
event.register(tes3.event.combatStart, combatStartCallback)

local function combatStopCallback(e)
	if saveData.inCombatMark == true then
		if tes3.hasSpell{reference = tes3.player, spell = heavyarmorshieldspell} then
			tes3.removeSpell{reference = tes3.player, spell = heavyarmorshieldspell}
		end
		if tes3.hasSpell{reference = tes3.player, spell = heavyarmorreflectspell} then
			tes3.removeSpell{reference = tes3.player, spell = heavyarmorreflectspell}
		end
		if tes3.hasSpell{reference = tes3.player, spell = heavyarmorresistspell} then
			tes3.removeSpell{reference = tes3.player, spell = heavyarmorresistspell}
		end
		if (perks.heavyarmorshield.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorshieldspell}) or (perks.heavyarmorreflect.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorreflectspell}) or (perks.heavyarmorresist.activated and not tes3.hasSpell{reference = tes3.player, spell = heavyarmorresistspell}) then
			tes3.playSound({ reference = tes3.player, sound = "spellmake fail" })
		end
		if tes3.hasSpell{reference = tes3.player, spell = lightarmorsanctuaryspell} then
			tes3.removeSpell{reference = tes3.player, spell = lightarmorsanctuaryspell}
		end
		if tes3.hasSpell{reference = tes3.player, spell = lightarmorfrostresistspell} then
			tes3.removeSpell{reference = tes3.player, spell = lightarmorfrostresistspell}
		end
		if (perks.lightarmorsanctuary.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorsanctuaryspell}) or (perks.lightarmorfrostresist.activated and not tes3.hasSpell{reference = tes3.player, spell = lightarmorfrostresistspell}) then
			tes3.playSound({ reference = tes3.player, sound = "spellmake fail" })
		end
		if tes3.hasSpell{reference = tes3.player, spell = mafireresistspell} then
			tes3.removeSpell{reference = tes3.player, spell = mafireresistspell}
			tes3.playSound({ reference = tes3.player, sound = "spellmake fail" })
		end
		saveData.inCombatMark = false
	end
end
event.register(tes3.event.combatStop, combatStopCallback)

local function cellChangedCallback(e)
	if not tes3.mobilePlayer.inCombat then
		combatStopCallback(e)
	end
end
event.register(tes3.event.cellChanged, cellChangedCallback)

local function armorAbilityOnY(e)
	if perks.heavyarmornighteyeTwo.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = heavyarmornighteyespell} then
		if saveData.catEyeBonus ~= 20 then
			saveData.catEyeBonus = 20
			heavyarmornighteyespell.effects[1].min = saveData.catEyeBonus
			heavyarmornighteyespell.effects[1].max = saveData.catEyeBonus
		end
		tes3.addSpell{reference = tes3.player, spell = heavyarmornighteyespell}
		tes3.playSound({ reference = tes3.player, sound = "illusion cast" })
		saveData.onYbutton = 1
	elseif perks.heavyarmornighteye.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = heavyarmornighteyespell} then
		tes3.addSpell{reference = tes3.player, spell = heavyarmornighteyespell}
		tes3.playSound({ reference = tes3.player, sound = "illusion cast" })
		saveData.onYbutton = 1
	elseif saveData.onYbutton == 1 and tes3.hasSpell{reference = tes3.player, spell = heavyarmornighteyespell} then
		tes3.removeSpell{reference = tes3.player, spell = heavyarmornighteyespell}
		tes3.playSound({ reference = tes3.player, sound = "Spell Failure Illusion" })
		saveData.onYbutton = 0
	elseif perks.mediumarmorlightTwo.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = mediumarmorlightspell} then
		if saveData.lightShineBonus ~= 20 then
			saveData.lightShineBonus = 20
			mediumarmorlightspell.effects[1].min = saveData.lightShineBonus
			mediumarmorlightspell.effects[1].max = saveData.lightShineBonus
		end
		tes3.addSpell{reference = tes3.player, spell = mediumarmorlightspell}
		tes3.playSound({ reference = tes3.player, sound = "illusion cast" })
		saveData.onYbutton = 1
	elseif perks.mediumarmorlight.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = mediumarmorlightspell} then
		tes3.addSpell{reference = tes3.player, spell = mediumarmorlightspell}
		tes3.playSound({ reference = tes3.player, sound = "illusion cast" })
		saveData.onYbutton = 1
	elseif saveData.onYbutton == 1 and tes3.hasSpell{reference = tes3.player, spell = mediumarmorlightspell} then
		tes3.removeSpell{reference = tes3.player, spell = mediumarmorlightspell}
		tes3.playSound({ reference = tes3.player, sound = "Spell Failure Illusion" })
		saveData.onYbutton = 0
	elseif perks.lightarmorfrogTwo.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = lightarmorfrogspell} then
		if saveData.frogBonus ~= 20 then
			saveData.frogBonus = 20
			lightarmorfrogspell.effects[1].min = saveData.frogBonus
			lightarmorfrogspell.effects[1].max = saveData.frogBonus
		end
		tes3.addSpell{reference = tes3.player, spell = lightarmorfrogspell}
		tes3.playSound({ reference = tes3.player, sound = "alteration cast" })
		saveData.onYbutton = 1
	elseif perks.lightarmorfrog.activated and saveData.fullSet == true and saveData.onYbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = lightarmorfrogspell} then
		tes3.addSpell{reference = tes3.player, spell = lightarmorfrogspell}
		tes3.playSound({ reference = tes3.player, sound = "alteration cast" })
		saveData.onYbutton = 1
	elseif saveData.onYbutton == 1 and tes3.hasSpell{reference = tes3.player, spell = lightarmorfrogspell} then
		tes3.removeSpell{reference = tes3.player, spell = lightarmorfrogspell}
		tes3.playSound({ reference = tes3.player, sound = "Spell Failure Alteration" })
		saveData.onYbutton = 0
	end
end
event.register(tes3.event.keyDown, armorAbilityOnY, { filter = tes3.scanCode.y })

local function armorAbilityOnU(e)
	if perks.lightarmorkeyTwo.activated and saveData.fullSet == true and saveData.onUbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = lightarmorkeyspell} then
		if saveData.keyBonus ~= 50 then
			saveData.keyBonus = 50
			lightarmorkeyspell.effects[1].min = saveData.keyBonus
			lightarmorkeyspell.effects[1].max = saveData.keyBonus
		end
		tes3.addSpell{reference = tes3.player, spell = lightarmorkeyspell}
		tes3.playSound({ reference = tes3.player, sound = "mysticism cast" })
		saveData.onUbutton = 1
	elseif perks.lightarmorkey.activated and saveData.fullSet == true and saveData.onUbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = lightarmorkeyspell} then
		tes3.addSpell{reference = tes3.player, spell = lightarmorkeyspell}
		tes3.playSound({ reference = tes3.player, sound = "mysticism cast" })
		saveData.onUbutton = 1
	elseif saveData.onUbutton == 1 and tes3.hasSpell{reference = tes3.player, spell = lightarmorkeyspell} then
		tes3.removeSpell{reference = tes3.player, spell = lightarmorkeyspell}
		tes3.playSound({ reference = tes3.player, sound = "Spell Failure Mysticism" })
		saveData.onUbutton = 0
	elseif perks.madetectenchantTwo.activated and saveData.fullSet == true and saveData.onUbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = madetectenchantspell} then
		if saveData.enchantBonus ~= 50 then
			saveData.enchantBonus = 50
			madetectenchantspell.effects[1].min = saveData.enchantBonus
			madetectenchantspell.effects[1].max = saveData.enchantBonus
		end
		tes3.addSpell{reference = tes3.player, spell = madetectenchantspell}
		tes3.playSound({ reference = tes3.player, sound = "mysticism cast" })
		saveData.onUbutton = 1
	elseif perks.madetectenchant.activated and saveData.fullSet == true and saveData.onUbutton == 0 and not tes3.hasSpell{reference = tes3.player, spell = madetectenchantspell} then
		tes3.addSpell{reference = tes3.player, spell = madetectenchantspell}
		tes3.playSound({ reference = tes3.player, sound = "mysticism cast" })
		saveData.onUbutton = 1
	elseif saveData.onUbutton == 1 and tes3.hasSpell{reference = tes3.player, spell = madetectenchantspell} then
		tes3.removeSpell{reference = tes3.player, spell = madetectenchantspell}
		tes3.playSound({ reference = tes3.player, sound = "Spell Failure Mysticism" })
		saveData.onUbutton = 0
	elseif perks.heavyarmorDefence.activated and saveData.fullSet == true and saveData.onUbutton == 0 then
		tes3.playSound({ reference = tes3.player, sound = "bell3" })
		tes3.messageBox("Глухая оборона!")
		saveData.onUbutton = 1
	elseif saveData.onUbutton == 1 then
		tes3.messageBox("Вы вышли из Глухой обороны!")
		saveData.onUbutton = 0
	end
end
event.register(tes3.event.keyDown, armorAbilityOnU, { filter = tes3.scanCode.u })

local function blockwrongEquipp(e)
	if e.reference ~= tes3.player then
		return
	end
	if perks.heavyarmor.activated and e.item.objectType == tes3.objectType.armor and e.item.weightClass ~= tes3.armorWeightClass.heavy then
		tes3.messageBox("Вам доступны только тяжелые доспехи!")
		e.block = true
	elseif perks.lightarmor.activated and e.item.objectType == tes3.objectType.armor and e.item.weightClass ~= tes3.armorWeightClass.light then
		tes3.messageBox("Вам доступны только легкие доспехи!")
		e.block = true
	elseif perks.mediumarmor.activated and e.item.objectType == tes3.objectType.armor and e.item.weightClass ~= tes3.armorWeightClass.medium then
		tes3.messageBox("Вам доступны только средние доспехи!")
		e.block = true
	end
	if perks.bluntweapon.activated and e.item.objectType == tes3.objectType.weapon and (e.item.type ~= tes3.weaponType.bluntOneHand and e.item.type ~= tes3.weaponType.bluntTwoClose) then
		tes3.messageBox("Вам доступны лишь молоты!")
		e.block = true
	elseif perks.longblade.activated and e.item.objectType == tes3.objectType.weapon and (e.item.type ~= tes3.weaponType.longBladeOneHand and e.item.type ~= tes3.weaponType.longBladeTwoClose) then
		tes3.messageBox("Вам доступны лишь мечи!")
		e.block = true
	elseif perks.axe.activated and e.item.objectType == tes3.objectType.weapon and (e.item.type ~= tes3.weaponType.axeOneHand and e.item.type ~= tes3.weaponType.axeTwoHand) then
		tes3.messageBox("Вам доступны лишь топоры!")
		e.block = true
	end
	if perks.warmage.activated and (e.item.objectType == tes3.objectType.lockpick or e.item.objectType == tes3.objectType.probe) then
		tes3.messageBox("Вам не доступны воровские инструменты!")
		e.block = true
	end
end
event.register(tes3.event.equip, blockwrongEquipp)

local armorSlots = {
	tes3.armorSlot.helmet,
	tes3.armorSlot.cuirass,
	tes3.armorSlot.leftPauldron,
	tes3.armorSlot.rightPauldron,
	tes3.armorSlot.greaves,
	tes3.armorSlot.boots,
	tes3.armorSlot.leftGauntlet,
	tes3.armorSlot.rightGauntlet,
	tes3.armorSlot.leftBracer,
	tes3.armorSlot.rightBracer
}
local function ArmorBonus(e)
	if e.reference ~= tes3.player then
		return
	end
	if (perks.heavyarmor.activated or perks.lightarmor.activated or perks.mediumarmor.activated) and e.item.objectType == tes3.objectType.armor and saveData.fullSet == false then
		local setbonus = 0
		for _, slot in ipairs(armorSlots) do
			if tes3.getEquippedItem{actor = tes3.player, slot = slot, objectType = tes3.objectType.armor} then
				setbonus = setbonus + 1
			end
		end
		if setbonus == 8 then
			if perks.mediumarmorfeatherTwo.activated then
				tes3.modStatistic({ reference = tes3.player, name = "encumbrance", current = -50 })
			elseif perks.mediumarmorfeather.activated then
				tes3.modStatistic({ reference = tes3.player, name = "encumbrance", current = -25 })
			end
			tes3.messageBox("Благодаря полному комплекту доспехов вы получили бонус!")
			saveData.fullSet = true
			if e.mobile.inCombat then
				combatStartCallback(e)
			end
		end
	end
end
event.register(tes3.event.equipped, ArmorBonus)

local function ArmorBonusMinus(e)
	if e.reference ~= tes3.player then
		return
	end
	if (perks.heavyarmor.activated or perks.lightarmor.activated or perks.mediumarmor.activated ) and e.item.objectType == tes3.objectType.armor and saveData.fullSet == true then
		local setbonus = 0
		for _, slot in ipairs(armorSlots) do
			if tes3.getEquippedItem{actor = tes3.player, slot = slot, objectType = tes3.objectType.armor} then
				setbonus = setbonus + 1
			end
		end
		if setbonus ~= 8 then
			if perks.mediumarmorfeatherTwo.activated then
				tes3.modStatistic({ reference = tes3.player, name = "encumbrance", current = 50 })
			elseif perks.mediumarmorfeather.activated then
				tes3.modStatistic({ reference = tes3.player, name = "encumbrance", current = 25 })
			end
			tes3.messageBox("Ваш комплект доспехов не полный, вы утратили бонус!")
			saveData.fullSet = false
			if e.mobile.inCombat then
				combatStopCallback(e)
			end
			if saveData.onYbutton == 1 then
				armorAbilityOnY(e)
			end
			if saveData.onUbutton == 1 then
				armorAbilityOnU(e)
			end
		end
	end
end
event.register(tes3.event.unequipped, ArmorBonusMinus)

local function damageModification(e)
	if saveData.timeToBlock == true and e.mobile == tes3.mobilePlayer and saveData.fullSet == true then
		e.block = true
		timer.start({
			duration = 0.03,
			callback = function()
				tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
			end
		})
		return
	end
	if perks.armorNoDie.activated and saveData.noDie == false and saveData.fullSet == true and e.mobile == tes3.mobilePlayer and (e.mobile.health.current <= e.mobile.health.base * 0.25) then
		tes3.messageBox("Будучи при смерти у вас открылось второе дыхание!")
		saveData.noDie = true
		if perks.armorNoDieTwo.activated and perks.lightarmor.activated then
			saveData.timeToBlock = true
			timer.start({duration = 12,
				callback = function()
					saveData.timeToBlock = false
				end
			})
		elseif perks.lightarmor.activated then
			saveData.timeToBlock = true
			timer.start({duration = 8,
				callback = function()
					saveData.timeToBlock = false
				end
			})
		elseif perks.armorNoDieTwo.activated and perks.heavyarmor.activated then
			timer.start({duration = 1,
				iterations = 10,
				callback = function()
					tes3.modStatistic({reference = e.mobile, name = "health", current = e.mobile.health.base * 0.05})
				end
			})
		elseif perks.heavyarmor.activated then
			timer.start({duration = 1,
				iterations = 10,
				callback = function()
					tes3.modStatistic({reference = e.mobile, name = "health", current = e.mobile.health.base * 0.025})
				end
			})
		elseif perks.armorNoDieTwo.activated and perks.mediumarmor.activated then
			saveData.timeToBlock = true
			timer.start({duration = 1,
				iterations = 5,
				callback = function()
					tes3.modStatistic({reference = e.mobile, name = "health", current = e.mobile.health.base * 0.06})
				end
			})
			timer.start({duration = 5,
				callback = function()
					saveData.timeToBlock = false
				end
			})
		elseif  perks.mediumarmor.activated then
			saveData.timeToBlock = true
			timer.start({duration = 1,
				iterations = 5,
				callback = function()
					tes3.modStatistic({reference = e.mobile, name = "health", current = e.mobile.health.base * 0.03})
				end
			})
			timer.start({duration = 5,
				callback = function()
					saveData.timeToBlock = false
				end
			})
		end
		timer.start({duration = 3600,
			callback = function()
				tes3.messageBox("Вы чувствуете, как к вам вернулось 'Второе дыхание'!")
				saveData.noDie = false
			end
		})
	end
	if e.source ~= tes3.damageSource.attack then
		return
	end
	if perks.nonShield.activated and e.mobile == tes3.mobilePlayer then
		if not tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield} then
			if perks.noArrowSword.activated and e.mobile == tes3.mobilePlayer and e.projectile then
				local angle = e.mobile:getViewToActor(e.attacker)
				if tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.weapon, type = tes3.weaponType.longBladeOneHand} and e.mobile.weaponReady and (angle > -45 and angle < 45) then
					local randomSwordArrow = math.random(1, 100)
					if randomSwordArrow > 75 then
						e.block = true
						timer.start({
							duration = 0.03,
							callback = function()
								tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
							end
						})
						local weaponSpeed = e.mobile.readiedWeapon.object.speed
						e.mobile.readiedWeapon.object.speed = 2
						local blockArrowtoSword = tes3.mobilePlayer:forceWeaponAttack({ attackType = chop })
						e.mobile.readiedWeapon.object.speed = weaponSpeed
						timer.start({
							duration = 0.1,
							callback = function()
								tes3.playSound({ reference = tes3.player, sound = "repair fail" })
								tes3.messageBox("Дальняя атака отбита мечом!")
							end
						})
						return
					end
				end
			end
			local randomAviod = math.random(1, 100)
			if randomAviod > 80 and not e.projectile then
				e.block = true
				timer.start({
					duration = 0.03,
					callback = function()
						tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
					end
				})
				if perks.mediumarmorDodge.activated then
					saveData.dodge = true
					timer.start({duration = 3,
						callback = function()
							saveData.dodge = false
						end
					})
				end
				tes3.messageBox("Вы уклонились от атаки!")
				tes3.playSound({ reference = tes3.player, sound = "Weapon Swish" })
				return
			end
		end
	elseif perks.withShield.activated and e.mobile == tes3.mobilePlayer and e.projectile then
		local angle = e.mobile:getViewToActor(e.attacker)
		if tes3.getEquippedItem{actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield} and (angle > -45 and angle < 45) then
			local randomNoArrow = math.random(1, 100)
			if randomNoArrow > 75 then
				e.block = true
				timer.start({
					duration = 0.03,
					callback = function()
						tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.shield, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
					end
				})
				tes3.playSound({ reference = tes3.player, sound = "repair fail" })
				tes3.messageBox("Дальняя атака отбита щитом!")
				timer.start({
					duration = 1,
					callback = function()
						tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
					end
				})
				return
			end
		end
	end
	if (perks.heavyarmor.activated or perks.lightarmor.activated or perks.mediumarmor.activated ) and saveData.fullSet == true and e.mobile == tes3.mobilePlayer then
		local randomDodge = math.random(1, 100)
		if (perks.mediumarmorDodgeTwo.activated and randomDodge > 75) or (perks.mediumarmorDodge.activated and randomDodge > 85) then
			e.block = true
			saveData.dodge = true
			timer.start({
				duration = 0.03,
				callback = function()
					tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle, startFlag = tes3.animationStartFlag.immediate, loopCount = 0 })
					tes3.messageBox("Вы уклонились от атаки!")
					tes3.playSound({ reference = tes3.player, sound = "Weapon Swish" })
				end
			})
			timer.start({duration = 3,
				callback = function()
					saveData.dodge = false
				end
			})
			return
		end
		if (e.mobile.isMovingBack or e.mobile.isMovingForward or e.mobile.isMovingLeft or e.mobile.isMovingRight) then
			if perks.lightarmorMovingTwo.activated then
				e.damage = e.damage * 0.75
				return
			elseif perks.lightarmorMoving.activated then
				e.damage = e.damage * 0.8
				return
			end
		end
		if saveData.onUbutton == 1 then
			if perks.heavyarmorDefenceTwo.activated then
				e.damage = e.damage * 0.5
			elseif perks.heavyarmorDefence.activated then
				e.damage = e.damage * 0.65
			end
			if perks.heavyarmorResonance.activated then
				if e.projectile then
					return
				end
				saveData.resCount = saveData.resCount + 1
				if (perks.heavyarmorResonanceTwo.activated and saveData.resCount >= 3) or (perks.heavyarmorResonance.activated and saveData.resCount >= 5) then
					tes3.modStatistic({ reference = e.attackerReference, name = "health", current = -e.attackerReference.mobile.health.base * 0.1})
					if perks.execute.activated and e.attackerReference.mobile.health.current <= e.attackerReference.mobile.health.base * 0.3 and e.attackerReference.mobile.health.current > 0 and not saveData.executeTargets[e.reference] then
						saveData.executeTargets[e.reference] = true
						tes3.messageBox("Следующий удар может добить противника!")
					end
					tes3.playSound({ reference = tes3.player, sound = "ThunderClap" })
					saveData.resCount = 0
					e.attackerReference.mobile:doJump({ velocity = tes3vector3.new(-750, 0, 500), applyFatigueCost = true, allowMidairJumping = false })
				end
			end
			return
		end
		if (perks.heavyarmorTwo.activated or perks.lightarmorTwo.activated or perks.mediumarmorTwo.activated) then
			e.damage = e.damage * 0.85
		else
			e.damage = e.damage * 0.9
		end
	end
	if not tes3.mobilePlayer.readiedWeapon or e.attackerReference ~= tes3.player then
		return
	end
	if (perks.bluntweapon.activated or perks.longblade.activated or perks.axe.activated) and tes3.mobilePlayer.weaponReady == true then
		if perks.mediumarmorСounterTwo.activated and saveData.dodge == true then
			e.damage = e.damage * 3
			saveData.dodge = false
		elseif perks.mediumarmorСounter.activated and saveData.dodge == true then
			e.damage = e.damage * 2
			saveData.dodge = false
		elseif saveData.onUbutton == 1 then
			if perks.heavyarmorDefenceTwo.activated then
				e.damage = e.damage * 0.65
			elseif perks.heavyarmorDefence.activated then
				e.damage = e.damage * 0.5
			end
		elseif (perks.bluntweaponTwo.activated or perks.longbladeTwo.activated or perks.axeTwo.activated) then
			e.damage = e.damage * 1.15
		else
			e.damage = e.damage * 1.1
		end
		if perks.bluntfatigueTwo.activated then
			tes3.modStatistic({ reference = e.reference, name = "fatigue", current = -e.damage * 3})
		elseif perks.bluntfatigue.activated then
			tes3.modStatistic({ reference = e.reference, name = "fatigue", current = -e.damage * 2})
		end
		if perks.axenonarmor.activated and not e.reference.mobile.isDead and e.reference.mobile.actorType == tes3.actorType.npc then
			local randomNoArmor = math.random(1, 100)
			if (perks.axenonarmorTwo.activated and randomNoArmor > 70) or (perks.axenonarmor.activated and randomNoArmor > 80) then
				e.reference.mobile:applyDamage({damage = e.damage, applyArmor = false})
				tes3.playSound({ reference = e.reference, sound = "Pack" })
			end
		end
		if perks.bluntshieldbroke.activated and not e.reference.mobile.isDead and e.reference.mobile.actorType == tes3.actorType.npc then
			local randomShield = math.random(1, 100)
			if (perks.bluntshieldbrokeTwo.activated and randomShield > 85) or (perks.bluntshieldbroke.activated and randomShield > 90) then
				local shield = tes3.getEquippedItem{actor = e.reference, slot = tes3.armorSlot.shield, objectType = tes3.objectType.armor}
				if shield then
					local shieldID = shield.object.id
					shield.itemData.condition = 0
					e.reference.mobile:unequip({armorSlot = tes3.armorSlot.shield})
					tes3.dropItem({ reference = e.reference, item = shieldID})
					tes3.messageBox("Противник лишился щита!")
				end
			end
		elseif perks.axenonweapon.activated and not e.reference.mobile.isDead and e.reference.mobile.actorType == tes3.actorType.npc then
			local randomDropWeapon = math.random(1, 100)
			if (perks.axenonweaponTwo.activated and randomDropWeapon > 90) or (perks.axenonweapon.activated and randomDropWeapon > 95) then
				local weapon = tes3.getEquippedItem{actor = e.reference, objectType = tes3.objectType.weapon}
				if weapon then
					local weaponID = weapon.object.id
					e.reference.mobile:unequip({type = tes3.objectType.weapon})
					tes3.dropItem({ reference = e.reference, item = weaponID})
					tes3.messageBox("Вы выбили оружие из рук противника!")
				end
			end
		end
	end
end
event.register(tes3.event.damage, damageModification)

local function onDamagedModification(e)
	if e.reference == tes3.player then
		return
	end
	if not tes3.mobilePlayer.readiedWeapon or e.attackerReference ~= tes3.player then
		return
	end
	if e.source == tes3.damageSource.attack and perks.longbladebleed.activated and not e.reference.mobile.isDead and not saveData.bleedingActors[e.reference] then
		local randomBlood = math.random(1, 100)
		if (perks.longbladebleedTwo.activated and randomBlood > 75) or (perks.longbladebleed.activated and randomBlood > 85) then
			saveData.bleedingActors[e.reference] = true
			tes3.messageBox("Противник истекает кровью!")
			local tickCount = 0
			timer.start({duration = 3,
				iterations = 5,
				callback = function()
					tickCount = tickCount + 1
					if not e.reference or not e.reference.mobile then
						saveData.bleedingActors[e.reference] = nil
						return false
					end
					tes3.modStatistic({
						reference = e.reference,
						name = "health",
						current = -e.reference.mobile.health.base * 0.02
					})
					if not e.reference.mobile.isDead then
						tes3.playSound({ reference = e.reference, sound = "Health Damage" })
					end
					if e.reference.mobile.isDead and saveData.bleedingActors[e.reference] then
						saveData.bleedingActors[e.reference] = nil
						return false
					end
					if tickCount >= 5 then
						saveData.bleedingActors[e.reference] = nil
						tes3.messageBox("Кровотечение у противника прошло!")
						return false
					end
					if perks.execute.activated and e.reference.mobile.health.current <= e.reference.mobile.health.base * 0.3 and not e.reference.mobile.isDead and not saveData.executeTargets[e.reference] then
						saveData.executeTargets[e.reference] = true
						tes3.messageBox("Следующий удар может добить противника!")
					end
				end
			})
		end
	end
	if perks.execute.activated then
		if e.reference.mobile.health.current <= e.reference.mobile.health.base * 0.3 and not e.reference.mobile.isDead and not saveData.executeTargets[e.reference] then
			saveData.executeTargets[e.reference] = true
			tes3.playSound({ reference = e.reference, sound = "critical damage" })
			tes3.messageBox("Следующий удар может добить противника!")
			return
		end
		local randomExecute = math.random(1, 100)
		if e.source == tes3.damageSource.attack and saveData.executeTargets[e.reference] and ((perks.executeTwo.activated and randomExecute > 85) or (perks.execute.activated and randomExecute > 90)) then
			tes3.modStatistic({
				reference = e.reference,
				name = "health",
				current = -e.reference.mobile.health.current
			})
			tes3.messageBox("Вы добили противника одним ударом!")
			saveData.executeTargets[e.reference] = nil
		elseif saveData.executeTargets[e.reference] and e.reference.mobile.isDead then
			saveData.executeTargets[e.reference] = nil
			return false
		end
	end
	if e.source == tes3.damageSource.attack and perks.bluntcrush.activated and not e.reference.mobile.isDead and not saveData.crushActors[e.reference] then
		local randomCrush = math.random(1, 100)
		if (perks.bluntcrushTwo.activated and randomCrush > 85) or (perks.bluntcrush.activated and randomCrush > 90) then
			saveData.crushActors[e.reference] = true
			e.reference.mobile.paralyze = 1
			tes3.messageBox("Ваш удар оглушил противника!")
			timer.start({
				duration = 5,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.crushActors[e.reference] = nil
						e.reference.mobile.paralyze = 0
						return false
					end
					if e.reference.mobile.isDead and saveData.crushActors[e.reference] then
						saveData.crushActors[e.reference] = nil
						e.reference.mobile.paralyze = 0
						return false
					end
					saveData.crushActors[e.reference] = nil
					e.reference.mobile.paralyze = 0
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.longbladeslowly.activated and not e.reference.mobile.isDead and not saveData.slowlyActors[e.reference] then
		local randomSlowly = math.random(1, 100)
		if (perks.longbladeslowlyTwo.activated and randomSlowly > 75) or (perks.longbladeslowly.activated and randomSlowly > 85) then
			saveData.slowlyActors[e.reference] = true
			tes3.messageBox("Противник хромает!")
			tes3.modStatistic({ reference = e.reference, name = "speed", current = -100, limit = true})
			timer.start({
				duration = 10,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.slowlyActors[e.reference] = nil
						tes3.modStatistic({ reference = e.reference, name = "speed", current = 100, limitToBase = true})
						return false
					end
					if e.reference.mobile.isDead and saveData.slowlyActors[e.reference] then
						saveData.slowlyActors[e.reference] = nil
						tes3.modStatistic({ reference = e.reference, name = "speed", current = 100, limitToBase = true})
						return false
					end
					saveData.slowlyActors[e.reference] = nil
					tes3.modStatistic({ reference = e.reference, name = "speed", current = 100, limitToBase = true})
					tes3.messageBox("Противник больше не хромает!")
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.burden.activated and not e.reference.mobile.isDead and not saveData.burdenActors[e.reference] then
		local randomBurden = math.random(1, 100)
		if (perks.burdenTwo.activated and randomBurden > 85) or (perks.burden.activated and randomBurden > 90) then
			saveData.burdenActors[e.reference] = true
			tes3.messageBox("На противника наложена обуза!")
			tes3.modStatistic({ reference = e.reference, name = "encumbrance", current = 500 })
			timer.start({
				duration = 10,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.burdenActors[e.reference] = nil
						tes3.modStatistic({ reference = e.reference, name = "encumbrance", current = -500 })
						return false
					end
					if e.reference.mobile.isDead and saveData.burdenActors[e.reference] then
						saveData.burdenActors[e.reference] = nil
						tes3.modStatistic({ reference = e.reference, name = "encumbrance", current = -500 })
						return false
					end
					saveData.burdenActors[e.reference] = nil
					tes3.modStatistic({ reference = e.reference, name = "encumbrance", current = -500 })
					tes3.messageBox("Обуза с противника снята!")
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.antronah.activated then
		local randomAtronah = math.random(1, 100)
		if (perks.antronahTwo.activated and randomAtronah > 85) or (perks.antronah.activated and randomAtronah > 90) then
			local randomType = math.random(0, 9)
			if randomType <= 3 then
				if not tes3.hasSpell{reference = tes3.player, spell = antronahspell1} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell2} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell3} then
					tes3.messageBox("Вы призвали Атронаха!")
					tes3.addSpell{reference = tes3.player, spell = antronahspell1}
					timer.start({
						duration = 10,
						callback = function()
							tes3.removeSpell{reference = tes3.player, spell = antronahspell1}
							tes3.messageBox("Атронах исчез!")
						end
					})
				end
			elseif randomType >= 4 and randomType <=6 then
				if not tes3.hasSpell{reference = tes3.player, spell = antronahspell1} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell2} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell3} then
					tes3.messageBox("Вы призвали Атронаха!")
					tes3.addSpell{reference = tes3.player, spell = antronahspell2}
					timer.start({
						duration = 10,
						callback = function()
							tes3.removeSpell{reference = tes3.player, spell = antronahspell2}
							tes3.messageBox("Атронах исчез!")
						end
					})
				end
			elseif randomType >=7 then
				if not tes3.hasSpell{reference = tes3.player, spell = antronahspell1} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell2} and not tes3.hasSpell{reference = tes3.player, spell = antronahspell3} then
					tes3.messageBox("Вы призвали Атронаха!")
					tes3.addSpell{reference = tes3.player, spell = antronahspell3}
					timer.start({
						duration = 10,
						callback = function()
							tes3.removeSpell{reference = tes3.player, spell = antronahspell3}
							tes3.messageBox("Атронах исчез!")
						end
					})
				end
			end
		end
	end
	if e.source == tes3.damageSource.attack and perks.longbladesilence.activated and not e.reference.mobile.isDead and not saveData.silenceActors[e.reference] then
		local randomSilence = math.random(1, 100)
		if (perks.longbladesilenceTwo.activated and randomSilence > 85) or (perks.longbladesilence.activated and randomSilence > 90) then
			saveData.silenceActors[e.reference] = true
			tes3.messageBox("На противника наложена немота!")
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference,
				source = "kb_perk_silencespell",
				bypassResistances = true
			})
			timer.start({
				duration = 30,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.silenceActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.silenceActors[e.reference] then
						saveData.silenceActors[e.reference] = nil
						return false
					end
					saveData.silenceActors[e.reference] = nil
					tes3.messageBox("Противник снова может произносить заклинания!")
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Illusion" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.bluntsound.activated and not e.reference.mobile.isDead and not saveData.soundActors[e.reference] then
		local randomSound = math.random(1, 100)
		if (perks.bluntsoundTwo.activated and randomSound > 85) or (perks.bluntsound.activated and randomSound > 90) then
			saveData.soundActors[e.reference] = true
			tes3.messageBox("На противника наложен эффект 'Звук'!")
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_perk_soundspell",
				bypassResistances = true
			})
			timer.start({
				duration = 60,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.soundActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.soundActors[e.reference] then
						saveData.soundActors[e.reference] = nil
						return false
					end
					saveData.soundActors[e.reference] = nil
					tes3.messageBox("'Звук' с противника снят!")
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Illusion" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.axeblind.activated and not e.reference.mobile.isDead and not saveData.blindActors[e.reference] then
		local randomBlind = math.random(1, 100)
		if (perks.axeblindTwo.activated and randomBlind > 85) or (perks.axeblind.activated and randomBlind > 90) then
			saveData.blindActors[e.reference] = true
			tes3.messageBox("Ваше оружие частично ослепило противника !")
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_perk_blindspell",
				bypassResistances = true
			})
			timer.start({
				duration = 60,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.blindActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.blindActors[e.reference] then
						saveData.blindActors[e.reference] = nil
						return false
					end
					saveData.blindActors[e.reference] = nil
					tes3.messageBox("Зрение противника восстановлено!")
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Illusion" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.bluntabsorbfatigue.activated and not e.reference.mobile.isDead and not saveData.absorbfatActors[e.reference] then
		local randomAbsorbFatigue = math.random(1, 100)
		if (perks.bluntabsorbfatigueTwo.activated and randomAbsorbFatigue > 85) or (perks.bluntabsorbfatigue.activated and randomAbsorbFatigue > 90) then
			saveData.absorbfatActors[e.reference] = true
			tes3.messageBox("Вы поглотили стамину противника!")
			if saveData.absorbFatigueCount ~= e.reference.mobile.fatigue.base * 0.05 then
				saveData.absorbFatigueCount = e.reference.mobile.fatigue.base * 0.05
				absorbfatiguespell.effects[1].min = saveData.absorbFatigueCount
				absorbfatiguespell.effects[1].max = saveData.absorbFatigueCount
			end
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_absorbfatiguespell",
			})
			timer.start({
				duration = 2,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.absorbfatActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.absorbfatActors[e.reference] then
						saveData.absorbfatActors[e.reference] = nil
						return false
					end
					saveData.absorbfatActors[e.reference] = nil
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Mysticism" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.axeabsorbhp.activated and not e.reference.mobile.isDead and not saveData.absorbHPActors[e.reference] then
		local randomAbsorbHP = math.random(1, 100)
		if (perks.axeabsorbhpTwo.activated and randomAbsorbHP > 85) or (perks.axeabsorbhp.activated and randomAbsorbHP > 90) then
			saveData.absorbHPActors[e.reference] = true
			tes3.messageBox("Вы поглотили здоровье противника!")
			if saveData.absorbHPCount ~= e.reference.mobile.health.base * 0.05 then
				saveData.absorbHPCount = e.reference.mobile.health.base * 0.05
				absorbHPspell.effects[1].min = saveData.absorbHPCount
				absorbHPspell.effects[1].max = saveData.absorbHPCount
			end
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_absorbHPspell",
			})
			timer.start({
				duration = 2,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.absorbHPActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.absorbHPActors[e.reference] then
						saveData.absorbHPActors[e.reference] = nil
						return false
					end
					saveData.absorbHPActors[e.reference] = nil
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Mysticism" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.bluntdisintegratear.activated and not e.reference.mobile.isDead and not saveData.disintegratearActors[e.reference] then
		local randomDesintegr = math.random(1, 100)
		if (perks.bluntdisintegratearTwo.activated and randomDesintegr > 70) or (perks.bluntdisintegratear.activated and randomDesintegr > 80) then
			saveData.disintegratearActors[e.reference] = true
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_disintegratearspell",
			})
			timer.start({
				duration = 2,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.disintegratearActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.disintegratearActors[e.reference] then
						saveData.disintegratearActors[e.reference] = nil
						return false
					end
					saveData.disintegratearActors[e.reference] = nil
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Destruction" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.longbladeburn.activated and not e.reference.mobile.isDead and not saveData.burnActors[e.reference] then
		local randomBurn = math.random(1, 100)
		if (perks.longbladeburnTwo.activated and randomBurn > 85) or (perks.longbladeburn.activated and randomBurn > 90) then
			saveData.burnActors[e.reference] = true
			tes3.messageBox("На противника наложена Уязвимость к огню!")
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_perk_burnspell",
			})
			timer.start({
				duration = 10,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.burnActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.burnActors[e.reference] then
						saveData.burnActors[e.reference] = nil
						return false
					end
					saveData.burnActors[e.reference] = nil
					tes3.messageBox("Уязвимость к огню с противника снята!")
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Destruction" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.axeshock.activated and not e.reference.mobile.isDead and not saveData.burnActors[e.reference] then
		local randomBurning = math.random(1, 100)
		if (perks.axeshockTwo.activated and randomBurning > 85) or (perks.axeshock.activated and randomBurning > 90) then
			saveData.burnActors[e.reference] = true
			tes3.messageBox("На противника наложена Уязвимость к электричеству!")
			tes3.applyMagicSource({
				reference = tes3.player,
				target = e.reference, 
				source = "kb_perk_shockspell",
			})
			timer.start({
				duration = 10,
				callback = function()
					if not e.reference or not e.reference.mobile then
						saveData.burnActors[e.reference] = nil
						return false
					end
					if e.reference.mobile.isDead and saveData.burnActors[e.reference] then
						saveData.burnActors[e.reference] = nil
						return false
					end
					saveData.burnActors[e.reference] = nil
					tes3.messageBox("Уязвимость к электричеству с противника снята!")
					tes3.playSound({ reference = tes3.player, sound = "Spell Failure Destruction" })
				end
			})
		end
	end
	if e.source == tes3.damageSource.attack and perks.longbladesoultrap.activated then
		local randomSoul = math.random(1, 100)
		if (perks.longbladesoultrapTwo.activated and randomSoul > 70) or (perks.longbladesoultrap.activated and randomSoul > 80) then
			local chargeWeapon = tes3.getEquippedItem{actor = tes3.player, enchanted = true, objectType = tes3.objectType.weapon}
			if chargeWeapon and chargeWeapon.object and chargeWeapon.object.objectType == tes3.objectType.weapon and chargeWeapon.object.enchantment and chargeWeapon.object.enchantment.castType == tes3.enchantmentType.onStrike then
				chargeWeapon.itemData.charge = math.min(chargeWeapon.itemData.charge + (chargeWeapon.object.enchantment.maxCharge * 0.2), chargeWeapon.object.enchantment.maxCharge)
			end
		end
	end
end
event.register(tes3.event.damaged, onDamagedModification)

local function onBindsFunction(e)
	if (not e.result) then
		return
	end
	if perks.warmage.activated and e.keybind == tes3.keybind.sneak and e.transition == tes3.keyTransition.downThisFrame then
		e.result = false
		tes3.messageBox("Скрытность запрещена в древе талантов Воин-Маг!")
	end
	if (e.keybind == tes3.keybind.forward or e.keybind == tes3.keybind.back or e.keybind == tes3.keybind.left or e.keybind == tes3.keybind.right) and e.transition == tes3.keyTransition.isDown and saveData.fullSet == true then
		if saveData.onUbutton == 1 and perks.heavyarmorDefence.activated then
			e.result = false
		elseif perks.lightarmorStamineTwo.activated and tes3.mobilePlayer.inCombat then
			tes3.modStatistic({ reference = tes3.mobilePlayer, name = "fatigue", current = tes3.mobilePlayer.fatigue.base * 0.0006, limitToBase = true})
		elseif perks.lightarmorStamine.activated and tes3.mobilePlayer.inCombat then
			tes3.modStatistic({ reference = tes3.mobilePlayer, name = "fatigue", current = tes3.mobilePlayer.fatigue.base * 0.0003, limitToBase = true})
		end
	end
end
event.register(tes3.event.keybindTested, onBindsFunction)

local function magicschoolchoise(e)
	if e.caster ~= tes3.player then
		return
	end
	if e.spell.castType ~= tes3.spellType.spell then
		return
	end
	if perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCI.activated or perks.magicschoolCA.activated or perks.magicschoolCM.activated or perks.magicschoolRI.activated or perks.magicschoolRA.activated or perks.magicschoolRM.activated or perks.magicschoolRC.activated or perks.magicschoolDI.activated or perks.magicschoolDA.activated or perks.magicschoolDM.activated or perks.magicschoolDC.activated or perks.magicschoolDR.activated then
		for _, effect in ipairs(e.spell.effects) do
			if effect.object and ((perks.magicschoolAI.activated and effect.object.school ~= tes3.magicSchool.alteration and effect.object.school ~= tes3.magicSchool.illusion) or (perks.magicschoolMI.activated and effect.object.school ~= tes3.magicSchool.mysticism and effect.object.school ~= tes3.magicSchool.illusion) or (perks.magicschoolMA.activated and effect.object.school ~= tes3.magicSchool.mysticism and effect.object.school ~= tes3.magicSchool.alteration) or (perks.magicschoolCI.activated and effect.object.school ~= tes3.magicSchool.conjuration and effect.object.school ~= tes3.magicSchool.illusion) or (perks.magicschoolCA.activated and effect.object.school ~= tes3.magicSchool.conjuration and effect.object.school ~= tes3.magicSchool.alteration) or (perks.magicschoolCM.activated and effect.object.school ~= tes3.magicSchool.conjuration and effect.object.school ~= tes3.magicSchool.mysticism) or (perks.magicschoolRI.activated and effect.object.school ~= tes3.magicSchool.restoration and effect.object.school ~= tes3.magicSchool.illusion) or (perks.magicschoolRA.activated and effect.object.school ~= tes3.magicSchool.restoration and effect.object.school ~= tes3.magicSchool.alteration) or (perks.magicschoolRM.activated and effect.object.school ~= tes3.magicSchool.restoration and effect.object.school ~= tes3.magicSchool.mysticism) or (perks.magicschoolRC.activated and effect.object.school ~= tes3.magicSchool.restoration and effect.object.school ~= tes3.magicSchool.conjuration) or (perks.magicschoolDI.activated and effect.object.school ~= tes3.magicSchool.destruction and effect.object.school ~= tes3.magicSchool.illusion) or (perks.magicschoolDA.activated and effect.object.school ~= tes3.magicSchool.destruction and effect.object.school ~= tes3.magicSchool.alteration) or (perks.magicschoolDM.activated and effect.object.school ~= tes3.magicSchool.destruction and effect.object.school ~= tes3.magicSchool.mysticism) or (perks.magicschoolDC.activated and effect.object.school ~= tes3.magicSchool.destruction and effect.object.school ~= tes3.magicSchool.conjuration) or (perks.magicschoolDR.activated and effect.object.school ~= tes3.magicSchool.destruction and effect.object.school ~= tes3.magicSchool.restoration)) then
				e.cost = 0
				e.instance.castChanceOverride = 0
				tes3.messageBox("Вам не доступны заклинания других магических школ!")
				return false
			end
		end
		if perks.magicschoolthree.activated then
			if math.random(0, 9) > 2 then
				return
			end
			e.cost = 0
			e.instance.castChanceOverride = 100
			tes3.messageBox("Вы успешно произнесли заклинание, не затратив магию!")
		elseif perks.magicschooltwo.activated then
			if math.random(0, 9) > 1 then
				return
			end
			e.cost = 0
			e.instance.castChanceOverride = 100
			tes3.messageBox("Вы успешно произнесли заклинание, не затратив магию!")
		else
			if math.random(0, 9) > 0 then
				return
			end
			e.cost = 0
			e.instance.castChanceOverride = 100
			tes3.messageBox("Вы успешно произнесли заклинание, не затратив магию!")
		end
	end
end
event.register(tes3.event.spellMagickaUse, magicschoolchoise)

local function repairCallback(e)
	if perks.repairer.activated and e.item.objectType and e.item.objectType == tes3.objectType.weapon and not saveData.repaireditems[e.item.id] then
		if e.itemData.condition + e.repairAmount >= e.item.maxCondition then
			saveData.repaireditems[e.item.id] = true
			tes3.messageBox("Оружие заточено и сбалансировано. Урон увеличен. Эффект длится в течении 60 минут.")
			if perks.repairerTwo.activated then
				e.item.chopMin = e.item.chopMin * 1.2
				e.item.chopMax = e.item.chopMax * 1.2
				e.item.slashMin = e.item.slashMin * 1.2
				e.item.slashMax = e.item.slashMax * 1.2
				e.item.thrustMin = e.item.thrustMin * 1.2
				e.item.thrustMax = e.item.thrustMax * 1.2
				e.item.value = e.item.value * 1.5
				timer.start({
					duration = 3600,
					callback = function()
						e.item.chopMin = e.item.chopMin / 1.2
						e.item.chopMax = e.item.chopMax / 1.2
						e.item.slashMin = e.item.slashMin / 1.2
						e.item.slashMax = e.item.slashMax / 1.2
						e.item.thrustMin = e.item.thrustMin / 1.2
						e.item.thrustMax = e.item.thrustMax / 1.2
						e.item.value = e.item.value / 1.5
						saveData.repaireditems[e.item.id] = nil
						tes3.messageBox("Рейтинг брони вашего доспеха вернулся к прежнему значению.")
					end
				})
			else
				e.item.chopMin = e.item.chopMin * 1.1
				e.item.chopMax = e.item.chopMax * 1.1
				e.item.slashMin = e.item.slashMin * 1.1
				e.item.slashMax = e.item.slashMax * 1.1
				e.item.thrustMin = e.item.thrustMin * 1.1
				e.item.thrustMax = e.item.thrustMax * 1.1
				e.item.value = e.item.value * 1.25
				timer.start({
					duration = 3600,
					callback = function()
						e.item.chopMin = e.item.chopMin / 1.1
						e.item.chopMax = e.item.chopMax / 1.1
						e.item.slashMin = e.item.slashMin / 1.1
						e.item.slashMax = e.item.slashMax / 1.1
						e.item.thrustMin = e.item.thrustMin / 1.1
						e.item.thrustMax = e.item.thrustMax / 1.1
						e.item.value = e.item.value / 1.25
						saveData.repaireditems[e.item.id] = nil
						tes3.messageBox("Рейтинг брони вашего доспеха вернулся к прежнему значению.")
					end
				})
			end
		end
	elseif perks.repairer.activated and e.item.objectType and e.item.objectType == tes3.objectType.armor and not saveData.repaireditems[e.item.id] then
		if e.itemData.condition + e.repairAmount >= e.item.maxCondition then
			saveData.repaireditems[e.item.id] = true
			tes3.messageBox("Вы починили доспех. Его рейтинг брони увеличен. Эффект длится в течении 60 минут.")
			if perks.repairerTwo.activated then
				e.item.armorRating = e.item.armorRating * 1.2
				e.item.value = e.item.value * 1.5
				timer.start({
					duration = 3600,
					callback = function()
						e.item.armorRating = e.item.armorRating / 1.2
						e.item.value = e.item.value / 1.5
						saveData.repaireditems[e.item.id] = nil
						tes3.messageBox("Рейтинг брони вашего доспеха вернулся к прежнему значению.")
					end
				})
			else
				e.item.armorRating = e.item.armorRating * 1.1
				e.item.value = e.item.value * 1.25
				timer.start({
					duration = 3600,
					callback = function()
						e.item.armorRating = e.item.armorRating / 1.1
						e.item.value = e.item.value / 1.25
						saveData.repaireditems[e.item.id] = nil
						tes3.messageBox("Рейтинг брони вашего доспеха вернулся к прежнему значению.")
					end
				})
			end
		end
	end
end
event.register(tes3.event.repair, repairCallback)

local function enchantChargeUseCallback(e)
	if e.caster ~= tes3.player then
		return
	end
	if e.isCast == false then
		return
	end
	if perks.enchanter.activated then
		local randomEnchante = math.random(1, 100)
		if (perks.enchanterTwo.activated and randomEnchante > 70) or (perks.enchanter.activated and randomEnchante > 80) then
			e.charge = 0
			tes3.messageBox("Заряд предмета не был израсходован.")
		end
	end
end
event.register(tes3.event.enchantChargeUse, enchantChargeUseCallback)

local function speechwork(e)
	if (perks.speechadmire.activated and e.info.type == tes3.dialogueType.service and e.dialogue.id == "Admire Success") or (perks.speechintimidate.activated and e.info.type == tes3.dialogueType.service and e.dialogue.id == "Intimidate Success") then
		if e.actor.objectType == tes3.objectType.npc then
			if e.actor.disposition >= 90  and (not tes3.hasSpell{reference = tes3.player, spell = speechluck})then
				if perks.speechadmireTwo.activated or perks.speechintimidateTwo.activated then
					if saveData.luckbonus ~= 30 then
						saveData.luckbonus = 30
						speechluck.effects[1].min = saveData.luckbonus
						speechluck.effects[1].max = saveData.luckbonus
					end
					tes3.addSpell{reference = tes3.player, spell = speechluck}
				else
					tes3.addSpell{reference = tes3.player, spell = speechluck}
				end
				tes3.messageBox("Благодаря продуктивной беседе вы воспряли духом и ваша Удача увеличилась на 1 час!")
				timer.start({
					duration = 3600,
					callback = function()
						tes3.removeSpell{reference = tes3.player, spell = speechluck}
						tes3.messageBox("Спустя 1 час ваша Удача вернулась к исходному значению!")
					end
				})
				
			end
		end
	end
end
event.register(tes3.event.dialogueFiltered, speechwork)

local function burterGold(e)
	if e.activator ~= tes3.player then
		return
	end
	
	if perks.trader.activated and e.target.baseObject.objectType == tes3.objectType.npc and not saveData.traderActors[e.target.id] then
		e.target.baseObject.barterGold = e.target.baseObject.barterGold * 10
		saveData.traderActors[e.target.id] = true
	end
end
event.register(tes3.event.activate, burterGold)

local function potionBrewedCallback(e)
	if perks.alchemyst.activated then
		local randomPotion = math.random(1, 100)
		if perks.alchemystTwo.activated and randomPotion > 70 then
			if not tes3.getObject(("k" .. e.object.id)) then
				saveData.newPotion = e.object:createCopy({ id = ("k" .. e.object.id) })
				saveData.newPotion.value = e.object.value * 4
				saveData.newPotion.weight = e.object.weight / 4
				saveData.newPotion.name = e.object.name .. "+"
			end
			tes3.removeItem({ reference = tes3.player, item = e.object })
			tes3.addItem({ reference = tes3.player, item = saveData.newPotion, count = 2 })
			tes3.messageBox("Вместо стандартного зелья вы сварили два Улучшенных!")
		elseif perks.alchemyst.activated and randomPotion > 80 then
			if not tes3.getObject(("k" .. e.object.id)) then
				saveData.newPotion = e.object:createCopy({ id = ("k" .. e.object.id) })
				saveData.newPotion.value = e.object.value * 2
				saveData.newPotion.weight = e.object.weight / 2
				saveData.newPotion.name = e.object.name .. "+"
			end
			tes3.removeItem({ reference = tes3.player, item = e.object })
			tes3.addItem({ reference = tes3.player, item = saveData.newPotion, count = 2 })
			tes3.messageBox("Вместо стандартного зелья вы сварили два Улучшенных!")
		end
	end
end
event.register(tes3.event.potionBrewed, potionBrewedCallback)

local function keySpreenter(e)
	if perks.spreenter.activated and saveData.speedUp == 0 then
		tes3.modStatistic({ reference = tes3.player, name = "athletics", current = 150})
		saveData.speedUp = 1
		timer.start({
			duration = 10,
			callback = function()
				tes3.modStatistic({ reference = tes3.player, name = "athletics", current = -150})
				saveData.speedUp = 2
				tes3.messageBox("Вам нужно перевести дыхание, прежде чем снова ускориться!")
				
				timer.start({
					duration = 20,
					callback = function()
						saveData.speedUp = 0
						tes3.messageBox("Вы восстановили дыхание и снова можете ускориться!")
					end
				})
			end
		})
	elseif perks.spreenter.activated and saveData.speedUp == 2 then
		tes3.messageBox("Вам нужно перевести дыхание, прежде чем снова ускориться!")
	end
end
event.register(tes3.event.keyDown, keySpreenter, { filter = tes3.scanCode.q })

local function jumpTwo(e)
	if perks.jumper.activated and saveData.onlyTwoJumps == true then
		tes3.mobilePlayer:doJump({ allowMidairJumping = true })
		saveData.onlyTwoJumps = false
	end
	if tes3.mobilePlayer.isJumping == false then
		saveData.onlyTwoJumps = true
	end
end
event.register(tes3.event.keyDown, jumpTwo, { filter = tes3.scanCode.space })

local function registerPerks()
	perks.warriorway = perkFramework.createPerk({
		id = "kb_perk_warriorway",
		name = "Путь Воина",
		description = "Путь Воина увеличивает шанс провести успешную физическую атаку на 10.(Выбор Пути - основополагающий. Дальнейшее развитие персонажа будет происходить в рамках древа талантов выбранного Пути.)",
		lvlReq = 2,
		perkExclude = {"kb_perk_mageway", "kb_perk_rogueway"},
		hideInMenu = true,
	})
	perks.warmage = perkFramework.createPerk({
		id = "kb_perk_warmage",
		name = "Воин-Маг",
		lvlReq = 4,
		description = "Вы не просто Воин - вы Воин-Маг. Ваш максимальный показатель магии увеличен на коэффициент 0.5",
		hideInMenu = true,
	})
	perks.heavyarmor = perkFramework.createPerk({
		id = "kb_perk_heavyarmor",
		name = "Тяжелые доспехи",
		description = "Вы специализируетесь на тяжелых доспехах, остальные вам недоступны. Но благодаря отличной подгонке, полный комплект тяжелых доспехов(кроме щита) уменьшает входящий физический урон на 10%.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_mediumarmor", "kb_perk_lightarmor"},
		hideInMenu = true,
	})
	perks.mediumarmor = perkFramework.createPerk({
		id = "kb_perk_mediumarmor",
		name = "Средние доспехи",
		description = "Вы специализируетесь на средних доспехах, остальные вам недоступны. Но благодаря отличной подгонке, полный комплект средних доспехов(кроме щита) уменьшает входящий физический урон на 10%.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_heavyarmor", "kb_perk_lightarmor"},
		hideInMenu = true,
	})
	perks.lightarmor = perkFramework.createPerk({
		id = "kb_perk_lightarmor",
		name = "Легкие доспехи",
		description = "Вы специализируетесь на легких доспехах, остальные вам недоступны. Но благодаря отличной подгонке, полный комплект легких доспехов(кроме щита) уменьшает входящий физический урон на 10%.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_mediumarmor", "kb_perk_heavyarmor"},
		hideInMenu = true,
	})
	perks.longblade = perkFramework.createPerk({
		id = "kb_perk_longblade",
		name = "Длинные клинки",
		description = "Вы специализируетесь на длинных клинках, остальное оружие вам недоступно. Но благодаря отличной подготовке, длинные клинки в ваших руках наносят на 10% больше урона.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_bluntweapon", "kb_perk_axe"},
		hideInMenu = true,
	})
	perks.axe = perkFramework.createPerk({
		id = "kb_perk_axe",
		name = "Секиры",
		description = "Вы специализируетесь на секирах, остальное оружие вам недоступно. Но благодаря отличной подготовке, секиры в ваших руках наносят на 10% больше урона.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_bluntweapon", "kb_perk_longblade"},
		hideInMenu = true,
	})
	perks.bluntweapon = perkFramework.createPerk({
		id = "kb_perk_bluntweapon",
		name = "Дробящее оружие",
		description = "Вы специализируетесь на дробящем оружии, остальное оружие вам недоступно. Но благодаря отличной подготовке, дробящее оружие в ваших руках наносит на 10% больше урона.",
		lvlReq = 6,
		perkReq = {"kb_perk_warriorway"},
		perkExclude = {"kb_perk_longblade", "kb_perk_axe"},
		hideInMenu = true,
	})
	perks.magicschoolDR = perkFramework.createPerk({
		id = "kb_perk_magicschoolDR",
		name = "Разрушение + Восстановление",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolDC = perkFramework.createPerk({
		id = "kb_perk_magicschoolDC",
		name = "Разрушение + Колдовство",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDR", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolDM = perkFramework.createPerk({
		id = "kb_perk_magicschoolDM",
		name = "Разрушение + Мистицизм",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDR", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolDA = perkFramework.createPerk({
		id = "kb_perk_magicschoolDA",
		name = "Разрушение + Изменение",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDR", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolDI = perkFramework.createPerk({
		id = "kb_perk_magicschoolDI",
		name = "Разрушение + Иллюзии",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDR", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolRC = perkFramework.createPerk({
		id = "kb_perk_magicschoolRC",
		name = "Восстановление + Колдовство",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolDR", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolRM = perkFramework.createPerk({
		id = "kb_perk_magicschoolRM",
		name = "Восстановление + Мистицизм",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolDR", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolRA = perkFramework.createPerk({
		id = "kb_perk_magicschoolRA",
		name = "Восстановление + Изменение",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolDR", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolRI = perkFramework.createPerk({
		id = "kb_perk_magicschoolRI",
		name = "Восстановление + Иллюзии",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolDR", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolCM = perkFramework.createPerk({
		id = "kb_perk_magicschoolCM",
		name = "Колдовство + Мистицизм",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolDR", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolCA = perkFramework.createPerk({
		id = "kb_perk_magicschoolCA",
		name = "Колдовство + Изменение",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolDR", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolCI = perkFramework.createPerk({
		id = "kb_perk_magicschoolCI",
		name = "Колдовство + Иллюзии",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolDR", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolMA = perkFramework.createPerk({
		id = "kb_perk_magicschoolMA",
		name = "Мистицизм + Изменение",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolDR", "kb_perk_magicschoolMI", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolMI = perkFramework.createPerk({
		id = "kb_perk_magicschoolMI",
		name = "Мистицизм + Иллюзии",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolDR", "kb_perk_magicschoolAI"},
		hideInMenu = true,
	})
	perks.magicschoolAI = perkFramework.createPerk({
		id = "kb_perk_magicschoolAI",
		name = "Изменение + Иллюзии",
		description = "Будучи Воином-Магом вам доступны лишь две школы магии. Однако теперь у вас есть 10% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 10,
		perkExclude = {"kb_perk_magicschoolDC", "kb_perk_magicschoolDM", "kb_perk_magicschoolDA", "kb_perk_magicschoolDI", "kb_perk_magicschoolRC", "kb_perk_magicschoolRM", "kb_perk_magicschoolRA", "kb_perk_magicschoolRI", "kb_perk_magicschoolCM", "kb_perk_magicschoolCA", "kb_perk_magicschoolCI", "kb_perk_magicschoolMA", "kb_perk_magicschoolMI", "kb_perk_magicschoolDR"},
		hideInMenu = true,
	})
	perks.warriorwayTwo = perkFramework.createPerk({
		id = "kb_perk_warriorwayTwo",
		name = "Искусный воин",
		description = "Теперь Путь Воина увеличивает ваш шанс провести успешную физическую атаку на 20 пунктов.",
		lvlReq = 12,
		perkReq = {"kb_perk_warriorway"},
		hideInMenu = true,
	})
	perks.warmageTwo = perkFramework.createPerk({
		id = "kb_perk_warmageTwo",
		name = "Искусный Воин-Маг",
		description = "Теперь ваш максимальный показатель магии увеличен на коэффициент 1.",
		lvlReq = 12,
		perkReq = {"kb_perk_warmage"},
		hideInMenu = true,
	})
	perks.heavyarmorTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorTwo",
		name = "Тяжелые доспехи II",
		description = "Теперь, благодаря отличной подгонке, полный комплект тяжелых доспехов(кроме щита) уменьшает входящий физический урон на 15%.",
		lvlReq = 12,
		perkReq = {"kb_perk_heavyarmor"},
		hideInMenu = true,
	})
	perks.mediumarmorTwo = perkFramework.createPerk({
		id = "kb_perk_mediumarmorTwo",
		name = "Средние доспехи II",
		description = "Теперь, благодаря отличной подгонке, полный комплект средних доспехов(кроме щита) уменьшает входящий физический урон на 15%.",
		lvlReq = 12,
		perkReq = {"kb_perk_mediumarmor"},
		hideInMenu = true,
	})
	perks.lightarmorTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorTwo",
		name = "Легкие доспехи II",
		description = "Теперь благодаря отличной подгонке, полный комплект легких доспехов(кроме щита) уменьшает входящий физический урон на 15%.",
		lvlReq = 12,
		perkReq = {"kb_perk_lightarmor"},
		hideInMenu = true,
	})
	perks.longbladeTwo = perkFramework.createPerk({
		id = "kb_perk_longbladeTwo",
		name = "Длинные клинки II",
		description = "Теперь благодаря отличной подготовке, длинные клинки в ваших руках наносят на 15% больше урона.",
		lvlReq = 12,
		perkReq = {"kb_perk_longblade"},
		hideInMenu = true,
	})
	perks.axeTwo = perkFramework.createPerk({
		id = "kb_perk_axeTwo",
		name = "Секиры II",
		description = "Теперь благодаря отличной подготовке, секиры в ваших руках наносят на 15% больше урона.",
		lvlReq = 12,
		perkReq = {"kb_perk_axe"},
		hideInMenu = true,
	})
	perks.bluntweaponTwo = perkFramework.createPerk({
		id = "kb_perk_bluntweaponTwo",
		name = "Дробящее оружие II",
		description = "Теперь благодаря отличной подготовке, дробящее оружие в ваших руках наносит на 15% больше урона.",
		lvlReq = 12,
		perkReq = {"kb_perk_bluntweapon"},
		hideInMenu = true,
	})
	perks.mediumarmorDodge = perkFramework.createPerk({
		id = "kb_perk_mediumarmorDodge",
		name = "Уклонение",
		description = "Полный комплект доспехов(кроме щита) позволяет с вероятностью 15% полностью избежать физического урона.",
		perkReq = {"kb_perk_mediumarmor"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.mediumarmorDodgeTwo = perkFramework.createPerk({
		id = "kb_perk_mediumarmorDodgeTwo",
		name = "Уклонение II",
		description = "Теперь ваша вероятность полностью избежать физического урона равна 25%.",
		perkReq = {"kb_perk_mediumarmorDodge"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.mediumarmorСounter = perkFramework.createPerk({
		id = "kb_perk_mediumarmorСounter",
		name = "Контратака",
		description = "После успешного уклонения ваш следующий удар в течении 3 секунд нанесет двойной урон.",
		perkReq = {"kb_perk_mediumarmorDodge"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.mediumarmorСounterTwo = perkFramework.createPerk({
		id = "kb_perk_mediumarmorСounterTwo",
		name = "Контратака II",
		description = "Теперь контратака наносит тройной урон.",
		perkReq = {"kb_perk_mediumarmorСounter"},
		lvlReq = 16,
		hideInMenu = true,
	})
	perks.armorNoDie = perkFramework.createPerk({
		id = "kb_perk_armorNoDie",
		name = "Второе дыхание",
		description = "Если в бою ваше здоровье опускается нище 20%, то:\nСредние доспехи - в течении 5 секунд вы имунны к урону, а так же восполняете 15% здоровья.\nТяжелые доспехи - в течении 10 секунд вы восполняете 25% здоровья.\nЛегкие Доспехи - в течении 8 секунд вы имунны к урону.\nЭффект срабатывает раз в 60 минут.",
		lvlReq = 12,
		customReq = function() return perks.heavyarmor.activated or perks.lightarmor.activated or perks.mediumarmor.activated end,
		hideInMenu = true,
	})
	perks.armorNoDieTwo = perkFramework.createPerk({
		id = "kb_perk_armorNoDieTwo",
		name = "Второе дыхание II",
		description = "Если в бою ваше здоровье опускается нище 20%, то:\nСредние доспехи - в течении 5 секунд вы имунны к урону, а так же восполняете 30% здоровья.\nТяжелые доспехи - в течении 10 секунд вы восполняете 50% здоровья.\nЛегкие Доспехи - в течении 12 секунд вы имунны к урону.\nЭффект срабатывает раз в 60 минут.",
		lvlReq = 14,
		perkReq = {"kb_perk_armorNoDie"},
		hideInMenu = true,
	})
	perks.heavyarmorDefence = perkFramework.createPerk({
		id = "kb_perk_heavyarmorDefence",
		name = "Глухая оборона",
		description = "Полный комплект доспехов(кроме щита) позволяет занять Глухую оборону, где входящий урон снижен на 35%, а исходящий на 50%. Способность можно активировать и деактивировать, нажав кнопку 'U'.",
		lvlReq = 12,
		perkReq = {"kb_perk_heavyarmor"},
		hideInMenu = true,
	})
	perks.heavyarmorDefenceTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorDefenceTwo",
		name = "Глухая оборона II",
		description = "Теперь в Глухой обороне входящий урон снижен на 50%, а исходящий снижен всего на 35%.",
		lvlReq = 14,
		perkReq = {"kb_perk_heavyarmorDefence"},
		hideInMenu = true,
	})
	perks.heavyarmorResonance = perkFramework.createPerk({
		id = "kb_perk_heavyarmorResonance",
		name = "Стальной резонанс",
		description = "Когда враг нанес по вам 5 ударов в Глухой обороне, его отбросит и он получит урон в размере 10% от своего базового ХП.",
		lvlReq = 14,
		perkReq = {"kb_perk_heavyarmorDefence"},
		hideInMenu = true,
	})
	perks.heavyarmorResonanceTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorResonanceTwo",
		name = "Стальной резонанс II",
		description = "Теперь для срабатывания резонанса требуется 3 удара.",
		lvlReq = 16,
		perkReq = {"kb_perk_heavyarmorResonance"},
		hideInMenu = true,
	})
	perks.lightarmorMoving = perkFramework.createPerk({
		id = "kb_perk_lightarmorMoving",
		name = "Проворство",
		description = "В движении и в полном комплекте доспехов(кроме щита) физический урон по вам снижен на 20%.",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.lightarmorMovingTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorMovingTwo",
		name = "Проворство II",
		description = "Теперь в движении физический урон по вам снижен на 25%.",
		perkReq = {"kb_perk_lightarmorMoving"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorStamine = perkFramework.createPerk({
		id = "kb_perk_lightarmorStamine",
		name = "Неутомимость",
		description = "В бою вы не тратите усталость на маневрирование.",
		perkReq = {"kb_perk_lightarmorMoving"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorStamineTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorStamineTwo",
		name = "Неутомимость II",
		description = "Теперь ваша усталость в бою во время движения даже немного восстанавливается.",
		perkReq = {"kb_perk_lightarmorStamine"},
		lvlReq = 16,
		hideInMenu = true,
	})
	perks.heavyarmorshield = perkFramework.createPerk({
		id = "kb_perk_heavyarmorshield",
		name = "Магический щит",
		description = "Будучи в бою и в полном комплекте тяжелых доспехов(кроме щита) вы получаете магический эффект 'Щит' 10 пунктов.",
		perkReq = {"kb_perk_heavyarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMA.activated or perks.magicschoolCA.activated or perks.magicschoolRA.activated or perks.magicschoolDA.activated end,
		hideInMenu = true,
	})
	perks.heavyarmorshieldTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorshieldTwo",
		name = "Магический щит II",
		description = "Теперь сила эффекта 'Щит' равна 15 пунктам.",
		perkReq = {"kb_perk_heavyarmorshield"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.heavyarmornighteye = perkFramework.createPerk({
		id = "kb_perk_heavyarmornighteye",
		name = "Кошачий глаз",
		description = "За полный комплект тяжелых доспехов(кроме щита) вы получаете активируемый магический эффект 'Кошачий глаз' 10 пунктов. Способность можно активировать и деактивировать, нажав кнопку 'Y'",
		perkReq = {"kb_perk_heavyarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.heavyarmornighteyeTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmornighteyeTwo",
		name = "Кошачий глаз II",
		description = "Теперь сила эффекта 'Кошачий глаз' равна 20 пунктам.",
		perkReq = {"kb_perk_heavyarmornighteye"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.heavyarmorreflect = perkFramework.createPerk({
		id = "kb_perk_heavyarmorreflect",
		name = "Отражение",
		description = "Будучи в бою и в полном комплекте тяжелых доспехов(кроме щита) вы получаете магический эффект 'Отражение' 10 пунктов.",
		perkReq = {"kb_perk_heavyarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.heavyarmorreflectTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorreflectTwo",
		name = "Отражение II",
		description = "Теперь сила эффекта 'Отражение' равна 15 пунктам.",
		perkReq = {"kb_perk_heavyarmorreflect"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.heavyarmorresist = perkFramework.createPerk({
		id = "kb_perk_heavyarmorresist",
		name = "Сопротивление магии",
		description = "Будучи в бою и в полном комплекте тяжелых доспехов(кроме щита) вы получаете магический эффект 'Сопротивление магии' 10 пунктов.",
		perkReq = {"kb_perk_heavyarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolRI.activated or perks.magicschoolRA.activated or perks.magicschoolRM.activated or perks.magicschoolRC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.heavyarmorresistTwo = perkFramework.createPerk({
		id = "kb_perk_heavyarmorresistTwo",
		name = "Сопротивление магии II",
		description = "Теперь сила эффекта 'Сопротивление магии' равна 15 пунктам.",
		perkReq = {"kb_perk_heavyarmorresist"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorsanctuary = perkFramework.createPerk({
		id = "kb_perk_lightarmorsanctuary",
		name = "Светоч",
		description = "Будучи в бою и в полном комплекте легких доспехов(кроме щита) вы получаете магический эффект 'Светоч' 10 пунктов.",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.lightarmorsanctuaryTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorsanctuaryTwo",
		name = "Светоч II",
		description = "Теперь сила эффекта 'Светоч' равна 15 пунктам.",
		perkReq = {"kb_perk_lightarmorsanctuary"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorfrostresist = perkFramework.createPerk({
		id = "kb_perk_lightarmorfrostresist",
		name = "Сопротивление холоду",
		description = "Будучи в бою и в полном комплекте легких доспехов(кроме щита) вы получаете магический эффект 'Сопротивление холоду' 10 пунктов.",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolRI.activated or perks.magicschoolRA.activated or perks.magicschoolRM.activated or perks.magicschoolRC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.lightarmorfrostresistTwo = perkFramework.createPerk({
		id = "kb_lightarmorfrostresistTwo",
		name = "Сопротивление холоду II",
		description = "Теперь сила эффекта 'Сопротивление холоду' равна 15 пунктам.",
		perkReq = {"kb_perk_lightarmorfrostresist"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorfrog = perkFramework.createPerk({
		id = "kb_perk_lightarmorfrog",
		name = "Жаба",
		description = "За полный комплект легких доспехов(кроме щита) вы получаете активируемый магический эффект 'Прыжок' 10 пунктов. Способность можно активировать и деактивировать, нажав кнопку 'Y'",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMA.activated or perks.magicschoolCA.activated or perks.magicschoolRA.activated or perks.magicschoolDA.activated end,
		hideInMenu = true,
	})
	perks.lightarmorfrogTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorfrogTwo",
		name = "Жаба II",
		description = "Теперь сила эффекта 'Жаба' равна 20 пунктам.",
		perkReq = {"kb_perk_lightarmorfrog"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.lightarmorkey = perkFramework.createPerk({
		id = "kb_perk_lightarmorkey",
		name = "Ключник",
		description = "За полный комплект легких доспехов(кроме щита) вы получаете активируемый магический эффект 'Найти ключ' 25 пунктов. Способность можно активировать и деактивировать, нажав кнопку 'U'",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.lightarmorkeyTwo = perkFramework.createPerk({
		id = "kb_perk_lightarmorkeyTwo",
		name = "Ключник II",
		description = "Теперь сила эффекта 'Найти ключ' равна 50 пунктам.",
		perkReq = {"kb_perk_lightarmorkey"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.mediumarmorfeather = perkFramework.createPerk({
		id = "kb_perk_mediumarmorfeather",
		name = "Перышко",
		description = "За полный комплект средних доспехов(кроме щита) вы получаете магический эффект 'Перышко' 25 пунктов.",
		perkReq = {"kb_perk_mediumarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMA.activated or perks.magicschoolCA.activated or perks.magicschoolRA.activated or perks.magicschoolDA.activated end,
		hideInMenu = true,
	})
	perks.mediumarmorfeatherTwo = perkFramework.createPerk({
		id = "kb_perk_mediumarmorfeatherTwo",
		name = "Перышко II",
		description = "Теперь сила эффекта 'Перышко' равна 50 пунктам.",
		perkReq = {"kb_perk_mediumarmorfeather"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.mediumarmorlight = perkFramework.createPerk({
		id = "kb_perk_mediumarmorlight",
		name = "Свет",
		description = "За полный комплект средних доспехов(кроме щита) вы получаете активируемый магический эффект 'Свет' 10 пунктов. Способность можно активировать и деактивировать, нажав кнопку 'Y'",
		perkReq = {"kb_perk_mediumarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.mediumarmorlightTwo = perkFramework.createPerk({
		id = "kb_perk_mediumarmorlightTwo",
		name = "Свет II",
		description = "Теперь сила эффекта 'Свет' равна 20 пунктов.",
		perkReq = {"kb_perk_mediumarmorlight"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.madetectenchant = perkFramework.createPerk({
		id = "kb_perk_madetectenchant",
		name = "Магическое зрение",
		description = "За полный комплект средних доспехов(кроме щита) вы получаете активируемый магический эффект 'Обнаружить чары' 25 пунктов. Способность можно активировать и деактивировать, нажав кнопку 'U'",
		perkReq = {"kb_perk_mediumarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.madetectenchantTwo = perkFramework.createPerk({
		id = "kb_perk_madetectenchantTwo",
		name = "Магическое зрение II",
		description = "Теперь сила эффекта 'Обнаружить чары' равна 50 пунктам.",
		perkReq = {"kb_perk_madetectenchant"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.mafireresist = perkFramework.createPerk({
		id = "kb_perk_mafireresist",
		name = "Сопротивление огню",
		description = "Будучи в бою и в полном комплекте средних доспехов(кроме щита) вы получаете магический эффект 'Сопротивление огню' 10 пунктов.",
		perkReq = {"kb_perk_mediumarmor"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolRI.activated or perks.magicschoolRA.activated or perks.magicschoolRM.activated or perks.magicschoolRC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.mafireresistTwo = perkFramework.createPerk({
		id = "kb_perk_mafireresistTwo",
		name = "Сопротивление огню II",
		description = "Теперь сила эффекта 'Сопротивление огню' равна 15 пунктам.",
		perkReq = {"kb_perk_mafireresist"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.axenonweapon = perkFramework.createPerk({
		id = "kb_perk_axenonweapon",
		name = "Разоружение",
		description = "Ваши удары с вероятностью 5% могут выбить оружие из рук противника.",
		perkReq = {"kb_perk_axe"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.axenonweaponTwo = perkFramework.createPerk({
		id = "kb_perk_axenonweaponTwo",
		name = "Разоружение II",
		description = "Теперь ваш шанс выбить оружие из рук противника равен 10%.",
		perkReq = {"kb_perk_axenonweapon"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.axenonarmor = perkFramework.createPerk({
		id = "kb_perk_axenonarmor",
		name = "Бронебой",
		description = "Удар топора с вероятностью 20% проигнорирует броню противника.",
		perkReq = {"kb_perk_axe"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.axenonarmorTwo = perkFramework.createPerk({
		id = "kb_perk_axenonarmorTwo",
		name = "Бронебой II",
		description = "Теперь удары проигнорирует броню противника с вероятностью 30%.",
		perkReq = {"kb_perk_axenonarmor"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.antronah = perkFramework.createPerk({
		id = "kb_perk_antronah",
		name = "Призыв Атронаха",
		description = "Удар топора с вероятностью 10% призовет вам в помощь Атронаха на 10 секунд.",
		lvlReq = 12,
		customReq = function() return (perks.longblade.activated or perks.axe.activated or perks.bluntweapon.activated) and (perks.magicschoolCI.activated or perks.magicschoolCA.activated or perks.magicschoolCM.activated or perks.magicschoolRC.activated or perks.magicschoolDC.activated) end,
		hideInMenu = true,
	})
	perks.antronahTwo = perkFramework.createPerk({
		id = "kb_perk_antronahTwo",
		name = "Призыв Атронаха II",
		description = "Теперь удары призовут атронаха с вероятностью 15%.",
		perkReq = {"kb_perk_antronah"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.burden = perkFramework.createPerk({
		id = "kb_perk_burden",
		name = "Обуза",
		description = "Удар топора с вероятностью 10% наложит на противника обузу на 10 сек, что полностью остановит его.",
		lvlReq = 12,
		customReq = function() return (perks.longblade.activated or perks.axe.activated or perks.bluntweapon.activated) and (perks.magicschoolAI.activated or perks.magicschoolMA.activated or perks.magicschoolCA.activated or perks.magicschoolRA.activated or perks.magicschoolDA.activated) end,
		hideInMenu = true,
	})
	perks.burdenTwo = perkFramework.createPerk({
		id = "kb_perk_burdenTwo",
		name = "Обуза II",
		description = "Теперь удары наложат эффект 'Обуза' с вероятностью 15%.",
		perkReq = {"kb_perk_burden"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.axeshock = perkFramework.createPerk({
		id = "kb_perk_axeshock",
		name = "Уязвимость к электричеству",
		description = "Удар топора с вероятностью 10% наложит на противника уязвимость к электричеству 10% на 10 сек.",
		perkReq = {"kb_perk_axe"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolDA.activated or perks.magicschoolDM.activated or perks.magicschoolDI.activated or perks.magicschoolDC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.axeshockTwo = perkFramework.createPerk({
		id = "kb_perk_axeshockTwo",
		name = "Уязвимость к электричеству II",
		description = "Теперь шанс наложить на противника уязвимость к электричеству равен 15%.",
		perkReq = {"kb_perk_axeshock"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.axeabsorbhp = perkFramework.createPerk({
		id = "kb_perk_axeabsorbhp",
		name = "Поглощение здоровья",
		description = "Удар топора с вероятностью 10% отнимет 15 единиц здоровья врага и передаст их вам.",
		perkReq = {"kb_perk_axe"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.axeabsorbhpTwo = perkFramework.createPerk({
		id = "kb_perk_axeabsorbhpTwo",
		name = "Поглощение здоровья II",
		description = "Теперь вероятность поглощения здоровья врага равна 15%.",
		perkReq = {"kb_perk_axeabsorbhp"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.axeblind = perkFramework.createPerk({
		id = "kb_perk_axeblind",
		name = "Ослепление",
		description = "Удар топора с вероятностью 10% вызовет у врага слепоту на 60 секунд, снижающую вероятность попадания по вам на 50%.",
		perkReq = {"kb_perk_axe"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.axeblindTwo = perkFramework.createPerk({
		id = "kb_perk_axeblindTwo",
		name = "Ослепление II",
		description = "Теперь ваши удары наложат эффект 'Ослепление' с вероятностью 15%.",
		perkReq = {"kb_perk_axeblind"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntfatigue = perkFramework.createPerk({
		id = "kb_perk_bluntfatigue",
		name = "Изнеможение",
		description = "Удары молота также отнимают у противника усталость в 2-х кратном размере от базового урона.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.bluntfatigueTwo = perkFramework.createPerk({
		id = "kb_perk_bluntfatigueTwo",
		name = "Изнеможение II",
		description = "Теперь удары отнимают у противника усталость в 3-х кратном размере от базового урона.",
		perkReq = {"kb_perk_bluntfatigue"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntshieldbroke = perkFramework.createPerk({
		id = "kb_perk_bluntshieldbroke",
		name = "Щитолом",
		description = "Удары молота с вероятностью 10% могут сломать щит противника.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.bluntshieldbrokeTwo = perkFramework.createPerk({
		id = "kb_perk_bluntshieldbrokeTwo",
		name = "Щитолом II",
		description = "Теперь вы можете сломать щит с вероятностью 15%.",
		perkReq = {"kb_perk_bluntshieldbroke"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntcrush = perkFramework.createPerk({
		id = "kb_perk_bluntcrush",
		name = "Оглушающий удар",
		description = "Удары молота с вероятностью 10% могут оглушить врага на 5 сек.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.bluntcrushTwo = perkFramework.createPerk({
		id = "kb_perk_bluntcrushTwo",
		name = "Оглушающий удар II",
		description = "Теперь вероятность оглушить врага равна 15%.",
		perkReq = {"kb_perk_bluntcrush"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntsound = perkFramework.createPerk({
		id = "kb_perk_bluntsound",
		name = "Звук",
		description = "Удары молота с вероятностью 10% могут наложить на противника эффект 'Звук', снижающий вероятность успешного произнесения заклинания противником на 50% в течении 60 секунд.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.bluntsoundTwo = perkFramework.createPerk({
		id = "kb_perk_bluntsoundTwo",
		name = "Звук II",
		description = "Теперь вероятность наложить на противника эффект 'Звук' равна 15%.",
		perkReq = {"kb_perk_bluntsound"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntabsorbfatigue = perkFramework.createPerk({
		id = "kb_perk_bluntabsorbfatigue",
		name = "Поглощение усталости",
		description = "Удары молота с вероятностью 10% поглотят 10% усталости врага.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.bluntabsorbfatigueTwo = perkFramework.createPerk({
		id = "kb_perk_bluntabsorbfatigueTwo",
		name = "Поглощение усталости II",
		description = "Теперь вероятность поглощения усталости врага равна 15%.",
		perkReq = {"kb_perk_bluntabsorbfatigue"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.bluntdisintegratear = perkFramework.createPerk({
		id = "kb_perk_bluntdisintegratear",
		name = "Уничтожение доспехов",
		description = "Удары молота с вероятностью 20% накладывают на доспехи противника эффект 'Уничтожение доспехов' 50 пунктов, постепенно доводя их состояние до нуля.",
		perkReq = {"kb_perk_bluntweapon"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolDA.activated or perks.magicschoolDM.activated or perks.magicschoolDI.activated or perks.magicschoolDC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.bluntdisintegratearTwo = perkFramework.createPerk({
		id = "kb_perk_bluntdisintegratearTwo",
		name = "Уничтожение доспехов II",
		description = "Теперь вероятность уничтожения доспехов равна 30%.",
		perkReq = {"kb_perk_bluntdisintegratear"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.longbladebleed = perkFramework.createPerk({
		id = "kb_perk_longbladebleed",
		name = "Кровопускание",
		description = "Ваши удары с вероятностью 15% вызывают у противника кровотечение, отнимающее 10% здоровья в течении 15 секунд.",
		perkReq = {"kb_perk_longblade"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.longbladebleedTwo = perkFramework.createPerk({
		id = "kb_perk_longbladebleedTwo",
		name = "Кровопускание II",
		description = "Теперь вероятность вызвать у противника кровотечение равна 25%.",
		perkReq = {"kb_perk_longbladebleed"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.execute = perkFramework.createPerk({
		id = "kb_perk_execute",
		name = "Казнь",
		description = "Когда у противника остается 30% здоровья, следующий удар с вероятностью 10% добьет его.",
		customReq = function() return perks.longblade.activated or perks.axe.activated end,
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.executeTwo = perkFramework.createPerk({
		id = "kb_perk_executeTwo",
		name = "Казнь II",
		description = "Теперь вероятность добить ослабленного противника равна 15%.",
		perkReq = {"kb_perk_execute"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.longbladeslowly = perkFramework.createPerk({
		id = "kb_perk_longbladeslowly",
		name = "Подрезание сухожилий",
		description = "Урон от длинных клинков с вероятностью 15% подрезает сухожилия противника, замедляя его на 10 секунд.",
		perkReq = {"kb_perk_longblade"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.longbladeslowlyTwo = perkFramework.createPerk({
		id = "kb_perk_longbladeslowlyTwo",
		name = "Подрезание сухожилий II",
		description = "Теперь ваши удары замедляют противника с вероятностью 25%.",
		perkReq = {"kb_perk_longbladeslowly"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.longbladesilence = perkFramework.createPerk({
		id = "kb_perk_longbladesilence",
		name = "Безмолвие",
		description = "Урон длинными клинками с вероятностью 10% наложит на противника Немоту на 30 сек, что не позволит ему использовать заклинания.",
		perkReq = {"kb_perk_longblade"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolAI.activated or perks.magicschoolMI.activated or perks.magicschoolCI.activated or perks.magicschoolRI.activated or perks.magicschoolDI.activated end,
		hideInMenu = true,
	})
	perks.longbladesilenceTwo = perkFramework.createPerk({
		id = "kb_perk_longbladesilenceTwo",
		name = "Безмолвие II",
		description = "Теперь шанс наложить на противника Немоту равен 15%.",
		perkReq = {"kb_perk_longbladesilence"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.longbladesoultrap = perkFramework.createPerk({
		id = "kb_perk_longbladesoultrap",
		name = "Хозяин Душ",
		description = "Урон зачарованным оружием с вероятностью 20% восстановит 20% его заряда.",
		perkReq = {"kb_perk_longblade"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolMI.activated or perks.magicschoolMA.activated or perks.magicschoolCM.activated or perks.magicschoolRM.activated or perks.magicschoolDM.activated end,
		hideInMenu = true,
	})
	perks.longbladesoultrapTwo = perkFramework.createPerk({
		id = "kb_perk_longbladesoultrapTwo",
		name = "Хозяин Душ II",
		description = "Теперь шанс восстановить заряд оружия равен 30%.",
		perkReq = {"kb_perk_longbladesoultrap"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.longbladeburn = perkFramework.createPerk({
		id = "kb_perk_longbladeburn",
		name = "Уязвимость к огню",
		description = "Удар длинного клинка с вероятностью 10% наложит на противника уязвимость к огню 50% на 10 сек.",
		perkReq = {"kb_perk_longblade"},
		lvlReq = 12,
		customReq = function() return perks.magicschoolDA.activated or perks.magicschoolDM.activated or perks.magicschoolDI.activated or perks.magicschoolDC.activated or perks.magicschoolDR.activated end,
		hideInMenu = true,
	})
	perks.longbladeburnTwo = perkFramework.createPerk({
		id = "kb_perk_longbladeburnTwo",
		name = "Уязвимость к огню II",
		description = "Теперь шанс наложить на противника уязвимость к огню равен 15%.",
		perkReq = {"kb_perk_longbladeburn"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.magicschooltwo = perkFramework.createPerk({
		id = "kb_perk_magicschooltwo",
		name = "Ученик магии",
		description = "Теперь вы получаете 20% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_warmage"},
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.magicschoolthree = perkFramework.createPerk({
		id = "kb_perk_magicschoolthree",
		name = "Эксперт магии",
		description = "Теперь вы получаете 30% шанс не потратить магию при произнесении заклинаний.",
		perkReq = {"kb_perk_magicschooltwo"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.repairer = perkFramework.createPerk({
		id = "kb_perk_repairer",
		name = "Кузнец Зенитара",
		description = "Полная починка оружия и доспехов на время улучшает их характеристики:\nОружие - увеличен урон на 10% в течении 60 минут.\nДоспехи - увеличен рейтинг защиты на 10% в течении 60 минут.",
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.repairerTwo = perkFramework.createPerk({
		id = "kb_perk_repairerTwo",
		name = "Кузнец Зенитара II",
		description = "Теперь урон оружия и рейтинг защиты доспехов увеличивается на 20% после починки.",
		lvlReq = 14,
		perkReq = {"kb_perk_repairer"},
		hideInMenu = true,
	})
	perks.enchanter = perkFramework.createPerk({
		id = "kb_perk_enchanter",
		name = "Зачарователь Магнуса",
		description = "У вас есть 20% шанс, что магический предмет не потеряет заряд при использовании.",
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.enchanterTwo = perkFramework.createPerk({
		id = "kb_perk_enchanterTwo",
		name = "Зачарователь Магнуса II",
		description = "Теперь ваш шанс не потратить заряд предмета равен 30%.",
		lvlReq = 14,
		perkReq = {"kb_perk_enchanter"},
		hideInMenu = true,
	})
	perks.speechadmire = perkFramework.createPerk({
		id = "kb_perk_speechadmire",
		name = "Красноречие: Вежливость",
		description = "Вежливость открывает многие замки. Подняв расположение НПС выше 90 благодаря вежливости, ваша Удача увеличивается на 15 на 1 час.",
		lvlReq = 12,
		perkExclude = {"kb_perk_speechintimidate"},
		hideInMenu = true,
	})
	perks.speechadmireTwo = perkFramework.createPerk({
		id = "kb_perk_speechadmireTwo",
		name = "Красноречие: Вежливость II",
		description = "Теперь, после продуктивной беседы, ваша Удача повышается на 30.",
		lvlReq = 14,
		perkReq = {"kb_perk_speechadmire"},
		hideInMenu = true,
	})
	perks.speechintimidate = perkFramework.createPerk({
		id = "kb_perk_speechintimidate",
		name = "Красноречие: Угрозы",
		description = "Угрозы открывает многие замки. Подняв расположение НПС выше 90 благодаря угрозам, ваша Удача увеличивается на 15 на 1 час.",
		lvlReq = 12,
		perkExclude = {"kb_perk_speechadmire"},
		hideInMenu = true,
	})
	perks.speechintimidateTwo = perkFramework.createPerk({
		id = "kb_perk_speechintimidateTwo",
		name = "Красноречие: Угрозы II",
		description = "Теперь, после продуктивной беседы, ваша Удача повышается на 30.",
		lvlReq = 14,
		perkReq = {"kb_perk_speechintimidate"},
		hideInMenu = true,
	})
	perks.nonShield = perkFramework.createPerk({
		id = "kb_perk_nonShield",
		name = "Без щита",
		description = "Находясь в бою без щита у вас есть 20% шанс уклониться от атаки.",
		lvlReq = 12,
		perkExclude = {"kb_perk_withShield"},
		hideInMenu = true,
	})
	perks.withShield = perkFramework.createPerk({
		id = "kb_perk_withShield",
		name = "Бастион",
		description = "Находясь в бою со щитом у вас есть 25% шанс отбить стрелу или метательный снаряд в секторе 90 градусов перед собой.",
		lvlReq = 12,
		perkExclude = {"kb_perk_nonShield"},
		hideInMenu = true,
	})
	perks.noArrowSword = perkFramework.createPerk({
		id = "kb_perk_noArrowSword",
		name = "Танец Клинка",
		description = "Находясь в бою без щита у вас есть 25% шанс отбить стрелу или метательный снаряд в секторе 90 градусов перед собой.",
		perkReq = {"kb_perk_longblade", "kb_perk_nonShield"},
		lvlReq = 14,
		hideInMenu = true,
	})
	perks.trader = perkFramework.createPerk({
		id = "kb_perk_trader",
		name = "Торгаш",
		description = "Все торгаши обзавелись кругленькой суммой и готовы скупить ваше барахло. Количество золото у торговцев выросло в 10 раз!",
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.alchemyst = perkFramework.createPerk({
		id = "kb_perk_alchemyst",
		name = "Алхимик",
		description = "С вероятностью 20% вы сварите не одно, а два зелья, вес которых будет в два раза ниже и соответственно цена в два раза выше!",
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.alchemystTwo = perkFramework.createPerk({
		id = "kb_perk_alchemystTwo",
		name = "Алхимик II",
		description = "С вероятностью 30% вы сварите не одно, а два зелья, вес которых будет в четыре раза ниже и соответственно цена в четыре раза выше!",
		lvlReq = 14,
		perkReq = {"kb_perk_alchemyst"},
		hideInMenu = true,
	})
	perks.spreenter = perkFramework.createPerk({
		id = "kb_perk_spreenter",
		name = "Спринтер",
		description = "Раз в 30 секунд вы можете значительно увеличить свою скорость передвижения на 10 секунд.Способность можно активировать, нажав на кнопку 'Q'.",
		lvlReq = 12,
		hideInMenu = true,
	})
	perks.jumper = perkFramework.createPerk({
		id = "kb_perk_jumper",
		name = "Акробат",
		description = "Теперь вы способны на двойной прыжок.",
		perkReq = {"kb_perk_lightarmor"},
		lvlReq = 12,
		hideInMenu = true,
	})
end
event.register("KCP:Initialized", registerPerks)