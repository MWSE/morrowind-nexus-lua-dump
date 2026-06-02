local effectList = require("Ben-MagicRebalance.effectList")
local spellList = require("Ben-MagicRebalance.spellList")
local util = require("Ben-MagicRebalance.util")

local this = {}

local defaultMcmConfig = {
    version = 1.2,
    lastUpdated = 0,
    shared = {
        modEnabled = true,
        loggingEnabled = false,
        useMcpAreaFormulaEverywhere = true, -- apply MCP area formula to ALL spells/enchantments when MCP feature is enabled
        fixSpellmakingTargetCost = true, -- fixes compounding x1.5 cost multiplier when creating NEW custom spells
        newEnchantingCostCalculation = true, -- makes enchant cost calculation match the construction set
        enchantmentConstantDurationMult = 200, -- 1 to 500, cost multiplier, unrelated to GMST
        excludedEffectIds = {
            [tes3.effect.damageSkill] = true,
            [tes3.effect.cureCorprusDisease] = true,
            [tes3.effect.fortifyMaximumMagicka] = true,
            [tes3.effect.removeCurse] = true,
            [tes3.effect.eXTRASPELL] = true,
            [tes3.effect.corprus] = true,
            [tes3.effect.vampirism] = true,
            [tes3.effect.sunDamage] = true,
            [tes3.effect.stuntedMagicka] = true,
            [tes3.effect.sEffectSummonCreature04] = true,
            [tes3.effect.sEffectSummonCreature05] = true,
        },
    },
    magicEffect = {
        rebalanceEnabled = true,
        elementalShieldMult = 0.25, -- 0.00 to 2.00, damage per magnitude
        effectCosts = effectList.getEffectCosts(),
        noSpellmakingEffectIds = {
            [tes3.effect.absorbMagicka] = true,
            [tes3.effect.fortifySkill] = true,
            [tes3.effect.resistNormalWeapons] = true,
            [tes3.effect.restoreMagicka] = true,
        },
        noEnchantingEffectIds = {
            [tes3.effect.absorbMagicka] = true,
            [tes3.effect.fortifySkill] = true,
            [tes3.effect.resistNormalWeapons] = true,
            [tes3.effect.restoreMagicka] = true,
        },
    },
    limit = {
        limitsEnabled = true,
        oneSecondMinDuration = true,
        effectLimits = effectList.getEffectLimits(),
    },
    spell = {
        rebalanceEnabled = true,
        updateSpellEffects = true, -- true = merge spellList changes, false = just update costs
        enforceLimitsOnPremadeSpells = false,
        forceRecalculateAllMagickaCosts = false,
        magnitudeVariance = { -- 0.0 to 100.0
            restore = 20, -- restore health/magicka/fatigue
            attack = 20, -- damage, drain/absorb health/magicka/fatigue
            debuff = 20, -- sound, blind, burden, drain/absorb attribute/skill
        },
        addStartSpells = true,
        addStartSpellsToArrille = true,
        startMagickaCost = 6, -- 0.00 to 20.00
        addNpcSpells = true,
        npcTierCount = 4, -- 1 to 6
        removeWeakSpellsFromNonMerchants = true,
        removeForbiddenEffectsFromMerchants = true,
        removeBirthsignSpellsFromMerchants = true,
        startEffectIds = {
            -- Alteration
            [tes3.effect.shield] = true, -- 15p 20s
            [tes3.effect.waterWalking] = true, -- 60s

            --Conjuration
            [tes3.effect.summonAncestralGhost] = true, -- 20s
            [tes3.effect.boundCuirass] = true, -- 20s

            -- Destruction
            [tes3.effect.fireDamage] = true, -- 20p
            [tes3.effect.damageFatigue] = true, -- 60p

            -- Illusion
            [tes3.effect.blind] = true, -- 15p 20s
            [tes3.effect.sound] = true, -- 30p 20s

            -- Mysticism
            [tes3.effect.absorbHealth] = true, -- 10p
            [tes3.effect.detectAnimal] = true, -- 100p 60s

            -- Restoration
            [tes3.effect.restoreHealth] = true, -- 20p
            [tes3.effect.resistCommonDisease] = true, -- 100p 60s

            -- NOTE: These effects do not work as starting spells:
            -- Restore/Fortify/Damage/Drain/Absorb Attribute/Skill

            -- Starting spells are NOT removed from the
            -- player if they are removed from this list.
        },
        npcEffectIds = {
            -- Alteration
            [tes3.effect.burden] = true,
            [tes3.effect.shield] = true,
            [tes3.effect.fireShield] = true,
            [tes3.effect.frostShield] = true,
            [tes3.effect.lightningShield] = true,

            -- Conjuration
            [tes3.effect.boundCuirass] = true,
            [tes3.effect.boundDagger] = true,
            [tes3.effect.boundBattleAxe] = true,
            [tes3.effect.boundLongsword] = true,
            [tes3.effect.boundMace] = true,
            [tes3.effect.boundSpear] = true,
            [tes3.effect.summonAncestralGhost] = true,
            [tes3.effect.summonBonelord] = true,
            [tes3.effect.summonBonewalker] = true,
            [tes3.effect.summonClannfear] = true,
            [tes3.effect.summonDaedroth] = true,
            [tes3.effect.summonDremora] = true,
            [tes3.effect.summonFlameAtronach] = true,
            [tes3.effect.summonFrostAtronach] = true,
            [tes3.effect.summonGoldenSaint] = true,
            [tes3.effect.summonGreaterBonewalker] = true,
            [tes3.effect.summonHunger] = true,
            [tes3.effect.summonScamp] = true,
            [tes3.effect.summonSkeletalMinion] = true,
            [tes3.effect.summonStormAtronach] = true,
            [tes3.effect.summonWingedTwilight] = true,

            -- Destruction
            [tes3.effect.poison] = true,
            [tes3.effect.fireDamage] = true,
            [tes3.effect.frostDamage] = true,
            [tes3.effect.shockDamage] = true,
            [tes3.effect.damageFatigue] = true,
            [tes3.effect.damageHealth] = true,
            [tes3.effect.damageMagicka] = true,

            -- Illusion
            [tes3.effect.sound] = true,
            [tes3.effect.blind] = true,
            [tes3.effect.silence] = true,
            [tes3.effect.paralyze] = true,

            -- Mysticism
            [tes3.effect.absorbFatigue] = true,
            [tes3.effect.absorbHealth] = true,

            -- Restoration
            [tes3.effect.restoreFatigue] = true,
            [tes3.effect.restoreHealth] = true,
        },
        weakEffectIds = {
            [tes3.effect.restoreSkill] = true,
            [tes3.effect.fortifySkill] = true,
            [tes3.effect.damageSkill] = true,
            [tes3.effect.drainSkill] = true,
            [tes3.effect.absorbSkill] = true,
            [tes3.effect.resistCommonDisease] = true,
            [tes3.effect.resistBlightDisease] = true,
            [tes3.effect.resistCorprusDisease] = true,
            [tes3.effect.resistParalysis] = true,
            [tes3.effect.resistPoison] = true,
            [tes3.effect.resistFire] = true,
            [tes3.effect.resistFrost] = true,
            [tes3.effect.resistShock] = true,
            [tes3.effect.resistMagicka] = true,
            [tes3.effect.weaknesstoCommonDisease] = true,
            [tes3.effect.weaknesstoBlightDisease] = true,
            [tes3.effect.weaknesstoCorprusDisease] = true,
            [tes3.effect.weaknesstoPoison] = true,
            [tes3.effect.weaknesstoFire] = true,
            [tes3.effect.weaknesstoFrost] = true,
            [tes3.effect.weaknesstoShock] = true,
            [tes3.effect.weaknesstoMagicka] = true,
            [tes3.effect.boundBoots] = true,
            [tes3.effect.boundGloves] = true,
            [tes3.effect.boundHelm] = true,
            [tes3.effect.boundShield] = true,
            [ 220] = true, -- Magicka Expanded: banishDaedra
            [ 239] = true, -- Magicka Expanded: boundGreaves
            [ 240] = true, -- Magicka Expanded: boundLeftPauldron
            [ 264] = true, -- Magicka Expanded: boundRightPauldron
            [ 429] = true, -- Bound Leggings for Beasts: boundLeggings
            [2111] = true, -- Tamriel_Data: T_bound_Greaves
            [2116] = true, -- Tamriel_Data: T_bound_Pauldron
            [2119] = true, -- Tamriel_Data: T_mysticism_BanishDae
        },
        forbiddenEffectIds = {
            [tes3.effect.restoreSkill] = true,
            [tes3.effect.fortifySkill] = true,
            [tes3.effect.damageSkill] = true,
            [tes3.effect.drainSkill] = true,
            [tes3.effect.absorbSkill] = true,
            [tes3.effect.resistCorprusDisease] = true,
            [tes3.effect.weaknesstoCorprusDisease] = true,
        },
    },
    alchemy = {
        rebalanceEnabled = true,
        standardizeNames = true,
        tier = {
            restore_magickaCost = { -- 0.00 to 300.00
                [1] = 3,
                [2] = 6,
                [3] = 12,
                [4] = 24,
                [5] = 48,
            },
            restore_duration = { -- 1 to 300
                [1] = 1,
                [2] = 2,
                [3] = 4,
                [4] = 8,
                [5] = 16,
            },
            other_magickaCost = { -- 0.00 to 300.00
                [1] = 3.75,
                [2] = 7.5,
                [3] = 15,
                [4] = 30,
                [5] = 60,
            },
            other_duration = { -- 1 to 300
                [1] = 15,
                [2] = 20,
                [3] = 30,
                [4] = 40,
                [5] = 60,
            },
            weight = { -- 0.00 to 10.00
                [1] = 1.5,
                [2] = 1.0,
                [3] = 0.75,
                [4] = 0.5,
                [5] = 0.25,
            },
            value = { -- 1 to 1000
                [1] = 10,
                [2] = 20,
                [3] = 40,
                [4] = 80,
                [5] = 160,
            },
            prefix = {
                [1] = "",
                [2] = "",
                [3] = "",
                [4] = "",
                [5] = "",
            },
            suffix = {
                [1] = ", Bargain",
                [2] = ", Cheap",
                [3] = ", Normal",
                [4] = ", Quality",
                [5] = ", Special",
            },
        },
        detectTier = {
            searchTerms =
                "1:Bargain\n"..
                "1:*_[bB]$\n"..
                "2:Cheap\n"..
                "2:*_[cC]$\n"..
                "3:Standard\n"..
                "3:*_[sS]$\n"..
                "4:Quality\n"..
                "4:*_[qQ]$\n"..
                "5:Exclusive\n"..
                "5:*_[eE]$",
        },
    },
}

local staticConfig = { -- config values that aren't exposed to the player
    magicEffect = {
        gameSettings = {}, -- populated via updateGameConfig()
    },
    spell = {
        npcSpellPicksPerMagicSchool = 2,
        npcOnlyUseBenAutoCalcSpells = false,
        spellInfos = spellList.getSpellInfos(),
        birthsignSpellIds = {
            ["blood of the north"] = true, -- Lord
            ["blessed touch"] = true, -- Ritual
            ["blessed word"] = true, -- Ritual
            ["star-curse"] = true, -- Serpent
            ["beggar's nose spell"] = true, -- Tower
        },
    },
}

local tempConfig = { -- config values needed for config menu UI elements
    shared = {
        excludedEffectNames = {},
    },
    magicEffect = {
        noSpellmakingEffectNames = {},
        noEnchantingEffectNames = {},
    },
    spell = {
        startEffectNames = {},
        npcEffectNames = {},
        weakEffectNames = {},
        forbiddenEffectNames = {},
    },
}

local mcmConfig = {} -- config values loaded from serialized json

local restartRequiredConfig = nil -- config values cached on first load

local gameConfig = {} -- default + static + mcm + restart required

local gameConfigUpdated = { -- onLoaded events need to re-run if config changed
    magicEffect = false,
    spell = false,
    alchemy = false,
}

local configName = "Ben-MagicRebalance"

local function updateGameConfig()

    gameConfig.magicEffect.noSpellmakingEffectIds = nil
    gameConfig.magicEffect.noEnchantingEffectIds = nil
    gameConfig.spell.startEffectIds = nil
    gameConfig.spell.npcEffectIds = nil
    gameConfig.spell.weakEffectIds = nil
    gameConfig.spell.forbiddenEffectIds = nil
    util.deepMerge(gameConfig, mcmConfig)

    gameConfig.shared.excludedEffectIds = nil
    util.deepMerge(gameConfig, restartRequiredConfig)

    gameConfig.magicEffect.gameSettings[tes3.gmst.fElementalShieldMult] = mcmConfig.magicEffect.elementalShieldMult

    gameConfigUpdated.magicEffect = true
    gameConfigUpdated.spell = true
    gameConfigUpdated.alchemy = true

end

local function getEffectIdFromName(effectName)

    local effectId = nil

    for i = #effectName - 2, 1, -1 do
        local char = effectName:sub(i, i)
        if char == "[" then effectId = effectName:sub(i + 1, #effectName - 1) end
    end

    return tonumber(effectId)

end

local function getEffectNameFromId(effectId)

    local magicEffect = tes3.getMagicEffect(effectId)
    local magicEffectName = magicEffect ~= nil and magicEffect.name or "zzz Unknown zzz"
    local effectName = string.format("%s [%d]", magicEffectName, effectId)
    return effectName

end

this.getEffectNameFromId = getEffectNameFromId

local function convertEffectNamesToIds(effectIds, effectNames)

    for effectName, value in pairs(effectNames) do
        if value then
            local effectId = getEffectIdFromName(effectName)
            effectIds[effectId] = true
        end
    end

end

local function convertEffectIdsToNames(effectIds, effectNames)

    for effectId, value in pairs(effectIds) do
        if value then
            local effectName = getEffectNameFromId(effectId)
            effectNames[effectName] = true
        end
    end

end

local function convertAllEffectNamesToIds()

    mcmConfig.shared.excludedEffectIds = {}
    mcmConfig.magicEffect.noSpellmakingEffectIds = {}
    mcmConfig.magicEffect.noEnchantingEffectIds = {}
    mcmConfig.spell.startEffectIds = {}
    mcmConfig.spell.npcEffectIds = {}
    mcmConfig.spell.weakEffectIds = {}
    mcmConfig.spell.forbiddenEffectIds = {}

    convertEffectNamesToIds(mcmConfig.shared.excludedEffectIds, tempConfig.shared.excludedEffectNames)
    convertEffectNamesToIds(mcmConfig.magicEffect.noSpellmakingEffectIds, tempConfig.magicEffect.noSpellmakingEffectNames)
    convertEffectNamesToIds(mcmConfig.magicEffect.noEnchantingEffectIds, tempConfig.magicEffect.noEnchantingEffectNames)
    convertEffectNamesToIds(mcmConfig.spell.startEffectIds, tempConfig.spell.startEffectNames)
    convertEffectNamesToIds(mcmConfig.spell.npcEffectIds, tempConfig.spell.npcEffectNames)
    convertEffectNamesToIds(mcmConfig.spell.weakEffectIds, tempConfig.spell.weakEffectNames)
    convertEffectNamesToIds(mcmConfig.spell.forbiddenEffectIds, tempConfig.spell.forbiddenEffectNames)

end

this.convertAllEffectNamesToIds = convertAllEffectNamesToIds

local function convertAllEffectIdsToNames()

    tempConfig.shared.excludedEffectNames = {}
    tempConfig.magicEffect.noSpellmakingEffectNames = {}
    tempConfig.magicEffect.noEnchantingEffectNames = {}
    tempConfig.spell.startEffectNames = {}
    tempConfig.spell.npcEffectNames = {}
    tempConfig.spell.weakEffectNames = {}
    tempConfig.spell.forbiddenEffectNames = {}

    convertEffectIdsToNames(mcmConfig.shared.excludedEffectIds, tempConfig.shared.excludedEffectNames)
    convertEffectIdsToNames(mcmConfig.magicEffect.noSpellmakingEffectIds, tempConfig.magicEffect.noSpellmakingEffectNames)
    convertEffectIdsToNames(mcmConfig.magicEffect.noEnchantingEffectIds, tempConfig.magicEffect.noEnchantingEffectNames)
    convertEffectIdsToNames(mcmConfig.spell.startEffectIds, tempConfig.spell.startEffectNames)
    convertEffectIdsToNames(mcmConfig.spell.npcEffectIds, tempConfig.spell.npcEffectNames)
    convertEffectIdsToNames(mcmConfig.spell.weakEffectIds, tempConfig.spell.weakEffectNames)
    convertEffectIdsToNames(mcmConfig.spell.forbiddenEffectIds, tempConfig.spell.forbiddenEffectNames)

end

this.convertAllEffectIdsToNames = convertAllEffectIdsToNames

local function updateDependentSettings()

    -- max > rec max > rec min > min
    -- further right = higher precidence

    for _, effect in pairs(mcmConfig.limit.effectLimits) do

        effect.minDuration = effect.minDuration or 0
        effect.recMinDuration = effect.recMinDuration or 0
        effect.maxDuration = effect.maxDuration or 0
        effect.minMagnitude = effect.minMagnitude or 0
        effect.recMinMagnitude = effect.recMinMagnitude or 0
        effect.recMaxMagnitude = effect.recMaxMagnitude or 0
        effect.maxMagnitude = effect.maxMagnitude or 0

        effect.minDuration = util.clamp(effect.minDuration, 0, nil)
        effect.minMagnitude = util.clamp(effect.minMagnitude, 0, nil)

        if effect.recMinDuration ~= 0 then effect.recMinDuration = util.clamp(effect.recMinDuration, util.zeroAsNil(effect.minDuration), nil) end
        if effect.maxDuration ~= 0 then effect.maxDuration = util.clamp(effect.maxDuration, util.zeroAsNil(effect.recMinDuration), nil) end

        if effect.recMinMagnitude ~= 0 then effect.recMinMagnitude = util.clamp(effect.recMinMagnitude, util.zeroAsNil(effect.minMagnitude), nil) end
        if effect.recMaxMagnitude ~= 0 then effect.recMaxMagnitude = util.clamp(effect.recMaxMagnitude, util.zeroAsNil(effect.recMinMagnitude), nil) end
        if effect.maxMagnitude ~= 0 then effect.maxMagnitude = util.clamp(effect.maxMagnitude, util.zeroAsNil(effect.recMaxMagnitude), nil) end

    end

end

local function saveMcmConfig()

    updateDependentSettings()
    convertAllEffectNamesToIds()

    mcmConfig.lastUpdated = os.time()
    mwse.saveConfig(configName, mcmConfig)
    updateGameConfig()

end

this.saveMcmConfig = saveMcmConfig

local function upgradeConfig(version)

    if version < 1.2 then

        -- version 1.0 did not set recommended minimums correctly
        -- version 1.1 did not iterate config version, but did fix underlying bug
        -- version 1.2 allows issue from 1.0 to be automatically corrected after upgrading

        for effectId, defaultEffectLimits in pairs(defaultMcmConfig.limit.effectLimits) do

            local mcmEffectLimits = mcmConfig.limit.effectLimits[effectId]

            mcmEffectLimits.recMinDuration = util.zeroAsNil(mcmEffectLimits.recMinDuration) or defaultEffectLimits.recMinDuration
            mcmEffectLimits.recMinMagnitude = util.zeroAsNil(mcmEffectLimits.recMinMagnitude) or defaultEffectLimits.recMinMagnitude

        end

    end

    mcmConfig.version = defaultMcmConfig.version

end

local function getVersion()

    -- if fresh config, return latest version
    if util.count(mcmConfig) == 0 then return defaultMcmConfig.version end

    -- if version is invalid, assume 1.0 config
    return util.getNumber(mcmConfig.version, 1.0)

end

local function updateRestartRequiredConfig()

    if restartRequiredConfig ~= nil then return end

    restartRequiredConfig = {
        shared = {
            modEnabled = mcmConfig.shared.modEnabled,
            excludedEffectIds = mcmConfig.shared.excludedEffectIds,
        },
        magicEffect = {
            rebalanceEnabled = mcmConfig.magicEffect.rebalanceEnabled,
        },
        spell = {
            rebalanceEnabled = mcmConfig.spell.rebalanceEnabled,
            enforceLimitsOnPremadeSpells = mcmConfig.spell.enforceLimitsOnPremadeSpells,
            forceRecalculateAllMagickaCosts = mcmConfig.spell.forceRecalculateAllMagickaCosts,
            addStartSpells = mcmConfig.spell.addStartSpells,
            addNpcSpells = mcmConfig.spell.addNpcSpells,
        },
        alchemy = {
            rebalanceEnabled = mcmConfig.alchemy.rebalanceEnabled,
            standardizeNames = mcmConfig.alchemy.standardizeNames,
        },
    }

end

local function addMissingEffect(magicEffect)

    local effectAdded = false

    if mcmConfig.magicEffect.effectCosts[magicEffect.id] == nil then

        mcmConfig.magicEffect.effectCosts[magicEffect.id] = {
            baseMagickaCost = magicEffect.baseMagickaCost,
        }

        effectAdded = true

    end

    if mcmConfig.limit.effectLimits[magicEffect.id] == nil then

        mcmConfig.limit.effectLimits[magicEffect.id] = {
            minDuration = 0,
            recMinDuration = 0,
            maxDuration = 0,
            minMagnitude = 0,
            recMinMagnitude = 0,
            recMaxMagnitude = 0,
            maxMagnitude = 0,
        }

        effectAdded = true

    end

    return effectAdded

end

local function addMissingEffects()

    local anyAdded = false

    for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        if addMissingEffect(magicEffect) then anyAdded = true end
    end

    return anyAdded

end

local function clearAlchemyAonTables()

    -- no all-or-nothing tables at the moment

end

this.clearAlchemyAonTables = clearAlchemyAonTables

local function clearSpellAonTables()

    mcmConfig.spell.startEffectIds = {}
    mcmConfig.spell.npcEffectIds = {}
    mcmConfig.spell.weakEffectIds = {}
    mcmConfig.spell.forbiddenEffectIds = {}

end

this.clearSpellAonTables = clearSpellAonTables

local function clearEffectLimitsAonTable()

    for _, effectInfo in pairs(mcmConfig.limit.effectLimits) do
        effectInfo.minDuration = 0
        effectInfo.recMinDuration = 0
        effectInfo.maxDuration = 0
        effectInfo.minMagnitude = 0
        effectInfo.recMinMagnitude = 0
        effectInfo.recMaxMagnitude = 0
        effectInfo.maxMagnitude = 0
    end

end

this.clearEffectLimitsAonTable = clearEffectLimitsAonTable

local function clearLimitAonTables()

    clearEffectLimitsAonTable()

end

this.clearLimitAonTables = clearLimitAonTables

local function clearEffectCostsAonTable()

    for _, effectInfo in pairs(mcmConfig.magicEffect.effectCosts) do
        effectInfo.baseMagickaCost = 0
    end

end

this.clearEffectCostsAonTable = clearEffectCostsAonTable

local function clearMagicEffectAonTables()

    mcmConfig.magicEffect.noSpellmakingEffectIds = {}
    mcmConfig.magicEffect.noEnchantingEffectIds = {}

    clearEffectCostsAonTable()

end

this.clearMagicEffectAonTables = clearMagicEffectAonTables

local function clearSharedAonTables()

    mcmConfig.shared.excludedEffectIds = {}

end

this.clearSharedAonTables = clearSharedAonTables

local function clearAllAonTables()

    clearSharedAonTables()
    clearMagicEffectAonTables()
    clearLimitAonTables()
    clearSpellAonTables()
    clearAlchemyAonTables()

end

this.clearAllAonTables = clearAllAonTables

local function restoreAllOrNothingTables(mcmConfig_AllOrNothingTables)

    if mcmConfig_AllOrNothingTables.shared.excludedEffectIds ~= nil then
        mcmConfig.shared.excludedEffectIds = mcmConfig_AllOrNothingTables.shared.excludedEffectIds
    end

    if mcmConfig_AllOrNothingTables.magicEffect.effectCosts ~= nil then
        mcmConfig.magicEffect.effectCosts = mcmConfig_AllOrNothingTables.magicEffect.effectCosts
    end

    if mcmConfig_AllOrNothingTables.magicEffect.noSpellmakingEffectIds ~= nil then
        mcmConfig.magicEffect.noSpellmakingEffectIds = mcmConfig_AllOrNothingTables.magicEffect.noSpellmakingEffectIds
    end

    if mcmConfig_AllOrNothingTables.magicEffect.noEnchantingEffectIds ~= nil then
        mcmConfig.magicEffect.noEnchantingEffectIds = mcmConfig_AllOrNothingTables.magicEffect.noEnchantingEffectIds
    end

    if mcmConfig_AllOrNothingTables.limit.effectLimits ~= nil then
        mcmConfig.limit.effectLimits = mcmConfig_AllOrNothingTables.limit.effectLimits
    end

    if mcmConfig_AllOrNothingTables.spell.startEffectIds ~= nil then
        mcmConfig.spell.startEffectIds = mcmConfig_AllOrNothingTables.spell.startEffectIds
    end

    if mcmConfig_AllOrNothingTables.spell.npcEffectIds ~= nil then
        mcmConfig.spell.npcEffectIds = mcmConfig_AllOrNothingTables.spell.npcEffectIds
    end

    if mcmConfig_AllOrNothingTables.spell.weakEffectIds ~= nil then
        mcmConfig.spell.weakEffectIds = mcmConfig_AllOrNothingTables.spell.weakEffectIds
    end

    if mcmConfig_AllOrNothingTables.spell.forbiddenEffectIds ~= nil then
        mcmConfig.spell.forbiddenEffectIds = mcmConfig_AllOrNothingTables.spell.forbiddenEffectIds
    end

end

local function saveAllOrNothingTables()

    local mcmConfig_AllOrNothingTables = {
        shared = {},
        magicEffect = {},
        limit = {},
        spell = {},
    }

    if mcmConfig.shared ~= nil and type(mcmConfig.shared.excludedEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.shared.excludedEffectIds = mcmConfig.shared.excludedEffectIds
        mcmConfig.shared.excludedEffectIds = nil
    end

    if mcmConfig.magicEffect ~= nil and type(mcmConfig.magicEffect.effectCosts) == "table" then
        mcmConfig_AllOrNothingTables.magicEffect.effectCosts = mcmConfig.magicEffect.effectCosts
        mcmConfig.magicEffect.effectCosts = nil
    end

    if mcmConfig.magicEffect ~= nil and type(mcmConfig.magicEffect.noSpellmakingEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.magicEffect.noSpellmakingEffectIds = mcmConfig.magicEffect.noSpellmakingEffectIds
        mcmConfig.magicEffect.noSpellmakingEffectIds = nil
    end

    if mcmConfig.magicEffect ~= nil and type(mcmConfig.magicEffect.noEnchantingEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.magicEffect.noEnchantingEffectIds = mcmConfig.magicEffect.noEnchantingEffectIds
        mcmConfig.magicEffect.noEnchantingEffectIds = nil
    end

    if mcmConfig.limit ~= nil and type(mcmConfig.limit.effectLimits) == "table" then
        mcmConfig_AllOrNothingTables.limit.effectLimits = mcmConfig.limit.effectLimits
        mcmConfig.limit.effectLimits = nil
    end

    if mcmConfig.spell ~= nil and type(mcmConfig.spell.startEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.spell.startEffectIds = mcmConfig.spell.startEffectIds
        mcmConfig.spell.startEffectIds = nil
    end

    if mcmConfig.spell ~= nil and type(mcmConfig.spell.npcEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.spell.npcEffectIds = mcmConfig.spell.npcEffectIds
        mcmConfig.spell.npcEffectIds = nil
    end

    if mcmConfig.spell ~= nil and type(mcmConfig.spell.weakEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.spell.weakEffectIds = mcmConfig.spell.weakEffectIds
        mcmConfig.spell.weakEffectIds = nil
    end

    if mcmConfig.spell ~= nil and type(mcmConfig.spell.forbiddenEffectIds) == "table" then
        mcmConfig_AllOrNothingTables.spell.forbiddenEffectIds = mcmConfig.spell.forbiddenEffectIds
        mcmConfig.spell.forbiddenEffectIds = nil
    end

    return mcmConfig_AllOrNothingTables

end

local function loadMcmConfig()

    mcmConfig = mwse.loadConfig(configName, {})
    util.fixNumberKeys(mcmConfig)

    local mcmConfig_AllOrNothingTables = saveAllOrNothingTables()
    local version = getVersion()

    util.deepRemoveMissingKeys(mcmConfig, defaultMcmConfig)
    util.deepMergeWhenNil(mcmConfig, defaultMcmConfig)

    restoreAllOrNothingTables(mcmConfig_AllOrNothingTables)
    updateDependentSettings()
    updateRestartRequiredConfig()
    upgradeConfig(version)

    updateGameConfig()

end

this.onModConfigReady = function(e)

    convertAllEffectIdsToNames()

    local anyAdded = addMissingEffects()
    if anyAdded then saveMcmConfig() end

end

this.onLoaded = function(e)

    convertAllEffectIdsToNames()

    local anyAdded = addMissingEffects()
    if anyAdded then saveMcmConfig() end

end

this.getDefaultMcmConfig = function ()
    return defaultMcmConfig
end

this.getTempConfig = function()
    return tempConfig
end

this.getMcmConfig = function()
    return mcmConfig
end

this.getGameConfig = function()
    return gameConfig
end

this.getGameConfigUpdated = function()
    return gameConfigUpdated
end

this.getModName = function()
    return "Magic Rebalance"
end

this.getVersion = function()
    return defaultMcmConfig.version
end

this.getLoggingEnabled = function()
    return gameConfig.shared.loggingEnabled
end

util.deepMerge(gameConfig, staticConfig)
loadMcmConfig()

return this
