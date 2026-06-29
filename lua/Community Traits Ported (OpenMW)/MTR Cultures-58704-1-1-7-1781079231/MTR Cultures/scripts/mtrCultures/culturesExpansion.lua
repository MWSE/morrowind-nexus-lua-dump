local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

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

local function getRaceId(npc)
    ---@diagnostic disable-next-line: undefined-field
    return npc.type.records[npc.recordId].race
end

deps.checkAll("MTR Cultures Expansion", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

I.CharacterTraits.addTrait {
    id = "cantemiric",
    type = traitType,
    name = "Cantemiric",
    description = (
        "Cantemiric Velothi are a group of Chimer and later Dunmer thought to be extinct due to " ..
        "epidemic of Knahaten Flu. They lived on the eastern coast of Argonia and possibly were " ..
        "worshippers of Aedric Divines, however such description is dubious as rejection of Aedric " ..
        "reverence was behind emergence of Chimer as a separate race. " ..
        "\n" ..
        "\n" ..
        "Adherence to Cantemiric customs grants bonuses to Poison Resistance, Maximum Magicka (50%) " ..
        "and penalties of Weakness to Fire, Weakness to Common Disease (100%) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Cantemiric")
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "ashabah",
    type = traitType,
    name = "Ash'abah",
    description = (
        "Ash'abah are secretive Redguard tribe who disregard religious taboo for the purpose of " ..
        "fighting necromancy. " ..
        "\n" ..
        "\n" ..
        "Adherence to Ash'abah customs grants bonuses to Restoration (+5), Maximum Magicka (50%) " ..
        "and penalties to Conjuration, Personality (-5) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Ashabah")

        attrs.personality.base  = attrs.personality.base - 5
        skills.conjuration.base = skills.conjuration.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "corelanyai",
    type = traitType,
    name = "Corelanyai",
    description = (
        "Corelanya are a clan of Altmer Daedra worshippers thought to be extinct. They colonized " ..
        "western part of what is now called Hammerfell, but were ultimately defeated by Redguards. " ..
        "\n" ..
        "\n" ..
        "Adherence to Corelanyai customs grants bonuses to Mercantile, Conjuration (+5), Resist " ..
        "Fire (50%) and penalties to Endurance (-5), Weakness to Frost (-50%) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Corelanyai")
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['high elf']
    end
}

I.CharacterTraits.addTrait {
    id = "oshornim",
    type = traitType,
    name = "Osh Ornim",
    description = (
        "Osh Ornim - 'Iron Orcs' - are Orsimer living in the Dragontail mountains of Hammerfell. " ..
        "It's a society of miners, smiths, and brutal warriors. " ..
        "\n" ..
        "\n" ..
        "Adherence to Osh Ornim customs grants bonuses to Armorer, Axe, Heavy Armor, Hand-to-hand, " ..
        "Blunt Weapon, Enchant, Strength, Endurance (+5) and penalties to Sneak, Speechcraft, " ..
        "Illusion, Mercantile, Block, Security, Intelligence, Personality (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Oshornim")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
        skills.sneak.base       = skills.sneak.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.mercantile.base  = skills.mercantile.base - 5
        skills.block.base       = skills.block.base - 5
        skills.security.base    = skills.security.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "kushragornim",
    type = traitType,
    name = "Kushrag Ornim",
    description = (
        "Kushrag Ornim - 'Sea Orcs' - are Orsimer said to be living on various islands on the " ..
        "western coast of Tamriel. One of the biggest fears of Eltheric Ocean seafarers is meeting " ..
        "a Sea Orc vessel. Some people believe that Kushrag Ornim are descendandts of Lefthanded " ..
        "Elves of Yokuda. " ..
        "\n" ..
        "\n" ..
        "Adherence to Kushrag Ornim customs grants bonuses to Light Armor, Long Blade, Conjuration, " ..
        "Agility, Endurance (+5), Resist Shock (25%), and penalties to Heavy Armor, Armorer, Block, " ..
        "Intelligence, Personality (-5), Weakness to Frost (-25%) to those being faithful to their " ..
        "culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Kushragornim")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.block.base       = skills.block.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "nelgragornim",
    type = traitType,
    name = "Nelgrag Ornim",
    description = (
        "Nelgrag Ornim - 'Swamp Orcs' - are Orsimer said to be living in parts of Black Marsh. " ..
        "These elusive people are rarely seen and often mistook for a rare subrace of Argonians. " ..
        "\n" ..
        "\n" ..
        "Adherence to Nelgrag Ornim customs grants bonuses to Alchemy, Illusion, Unarmored, Spear " ..
        "(+5), Maximum Magicka (50%), Resist Poison, Resist Common Disease (25%), and penalties to " ..
        "Heavy Armor, Armorer, Block, Medium Armor, Personality (-5), Weakness to Frost (-50%) to " ..
        "those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Nelgragornim")

        attrs.personality.base  = attrs.personality.base - 5
        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.mediumArmor.base = skills.mediumArmor.base - 5
        skills.block.base       = skills.block.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "ugrashornim",
    type = traitType,
    name = "Ugrash Ornim",
    description = (
        "Ugrash Ornim - 'Snow Orcs' - are Orsimer living in desolate parts of Skyrim. They are " ..
        "isoliationistic, but peaceful people. " ..
        "\n" ..
        "\n" ..
        "Adherence to Ugrash Ornim customs grants bonuses to Light Armor, Axe, Blunt Weapon, " ..
        "Destruction (+5), Resist Frost (25%) and penalties to Heavy Armor, Armorer, Block, " ..
        "Speechcraft (-5), Weakness to Fire (-25%) to those being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Ugrashornim")

        skills.heavyArmor.base  = skills.heavyArmor.base - 5
        skills.speechcraft.base = skills.speechcraft.base - 5
        skills.armorer.base     = skills.armorer.base - 5
        skills.block.base       = skills.block.base - 5
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "cosmopolitan",
    type = traitType,
    name = "-Cosmopolitan-",
    description = (
        "Cosmopolitan is a generic culture whose followers see whole of Nirn as a single community. " ..
        "\n" ..
        "\n" ..
        "Adherence to Cosmopolitan customs grants bonuses to Sneak, Mercantile, Speechcraft, " ..
        "Security, Unarmored, Mysticism, Personality, Speed (+5) and penalties to Heavy Armor, " ..
        "Spear, Armorer, Axe, Alchemy, Enchant, Strength, Willpower (-5) to those being faithful to " ..
        "their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Cosmopolitan")

        attrs.strength.base    = attrs.strength.base - 5
        attrs.willpower.base   = attrs.willpower.base - 5
        skills.heavyArmor.base = skills.heavyArmor.base - 5
        skills.armorer.base    = skills.armorer.base - 5
        skills.spear.base      = skills.spear.base - 5
        skills.axe.base        = skills.axe.base - 5
        skills.alchemy.base    = skills.alchemy.base - 5
        skills.enchant.base    = skills.enchant.base - 5
    end,
}

I.CharacterTraits.addTrait {
    id = "magocratic",
    type = traitType,
    name = "-Magocratic-",
    description = (
        "Magocratic is a generic culture whose followers see pursuing knowledge as a necessary part " ..
        "of life. " ..
        "\n" ..
        "\n" ..
        "Adherence to Magocratic customs grants bonuses to Illusion, Alchemy, Enchant, Alteration, " ..
        "Destruction, Restoration, Intelligence (+5), Maximum Magicka (50%) and penalties to Heavy " ..
        "Armor, Medium Armor, Spear, Axe, Athletics, Marksman, Strength, Endurance (-5) to those " ..
        "being faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Magocratic")

        attrs.strength.base = attrs.strength.base - 5
    end,
}

I.CharacterTraits.addTrait {
    id = "martial",
    type = traitType,
    name = "-Martial-",
    description = (
        "Martial is a generic culture whose followers see warfare as a necessary part of life and " ..
        "way to achieve honor, glory, and valor. " ..
        "\n" ..
        "\n" ..
        "Adherence to Martial customs grants bonuses to Heavy Armor, Medium Armor, Spear, Axe, " ..
        "Blunt Weapon, Long Blade, Strength, Endurance (+5) and penalties to Mysticism, Alteration, " ..
        "Enchant, Alchemy, Illusion, Restoration, Personality, Intelligence (-5) to those being " ..
        "faithful to their culture. "
    ),
    doOnce = function()
        selfSpells:add("mtrCultures_Martial")

        attrs.personality.base  = attrs.personality.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        skills.mysticism.base   = skills.mysticism.base - 5
        skills.alteration.base  = skills.alteration.base - 5
        skills.enchant.base     = skills.enchant.base - 5
        skills.alchemy.base     = skills.alchemy.base - 5
        skills.illusion.base    = skills.illusion.base - 5
        skills.restoration.base = skills.restoration.base - 5
    end,
}
