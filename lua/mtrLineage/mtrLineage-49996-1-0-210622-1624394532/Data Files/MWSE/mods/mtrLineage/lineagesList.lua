local this = {}

local function getConfig()
    return mwse.loadConfig("character_lineages") or {}
end

local function saveConfig(newConfig)
    mwse.saveConfig("character_lineages", newConfig)
end

--SPRIGGAN
this.spriggan = {
    id = "spriggan",
    name = "Spriggan",
    description = (
        "Spriggans are a race of humanoid tree-spirits.\n\nAdmixture of Spriggan blood flowing in your veins grants you ability to regenerate health at a cost of weakness to fire. \n\nRestore Health (1p) and Weakness to Fire (100%) are traits of those with Spriggan ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Spriggan"
        }
    end,
}

--NYMPH --NEREID
this.nymph = {
    id = "nymph",
    name = "Nymph",
    description = (
        "Nymphs are a race of humanoid fae species.\n\nAdmixture of Nymph blood flowing in your veins grants you resistance to normal weapons at a cost of penalty to personality. \n\nResist Normal Weapons (25%) and penalty to Personality (-10) are traits of those with Nymph ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Nymph"
        }
    end,
}

--DRAGON
this.dragon = {
    id = "dragon",
    name = "Dragon",
    description = (
        "Dragons are intelligent race of large flying reptiles.\n\nAdmixture of Dragon blood flowing in your veins grants you bonus to intelligence at a cost of penalty to speed. \n\nBonus to Intelligence (+10) and penalty to Speed (-10) are traits of those with Dragon ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -10
        })
    end,
}

--AUREAL
this.aureal = {
    id = "aureal",
    name = "Aureal",
    description = (
        "Aureals, also known as Golden Saints, are a humanoid race of golden-skinned daedra usually serving Sheogorath.\n\nAdmixture of Aureal blood flowing in your veins grants you ability to reflect spells at a cost of weakness to poison. \n\nReflect (5%) and Weakness to Poison (50%) are traits of those with Aureal ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Aureal"
        }
    end,
}

--AURORAN
this.auroran = {
    id = "auroran",
    name = "Auroran",
    description = (
        "Aurorans are a humanoid race of daedra serving Meridia.\n\nAdmixture of Auroran blood flowing in your veins grants you resistance to shock at a cost of weakness to fire. \n\nResist Shock (25%) and Weakness to Fire (25%) are traits of those with Auroran ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Auroran"
        }
    end,
}

--DREMORA
this.dremora = {
    id = "dremora",
    name = "Dremora",
    description = (
        "Dremoras are a humanoid race of daedra serving Mehrunes Dagon.\n\nAdmixture of Dremora blood flowing in your veins grants you bonus to willpower at a cost of penalty to personality. \n\nBonus to Willpower (+10) and penalty to Personality (-10) are traits of those with Dremora ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--HERNE --SKAAFIN --SCAMP --MORPHOID
this.herne = {
    id = "herne",
    name = "Herne",
    description = (
        "Herne are a humanoid race of daedra related to Skaafins, Scamps and Morphoids. They usually serve Clavicus Vile and Mehrunes Dagon.\n\nAdmixture of Herne blood flowing in your veins grants you bonus to speed at a cost of penalty to intelligence. \n\nBonus to Speed (+10) and penalty to Intelligence (-10) are traits of those with Herne ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
    end,
}

--MAZKEN
this.mazken = {
    id = "mazken",
    name = "Mazken",
    description = (
        "Mazkens, also known as Dark Seducers, are a humanoid race of purple-skinned daedra usually serving Sheogorath.\n\nAdmixture of Mazken blood flowing in your veins grants you ability to absorb spells at a cost of weakness to frost. \n\nAbsorb Magicka (5%) and Weakness to Frost (75%) are traits of those with Mazken ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Mazken"
        }
    end,
}

--XIVILAI
this.xivilai = {
    id = "xivilai",
    name = "Xivilai",
    description = (
        "Xivilai are a humanoid race of gray-skinned daedra serving Mehrunes Dagon and Molag Bal.\n\nAdmixture of Xivilai blood flowing in your veins grants you ability to absorb spells and resist fire at a cost of inability to generate magicka and weakness to shock. \n\nAbsorb Magicka (25%), Resist Fire (25%), Stunted Magicka and Weakness to Shock (50%) are traits of those with Xivilai ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Xivilai"
        }
    end,
}

--TSAESCI
this.tsaesci = {
    id = "tsaesci",
    name = "Tsaesci",
    description = (
        "Tsaesci are a serpent-folk of Akavir.\n\nAdmixture of Tsaesci blood flowing in your veins grants you bonus to long blade at a cost of penalty to block. \n\nBonus to Long Blade (+10) and penalty to Block (-10) are traits of those with Tsaesci ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = -10
        })
    end,
}

--TANG MO
this.tangmo = {
    id = "tangmo",
    name = "Tang Mo",
    description = (
        "Tang Mo are a monkey-folk of Akavir.\n\nAdmixture of Tang Mo blood flowing in your veins grants you bonus to agility at a cost of penalty to intelligence. \n\nBonus to Agility (+10) and penalty to Intelligence (-10) are traits of those with Tang Mo ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
    end,
}

--KAMAL
this.kamal = {
    id = "kamal",
    name = "Kamal",
    description = (
        "Kamal are a snow demon race of Akavir.\n\nAdmixture of Kamal blood flowing in your veins grants you ability to resist frost at a cost of weakness to non-elemental magicka. \n\nResist Frost (25%) and Weakness to Magicka (25%) are traits of those with Kamal ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Kamal"
        }
    end,
}

--KA PO' TUN
this.kapotun = {
    id = "kapotun",
    name = "Ka Po' Tun",
    description = (
        "Ka Po' Tun are a tiger-dragon-folk of Akavir.\n\nAdmixture of Ka Po' Tun blood flowing in your veins grants you bonus to strength at a cost of penalty to personality. \n\nBonus to Strength (+10) and penalty to Personality (-10) are traits of those with Ka Po' Tun ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--SLOAD
this.sload = {
    id = "sload",
    name = "Sload",
    description = (
        "Sload are a slug-like beast race from Coral Kingdoms of Thras south-west of Tamriel.\n\nAdmixture of Sload blood flowing in your veins grants you bonus to conjuration and alchemy at a cost of penalty to speed. \n\nBonus to Conjuration (+10), bonus to Alchemy (+10) and penalty to Speed (-10) are traits of those with Sload ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -10
        })
    end,
}

--MINOTAUR
this.minotaur = {
    id = "minotaur",
    name = "Minotaur",
    description = (
        "Minotaurs are a beast race native to Cyrodiil with man body and head of a bull.\n\nAbsorbAdmixture of Minotaur blood flowing in your veins grants you bonus to willpower at a cost of penalty to intelligence. \n\nBonus to Willpower (+10) and penalty to Intelligence (-10) are traits of those with Minotaur ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
    end,
}

--LILMOTHIIT
this.lilmothiit = {
    id = "lilmothiit",
    name = "Lilmothiit",
    description = (
        "Lilmothiit were a nomadic fox-like beast race native to Black Marsh who most likely went extinct following the Knahaten Flu epidemic.\n\nAdmixture of Lilmothiit blood flowing in your veins grants you bonus to agility at a cost of weakness to disease. \n\nBonus to Agility (+10) and Weakness to Common Disease (50%) are traits of those with Lilmothiit ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Lilmothiit"
        }
    end,
}

--LAMIA --MEDUSA
this.lamia = {
    id = "lamia",
    name = "Lamia",
    description = (
        "Lamias are a beast race of aquatic snakes.\n\nAdmixture of Lamia blood flowing in your veins grants you ability to swim faster at a cost of weakness to frost. \n\nSwift Swim (25p) and Weakness to Frost (25%) are traits of those with Lamia ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Lamia"
        }
    end,
}

--IMGA
this.imga = {
    id = "imga",
    name = "Imga",
    description = (
        "Imgas are a beast race of apes native to Valenwood.\n\nAdmixture of Imga blood flowing in your veins grants you bonus to agility at a cost of penalty to personality. \n\nBonus to Agility (+10) and penalty to Personality (-10) are traits of those with Imga ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--HARPY
this.harpy = {
    id = "harpy",
    name = "Harpy",
    description = (
        "Harpies are a beast race native to Iliac Bay area with man body and bird wings.\n\nAdmixture of Harpy blood flowing in your veins grants you bonus to agility at a cost of penalty to intelligence. \n\nBonus to Agility (+10) and penalty to Intelligence (-10) are traits of those with Harpy ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
    end,
}

--HAGRAVEN --HAG
this.hagraven = {
    id = "hagraven",
    name = "Hagraven",
    description = (
        "Hagravens are witches who undergone a ritual to access powerful magicka.\n\nAdmixture of Hagraven blood flowing in your veins grants you resistance to non-elemental magicka at a cost of penalty to personality. \n\nResist Magicka (25%) and penalty to Personality (-10) are traits of those with Hagraven ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Hagraven"
        }
    end,
}

--GRUMMITE
this.grummite = {
    id = "grummite",
    name = "Grummite",
    description = (
        "Grummites are a frog-like beast race native to the Shivering Isles.\n\nAdmixture of Grummite blood flowing in your veins grants you resistance to frost at a cost of weakness to fire. \n\nResist Frost (25%) and Weakness to Fire (25%) are traits of those with Grummite ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Grummite"
        }
    end,
}

--GREMLIN
this.gremlin = {
    id = "gremlin",
    name = "Gremlin",
    description = (
        "Gremlins are a beast race related to, and often living alongside, Goblins, also known as Orc-rats.\n\nAdmixture of Gremlin blood flowing in your veins grants you bonus to agility at a cost of weakness to frost. \n\nBonus to Agility (+10) and Weakness to Frost (25%) are traits of those with Gremlin ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Gremlin"
        }
    end,
}

--RIEKLING --RIEKR
this.riekling = {
    id = "riekling",
    name = "Riekling",
    description = (
        "Rieklings are a blue-skinned beast race related to Goblins.\n\nAdmixture of Riekling blood flowing in your veins grants you resistance to frost at a cost of penalty to intelligence. \n\nResist Frost (25%) and penalty to Intelligence (-10) are traits of those with Riekling ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Riekling"
        }
    end,
}

--OGRE
this.ogre = {
    id = "ogre",
    name = "Ogre",
    description = (
        "Ogres are a beast race worshipping Malacath.\n\nAdmixture of Ogre blood flowing in your veins grants you bonus to strength at a cost of weakness to poison. \n\nBonus to Strength (+10) and Weakness to Poison (25%) are traits of those with Ogre ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Ogre"
        }
    end,
}

--GOBLIN
this.goblin = {
    id = "goblin",
    name = "Goblin",
    description = (
        "Goblins are a green-skinned beast race.\n\nAdmixture of Goblin blood flowing in your veins grants you resistance to fire at a cost of weakness to non-elemental magicka. \n\nResist Fire (25%) and Weakness to Magicka (25%) are traits of those with Goblin ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Goblin"
        }
    end,
}

--GIANT
this.giant = {
    id = "giant",
    name = "Giant",
    description = (
        "Giants are a very tall humanoid race.\n\nAdmixture of Giant blood flowing in your veins grants you bonus to strength at a cost of penalty to agility. \n\nBonus to Strength (+10) and penalty to Agility (-10) are traits of those with Giant ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -10
        })
    end,
}

--DREUGH
this.dreugh = {
    id = "dreugh",
    name = "Dreugh",
    description = (
        "Dreughs are an octopus-like beast race.\n\nAdmixture of Dreugh blood flowing in your veins grants you ability to swim faster at a cost of weakness to frost. \n\nSwift Swim (25p) and Weakness to Frost (25%) are traits of those with Dreugh ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Dreugh"
        }
    end,
}

--CENTAUR
this.centaur = {
    id = "centaur",
    name = "Centaur",
    description = (
        "Centaurs are a beast race with horse lower-body and head and torso of a human.\n\nAdmixture of Centaur blood flowing in your veins grants you bonus to speed at a cost of penalty to personality. \n\nBonus to Speed (+10) and penalty to Personality (-10) are traits of those with Centaur ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--SINISTRAL MER
this.sinistralmer = {
    id = "sinistralmer",
    name = "Sinistral Mer",
    description = (
        "Sinistral Mer, also known as Lefthanded Elves, were an elven race of sunken continent of Yokuda.\n\nAdmixture of Sinistral Mer blood flowing in your veins grants you bonus to long blade at a cost of penalty to armorer. \n\nBonus to Long Blade (+10) and penalty to Armorer (-10) are traits of those with Sinistral Mer ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = -10
        })
    end,
}

--MAORMER
this.maormer = {
    id = "maormer",
    name = "Maormer",
    description = (
        "Maormer, also known as Sea Elves, are an elven race living in Pyandonea.\n\nAdmixture of Maormer blood flowing in your veins grants you resistance to shock at a cost of weakness to frost. \n\nResist Shock (25%) and Weakness to Frost (25%) are traits of those with Maormer ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Maormer"
        }
    end,
}

--FALMER
this.falmer = {
    id = "falmer",
    name = "Falmer",
    description = (
        "Falmer, also known as Snow Elves, are an almost extinct elven race living in cold, remote areas.\n\nAdmixture of Falmer blood flowing in your veins grants you resistance to frost at a cost of weakness to fire. \n\nResist Frost (25%) and Weakness to Fire (25%) are traits of those with Falmer ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Falmer"
        }
    end,
}

--DWEMER
this.dwemer = {
    id = "dwemer",
    name = "Dwemer",
    description = (
        "Dwemer, also known as Dwarves and Deep Elves, were an elven race living in Morrowind and Hammerfell.\n\nAdmixture of Dwemer blood flowing in your veins grants you bonus to intelligence, enchanting and armorer at a cost of penalty to personality and partial blindness. \n\nBonus to Intelligence (+10), bonus to Enchant (+10), bonus to Armorer (+10), penalty to Personality (-10) and Blind (25%) are traits of those with Dwemer ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = 10
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Dwemer"
        }
    end,
}

--AYLEID
this.ayleid = {
    id = "ayleid",
    name = "Ayleid",
    description = (
        "Ayleids, also known as Wild Elves, were an elven race which created an empire in Cyrodiil.\n\nAdmixture of Ayleid blood flowing in your veins grants you bonus to conjuration, armorer, enchanting, marksman, alteration and block at a cost of penalty to personality. \n\nBonus to Conjuration (+5), bonus to Armorer (+5), bonus to Enchant (+5), bonus to Marksman (+5), bonus to Alteration (+5), bonus to Block (+5) and penalty to Personality (-15) are traits of those with Ayleid ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.marksman, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -15
        })
    end,
}

--YESPEST
this.yespest = {
    id = "yespest",
    name = "Yespest",
    description = (
        "Yespest were a man tribe native to Black Marsh who most likely went extinct following the Knahaten Flu epidemic.\n\nAdmixture of Yespest blood flowing in your veins grants you bonus to endurance at a cost of weakness to disease. \n\nBonus to Endurance (+10) and Weakness to Common Disease (50%) are traits of those with Yespest ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Yespest"
        }
    end,
}

--RONTHA
this.rontha = {
    id = "rontha",
    name = "Rontha",
    description = (
        "Rontha were an early man tribe of witch-hunters and spell-drinkers who inhabited western Morrowind.\n\nAdmixture of Rontha blood flowing in your veins grants you ability to absorb spells at a cost of penalty to personality. \n\nAbsorb Magicka (5%) and penalty to Personality (-15) are traits of those with Rontha ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -15
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Rontha"
        }
    end,
}

--REACHMEN
this.reachmen = {
    id = "reachmen",
    name = "Reachmen",
    description = (
        "Reachmen are a tribe of humans inhabiting Eastern High Rock and Western Skyrim believed to be related to Bretons.\n\nAdmixture of Reachmen blood flowing in your veins grants you bonus to willpower at a cost of penalty to personality. \n\nBonus to Willpower (+10) and penalty to Personality (-10) are traits of those with Reachmen ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--PERENA
this.perena = {
    id = "perena",
    name = "Perena",
    description = (
        "Perena were an early man tribe practicing observation of the stars living in Cyrodiil and Hammerfell.\n\nAdmixture of Perena blood flowing in your veins grants you additional magicka at a cost of weakness to frost. \n\nFortify Maximum Magicka (10%) and Weakness to Frost (25%) are traits of those with Perena ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Perena"
        }
    end,
}

--ORMA
this.orma = {
    id = "orma",
    name = "Orma",
    description = (
        "Orma were a man tribe native to Black Marsh who were born without eyes.\n\nAdmixture of Orma blood flowing in your veins grants you heightened senses at a cost of weaker sight. \n\nDetect Animal (150p), Detect Enchantment (150p), Detect Key (150p) and Blind (50%) are traits of those with Orma ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Orma"
        }
    end,
}

--NEDE
this.nede = {
    id = "nede",
    name = "Nede",
    description = (
        "Nedes were a man tribe or group of tribes inhabiting Tamriel in early eras./n/nAdmixture of Nede blood flowing in your veins grants you resistance to non-elemental magicka at a cost of weakness to fire. \n\nResist Magicka (25%) and Weakness to Fire (25%) are traits of those with Nede ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Nede"
        }
    end,
}

--MEN-OF-GE
this.menofge = {
    id = "menofge",
    name = "Men-of-Ge",
    description = (
        "Men-of-Ge were an early man tribe who were wiped out by the Ayleids.\n\nAdmixture of Men-of-Ge blood flowing in your veins grants you bonus to endurance at a cost of penalty to luck. \n\nBonus to Endurance (+10) and penalty to Luck (-10) are traits of those with Men-of-Ge ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -10
        })
    end,
}

--KOTHRINGI --KOTHRI
this.kothringi = {
    id = "kothringi",
    name = "Kothringi",
    description = (
        "Kothringi were a tribe of silver-skinned man native to Black Marsh who most likely went extinct following Knahaten Flu epidemic. They were knows as avid sailors.\n\nAdmixture of Kothringi blood flowing in your veins grants you bonus to unarmored, resistance to poison and resistance to shock at a cost of penalty to heavy armor and weakness to disease. \n\nBonus to Unarmored (+10), Resist Poison (25%), Resist Shock (25%), penalty to Heavy Armor (-10) and Weakness to Common Diseases (50%) are traits of those with Kothringi ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.heavyArmor, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Kothringi"
        }
    end,
}

--KEPTU
this.keptu = {
    id = "keptu",
    name = "Keptu",
    description = (
        "Keptu were a tribe of early man inhabiting Hammerfell.\n\nAdmixture of Keptu blood flowing in your veins grants you bonus to armorer and enchanting at a cost of penalty to personality. \n\nBonus to Armorer (+10), bonus to Enchant (+10) and penalty to Personality (-10) are traits of those with Keptu ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end,
}

--HORWALLI
this.horwalli = {
    id = "horwalli",
    name = "Horwalli",
    description = (
        "Horwalli were a man tribe native to Black Marsh who most likely went extinct following the Knahaten Flu epidemic.\n\nAdmixture of Horwalli blood flowing in your veins grants you bonus to spear at a cost of weakness to disease. \n\nBonus to Spear (+20) and Weakness to Common Disease (50%) are traits of those with Horwalli ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = 20
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Horwalli"
        }
    end,
}

--DURAKI
this.duraki = {
    id = "duraki",
    name = "Duraki",
    description = (
        "Duraki were a tribe of early man living in Hammerfell.\n\nAdmixture of Duraki blood flowing in your veins grants you bonus to conjuration and mysticism at a cost of penalty to luck. \n\nBonus to Conjuration (+10), bonus to Mysticism (+10) and penalty to Luck (-10) are traits of those with Duraki ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -10
        })
    end,
}

--AL-GEMHA
this.algemha = {
    id = "algemha",
    name = "Al-Gemha",
    description = (
        "Al-Gemha were an early tribe of martial man living in western Cyrodiil.\n\nAdmixture of Al-Gemha blood flowing in your veins grants you bonus to endurance at a cost of penalty to willpower. \n\nBonus to Endurance (+10) and penalty to Willpower (-10) are traits of those with Al-Gemha ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -10
        })
    end,
}

--AL-HARED
this.alhared = {
    id = "alhared",
    name = "Al-Hared",
    description = (
        "Al-Hare were an early tribe of shamanistic man living in eastern Cyrodiil.\n\nAdmixture of Al-Hared blood flowing in your veins grants you bonus to willpower and spear at a cost of penalty to endurance. \n\nBonus to Willpower (+5), bonus to Spear (+10) and penalty to Endurance (-10) are traits of those with Al-Hared ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -10
        })
    end,
}

--CLANNFEAR
this.clannfear = {
    id = "clannfear",
    name = "Clannfear",
    description = (
        "Clannfear are a race of bipedal lizarlike daedra.\n\nAdmixture of Clannfear blood flowing in your veins grants you resistance to fire at a cost of weakness to shock. \n\nResist Fire (25%) and Weakness to Shock (25%) are traits of those with Clannfear ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Clannfear"
        }
    end,
}

--DAEDROTH
this.daedroth = {
    id = "daedroth",
    name = "Daedroth",
    description = (
        "Daedroths are a race of bipedal crocodile-like daedra serving Molag Bal and Mehrunes Dagon.\n\nAdmixture of Daedroth blood flowing in your veins grants you resistance to normal weapons at a cost of weakness to shock. \n\nResist Normal Weapons (25%) and Weakness to Shock (25%) are traits of those with Daedroth ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Daedroth"
        }
    end,
}

--GRAHL
this.grahl = {
    id = "grahl",
    name = "Grahl",
    description = (
        "Grahls are a race of ice trolls.\n\nAdmixture of Grahl blood flowing in your veins grants you resistance to frost at a cost of weakness to fire. \n\nResist Frost (25%) and Weakness to Fire (25%) are traits of those with Grahl ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Grahl"
        }
    end,
}

--HARVESTER
this.harvester = {
    id = "harvester",
    name = "Harvester",
    description = (
        "Harvesters are a race of four-armed snakelike daedra serving Molag Bal.\n\nAdmixture of Harvester blood flowing in your veins grants you bonus to conjuration and illusion at a cost of penalty to long blade and axe. \n\nBonus to Conjuration (+10), bonus to Illusion (+10), penalty to Long Blade (-10) and penalty to Axe (-10) are traits of those with Harvester ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion, 
            value = 10
        })
    end,
}

--HUNGER
this.hunger = {
    id = "hunger",
    name = "Hunger",
    description = (
        "Hungers are a race of daedra serving Boethiah.\n\nAdmixture of Hunger blood flowing in your veins grants you bonus to destruction at a cost of penalty to restoration. \n\nBonus to Destruction (+10) and penalty to Restoration (-10) are traits of those with Hunger ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration, 
            value = -10
        })
    end,
}

--IMP
this.imp = {
    id = "imp",
    name = "Imp",
    description = (
        "Imps are a race of small, winged humanoids of potentially daedric origin.\n\nAdmixture of Imp blood flowing in your veins grants you ability to detect animals at a cost of penalty to strength. \n\nDetect Animal (150p) and penalty to Strength (-10) are traits of those with Imp ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -10
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Imp"
        }
    end,
}

--OGRIM
this.ogrim = {
    id = "ogrim",
    name = "Ogrim",
    description = (
        "Ogrims are a race of daedra serving Malacath.\n\nAdmixture of Ogrim blood flowing in your veins grants you ability to regenerate health at a cost of penalty to intelligence. \n\nRestore Health (1p) and penalty to Intelligence (-20) are traits of those with Ogrim ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -20
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Ogrim"
        }
    end,
}

--TROLL
this.troll = {
    id = "troll",
    name = "Troll",
    description = (
        "Trolls are a race of ape-like humanoids.\n\nAdmixture of Troll blood flowing in your veins grants you ability to regenerate health and bonus to speed at a cost of penalty to intelligence and weakness to fire. \n\nRestore Health (1p), bonus to Speed (+10), Weakness to Fire (100%) and penalty to Intelligence (-10) are traits of those with Troll ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Troll"
        }
    end,
}

--VERMAI
this.vermai = {
    id = "vermai",
    name = "Vermai",
    description = (
        "Vermai are a race of thoughtless daedra.\n\nAdmixture of Vermai blood flowing in your veins grants you bonus to strength, bonus to willpower and bonus to endurance at a cost of penalty to intelligence and penalty to personality. \n\nBonus to Strength (+20), bonus to Willpower (+15), bonus to Endurance (+15), penalty to Intelligence (-25) and penalty to Personality (-25) are traits of those with Vermai ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 15
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 15
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 20
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -25
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -25
        })
    end,
}

--WINGED TWILIGHT
this.wingedtwilight = {
    id = "wingedtwilight",
    name = "Winged Twilight",
    description = (
        "Winged Twilights are a race of purple-skinned, winged, harpy-like daedra serving Azura.\n\nAdmixture of Winged Twilight blood flowing in your veins grants you ability to reflect spells at a cost of penalty to personality. \n\nReflect (5%) and penalty to Personality (-20) are traits of those with Winged Twilight ancestry."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -20
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_WingedTwilight"
        }
    end,
}

--FLAME ATRONACH
this.flameatronach = {
    id = "flameatronach",
    name = "Flame Atronach",
    description = (
        "Flame Atronachs are race of elemental daedra.\n\nAdmixture of Flame Atronach blood flowing in your veins grants you fire shield at a cost of weakness to frost. \n\nFire Shield (20p) and Weakness to Frost (25%) are traits of those with Flame Atronach ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_FlameAtronach"
        }
    end,
}

--FROST ATRONACH
this.frostatronach = {
    id = "frostatronach",
    name = "Frost Atronach",
    description = (
        "Frost Atronachs are race of elemental daedra.\n\nAdmixture of Frost Atronach blood flowing in your veins grants you frost shield at a cost of weakness to fire. \n\nFrost Shield (20p) and Weakness to Fire (25%) are traits of those with Frost Atronach ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_FrostAtronach"
        }
    end,
}

--STORM ATRONACH
this.stormatronach = {
    id = "stormatronach",
    name = "Storm Atronach",
    description = (
        "Storm Atronachs are race of elemental daedra.\n\nAdmixture of Storm Atronach blood flowing in your veins grants you lightning shield at a cost of weakness to non-elemental magicka. \n\nLightning Shield (20p) and Weakness to Magicka (25%) are traits of those with Storm Atronach ancestry."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_StormAtronach"
        }
    end,
}

--ALTMER PURE
this.altmer = {
    id = "altmer",
    name = "Altmer",
    description = (
        "The High Elves consider themselves the most civilized culture of Tamriel; the common tongue of the Empire, Tamrielic, is based on Altmer speech and writing, and most of the Empire's arts, crafts, and sciences derive from High Elven traditions. Deft, intelligent, and strong-willed, High Elves are often gifted in the arcane arts, and High Elves boast that their sublime physical natures make them far more resistant to disease than the 'lesser races.'\n\nYour pure Altmer blood bolsters your magicka supplies and intelligence and hinders your resistance to non-elemental magicka and strength.\n\nFortify Maximum Magicka (50%), bonus to Intelligence (+5), Weakness to Magicka (50%) and penalty to Strength (-5) are traits of those with Altmer pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "High Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Altmer"
        }
    end,
}

--ALTMER HALF
this.altmerhalf = {
    id = "altmerhalf",
    name = "Half-Altmer",
    description = (
        "The High Elves consider themselves the most civilized culture of Tamriel; the common tongue of the Empire, Tamrielic, is based on Altmer speech and writing, and most of the Empire's arts, crafts, and sciences derive from High Elven traditions. Deft, intelligent, and strong-willed, High Elves are often gifted in the arcane arts, and High Elves boast that their sublime physical natures make them far more resistant to disease than the 'lesser races.'\n\nAdmixture of Altmer blood flowing in your veins grants you additional magicka supplies and bonus to intelligence at a cost of weakness to non-elemental magicka and penalty to strength.\n\nFortify Maximum Magicka (50%), bonus to Intelligence (+5), Weakness to Magicka (50%) and penalty to Strength (-5) are traits of those with Altmer ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "High Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Altmer"
        }
    end,
}

--ARGONIAN PURE
this.argonian = {
    id = "argonian",
    name = "Argonian",
    description = (
        "At home in water and on land, the Argonians of Black Marsh are well-suited to the treacherous swamps of their homeland, with natural immunities protecting them from disease and poison. The female life-phase is highly intelligent, and gifted in the magical arts. The more aggressive male phase has the traits of the hunter: stealth, speed, and agility. Argonians are reserved with strangers, yet fiercely loyal to those they accept as friends. Like the Khajiit, Argonians are limited to some headgear and no footwear.\n\nYour pure Argonian blood bolsters your intelligence and agility and hinders your endurance and personality.\n\nBonus to Intelligence (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty to Personality (-5) are traits of those with Argonian pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Argonian"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
    end,
}

--ARGONIAN HALF
this.argonianhalf = {
    id = "argonianhalf",
    name = "Half-Argonian",
    description = (
        "At home in water and on land, the Argonians of Black Marsh are well-suited to the treacherous swamps of their homeland, with natural immunities protecting them from disease and poison. The female life-phase is highly intelligent, and gifted in the magical arts. The more aggressive male phase has the traits of the hunter: stealth, speed, and agility. Argonians are reserved with strangers, yet fiercely loyal to those they accept as friends. Like the Khajiit, Argonians are limited to some headgear and no footwear.\n\nAdmixture of Argonian blood flowing in your veins grants you bonus intelligence, bonus to agility and resistance to poison at a cost of penalty to endurance, penalty to personality and weakness to frost.\n\nBonus to Intelligence (+5), bonus to Agility (+5), Resist Poison (25%), penalty to Endurance (-5), penalty to Personality (-5) and Weakness to Frost are traits of those with Argonian ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Argonian"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Argonian"
        }
    end,
}

--BOSMER PURE
this.bosmer = {
    id = "bosmer",
    name = "Bosmer",
    description = (
        "The Wood Elves are the various barbarian Elven clanfolk of the Western Valenwood forests. These country cousins of the High Elves and Dark Elves are nimble and quick in body and wit, and because of their curious natures and natural agility, Wood Elves are especially suitable as scouts, agents, and thieves. But most of all, the Wood Elves are known for their skills with bows; there are no finer archers in all of Tamriel.\n\nYour pure Bosmer blood bolsters your speed and agility and hinders your endurance and strength.\n\nBonus to Speed (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty to Strength (-5) are traits of those with Bosmer pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
    end,
}

--BOSMER HALF
this.bosmerhalf = {
    id = "bosmerhalf",
    name = "Half-Bosmer",
    description = (
        "The Wood Elves are the various barbarian Elven clanfolk of the Western Valenwood forests. These country cousins of the High Elves and Dark Elves are nimble and quick in body and wit, and because of their curious natures and natural agility, Wood Elves are especially suitable as scouts, agents, and thieves. But most of all, the Wood Elves are known for their skills with bows; there are no finer archers in all of Tamriel.\n\nAdmixtre of Bosmer blood flowing in your veins grants you bonus speed and agility at a cost of penalty to endurance and strength.\n\nBonus to Speed (+5), bonus to Agility (+5), penalty to Endurance (-5) and penalty to Strength (-5) are traits of those with Bosmer ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Wood Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -5
        })
    end,
}

--BRETON PURE
this.breton = {
    id = "breton",
    name = "Breton",
    description = (
        "Passionate and eccentric, poetic and flamboyant, intelligent and willful, the Bretons feel an inborn, instinctive bond with the mercurial forces of magic and the supernatural. Many great sorcerers have come out of their home province of High Rock, and in addition to their quick and perceptive grasp of spellcraft, enchantment, and alchemy, even the humblest of Bretons can boast a high resistance to destructive and dominating magical energies.\n\nYour pure Breton blood bolsters your intelligence, willpower and magicka supplies and hinders your strength, agility, speed and endurance.\n\nBonus to Intelligence (+5), bonus to Willpower (+5), Fortify Maximum Magicka (50%), penalty to Strength (-5), penalty to Agility (-5), penalty to Speed (-5) and penalty to Endurance (-5) are traits of those with Breton pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Breton"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
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
            attribute = tes3.attribute.speed, 
            value = -5
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Breton"
        }
    end,
}

--BRETON HALF
this.bretonhalf = {
    id = "bretonhalf",
    name = "Half-Breton",
    description = (
        "Passionate and eccentric, poetic and flamboyant, intelligent and willful, the Bretons feel an inborn, instinctive bond with the mercurial forces of magic and the supernatural. Many great sorcerers have come out of their home province of High Rock, and in addition to their quick and perceptive grasp of spellcraft, enchantment, and alchemy, even the humblest of Bretons can boast a high resistance to destructive and dominating magical energies.\n\nAdmixture of Breton blood flowing in your veins grants you bonus to intelligence, willpower and magicka supplies at a cost of penalty to strength, agility, speed and endurance.\n\nBonus to Intelligence (+5), bonus to Willpower (+5), Fortify Maximum Magicka (50%), penalty to Strength (-5), penalty to Agility (-5), penalty to Speed (-5) and penalty to Endurance (-5) are traits of those with Breton ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Breton"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
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
            attribute = tes3.attribute.speed, 
            value = -5
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Breton"
        }
    end,
}

--DUNMER PURE
this.dunmer = {
    id = "dunmer",
    name = "Dunmer",
    description = (
        "In the Empire, 'Dark Elves' is the common usage, but in their Morrowind homeland, they call themselves the 'Dunmer'. The dark-skinned, red-eyed Dark Elves combine powerful intellect with strong and agile physiques, producing superior warriors and sorcerers. On the battlefield, Dark Elves are noted for their skilled and balanced integration of swordsmen, marksmen, and war wizards. In character, they are grim, distrusting, and disdainful of other races.\n\nYour pure Dunmer blood bolsters your strength, intelligence, agility and speed and hinders your willpower and personality.\n\nBonus to Strength (+5), bonus to Intelligence (+5), bonus to Agility (+5), bonus to Speed (+5), penalty to Willpower (-10) and penalty to Personality (-10) are traits of those with Dunmer pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Dark Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
    end,
}

--DUNMER HALF
this.dunmerhalf = {
    id = "dunmerhalf",
    name = "Half-Dunmer",
    description = (
        "In the Empire, 'Dark Elves' is the common usage, but in their Morrowind homeland, they call themselves the 'Dunmer'. The dark-skinned, red-eyed Dark Elves combine powerful intellect with strong and agile physiques, producing superior warriors and sorcerers. On the battlefield, Dark Elves are noted for their skilled and balanced integration of swordsmen, marksmen, and war wizards. In character, they are grim, distrusting, and disdainful of other races.\n\nAdmixture of Dunmer blood flowing in your veins grants you bonus to strength, intelligence, agility and fire resistance at a cost of penalty to willpower and personality.\n\nBonus to Strength (+5), bonus to Intelligence (+5), bonus to Agility (+5), Resist Fire (25%), penalty to Willpower (-10) and penalty to Personality (-10) are traits of those with Dunmer ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Dark Elf"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Dunmer"
        }
    end,
}

--CYRODIIL PURE
this.cyrodiil = {
    id = "cyrodiil",
    name = "Cyrodiil",
    description = (
        "The well-educated and well-spoken native of Cyrodiil are known for the discipline and training of their citizen armies. Though physically less imposing than the other races, Imperials are shrewd diplomats and traders, and these traits, along with their remarkable skill and training as light infantry, have enabled them to subdue all the other nations and races, and to have erected the monument to peace and prosperity that comprises the Glorious Empire.\n\nYour pure Cyrodiil blood bolsters your personality and hinders your agility.\n\nBonus to Personality (+5) and penalty to Agility (-5) are traits of those with Cyrodiil pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Imperial"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
    end,
}

--CYRODIIL HALF
this.cyrodiilhalf = {
    id = "cyrodiilhalf",
    name = "Half-Cyrodiil",
    description = (
        "The well-educated and well-spoken native of Cyrodiil are known for the discipline and training of their citizen armies. Though physically less imposing than the other races, Imperials are shrewd diplomats and traders, and these traits, along with their remarkable skill and training as light infantry, have enabled them to subdue all the other nations and races, and to have erected the monument to peace and prosperity that comprises the Glorious Empire.\n\nAdmixture of Cyrodiil blood flowing in your veins grants you bonus to personality at a cost of penalty to agility.\n\nBonus to Personality (+5) and penalty to Agility (-5) are traits of those with Cyrodiil ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Imperial"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
    end,
}

--KHAJIIT PURE
this.khajiit = {
    id = "khajiit",
    name = "Khajiit",
    description = (
        "The Khajiit of Elsweyr can vary in appearance from nearly Elven to the cathay-raht 'jaguar men' to the great Senche-Tiger. The most common breed found in Morrowind, the suthay-raht, is intelligent, quick, and agile. Khajiit of all breeds have a weakness for sweets, especially the drug known as skooma. Many Khajiit disdain weapons in favor of their natural claws. They make excellent thieves due to their natural agility and unmatched acrobatics ability.\n\nYour pure Khajiit blood bolsters your agility and hinders your willpower.\n\nBonus to Agility (+5) and penalty to Willpower (-5) are traits of those with Khajiit pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Khajiit"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
    end,
}

--KHAJIIT HALF
this.khajiithalf = {
    id = "khajiithalf",
    name = "Half-Khajiit",
    description = (
        "The Khajiit of Elsweyr can vary in appearance from nearly Elven to the cathay-raht 'jaguar men' to the great Senche-Tiger. The most common breed found in Morrowind, the suthay-raht, is intelligent, quick, and agile. Khajiit of all breeds have a weakness for sweets, especially the drug known as skooma. Many Khajiit disdain weapons in favor of their natural claws. They make excellent thieves due to their natural agility and unmatched acrobatics ability.\n\nAdmixture of Khajiit blood flowing in your veins grants you bonus to agility at a cost of penalty to willpower.\n\nBonus to Agility (+5) and penalty to Willpower (-5) are traits of those with Khajiit ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Khajiit"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
    end,
}

--NORD PURE
this.nord = {
    id = "nord",
    name = "Nord",
    description = (
        "The citizens of Skyrim are aggressive and fearless in war, industrious and enterprising in trade and exploration. Strong, stubborn, and hardy, Nords are famous for their resistance to cold, even magical frost. Violence is an accepted and comfortable aspect of Nord culture; Nords of all classes are skilled with a variety of weapon and armor styles, and they cheerfully face battle with an ecstatic ferocity that shocks and appalls their enemies.\n\nYour pure Nord blood bolsters your strength, willpower and endurance and hinders your intelligence and agility.\n\nBonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance(+5), penalty to Intelligence (-10) and penalty to Agility (-5) are traits of those with Nord pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Nord"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -5
        })
    end,
}

--NORD HALF
this.nordhalf = {
    id = "nordhalf",
    name = "Half-Nord",
    description = (
        "The citizens of Skyrim are aggressive and fearless in war, industrious and enterprising in trade and exploration. Strong, stubborn, and hardy, Nords are famous for their resistance to cold, even magical frost. Violence is an accepted and comfortable aspect of Nord culture; Nords of all classes are skilled with a variety of weapon and armor styles, and they cheerfully face battle with an ecstatic ferocity that shocks and appalls their enemies.\n\nAdmixture of Nord blood flowing in your veins grants you bonus to strength, willpower, endurance and frost resistance at a cost of penalty to intelligence and agility.\n\nBonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance(+5), Resist Frost (25%), penalty to Intelligence (-10) and penalty to Agility (-10) are traits of those with Nord ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Nord"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Nord"
        }
    end,
}

--ORSIMER PURE
this.orsimer = {
    id = "orsimer",
    name = "Orsimer",
    description = (
        "These sophisticated barbarian beast peoples of the Wrothgarian and Dragontail Mountains are noted for their unshakeable courage in war and their unflinching endurance of hardships. Orc warriors in heavy armor are among the finest front-line troops in the Empire. Most Imperial citizens regard Orc society as rough and cruel, but there is much to admire in their fierce tribal loyalties and generous equality of rank and respect among the sexes.\n\nYour pure Orsimer blood bolsters your strength, willpower, endurance and resistance to non-elemental magicka and hinders your intelligence, agility and personality.\n\nBonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance (+5), Resist Magicka (25%), penalty to Intelligence (-5), penalty to Agility (-5) and penalty to Personality (-10) are traits of those with Orsimer pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Orc"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
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
            attribute = tes3.attribute.personality, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Orsimer"
        }
    end,
}

--ORSIMER HALF
this.orsimerhalf = {
    id = "orsimerhalf",
    name = "Half-Orsimer",
    description = (
        "These sophisticated barbarian beast peoples of the Wrothgarian and Dragontail Mountains are noted for their unshakeable courage in war and their unflinching endurance of hardships. Orc warriors in heavy armor are among the finest front-line troops in the Empire. Most Imperial citizens regard Orc society as rough and cruel, but there is much to admire in their fierce tribal loyalties and generous equality of rank and respect among the sexes.\n\nAdmixture of Orsimer blood flowing in your veins grants you bonus to strength, willpower, endurance and resistance to non-elemental magicka at a cost of penalty to intelligence, agility and personality.\n\nBonus to Strength (+5), bonus to Willpower (+5), bonus to Endurance (+5), Resist Magicka (25%), penalty to Intelligence (-5), penalty to Agility (-5) and penalty to Personality (-10) are traits of those with Orsimer ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Orc"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
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
            attribute = tes3.attribute.personality, 
            value = -10
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Orsimer"
        }
    end,
}

--REDGUARD PURE
this.redguard = {
    id = "redguard",
    name = "Redguard",
    description = (
        "The most naturally talented warriors in Tamriel, the dark-skinned, wiry-haired Redguards of Hammerfell seem born to battle, though their pride and fierce independence of spirit makes them more suitable as scouts or skirmishers, or as free-ranging heroes and adventurers, than as rank-and-file soldiers. In addition to their cultural affinities for many weapon and armor styles, Redguards are also physically blessed with hardy constitutions and quickness of foot.\n\nYour pure Redguard blood bolsters your strength, endurance and speed and hinders your intelligence, willpower and personality.\n\nBonus to Strength (+5), bonus to Endurance (+5), bonus to Speed (+5), penalty to Intelligence (-5), penalty to Willpower (-5) and penalty to Personality (-5) are traits of those with Redguard pureblood."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Redguard"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
    end,
}

--REDGUARD HALF
this.redguardhalf = {
    id = "redguardhalf",
    name = "Half-Redguard",
    description = (
        "The most naturally talented warriors in Tamriel, the dark-skinned, wiry-haired Redguards of Hammerfell seem born to battle, though their pride and fierce independence of spirit makes them more suitable as scouts or skirmishers, or as free-ranging heroes and adventurers, than as rank-and-file soldiers. In addition to their cultural affinities for many weapon and armor styles, Redguards are also physically blessed with hardy constitutions and quickness of foot.\n\nAdmixture of Redguard blood flowing in your veins grants you bonus strength, endurance, speed, poison resistance and disease resistance at a cost of penalty to intelligence, willpower and personality.\n\nBonus to Strength (+5), bonus to Endurance (+5), bonus to Speed (+5), Resist Poison (25%), Resist Common Diseases (25%), penalty to Intelligence (-10), penalty to Willpower (-10) and penalty to Personality (-5) are traits of those with Redguard ancestry."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race == "Redguard"
    end,
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "mtrLineage_Redguard"
        }
    end,
}

-- Options deemed either too distant, obscure or too crazy still are Hist, Faerie other than Spriggan/Nymphs, Magna-Ge, Ehlnofey, Nocturnal Shrikes, Spiderkith, Xivkyn, Akaviri Canine Folk, Akaviri Rat People, Lizard Bull, Cyrodiilic Bird Men, Chimer, Changeling, Aldmer, Banekin, Gargoyle, Huntsman, Knight of Order, Lurker, Mermaid, Purified, Seeker, Echmer, Hyu-Ket, Kitapoe, Broh-Kah, Terenjoe, Chimeri-quey, Air Atronach, Stone Atronach, Flesh Atronach, Iron Atronach

return this