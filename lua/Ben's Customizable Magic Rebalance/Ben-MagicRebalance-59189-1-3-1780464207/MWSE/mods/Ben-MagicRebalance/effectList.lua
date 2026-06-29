local effectCosts = {}
local effectLimits = {}
local categories = {}
local categoryIndex = 0

local function addEffect(effectId, baseMagickaCost, duration, magnitude)

    -- baseMagickaCost values:
    -- 0    to 2000    = neither
    -- 0.0  to  200.0  = magnitude or duration
    -- 0.00 to   20.00 = magnitude and duration

    -- duration = { min, recommended min, max }
    -- spells with BOTH duration and magnitude will use recMinDuration until recMaxMagnitude is hit
    -- spells with ONLY duration use recMinDuration as minimum useful duration

    -- magnitude = { min, recommended min, recommended max, max }
    -- spells and potions will never go over recMaxMagnitude

    -- spellmaking ignores recommended min/max

    duration = duration or {}
    magnitude = magnitude or {}

    duration[2] = duration[2] or duration[1]
    magnitude[2] = magnitude[2] or magnitude[1]
    magnitude[3] = magnitude[3] or magnitude[4]

    effectCosts[effectId] = {
        baseMagickaCost = baseMagickaCost or 0,
    }

    effectLimits[effectId] = {
            minDuration = duration [1] or 0, -- 0 to 300
         recMinDuration = duration [2] or 0, -- 0 to 300
            maxDuration = duration [3] or 0, -- 0 to 300
           minMagnitude = magnitude[1] or 0, -- 0 to 500
        recMinMagnitude = magnitude[2] or 0, -- 0 to 500
        recMaxMagnitude = magnitude[3] or 0, -- 0 to 500
           maxMagnitude = magnitude[4] or 0, -- 0 to 500
    }

    if categoryIndex > 0 then table.insert(categories[categoryIndex].effectIds, effectId) end

end

local function addCategory(categoryName)

    categoryIndex = categoryIndex + 1

    categories[categoryIndex] = {
        name = categoryName,
        effectIds = {}
    }

end

local function startModdedEffects()

    -- modded effects are not organized into categories
    -- they appear on a separate page grouped by mod instead
    categoryIndex = -1

end

----------------------------------------------------------------------------------------------------
addCategory("Restore/Cure")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.restoreFatigue  , 3, {}, {nil, 80})
addEffect(tes3.effect.restoreHealth   , 6, {}, {nil, 40})
addEffect(tes3.effect.restoreMagicka  , 6, {}, {nil, 40})
addEffect(tes3.effect.restoreAttribute, 3, {}, {nil, 40})
addEffect(tes3.effect.restoreSkill    , 3, {}, {nil, 40})

addEffect(tes3.effect.curePoison        ,  100)
addEffect(tes3.effect.cureParalyzation  ,  100)
addEffect(tes3.effect.cureCommonDisease ,  400)
addEffect(tes3.effect.cureBlightDisease ,  800)
addEffect(tes3.effect.cureCorprusDisease, 1600)

addEffect(tes3.effect.dispel, 2, {}, {100, nil, nil, 100})

----------------------------------------------------------------------------------------------------
addCategory("Fortify/Resist")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.fortifyFatigue  , 0.1, {20}, {nil, 100, nil, nil})
addEffect(tes3.effect.fortifyHealth   , 0.2, {20}, {nil,  50, nil, nil})
addEffect(tes3.effect.fortifyMagicka  , 0.4, {20}, {nil,  25, nil, nil})
addEffect(tes3.effect.fortifyAttribute, 1  , {20}, {nil,  10, 100, nil})
addEffect(tes3.effect.fortifySkill    , 1  , {20}, {nil,  10, 100, nil})
addEffect(tes3.effect.fortifyAttack   , 1  , {10}, {nil,  20, 100, nil})
addEffect(tes3.effect.sanctuary       , 1  , {10}, {nil,  20, 100, nil})

addEffect(tes3.effect.resistCommonDisease , 0.02, {20,  60}, {nil, 100, 100, nil})
addEffect(tes3.effect.resistBlightDisease , 0.04, {20,  60}, {nil, 100, 100, nil})
addEffect(tes3.effect.resistCorprusDisease, 0.08, {20,  60}, {nil, 100, 100, nil})
addEffect(tes3.effect.resistParalysis     , 0.1 , {20, nil}, {nil, 100, 100, nil})
addEffect(tes3.effect.resistPoison        , 0.2 , {20, nil}, {nil, 25 , 100, nil})
addEffect(tes3.effect.resistFire          , 0.4 , {20, nil}, {nil, 25 , 100, nil})
addEffect(tes3.effect.resistFrost         , 0.4 , {20, nil}, {nil, 25 , 100, nil})
addEffect(tes3.effect.resistShock         , 0.4 , {20, nil}, {nil, 25 , 100, nil})
addEffect(tes3.effect.resistMagicka       , 0.4 , {20, nil}, {nil, 25 , 100, nil})
addEffect(tes3.effect.resistNormalWeapons , 1   , {10, nil}, {nil, 20 , 100, nil})

----------------------------------------------------------------------------------------------------
addCategory("Shield/Bound")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.shield         , 0.4, {20}, {nil, 20})
addEffect(tes3.effect.fireShield     , 0.5, {20}, {nil, 20})
addEffect(tes3.effect.frostShield    , 0.5, {20}, {nil, 20})
addEffect(tes3.effect.lightningShield, 0.5, {20}, {nil, 20})

addEffect(tes3.effect.boundBoots  , 2, {20})
addEffect(tes3.effect.boundGloves , 2, {20})
addEffect(tes3.effect.boundHelm   , 2, {20})
addEffect(tes3.effect.boundShield , 2, {20})
addEffect(tes3.effect.boundCuirass, 6, {20})

addEffect(tes3.effect.boundDagger   , 10, {20})
addEffect(tes3.effect.boundBattleAxe, 20, {20})
addEffect(tes3.effect.boundLongbow  , 20, {20})
addEffect(tes3.effect.boundLongsword, 20, {20})
addEffect(tes3.effect.boundMace     , 20, {20})
addEffect(tes3.effect.boundSpear    , 20, {20})

addEffect(tes3.effect.reflect        , 1, {10}, {nil, 25, 100, nil})
addEffect(tes3.effect.spellAbsorption, 1, {10}, {nil, 25, 100, nil})

----------------------------------------------------------------------------------------------------
addCategory("Attack")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.poison     , 6, {}, {nil, 30})
addEffect(tes3.effect.fireDamage , 6, {}, {nil, 30})
addEffect(tes3.effect.frostDamage, 6, {}, {nil, 30})
addEffect(tes3.effect.shockDamage, 8, {}, {nil, 30})

addEffect(tes3.effect.damageFatigue  ,  2, {}, {nil, 120})
addEffect(tes3.effect.damageHealth   ,  8, {}, {nil,  30})
addEffect(tes3.effect.damageMagicka  ,  4, {}, {nil,  60})
addEffect(tes3.effect.damageAttribute, 16, {}, {nil,  15})
addEffect(tes3.effect.damageSkill    , 16, {}, {nil,  15})

addEffect(tes3.effect.drainFatigue  , 0.08, {20}, {nil, 100, nil, nil})
addEffect(tes3.effect.drainHealth   , 0.32, {20}, {nil,  25, nil, 100})
addEffect(tes3.effect.drainMagicka  , 0.16, {20}, {nil,  50, nil, nil})
addEffect(tes3.effect.drainAttribute, 0.6 , {20}, {nil,  15, 100, nil})
addEffect(tes3.effect.drainSkill    , 0.6 , {20}, {nil,  15, 100, nil})

addEffect(tes3.effect.absorbFatigue  ,  4  , {nil}, {nil, 60, nil, nil})
addEffect(tes3.effect.absorbHealth   , 12  , {nil}, {nil, 20, nil, nil})
addEffect(tes3.effect.absorbMagicka  , 12  , {nil}, {nil, 20, nil, nil})
addEffect(tes3.effect.absorbAttribute,  1.2, { 20}, {nil, 10, 100, nil})
addEffect(tes3.effect.absorbSkill    ,  1.2, { 20}, {nil, 10, 100, nil})

----------------------------------------------------------------------------------------------------
addCategory("Debuff")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.weaknesstoCommonDisease , 0.02, {20}, {nil, 100, 100, nil})
addEffect(tes3.effect.weaknesstoBlightDisease , 0.04, {20}, {nil, 100, 100, nil})
addEffect(tes3.effect.weaknesstoCorprusDisease, 0.04, {20}, {nil, 100, 100, nil})
addEffect(tes3.effect.weaknesstoPoison        , 0.24, {20}, {nil,  25, 100, nil})
addEffect(tes3.effect.weaknesstoFire          , 0.24, {20}, {nil,  25, 100, nil})
addEffect(tes3.effect.weaknesstoFrost         , 0.24, {20}, {nil,  25, 100, nil})
addEffect(tes3.effect.weaknesstoShock         , 0.24, {20}, {nil,  25, 100, nil})
addEffect(tes3.effect.weaknesstoMagicka       , 0.24, {20}, {nil,  25, 100, nil})
addEffect(tes3.effect.weaknesstoNormalWeapons , 0.4 , {20}, {nil,  25, 100, nil})

addEffect(tes3.effect.disintegrateArmor , 0.4, {}, {nil, 500})
addEffect(tes3.effect.disintegrateWeapon, 0.8, {}, {nil, 250})

addEffect(tes3.effect.sound, 0.2, {20}, {nil, 50, 200, nil})
addEffect(tes3.effect.blind, 0.4, {20}, {nil, 25, 100, nil})

addEffect(tes3.effect.silence,  20, {10})
addEffect(tes3.effect.paralyze, 40, { 5})

----------------------------------------------------------------------------------------------------
addCategory("Manipulate")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.calmCreature, 0.12, {20}, {100, nil, nil, 100})
addEffect(tes3.effect.calmHumanoid, 0.24, {20}, {100, nil, nil, 100})

addEffect(tes3.effect.frenzyCreature, 0.2, {20}, {100, nil, nil, 100})
addEffect(tes3.effect.frenzyHumanoid, 0.4, {20}, {100, nil, nil, 100})

addEffect(tes3.effect.rallyCreature, 0.02, {20}, {100, nil, nil, 100})
addEffect(tes3.effect.rallyHumanoid, 0.04, {20}, {100, nil, nil, 100})

addEffect(tes3.effect.turnUndead        , 0.08, {20}, {100, nil, nil, 100})
addEffect(tes3.effect.demoralizeCreature, 0.12, {20}, {100, nil, nil, 100})
addEffect(tes3.effect.demoralizeHumanoid, 0.24, {20}, {100, nil, nil, 100})

addEffect(tes3.effect.commandCreature, 2, {20}, {nil, 5, nil, nil})
addEffect(tes3.effect.commandHumanoid, 4, {20}, {nil, 5, nil, nil})

----------------------------------------------------------------------------------------------------
addCategory("Traverse")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.slowFall, 0.1, {nil,  20}, {nil, 20})
addEffect(tes3.effect.jump    , 0.5, { 20, nil}, {nil, 10})

addEffect(tes3.effect.swiftSwim, 0.1, {nil, 20}, {nil, 50, 100, nil})
addEffect(tes3.effect.levitate , 0.2, {nil, 20}, {nil, 25, nil, nil})

addEffect(tes3.effect.feather, 0.04, {nil,  60}, {nil,  50})
addEffect(tes3.effect.burden , 0.06, { 20, nil}, {nil, 125})

addEffect(tes3.effect.waterBreathing, 2, {nil, 60})
addEffect(tes3.effect.waterWalking  , 2, {nil, 60})

addEffect(tes3.effect.almsiviIntervention, 200)
addEffect(tes3.effect.divineIntervention , 200)

addEffect(tes3.effect.mark  , 400)
addEffect(tes3.effect.recall, 400)

----------------------------------------------------------------------------------------------------
addCategory("Explore")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.open, 10, {}, {nil,  25, 100, nil})
addEffect(tes3.effect.lock, 10, {}, { 10, nil, 100, nil})

addEffect(tes3.effect.light   , 0.05, {nil, 60}, {nil, 50, 50, nil})
addEffect(tes3.effect.nightEye, 0.1 , {nil, 60}, {nil, 25, 25, nil})

addEffect(tes3.effect.detectAnimal     , 0.02, {nil, 60}, {nil, 100, 100, nil})
addEffect(tes3.effect.detectEnchantment, 0.02, {nil, 60}, {nil, 100, 100, nil})
addEffect(tes3.effect.detectKey        , 0.02, {nil, 60}, {nil, 100, 100, nil})

addEffect(tes3.effect.charm      , 0.5, {20, nil}, {nil,  20, 100, nil})
addEffect(tes3.effect.telekinesis, 1.0, {20, nil}, {nil,  10, 100, nil})
addEffect(tes3.effect.soultrap   , 2.0, {20,  60})

addEffect(tes3.effect.chameleon   ,  1, {10}, {nil, 20, 100, nil})
addEffect(tes3.effect.invisibility, 20, {10})

----------------------------------------------------------------------------------------------------
addCategory("Summon")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.summonAncestralGhost   ,  6, {20})
addEffect(tes3.effect.summonSkeletalMinion   ,  6, {20})

addEffect(tes3.effect.callWolf               , 10, {20})
addEffect(tes3.effect.summonBonewalker       , 10, {20})
addEffect(tes3.effect.summonCenturionSphere  , 10, {20})
addEffect(tes3.effect.summonScamp            , 10, {20})

addEffect(tes3.effect.summonBonelord         , 15, {20})
addEffect(tes3.effect.summonBonewolf         , 15, {20})
addEffect(tes3.effect.summonClannfear        , 15, {20})
addEffect(tes3.effect.summonFlameAtronach    , 15, {20})
addEffect(tes3.effect.summonGreaterBonewalker, 15, {20})

addEffect(tes3.effect.callBear               , 20, {20})
addEffect(tes3.effect.summonDremora          , 20, {20})
addEffect(tes3.effect.summonFrostAtronach    , 20, {20})

addEffect(tes3.effect.summonDaedroth         , 30, {20})
addEffect(tes3.effect.summonHunger           , 30, {20})
addEffect(tes3.effect.summonFabricant        , 30, {20})
addEffect(tes3.effect.summonStormAtronach    , 30, {20})
addEffect(tes3.effect.summonWingedTwilight   , 30, {20})

addEffect(tes3.effect.summonGoldenSaint      , 40, {20})

----------------------------------------------------------------------------------------------------
addCategory("Other")
----------------------------------------------------------------------------------------------------

addEffect(tes3.effect.fortifyMaximumMagicka)
addEffect(tes3.effect.stuntedMagicka)
addEffect(tes3.effect.removeCurse)
addEffect(tes3.effect.corprus)
addEffect(tes3.effect.vampirism)
addEffect(tes3.effect.sunDamage)
addEffect(tes3.effect.sEffectSummonCreature04)
addEffect(tes3.effect.sEffectSummonCreature05)
addEffect(tes3.effect.eXTRASPELL)

----------------------------------------------------------------------------------------------------
startModdedEffects()
----------------------------------------------------------------------------------------------------

addEffect( 229, 20, {20}) -- Magicka Expanded: boundClaymore
addEffect( 230, 20, {20}) -- Magicka Expanded: boundClub
addEffect( 231, 20, {20}) -- Magicka Expanded: boundDaiKatana
addEffect( 232, 20, {20}) -- Magicka Expanded: boundKatana
addEffect( 233, 20, {20}) -- Magicka Expanded: boundShortSword
addEffect( 234, 20, {20}) -- Magicka Expanded: boundStaff
addEffect( 235, 20, {20}) -- Magicka Expanded: boundTanto
addEffect( 236, 20, {20}) -- Magicka Expanded: boundWakizashi
addEffect( 237, 20, {20}) -- Magicka Expanded: boundWarAxe
addEffect( 238, 20, {20}) -- Magicka Expanded: boundWarhammer
addEffect( 239,  2, {20}) -- Magicka Expanded: boundGreaves
addEffect( 240,  2, {20}) -- Magicka Expanded: boundLeftPauldron
addEffect( 264,  2, {20}) -- Magicka Expanded: boundRightPauldron
addEffect( 429,  2, {20}) -- Bound Leggings for Beasts: boundLeggings
addEffect( 704,  4, {20}) -- Bound Ammo: boundarrow
addEffect( 705,  4, {20}) -- Bound Ammo (JosephMcKean Edit): boundbolt
addEffect( 706, 20, {20}) -- Bound Ammo (JosephMcKean Edit): boundcrossbow
addEffect(2111,  2, {20}) -- Tamriel_Data: T_bound_Greaves
addEffect(2112, 20, {20}) -- Tamriel_Data: T_bound_Waraxe
addEffect(2113, 20, {20}) -- Tamriel_Data: T_bound_Warhammer
addEffect(2116,  4, {20}) -- Tamriel_Data: T_bound_Pauldron
addEffect(2145, 20, {20}) -- Tamriel_Data: T_bound_Greatsword

----------------------------------------------------------------------------------------------------

addEffect( 223, nil, {20}) -- Magicka Expanded: summonGoblinGrunt
addEffect( 224, nil, {20}) -- Magicka Expanded: summonGoblinOfficer
addEffect( 225, nil, {20}) -- Magicka Expanded: summonHulkingFabricant
addEffect( 226, nil, {20}) -- Magicka Expanded: summonAscendedSleeper
addEffect( 227, nil, {20}) -- Magicka Expanded: summonDraugr
addEffect( 228, nil, {20}) -- Magicka Expanded: summonLich
addEffect( 252, nil, {20}) -- Magicka Expanded: summonOgrim
addEffect( 253, nil, {20}) -- Magicka Expanded: summonWarDurzog
addEffect( 254, nil, {20}) -- Magicka Expanded: summonSpriggan
addEffect( 255, nil, {20}) -- Magicka Expanded: summonCenturionSteam
addEffect( 256, nil, {20}) -- Magicka Expanded: summonCenturionProjectile
addEffect( 257, nil, {20}) -- Magicka Expanded: summonAshGhoul
addEffect( 258, nil, {20}) -- Magicka Expanded: summonAshZombie
addEffect( 259, nil, {20}) -- Magicka Expanded: summonAshSlave
addEffect( 260, nil, {20}) -- Magicka Expanded: summonCenturionSpider
addEffect( 261, nil, {20}) -- Magicka Expanded: summonImperfect
addEffect( 262, nil, {20}) -- Magicka Expanded: summonGoblinWarchief
addEffect( 267, nil, {20}) -- Magicka Expanded: summonArmorCent
addEffect( 268, nil, {20}) -- Magicka Expanded: summonArmorCentChamp
addEffect( 269, nil, {20}) -- Magicka Expanded: summonDraugrHsCrl
addEffect( 270, nil, {20}) -- Magicka Expanded: summonDraugrLord
addEffect( 271, nil, {20}) -- Magicka Expanded: summonDridrea
addEffect( 272, nil, {20}) -- Magicka Expanded: summonDridreaMonarch
addEffect( 273, nil, {20}) -- Magicka Expanded: summonFrostLich
addEffect( 274, nil, {20}) -- Magicka Expanded: summonGiant
addEffect( 275, nil, {20}) -- Magicka Expanded: summonGoblinShaman
addEffect( 276, nil, {20}) -- Magicka Expanded: summonGreaterLich
addEffect( 277, nil, {20}) -- Magicka Expanded: summonLamia
addEffect( 278, nil, {20}) -- Magicka Expanded: summonMammoth
addEffect( 279, nil, {20}) -- Magicka Expanded: summonMinotaur
addEffect( 280, nil, {20}) -- Magicka Expanded: summonMudGolem
addEffect( 281, nil, {20}) -- Magicka Expanded: summonParastylus
addEffect( 282, nil, {20}) -- Magicka Expanded: summonPlainStrider
addEffect( 283, nil, {20}) -- Magicka Expanded: summonRaki
addEffect( 285, nil, {20}) -- Magicka Expanded: summonSiltStrider
addEffect( 286, nil, {20}) -- Magicka Expanded: summonSload
addEffect( 287, nil, {20}) -- Magicka Expanded: summonSwampTroll
addEffect( 288, nil, {20}) -- Magicka Expanded: summonWelkyndSpirit
addEffect( 290, nil, {20}) -- Magicka Expanded: summonVelk
addEffect( 291, nil, {20}) -- Magicka Expanded: summonVermai
addEffect( 292, nil, {20}) -- Magicka Expanded: summonTrebataur
addEffect( 327, nil, {20}) -- Magicka Expanded: summonAlfiq
addEffect( 420, nil, {20}) -- Summon Creeper: summonCreeper
addEffect( 427, nil, {20}) -- OAAB Integrations: summonDarkSeducer
addEffect( 430, nil, {20}) -- Power Fantasy: summonAncestorGuardianPlayer
addEffect( 431, nil, {20}) -- Power Fantasy: summonAncestorGuardianNPC
addEffect(1202, nil, {20}) -- Vaermina's Quest - Dreams of the Escaped: summonCorruptedDouble
addEffect(1203, nil, {20}) -- Vaermina's Quest - Dreams of the Escaped: summonCorruptedDoublePotion
addEffect(2090, nil, {20}) -- Tamriel_Data: T_summon_Devourer
addEffect(2091, nil, {20}) -- Tamriel_Data: T_summon_DremArch
addEffect(2092, nil, {20}) -- Tamriel_Data: T_summon_DremCast
addEffect(2093, nil, {20}) -- Tamriel_Data: T_summon_Guardian
addEffect(2094, nil, {20}) -- Tamriel_Data: T_summon_LesserClfr
addEffect(2095, nil, {20}) -- Tamriel_Data: T_summon_Ogrim
addEffect(2096, nil, {20}) -- Tamriel_Data: T_summon_Seducer
addEffect(2097, nil, {20}) -- Tamriel_Data: T_summon_SeducerDark
addEffect(2098, nil, {20}) -- Tamriel_Data: T_summon_Vermai
addEffect(2099, nil, {20}) -- Tamriel_Data: T_summon_AtroStormMon
addEffect(2100, nil, {20}) -- Tamriel_Data: T_summon_SummonIceWraith
addEffect(2101, nil, {20}) -- Tamriel_Data: T_summon_SummonDweSpectre
addEffect(2102, nil, {20}) -- Tamriel_Data: T_summon_SummonSteamCent
addEffect(2103, nil, {20}) -- Tamriel_Data: T_summon_SummonSpiderCent
addEffect(2104, nil, {20}) -- Tamriel_Data: T_summon_SummonWelkyndSpirit
addEffect(2105, nil, {20}) -- Tamriel_Data: T_summon_SummonAuroran
addEffect(2107, nil, {20}) -- Tamriel_Data: T_summon_Herne
addEffect(2108, nil, {20}) -- Tamriel_Data: T_summon_Morphoid
addEffect(2109, nil, {20}) -- Tamriel_Data: T_summon_Draugr
addEffect(2110, nil, {20}) -- Tamriel_Data: T_summon_Spriggan
addEffect(2117, nil, {20}) -- Tamriel_Data: T_summon_BoneldGr
addEffect(2126, nil, {20}) -- Tamriel_Data: T_summon_Ghost
addEffect(2127, nil, {20}) -- Tamriel_Data: T_summon_Wraith
addEffect(2128, nil, {20}) -- Tamriel_Data: T_summon_Barrowguard
addEffect(2129, nil, {20}) -- Tamriel_Data: T_summon_MinoBarrowguard
addEffect(2130, nil, {20}) -- Tamriel_Data: T_summon_SkeletonChampion
addEffect(2131, nil, {20}) -- Tamriel_Data: T_summon_AtroFrostMon
addEffect(3301, nil, {20}) -- Summon Souls: summonSoul1
addEffect(3302, nil, {20}) -- Summon Souls: summonSoul2
addEffect(3303, nil, {20}) -- Summon Souls: summonSoul3
addEffect(3304, nil, {20}) -- Summon Souls: summonSoul4
addEffect(3305, nil, {20}) -- Summon Souls: summonSoul5
addEffect(3306, nil, {20}) -- Summon Souls: summonSoul6
addEffect(3307, nil, {20}) -- Summon Souls: summonSoul7
addEffect(3308, nil, {20}) -- Summon Souls: summonSoul8
addEffect(7700, nil, {20}) -- Atronach Expansion: summonAshGolem
addEffect(7701, nil, {20}) -- Atronach Expansion: summonBoneGolem
addEffect(7702, nil, {20}) -- Atronach Expansion: summonCrystalGolem
addEffect(7703, nil, {20}) -- Atronach Expansion: summonFleshAtronach
addEffect(7704, nil, {20}) -- Atronach Expansion: summonIronGolem
addEffect(7705, nil, {20}) -- Atronach Expansion: summonSwampMyconid
addEffect(7706, nil, {20}) -- Atronach Expansion: summonTelvanniMyconid
addEffect(7800, nil, {20}) -- OOAB Grazelands: flawedSummonDaedroth

----------------------------------------------------------------------------------------------------

local this = {}

this.getEffectCosts = function()
    return effectCosts
end

this.getEffectLimits = function()
    return effectLimits
end

this.getCategories = function()
    return categories
end

return this
