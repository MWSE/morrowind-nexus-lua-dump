local I = require("openmw.interfaces")
local self = require("openmw.self")

local selfSkills = self.type.stats.skills
local selfAttrs = self.type.stats.attributes

local deps = require("scripts.mtrCultures.utils.dependencies")
local raceCheckers = require("scripts.mtrCultures.utils.raceGroups")
local traitType = require("scripts.mtrCultures.utils.traitTypes").culture
local skills = {
    acrobatics  = selfSkills.acrobatics(self),
    alchemy     = selfSkills.alchemy(self),
    alteration  = selfSkills.alteration(self),
    armorer     = selfSkills.armorer(self),
    athletics   = selfSkills.athletics(self),
    axe         = selfSkills.axe(self),
    block       = selfSkills.block(self),
    bluntWeapon = selfSkills.bluntweapon(self),
    conjuration = selfSkills.conjuration(self),
    destruction = selfSkills.destruction(self),
    enchant     = selfSkills.enchant(self),
    handToHand  = selfSkills.handtohand(self),
    heavyArmor  = selfSkills.heavyarmor(self),
    illusion    = selfSkills.illusion(self),
    lightArmor  = selfSkills.lightarmor(self),
    longBlade   = selfSkills.longblade(self),
    marksman    = selfSkills.marksman(self),
    mediumArmor = selfSkills.mediumarmor(self),
    mercantile  = selfSkills.mercantile(self),
    mysticism   = selfSkills.mysticism(self),
    restoration = selfSkills.restoration(self),
    security    = selfSkills.security(self),
    shortBlade  = selfSkills.shortblade(self),
    sneak       = selfSkills.sneak(self),
    spear       = selfSkills.spear(self),
    speechcraft = selfSkills.speechcraft(self),
    unarmored   = selfSkills.unarmored(self),
}
local attrs = {
    agility      = selfAttrs.agility(self),
    endurance    = selfAttrs.endurance(self),
    intelligence = selfAttrs.intelligence(self),
    luck         = selfAttrs.luck(self),
    personality  = selfAttrs.personality(self),
    speed        = selfAttrs.speed(self),
    strength     = selfAttrs.strength(self),
    willpower    = selfAttrs.willpower(self),
}
local selfSpells = self.type.spells(self)
local races = {
    -- vanilla
    argonian     = "argonian",
    breton       = "breton",
    darkElf      = "dark elf",
    ["dark elf"] = "dark elf",
    dunmer       = "dark elf",
    highElf      = "high elf",
    ["high elf"] = "high elf",
    altmer       = "high elf",
    imperial     = "imperial",
    khajiit      = "khajiit",
    nord         = "nord",
    orc          = "orc",
    redguard     = "redguard",
    woodElf      = "wood elf",
    ["wood elf"] = "wood elf",
    bosmer       = "wood elf",
    -- TR
    reachman     = "t_sky_reachman",
    cathay       = "t_els_cathay",
    cathayRaht   = "t_els_cathay-raht",
    ohmes        = "t_els_ohmes",
    ohmesRaht    = "t_els_ohmes-raht",
    suthay       = "t_els_suthay",
}

local function getRaceId(player)
    ---@diagnostic disable-next-line: undefined-field
    return player.type.records[player.recordId].race
end

deps.checkAll("MTR Cultures", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

I.CharacterTraits.addTrait {
    id = "agrunornim",
    type = traitType,
    name = "Agrun Ornim",
    description = (
        "Agrun Ornim - 'Deep Orcs' - are Orsimer living in the ancient Dwemer strongholds of " ..
        "Rourken clan in Hammerfell. They adopted Dwemer fashion and wear stylized beard and " ..
        "hairstyles of the long extinct Dwarves. More superstitious inhabitants of neighbouring " ..
        "areas even started believin that Dwemer never disappeared, but were instead turned into " ..
        "Orsimer as punishment for questioning the Divines. " ..
        "\n" ..
        "\n" ..
        "Adherence to Agrun Ornim customs grants bonuses to Armorer, Enchant, Long Blade, Spear, " ..
        "Alteration, Illusion, Intelligence (+5), Maximum Magicka (50%) and penalties to Axe, " ..
        "Block, Medium Armor, Conjuration, Alchemy, Mysticism, Agility, Speed (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Agrunornim")

        attrs.speed.base        = attrs.speed.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.axe.base         = skills.axe.base - 5
        skills.block.base       = skills.block.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "folrashornim",
    type = traitType,
    name = "Folrash Ornim",
    description = (
        "Folrash Ornim - 'Sand Orcs' - is a term used to describe two separate, but ultimately very " ..
        "similar nomadic cultures which came to existence due to convergent evolution. Orsimer of " ..
        "Alik'r desert in Hammerfell and Orsimer of Ne Quin-al desert in Elsweyr, though not " ..
        "closely related, exhibit similar traits and culture. Not as strong as other Orcs due to " ..
        "adaption for living in harsh conditions of water shortage, they took up a life of trade " ..
        "instead that of a fight. They are also said to reject traditional Orc worship of Malacath, " ..
        "Mauloch, or Trinimac in favor of worshipping Aedra, specifically their interpretation of " ..
        "Wind Goddess Kynareth. " ..
        "\n" ..
        "\n" ..
        "Adherence to Folrash Ornim customs grants bonuses to Mercantile, Athletics, Unarmored, " ..
        "Light Armor, Restoration, Endurance, Personality (+5), Resist Fire (25%) and penalties to " ..
        "Axe (-5), Heavy Armor, Medium Armor, Strength (-10) to those being faithful to their " ..
        "culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Folrashornim")

        attrs.strength.base     = attrs.strength.base - 10
        skills.axe.base         = skills.axe.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 10
        skills.mediumArmor.base = skills.mediumArmor.base - 10
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "folshornim",
    type = traitType,
    name = "Folsh Ornim",
    description = (
        "Folsh Ornim - 'Ash Orcs' - are barbarian, Malacath worshipping Orsimer living on the " ..
        "island of Vvardenfell often occupying ruined Daedric Shrines and ancient Dunmer " ..
        "strongholds. " ..
        "\n" ..
        "\n" ..
        "Adherence to Folsh Ornim customs grants bonuses to Unarmored, Light Armor, Blunt Weapon, " ..
        "Endurance, Speed (+5), Resist Fire (25%), Resist Blight Disease (25%) and penalties to " ..
        "Enchant, Destruction, Conjuration, Intelligence, Willpower (-5), Weakness to Magicka (50%) " ..
        "to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Folshornim")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.willpower.base    = attrs.willpower.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "malahkornim",
    type = traitType,
    name = "Malahk Ornim",
    description = (
        "Malahk Ornim are Orsimer living in valley deep between Velothi mountains in western " ..
        "Morrowind and Nibenay in eastern Cyrodiil. Bigger than any other subrace of Orcs, they are " ..
        "merciless raiders and barbarians worshipping Mauloch. " ..
        "\n" ..
        "\n" ..
        "Adherence to Malahk Ornim customs grants bonuses to Hand-to-hand, Axe, Blunt Weapon, " ..
        "Unarmored, Medium Armor, Athletics, Strength, Speed (+5) and penalties to Armorer, Block, " ..
        "Heavy Armor, Short Blade, Enchant, Security, Intelligence, Agility (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Malahkornim")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
        skills.block.base       = skills.block.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.security.base    = skills.security.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "sagraornim",
    type = traitType,
    name = "Sagra Ornim",
    description = (
        "Sagra Ornim - 'Wood Orcs' - are Orsimer living in forests of Valenwood. Smaller than other " ..
        "Orcs, they are expert tree-climbers and trackers. Since they tend to worship Mauloch and " ..
        "don't adhere to the Green Pact they established a strong trading contacts with local " ..
        "Bosmer supplying them with items made of materials which gathering is forbidden for the " ..
        "followers of Y'ffre. " ..
        "\n" ..
        "\n" ..
        "Adherence to Sagra Ornim customs grants bonuses to Short Blade, Acrobatics, Light Armor, " ..
        "Alchemy, Mercantile, Sneak, Speed, Agility (+5) and penalties to Block, Heavy Armor, " ..
        "Medium Armor (-10), Strength, Endurance (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Sagraornim")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "krazornim",
    type = traitType,
    name = "Kraz Ornim",
    description = (
        "Kraz Ornim - 'Mountain Orcs' - are Orsimer living in the mountain ranges of High Rock. " ..
        "They inhabit the most recognized of Orcish entities - Orsinium - and have recently " ..
        "rejected Malacath worship in favor of renewing of Trinimac worship. " ..
        "\n" ..
        "\n" ..
        "Adherence to Kraz Ornim customs grants bonuses to Armorer, Axe, Block, Speechcraft, Medium " ..
        "Armor, Athletics, Willpower, Personality (+5) and penalties to Sneak, Short Blade, " ..
        "Illusion, Conjuration, Enchant, Security, Intelligence, Agility (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Krazornim")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.security.base    = skills.security.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "rielleie",
    type = traitType,
    name = "Rielleie",
    description = (
        "Riellei - 'The Beautiful' - are a movement aiming to shake up Altmer society. They believe " ..
        "that Summerset Islands need let go of its past in order to move forward. Rielleie methods " ..
        "are radical, they seek to destroy monuments and murder members of aristocracy. " ..
        "\n" ..
        "\n" ..
        "Adherence to Rielleie customs grants bonuses to Sneak, Short Blade, Blunt Weapon, " ..
        "Marksman, Athletics, Hand-to-hand, Strength, Speed (+5) and penalties to Alchemy, " ..
        "Alteration, Conjuration, Restoration, Enchant, Illusion, Willpower, Personality (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Rielleie")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.restoration.base = skills.restoration.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['high elf']
    end
}

I.CharacterTraits.addTrait {
    id = "dirennis",
    type = traitType,
    name = "Dirennis",
    description = (
        "Clan Direnni is an Altmer clan who colonized northwestern Tamriel. In the past their " ..
        "economic and military power was formidable enough that they controlled a quarter of " ..
        "Tamriel. Direnni are not subscribing to racial purity tenets of the Alcharyai. " ..
        "\n" ..
        "\n" ..
        "Adherence to Dirennis customs grants bonuses to Alchemy, Conjuration, Mercantile, Enchant, " ..
        "Mysticism, Security, Personality, Intelligence (+5) and penalties to Destruction, " ..
        "Illusion, Restoration, Sneak, Axe, Long Blade, Agility, Endurance (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Dirennis")

        attrs.agility.base = attrs.agility.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (
            playerRace == races.highElf
            or playerRace == races.breton
        )
    end
}

I.CharacterTraits.addTrait {
    id = "meldise",
    type = traitType,
    name = "Meldise",
    description = (
        "Meldis - 'exiled' - are Altmer who were banished from Summerset Islands for breaking the " ..
        "rules of the so-called 'ideal society'. Alcharyai regard exile as equivalent of death " ..
        "sentence. " ..
        "\n" ..
        "\n" ..
        "Adherence to Meldise customs grants bonuses to Sneak, Security, Alteration, Restoration, " ..
        "Mysticism, Conjuration, Intelligence, Agility (+5) and penalties to Destruction, Enchant, " ..
        "Illusion, Speechcraft, Mercantile, Armorer, Willpower, Speed (-5) to those being faithful " ..
        "to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Meldise")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.speed.base        = attrs.speed.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.armorer.base     = skills.armorer.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['high elf']
    end
}

I.CharacterTraits.addTrait {
    id = "alcharyae",
    type = traitType,
    name = "Alcharyae",
    description = (
        "Alcharyai - 'Highest Elves' - are those Altmer who adhere to ancient customs. Over " ..
        "hundreds of generations they have bred themselves into a racially pure line, and are now " ..
        "almost identical to one another in appearance. They despise other Elves as unsophisticated " ..
        "churls and barely consider the non-Aldmeri races at all. Alcharyai have a high regard for " ..
        "order, they are wearing uniforms and speaking in formal patterns. Their trees and their " ..
        "livestock have been bred to be as standard and ideal as they are. They have no real names " ..
        "of their own, only combinations of numbers. Alcharyai feel no real tenderness for one " ..
        "another and have no concept of compassion. They are decadent and self-obsessed, aware of " ..
        "their aristocratic position, they surround themselves with riches and treasures, the works " ..
        "of great artists and the finest of everything, but have no real appreciation for any of " ..
        "these things. Each of them is concerned solely with himself, and as a result they do no " ..
        "real socializing; they meet and hold courts only to demonstrate their importance and power " ..
        "to each other. " ..
        "\n" ..
        "\n" ..
        "Adherence to Alcharyae customs grants bonuses to Long Blade, Armorer, Speechcraft, " ..
        "Destruction, Enchant, Illusion, Willpower (+5), Maximum Magicka (50%) and penalties to " ..
        "Mercantile, Conjuration, Alchemy, Alteration, Sneak, Athletics, Personality, Speed (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Alcharyae")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.speed.base        = attrs.speed.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.athletics.base   = skills.athletics.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['high elf']
    end
}

I.CharacterTraits.addTrait {
    id = "lukiul",
    type = traitType,
    name = "Lukiul",
    description = (
        "Lukiul or 'assimilated' are those Argonians who abandoned or were forced to abandon their " ..
        "traditional customs in favor of foreign culture, be that of the Empire or another. " ..
        "\n" ..
        "\n" ..
        "Adherence to Lukiul customs grants bonuses to Mercantile, Speechcraft, Personality (+5) " ..
        "and penalties to Mysticism, Spear, Willpower (-5) to those being faithful to their " ..
        "culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Lukiul")

        attrs.willpower.base  = attrs.willpower.base - 5
        skills.mysticism.base = skills.mysticism.base - 5
        skills.spear.base     = skills.spear.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "xileel",
    type = traitType,
    name = "Xileel",
    description = (
        "The Xileel - Argonians native to southwestern Black Marsh - are radically religious and " ..
        "hostile towards Septim Empire. " ..
        "\n" ..
        "\n" ..
        "Adherence to Xileel customs grants bonuses to Alteration, Restoration, Mysticism, " ..
        "Illusion, Speechcraft, Destruction, Willpower (+5), Maximum Magicka (50%) and penalties to " ..
        "Alchemy, Athletics, Unarmored, Personality (-10) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Xileel")

        attrs.personality.base = attrs.personality.base - 10
        skills.alchemy.base    = skills.alchemy.base - 10
        skills.athletics.base  = skills.athletics.base - 10
        skills.unarmored.base  = skills.unarmored.base - 10
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "bejeha",
    type = traitType,
    name = "Bejeha",
    description = (
        "The Bejeha - Argonians native to central and eastern Black Marsh - are conservative " ..
        "isolationists who never accepted the Imperial control. " ..
        "\n" ..
        "\n" ..
        "Adherence to Bejeha customs grants bonuses to Sneak, Security, Mercantile, Mysticism, " ..
        "Illusion, Spear, Endurance, Willpower (+5) and penalties to Long Blade, Armorer, " ..
        "Alteration, Heavy Armor, Medium Armor, Speechcraft, Personality, Intelligence (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Bejeha")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "nitus",
    type = traitType,
    name = "Nitus",
    description = (
        "The Nitus - Argonians native to northwestern Black Marsh - are a tribe of exiles, " ..
        "heretics, criminals, and escaped slaves. " ..
        "\n" ..
        "\n" ..
        "Adherence to Nitus customs grants bonuses to Sneak, Security, Short Blade, Mysticism, " ..
        "Illusion, Unarmored, Agility, Intelligence (+5) and penalties to Alchemy, Armorer, " ..
        "Enchant, Heavy Armor, Mercantile, Speechcraft, Strength, Endurance (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Nitus")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "galnaresh",
    type = traitType,
    name = "Galnaresh",
    description = (
        "The Galnaresh - Argonians native to northeastern Black Marsh - are a common victims of " ..
        "Dunmer slave raids and resent the Empire for turning the blind eye on their misery. " ..
        "\n" ..
        "\n" ..
        "Adherence to Galnaresh customs grants bonuses to Sneak, Athletics, Light Armor, Marksman, " ..
        "Unarmored, Hand-to-hand, Willpower, Endurance (+5) and penalties to Alchemy, Illusion, " ..
        "Heavy Armor, Mysticism, Spear, Speechcraft, Strength, Luck (-5) to those being faithful to " ..
        "their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Galnaresh")

        attrs.strength.base     = attrs.strength.base - 5
        attrs.luck.base         = attrs.luck.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.spear.base       = skills.spear.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "cayalura",
    type = traitType,
    name = "Cayalura",
    description = (
        "The Cayalura - Argonians native to southeastern Black Marsh - are peaceful, nomadic, and " ..
        "isolationist. " ..
        "\n" ..
        "\n" ..
        "Adherence to Cayalura customs grants bonuses to Sneak, Illusion, Athletics, Mercantile, " ..
        "Armorer, Enchant, Agility, Personality (+5) and penalties to Alchemy, Medium Armor, Heavy " ..
        "Armor, Mysticism, Spear, Long Blade, Strength, Endurance (-5) to those being faithful to " ..
        "their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Cayalura")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "yersilus",
    type = traitType,
    name = "Yersilus",
    description = (
        "The Yersilus - Argonians native to southern Black Marsh - are brutal and corrupt " ..
        "collaborationists working with the Empire otherwise known as Archeins. " ..
        "\n" ..
        "\n" ..
        "Adherence to Yersilus customs grants bonuses to Hand-to-hand, Speechcraft, Heavy Armor, " ..
        "Medium Armor, Long Blade, Security, Strength, Endurance (+5) and penalties to Alchemy, " ..
        "Armorer, Mysticism, Unarmored, Enchant, Restoration, Personality, Willpower (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Yersilus")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.unarmored.base   = skills.unarmored.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.restoration.base = skills.restoration.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "agaceph",
    type = traitType,
    name = "Agaceph",
    description = (
        "Agacephs - Argonians native to central and western Black Marsh - are warrior " ..
        "traditionalists avoiding contacts with the Empire. " ..
        "\n" ..
        "\n" ..
        "Adherence to Agaceph customs grants bonuses to Armorer, Mercantile, Heavy Armor, Medium " ..
        "Armor, Long Blade, Spear, Strength, Endurance (+5) and penalties to Alchemy, Illusion, " ..
        "Mysticism, Unarmored, Enchant, Restoration, Intelligence, Willpower (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Agaceph")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.unarmored.base   = skills.unarmored.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.restoration.base = skills.restoration.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "chuzei",
    type = traitType,
    name = "Chuzei",
    description = (
        "Chuzei is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Central Morrowind they are usually associated with Great House Indoril, more specifically " ..
        "its more progressive fraction. " ..
        "\n" ..
        "\n" ..
        "Adherence to Chuzei customs grants bonuses to Restoration, Mysticism, Long Blade, Block, " ..
        "Medium Armor, Heavy Armor, Strength, Personality (+5) and penalties to Athletics, " ..
        "Destruction, Light Armor, Blunt Weapon, Marksman, Short Blade, Willpower, Agility (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Chuzei")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.athletics.base   = skills.athletics.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.bluntWeapon.base = skills.bluntWeapon.base - 5
        skills.lightArmor.base  = skills.lightArmor.base - 5
        skills.marksman.base    = skills.marksman.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "chevaram",
    type = traitType,
    name = "Chev-Aram",
    description = (
        "Chev-Aram is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Central Morrowind they are usually associated with Great House Indoril, more specifically " ..
        "its more conservative fraction. " ..
        "\n" ..
        "\n" ..
        "Adherence to Chev-Aram customs grants bonuses to Restoration, Medium Armor, Conjuration, " ..
        "Blunt Weapon, Mysticism, Axe, Willpower, Personality (+5) and penalties to Athletics, " ..
        "Destruction, Light Armor, Long Blade, Marksman, Short Blade, Intelligence, Speed (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Chevaram")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.speed.base        = attrs.speed.base - 5
        skills.athletics.base   = skills.athletics.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.lightArmor.base  = skills.lightArmor.base - 5
        skills.marksman.base    = skills.marksman.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "armunan",
    type = traitType,
    name = "Armun-An",
    description = (
        "Armun-An is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Southwestern Morrowind they are usually associated with Great House Hlaalu. " ..
        "\n" ..
        "\n" ..
        "Adherence to Armun-An customs grants bonuses to Light Armor, Mercantile, Sneak, Security, " ..
        "Short Blade, Speechcraft, Speed, Personality (+5) and penalties to Athletics, Destruction, " ..
        "Long Blade, Mysticism, Heavy Armor, Conjuration, Endurance, Willpower (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Armunan")

        attrs.willpower.base = attrs.willpower.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "chiaddun",
    type = traitType,
    name = "Chi-Addun",
    description = (
        "Chi-Addun is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Northeastern Morrowind they are usually associated with Great House Telvanni. " ..
        "\n" ..
        "\n" ..
        "Adherence to Chi-Addun customs grants bonuses to Alteration, Conjuration, Destruction, " ..
        "Enchant, Illusion, Alchemy, Intelligence (+5), Maximum Magicka (50%) and penalties to " ..
        "Athletics, Light Armor, Long Blade, Marksman, Short Blade, Acrobatics, Strength, " ..
        "Personality (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Chiaddun")

        attrs.personality.base = attrs.personality.base - 5
        attrs.strength.base    = attrs.strength.base - 5
        skills.athletics.base  = skills.athletics.base - 5
        skills.lightArmor.base = skills.lightArmor.base - 5
        skills.longBlade.base  = skills.longBlade.base - 5
        skills.marksman.base   = skills.marksman.base - 5
        skills.shortBlade.base = skills.shortBlade.base - 5
        skills.acrobatics.base = skills.acrobatics.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "gahkogo",
    type = traitType,
    name = "Gah-Kogo",
    description = (
        "Gah-Kogo is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Southeastern Morrowind they are usually associated with Great House Dres. " ..
        "\n" ..
        "\n" ..
        "Adherence to Gah-Kogo customs grants bonuses to Athletics, Medium Armor, Spear, Light " ..
        "Armor, Marksman, Mercantile, Agility, Endurance (+5) and penalties to Mysticism, Heavy " ..
        "Armor, Short Blade, Destruction, Speechcraft, Long Blade, Personality, Intelligence (-5) " ..
        "to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Gahkogo")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "gahjulan",
    type = traitType,
    name = "Gah-Julan",
    description = (
        "Gah-Julan is one of the main divisions of Ouraanmeri - House Dunmer - culture. Native to " ..
        "Northwestern Morrowind they are usually associated with Great House Redoran. " ..
        "\n" ..
        "\n" ..
        "Adherence to Gah-Julan customs grants bonuses to Athletics, Medium Armor, Long Blade, Axe, " ..
        "Spear, Heavy Armor, Strength, Endurance (+5) and penalties to Mysticism, Speechcraft, " ..
        "Mercantile, Destruction, Security, Sneak, Speed, Intelligence (-5) to those being faithful " ..
        "to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Gahjulan")

        attrs.speed.base        = attrs.speed.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.security.base    = skills.security.base - 5
        skills.sneak.base       = skills.sneak.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "velothi",
    type = traitType,
    name = "Velothi",
    description = (
        "In the long past the term Velothi was used to describe followers of prophet Veloth who " ..
        "became the Chimer, nowadays Velothi is a designation for Ashlanders who abandoned their " ..
        "nomadic life and settled among House Dunmer. Their Ashlander cousins seem them as weak and " ..
        "soft, while other Dunmer see them as insignificant underclass. " ..
        "\n" ..
        "\n" ..
        "Adherence to Velothi customs grants bonuses to Marksman, Light Armor, Security, Sneak, " ..
        "Spear, Medium Armor, Agility, Speed (+5) and penalties to Mysticism, Speechcraft, " ..
        "Alteration, Destruction, Short Blade, Heavy Armor, Personality, Endurance (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Velothi")
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "aradormeerm",
    type = traitType,
    name = "Aradormeer'm",
    description = (
        "Ashlanders or Aradormeer are Dunmeri nomadic herder-hunters who reject the Tribunal and " ..
        "preserve the ancient customs of the Chimer. They see material wealth as purposeless. " ..
        "\n" ..
        "\n" ..
        "Adherence to Aradormeer'm customs grants bonuses to Marksman, Light Armor, Mysticism, " ..
        "Alteration, Spear, Medium Armor, Agility, Endurance (+5) and penalties to Mercantile, " ..
        "Speechcraft, Security, Destruction, Short Blade, Heavy Armor, Personality, Intelligence " ..
        "(-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Aradormeerm")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.security.base    = skills.security.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "orthaud",
    type = traitType,
    name = "Or-Thaud",
    description = (
        "The Or-Thaud are itinerant Bosmer dwelling mainly in northeastern Valenwood or in exile in " ..
        "Hammerfell. Aggressive towards outsiders, they seek repayment of wrongdoings commited " ..
        "against them by Altmers, Khajiits, Cyrodiils through the means of raiding. Unlike most " ..
        "other Bosmer they favor Peryite over Y'ffre. " ..
        "\n" ..
        "\n" ..
        "Adherence to Or-Thaud customs grants bonuses to Athletics, Light Armor, Marksman, Sneak, " ..
        "Acrobatics, Mercantile, Speed, Endurance (+5) and penalties to Alchemy, Heavy Armor, " ..
        "Medium Armor, Block, Illusion, Enchant, Personality, Intelligence (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Orthaud")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.block.base       = skills.block.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.enchant.base     = skills.enchant.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "boshau",
    type = traitType,
    name = "Bos'hau",
    description = (
        "The Bos'hau - inhabitants of southwestern part Valenwood province - are ardent followers " ..
        "of the Green Pact which is however an extreme taboo in their matriarchal and polygamistic " ..
        "society. " ..
        "\n" ..
        "\n" ..
        "Adherence to Bos'hau customs grants bonuses to Armorer, Mercantile, Blunt Weapon, Heavy " ..
        "Armor, Medium Armor, Alchemy, Agility, Endurance (+5) and penalties to Acrobatics, Sneak, " ..
        "Security, Illusion, Athletics, Unarmored, Speed, Intelligence (-5) to those being faithful " ..
        "to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Boshau")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.speed.base        = attrs.speed.base - 5
        skills.acrobatics.base  = skills.acrobatics.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.security.base    = skills.security.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.athletics.base   = skills.athletics.base - 5
        skills.unarmored.base   = skills.unarmored.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "hanae",
    type = traitType,
    name = "Hanae",
    description = (
        "The Hanae - inhabitants of northwestern part Valenwood province - are the most rigid " ..
        "followers of the Green Pact and god Y'ffre. " ..
        "\n" ..
        "\n" ..
        "Adherence to Hanae customs grants bonuses to Acrobatics, Axe, Blunt Weapon, Heavy Armor, " ..
        "Medium Armor, Sneak, Agility, Strength (+5) and penalties to Mercantile, Speechcraft, " ..
        "Security, Long Blade, Spear, Alchemy, Personality, Intelligence (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Hanae")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.security.base    = skills.security.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.spear.base       = skills.spear.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "anam",
    type = traitType,
    name = "Anam",
    description = (
        "The Anam are inhabitants of southeastern part Valenwood province. Bosmers living there " ..
        "enjoy fairly cosmopolitan lifestyle and are very individualistic. Anam role in the society " ..
        "is decided from the moment they are conceived and many end up as skilled artisans with no " ..
        "knowledge on how to perform different tasks. " ..
        "\n" ..
        "\n" ..
        "Adherence to Anam customs grants bonuses to Mercantile, Alchemy, Alteration, Armorer, " ..
        "Enchant, Conjuration, Agility (+5), Maximum Magicka (50%) and penalties to Acrobatics, " ..
        "Sneak (-10), Speechcraft, Marksman, Personality, Endurance (-5) to those being faithful to " ..
        "their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Anam")

        attrs.personality.base = attrs.personality.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "tehl",
    type = traitType,
    name = "Tehl",
    description = (
        "The Tehl are inhabitants of northeastern part of the Valenwood province - area around the city of " ..
        "Arenthia which borders Colovia and Elsweyr. Bosmers living there enjoy more cosmopolitan " ..
        "lifestyle than any other inhabitants of Valenwood. " ..
        "\n" ..
        "\n" ..
        "Adherence to Tehl customs grants bonuses to Security, Light Armor, Speechcraft, " ..
        "Mercantile, Alchemy, Short Blade, Intelligence, Personality (+5) and penalties to " ..
        "Acrobatics, Marksman, Sneak (-10), Speed, Agility (-5) to those being faithful to their " ..
        "culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Tehl")

        attrs.speed.base       = attrs.speed.base - 5
        attrs.agility.base     = attrs.agility.base - 5
        skills.acrobatics.base = skills.acrobatics.base - 10
        skills.marksman.base   = skills.marksman.base - 10
        skills.sneak.base      = skills.sneak.base - 10
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "camorani",
    type = traitType,
    name = "Camorani",
    description = (
        "Camorani are a group of Bosmer loyal to the Camoran dynasty. Apart from other Bosmer both " ..
        "in appearance and in customs since the beginning of the First Era, they are often mistaken " ..
        "for Altmer by outlanders. It's unclear whether their towering stature is caused by " ..
        "eugenicist breeding or simply by powerful magicka. " ..
        "\n" ..
        "\n" ..
        "Adherence to Camorani customs grants bonuses to Alteration, Unarmored, Destruction, " ..
        "Illusion, Alchemy, Enchant, Willpower (+5), Maximum Magicka (+50%) and penalties to " ..
        "Acrobatics, Light Armor, Marksman, Sneak, Security, Hand-to-hand, Speed, Agility (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Camorani")

        attrs.speed.base       = attrs.speed.base - 5
        attrs.agility.base     = attrs.agility.base - 5
        skills.acrobatics.base = skills.acrobatics.base - 5
        skills.lightArmor.base = skills.lightArmor.base - 5
        skills.marksman.base   = skills.marksman.base - 5
        skills.sneak.base      = skills.sneak.base - 5
        skills.security.base   = skills.security.base - 5
        skills.handToHand.base = skills.handToHand.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "yokudan",
    type = traitType,
    name = "Yokudan",
    description = (
        "Yokudans are inhabitants of what is left of destroyed continent of Yokuda. Sometimes they " ..
        "immigrate to the land of their heircousins - Hammerfell. " ..
        "\n" ..
        "\n" ..
        "Adherence to Yokudan customs grants bonuses to Long Blade, Enchant, Mysticism (+5), " ..
        "Maximum Magicka (50%) and penalties to Block, Armorer, Conjuration, Personality (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Yokudan")

        attrs.personality.base  = attrs.personality.base - 5
        skills.block.base       = skills.block.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "elinhi",
    type = traitType,
    name = "Elin-Hi",
    description = (
        "Elin-Hi - 'strong who delve in magic' - are inhabitants of the area around city of Elinhir " ..
        "in Eastern Hammerfell. Elinhir is a city of contradictions, it's a home to Crown Redguard " ..
        "who adopted Colovian fashion and taste, it's a city of soldierly people yet it's nicknamed " ..
        "'The City of Mages'. " ..
        "\n" ..
        "\n" ..
        "Adherence to Elin-Hi customs grants bonuses to Alteration, Destruction, Illusion, Alchemy, " ..
        "Mysticism, Enchant, Intelligence (+5) Maximum Magicka (+50%) and penalties to Heavy Armor, " ..
        "Blunt Weapon, Axe, Long Blade, Medium Armor, Athletics, Strength, Endurance (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Elinhi")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "satakalugak",
    type = traitType,
    name = "Satakal'Ugak",
    description = (
        "Satakals or Satakal'Ugak - 'rage-with-Satakal' - are devotees of Satakal the Serpent God. " ..
        "They are beggar-bandit-madmen pretending to be snakes, often rolling in the dirt " ..
        "completely naked and attacking passersby by nipping at their legs. Satakals are also known " ..
        "for ritual scarification, the so-called skin-shedding. " ..
        "\n" ..
        "\n" ..
        "Adherence to Satakal'Ugak customs grants bonuses to Unarmored, Short Blade, Sneak, " ..
        "Acrobatics, Athletics, Hand-to-hand, Agility, Endurance (+5) and penalties to Heavy Armor, " ..
        "Blunt Weapon, Axe, Long Blade, Medium Armor, Mercantile, Strength, Speed (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Satakalugak")

        attrs.strength.base     = attrs.strength.base - 5
        attrs.speed.base        = attrs.speed.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.bluntWeapon.base = skills.bluntWeapon.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.axe.base         = skills.axe.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "alikr",
    type = traitType,
    name = "Alik'r",
    description = (
        "Dunedwellers of Alik'r are nomadic inhabitants of Hammerfell deserts. They reject urban " ..
        "life and wander desolate land rarely coming into contact with urban people. " ..
        "\n" ..
        "\n" ..
        "Adherence to Alik'r customs grants bonuses to Unarmored, Short Blade, Illusion, Endurance, " ..
        "Speed (+5), Resist Fire (15%), Resist Shock (10%) and penalties to Heavy Armor, " ..
        "Mercantile, Speechcraft, Personality, Intelligence (-5), Weakness to Frost (25%) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Alikr")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "lhotunic",
    type = traitType,
    name = "Lhotunic",
    description = (
        "Lhotunics is an emerging faction of Redguard society. Followers of King Lhotun of Sentinel " ..
        "who revere Yokudan past, but respect the Imperial ways. Trying to merge Crown and Forebear " ..
        "creeds, they achieved nothing but disdain from them both. " ..
        "\n" ..
        "\n" ..
        "Adherence to Lhotunic customs grants bonuses to Mercantile, Speechcraft (+5) and penalty " ..
        "to Personality (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Lhotunic")

        attrs.personality.base = attrs.personality.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "ragada",
    type = traitType,
    name = "Ra'Gada",
    description = (
        "Ra'Gada - 'warrior wave' - also known as Forebears are Redguard descendants of warrior " ..
        "wave of Yokudans who first reached Tamriel. They are more nomadic than Na-Totambu and " ..
        "adopted Imperial and Breton gods - or at least their names - Crown view this as outrageous " ..
        "non-traditional practices. " ..
        "\n" ..
        "\n" ..
        "Adherence to Ra'Gada customs grants bonuses to Light Armor, Marksman, Mercantile, " ..
        "Security, Speechcraft, Short Blade, Agility, Speed (+5) and penalties to Heavy Armor, " ..
        "Blunt Weapon, Axe, Long Blade, Illusion, Mysticism, Willpower, Endurance (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Ragada")

        attrs.willpower.base = attrs.willpower.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "natotambu",
    type = traitType,
    name = "Na-Totambu",
    description = (
        "Na-Totambu - 'ruling' - also known as Crowns are Redguard descendants of old ruling class " ..
        "of Yokuda. They still honor the ancient Redguard ways and worship traditional Yokudan " ..
        "divines. " ..
        "\n" ..
        "\n" ..
        "Adherence to Na-Totambu customs grants bonuses to Armorer, Athletics, Axe, Blunt Weapon, " ..
        "Heavy Armor, Block, Strength, Endurance (+5) and penalties to Speechcraft, Sneak, " ..
        "Illusion, Enchant, Destruction, Alteration, Personality, Intelligence (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Natotambu")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.destruction.base = skills.destruction.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "froesselvirker",
    type = traitType,
    name = "Froesselvirker",
    description = (
        "Froesselvirkva - also known as Winterholders, Broken-Capetonians, or Hsaarikva - are " ..
        "inhabitants of the northeastern part of Skyrim - Hold of Winterhold - which they share " ..
        "with Aldihaldva. Froesselvirkva manifest an old mercantile spirit and hold Clever-Men in " ..
        "high regard. " ..
        "\n" ..
        "\n" ..
        "Adherence to Froesselvirker customs grants bonuses to Mercantile, Speechcraft, " ..
        "Destruction, Illusion, Alchemy, Alteration, Intelligence (+5), Maximum Magicka (50%) and " ..
        "penalties to Axe, Blunt Weapon, Medium Armor, Heavy Armor, Long Blade, Spear, Strength, " ..
        "Endurance (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Froesselvirker")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['nord']
    end
}

I.CharacterTraits.addTrait {
    id = "nyihalder",
    type = traitType,
    name = "Nyihalder",
    description = (
        "Nyihaldva or New-Holders are inhabitants of the western part of Skyrim: Holds of the " ..
        "Reach, Haafinheim, Whiterun, Falkreath, and Hrothgar. Nyihaldva are more progressive than " ..
        "their eastern countrymen. " ..
        "\n" ..
        "\n" ..
        "Adherence to Nyihalder customs grants bonuses to Mercantile, Speechcraft, Security, Sneak, " ..
        "Enchant, Armorer, Personality, Intelligence (+5) and penalties to Axe, Blunt Weapon, " ..
        "Medium Armor, Heavy Armor, Long Blade, Spear, Willpower, Endurance (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Nyihalder")

        attrs.willpower.base = attrs.willpower.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['nord']
    end
}

I.CharacterTraits.addTrait {
    id = "aldihalder",
    type = traitType,
    name = "Aldihalder",
    description = (
        "Aldihaldva or Old-Holders are inhabitants of the eastern part of Skyrim: Holds of " ..
        "Winterhold, Eastmarch, the Rift, and the Pale. Aldihaldva remain isolated, by geography " ..
        "and by choice, and hold true to the ways of their forefathers. " ..
        "\n" ..
        "\n" ..
        "Adherence to Aldihalder customs grants bonuses to Armorer, Block, Heavy Armor, Long Blade, " ..
        "Spear, Athletics, Strength, Endurance (+5) and penalties to Speechcraft, Sneak, Illusion, " ..
        "Enchant, Alteration, Security, Personality, Intelligence (-5) to those being faithful to " ..
        "their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Aldihalder")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.security.base    = skills.security.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['nord']
    end
}

I.CharacterTraits.addTrait {
    id = "skaal",
    type = traitType,
    name = "Skaal",
    description = (
        "Skaal are inhabitants of the island of Solstheim, culturally different from other Nords, " ..
        "Skaal believe in dualistic cosmology within monotheistic religion. They feel strong " ..
        "connection to the land and nature, and strive for sustainability. " ..
        "\n" ..
        "\n" ..
        "Adherence to Skaal customs grants bonuses to Athletics, Marksman, Medium Armor, " ..
        "Restoration, Light Armor, Sneak, Willpower (+5), Maximum Magicka (50%) and penalties to " ..
        "Heavy Armor, Unarmored, Mercantile, Enchant, Destruction, Long Blade, Personality, " ..
        "Intelligence (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Skaal")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.unarmored.base   = skills.unarmored.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.destruction.base = skills.destruction.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['nord']
    end
}

I.CharacterTraits.addTrait {
    id = "osternish",
    type = traitType,
    name = "Osternish",
    description = (
        "Ostern are inhabitants of eastern part of High Rock though significant minority can be " ..
        "found all over the province. They cherish their Merish roots and aspire to establish a " ..
        "society based on Elven values. " ..
        "\n" ..
        "\n" ..
        "Adherence to Osternish customs grants bonuses to Illusion, Conjuration, Destruction, " ..
        "Restoration, Mysticism, Enchant, Intelligence (+5), Maximum Magicka (50%) and penalties to " ..
        "Heavy Armor, Medium Armor, Spear, Long Blade, Athletics, Block, Strength, Endurance (-5) " ..
        "to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Osternish")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (
            playerRace == races.breton
            or playerRace == races.reachman
        )
    end
}

I.CharacterTraits.addTrait {
    id = "bayard",
    type = traitType,
    name = "Bayard",
    description = (
        "Bayards are inhabitants of southern part of High Rock. They are the most Imperialized of " ..
        "Breton cultures. " ..
        "\n" ..
        "\n" ..
        "Adherence to Bayard customs grants bonuses to Heavy Armor, Spear, Mercantile, Speechcraft, " ..
        "Security, Light Armor, Personality, Willpower (+5) and penalties to Marksman, Alteration, " ..
        "Acrobatics, Axe, Blunt Weapon, Restoration, Strength, Endurance (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Bayard")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (playerRace == races.breton or playerRace == races.reachman)
    end
}

I.CharacterTraits.addTrait {
    id = "normannish",
    type = traitType,
    name = "Normannish",
    description = (
        "Normen are inhabitants of northern part of High Rock. Isolated from other Breton and " ..
        "Merish influence they reject the Manmeri customs and honor their ancient Nordic and Nedic " ..
        "heritage. " ..
        "\n" ..
        "\n" ..
        "Adherence to Normannish customs grants bonuses to Enchant, Axe, Heavy Armor, Medium Armor, " ..
        "Blunt Weapon, Block, Strength, Endurance (+5) and penalties to Alchemy, Alteration, " ..
        "Conjuration, Illusion, Mysticism, Restoration, Intelligence, Willpower (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Normannish")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.willpower.base    = attrs.willpower.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.restoration.base = skills.restoration.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (
            playerRace == races.breton
            or playerRace == races.reachman
        )
    end
}

I.CharacterTraits.addTrait {
    id = "bjoulsaean",
    type = traitType,
    name = "Bjoulsaean",
    description = (
        "Bjoulsae River Tribes are predominantly Breton tribes of horse nomads dwelling on the " ..
        "plains surrounding Bjoulsae River which forms a border between High Rock and Hammerfell. " ..
        "Redguard tribes are sometimes called Silverhoof Horsemen. " ..
        "\n" ..
        "\n" ..
        "Adherence to Bjoulsaean customs grants bonuses to Light Armor, Athletics, Marksman, Hand- " ..
        "to-hand, Axe, Spear, Agility, Speed (+5) and penalties to Block, Alteration, Conjuration, " ..
        "Illusion, Heavy Armor, Speechcraft, Intelligence, Personality (-5) to those being faithful " ..
        "to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Bjoulsaean")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.block.base       = skills.block.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (
            playerRace == races.breton
            or playerRace == races.reachman
            or playerRace == races.redguard
        )
    end
}

I.CharacterTraits.addTrait {
    id = "reachmannish",
    type = traitType,
    name = "Reachmannish",
    description = (
        "Reachmen are a tribe of humans inhabiting Eastern High Rock and Western Skyrim believed to " ..
        "be related to Bretons. Neither Bretons nor Reachmen acknowledge such relation and the " ..
        "latter are often shunned by other races. " ..
        "\n" ..
        "\n" ..
        "Adherence to Reachmannish customs grants bonuses to Conjuration, Destruction, Alteration, " ..
        "Alchemy, Blunt Weapon, Athletics, Willpower (+5), Maximum Magicka (+50%) and penalties to " ..
        "Illusion, Mysticism, Speechcraft, Mercantile, Security, Enchant, Strength, Personality " ..
        "(-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Reachmannish")

        attrs.strength.base     = attrs.strength.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.security.base    = skills.security.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.enchant.base     = skills.enchant.base - 5
    end,
    checkDisabled = function()
        local playerRace = getRaceId(self)
        return not (
            playerRace == races.breton
            or playerRace == races.reachman
        )
    end
}

I.CharacterTraits.addTrait {
    id = "jovansa",
    type = traitType,
    name = "Jovansa",
    description = (
        "Jovansa which translates to 'those who secure their future' are communities of Khajiits " ..
        "who are hiding their beastfolk appearance and pretend to be Mer. Called Ririnajiit - " ..
        "'compulsive liars' - by other Khajiit they nonetheless shave off their fur and plan " ..
        "conception and birth carefully to make sure the offspring is of Ohmes stock. Eventhough " ..
        "these practices are widely frowned upon, they remain entrenched in regions where attitudes " ..
        "towards Khajiit are hostile such as Morrowind or Valenwood. " ..
        "\n" ..
        "\n" ..
        "Adherence to Jovansa customs grants bonuses to Alchemy, Illusion, Mysticism, Alteration, " ..
        "Restoration, Speechcraft, Willpower (+5), Maximum Magicka (+50%) and penalties to " ..
        "Acrobatics, Athletics, Hand-to-hand, Security, Sneak, Unarmored, Agility, Speed (-5) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Jovansa")

        attrs.agility.base     = attrs.agility.base - 5
        attrs.speed.base       = attrs.speed.base - 5
        skills.security.base   = skills.security.base - 5
        skills.acrobatics.base = skills.acrobatics.base - 5
        skills.sneak.base      = skills.sneak.base - 5
        skills.athletics.base  = skills.athletics.base - 5
        skills.handToHand.base = skills.handToHand.base - 5
        skills.unarmored.base  = skills.unarmored.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end
}

I.CharacterTraits.addTrait {
    id = "nequinal",
    type = traitType,
    name = "Ne Quin-al",
    description = (
        "Ne Quin-al or Anequinans are inhabitants of kingdom of Anequina forming a northern part of " ..
        "Elsweyr Confederacy. For the outsiders, Anequina seems to be a place of uncouth " ..
        "barbarians, for the locals, it is a place of proud warriors. " ..
        "\n" ..
        "\n" ..
        "Adherence to Ne Quin-al customs grants bonuses to Long Blade, Marksman, Heavy Armor, " ..
        "Medium Armor, Axe, Blunt Weapon, Strength, Endurance (+5) and penalties to Security, Short " ..
        "Blade, Sneak, Enchant, Speechcraft, Mercantile, Intelligence, Personality (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Nequinal")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.security.base    = skills.security.base - 5
        skills.shortBlade.base  = skills.shortBlade.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end
}

I.CharacterTraits.addTrait {
    id = "paalatiin",
    type = traitType,
    name = "Pa'alatiin",
    description = (
        "Pa'alatiin or Pellitinians are inhabitants of kingdom of Pellitine forming a southern part " ..
        "of Elsweyr Confederacy. For the outsiders, Pellitine seems to be a place of decadence and " ..
        "depravity, for the locals, it is a place of merchantry and wealth. " ..
        "\n" ..
        "\n" ..
        "Adherence to Pa'alatiin customs grants bonuses to Security, Speechcraft, Mercantile, " ..
        "Unarmored, Sneak, Alchemy, Intelligence, Personality (+5) and penalties to Heavy Armor, " ..
        "Medium Armor, Spear, Axe, Long Blade, Marksman, Strength, Agility (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Paalatiin")

        attrs.agility.base      = attrs.agility.base - 5
        attrs.strength.base     = attrs.strength.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.spear.base       = skills.spear.base - 5
        skills.axe.base         = skills.axe.base - 5
        skills.marksman.base    = skills.marksman.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end
}

I.CharacterTraits.addTrait {
    id = "baandari",
    type = traitType,
    name = "Baandari",
    description = (
        "Baandari are nomadic Khajiit peddler-fortunetellers. They live by tenets of their god - " ..
        "Baan Dar - any item not clearly belonging to someone is an item they can rightfully take. " ..
        "\n" ..
        "\n" ..
        "Adherence to Baandari customs grants bonuses to Security, Speechcraft, Mercantile, " ..
        "Illusion, Sneak, Armorer, Agility, Personality (+5) and penalties to Heavy Armor, Medium " ..
        "Armor, Spear, Axe, Long Blade, Destruction, Strength, Endurance (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Baandari")
    end,
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end
}

I.CharacterTraits.addTrait {
    id = "rimmen",
    type = traitType,
    name = "Rim-Men",
    description = (
        "Rim-Men are mostly human inhabitants of The Rim - region in Elsweyr on the border with " ..
        "Cyrodiil province. They are descendants of Akaviri banished from Cyrodiil by Warlord " ..
        "Attrebus in Second Era. Although their Akaviri bloodline thinned over the years - with " ..
        "traces of Cyrodiilic, Khajiiti, and perhaps even Kamal blood - the old traditions are " ..
        "still celebrated to this day. " ..
        "\n" ..
        "\n" ..
        "Adherence to Rim-Men customs grants bonuses to Long Blade, Short Blade (+5), Resist Fire " ..
        "(25%) and penalties to Blunt Weapon, Axe (-5), Weakness to Frost (25%) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Rimmen")

        skills.bluntWeapon.base = skills.bluntWeapon.base - 5
        skills.axe.base         = skills.axe.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end
}

I.CharacterTraits.addTrait {
    id = "heartlander",
    type = traitType,
    name = "Heartlander",
    description = (
        "Heartlanders are inhabitants of The Heartlands - central part of Cyrodiil province around " ..
        "Lake Rumare and the most lustrious city on Nirn - the Imperial City. Living in a region " ..
        "between Nibenay Valley and Colovian Highlands they combine Nibenese traditions with " ..
        "elements of Colovian culture. " ..
        "\n" ..
        "\n" ..
        "Adherence to Heartlander customs grants bonuses to Short Blade, Unarmored, Mercantile, " ..
        "Security, Mysticism, Sneak, Personality, Speed (+5) and penalties to Long Blade, Blunt " ..
        "Weapon, Block, Light Armor, Acrobatics, Marksman, Willpower, Agility (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Heartlander")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.bluntWeapon.base = skills.bluntWeapon.base - 5
        skills.block.base       = skills.block.base - 5
        skills.marksman.base    = skills.marksman.base - 5
        skills.lightArmor.base  = skills.lightArmor.base - 5
        skills.acrobatics.base  = skills.acrobatics.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['imperial']
    end
}

I.CharacterTraits.addTrait {
    id = "nibenese",
    type = traitType,
    name = "Nibenese",
    description = (
        "Nibenese are inhabitants of Nibenay - eastern part of Cyrodiil province. They are regarded " ..
        "as Cyrodiil's soul: magnanimous, tolerant, and administrative. Nibenese excel in magicka " ..
        "and merchantry. They relish in garish costumes, bizarre tapestries, tattoos, brandings, " ..
        "and elaborate ceremony. " ..
        "\n" ..
        "\n" ..
        "Adherence to Nibenese customs grants bonuses to Destruction, Enchant, Restoration, " ..
        "Conjuration, Mysticism, Mercantile, Intelligence (+5), Maximum Magicka (+50%) and " ..
        "penalties to Long Blade, Hand-to-hand, Spear, Marksman, Blunt Weapon, Block, Strength, " ..
        "Agility (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Nibenese")

        attrs.strength.base     = attrs.strength.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.longBlade.base   = skills.longBlade.base - 5
        skills.handToHand.base  = skills.handToHand.base - 5
        skills.spear.base       = skills.spear.base - 5
        skills.marksman.base    = skills.marksman.base - 5
        skills.bluntWeapon.base = skills.bluntWeapon.base - 5
        skills.block.base       = skills.block.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['imperial']
    end
}

I.CharacterTraits.addTrait {
    id = "colovar",
    type = traitType,
    name = "Colovar",
    description = (
        "Colovari are inhabitants of northern part of Colovia - northwestern part of Cyrodiil " ..
        "province. Main difference between them and Colovians is that Colovari are extremely proud " ..
        "of their Nordic roots and view themselves as more noble people. " ..
        "\n" ..
        "\n" ..
        "Adherence to Colovar customs grants bonuses to Axe, Long Blade, Heavy Armor, Medium Armor, " ..
        "Blunt Weapon, Speechcraft, Strength, Endurance (+5), Resist Frost (25%) and penalties to " ..
        "Sneak, Illusion, Conjuration, Alteration, Destruction, Security, Intelligence, Agility " ..
        "(-5), Weakness to Fire (25%) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Colovar")
        selfSpells:add("mtrCultures_Colovar2")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.security.base    = skills.security.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['imperial']
    end
}

I.CharacterTraits.addTrait {
    id = "colovian",
    type = traitType,
    name = "Colovian",
    description = (
        "Colovians are inhabitants of Colovia - western part of Cyrodiil province. They are " ..
        "respected as Cyrodiil's iron hand: firm, unwavering, and ever-vigilant. Disinclined to " ..
        "magic and industry they prefer bloody engagement and plunder. Colovians are uncomplicated, " ..
        "self-sufficient, hearty, and extremely loyal to one another. They favor simple clothing " ..
        "over extravagant costumes. " ..
        "\n" ..
        "\n" ..
        "Adherence to Colovian customs grants bonuses to Axe, Block, Heavy Armor, Medium Armor, " ..
        "Athletics, Spear, Strength, Endurance (+5) and penalties to Mercantile, Illusion, " ..
        "Conjuration, Alteration, Destruction, Mysticism, Intelligence, Willpower (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Colovian")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.willpower.base    = attrs.willpower.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.destruction.base = skills.destruction.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['imperial']
    end
}
