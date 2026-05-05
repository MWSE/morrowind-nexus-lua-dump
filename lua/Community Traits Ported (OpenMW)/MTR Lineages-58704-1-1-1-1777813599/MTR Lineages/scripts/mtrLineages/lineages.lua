local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local selfSkills = self.type.stats.skills
local selfAttrs = self.type.stats.attributes

local deps = require("scripts.mtrLineages.utils.dependencies")
local raceCheckers = require("scripts.mtrLineages.utils.raceGroups")
local traitType = require("scripts.mtrLineages.utils.traitTypes").lineage
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

deps.checkAll("MTR Lineages", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

I.CharacterTraits.addTrait {
    id = "spriggan",
    type = traitType,
    name = "Spriggan",
    description = (
        "Spriggans are a race of humanoid tree-spirits. " ..
        "\n" ..
        "\n" ..
        "Admixture of Spriggan blood flowing in your veins grants you ability to regenerate health " ..
        "at a cost of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Restore Health (1p) and Weakness to Fire (100%) are traits of those with Spriggan " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Spriggan")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "nymph",
    type = traitType,
    name = "Nymph",
    description = (
        "Nymphs are a race of humanoid fae species. " ..
        "\n" ..
        "\n" ..
        "Admixture of Nymph blood flowing in your veins grants you resistance to normal weapons at " ..
        "a cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Resist Normal Weapons (25%) and penalty to Personality (-10) are traits of those with " ..
        "Nymph ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Nymph")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "dragon",
    type = traitType,
    name = "Dragon",
    description = (
        "Dragons are intelligent race of large flying reptiles. " ..
        "\n" ..
        "\n" ..
        "Admixture of Dragon blood flowing in your veins grants you bonus to intelligence at a cost " ..
        "of penalty to speed. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+10) and penalty to Speed (-10) are traits of those with Dragon " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Dragon")

        attrs.speed.base = attrs.speed.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "aureal",
    type = traitType,
    name = "Aureal",
    description = (
        "Aureals, also known as Golden Saints, are a humanoid race of golden-skinned daedra usually " ..
        "serving Sheogorath. " ..
        "\n" ..
        "\n" ..
        "Admixture of Aureal blood flowing in your veins grants you ability to reflect spells at a " ..
        "cost of weakness to poison. " ..
        "\n" ..
        "\n" ..
        "Reflect (5%) and Weakness to Poison (50%) are traits of those with Aureal ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Aureal")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "auroran",
    type = traitType,
    name = "Auroran",
    description = (
        "Aurorans are a humanoid race of daedra serving Meridia. " ..
        "\n" ..
        "\n" ..
        "Admixture of Auroran blood flowing in your veins grants you resistance to shock at a cost " ..
        "of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Resist Shock (25%) and Weakness to Fire (25%) are traits of those with Auroran ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Auroran")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "dremora",
    type = traitType,
    name = "Dremora",
    description = (
        "Dremoras are a humanoid race of daedra serving Mehrunes Dagon. " ..
        "\n" ..
        "\n" ..
        "Admixture of Dremora blood flowing in your veins grants you bonus to willpower at a cost " ..
        "of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Willpower (+10) and penalty to Personality (-10) are traits of those with Dremora " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Dremora")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "herne",
    type = traitType,
    name = "Herne",
    description = (
        "Herne are a humanoid race of daedra related to Skaafins, Scamps and Morphoids. They " ..
        "usually serve Clavicus Vile and Mehrunes Dagon. " ..
        "\n" ..
        "\n" ..
        "Admixture of Herne blood flowing in your veins grants you bonus to speed at a cost of " ..
        "penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Bonus to Speed (+10) and penalty to Intelligence (-10) are traits of those with Herne " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Herne")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "mazken",
    type = traitType,
    name = "Mazken",
    description = (
        "Mazkens, also known as Dark Seducers, are a humanoid race of purple-skinned daedra usually " ..
        "serving Sheogorath. " ..
        "\n" ..
        "\n" ..
        "Admixture of Mazken blood flowing in your veins grants you ability to absorb spells at a " ..
        "cost of weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Spell Absorption (5%) and Weakness to Frost (75%) are traits of those with Mazken " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Mazken")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "xivilai",
    type = traitType,
    name = "Xivilai",
    description = (
        "Xivilai are a humanoid race of gray-skinned daedra serving Mehrunes Dagon and Molag Bal. " ..
        "\n" ..
        "\n" ..
        "Admixture of Xivilai blood flowing in your veins grants you ability to absorb spells and " ..
        "resist fire at a cost of inability to generate magicka and weakness to shock. " ..
        "\n" ..
        "\n" ..
        "Spell Absorption (25%), Resist Fire (25%), Stunted Magicka and Weakness to Shock (50%) are " ..
        "traits of those with Xivilai ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Xivilai")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "akaviri",
    type = traitType,
    name = "Akaviri",
    description = (
        "Akaviri or Men of Akavir are a human race native to Akavir. " ..
        "\n" ..
        "\n" ..
        "Admixture of Akaviri blood flowing in your veins grants you bonus to long blade at a cost " ..
        "of penalty to blunt weapon. " ..
        "\n" ..
        "\n" ..
        "Bonus to Long Blade (+10) and penalty to Blunt Weapon (-10) are traits of those with " ..
        "Akaviri ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Akaviri")

        skills.bluntWeapon.base = skills.bluntWeapon.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "tsaesci",
    type = traitType,
    name = "Tsaesci",
    description = (
        "Tsaesci are a serpent-folk of Akavir. " ..
        "\n" ..
        "\n" ..
        "Admixture of Tsaesci blood flowing in your veins grants you bonus to long blade at a cost " ..
        "of penalty to block. " ..
        "\n" ..
        "\n" ..
        "Bonus to Long Blade (+10) and penalty to Block (-10) are traits of those with Tsaesci " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Tsaesci")

        skills.block.base = skills.block.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "tangmo",
    type = traitType,
    name = "Tang Mo",
    description = (
        "Tang Mo are a monkey-folk of Akavir. " ..
        "\n" ..
        "\n" ..
        "Admixture of Tang Mo blood flowing in your veins grants you bonus to agility at a cost of " ..
        "penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+10) and penalty to Intelligence (-10) are traits of those with Tang Mo " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_TangMo")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "kamal",
    type = traitType,
    name = "Kamal",
    description = (
        "Kamal are a snow demon race of Akavir. " ..
        "\n" ..
        "\n" ..
        "Admixture of Kamal blood flowing in your veins grants you ability to resist frost at a " ..
        "cost of weakness to non-elemental magicka. " ..
        "\n" ..
        "\n" ..
        "Resist Frost (25%) and Weakness to Magicka (25%) are traits of those with Kamal ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Kamal")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "kapotun",
    type = traitType,
    name = "Ka Po' Tun",
    description = (
        "Ka Po' Tun are a tiger-dragon-folk of Akavir. " ..
        "\n" ..
        "\n" ..
        "Admixture of Ka Po' Tun blood flowing in your veins grants you bonus to strength at a cost " ..
        "of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+10) and penalty to Personality (-10) are traits of those with Ka Po' " ..
        "Tun ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_KaPoTun")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "sload",
    type = traitType,
    name = "Sload",
    description = (
        "Sload are a slug-like beast race from Coral Kingdoms of Thras south-west of Tamriel. " ..
        "\n" ..
        "\n" ..
        "Admixture of Sload blood flowing in your veins grants you bonus to conjuration and alchemy " ..
        "at a cost of penalty to speed. " ..
        "\n" ..
        "\n" ..
        "Bonus to Conjuration (+10), bonus to Alchemy (+10) and penalty to Speed (-10) are traits " ..
        "of those with Sload ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Sload")

        attrs.speed.base = attrs.speed.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "minotaur",
    type = traitType,
    name = "Minotaur",
    description = (
        "Minotaurs are a beast race native to Cyrodiil with man body and head of a bull. " ..
        "\n" ..
        "\n" ..
        "Admixture of Minotaur blood flowing in your veins grants you bonus to willpower at a cost " ..
        "of penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Bonus to Willpower (+10) and penalty to Intelligence (-10) are traits of those with " ..
        "Minotaur ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Minotaur")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "lilmothiit",
    type = traitType,
    name = "Lilmothiit",
    description = (
        "Lilmothiit were a nomadic fox-like beast race native to Black Marsh who most likely went " ..
        "extinct following the Knahaten Flu epidemic. " ..
        "\n" ..
        "\n" ..
        "Admixture of Lilmothiit blood flowing in your veins grants you bonus to agility at a cost " ..
        "of weakness to disease. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+10) and Weakness to Common Disease (50%) are traits of those with " ..
        "Lilmothiit ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Lilmothiit")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "lamia",
    type = traitType,
    name = "Lamia",
    description = (
        "Lamias are a beast race of aquatic snakes. " ..
        "\n" ..
        "\n" ..
        "Admixture of Lamia blood flowing in your veins grants you ability to swim faster at a cost " ..
        "of weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Swift Swim (25p) and Weakness to Frost (25%) are traits of those with Lamia ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Lamia")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "imga",
    type = traitType,
    name = "Imga",
    description = (
        "Imgas are a beast race of apes native to Valenwood. " ..
        "\n" ..
        "\n" ..
        "Admixture of Imga blood flowing in your veins grants you bonus to agility at a cost of " ..
        "penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+10) and penalty to Personality (-10) are traits of those with Imga " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Imga")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "harpy",
    type = traitType,
    name = "Harpy",
    description = (
        "Harpies are a beast race native to Iliac Bay area with man body and bird wings. " ..
        "\n" ..
        "\n" ..
        "Admixture of Harpy blood flowing in your veins grants you bonus to agility at a cost of " ..
        "penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+10) and penalty to Intelligence (-10) are traits of those with Harpy " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Harpy")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "hagraven",
    type = traitType,
    name = "Hagraven",
    description = (
        "Hagravens are witches who undergone a ritual to access powerful magicka. " ..
        "\n" ..
        "\n" ..
        "Admixture of Hagraven blood flowing in your veins grants you resistance to non-elemental " ..
        "magicka at a cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Resist Magicka (25%) and penalty to Personality (-10) are traits of those with Hagraven " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Hagraven")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "grummite",
    type = traitType,
    name = "Grummite",
    description = (
        "Grummites are a frog-like beast race native to the Shivering Isles. " ..
        "\n" ..
        "\n" ..
        "Admixture of Grummite blood flowing in your veins grants you resistance to frost at a cost " ..
        "of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Resist Frost (25%) and Weakness to Fire (25%) are traits of those with Grummite ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Grummite")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "gremlin",
    type = traitType,
    name = "Gremlin",
    description = (
        "Gremlins are a beast race related to, and often living alongside, Goblins, also known as " ..
        "Orc-rats. " ..
        "\n" ..
        "\n" ..
        "Admixture of Gremlin blood flowing in your veins grants you bonus to agility at a cost of " ..
        "weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+10) and Weakness to Frost (25%) are traits of those with Gremlin " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Gremlin")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "riekling",
    type = traitType,
    name = "Riekling",
    description = (
        "Rieklings are a blue-skinned beast race related to Goblins. " ..
        "\n" ..
        "\n" ..
        "Admixture of Riekling blood flowing in your veins grants you resistance to frost at a cost " ..
        "of penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Resist Frost (25%) and penalty to Intelligence (-10) are traits of those with Riekling " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Riekling")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "ogre",
    type = traitType,
    name = "Ogre",
    description = (
        "Ogres are a beast race worshipping Malacath. " ..
        "\n" ..
        "\n" ..
        "Admixture of Ogre blood flowing in your veins grants you bonus to strength at a cost of " ..
        "weakness to poison. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+10) and Weakness to Poison (25%) are traits of those with Ogre " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Ogre")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "goblin",
    type = traitType,
    name = "Goblin",
    description = (
        "Goblins are a green-skinned beast race. " ..
        "\n" ..
        "\n" ..
        "Admixture of Goblin blood flowing in your veins grants you resistance to fire at a cost of " ..
        "weakness to non-elemental magicka. " ..
        "\n" ..
        "\n" ..
        "Resist Fire (25%) and Weakness to Magicka (25%) are traits of those with Goblin ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Goblin")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "giant",
    type = traitType,
    name = "Giant",
    description = (
        "Giants are a very tall humanoid race. " ..
        "\n" ..
        "\n" ..
        "Admixture of Giant blood flowing in your veins grants you bonus to strength at a cost of " ..
        "penalty to agility. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+10) and penalty to Agility (-10) are traits of those with Giant " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Giant")

        attrs.agility.base = attrs.agility.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "dreugh",
    type = traitType,
    name = "Dreugh",
    description = (
        "Dreughs are an octopus-like beast race. " ..
        "\n" ..
        "\n" ..
        "Admixture of Dreugh blood flowing in your veins grants you ability to swim faster at a " ..
        "cost of weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Swift Swim (25p) and Weakness to Frost (25%) are traits of those with Dreugh ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Dreugh")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "centaur",
    type = traitType,
    name = "Centaur",
    description = (
        "Centaurs are a beast race with horse lower-body and head and torso of a human. " ..
        "\n" ..
        "\n" ..
        "Admixture of Centaur blood flowing in your veins grants you bonus to speed at a cost of " ..
        "penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Speed (+10) and penalty to Personality (-10) are traits of those with Centaur " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Centaur")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "sinistralmer",
    type = traitType,
    name = "Sinistral Mer",
    description = (
        "Sinistral Mer, also known as Lefthanded Elves, were an elven race of sunken continent of " ..
        "Yokuda. " ..
        "\n" ..
        "\n" ..
        "Admixture of Sinistral Mer blood flowing in your veins grants you bonus to long blade at a " ..
        "cost of penalty to armorer. " ..
        "\n" ..
        "\n" ..
        "Bonus to Long Blade (+10) and penalty to Armorer (-10) are traits of those with Sinistral " ..
        "Mer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Sinistral")

        skills.armorer.base = skills.armorer.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "maormer",
    type = traitType,
    name = "Maormer",
    description = (
        "Maormer, also known as Sea Elves, are an elven race living in Pyandonea. " ..
        "\n" ..
        "\n" ..
        "Admixture of Maormer blood flowing in your veins grants you resistance to shock at a cost " ..
        "of weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Resist Shock (25%) and Weakness to Frost (25%) are traits of those with Maormer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Maormer")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "falmer",
    type = traitType,
    name = "Falmer",
    description = (
        "Falmer, also known as Snow Elves, are an almost extinct elven race living in cold, remote " ..
        "areas. " ..
        "\n" ..
        "\n" ..
        "Admixture of Falmer blood flowing in your veins grants you resistance to frost at a cost " ..
        "of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Resist Frost (25%) and Weakness to Fire (25%) are traits of those with Falmer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Falmer")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "dwemer",
    type = traitType,
    name = "Dwemer",
    description = (
        "Dwemer, also known as Dwarves and Deep Elves, were an elven race living in Morrowind and " ..
        "Hammerfell. " ..
        "\n" ..
        "\n" ..
        "Admixture of Dwemer blood flowing in your veins grants you bonus to intelligence, " ..
        "enchanting and armorer at a cost of penalty to personality and luck. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+10), bonus to Enchant (+10), bonus to Armorer (+10), penalty to " ..
        "Personality (-10) and Luck (-10) are traits of those with Dwemer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Dwemer")

        attrs.luck.base        = attrs.luck.base - 10
        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "ayleid",
    type = traitType,
    name = "Ayleid",
    description = (
        "Ayleids, also known as Wild Elves, were an elven race which created an empire in Cyrodiil. " ..
        "\n" ..
        "\n" ..
        "Admixture of Ayleid blood flowing in your veins grants you bonus to conjuration, armorer, " ..
        "enchanting, marksman, alteration and block at a cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Conjuration (+5), bonus to Armorer (+5), bonus to Enchant (+5), bonus to Marksman " ..
        "(+5), bonus to Alteration (+5), bonus to Block (+5) and penalty to Personality (-15) are " ..
        "traits of those with Ayleid ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Ayleid")

        attrs.personality.base = attrs.personality.base - 15
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "yespest",
    type = traitType,
    name = "Yespest",
    description = (
        "Yespest were a man tribe native to Black Marsh who most likely went extinct following the " ..
        "Knahaten Flu epidemic. " ..
        "\n" ..
        "\n" ..
        "Admixture of Yespest blood flowing in your veins grants you bonus to endurance at a cost " ..
        "of weakness to disease. " ..
        "\n" ..
        "\n" ..
        "Bonus to Endurance (+10) and Weakness to Common Disease (50%) are traits of those with " ..
        "Yespest ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Yespest")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "rontha",
    type = traitType,
    name = "Rontha",
    description = (
        "Rontha were an early man tribe of witch-hunters and spell-drinkers who inhabited western " ..
        "Morrowind. " ..
        "\n" ..
        "\n" ..
        "Admixture of Rontha blood flowing in your veins grants you ability to absorb spells at a " ..
        "cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Spell Absorption (5%) and penalty to Personality (-15) are traits of those with Rontha " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Rontha")

        attrs.personality.base = attrs.personality.base - 15
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "reachmen",
    type = traitType,
    name = "Reachmen",
    description = (
        "Reachmen are a tribe of humans inhabiting Eastern High Rock and Western Skyrim believed to " ..
        "be related to Bretons. " ..
        "\n" ..
        "\n" ..
        "Admixture of Reachmen blood flowing in your veins grants you bonus to willpower at a cost " ..
        "of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Willpower (+10) and penalty to Personality (-10) are traits of those with " ..
        "Reachmen ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Reachmen")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "perena",
    type = traitType,
    name = "Perena",
    description = (
        "Perena were an early man tribe practicing observation of the stars living in Cyrodiil and " ..
        "Hammerfell. " ..
        "\n" ..
        "\n" ..
        "Admixture of Perena blood flowing in your veins grants you additional magicka at a cost of " ..
        "weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Fortify Maximum Magicka (10%) and Weakness to Frost (25%) are traits of those with Perena " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Perena")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "orma",
    type = traitType,
    name = "Orma",
    description = (
        "Orma were a man tribe native to Black Marsh who were born without eyes. " ..
        "\n" ..
        "\n" ..
        "Admixture of Orma blood flowing in your veins grants you heightened senses at a cost of " ..
        "weaker sight. " ..
        "\n" ..
        "\n" ..
        "Detect Animal (150p), Detect Enchantment (150p), Detect Key (150p) and Blind (50%) are " ..
        "traits of those with Orma ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Orma")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "nede",
    type = traitType,
    name = "Nede",
    description = (
        "Nedes were a man tribe or group of tribes inhabiting Tamriel in early eras./n/nAdmixture " ..
        "of Nede blood flowing in your veins grants you resistance to non-elemental magicka at a " ..
        "cost of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Resist Magicka (25%) and Weakness to Fire (25%) are traits of those with Nede ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Nede")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "menofge",
    type = traitType,
    name = "Men-of-Ge",
    description = (
        "Men-of-Ge were an early man tribe who were wiped out by the Ayleids. " ..
        "\n" ..
        "\n" ..
        "Admixture of Men-of-Ge blood flowing in your veins grants you bonus to endurance at a cost " ..
        "of penalty to luck. " ..
        "\n" ..
        "\n" ..
        "Bonus to Endurance (+10) and penalty to Luck (-10) are traits of those with Men-of-Ge " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Ge")

        attrs.luck.base = attrs.luck.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "kothringi",
    type = traitType,
    name = "Kothringi",
    description = (
        "Kothringi were a tribe of silver-skinned man native to Black Marsh who most likely went " ..
        "extinct following Knahaten Flu epidemic. They were knows as avid sailors. " ..
        "\n" ..
        "\n" ..
        "Admixture of Kothringi blood flowing in your veins grants you bonus to unarmored, " ..
        "resistance to poison and resistance to shock at a cost of penalty to heavy armor and " ..
        "weakness to disease. " ..
        "\n" ..
        "\n" ..
        "Bonus to Unarmored (+10), Resist Poison (25%), Resist Shock (25%), penalty to Heavy Armor " ..
        "(-10) and Weakness to Common Diseases (50%) are traits of those with Kothringi ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Kothringi")

        skills.heavyArmor.base = skills.heavyArmor.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "keptu",
    type = traitType,
    name = "Keptu",
    description = (
        "Keptu were a tribe of early man inhabiting Hammerfell. " ..
        "\n" ..
        "\n" ..
        "Admixture of Keptu blood flowing in your veins grants you bonus to armorer and enchanting " ..
        "at a cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Armorer (+10), bonus to Enchant (+10) and penalty to Personality (-10) are traits " ..
        "of those with Keptu ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Keptu")

        attrs.personality.base = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "horwalli",
    type = traitType,
    name = "Horwalli",
    description = (
        "Horwalli were a man tribe native to Black Marsh who most likely went extinct following the " ..
        "Knahaten Flu epidemic. " ..
        "\n" ..
        "\n" ..
        "Admixture of Horwalli blood flowing in your veins grants you bonus to spear at a cost of " ..
        "weakness to disease. " ..
        "\n" ..
        "\n" ..
        "Bonus to Spear (+20) and Weakness to Common Disease (50%) are traits of those with " ..
        "Horwalli ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Horwalli")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "duraki",
    type = traitType,
    name = "Duraki",
    description = (
        "Duraki were a tribe of early man living in Hammerfell. " ..
        "\n" ..
        "\n" ..
        "Admixture of Duraki blood flowing in your veins grants you bonus to conjuration and " ..
        "mysticism at a cost of penalty to luck. " ..
        "\n" ..
        "\n" ..
        "Bonus to Conjuration (+10), bonus to Mysticism (+10) and penalty to Luck (-10) are traits " ..
        "of those with Duraki ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Duraki")

        attrs.luck.base = attrs.luck.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "algemha",
    type = traitType,
    name = "Al-Gemha",
    description = (
        "Al-Gemha were an early tribe of martial man living in western Cyrodiil. " ..
        "\n" ..
        "\n" ..
        "Admixture of Al-Gemha blood flowing in your veins grants you bonus to endurance at a cost " ..
        "of penalty to willpower. " ..
        "\n" ..
        "\n" ..
        "Bonus to Endurance (+10) and penalty to Willpower (-10) are traits of those with Al-Gemha " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_AlGemha")

        attrs.willpower.base = attrs.willpower.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "alhared",
    type = traitType,
    name = "Al-Hared",
    description = (
        "Al-Hared were an early tribe of shamanistic man living in eastern Cyrodiil. " ..
        "\n" ..
        "\n" ..
        "Admixture of Al-Hared blood flowing in your veins grants you bonus to willpower and spear " ..
        "at a cost of penalty to endurance. " ..
        "\n" ..
        "\n" ..
        "Bonus to Willpower (+5), bonus to Spear (+10) and penalty to Endurance (-10) are traits of " ..
        "those with Al-Hared ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_AlHared")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "clannfear",
    type = traitType,
    name = "Clannfear",
    description = (
        "Clannfear are a race of bipedal lizarlike daedra. " ..
        "\n" ..
        "\n" ..
        "Admixture of Clannfear blood flowing in your veins grants you resistance to fire at a cost " ..
        "of weakness to shock. " ..
        "\n" ..
        "\n" ..
        "Resist Fire (25%) and Weakness to Shock (25%) are traits of those with Clannfear ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Clannfear")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "daedroth",
    type = traitType,
    name = "Daedroth",
    description = (
        "Daedroths are a race of bipedal crocodile-like daedra serving Molag Bal and Mehrunes " ..
        "Dagon. " ..
        "\n" ..
        "\n" ..
        "Admixture of Daedroth blood flowing in your veins grants you resistance to normal weapons " ..
        "at a cost of weakness to shock. " ..
        "\n" ..
        "\n" ..
        "Resist Normal Weapons (25%) and Weakness to Shock (25%) are traits of those with Daedroth " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Daedroth")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "grahl",
    type = traitType,
    name = "Grahl",
    description = (
        "Grahls are a race of ice trolls. " ..
        "\n" ..
        "\n" ..
        "Admixture of Grahl blood flowing in your veins grants you resistance to frost at a cost of " ..
        "weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Resist Frost (25%) and Weakness to Fire (25%) are traits of those with Grahl ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Grahl")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "harvester",
    type = traitType,
    name = "Harvester",
    description = (
        "Harvesters are a race of four-armed snakelike daedra serving Molag Bal. " ..
        "\n" ..
        "\n" ..
        "Admixture of Harvester blood flowing in your veins grants you bonus to conjuration and " ..
        "illusion at a cost of penalty to long blade and axe. " ..
        "\n" ..
        "\n" ..
        "Bonus to Conjuration (+10), bonus to Illusion (+10), penalty to Long Blade (-10) and " ..
        "penalty to Axe (-10) are traits of those with Harvester ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Harvester")

        skills.longBlade.base = skills.longBlade.base - 10
        skills.axe.base       = skills.axe.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "hunger",
    type = traitType,
    name = "Hunger",
    description = (
        "Hungers are a race of daedra serving Boethiah. " ..
        "\n" ..
        "\n" ..
        "Admixture of Hunger blood flowing in your veins grants you bonus to destruction at a cost " ..
        "of penalty to restoration. " ..
        "\n" ..
        "\n" ..
        "Bonus to Destruction (+10) and penalty to Restoration (-10) are traits of those with " ..
        "Hunger ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Hunger")

        skills.restoration.base = skills.restoration.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "imp",
    type = traitType,
    name = "Imp",
    description = (
        "Imps are a race of small, winged humanoids of potentially daedric origin. " ..
        "\n" ..
        "\n" ..
        "Admixture of Imp blood flowing in your veins grants you ability to detect animals at a " ..
        "cost of penalty to strength. " ..
        "\n" ..
        "\n" ..
        "Detect Animal (150p) and penalty to Strength (-10) are traits of those with Imp ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Imp")

        attrs.strength.base = attrs.strength.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "ogrim",
    type = traitType,
    name = "Ogrim",
    description = (
        "Ogrims are a race of daedra serving Malacath. " ..
        "\n" ..
        "\n" ..
        "Admixture of Ogrim blood flowing in your veins grants you ability to regenerate health at " ..
        "a cost of penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Restore Health (1p) and penalty to Intelligence (-20) are traits of those with Ogrim " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Ogrim")

        attrs.intelligence.base = attrs.intelligence.base - 20
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "troll",
    type = traitType,
    name = "Troll",
    description = (
        "Trolls are a race of ape-like humanoids. " ..
        "\n" ..
        "\n" ..
        "Admixture of Troll blood flowing in your veins grants you ability to regenerate health and " ..
        "bonus to speed at a cost of penalty to intelligence and weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Restore Health (1p), bonus to Speed (+10), Weakness to Fire (100%) and penalty to " ..
        "Intelligence (-10) are traits of those with Troll ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Troll")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "vermai",
    type = traitType,
    name = "Vermai",
    description = (
        "Vermai are a race of thoughtless daedra. " ..
        "\n" ..
        "\n" ..
        "Admixture of Vermai blood flowing in your veins grants you bonus to strength, bonus to " ..
        "willpower and bonus to endurance at a cost of penalty to intelligence and penalty to " ..
        "personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+20), bonus to Willpower (+15), bonus to Endurance (+15), penalty to " ..
        "Intelligence (-25) and penalty to Personality (-25) are traits of those with Vermai " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Vermai")

        attrs.intelligence.base = attrs.intelligence.base - 25
        attrs.personality.base  = attrs.personality.base - 25
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "wingedtwilight",
    type = traitType,
    name = "Winged Twilight",
    description = (
        "Winged Twilights are a race of purple-skinned, winged, harpy-like daedra serving Azura. " ..
        "\n" ..
        "\n" ..
        "Admixture of Winged Twilight blood flowing in your veins grants you ability to reflect " ..
        "spells at a cost of penalty to personality. " ..
        "\n" ..
        "\n" ..
        "Reflect (5%) and penalty to Personality (-20) are traits of those with Winged Twilight " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_WingedTwilight")

        attrs.personality.base = attrs.personality.base - 20
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "flameatronach",
    type = traitType,
    name = "Flame Atronach",
    description = (
        "Flame Atronachs are race of elemental daedra. " ..
        "\n" ..
        "\n" ..
        "Admixture of Flame Atronach blood flowing in your veins grants you fire shield at a cost " ..
        "of weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Fire Shield (20p) and Weakness to Frost (25%) are traits of those with Flame Atronach " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_FlameAtronach")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "frostatronach",
    type = traitType,
    name = "Frost Atronach",
    description = (
        "Frost Atronachs are race of elemental daedra. " ..
        "\n" ..
        "\n" ..
        "Admixture of Frost Atronach blood flowing in your veins grants you frost shield at a cost " ..
        "of weakness to fire. " ..
        "\n" ..
        "\n" ..
        "Frost Shield (20p) and Weakness to Fire (25%) are traits of those with Frost Atronach " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_FrostAtronach")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "stormatronach",
    type = traitType,
    name = "Storm Atronach",
    description = (
        "Storm Atronachs are race of elemental daedra. " ..
        "\n" ..
        "\n" ..
        "Admixture of Storm Atronach blood flowing in your veins grants you lightning shield at a " ..
        "cost of weakness to non-elemental magicka. " ..
        "\n" ..
        "\n" ..
        "Lightning Shield (20p) and Weakness to Magicka (25%) are traits of those with Storm " ..
        "Atronach ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_StormAtronach")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "naga",
    type = traitType,
    name = "Naga",
    description = (
        "Naga are a breed of Argonians who live in deeper parts of Black Marsh. They are described " ..
        "as having 'huge mouths filled with dripping needle-like fangs'. " ..
        "\n" ..
        "\n" ..
        "Admixture of Naga blood flowing in your veins grants you bonus to strength at a cost of " ..
        "penalty to intelligence. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+10) and penalty to Intelligence (-10) are traits of those with Naga " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Naga")

        attrs.intelligence.base = attrs.intelligence.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "altmer",
    type = traitType,
    name = "Altmer",
    description = (
        "The High Elves consider themselves the most civilized culture of Tamriel; the common " ..
        "tongue of the Empire, Tamrielic, is based on Altmer speech and writing, and most of the " ..
        "Empire's arts, crafts, and sciences derive from High Elven traditions. Deft, intelligent, " ..
        "and strong-willed, High Elves are often gifted in the arcane arts, and High Elves boast " ..
        "that their sublime physical natures make them far more resistant to disease than the " ..
        "'lesser races.' " ..
        "\n" ..
        "\n" ..
        "Your pure Altmer blood bolsters your magicka supplies and intelligence and hinders your " ..
        "resistance to non-elemental magicka and strength. " ..
        "\n" ..
        "\n" ..
        "Fortify Maximum Magicka (50%), bonus to Intelligence (+5), Weakness to Magicka (50%) and " ..
        "penalty to Strength (-5) are traits of those with Altmer pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Altmer")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['high elf']
    end
}

I.CharacterTraits.addTrait {
    id = "altmerhalf",
    type = traitType,
    name = "Half-Altmer",
    description = (
        "The High Elves consider themselves the most civilized culture of Tamriel; the common " ..
        "tongue of the Empire, Tamrielic, is based on Altmer speech and writing, and most of the " ..
        "Empire's arts, crafts, and sciences derive from High Elven traditions. Deft, intelligent, " ..
        "and strong-willed, High Elves are often gifted in the arcane arts, and High Elves boast " ..
        "that their sublime physical natures make them far more resistant to disease than the " ..
        "'lesser races.' " ..
        "\n" ..
        "\n" ..
        "Admixture of Altmer blood flowing in your veins grants you additional magicka supplies and " ..
        "bonus to intelligence at a cost of weakness to non-elemental magicka and penalty to " ..
        "strength. " ..
        "\n" ..
        "\n" ..
        "Fortify Maximum Magicka (50%), bonus to Intelligence (+5), Weakness to Magicka (50%) and " ..
        "penalty to Strength (-5) are traits of those with Altmer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Altmer")

        attrs.strength.base = attrs.strength.base - 5
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "argonian",
    type = traitType,
    name = "Argonian",
    description = (
        "At home in water and on land, the Argonians of Black Marsh are well-suited to the " ..
        "treacherous swamps of their homeland, with natural immunities protecting them from disease " ..
        "and poison. The female life-phase is highly intelligent, and gifted in the magical arts. " ..
        "The more aggressive male phase has the traits of the hunter: stealth, speed, and agility. " ..
        "Argonians are reserved with strangers, yet fiercely loyal to those they accept as friends. " ..
        "Like the Khajiit, Argonians are limited to some headgear and no footwear. " ..
        "\n" ..
        "\n" ..
        "Your pure Argonian blood bolsters your intelligence and agility and hinders your endurance " ..
        "and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty " ..
        "to Personality (-5) are traits of those with Argonian pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_ArgonianPure")
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['argonian']
    end
}

I.CharacterTraits.addTrait {
    id = "argonianhalf",
    type = traitType,
    name = "Half-Argonian",
    description = (
        "At home in water and on land, the Argonians of Black Marsh are well-suited to the " ..
        "treacherous swamps of their homeland, with natural immunities protecting them from disease " ..
        "and poison. The female life-phase is highly intelligent, and gifted in the magical arts. " ..
        "The more aggressive male phase has the traits of the hunter: stealth, speed, and agility. " ..
        "Argonians are reserved with strangers, yet fiercely loyal to those they accept as friends. " ..
        "Like the Khajiit, Argonians are limited to some headgear and no footwear. " ..
        "\n" ..
        "\n" ..
        "Admixture of Argonian blood flowing in your veins grants you bonus intelligence, bonus to " ..
        "agility and resistance to poison at a cost of penalty to endurance, penalty to personality " ..
        "and weakness to frost. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+5), bonus to Agility (+5), Resist Poison (25%), penalty to " ..
        "Endurance (-5), penalty to Personality (-5) and Weakness to Frost (25%) are traits of " ..
        "those with Argonian ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Argonian")

        attrs.endurance.base = attrs.endurance.base - 5
        attrs.personality.base = attrs.personality.base - 5
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "bosmer",
    type = traitType,
    name = "Bosmer",
    description = (
        "The Wood Elves are the various barbarian Elven clanfolk of the Western Valenwood forests. " ..
        "These country cousins of the High Elves and Dark Elves are nimble and quick in body and " ..
        "wit, and because of their curious natures and natural agility, Wood Elves are especially " ..
        "suitable as scouts, agents, and thieves. But most of all, the Wood Elves are known for " ..
        "their skills with bows; there are no finer archers in all of Tamriel. " ..
        "\n" ..
        "\n" ..
        "Your pure Bosmer blood bolsters your speed and agility and hinders your endurance and " ..
        "strength. " ..
        "\n" ..
        "\n" ..
        "Bonus to Speed (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty to " ..
        "Strength (-5) are traits of those with Bosmer pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Bosmer")
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['wood elf']
    end
}

I.CharacterTraits.addTrait {
    id = "bosmerhalf",
    type = traitType,
    name = "Half-Bosmer",
    description = (
        "The Wood Elves are the various barbarian Elven clanfolk of the Western Valenwood forests. " ..
        "These country cousins of the High Elves and Dark Elves are nimble and quick in body and " ..
        "wit, and because of their curious natures and natural agility, Wood Elves are especially " ..
        "suitable as scouts, agents, and thieves. But most of all, the Wood Elves are known for " ..
        "their skills with bows; there are no finer archers in all of Tamriel. " ..
        "\n" ..
        "\n" ..
        "Admixtre of Bosmer blood flowing in your veins grants you bonus speed and agility at a " ..
        "cost of penalty to endurance and strength. " ..
        "\n" ..
        "\n" ..
        "Bonus to Speed (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty to " ..
        "Strength (-5) are traits of those with Bosmer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Bosmer")
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "breton",
    type = traitType,
    name = "Breton",
    description = (
        "Passionate and eccentric, poetic and flamboyant, intelligent and willful, the Bretons feel " ..
        "an inborn, instinctive bond with the mercurial forces of magic and the supernatural. Many " ..
        "great sorcerers have come out of their home province of High Rock, and in addition to " ..
        "their quick and perceptive grasp of spellcraft, enchantment, and alchemy, even the " ..
        "humblest of Bretons can boast a high resistance to destructive and dominating magical " ..
        "energies. " ..
        "\n" ..
        "\n" ..
        "Your pure Breton blood bolsters your intelligence, willpower and magicka supplies and " ..
        "hinders your strength, agility, speed and endurance. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+5), bonus to Willpower (+5), Fortify Maximum Magicka (50%), " ..
        "penalty to Strength (-5), penalty to Agility (-5), penalty to Speed (-5) and penalty to " ..
        "Endurance (-5) are traits of those with Breton pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Breton")

        attrs.endurance.base = attrs.endurance.base - 5
        attrs.strength.base = attrs.strength.base - 5
        attrs.agility.base = attrs.agility.base - 5
        attrs.speed.base = attrs.speed.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['breton']
    end
}

I.CharacterTraits.addTrait {
    id = "bretonhalf",
    type = traitType,
    name = "Half-Breton",
    description = (
        "Passionate and eccentric, poetic and flamboyant, intelligent and willful, the Bretons feel " ..
        "an inborn, instinctive bond with the mercurial forces of magic and the supernatural. Many " ..
        "great sorcerers have come out of their home province of High Rock, and in addition to " ..
        "their quick and perceptive grasp of spellcraft, enchantment, and alchemy, even the " ..
        "humblest of Bretons can boast a high resistance to destructive and dominating magical " ..
        "energies. " ..
        "\n" ..
        "\n" ..
        "Admixture of Breton blood flowing in your veins grants you bonus to intelligence, " ..
        "willpower and magicka supplies at a cost of penalty to strength, agility, speed and " ..
        "endurance. " ..
        "\n" ..
        "\n" ..
        "Bonus to Intelligence (+5), bonus to Willpower (+5), Fortify Maximum Magicka (50%), " ..
        "penalty to Strength (-5), penalty to Agility (-5), penalty to Speed (-5) and penalty to " ..
        "Endurance (-5) are traits of those with Breton ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Breton")

        attrs.endurance.base = attrs.endurance.base - 5
        attrs.strength.base = attrs.strength.base - 5
        attrs.agility.base = attrs.agility.base - 5
        attrs.speed.base = attrs.speed.base - 5
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "dunmer",
    type = traitType,
    name = "Dunmer",
    description = (
        "In the Empire, 'Dark Elves' is the common usage, but in their Morrowind homeland, they " ..
        "call themselves the 'Dunmer'. The dark-skinned, red-eyed Dark Elves combine powerful " ..
        "intellect with strong and agile physiques, producing superior warriors and sorcerers. On " ..
        "the battlefield, Dark Elves are noted for their skilled and balanced integration of " ..
        "swordsmen, marksmen, and war wizards. In character, they are grim, distrusting, and " ..
        "disdainful of other races. " ..
        "\n" ..
        "\n" ..
        "Your pure Dunmer blood bolsters your strength, intelligence, agility and speed and hinders " ..
        "your willpower and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Intelligence (+5), bonus to Agility (+5), bonus to Speed " ..
        "(+5), penalty to Willpower (-10) and penalty to Personality (-10) are traits of those with " ..
        "Dunmer pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_DunmerPure")

        attrs.personality.base = attrs.personality.base - 10
        attrs.willpower.base   = attrs.willpower.base - 10
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['dark elf']
    end
}

I.CharacterTraits.addTrait {
    id = "dunmerhalf",
    type = traitType,
    name = "Half-Dunmer",
    description = (
        "In the Empire, 'Dark Elves' is the common usage, but in their Morrowind homeland, they " ..
        "call themselves the 'Dunmer'. The dark-skinned, red-eyed Dark Elves combine powerful " ..
        "intellect with strong and agile physiques, producing superior warriors and sorcerers. On " ..
        "the battlefield, Dark Elves are noted for their skilled and balanced integration of " ..
        "swordsmen, marksmen, and war wizards. In character, they are grim, distrusting, and " ..
        "disdainful of other races. " ..
        "\n" ..
        "\n" ..
        "Admixture of Dunmer blood flowing in your veins grants you bonus to strength, " ..
        "intelligence, agility and fire resistance at a cost of penalty to willpower and " ..
        "personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Intelligence (+5), bonus to Agility (+5), Resist Fire " ..
        "(25%), penalty to Willpower (-10) and penalty to Personality (-10) are traits of those " ..
        "with Dunmer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Dunmer")

        attrs.personality.base = attrs.personality.base - 10
        attrs.willpower.base   = attrs.willpower.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "cyrodiil",
    type = traitType,
    name = "Cyrodiil",
    description = (
        "The well-educated and well-spoken native of Cyrodiil are known for the discipline and " ..
        "training of their citizen armies. Though physically less imposing than the other races, " ..
        "Imperials are shrewd diplomats and traders, and these traits, along with their remarkable " ..
        "skill and training as light infantry, have enabled them to subdue all the other nations " ..
        "and races, and to have erected the monument to peace and prosperity that comprises the " ..
        "Glorious Empire. " ..
        "\n" ..
        "\n" ..
        "Your pure Cyrodiil blood bolsters your personality and hinders your agility. " ..
        "\n" ..
        "\n" ..
        "Bonus to Personality (+5) and penalty to Agility (-5) are traits of those with Cyrodiil " ..
        "pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Cyrodiil")

        attrs.agility.base = attrs.agility.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['imperial']
    end
}

I.CharacterTraits.addTrait {
    id = "cyrodiilhalf",
    type = traitType,
    name = "Half-Cyrodiil",
    description = (
        "The well-educated and well-spoken native of Cyrodiil are known for the discipline and " ..
        "training of their citizen armies. Though physically less imposing than the other races, " ..
        "Imperials are shrewd diplomats and traders, and these traits, along with their remarkable " ..
        "skill and training as light infantry, have enabled them to subdue all the other nations " ..
        "and races, and to have erected the monument to peace and prosperity that comprises the " ..
        "Glorious Empire. " ..
        "\n" ..
        "\n" ..
        "Admixture of Cyrodiil blood flowing in your veins grants you bonus to personality at a " ..
        "cost of penalty to agility. " ..
        "\n" ..
        "\n" ..
        "Bonus to Personality (+5) and penalty to Agility (-5) are traits of those with Cyrodiil " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Cyrodiil")

        attrs.agility.base = attrs.agility.base - 5
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "khajiit",
    type = traitType,
    name = "Khajiit",
    description = (
        "The Khajiit of Elsweyr can vary in appearance from nearly Elven to the cathay-raht 'jaguar " ..
        "men' to the great Senche-Tiger. The most common breed found in Morrowind, the suthay-raht, " ..
        "is intelligent, quick, and agile. Khajiit of all breeds have a weakness for sweets, " ..
        "especially the drug known as skooma. Many Khajiit disdain weapons in favor of their " ..
        "natural claws. They make excellent thieves due to their natural agility and unmatched " ..
        "acrobatics ability. " ..
        "\n" ..
        "\n" ..
        "Your pure Khajiit blood bolsters your agility and hinders your willpower. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+5) and penalty to Willpower (-5) are traits of those with Khajiit " ..
        "pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Khajiit")

        attrs.willpower.base = attrs.willpower.base - 5
    end,
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        local playerRace = getRaceId(self)
        local khajiitRaces = {
            ["khajiit"] = true,
            ["t_els_cathay"] = true,
            ["t_els_cathay-raht"] = true,
            ["t_els_dagi-raht"] = true,
            ["t_els_ohmes"] = true,
            ["t_els_ohmes-raht"] = true,
            ["t_els_suthay"] = true,
        }
        return not khajiitRaces[playerRace]
    end
}

I.CharacterTraits.addTrait {
    id = "khajiithalf",
    type = traitType,
    name = "Half-Khajiit",
    description = (
        "The Khajiit of Elsweyr can vary in appearance from nearly Elven to the cathay-raht 'jaguar " ..
        "men' to the great Senche-Tiger. The most common breed found in Morrowind, the suthay-raht, " ..
        "is intelligent, quick, and agile. Khajiit of all breeds have a weakness for sweets, " ..
        "especially the drug known as skooma. Many Khajiit disdain weapons in favor of their " ..
        "natural claws. They make excellent thieves due to their natural agility and unmatched " ..
        "acrobatics ability. " ..
        "\n" ..
        "\n" ..
        "Admixture of Khajiit blood flowing in your veins grants you bonus to agility at a cost of " ..
        "penalty to willpower. " ..
        "\n" ..
        "\n" ..
        "Bonus to Agility (+5) and penalty to Willpower (-5) are traits of those with Khajiit " ..
        "ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Khajiit")

        attrs.willpower.base = attrs.willpower.base - 5
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "nord",
    type = traitType,
    name = "Nord",
    description = (
        "The citizens of Skyrim are aggressive and fearless in war, industrious and enterprising in " ..
        "trade and exploration. Strong, stubborn, and hardy, Nords are famous for their resistance " ..
        "to cold, even magical frost. Violence is an accepted and comfortable aspect of Nord " ..
        "culture; Nords of all classes are skilled with a variety of weapon and armor styles, and " ..
        "they cheerfully face battle with an ecstatic ferocity that shocks and appalls their " ..
        "enemies. " ..
        "\n" ..
        "\n" ..
        "Your pure Nord blood bolsters your strength, willpower and endurance and hinders your " ..
        "intelligence and agility. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance(+5), penalty to " ..
        "Intelligence (-10) and penalty to Agility (-5) are traits of those with Nord pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_NordPure")

        attrs.intelligence.base = attrs.intelligence.base - 10
        attrs.agility.base      = attrs.agility.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['nord']
    end
}

I.CharacterTraits.addTrait {
    id = "nordhalf",
    type = traitType,
    name = "Half-Nord",
    description = (
        "The citizens of Skyrim are aggressive and fearless in war, industrious and enterprising in " ..
        "trade and exploration. Strong, stubborn, and hardy, Nords are famous for their resistance " ..
        "to cold, even magical frost. Violence is an accepted and comfortable aspect of Nord " ..
        "culture; Nords of all classes are skilled with a variety of weapon and armor styles, and " ..
        "they cheerfully face battle with an ecstatic ferocity that shocks and appalls their " ..
        "enemies. " ..
        "\n" ..
        "\n" ..
        "Admixture of Nord blood flowing in your veins grants you bonus to strength, willpower, " ..
        "endurance and frost resistance at a cost of penalty to intelligence and agility. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance(+5), Resist Frost " ..
        "(25%), penalty to Intelligence (-10) and penalty to Agility (-10) are traits of those with " ..
        "Nord ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Nord")

        attrs.intelligence.base = attrs.intelligence.base - 10
        attrs.agility.base      = attrs.agility.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "orsimer",
    type = traitType,
    name = "Orsimer",
    description = (
        "These sophisticated barbarian beast peoples of the Wrothgarian and Dragontail Mountains " ..
        "are noted for their unshakeable courage in war and their unflinching endurance of " ..
        "hardships. Orc warriors in heavy armor are among the finest front-line troops in the " ..
        "Empire. Most Imperial citizens regard Orc society as rough and cruel, but there is much to " ..
        "admire in their fierce tribal loyalties and generous equality of rank and respect among " ..
        "the sexes. " ..
        "\n" ..
        "\n" ..
        "Your pure Orsimer blood bolsters your strength, willpower, endurance and resistance to " ..
        "non-elemental magicka and hinders your intelligence, agility and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance (+5), Resist Magicka " ..
        "(25%), penalty to Intelligence (-5), penalty to Agility (-5) and penalty to Personality " ..
        "(-10) are traits of those with Orsimer pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Orsimer")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        attrs.personality.base  = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end
}

I.CharacterTraits.addTrait {
    id = "orsimerhalf",
    type = traitType,
    name = "Half-Orsimer",
    description = (
        "These sophisticated barbarian beast peoples of the Wrothgarian and Dragontail Mountains " ..
        "are noted for their unshakeable courage in war and their unflinching endurance of " ..
        "hardships. Orc warriors in heavy armor are among the finest front-line troops in the " ..
        "Empire. Most Imperial citizens regard Orc society as rough and cruel, but there is much to " ..
        "admire in their fierce tribal loyalties and generous equality of rank and respect among " ..
        "the sexes. " ..
        "\n" ..
        "\n" ..
        "Admixture of Orsimer blood flowing in your veins grants you bonus to strength, willpower, " ..
        "endurance and resistance to non-elemental magicka at a cost of penalty to intelligence, " ..
        "agility and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance (+5), Resist Magicka " ..
        "(25%), penalty to Intelligence (-5), penalty to Agility (-5) and penalty to Personality " ..
        "(-10) are traits of those with Orsimer ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Orsimer")

        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.agility.base      = attrs.agility.base - 5
        attrs.personality.base  = attrs.personality.base - 10
    end,
    checkDisabled = function()
        return false
    end
}

I.CharacterTraits.addTrait {
    id = "redguard",
    type = traitType,
    name = "Redguard",
    description = (
        "The most naturally talented warriors in Tamriel, the dark-skinned, wiry-haired Redguards " ..
        "of Hammerfell seem born to battle, though their pride and fierce independence of spirit " ..
        "makes them more suitable as scouts or skirmishers, or as free-ranging heroes and " ..
        "adventurers, than as rank-and-file soldiers. In addition to their cultural affinities for " ..
        "many weapon and armor styles, Redguards are also physically blessed with hardy " ..
        "constitutions and quickness of foot. " ..
        "\n" ..
        "\n" ..
        "Your pure Redguard blood bolsters your strength, endurance and speed and hinders your " ..
        "intelligence, willpower and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Endurance (+5), bonus to Speed (+5), penalty to " ..
        "Intelligence (-5), penalty to Willpower (-5) and penalty to Personality (-5) are traits of " ..
        "those with Redguard pureblood. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_RedguardPure")

        attrs.willpower.base    = attrs.willpower.base - 5
        attrs.intelligence.base = attrs.intelligence.base - 5
        attrs.personality.base  = attrs.personality.base - 5
    end,
    checkDisabled = function()
        return getRaceId(self) ~= races['redguard']
    end
}

I.CharacterTraits.addTrait {
    id = "redguardhalf",
    type = traitType,
    name = "Half-Redguard",
    description = (
        "The most naturally talented warriors in Tamriel, the dark-skinned, wiry-haired Redguards " ..
        "of Hammerfell seem born to battle, though their pride and fierce independence of spirit " ..
        "makes them more suitable as scouts or skirmishers, or as free-ranging heroes and " ..
        "adventurers, than as rank-and-file soldiers. In addition to their cultural affinities for " ..
        "many weapon and armor styles, Redguards are also physically blessed with hardy " ..
        "constitutions and quickness of foot. " ..
        "\n" ..
        "\n" ..
        "Admixture of Redguard blood flowing in your veins grants you bonus strength, endurance, " ..
        "speed, poison resistance and disease resistance at a cost of penalty to intelligence, " ..
        "willpower and personality. " ..
        "\n" ..
        "\n" ..
        "Bonus to Strength (+5), bonus to Endurance (+5), bonus to Speed (+5), Resist Poison (25%), " ..
        "Resist Common Diseases (25%), penalty to Intelligence (-10), penalty to Willpower (-10) " ..
        "and penalty to Personality (-5) are traits of those with Redguard ancestry. "
    ),
    doOnce = function()
        selfSpells:add("mtrLineage_Redguard")

        attrs.willpower.base    = attrs.willpower.base - 10
        attrs.intelligence.base = attrs.intelligence.base - 10
        attrs.personality.base  = attrs.personality.base - 5
    end,
    checkDisabled = function()
        return false
    end
}
