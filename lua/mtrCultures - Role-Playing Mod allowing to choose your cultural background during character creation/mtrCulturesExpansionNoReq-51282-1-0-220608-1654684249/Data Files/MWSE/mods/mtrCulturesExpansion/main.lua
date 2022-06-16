-- get the current mtrCultures data
local function getData()
    local data = tes3.player.data.mtrCultures or {}
    return data
end

-- start the mod
local function onInit(e)
	local interop = require("mtrCultures.interop")

--CANTEMIRIC
local cantemiricDoOnce
local cantemiric = {
    id = "cantemiric",
    name = "Cantemiric",
    description = (
        "Cantemiric Velothi are a group of Chimer and later Dunmer thought to be extinct due to epidemic of Knahaten Flu. They lived on the eastern coast of Argonia and possibly were worshippers of Aedric Divines, however such description is dubious as rejection of Aedric reverence was behind emergence of Chimer as a separate race.\n\nAdherence to Cantemiric customs grants bonuses to Poison Resistance, Maximum Magicka (50%) and penalties of Weakness to Fire, Weakness to Common Disease (100%) to those being faithful to their culture." --added extinct culture for more variety
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Cantemiric"
        }
    end,
}
interop.addCulture(cantemiric)

--ASHABAH
local ashabahDoOnce
local ashabah = {
    id = "ashabah",
    name = "Ash'abah",
    description = (
        "Ash'abah are secretive Redguard tribe who disregard religious taboo for the purpose of fighting necromancy. \n\nAdherence to Ash'abah customs grants bonuses to Restoration (+5), Maximum Magicka (50%) and penalties to Conjuration, Personality (-5) to those being faithful to their culture." --boring token fighting necromancy eso stuff...
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Ashabah"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
    end,
}
interop.addCulture(ashabah)

--CORELANYAI
local corelanyaiDoOnce
local corelanyai = {
    id = "corelanyai",
    name = "Corelanyai",
    description = (
        "Corelanya are a clan of Altmer Daedra worshippers thought to be extinct. They colonized western part of what is now called Hammerfell, but were ultimately defeated by Redguards.\n\nAdherence to Corelanyai customs grants bonuses to Mercantile, Conjuration (+5), Resist Fire (50%) and penalties to Endurance (-5), Weakness to Frost (-50%) to those being faithful to their culture." --added extinct eso culture for more variety
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Corelanyai"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
    end,
}
interop.addCulture(corelanyai)

--OSH ORNIM
local oshornimDoOnce
local oshornim = {
    id = "oshornim",
    name = "Osh Ornim",
    description = (
        "Osh Ornim - \"Iron Orcs\" - are Orsimer living in the Dragontail mountains of Hammerfell. It's a society of miners, smiths, and brutal warriors. \n\nAdherence to Osh Ornim customs grants bonuses to Armorer, Axe, Heavy Armor, Hand-to-hand, Blunt Weapon, Enchant, Strength, Endurance (+5) and penalties to Sneak, Speechcraft, Illusion, Mercantile, Block, Security, Intelligence, Personality (-5) to those being faithful to their culture." --eso Orcs
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Oshornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
    end,
}
interop.addCulture(oshornim)

--KUSHRAG ORNIM
local kushragornimDoOnce
local kushragornim = {
    id = "kushragornim",
    name = "Kushrag Ornim",
    description = (
        "Kushrag Ornim - \"Sea Orcs\" - are Orsimer said to be living on various islands on the western coast of Tamriel. One of the biggest fears of Eltheric Ocean seafarers is meeting a Sea Orc vessel. Some people believe that Kushrag Ornim are descendandts of Lefthanded Elves of Yokuda.\n\nAdherence to Kushrag Ornim customs grants bonuses to Light Armor, Long Blade, Conjuration, Agility, Endurance (+5), Resist Shock (25%), and penalties to Heavy Armor, Armorer, Block, Intelligence, Personality (-5), Weakness to Frost (-25%) to those being faithful to their culture." -- original, there is however a Seamount Clan in ESO, and I believe suggestions about making Sea Orcs were made somewhere in PT, name from /u/orsimeris Orcish language, kush=tooth, memrag=water
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Kushragornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
    end,
}
interop.addCulture(kushragornim)

--NELGRAG ORNIM
local nelgragornimDoOnce
local nelgragornim = {
    id = "nelgragornim",
    name = "Nelgrag Ornim",
    description = (
        "Nelgrag Ornim - \"Swamp Orcs\" - are Orsimer said to be living in parts of Black Marsh. These elusive people are rarely seen and often mistook for a rare subrace of Argonians.\n\nAdherence to Nelgrag Ornim customs grants bonuses to Alchemy, Illusion, Unarmored, Spear (+5), Maximum Magicka (50%), Resist Poison, Resist Common Disease (25%), and penalties to Heavy Armor, Armorer, Block, Medium Armor, Personality (-5), Weakness to Frost (-50%) to those being faithful to their culture." -- completely made up :), name from /u/orsimeris Orcish language, nedulg=stand, nedulg=sit, memrag=water
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Nelgragornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
    end,
}
interop.addCulture(nelgragornim)

--UGRASH ORNIM
local ugrashornimDoOnce
local ugrashornim = {
    id = "ugrashornim",
    name = "Ugrash Ornim",
    description = (
        "Ugrash Ornim - \"Snow Orcs\" - are Orsimer living in desolate parts of Skyrim. They are isoliationistic, but peaceful people. \n\nAdherence to Ugrash Ornim customs grants bonuses to Light Armor, Axe, Blunt Weapon, Destruction (+5), Resist Frost (25%) and penalties to Heavy Armor, Armorer, Block, Speechcraft (-5), Weakness to Fire (-25%) to those being faithful to their culture." -- original though there are Orcs in Skyrim in TES V, name from /u/orsimeris Orcish language, ugol=white, rashso=sand, rash=earth, there is also a word for cold=nefolk, but it's simply a negation of hot=folk, so the name would become a mouthful
		),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Ugrashornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
    end,
}
interop.addCulture(ugrashornim)

--GENERIC COSMOPOLITAN
local cosmopolitanDoOnce
local cosmopolitan = {
    id = "cosmopolitan",
    name = "-Cosmopolitan-",
    description = (
        "Cosmopolitan is a generic culture whose followers see whole of Nirn as a single community. \n\nAdherence to Cosmopolitan customs grants bonuses to Sneak, Mercantile, Speechcraft, Security, Unarmored, Mysticism, Personality, Speed (+5) and penalties to Heavy Armor, Spear, Armorer, Axe, Alchemy, Enchant, Strength, Willpower (-5) to those being faithful to their culture."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Cosmopolitan"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
    end,
}
interop.addCulture(cosmopolitan)

--GENERIC MAGOCRATIC
local magocraticDoOnce
local magocratic = {
    id = "magocratic",
    name = "-Magocratic-",
    description = (
        "Magocratic is a generic culture whose followers see pursuing knowledge as a necessary part of life. \n\nAdherence to Magocratic customs grants bonuses to Illusion, Alchemy, Enchant, Alteration, Destruction, Restoration, Intelligence (+5), Maximum Magicka (50%) and penalties to Heavy Armor, Medium Armor, Spear, Axe, Athletics, Marksman, Strength, Endurance (-5) to those being faithful to their culture."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Magocratic"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
    end,
}
interop.addCulture(magocratic)

--GENERIC MARTIAL
local martialDoOnce
local martial = {
    id = "martial",
    name = "-Martial-",
    description = (
        "Martial is a generic culture whose followers see warfare as a necessary part of life and way to achieve honor, glory, and valor. \n\nAdherence to Martial customs grants bonuses to Heavy Armor, Medium Armor, Spear, Axe, Blunt Weapon, Long Blade, Strength, Endurance (+5) and penalties to Mysticism, Alteration, Enchant, Alchemy, Illusion, Restoration, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Martial"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}
interop.addCulture(martial)

end

event.register("initialized", onInit)

]]