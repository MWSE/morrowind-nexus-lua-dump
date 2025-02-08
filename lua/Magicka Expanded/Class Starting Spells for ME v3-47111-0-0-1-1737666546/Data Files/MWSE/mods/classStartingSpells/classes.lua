local spells = require("classStartingSpells.spells")
local config = require("classStartingSpells.config")
local class = {}

local classTable = {
 
	Acrobat = {
		attributes = {tes3.attribute.agility, tes3.attribute.endurance},
		magic = {
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Illusion = {spells.id.sanctuary, spells.id.darkness, spells.id.chameleon},
			Restoration = {spells.id.restoreFatigue, spells.id.dummyFortifyAgility, spells.id.fortifyHealth},
			Conjuration =  {spells.id.boundBow, spells.id.boundSpear, spells.id.commandCreature},
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.damageFatigue, spells.id.poisonTarget, spells.id.damageHealth},
		}
	},
	
	Agent = {
		attributes = {tes3.attribute.personality, tes3.attribute.agility},
		magic = {
			Illusion = {spells.id.charm, spells.id.chameleon, spells.id.sanctuary,},
			Conjuration =  {spells.id.boundDagger, spells.id.commandHumanoid, spells.id.commandCreature},
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Restoration = {spells.id.dummyFortifyPersonality, spells.id.dummyFortifyAgility, spells.id.restoreFatigue},
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.poison, spells.id.poisonTarget, spells.id.disintegrateWeapon},
		}
	},
	
	Archer = {
		attributes = {tes3.attribute.agility, tes3.attribute.strength},
		magic = {
			Restoration = {spells.id.dummyFortifyAgility, spells.id.dummyFortifyStrength, spells.id.restoreFatigue},
			Alteration = {spells.id.feather, spells.id.swiftSwim, spells.id.jump},
			Illusion = {spells.id.sanctuary, spells.id.nightEye, spells.id.darkness},
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.poison, spells.id.poisonTarget, spells.id.disintegrateWeapon},
			Conjuration =  {spells.id.boundBow, spells.id.commandCreature, spells.id.boundSword},
		}
	},
	
	Assassin = {
		attributes = {tes3.attribute.speed, tes3.attribute.intelligence},
		magic = {
			Restoration = {spells.id.dummyFortifyAgility, spells.id.dummyFortifyStrength, spells.id.restoreFatigue},
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Illusion = {spells.id.sanctuary, spells.id.nightEye, spells.id.darkness},
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.weaknesstoPoison, spells.id.poison, spells.id.poisonTarget},
			Conjuration = {spells.id.boundDagger, spells.id.boundBow, spells.id.commandHumanoid},
		}
	},
	
	Barbarian = {
		attributes = {tes3.attribute.strength, tes3.attribute.speed},
		magic = {
			Restoration = {spells.id.dummyFortifyStrength, spells.id.restoreFatigue, spells.fortifyHealth},
			Alteration = {spells.id.feather, spells.id.swiftSwim, spells.id.jump},
			Illusion = {spells.id.sanctuary, spells.id.demoralizeCreature, spells.id.demoralizeHumanoid},
			Mysticism = {spells.id.detectCreature, spells.id.detectUndeadDaedra, spells.id.detectTrap},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
			Conjuration = {spells.id.boundAxe, spells.id.commandCreature, spells.id.boundBow},
		}
	},
	
	Bard = {
		attributes = {tes3.attribute.personality, tes3.attribute.intelligence},
		magic = {
			Illusion = {spells.id.rallyHumanoid, spells.id.charm, spells.id.sound},
			Destruction = {spells.id.weaknesstoMagicka, spells.id.damageFatigue, spells.id.disintegrateWeapon},
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.unlock},
			Mysticism = {spells.id.detectEnchantment, spells.id.telekinesis, spells.id.dispel},
			Restoration = {spells.id.restoreFatigue, spells.id.dummyFortifyPersonality, spells.id.dummyFortifyIntelligence},
			Conjuration = {spells.id.commandHumanoid, spells.id.commandCreature, spells.id.boundSword},
		}
	},
	
	Battlemage = {
		attributes = {tes3.attribute.intelligence, tes3.attribute.strength},
		magic = {
			Conjuration = {spells.id.turnUndead, spells.id.boundAxe, spells.id.summonScamp},
			Destruction = {spells.id.fire, spells.id.shockTarget, spells.id.disintegrateWeapon}, 
			Alteration = {spells.id.shield, spells.id.burden, spells.id.waterWalking},
			Mysticism = {spells.id.detectEnchantment, spells.id.soulTrap, spells.id.spellAbsorbtion},
			Restoration = {spells.id.dummyFortifyStrength, spells.id.restoreHealth, spells.id.dummyFortifyIntelligence},
			Illusion = {spells.id.sound, spells.id.demoralizeHumanoid, spells.id.demoralizeCreature},
		}
	},
	
	Crusader = {
		attributes = {tes3.attribute.willpower, tes3.attribute.strength},
		magic = {
			Restoration = {spells.id.restoreHealth, spells.id.resistMagicka, spells.id.dummyFortifyStrength},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
			Conjuration = {spells.id.turnUndead, spells.id.boundMace, spells.id.banishDaedra},
			Illusion = {spells.id.light, spells.id.demoralizeHumanoid, spells.id.demoralizeCreature},
			Mysticism = {spells.id.detectUndeadDaedra, spells.id.dispel, spells.id.spellAbsorbtion},
			Alteration = {spells.id.shield, spells.id.burden, spells.id.feather},
		}
	},
	
	Healer = {
		attributes = {tes3.attribute.willpower, tes3.attribute.personality},
		magic = {
			Alteration = {spells.id.shield, spells.id.burden, spells.id.feather},
			Restoration = {spells.id.restoreHealth, spells.id.resistMagicka, spells.id.cureDisease},
			Illusion = {spells.id.calmHumanoid, spells.id.sanctuary, spells.id.calmCreature}, 
			Mysticism = {spells.id.soulScrie, spells.id.detectCreature, spells.id.dispel},
			Destruction = {spells.id.damageFatigue, spells.id.disintegrateWeapon, spells.id.weaknesstoMagicka},
			Conjuration = {spells.id.turnUndead, spells.id.commandHumanoid, spells.id.banishDaedra}
		}
	},
	
	Knight = {
		attributes = {tes3.attribute.strength, tes3.attribute.personality},
		magic = {
			Restoration = {spells.id.dummyFortifyStrength,  spells.id.dummyFortifyPersonality, spells.id.restoreFatigue},
			Alteration = {spells.id.shield, spells.id.burden, spells.id.feather},
			Illusion = {spells.id.charm, spells.id.demoralizeCreature, spells.id.demoralizeHumanoid},
			Mysticism = {spells.id.detectCreature, spells.id.detectUndeadDaedra, spells.id.detectTrap},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
			Conjuration = {spells.id.boundSword, spells.id.commandHumanoid, spells.id.boundAxe},
		}
	},
	
	Mage = {
		attributes = {tes3.attribute.intelligence, tes3.attribute.willpower},
		magic = {
			Destruction = {spells.id.fire, spells.id.shockTarget, spells.id.weaknesstoMagicka},
			Illusion = {spells.id.light, spells.id.sanctuary, spells.id.sound},
			Alteration = {spells.id.shield, spells.id.waterWalking, spells.id.unlock},
			Mysticism = {spells.id.detectEnchantment, spells.id.telekinesis, spells.id.dispel},
			Restoration = {spells.id.restoreMagicka, spells.id.restoreHealth, spells.id.dummyFortifyIntelligence},
			Conjuration = {spells.id.boundDagger, spells.id.commandCreature, spells.id.summonScamp},
		}
	},
	
	Monk = {
		attributes = {tes3.attribute.agility, tes3.attribute.willpower},
		magic = {
			Restoration = {spells.id.dummyFortifyAgility, spells.id.restoreFatigue, spells.id.resistMagicka},
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Illusion = {spells.id.sanctuary, spells.id.chameleon, spells.id.calmHumanoid},
			Conjuration =  {spells.id.turnUndead, spells.id.banishDaedra, spells.id.boundBow},
			Mysticism = {spells.id.detectTrap, spells.id.detectUndeadDaedra, spells.id.blink},
			Destruction = {spells.id.damageFatigue, spells.id.disintegrateWeapon, spells.id.damageHealth},
		}
	},
	
	Nightblade = {
		attributes = {tes3.attribute.willpower, tes3.attribute.speed},
		magic = {
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.unlock},
			Illusion = {spells.id.nightEye, spells.id.darkness, spells.id.chameleon}, 
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.poison, spells.id.poisonTarget, spells.id.weaknesstoPoison},
			Conjuration =  {spells.id.boundDagger, spells.id.boundBow, spells.id.commandHumanoid},
			Restoration = {spells.id.restoreMagicka, spells.id.restoreFatigue, spells.id.resistMagicka},
		}
	},
	
	Pilgrim = {
		attributes = {tes3.attribute.personality, tes3.attribute.endurance},
		magic = {
			Illusion = {spells.id.light, spells.id.charm, spells.id.demoralizeCreature},
			Restoration = {spells.id.restoreFatigue, spells.id.dummyFortifyPersonality, spells.id.fortifyHealth},
			Conjuration =  {spells.id.commandHumanoid, spells.id.boundBow, spells.id.boundDagger},
			Mysticism = {spells.id.detectTrap, spells.id.detectCreature, spells.id.blink},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
			Alteration = {spells.id.feather, spells.id.swiftSwim, spells.id.shield},
		}
	},
	
	Rogue = {
		attributes = {tes3.attribute.speed, tes3.attribute.personality},
		magic = {
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Illusion = {spells.id.sanctuary, spells.id.charm, spells.id.darkness},
			Restoration = {spells.id.restoreFatigue, spells.id.dummyFortifyAgility, spells.id.dummyFortifyPersonality},
			Conjuration =  {spells.id.boundDagger, spells.id.commandHumanoid, spells.id.boundAxe},
			Mysticism = {spells.id.detectCreature, spells.id.detectTrap, spells.id.blink},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.poisonTarget},
		}
	},
	
	Scout = {
		attributes = {tes3.attribute.speed, tes3.attribute.endurance},
		magic = {
			Alteration = {spells.id.feather, spells.id.swiftSwim, spells.id.jump},
			Illusion = {spells.id.sanctuary, spells.id.darkness, spells.id.nightEye},
			Restoration = {spells.id.restoreFatigue, spells.id.fortifyHealth, spells.id.restoreHealth},
			Conjuration = {spells.id.boundSword, spells.id.boundBow, spells.id.boundShield},
			Mysticism = {spells.id.detectCreature, spells.id.detectTrap, spells.id.detectUndeadDaedra},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
		}
	},

	Sorcerer = {
		attributes = {tes3.attribute.intelligence, tes3.attribute.endurance},
		magic = {
			Destruction = {spells.id.fire, spells.id.shockTarget, spells.id.weaknesstoMagicka}, 
			Alteration = {spells.id.shield, spells.id.burden, spells.id.unlock},
			Mysticism = {spells.id.detectCreature, spells.id.soulTrap, spells.id.telekinesis}, 
			Conjuration = {spells.id.turnUndead, spells.id.banishDaedra, spells.id.summonScamp}, 
			Illusion = {spells.id.light, spells.id.demoralizeCreature, spells.id.demoralizeHumanoid},
			Restoration = {spells.id.restoreMagicka, spells.id.restoreHealth, spells.id.dummyFortifyIntelligence},
		}
	},
	
	Spellsword = {
		attributes = {tes3.attribute.willpower, tes3.attribute.endurance},
		magic = {
			Restoration = {spells.id.restoreMagicka, spells.id.restoreHealth, spells.id.fortifyHealth},
			Alteration = {spells.id.shield, spells.id.waterWalking, spells.id.feather},
			Destruction = {spells.id.fire, spells.id.shockTarget, spells.id.disintegrateWeapon},
			Illusion = {spells.id.sound, spells.id.demoralizeHumanoid, spells.id.demoralizeCreature},
			Mysticism = {spells.id.detectCreature, spells.id.dispel, spells.id.spellAbsorbtion},
			Conjuration = {spells.id.boundSword, spells.id.commandCreature, spells.id.boundAxe},
		}
	},
	
	Thief = {
		attributes = {tes3.attribute.speed, tes3.attribute.agility},
		magic = {
			Alteration = {spells.id.slowFall, spells.id.jump, spells.id.feather},
			Illusion = {spells.id.sanctuary, spells.id.chameleon, spells.id.charm},
			Restoration = {spells.id.restoreFatigue, spells.id.dummyFortifyAgility, spells.id.restoreHealth},
			Conjuration =  {spells.id.boundDagger, spells.id.commandHumanoid, spells.id.boundBow},
			Mysticism = {spells.id.detectTrap, spells.id.telekinesis, spells.id.blink},
			Destruction = {spells.id.poison, spells.id.weaknesstoPoison, spells.id.damageFatigue},
		}
	},
	
	Warrior = {
		attributes = {tes3.attribute.strength, tes3.attribute.endurance},
		magic = {
			Restoration = {spells.id.dummyFortifyStrength, spells.id.restoreFatigue, spells.fortifyHealth},
			Alteration = {spells.id.feather, spells.id.swiftSwim, spells.id.shield},
			Illusion = {spells.id.demoralizeCreature, spells.id.demoralizeHumanoid, spells.id.sanctuary},
			Mysticism = {spells.id.detectCreature, spells.id.detectUndeadDaedra, spells.id.detectTrap},
			Destruction = {spells.id.damageFatigue, spells.id.damageHealth, spells.id.disintegrateWeapon},
			Conjuration = {spells.id.boundSword, spells.id.boundBow, spells.id.boundAxe},
		}
	},
	
	Witchhunter = {
		attributes = {tes3.attribute.intelligence, tes3.attribute.agility},
		magic = {
			Conjuration = {spells.id.turnUndead, spells.id.banishDaedra, spells.id.boundMace},
			Mysticism = {spells.id.detectUndeadDaedra, spells.id.dispel, spells.id.spellAbsorbtion},
			Restoration = {spells.id.restoreHealth, spells.id.restoreMagicka, spells.id.dummyFortifyAgility},
			Destruction = {spells.id.fire, spells.id.shockTarget, spells.id.disintegrateWeapon},
			Illusion = {spells.id.sound, spells.id.chameleon, spells.id.sanctuary},
			Alteration = {spells.id.shield, spells.id.burden, spells.id.feather},
		}
	}
}

local customClass = {
	specialization = nil,
	attributes = {},
	majorSkills = {},
	minorSkills = {},
}

local counter = {"One", "Two", "Three", "Four", "Five"}

local nameSkill = {
	Block = 0,
	Armorer = 1,
	["Medium Armor"] = 2,
	["Heavy Armor"] = 3,
	["Blunt Weapon"] = 4,
	["Long Blade"] = 5,
	Axe = 6,
	Spear = 7,
	Athletics = 8,
	Enchant = 9,
	Destruction = 10,
	Alteration = 11,
	Illusion = 12,
	Conjuration = 13,
	Mysticism = 14,
	Restoration = 15,
	Alchemy = 16,
	Unarmored = 17,
	Security = 18,
	Sneak = 19,
	Acrobatics = 20,
	["Light Armor"] = 21,
	["Short Blade"] = 22,
	Marksman = 23,
	Mercantile = 24,
	Speechcraft = 25,
	["Hand to Hand"] = 26
}

class.getFromCreationMenu = function(menu)
	customClass.attributes[1] =  tes3.attribute[string.lower(menu:findChild(tes3ui.registerID("MenuCreateClass_AttributeOne")).text)]
	customClass.attributes[2] =  tes3.attribute[string.lower(menu:findChild(tes3ui.registerID("MenuCreateClass_AttributeTwo")).text)]
	customClass.specialization = tes3.specialization[string.lower(menu:findChild(tes3ui.registerID("MenuCreateClass_Special")).text)]
	for i = 1, 5 do
		local major = menu:findChild(tes3ui.registerID("MenuCreateClass_MajorSkill" .. counter[i])).text
		local minor = menu:findChild(tes3ui.registerID("MenuCreateClass_MinorSkill" .. counter[i])).text
		customClass.majorSkills[i] = nameSkill[major]
		customClass.minorSkills[i] = nameSkill[minor]
	end
	return customClass
end


local function getSkillValue (skill, playerClass)
	local value = 5
	
	local race = tes3.player.baseObject.race
	for _, skillBonus in pairs(race.skillBonuses) do
		if skill == tes3.skillName[skillBonus.skill] then 
			value = value + skillBonus.bonus
		end
	end
	
	if playerClass.specialization == tes3.specialization.magic then
		value = value + 5
	end
	
	for _, major in pairs(playerClass.majorSkills) do
		--mwse.log(tes3.skillName[major])
		if skill == tes3.skillName[major] then 
			return value + 25 
		end
	end
	
	for _, minor in pairs(playerClass.minorSkills) do
		if skill == tes3.skillName[minor] then 
			return value + 10 
		end
	end
	
	return false
end

class.crusaderFix = function()
	local crusader
	for _, c in pairs(tes3.dataHandler.nonDynamicData.classes) do
		if c.id == "Crusader" then
			crusader = c
			break
		end
	end
	crusader.attributes[1] = tes3.attribute.willpower
end

local function getByAttributes(playerClass)
	if playerClass.attributes[1] == tes3.attribute.luck or playerClass.attributes[2] == tes3.attribute.luck then
		if playerClass.specialization == tes3.specialization.magic then
			return "Mage"
		elseif playerClass.specialization == tes3.specialization.combat then
			return "Warrior"
		elseif playerClass.specialization == tes3.specialization.stealth then
			return "Thief"
		
		end
	end
	for name, data in pairs(classTable) do
		if data.attributes[1] == playerClass.attributes[1] and data.attributes[2] == playerClass.attributes[2] then
			--mwse.log("playerClass.attributes: %s, %s", playerClass.attributes[1], playerClass.attributes[2])
			--mwse.log("detected class: %s", name)
			return name
		elseif data.attributes[2] == playerClass.attributes[1] and data.attributes[1] == playerClass.attributes[2] then
			--mwse.log("playerClass.attributes: %s, %s", playerClass.attributes[1], playerClass.attributes[2])
			--mwse.log("detected class: %s", name)
			return name
		end
	end
end

class.addSpells = function(playerClass)
	local className = getByAttributes(playerClass)
	local magic = classTable[className] and classTable[className].magic
	if not magic then return end
	for school, spells in pairs(magic) do
		local skill = getSkillValue(school, playerClass)
		for i, spell in ipairs(spells) do
			if not skill then 
				--mwse.log("%s is not in %s", school, className)
				break 
			end
			if skill >= config.skillRequirements + 10*(i-1) then
				--mwse.log("%s %s %d >= %d",school, spell, skill, config.skillRequirements + 10*(i-1))
				spell = tes3.getObject(spell)
				if spell.flags ~= 2 and spell.flags ~= 3 and spell.flags < 6 then
					spell.flags = spell.flags + 2
				end
			end
		end
	end
end

return class