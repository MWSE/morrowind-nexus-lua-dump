local this = {}
this.none = {
    id = "none",
    name = "--None--",
    description = "No Culture Selected"
}

--AGRUN ORNIM
this.agrunornim = {
    id = "agrunornim",
    name = "Agrun Ornim",
    description = (
        "Agrun Ornim - \"Deep Orcs\" - are Orsimer living in the ancient Dwemer strongholds of Rourken clan in Hammerfell. They adopted Dwemer fashion and wear stylized beard and hairstyles of the long extinct Dwarves. More superstitious inhabitants of neighbouring areas even started believin that Dwemer never disappeared, but were instead turned into Orsimer as punishment for questioning the Divines.\n\nAdherence to Agrun Ornim customs grants bonuses to Armorer, Enchant, Long Blade, Spear, Alteration, Illusion, Intelligence (+5), Maximum Magicka (50%) and penalties to Axe, Block, Medium Armor, Conjuration, Alchemy, Mysticism, Agility, Speed (-5) to those being faithful to their culture." --name very roughly from /u/orsimeris Orcish language, from agol=brown, agen=orange, acrun=red, ugo=see, based on Citizens of the Empire by Lady Nerevar
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Agrunornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
    end,
}

--FOLRASH ORNIM
this.folrashornim = {
    id = "folrashornim",
    name = "Folrash Ornim",
    description = (
        "Folrash Ornim - \"Sand Orcs\" - is a term used to describe two separate, but ultimately very similar nomadic cultures which came to existence due to convergent evolution. Orsimer of Alik'r desert in Hammerfell and Orsimer of Ne Quin-al desert in Elsweyr, though not closely related, exhibit similar traits and culture. Not as strong as other Orcs due to adaption for living in harsh conditions of water shortage, they took up a life of trade instead that of a fight. They are also said to reject traditional Orc worship of Malacath, Mauloch, or Trinimac in favor of worshipping Aedra, specifically their interpretation of Wind Goddess Kynareth.\n\nAdherence to Folrash Ornim customs grants bonuses to Mercantile, Athletics, Unarmored, Light Armor, Restoration, Endurance, Personality (+5), Resist Fire (25%) and penalties to Axe (-5), Heavy Armor, Medium Armor, Strength (-10) to those being faithful to their culture." --name from /u/orsimeris Orcish language, rashso=sand, but I did not like the 'shso' part, so added some bits to amplify the 'hot sands, desert' part from folkur=smoke, folk=fire, folk=hot, Elsweyr Orcs are PT, Hammerfell Orcs are from /u/Fruitbird15
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Folrashornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -10
        })
    end,
}

--FOLSH ORNIM
this.folshornim = {
    id = "folshornim",
    name = "Folsh Ornim",
    description = (
        "Folsh Ornim - \"Ash Orcs\" - are barbarian, Malacath worshipping Orsimer living on the island of Vvardenfell often occupying ruined Daedric Shrines and ancient Dunmer strongholds.\n\nAdherence to Folsh Ornim customs grants bonuses to Unarmored, Light Armor, Blunt Weapon, Endurance, Speed (+5), Resist Fire (25%), Resist Blight Disease (25%) and penalties to Enchant, Destruction, Conjuration, Intelligence, Willpower (-5), Weakness to Magicka (50%) to those being faithful to their culture." --name from /u/orsimeris Orcish language, folsh=ash
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Folshornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
    end,
}

--MALAHK ORNIM
this.malahkornim = {
    id = "malahkornim",
    name = "Malahk Ornim",
    description = (
        "Malahk Ornim are Orsimer living in valley deep between Velothi mountains in western Morrowind and Nibenay in eastern Cyrodiil. Bigger than any other subrace of Orcs, they are merciless raiders and barbarians worshipping Mauloch.\n\nAdherence to Malahk Ornim customs grants bonuses to Hand-to-hand, Axe, Blunt Weapon, Unarmored, Medium Armor, Athletics, Strength, Speed (+5) and penalties to Armorer, Block, Heavy Armor, Short Blade, Enchant, Security, Intelligence, Agility (-5) to those being faithful to their culture." --TR Orcs
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
		tes3.player.scale = tes3.player.scale * 1.1
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Malahkornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
    end,
}

--SAGRA ORNIM
this.sagraornim = {
    id = "sagraornim",
    name = "Sagra Ornim",
    description = (
        "Sagra Ornim - \"Wood Orcs\" - are Orsimer living in forests of Valenwood. Smaller than other Orcs, they are expert tree-climbers and trackers. Since they tend to worship Mauloch and don't adhere to the Green Pact they established a strong trading contacts with local Bosmer supplying them with items made of materials which gathering is forbidden for the followers of Y'ffre.\n\nAdherence to Sagra Ornim customs grants bonuses to Short Blade, Acrobatics, Light Armor, Alchemy, Mercantile, Sneak, Speed, Agility (+5) and penalties to Block, Heavy Armor, Medium Armor (-10), Strength, Endurance (-5) to those being faithful to their culture." --name from /u/orsimeris Orcish language, si=die, agra=tree
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
		tes3.player.scale = tes3.player.scale * 0.92
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Sagraornim"
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
            skill = tes3.skill.block, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -10
        })
    end,
}

--KRAZ ORNIM
this.krazornim = {
    id = "krazornim",
    name = "Kraz Ornim",
    description = (
        "Kraz Ornim - \"Mountain Orcs\" - are Orsimer living in the mountain ranges of High Rock. They inhabit the most recognized of Orcish entities - Orsinium - and have recently rejected Malacath worship in favor of renewing of Trinimac worship.\n\nAdherence to Kraz Ornim customs grants bonuses to Armorer, Axe, Block, Speechcraft, Medium Armor, Athletics, Willpower, Personality (+5) and penalties to Sneak, Short Blade, Illusion, Conjuration, Enchant, Security, Intelligence, Agility (-5) to those being faithful to their culture." --name from /u/orsimeris Orcish language, kraz=mountain
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Krazornim"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
    end,
}

--RIELLEIE
this.rielleie = {
    id = "rielleie",
    name = "Rielleie",
    description = (
        "Riellei - \"The Beautiful\" - are a movement aiming to shake up Altmer society. They believe that Summerset Islands need let go of its past in order to move forward. Rielleie methods are radical, they seek to destroy monuments and murder members of aristocracy.\n\nAdherence to Rielleie customs grants bonuses to Sneak, Short Blade, Blunt Weapon, Marksman, Athletics, Hand-to-hand, Strength, Speed (+5) and penalties to Alchemy, Alteration, Conjuration, Restoration, Enchant, Illusion, Willpower, Personality (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "High Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Rielleie"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
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
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}

--DIRENNIS
this.dirennis = {
    id = "dirennis",
    name = "Dirennis",
    description = (
        "Clan Direnni is an Altmer clan who colonized northwestern Tamriel. In the past their economic and military power was formidable enough that they controlled a quarter of Tamriel. Direnni are not subscribing to racial purity tenets of the Alcharyai.\n\nAdherence to Dirennis customs grants bonuses to Alchemy, Conjuration, Mercantile, Enchant, Mysticism, Security, Personality, Intelligence (+5) and penalties to Destruction, Illusion, Restoration, Sneak, Axe, Long Blade, Agility, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isDirenniRace = ( race == "High Elf" or race == "Breton" )
        return not isDirenniRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Dirennis"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
    end,
}

--MELDISE
this.meldise = {
    id = "meldise",
    name = "Meldise",
    description = (
        "Meldis - \"exiled\" - are Altmer who were banished from Summerset Islands for breaking the rules of the so-called \"ideal society\". Alcharyai regard exile as equivalent of death sentence.\n\nAdherence to Meldise customs grants bonuses to Sneak, Security, Alteration, Restoration, Mysticism, Conjuration, Intelligence, Agility (+5) and penalties to Destruction, Enchant, Illusion, Speechcraft, Mercantile, Armorer, Willpower, Speed (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "High Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Meldise"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
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
    end,
}

--ALCHARYAE
this.alcharyae = {
    id = "alcharyae",
    name = "Alcharyae",
    description = (
        "Alcharyai - \"Highest Elves\" - are those Altmer who adhere to ancient customs. Over hundreds of generations they have bred themselves into a racially pure line, and are now almost identical to one another in appearance. They despise other Elves as unsophisticated churls and barely consider the non-Aldmeri races at all. Alcharyai have a high regard for order, they are wearing uniforms and speaking in formal patterns. Their trees and their livestock have been bred to be as standard and ideal as they are. They have no real names of their own, only combinations of numbers. Alcharyai feel no real tenderness for one another and have no concept of compassion. They are decadent and self-obsessed, aware of their aristocratic position, they surround themselves with riches and treasures, the works of great artists and the finest of everything, but have no real appreciation for any of these things. Each of them is concerned solely with himself, and as a result they do no real socializing; they meet and hold courts only to demonstrate their importance and power to each other.\n\nAdherence to Alcharyae customs grants bonuses to Long Blade, Armorer, Speechcraft, Destruction, Enchant, Illusion, Willpower (+5), Maximum Magicka (50%) and penalties to Mercantile, Conjuration, Alchemy, Alteration, Sneak, Athletics, Personality, Speed (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "High Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Alcharyae"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
    end,
}

--LUKIUL
this.lukiul = {
    id = "lukiul",
    name = "Lukiul",
    description = (
        "Lukiul or \"assimilated\" are those Argonians who abandoned or were forced to abandon their traditional customs in favor of foreign culture, be that of the Empire or another.\n\nAdherence to Lukiul customs grants bonuses to Mercantile, Speechcraft, Personality (+5) and penalties to Mysticism, Spear, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Lukiul"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
		})
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
    end,
}

--XILEEL
this.xileel = {
    id = "xileel",
    name = "Xileel",
    description = (
        "The Xileel - Argonians native to southwestern Black Marsh - are radically religious and hostile towards Septim Empire.\n\nAdherence to Xileel customs grants bonuses to Alteration, Restoration, Mysticism, Illusion, Speechcraft, Destruction, Willpower (+5), Maximum Magicka (50%) and penalties to Alchemy, Athletics, Unarmored, Personality (-10) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Xileel"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
		})
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -10
        })
    end,
}

--BEJEHA
this.bejeha = {
    id = "bejeha",
    name = "Bejeha",
    description = (
        "The Bejeha - Argonians native to central and eastern Black Marsh - are conservative isolationists who never accepted the Imperial control.\n\nAdherence to Bejeha customs grants bonuses to Sneak, Security, Mercantile, Mysticism, Illusion, Spear, Endurance, Willpower (+5) and penalties to Long Blade, Armorer, Alteration, Heavy Armor, Medium Armor, Speechcraft, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Bejeha"
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
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
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
            skill = tes3.skill.speechcraft, 
            value = -5
        })
    end,
}

--NITUS
this.nitus = {
    id = "nitus",
    name = "Nitus",
    description = (
        "The Nitus - Argonians native to northwestern Black Marsh - are a tribe of exiles, heretics, criminals, and escaped slaves.\n\nAdherence to Nitus customs grants bonuses to Sneak, Security, Short Blade, Mysticism, Illusion, Unarmored, Agility, Intelligence (+5) and penalties to Alchemy, Armorer, Enchant, Heavy Armor, Mercantile, Speechcraft, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Nitus"
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
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
    end,
}

--GALNARESH
this.galnaresh = {
    id = "galnaresh",
    name = "Galnaresh",
    description = (
        "The Galnaresh - Argonians native to northeastern Black Marsh - are a common victims of Dunmer slave raids and resent the Empire for turning the blind eye on their misery.\n\nAdherence to Galnaresh customs grants bonuses to Sneak, Athletics, Light Armor, Marksman, Unarmored, Hand-to-hand, Willpower, Endurance (+5) and penalties to Alchemy, Illusion, Heavy Armor, Mysticism, Spear, Speechcraft, Strength, Luck (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Galnaresh"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
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
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
    end,
}

--CAYALURA
this.cayalura = {
    id = "cayalura",
    name = "Cayalura",
    description = (
        "The Cayalura - Argonians native to southeastern Black Marsh - are peaceful, nomadic, and isolationist.\n\nAdherence to Cayalura customs grants bonuses to Sneak, Illusion, Athletics, Mercantile, Armorer, Enchant, Agility, Personality (+5) and penalties to Alchemy, Medium Armor, Heavy Armor, Mysticism, Spear, Long Blade, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Cayalura"
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
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
    end,
}

--YERSILUS
this.yersilus = {
    id = "yersilus",
    name = "Yersilus",
    description = (
        "The Yersilus - Argonians native to southern Black Marsh - are brutal and corrupt collaborationists working with the Empire otherwise known as Archeins.\n\nAdherence to Yersilus customs grants bonuses to Hand-to-hand, Speechcraft, Heavy Armor, Medium Armor, Long Blade, Security, Strength, Endurance (+5) and penalties to Alchemy, Armorer, Mysticism, Unarmored, Enchant, Restoration, Personality, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Yersilus"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}

--AGACEPH
this.agaceph = {
    id = "agaceph",
    name = "Agaceph",
    description = (
        "Agacephs - Argonians native to central and western Black Marsh - are warrior traditionalists avoiding contacts with the Empire.\n\nAdherence to Agaceph customs grants bonuses to Armorer, Mercantile, Heavy Armor, Medium Armor, Long Blade, Spear, Strength, Endurance (+5) and penalties to Alchemy, Illusion, Mysticism, Unarmored, Enchant, Restoration, Intelligence, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Agaceph"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
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
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}

--CHUZEI
this.chuzei = {
    id = "chuzei",
    name = "Chuzei",
    description = (
        "Chuzei is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Central Morrowind they are usually associated with Great House Indoril, more specifically its more progressive fraction.\n\nAdherence to Chuzei customs grants bonuses to Restoration, Mysticism, Long Blade, Block, Medium Armor, Heavy Armor, Strength, Personality (+5) and penalties to Athletics, Destruction, Light Armor, Blunt Weapon, Marksman, Short Blade, Willpower, Agility (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Chuzei"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
    end,
}

--CHEV-ARAM
this.chevaram = {
    id = "chevaram",
    name = "Chev-Aram",
    description = (
        "Chev-Aram is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Central Morrowind they are usually associated with Great House Indoril, more specifically its more conservative fraction.\n\nAdherence to Chev-Aram customs grants bonuses to Restoration, Medium Armor, Conjuration, Blunt Weapon, Mysticism, Axe, Willpower, Personality (+5) and penalties to Athletics, Destruction, Light Armor, Long Blade, Marksman, Short Blade, Intelligence, Speed (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Chevaram"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
    end,
}

--ARMUN-AN
this.armunan = {
    id = "armunan",
    name = "Armun-An",
    description = (
        "Armun-An is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Southwestern Morrowind they are usually associated with Great House Hlaalu.\n\nAdherence to Armun-An customs grants bonuses to Light Armor, Mercantile, Sneak, Security, Short Blade, Speechcraft, Speed, Personality (+5) and penalties to Athletics, Destruction, Long Blade, Mysticism, Heavy Armor, Conjuration, Endurance, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Armunan"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
    end,
}

--CHI-ADDUN
this.chiaddun = {
    id = "chiaddun",
    name = "Chi-Addun",
    description = (
        "Chi-Addun is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Northeastern Morrowind they are usually associated with Great House Telvanni.\n\nAdherence to Chi-Addun customs grants bonuses to Alteration, Conjuration, Destruction, Enchant, Illusion, Alchemy, Intelligence (+5), Maximum Magicka (50%) and penalties to Athletics, Light Armor, Long Blade, Marksman, Short Blade, Acrobatics, Strength, Personality (-5) to those being faithful to their culture." -- Name from Elder Kings 2, to be renamed after TR decides on a name for Native Telvanni Bonemold
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Chiaddun"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
    end,
}

--GAH-KOGO
this.gahkogo = {
    id = "gahkogo",
    name = "Gah-Kogo",
    description = (
        "Gah-Kogo is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Southeastern Morrowind they are usually associated with Great House Dres.\n\nAdherence to Gah-Kogo customs grants bonuses to Athletics, Medium Armor, Spear, Light Armor, Marksman, Mercantile, Agility, Endurance (+5) and penalties to Mysticism, Heavy Armor, Short Blade, Destruction, Speechcraft, Long Blade, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Gahkogo"
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
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
    end,
}

--GAH-JULAN
this.gahjulan = {
    id = "gahjulan",
    name = "Gah-Julan",
    description = (
        "Gah-Julan is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to Northwestern Morrowind they are usually associated with Great House Redoran.\n\nAdherence to Gah-Julan customs grants bonuses to Athletics, Medium Armor, Long Blade, Axe, Spear, Heavy Armor, Strength, Endurance (+5) and penalties to Mysticism, Speechcraft, Mercantile, Destruction, Security, Sneak, Speed, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Gahjulan"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
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
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
    end,
}

--VELOTHI
this.velothi = {
    id = "velothi",
    name = "Velothi",
    description = (
        "In the long past the term Velothi was used to describe followers of prophet Veloth who became the Chimer, nowadays Velothi is a designation for Ashlanders who abandoned their nomadic life and settled among House Dunmer. Their Ashlander cousins seem them as weak and soft, while other Dunmer see them as insignificant underclass.\n\nAdherence to Velothi customs grants bonuses to Marksman, Light Armor, Security, Sneak, Spear, Medium Armor, Agility, Speed (+5) and penalties to Mysticism, Speechcraft, Alteration, Destruction, Short Blade, Heavy Armor, Personality, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Velothi"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
    end,
}

--ARADORMEER'M
this.aradormeerm = {
    id = "aradormeerm",
    name = "Aradormeer'm",
    description = (
        "Ashlanders or Aradormeer are Dunmeri nomadic herder-hunters who reject the Tribunal and preserve the ancient customs of the Chimer. They see material wealth as purposeless. \n\nAdherence to Aradormeer'm customs grants bonuses to Marksman, Light Armor, Mysticism, Alteration, Spear, Medium Armor, Agility, Endurance (+5) and penalties to Mercantile, Speechcraft, Security, Destruction, Short Blade, Heavy Armor, Personality, Intelligence (-5) to those being faithful to their culture." --Name based on unofficial Dunmeris dictionaries by Smitehammer. From Arador-Ashlands, Aradormer-Ashlander, Aradormeer-Ashlanders, Aradormeer'm-of Ashlanders
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Aradormeerm"
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
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
    end,
}

--OR-THAUD
this.orthaud = {
    id = "orthaud",
    name = "Or-Thaud",
    description = (
        "The Or-Thaud are itinerant Bosmer dwelling mainly in northeastern Valenwood or in exile in Hammerfell. Aggressive towards outsiders, they seek repayment of wrongdoings commited against them by Altmers, Khajiits, Cyrodiils through the means of raiding. Unlike most other Bosmer they favor Peryite over Y'ffre.\n\nAdherence to Or-Thaud customs grants bonuses to Athletics, Light Armor, Marksman, Sneak, Acrobatics, Mercantile, Speed, Endurance (+5) and penalties to Alchemy, Heavy Armor, Medium Armor, Block, Illusion, Enchant, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Orthaud"
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
            skill = tes3.skill.alchemy, 
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
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
    end,
}

--BOS'HAU
this.boshau = {
    id = "boshau",
    name = "Bos'hau",
    description = (
        "The Bos'hau - inhabitants of southwestern part Valenwood province - are ardent followers of the Green Pact which is however an extreme taboo in their matriarchal and polygamistic society.\n\nAdherence to Bos'hau customs grants bonuses to Armorer, Mercantile, Blunt Weapon, Heavy Armor, Medium Armor, Alchemy, Agility, Endurance (+5) and penalties to Acrobatics, Sneak, Security, Illusion, Athletics, Unarmored, Speed, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Boshau"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -5
        })
    end,
}

--HANAE
this.hanae = {
    id = "hanae",
    name = "Hanae",
    description = (
        "The Hanae - inhabitants of northwestern part Valenwood province - are the most rigid followers of the Green Pact and god Y'ffre.\n\nAdherence to Hanae customs grants bonuses to Acrobatics, Axe, Blunt Weapon, Heavy Armor, Medium Armor, Sneak, Agility, Strength (+5) and penalties to Mercantile, Speechcraft, Security, Long Blade, Spear, Alchemy, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Hanae"
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
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
    end,
}

--ANAM
this.anam = {
    id = "anam",
    name = "Anam",
    description = (
        "The Anam are inhabitants of southeastern part Valenwood province. Bosmers living there enjoy fairly cosmopolitan lifestyle and are very individualistic. Anam role in the society is decided from the moment they are conceived and many end up as skilled artisans with no knowledge on how to perform different tasks. \n\nAdherence to Anam customs grants bonuses to Mercantile, Alchemy, Alteration, Armorer, Enchant, Conjuration, Agility (+5), Maximum Magicka (50%) and penalties to Acrobatics, Sneak (-10), Speechcraft, Marksman, Personality, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Anam"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -10
        })
    end,
}

--TEHL
this.tehl = {
    id = "tehl",
    name = "Tehl",
    description = (
        "The Tehl are inhabitants of northeastern part Valenwood province - area around the city of Arenthia which borders Colovia and Elsweyr. Bosmers living there enjoy more cosmopolitan lifestyle than any other inhabitants of Valenwood. \n\nAdherence to Tehl customs grants bonuses to Security, Light Armor, Speechcraft, Mercantile, Alchemy, Short Blade, Intelligence, Personality (+5) and penalties to Acrobatics, Marksman, Sneak (-10), Speed, Agility (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Tehl"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -10
        })
    end,
}

--CAMORANI
this.camorani = {
    id = "camorani",
    name = "Camorani",
    description = (
        "Camorani are a group of Bosmer loyal to the Camoran dynasty. Apart from othe Bosmer both in appearance and in customs since the beginning of the First Era, they are often mistaken for Altmer by outlanders. It's unclear whether their towering stature is caused by eugenicist breeding or simply by powerful magicka.\n\nAdherence to Camorani customs grants bonuses to Alteration, Unarmored, Destruction, Illusion, Alchemy, Enchant, Willpower (+5), Maximum Magicka (+50%) and penalties to Acrobatics, Light Armor, Marksman, Sneak, Security, Hand-to-hand, Speed, Agility (-5) to those being faithful to their culture." --based on Citizens of the Empire by Lady Nerevar
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
		tes3.player.scale = tes3.player.scale * 1.1
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Camorani"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.handToHand, 
            value = -5
        })
    end,
}

--YOKUDAN
this.yokudan = {
    id = "yokudan",
    name = "Yokudan",
    description = (
        "Yokudans are inhabitants of what is left of destroyed continent of Yokuda. Sometimes they immigrate to the land of their heircousins - Hammerfell. \n\nAdherence to Yokudan customs grants bonuses to Long Blade, Enchant, Mysticism (+5), Maximum Magicka (50%) and penalties to Block, Armorer, Conjuration, Personality (-5) to those being faithful to their culture." --Yes, I made up the word "heircousin"
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Yokudan"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
    end,
}

--ELIN-HI
this.elinhi = {
    id = "elinhi",
    name = "Elin-Hi",
    description = (
        "Elin-Hi - \"strong who delve in magic\" - are inhabitants of the area around city of Elinhir in Eastern Hammerfell. Elinhir is a city of contradictions, it's a home to Crown Redguard who adopted Colovian fashion and taste, it's a city of soldierly people yet it's nicknamed 'The City of Mages'.\n\nAdherence to Elin-Hi customs grants bonuses to Alteration, Destruction, Illusion, Alchemy, Mysticism, Enchant, Intelligence (+5) Maximum Magicka (+50%) and penalties to Heavy Armor, Blunt Weapon, Axe, Long Blade, Medium Armor, Athletics, Strength, Endurance (-5) to those being faithful to their culture." --Initially I simply named it Elinhiri, but it ended up being the most bland of all the names. Resources on Yoku/Redguard's language are very sparse, but Hi=magic, while in Hrafnir's languages "elin" appears in few Ayleid words like pelin=member of the warrior caste and Telin=fortress, so I renamed this culture Elin-Hi to make it less bland. Let's say Elin-Hi means Mages of the warriors in this mixed Yoku-Cyrodis. Sounds just about right if you ask me. I hope anyone who is actually reading this ramblings has a nice day! :)
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Elinhi"
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
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
    end,
}

--SATAKAL'UGAK
this.satakalugak = {
    id = "satakalugak",
    name = "Satakal'Ugak",
    description = (
        "Satakals or Satakal'Ugak - \"rage-with-Satakal\" - are devotees of Satakal the Serpent God. They are beggar-bandit-madmen pretending to be snakes, often rolling in the dirt completely naked and attacking passersby by nipping at their legs. Satakals are also known for ritual scarification, the so-called skin-shedding.\n\nAdherence to Satakal'Ugak customs grants bonuses to Unarmored, Short Blade, Sneak, Acrobatics, Athletics, Hand-to-hand, Agility, Endurance (+5) and penalties to Heavy Armor, Blunt Weapon, Axe, Long Blade, Medium Armor, Mercantile, Strength, Speed (-5) to those being faithful to their culture." --Satakal'Mad
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Satakalugak"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
    end,
}

--ALIK'R
this.alikr = {
    id = "alikr",
    name = "Alik'r",
    description = (
        "Dunedwellers of Alik'r are nomadic inhabitants of Hammerfell deserts. They reject urban life and wander desolate land rarely coming into contact with urban people.\n\nAdherence to Alik'r customs grants bonuses to Unarmored, Short Blade, Illusion, Endurance, Speed (+5), Resist Fire (15%), Resist Shock (10%) and penalties to Heavy Armor, Mercantile, Speechcraft, Personality, Intelligence (-5), Weakness to Frost (25%) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Alikr"
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
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
    end,
}

--LHOTUNIC
this.lhotunic = {
    id = "lhotunic",
    name = "Lhotunic",
    description = (
        "Lhotunics is an emerging faction of Redguard society. Followers of King Lhotun of Sentinel who revere Yokudan past, but respect the Imperial ways. Trying to merge Crown and Forebear creeds, they achieved nothing but disdain from them both.\n\nAdherence to Lhotunic customs grants bonuses to Mercantile, Speechcraft (+5) and penalty to Personality (-5) to those being faithful to their culture." -- Lhotun = Second Boy
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Lhotunic"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
    end,
}

--RA'GADA
this.ragada = {
    id = "ragada",
    name = "Ra'Gada",
    description = (
        "Ra'Gada - \"warrior wave\" - also known as Forebears are Redguard descendants of warrior wave of Yokudans who first reached Tamriel. They are more nomadic than Na-Totambu and adopted Imperial and Breton gods - or at least their names - Crown view this as outrageous non-traditional practices.\n\nAdherence to Ra'Gada customs grants bonuses to Light Armor, Marksman, Mercantile, Security, Speechcraft, Short Blade, Agility, Speed (+5) and penalties to Heavy Armor, Blunt Weapon, Axe, Long Blade, Illusion, Mysticism, Willpower, Endurance (-5) to those being faithful to their culture." 
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Ragada"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
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
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
    end,
}

--NA-TOTAMBU
this.natotambu = {
    id = "natotambu",
    name = "Na-Totambu",
    description = (
        "Na-Totambu - \"ruling\" - also known as Crowns are Redguard descendants of old ruling class of Yokuda. They still honor the ancient Redguard ways and worship traditional Yokudan divines.\n\nAdherence to Na-Totambu customs grants bonuses to Armorer, Athletics, Axe, Blunt Weapon, Heavy Armor, Block, Strength, Endurance (+5) and penalties to Speechcraft, Sneak, Illusion, Enchant, Destruction, Alteration, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Natotambu"
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
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
    end,
}

--FRØSSELVIRKER
this.froesselvirker = {
    id = "froesselvirker",
    name = "Froesselvirker",
    description = (
        "Froesselvirkva - also known as Winterholders, Broken-Capetonians, or Hsaarikva - are inhabitants of the northeastern part of Skyrim - Hold of Winterhold - which they share with Aldihaldva. Froesselvirkva manifest an old mercantile spirit and hold Clever-Men in high regard.\n\nAdherence to Froesselvirker customs grants bonuses to Mercantile, Speechcraft, Destruction, Illusion, Alchemy, Alteration, Intelligence (+5), Maximum Magicka (50%) and penalties to Axe, Blunt Weapon, Medium Armor, Heavy Armor, Long Blade, Spear, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Froesselvirker"
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
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
    end,
}

--NYIHALDER
this.nyihalder = {
    id = "nyihalder",
    name = "Nyihalder",
    description = (
        "Nyihaldva or New-Holders are inhabitants of the western part of Skyrim: Holds of the Reach, Haafinheim, Whiterun, Falkreath, and Hrothgar. Nyihaldva are more progressive than their eastern countrymen.\n\nAdherence to Nyihalder customs grants bonuses to Mercantile, Speechcraft, Security, Sneak, Enchant, Armorer, Personality, Intelligence (+5) and penalties to Axe, Blunt Weapon, Medium Armor, Heavy Armor, Long Blade, Spear, Willpower, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Nyihalder"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mediumArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
    end,
}

--ALDIHALDER
this.aldihalder = {
    id = "aldihalder",
    name = "Aldihalder",
    description = (
        "Aldihaldva or Old-Holders are inhabitants of the eastern part of Skyrim: Holds of Winterhold, Eastmarch, the Rift, and the Pale. Aldihaldva remain isolated, by geography and by choice, and hold true to the ways of their forefathers.\n\nAdherence to Aldihalder customs grants bonuses to Armorer, Block, Heavy Armor, Long Blade, Spear, Athletics, Strength, Endurance (+5) and penalties to Speechcraft, Sneak, Illusion, Enchant, Alteration, Security, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Aldihalder"
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
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
    end,
}

--SKAAL
this.skaal = {
    id = "skaal",
    name = "Skaal",
    description = (
        "Skaal are inhabitants of the island of Solstheim, culturally different from other Nords, Skaal believe in dualistic cosmology within monotheistic religion. They feel strong connection to the land and nature, and strive for sustainability.\n\nAdherence to Skaal customs grants bonuses to Athletics, Marksman, Medium Armor, Restoration, Light Armor, Sneak, Willpower (+5), Maximum Magicka (50%) and penalties to Heavy Armor, Unarmored, Mercantile, Enchant, Destruction, Long Blade, Personality, Intelligence (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Skaal"
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
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
    end,
}

--OSTERNISH
this.osternish = {
    id = "osternish",
    name = "Osternish",
    description = (
        "Ostern are inhabitants of eastern part of High Rock though significant minority can be found all over the province. They cherish their Merish roots and aspire to establish a society based on Elven values. \n\nAdherence to Osternish customs grants bonuses to Illusion, Conjuration, Destruction, Restoration, Mysticism, Enchant, Intelligence (+5), Maximum Magicka (50%) and penalties to Heavy Armor, Medium Armor, Spear, Long Blade, Athletics, Block, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isHighRockRace = ( race == "Breton" or race == "T_Sky_Reachman" )
        return not isHighRockRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Osternish"
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
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
    end,
}

--BAYARD
this.bayard = {
    id = "bayard",
    name = "Bayard",
    description = (
        "Bayards are inhabitants of southern part of High Rock. They are the most Imperialized of Breton cultures. \n\nAdherence to Bayard customs grants bonuses to Heavy Armor, Spear, Mercantile, Speechcraft, Security, Light Armor, Personality, Willpower (+5) and penalties to Marksman, Alteration, Acrobatics, Axe, Blunt Weapon, Restoration, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isHighRockRace = ( race == "Breton" or race == "T_Sky_Reachman" )
        return not isHighRockRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Bayard"
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
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}

--NORMANNISH
this.normannish = {
    id = "normannish",
    name = "Normannish",
    description = (
        "Normen are inhabitants of northern part of High Rock. Isolated from other Breton and Merish influence they reject the Manmeri customs and honor their ancient Nordic and Nedic heritage. \n\nAdherence to Normannish customs grants bonuses to Enchant, Axe, Heavy Armor, Medium Armor, Blunt Weapon, Block, Strength, Endurance (+5) and penalties to Alchemy, Alteration, Conjuration, Illusion, Mysticism, Restoration, Intelligence, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isHighRockRace = ( race == "Breton" or race == "T_Sky_Reachman" )
        return not isHighRockRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Normannish"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -5
        })
    end,
}

--BJOULSAEAN
this.bjoulsaean = {
    id = "bjoulsaean",
    name = "Bjoulsaean",
    description = (
        "Bjoulsae River Tribes are predominantly Breton tribes of horse nomads dwelling on the plains surrounding Bjoulsae River which forms a border between High Rock and Hammerfell. Redguard tribes are sometimes called Silverhoof Horsemen. \n\nAdherence to Bjoulsaean customs grants bonuses to Light Armor, Athletics, Marksman, Hand-to-hand, Axe, Spear, Agility, Speed (+5) and penalties to Block, Alteration, Conjuration, Illusion, Heavy Armor, Speechcraft, Intelligence, Personality (-5) to those being faithful to their culture." --From my knowledge Project Tamriel is discarding ESO's Silverhoof Horsemen, so I sneaked them in here :)
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isHorseRace = ( race == "Breton" or race == "T_Sky_Reachman" or race == "Redguard" )
        return not isHorseRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Bjoulsaean"
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
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
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
            skill = tes3.skill.heavyArmor, 
            value = -5
        })
    end,
}

--REACHMANNISH
this.reachmannish = {
    id = "reachmannish",
    name = "Reachmannish",
    description = (
        "Reachmen are a tribe of humans inhabiting Eastern High Rock and Western Skyrim believed to be related to Bretons. Neither Bretons nor Reachmen acknowledge such relation and the latter are often shunned by other races. \n\nAdherence to Reachmannish customs grants bonuses to Conjuration, Destruction, Alteration, Alchemy, Blunt Weapon, Athletics, Willpower (+5), Maximum Magicka (+50%) and penalties to Illusion, Mysticism, Speechcraft, Mercantile, Security, Enchant, Strength, Personality (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isHighRockRace = ( race == "Breton" or race == "T_Sky_Reachman" )
        return not isHighRockRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Reachmannish"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
    end,
}

--JOVANSA
this.jovansa = {
    id = "jovansa",
    name = "Jovansa",
    description = (
        "Jovansa which translates to \"those who secure their future\" are communities of Khajiits who are hiding their beastfolk appearance and pretend to be Mer. Called Ririnajiit - \"compulsive liars\" - by other Khajiit they nonetheless shave off their fur and plan conception and birth carefully to make sure the offspring is of Ohmes stock. Eventhough these practices are widely frowned upon, they remain entrenched in regions where attitudes towards Khajiit are hostile such as Morrowind or Valenwood. \n\nAdherence to Jovansa customs grants bonuses to Alchemy, Illusion, Mysticism, Alteration, Restoration, Speechcraft, Willpower (+5), Maximum Magicka (+50%) and penalties to Acrobatics, Athletics, Hand-to-hand, Security, Sneak, Unarmored, Agility, Speed (-5) to those being faithful to their culture." --based on Citizens of the Empire by Lady Nerevar
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isCatRace = ( race == "Khajiit" or race == "T_Els_Cathay" or race == "T_Els_Cathay-raht" or race == "T_Els_Ohmes" or race == "T_Els_Ohmes-raht" or race == "T_Els_Suthay" )
        return not isCatRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Jovansa"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.athletics, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.handToHand, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = -5
        })
    end,
}

--NE QUIN-AL
this.nequinal = {
    id = "nequinal",
    name = "Ne Quin-al",
    description = (
        "Ne Quin-al or Anequinans are inhabitants of kingdom of Anequina forming a northern part of Elsweyr Confederacy. For the outsiders, Anequina seems to be a place of uncouth barbarians, for the locals, it is a place of proud warriors.\n\nAdherence to Ne Quin-al customs grants bonuses to Long Blade, Marksman, Heavy Armor, Medium Armor, Axe, Blunt Weapon, Strength, Endurance (+5) and penalties to Security, Short Blade, Sneak, Enchant, Speechcraft, Mercantile, Intelligence, Personality (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isCatRace = ( race == "Khajiit" or race == "T_Els_Cathay" or race == "T_Els_Cathay-raht" or race == "T_Els_Ohmes" or race == "T_Els_Ohmes-raht" or race == "T_Els_Suthay" )
        return not isCatRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Nequinal"
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
            skill = tes3.skill.security, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
    end,
}

--PA'ALATIIN
this.paalatiin = {
    id = "paalatiin",
    name = "Pa'alatiin",
    description = (
        "Pa'alatiin or Pellitinians are inhabitants of kingdom of Pellitine forming a southern part of Elsweyr Confederacy. For the outsiders, Pellitine seems to be a place of decadence and depravity, for the locals, it is a place of merchantry and wealth.\n\nAdherence to Pa'alatiin customs grants bonuses to Security, Speechcraft, Mercantile, Unarmored, Sneak, Alchemy, Intelligence, Personality (+5) and penalties to Heavy Armor, Medium Armor, Spear, Axe, Long Blade, Marksman, Strength, Agility (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isCatRace = ( race == "Khajiit" or race == "T_Els_Cathay" or race == "T_Els_Cathay-raht" or race == "T_Els_Ohmes" or race == "T_Els_Ohmes-raht" or race == "T_Els_Suthay" )
        return not isCatRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Paalatiin"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
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
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
    end,
}

--BAANDARI
this.baandari = {
    id = "baandari",
    name = "Baandari",
    description = (
        "Baandari are nomadic Khajiit peddler-fortunetellers. They live by tenets of their god - Baan Dar - any item not clearly belonging to someone is an item they can rightfully take.\n\nAdherence to Baandari customs grants bonuses to Security, Speechcraft, Mercantile, Illusion, Sneak, Armorer, Agility, Personality (+5) and penalties to Heavy Armor, Medium Armor, Spear, Axe, Long Blade, Destruction, Strength, Endurance (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isCatRace = ( race == "Khajiit" or race == "T_Els_Cathay" or race == "T_Els_Cathay-raht" or race == "T_Els_Ohmes" or race == "T_Els_Ohmes-raht" or race == "T_Els_Suthay" )
        return not isCatRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Baandari"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
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
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
    end,
}

--RIM-MEN
this.rimmen = {
    id = "rimmen",
    name = "Rim-Men",
    description = (
        "Rim-Men are mostly human inhabitants of The Rim - region in Elsweyr on the border with Cyrodiil province. They are descendants of Akaviri banished from Cyrodiil by Warlord Attrebus in Second Era. Although their Akaviri bloodline thinned over the years - with traces of Cyrodiilic, Khajiiti, and perhaps even Kamal blood - the old traditions are still celebrated to this day.\n\nAdherence to Rim-Men customs grants bonuses to Long Blade, Short Blade (+5), Resist Fire (25%) and penalties to Blunt Weapon, Axe (-5), Weakness to Frost (25%) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
		local isRimRace = ( race == "Imperial" or race == "Khajiit" or race == "T_Els_Cathay" or race == "T_Els_Cathay-raht" or race == "T_Els_Ohmes" or race == "T_Els_Ohmes-raht" or race == "T_Els_Suthay" )
        return not isRimRace
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Rimmen"
        }
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -5
        })
    end,
}

--HEARTLANDER
this.heartlander = {
    id = "heartlander",
    name = "Heartlander",
    description = (
        "Heartlanders are inhabitants of The Heartlands - central part of Cyrodiil province around Lake Rumare and the most lustrious city on Nirn - the Imperial City. Living in a region between Nibenay Valley and Colovian Highlands they combine Nibenese traditions with elements of Colovian culture.\n\nAdherence to Heartlander customs grants bonuses to Short Blade, Unarmored, Mercantile, Security, Mysticism, Sneak, Personality, Speed (+5) and penalties to Long Blade, Blunt Weapon, Block, Light Armor, Acrobatics, Marksman, Willpower, Agility (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Imperial"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Heartlander"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.lightArmor, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.acrobatics, 
            value = -5
        })
    end,
}

--NIBENESE
this.nibenese = {
    id = "nibenese",
    name = "Nibenese",
    description = (
        "Nibenese are inhabitants of Nibenay - eastern part of Cyrodiil province. They are regarded as Cyrodiil's soul: magnanimous, tolerant, and administrative. Nibenese excel in magicka and merchantry. They relish in garish costumes, bizarre tapestries, tattoos, brandings, and elaborate ceremony.\n\nAdherence to Nibenese customs grants bonuses to Destruction, Enchant, Restoration, Conjuration, Mysticism, Mercantile, Intelligence (+5), Maximum Magicka (+50%) and penalties to Long Blade, Hand-to-hand, Spear, Marksman, Blunt Weapon, Block, Strength, Agility (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Imperial"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Nibenese"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.handToHand, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -5
        })
    end,
}

--COLOVIAN
this.colovian = {
    id = "colovian",
    name = "Colovian",
    description = (
        "Colovians are inhabitants of Colovia - western part of Cyrodiil province. They are respected as Cyrodiil's iron hand: firm, unwavering, and ever-vigilant. Disinclined to magic and industry they prefer bloody engagement and plunder. Colovians are uncomplicated, self-sufficient, hearty, and extremely loyal to one another. They favor simple clothing over extravagant costumes.\n\nAdherence to Colovian customs grants bonuses to Axe, Block, Heavy Armor, Medium Armor, Athletics, Spear, Strength, Endurance (+5) and penalties to Mercantile, Illusion, Conjuration, Alteration, Destruction, Mysticism, Intelligence, Willpower (-5) to those being faithful to their culture."
    ),
	checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Imperial"
    end,
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrCultures_Colovian"
        }
		tes3.addItem{
            reference = tes3.player,
            item = "fur_colovian_helm",
            count = 1,
			updateGUI = false,
            playSound = false
        } -- Easter Egg :)
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = -5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = -5
        })
    end,
}

return this