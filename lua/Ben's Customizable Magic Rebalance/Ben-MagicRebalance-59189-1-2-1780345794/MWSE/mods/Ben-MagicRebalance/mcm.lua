local effectList = require("Ben-MagicRebalance.effectList")
local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local defaultMcmConfig = config.getDefaultMcmConfig()
local tempConfig = config.getTempConfig()
local mcmConfig = config.getMcmConfig()

local moddedMagicEffects = {} -- sourceMod = effectInfos[]

local alreadyLoaded = false
local mainExcludedEffectsPage = nil
local magicEffectCostsModdedPage = nil
local magicEffectCostsModdedPage_Info = nil
local magicEffectNoSpellmakingEffectsPage = nil
local magicEffectNoEnchantingEffectsPage = nil
local limitTemplate = nil
local limitHomePage_Info = nil
local spellWeakEffectsPage = nil
local spellForbiddenEffectsPage = nil

local function getMinMaxStepJumpDecimalPlaces_BaseMagickaCost(magicEffect)

    -- baseMagickaCost values:
    -- 0    to 2000    = neither
    -- 0.0  to  200.0  = magnitude or duration
    -- 0.00 to   20.00 = magnitude and duration

    if magicEffect.hasNoMagnitude
    and magicEffect.hasNoDuration then

        return {0, 2000, 1, 50, 0}

    elseif magicEffect.hasNoMagnitude
    or magicEffect.hasNoDuration then

        return {0, 200, 0.1, 5, 1}

    else -- neither

        return {0, 20, 0.01, 0.5, 2}

    end

end

local function getExclusionsCallback_Helper(effectNames, effectId, validEffectIds, invalidEffectIds)

    if validEffectIds ~= nil and validEffectIds[effectId] ~= true then return end
    if invalidEffectIds ~= nil and invalidEffectIds[effectId] then return end

    local effectName = config.getEffectNameFromId(effectId)
    table.insert(effectNames, effectName)

end

local function getExclusionsCallback(validEffectIds, invalidEffectIds)

    return function()

        local effectNames = {}

        for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
            getExclusionsCallback_Helper(effectNames, magicEffect.id, validEffectIds, invalidEffectIds)
        end

        table.sort(effectNames, util.sortFunction_ByStringKey)
        return effectNames

    end

end

local function getExclusionsCallback_VanillaOnly(invalidEffectIds)

    local validEffectIds = {}

    for i = 0, 142 do
        validEffectIds[i] = true
    end

    return getExclusionsCallback(validEffectIds, invalidEffectIds)

end

local function createAlchemyRestoreDefaultsPage(template)

    local page = template:createSideBarPage({ label = "Restore Defaults" })

    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Potion Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 5: Potions\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearAlchemyAonTables()
            util.deepMerge(mcmConfig.alchemy, defaultMcmConfig.alchemy)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore \"Home\" Defaults",
        description = "Restores the default values of all settings on the \"Home\" tab.",
        callback = function()
            mcmConfig.alchemy.rebalanceEnabled = defaultMcmConfig.alchemy.rebalanceEnabled
            mcmConfig.alchemy.standardizeNames = defaultMcmConfig.alchemy.standardizeNames
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore \"Tier\" Defaults",
        description = "Restores the default values of all settings on the \"Tier\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.alchemy.tier, defaultMcmConfig.alchemy.tier)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"Detect Tier\" Defaults",
        description = "Restores the default values of all settings on the \"Detect Tier\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.alchemy.detectTier, defaultMcmConfig.alchemy.detectTier)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

end

local function createAlchemyDetectTierBySearchTermPage(template)

    local page = template:createSideBarPage({ label = "Detect Tier", noScroll = true })

    page.sidebar:createInfo({ text =
        "Tier:SearchTerm"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a tier and a search term, separated by a colon."..
        " If a potion's name or ID contains the search term, it is assigned the corresponding tier."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the potion is not rebalanced."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk are ignored and the remainder of the search term are treated as a Lua pattern."..
        "\n\nSPECIAL: Potions assigned to tier zero will not be rebalanced."..
        "\n\nREQUIRES RESTART: The game must be restarted before any additions, removals, or changes to tier zero search terms will come into effect."
    })

    page:createParagraphField({
        label = "\"Tier\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.alchemy.detectTier,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })

end

local function createAlchemyTierPage(template)

    local page = template:createSideBarPage({ label = "Tier" })

    page.sidebar:createInfo({ text =
        "Potion Magnitude = "..
        "\n  Magicka Cost /"..
        "\n  Duration /"..
        "\n  Base Magicka Cost /"..
        "\n  0.05"..
        "\n\n\"- Restore\" settings affect \"Restore Xyz\" potions."..
        "\n\"- Other\" settings affect all other potions."..
        "\n\nIf an effect reaches its Recommended Maximum Magnitude, the effect duration will be increased beyond what is listed."..
        "\n\nPotions with multiple effects are not rebalanced."..
        " Potions that do not have an obvious Tier (Bargain, Cheap, Standard, Quality, Exclusive) are not rebalanced."..
        " Potions created by the player are not rebalanced.",
    })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.restore_magickaCost) do

        page:createSlider({
            label = string.format("T%d Magicka Cost - Restore", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.restore_magickaCost,
                id = tier,
            }),
            min = 0,
            max = 300,
            step = 0.01,
            jump = 1,
            decimalPlaces = 2,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.restore_duration) do

        page:createSlider({
            label = string.format("T%d Duration - Restore", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.restore_duration,
                id = tier,
            }),
            min = 0,
            max = 300,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.other_magickaCost) do

        page:createSlider({
            label = string.format("T%d Magicka Cost - Other", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.other_magickaCost,
                id = tier,
            }),
            min = 0,
            max = 300,
            step = 0.01,
            jump = 1,
            decimalPlaces = 2,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.other_duration) do

        page:createSlider({
            label = string.format("T%d Duration - Other", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.other_duration,
                id = tier,
            }),
            min = 0,
            max = 300,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.weight) do

        page:createSlider({
            label = string.format("T%d Weight", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.weight,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.01,
            jump = 0.25,
            decimalPlaces = 2,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.value) do

        page:createSlider({
            label = string.format("T%d Value", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.value,
                id = tier,
            }),
            min = 0,
            max = 1000,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.prefix) do

        page:createTextField({
            label = string.format("T%d Name Prefix", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.prefix,
                id = tier,
            }),
        })

    end

    page:createInfo({ text = "------------------------------" })

    for tier, _ in util.sortedPairs(mcmConfig.alchemy.tier.suffix) do

        page:createTextField({
            label = string.format("T%d Name Suffix", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.alchemy.tier.suffix,
                id = tier,
            }),
        })

    end

end

local function createAlchemyHomePage(template)

    local page = template:createSideBarPage({ label = "Home" })

    page:createYesNoButton({
        label = "Potion Rebalance Enabled",
        description =
            "Yes = Updates basic potions according to the settings in the \"Magic Rebalance 5: Potions\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.alchemy.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.alchemy,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Standardize Potion Names",
        description =
            "Yes = Potion names are updated to use the prefixes and suffixes specified on the \"Tier\" tab."..
            " The default settings allow potions to sort by effect, then by Tier."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.alchemy.standardizeNames),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.alchemy,
            id = "standardizeNames",
        }),
        restartRequired = true,
    })

end

local function createSpellRestoreDefaultsPage(template)

    local page = template:createSideBarPage({ label = "Restore Defaults" })

    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Spell Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 4: Spells\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearSpellAonTables()
            util.deepMerge(mcmConfig.spell, defaultMcmConfig.spell)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore \"Home\" Defaults",
        description = "Restores the default values of all settings on the \"Home\" tab",
        callback = function()
            mcmConfig.spell.rebalanceEnabled = defaultMcmConfig.spell.rebalanceEnabled
            mcmConfig.spell.updateSpellEffects = defaultMcmConfig.spell.updateSpellEffects
            mcmConfig.spell.enforceLimitsOnPremadeSpells = defaultMcmConfig.spell.enforceLimitsOnPremadeSpells
            mcmConfig.spell.forceRecalculateAllMagickaCosts = defaultMcmConfig.spell.forceRecalculateAllMagickaCosts

            util.deepMerge(mcmConfig.spell.magnitudeVariance, defaultMcmConfig.spell.magnitudeVariance)

            mcmConfig.spell.addStartSpells = defaultMcmConfig.spell.addStartSpells
            mcmConfig.spell.addStartSpellsToArrille = defaultMcmConfig.spell.addStartSpellsToArrille
            mcmConfig.spell.startMagickaCost = defaultMcmConfig.spell.startMagickaCost

            mcmConfig.spell.addNpcSpells = defaultMcmConfig.spell.addNpcSpells
            mcmConfig.spell.npcTierCount = defaultMcmConfig.spell.npcTierCount

            mcmConfig.spell.removeWeakSpellsFromNonMerchants = defaultMcmConfig.spell.removeWeakSpellsFromNonMerchants
            mcmConfig.spell.removeForbiddenEffectsFromMerchants = defaultMcmConfig.spell.removeForbiddenEffectsFromMerchants
            mcmConfig.spell.removeBirthsignSpellsFromMerchants = defaultMcmConfig.spell.removeBirthsignSpellsFromMerchants
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore \"Starting Spells\" Defaults",
        description = "Restores the default values of all settings on the \"Starting Spells\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.spell.startEffectIds = util.deepCopy(defaultMcmConfig.spell.startEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"NPC Spells\" Defaults",
        description = "Restores the default values of all settings on the \"NPC Spells\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.spell.npcEffectIds = util.deepCopy(defaultMcmConfig.spell.npcEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"Weak Effects\" Defaults",
        description = "Restores the default values of all settings on the \"Weak Effects\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.spell.weakEffectIds = util.deepCopy(defaultMcmConfig.spell.weakEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"Forbidden Effects\" Defaults",
        description = "Restores the default values of all settings on the \"Forbidden Effects\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.spell.forbiddenEffectIds = util.deepCopy(defaultMcmConfig.spell.forbiddenEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

end

local function createSpellForbiddenEffectsPage(template)

    spellForbiddenEffectsPage = template:createExclusionsPage{
        label = "Forbidden Effects",
        description = "Spells with forbidden effects are removed from spell-merchant NPCs.",
        leftListLabel = "Forbidden Effects",
        rightListLabel = "Non-Forbidden Effects",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.spell,
            id = "forbiddenEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.spell.forbiddenEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback(),
            },
        },
    }

end

local function createSpellWeakEffectsPage(template)

    spellWeakEffectsPage = template:createExclusionsPage{
        label = "Weak Effects",
        description = "Spells with only weak effects are removed from non-spell-merchant NPCs.",
        leftListLabel = "Weak Effects",
        rightListLabel = "Non-Weak Effects",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.spell,
            id = "weakEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.spell.weakEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback(),
            },
        },
    }

end

local function createSpellNpcEffectsPage(template)

    template:createExclusionsPage{
        label = "NPC Spells",
        description = "For each NPC effect, one or more NPC spells are created.",
        leftListLabel = "NPC Effects",
        rightListLabel = "Non-NPC Effects",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.spell,
            id = "npcEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.spell.npcEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback_VanillaOnly(),
            },
        },
    }

end

local function createSpellStartEffectsPage(template)

    template:createExclusionsPage{
        label = "Starting Spells",
        description = "For each starting effect, one starting spell are created.",
        leftListLabel = "Starting Effects",
        rightListLabel = "Non-Starting Effects",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.spell,
            id = "startEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.spell.startEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback_VanillaOnly({
                    [tes3.effect.restoreAttribute] = true,
                    [tes3.effect.fortifyAttribute] = true,
                    [tes3.effect.damageAttribute] = true,
                    [tes3.effect.drainAttribute] = true,
                    [tes3.effect.absorbAttribute] = true,
                    [tes3.effect.restoreSkill] = true,
                    [tes3.effect.fortifySkill] = true,
                    [tes3.effect.damageSkill] = true,
                    [tes3.effect.drainSkill] = true,
                    [tes3.effect.absorbSkill] = true,
                }),
            },
        },
    }

end

local function createSpellHomePage(template)

    local page = template:createSideBarPage({ label = "Home" })

    page:createYesNoButton({
        label = "Spell Rebalance Enabled",
        description =
            "Yes = Updates every spell in the game according to the settings in the \"Magic Rebalance 4: Spells\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Update Spell Effects",
        description =
            "Yes = Updates the effects of 600+ vanilla spells."..
            "\n\nEach spell was manually assigned a Tier (0.5 through 4.0), a duration multiplier, and an area."..
            " Magnitudes and durations are calculated using the spell's Tier and the settings in the \"Magic Rebalance 3: Limits\" section."..
            " In most scenarios, the formulas for calculating magnitude and duration are:"..
            "\n\nEffect Magnitude ="..
            "\n  Recommended Minimum Magnitude *"..
            "\n  Spell Tier"..
            "\n\nEffect Duration ="..
            "\n  Recommended Minimum Duration *"..
            "\n  Magnitude Overflow"..
            "\n\nWith this mod's default settings:"..
            "\n  Fire Damage: T1 = 30 pts. T4 = 120 pts."..
            "\n  Absorb Health: T1 = 20 pts. T4 = 80 pts."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.updateSpellEffects)..
            "\n\nSPECIAL: My spell effect overrides are all defined in this mod's spellList.lua file."..
            " If you're feeling adventurous, you can always modify that file to make changes of your own."..
            " This mod even comes with the spreadsheet I used to generate the contents of that file.",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "updateSpellEffects",
        }),
    })

    page:createYesNoButton({
        label = "Enforce Limits on Premade Spells",
        description =
            "Yes = Updates premade spells so they respect the configured min/max duration/magnitude limits."..
            " Recommended min/max limits are ignored."..
            " The relative power of updated spell effects is kept the same."..
            " Increasing duration will decrease magnitude, decreasing duration will increase magnitude, etc."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.enforceLimitsOnPremadeSpells),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "enforceLimitsOnPremadeSpells",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Force Recalculate ALL Magicka Costs",
        description =
            "Yes = Always recalculate EVERY spell's magicka cost, no matter what."..
            " This causes spells that were purposefully given a discounted magicka cost to be made more expensive."..
            "\n\nNo = Only recalculate a spell's magicka cost when it seems safe to do so. These safe scenarios are detailed below:"..
            "\n\n1. The spell's AutoCalc flag is true."..
            " You see this a lot in the base game, but many mods set AutoCalc to false so NPCs don't use the mod's new spells."..
            "\n\n2. The spell's original calculated magicka cost is equal to its original manually-specified magicka cost."..
            " In these scenarios, I'm assuming the spell was only set to AutoCalc false to prevent NPCs from using the spell."..
            "\n\n3. The spell's new calculated magicka cost is less than its original manually-specified magicka cost."..
            " These spells were likely given a discounted magicka cost on purpose."..
            " This at least prevents them from becoming MORE expensive than normal."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.forceRecalculateAllMagickaCosts),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "forceRecalculateAllMagickaCosts",
        }),
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createSlider({
        label = "Magnitude Variance - Restore",
        description =
            "Determines the minimum and maximum magnitude of updated and created spells."..
            " Final results are rounded to multiples of 5 or 10, when possible."..
            "\n\nMinimum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 - Variance / 100)"..
            "\n\nMaximum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 + Variance / 100)"..
            "\n\nAffects:"..
            "\n  Restore Health/Magicka/Fatigue"..
            "\n\nDefault Value: " .. defaultMcmConfig.spell.magnitudeVariance.restore,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell.magnitudeVariance,
            id = "restore",
        }),
        min = 1,
        max = 100,
        step = 0.1,
        jump = 5,
        decimalPlaces = 1,
    })

    page:createSlider({
        label = "Magnitude Variance - Attack",
        description =
            "Determines the minimum and maximum magnitude of updated and created spells."..
            " Final results are rounded to multiples of 5 or 10, when possible."..
            "\n\nMinimum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 - Variance / 100)"..
            "\n\nMaximum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 + Variance / 100)"..
            "\n\nAffects:"..
            "\n  Elemental Damage"..
            "\n  Damage (All Effects)"..
            "\n  Drain Health/Magicka/Fatigue"..
            "\n  Absorb Health/Magicka/Fatigue"..
            "\n\nDefault Value: " .. defaultMcmConfig.spell.magnitudeVariance.attack,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell.magnitudeVariance,
            id = "attack",
        }),
        min = 1,
        max = 100,
        step = 0.1,
        jump = 5,
        decimalPlaces = 1,
    })

    page:createSlider({
        label = "Magnitude Variance - Debuff",
        description =
            "Determines the minimum and maximum magnitude of updated and created spells."..
            " Final results are rounded to multiples of 5 or 10, when possible."..
            "\n\nMinimum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 - Variance / 100)"..
            "\n\nMaximum Magnitude = "..
            "\n  Average Magnitude *"..
            "\n  (1 + Variance / 100)"..
            "\n\nAffects:"..
            "\n  Sound, Blind, Burden"..
            "\n  Drain Attribute/Skill"..
            "\n  Absorb Attribute/Skill"..
            "\n\nDefault Value: " .. defaultMcmConfig.spell.magnitudeVariance.debuff,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell.magnitudeVariance,
            id = "debuff",
        }),
        min = 1,
        max = 100,
        step = 0.1,
        jump = 5,
        decimalPlaces = 1,
    })

    page:createInfo({ text = "------------------------------" })

    page:createYesNoButton({
        label = "Add Starting Spells",
        description =
            "Yes = Creates new starting spells and removes the starting spell flag from all existing spells."..
            " The list of starting spells can be customized in the \"Starting Spells\" tab."..
            "\n\nOnce spells are created in a save file, they are stored in all subsequent saves."..
            " Spells created this way are not removed if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.addStartSpells),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "addStartSpells",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Add Starting Spells to Arrille",
        description =
            "Yes = Spells created by \"Add Starting Spells\" are added to Arrille in Seyda Neen."..
            " This allows you to purchase starting spells you didn't qualify for."..
            " These spells cannot be obtained anywhere else."..
            "\n\nSpells are added when the NPC is encountered."..
            " Spells added this way are not removed if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.addStartSpellsToArrille),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "addStartSpellsToArrille",
        }),
    })

    page:createSlider({
        label = "Starting Spell Magicka Cost",
        description =
            "Spells created by \"Add Starting Spells\" cost this much magicka."..
            " If an effect is too expensive or its minimum limits are too high, its magicka cost might be higher than this setting."..
            "\n\nDefault Value: " .. defaultMcmConfig.spell.startMagickaCost,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "startMagickaCost",
        }),
        min = 0,
        max = 20,
        step = 0.01,
        jump = 1,
        decimalPlaces = 2,
    })

    page:createInfo({ text = "------------------------------" })

    page:createYesNoButton({
        label = "Add NPC Spells",
        description =
            "Yes = Creates new spells for NPCs to use."..
            "\n\nMost NPCs can cast any spell with the AutoCalc construction set flag set to true."..
            " This setting updates all vanilla spells to AutoCalc false and adds many new spells with AutoCalc true."..
            " NPCs can still cast spells explicitly assigned to them, even when this setting is enabled."..
            "\n\nThis makes NPCs more likely to cast powerful spells."..
            " The list of NPC spells can be customized in the \"NPC Spells\" tab."..
            "\n\nOnce spells are created in a save file, they are stored in all subsequent saves."..
            " Spells created this way are not removed if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.addNpcSpells),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "addNpcSpells",
        }),
        restartRequired = true,
    })

    page:createSlider({
        label = "NPC Spell Tiers",
        description =
            "Spells created by \"Add NPC Spells\" are created for Tier 1 through Tier X."..
            " This setting determines Tier X."..
            " NPC spells cost 10 magicka per tier."..
            "\n\nDefault Value: " .. defaultMcmConfig.spell.npcTierCount,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "npcTierCount",
        }),
        min = 1,
        max = 6,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })

    page:createInfo({ text = "------------------------------" })

    page:createYesNoButton({
        label = "Remove NPC Spells - Weak Spells",
        description =
            "Yes = Spells with only weak effects are removed from non-spell-merchant NPCs."..
            "\n\nThis prevents NPCs from wasting their magicka on useless spells like \"Weakness to Common Disease\", even when those spells are explicitly assigned to them."..
            " The list of weak effects can be customized in the \"Weak Effects\" tab."..
            "\n\nSpells are removed when the NPC is encountered."..
            " Spells removed this way are not re-added if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.removeWeakSpellsFromNonMerchants),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "removeWeakSpellsFromNonMerchants",
        }),
    })

    page:createYesNoButton({
        label = "Remove NPC Spells - Forbidden Effects",
        description =
            "Yes = Spells with forbidden effects are removed from spell-merchant NPCs."..
            "\n\nThis prevents the player from acquiring spells with overpowered or useless effects."..
            " The list of forbidden effects can be customized in the \"Forbidden Effects\" tab."..
            "\n\nSpells are removed when the NPC is encountered."..
            " Spells removed this way are not re-added if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.removeForbiddenEffectsFromMerchants),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "removeForbiddenEffectsFromMerchants",
        }),
    })

    page:createYesNoButton({
        label = "Remove NPC Spells - Birthsign Spells",
        description =
            "Yes = Vanilla birthsign spells are removed from spell-merchant NPCs."..
            "\n\nIn the base game, Ygfa in Fort Pelagiad has the \"Blessed Touch\" spell from the Ritual birthsign."..
            " This setting removes the spell from Ygfa and fixes similar mistakes in other mods."..
            "\n\nSpells are removed when the NPC is encountered."..
            " Spells removed this way are not re-added if this setting is later disabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.removeBirthsignSpellsFromMerchants),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "removeBirthsignSpellsFromMerchants",
        }),
    })

end

local function createLimitSliders(page, effectId, isFirstEffect)

    if mcmConfig.shared.excludedEffectIds[effectId] then return end

    local magicEffect = tes3.getMagicEffect(effectId)
    local defaultLimits = defaultMcmConfig.limit.effectLimits[effectId]

    if magicEffect.hasNoMagnitude and magicEffect.hasNoDuration then return end

    local displayName = magicEffect.name
    if displayName == nil or displayName == "" then displayName = string.format("[%d]", effectId) end

    local     dvMinDuration = ""
    local  dvRecMinDuration = ""
    local     dvMaxDuration = ""
    local    dvMinMagnitude = ""
    local dvRecMinMagnitude = ""
    local dvRecMaxMagnitude = ""
    local    dvMaxMagnitude = ""

    if defaultLimits ~= nil then -- modded effects might not have default values
            dvMinDuration = "\nDefault Value: " .. util.numberToString(defaultLimits.minDuration     or 0, 0)
         dvRecMinDuration = "\nDefault Value: " .. util.numberToString(defaultLimits.recMinDuration  or 0, 0)
            dvMaxDuration = "\nDefault Value: " .. util.numberToString(defaultLimits.maxDuration     or 0, 0)
           dvMinMagnitude = "\nDefault Value: " .. util.numberToString(defaultLimits.minMagnitude    or 0, 0)
        dvRecMinMagnitude = "\nDefault Value: " .. util.numberToString(defaultLimits.recMinMagnitude or 0, 0)
        dvRecMaxMagnitude = "\nDefault Value: " .. util.numberToString(defaultLimits.recMaxMagnitude or 0, 0)
           dvMaxMagnitude = "\nDefault Value: " .. util.numberToString(defaultLimits.maxMagnitude    or 0, 0)
    end

    if not isFirstEffect then page:createInfo({ text = "------------------------------" }) end

    if not magicEffect.hasNoDuration then

        page:createSlider({
            label = string.format("%s - Dur Min", displayName),
            description =
                displayName ..
                "\n  Duration Minimum"..
                "\n" .. dvMinDuration,
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.limit.effectLimits[effectId],
                id = "minDuration",
            }),
            min = 0,
            max = 300,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

        if magicEffect.sourceMod ~= nil then

            page:createSlider({
                label = string.format("%s - Dur Min (Rec)", displayName),
                description =
                    displayName ..
                    "\n  Duration Minimum (Recommended)"..
                    "\n" .. dvRecMinDuration,
                variable = mwse.mcm.createTableVariable({
                    table = mcmConfig.limit.effectLimits[effectId],
                    id = "recMinDuration",
                }),
                min = 0,
                max = 300,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })

        end

        page:createSlider({
            label = string.format("%s - Dur Max", displayName),
            description =
                displayName ..
                "\n  Duration Maximum"..
                "\n" .. dvMaxDuration,
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.limit.effectLimits[effectId],
                id = "maxDuration",
            }),
            min = 0,
            max = 300,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

    end

    if not magicEffect.hasNoMagnitude then

        page:createSlider({
            label = string.format("%s - Mag Min", displayName),
            description =
                displayName ..
                "\n  Magnitude Minimum"..
                "\n" .. dvMinMagnitude,
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.limit.effectLimits[effectId],
                id = "minMagnitude",
            }),
            min = 0,
            max = 500,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

        if magicEffect.sourceMod ~= nil then

            page:createSlider({
                label = string.format("%s - Mag Min (Rec)", displayName),
                description =
                    displayName ..
                    "\n  Magnitude Minimum (Recommended)"..
                    "\n" .. dvRecMinMagnitude,
                variable = mwse.mcm.createTableVariable({
                    table = mcmConfig.limit.effectLimits[effectId],
                    id = "recMinMagnitude",
                }),
                min = 0,
                max = 500,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })

            page:createSlider({
                label = string.format("%s - Mag Max (Rec)", displayName),
                description =
                    displayName ..
                    "\n  Magnitude Maximum (Recommended)"..
                    "\n" .. dvRecMaxMagnitude,
                variable = mwse.mcm.createTableVariable({
                    table = mcmConfig.limit.effectLimits[effectId],
                    id = "recMaxMagnitude",
                }),
                min = 0,
                max = 500,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })

        end

        page:createSlider({
            label = string.format("%s - Mag Max", displayName),
            description =
                displayName ..
                "\n  Magnitude Maximum"..
                "\n" .. dvMaxMagnitude,
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.limit.effectLimits[effectId],
                id = "maxMagnitude",
            }),
            min = 0,
            max = 500,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })

    end

end

local function createLimitModdedPages(template)

    for sourceMod, effectInfos in util.sortedPairs(moddedMagicEffects, util.sortFunction_ByStringKey) do

        if sourceMod == "zzz" then sourceMod = "Unknown" end

        local page = template:createSideBarPage({ label = sourceMod })

        page.sidebar:createInfo({ text =
            "The spellmaking and enchanting UIs will respect the Minimums and Maximums on this page."
        })

        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = sourceMod })
        page:createInfo({ text = "------------------------------" })

        local isFirstEffect = true

        for _, effectInfo in util.sortedPairs(effectInfos, util.getSortFunction_ByValueNameThenKey(effectInfos)) do
            createLimitSliders(page, effectInfo.id, isFirstEffect)
            isFirstEffect = false
        end

    end

end

local function createLimitVanillaPages(template)

    local categories = effectList.getCategories()

    for _, category in ipairs(categories) do

        local page = template:createSideBarPage({ label = category.name })

        page.sidebar:createInfo({ text =
            "The spellmaking and enchanting UIs will respect the Minimums and Maximums on this page."..
            " Spellmaking and enchanting do not care about the Recommended settings."..
            "\n\nRebalanced spells will respect the Recommended Minimums and Maximums."..
            " If no recommendations are present, spells will fall back to respecting the normal Minimums and Maximums."..
            "\n\nRebalanced potions will respect the Recommended Maximum Magnitude."..
            " If no recommendation is present, potions will fall back to respecting the Maximum Magnitude."
        })

        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = category.name })
        page:createInfo({ text = "------------------------------" })

        local isFirstEffect = true

        for _, effectId in ipairs(category.effectIds) do
            createLimitSliders(page, effectId, isFirstEffect)
            isFirstEffect = false
        end

    end

end

local function createLimitHomePage(template)

    local page = template:createSideBarPage({ label = "Home" })

    limitHomePage_Info = page.sidebar:createInfo({ text =
        "Start a new game or load a save to see the limit tabs for effects added by mods."
    })

    page:createYesNoButton({
        label = "Creation Limits Enabled",
        description =
            "Yes = When creating custom spells and enchantments, effect durations and magnitudes are contrained by the settings in the \"Magic Rebalance 3: Limits\" section."..
            "\n\nNOTE: The Spell Rebalance and Potion Rebalance also use the limits in this section, but that functionality is not tied to this setting and cannot be toggled off."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.limit.limitsEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.limit,
            id = "limitsEnabled",
        }),
    })

    page:createYesNoButton({
        label = "One Second Minimum Duration",
        description =
            "Yes = When creating custom spells and enchantments, effect duration cannot be reduced below one second."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.limit.oneSecondMinDuration),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.limit,
            id = "oneSecondMinDuration",
        }),
    })

end

local function createMagicEffectRestoreDefaultsPage(template)

    local page = template:createSideBarPage({ label = "Restore Defaults" })

    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Effect Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 2: Effects\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearMagicEffectAonTables()
            util.deepMerge(mcmConfig.magicEffect, defaultMcmConfig.magicEffect)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore \"Home\" Defaults",
        description = "Restores the default values of all settings on the \"Magic Rebalance 2: Effects\" section's \"Home\" tab.",
        callback = function()
            mcmConfig.magicEffect.rebalanceEnabled = defaultMcmConfig.magicEffect.rebalanceEnabled
            mcmConfig.magicEffect.elementalShieldMult = defaultMcmConfig.magicEffect.elementalShieldMult
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore \"Costs\" Defaults",
        description = "Restores the default values of all settings on the \"Vanilla Costs\" and \"Modded Costs\" tabs.",
        callback = function()
            config.clearEffectCostsAonTable()
            util.deepMerge(mcmConfig.magicEffect.effectCosts, defaultMcmConfig.magicEffect.effectCosts)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"No Spellmaking\" Defaults",
        description = "Restores the default values of all settings on the \"No Spellmaking\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.magicEffect.noSpellmakingEffectIds = util.deepCopy(defaultMcmConfig.magicEffect.noSpellmakingEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"No Enchanting\" Defaults",
        description = "Restores the default values of all settings on the \"No Enchanting\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.magicEffect.noEnchantingEffectIds = util.deepCopy(defaultMcmConfig.magicEffect.noEnchantingEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Limit Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 3: Limits\" section.",
        callback = function()
            config.clearLimitAonTables()
            util.deepMerge(mcmConfig.limit, defaultMcmConfig.limit)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore \"Home\" Defaults",
        description = "Restores the default values of all settings on the \"Magic Rebalance 3: Limits\" section's \"Home\" tab.",
        callback = function()
            mcmConfig.limit.limitsEnabled = defaultMcmConfig.limit.limitsEnabled
            mcmConfig.limit.oneSecondMinDuration = defaultMcmConfig.limit.oneSecondMinDuration
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore \"Non-Home\" Defaults",
        description = "Restores the default values of all settings in the \"Magic Rebalance 3: Limits\" section EXCEPT the \"Home\" tab.",
        callback = function()
            config.clearEffectLimitsAonTable()
            util.deepMerge(mcmConfig.limit.effectLimits, defaultMcmConfig.limit.effectLimits)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

end

local function createMagicEffectNoEnchantingEffectsPage(template)

    magicEffectNoEnchantingEffectsPage = template:createExclusionsPage{
        label = "No Enchanting",
        description = "Add effects to the \"No Enchanting\" list to exclude them from enchanting.",
        leftListLabel = "No Enchanting",
        rightListLabel = "Allow Enchanting",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.magicEffect,
            id = "noEnchantingEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.magicEffect.noEnchantingEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback(),
            },
        },
    }

end

local function createMagicEffectNoSpellmakingEffectsPage(template)

    magicEffectNoSpellmakingEffectsPage = template:createExclusionsPage{
        label = "No Spellmaking",
        description = "Add effects to the \"No Spellmaking\" list to exclude them from spellmaking.",
        leftListLabel = "No Spellmaking",
        rightListLabel = "Allow Spellmaking",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.magicEffect,
            id = "noSpellmakingEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.magicEffect.noSpellmakingEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback(),
            },
        },
    }

end

local function createBaseMagickaCostSlider(page, effectId)

    if mcmConfig.shared.excludedEffectIds[effectId] then return end

    local magicEffect = tes3.getMagicEffect(effectId)
    local unmodifiedMagicEffect = common.getUnmodifiedMagicEffect(effectId)
    local defaultCosts = defaultMcmConfig.magicEffect.effectCosts[effectId]
    local mmsjd = getMinMaxStepJumpDecimalPlaces_BaseMagickaCost(magicEffect)

    local displayName = magicEffect.name
    if displayName == nil or displayName == "" then displayName = string.format("[%d]", effectId) end

    local defaultValueString = "" -- modded effects might not have default values
    if defaultCosts ~= nil then defaultValueString = "\nDefault Value: " .. util.numberToString(defaultCosts.baseMagickaCost or 0, mmsjd[5]) end

    page:createSlider({
        label = string.format("%s - Cost", displayName),
        description =
            displayName ..
            "\n  Base Magicka Cost"..
            "\n" .. defaultValueString ..
            "\nOriginal Value: " .. util.numberToString(unmodifiedMagicEffect.baseMagickaCost, mmsjd[5]),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.magicEffect.effectCosts[effectId],
            id = "baseMagickaCost",
        }),
        min = mmsjd[1],
        max = mmsjd[2],
        step = mmsjd[3],
        jump = mmsjd[4],
        decimalPlaces = mmsjd[5],
    })

end

local function createMagicEffectCostsModdedPage_Full()

    if magicEffectCostsModdedPage == nil then return end
    if magicEffectCostsModdedPage_Info == nil then return end

    local page = magicEffectCostsModdedPage

    magicEffectCostsModdedPage_Info.text =
        "Magicka Cost = "..
        "\n  Base Magicka Cost *"..
        "\n  Avg Magnitude *"..
        "\n  Duration *"..
        "\n  0.05"..
        "\n\nMagicka cost is multiplied by 1.5 for On Target effects."..
        " Magicka cost is increased further by effect area."..
        "\n\nEffects with their slider set to zero will be treated the same as excluded effects."..
        " Excluded effects, and spells/potions with those effects, will not be rebalanced by this mod."

    for sourceMod, effectInfos in util.sortedPairs(moddedMagicEffects, util.sortFunction_ByStringKey) do

        if sourceMod == "zzz" then sourceMod = "Unknown" end

        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = sourceMod })
        page:createInfo({ text = "------------------------------" })

        for _, effectInfo in util.sortedPairs(effectInfos, util.getSortFunction_ByValueNameThenKey(effectInfos)) do
            createBaseMagickaCostSlider(page, effectInfo.id)
        end

    end

end

local function createMagicEffectCostsModdedPage_Stub(template)

    magicEffectCostsModdedPage = template:createSideBarPage({ label = "Modded Costs" })

    magicEffectCostsModdedPage_Info = magicEffectCostsModdedPage.sidebar:createInfo({ text =
        "Start a new game or load a save to see the settings on this page."
    })

end

local function createMagicEffectCostsVanillaPage(template)

    local page = template:createSideBarPage({ label = "Vanilla Costs" })

    page.sidebar:createInfo({ text =
        "Magicka Cost = "..
        "\n  Base Magicka Cost *"..
        "\n  Avg Magnitude *"..
        "\n  Duration *"..
        "\n  0.05"..
        "\n\nMagicka cost is multiplied by 1.5 for On Target effects."..
        " Magicka cost is increased further by effect area."..
        "\n\nEffects with their slider set to zero will be treated the same as excluded effects."..
        " Excluded effects, and spells/potions with those effects, will not be rebalanced by this mod."
    })

    local categories = effectList.getCategories()

    for _, category in ipairs(categories) do

        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = category.name })
        page:createInfo({ text = "------------------------------" })

        for _, effectId in ipairs(category.effectIds) do
            createBaseMagickaCostSlider(page, effectId)
        end

    end

end

local function createMagicEffectHomePage(template)

    local page = template:createSideBarPage({ label = "Home" })

    page:createYesNoButton({
        label = "Magic Effect Rebalance Enabled",
        description =
            "Yes = Updates every magic effect in the game according to the settings in the \"Magic Rebalance 2: Effects\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.magicEffect.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.magicEffect,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createSlider({
        label = "Elemental Shield Mult",
        description =
            "Determines the damage dealt to attackers when they hit a creature affected by Fire, Frost, or Lightning Shield."..
            "\n\nDamage Per Hit ="..
            "\n  Spell Magnitude *"..
            "\n  Elemental Shield Mult"..
            "\n\nDefault Value: " .. defaultMcmConfig.magicEffect.elementalShieldMult ..
            "\nVanilla Value: 0.1",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.magicEffect,
            id = "elementalShieldMult",
        }),
        min = 0,
        max = 2,
        step = 0.01,
        jump = 0.05,
        decimalPlaces = 2,
    })

end

local function createMainRestoreDefaultsPage(template)

    local page = template:createSideBarPage({ label = "Restore Defaults" })

    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Defaults",
        description = "Restores the default values of ALL settings EVERYWHERE in this mod.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearAllAonTables()
            util.deepMerge(mcmConfig, defaultMcmConfig)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore ALL Effect Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 2: Effects\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearMagicEffectAonTables()
            util.deepMerge(mcmConfig.magicEffect, defaultMcmConfig.magicEffect)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore ALL Limit Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 3: Limits\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearLimitAonTables()
            util.deepMerge(mcmConfig.limit, defaultMcmConfig.limit)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })

    page:createButton({
        buttonText = "Restore ALL Spell Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 4: Spells\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearSpellAonTables()
            util.deepMerge(mcmConfig.spell, defaultMcmConfig.spell)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore ALL Potion Defaults",
        description = "Restores the default values of ALL settings in the \"Magic Rebalance 5: Potions\" section.",
        callback = function()
            config.convertAllEffectNamesToIds()
            config.clearAlchemyAonTables()
            util.deepMerge(mcmConfig.alchemy, defaultMcmConfig.alchemy)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createButton({
        buttonText = "Restore \"Home\" Defaults",
        description = "Restores the default values of all settings on the \"Home\" tab.",
        callback = function()
            mcmConfig.shared.modEnabled = defaultMcmConfig.shared.modEnabled
            mcmConfig.shared.loggingEnabled = defaultMcmConfig.shared.loggingEnabled

            mcmConfig.magicEffect.rebalanceEnabled = defaultMcmConfig.magicEffect.rebalanceEnabled
            mcmConfig.limit.limitsEnabled = defaultMcmConfig.limit.limitsEnabled
            mcmConfig.spell.rebalanceEnabled = defaultMcmConfig.spell.rebalanceEnabled
            mcmConfig.alchemy.rebalanceEnabled = defaultMcmConfig.alchemy.rebalanceEnabled

            mcmConfig.shared.useMcpAreaFormulaEverywhere = defaultMcmConfig.shared.useMcpAreaFormulaEverywhere
            mcmConfig.shared.fixSpellmakingTargetCost = defaultMcmConfig.shared.fixSpellmakingTargetCost
            mcmConfig.shared.newEnchantingCostCalculation = defaultMcmConfig.shared.newEnchantingCostCalculation
            mcmConfig.shared.enchantmentConstantDurationMult = defaultMcmConfig.shared.enchantmentConstantDurationMult
        end,
        restartRequired = true,
    })

    page:createButton({
        buttonText = "Restore \"Excluded Effects\" Defaults",
        description = "Restores the default values of all settings on the \"Excluded Effects\" tab.",
        callback = function()
            config.convertAllEffectNamesToIds()
            mcmConfig.shared.excludedEffectIds = util.deepCopy(defaultMcmConfig.shared.excludedEffectIds)
            config.convertAllEffectIdsToNames()
        end,
        restartRequired = true,
    })

end

local function createMainExcludedEffectsPage(template)

    mainExcludedEffectsPage = template:createExclusionsPage{
        label = "Excluded Effects",
        description = "Excluded effects, and spells/potions with those effects, will not be rebalanced by this mod.",
        leftListLabel = "Excluded Effects (Requires Restart)",
        rightListLabel = "Included Effects (Requires Restart)",
        variable = mwse.mcm.createTableVariable{
            table = tempConfig.shared,
            id = "excludedEffectNames",
        },
        filters = {
            {
                label = "Defaults",
                callback = getExclusionsCallback(defaultMcmConfig.shared.excludedEffectIds)
            },
            {
                label = "All Effects",
                callback = getExclusionsCallback(),
            },
        },
        inGameOnly = true,
    }

end

local function createMainHomePage(template)

    local page = template:createSideBarPage({ label = "Home" })

    page:createYesNoButton({
        label = "Mod Enabled",
        description =
            "No = Disables EVERYTHING in this mod."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.modEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "modEnabled",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Logging Enabled",
        description =
            "Yes = Debug messages will appear in the MWSE.log file located in your base Morrowind install directory."..
            "\n\nThis log file will list all magic effects, spells, and potions, if they were changed, and how they were changed."..
            " For the best results: restart the game, load a save, then check the log file."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.loggingEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "loggingEnabled",
        }),
    })

    page:createInfo({ text = "------------------------------" })

    page:createYesNoButton({
        label = "Magic Effect Rebalance Enabled",
        description =
            "Yes = Updates every magic effect in the game according to the settings in the \"Magic Rebalance 2: Effects\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.magicEffect.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.magicEffect,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Creation Limits Enabled",
        description =
            "Yes = When creating custom spells and enchantments, effect durations and magnitudes are contrained by the settings in the \"Magic Rebalance 3: Limits\" section."..
            "\n\nNOTE: The Spell Rebalance and Potion Rebalance also use the limits in this section, but that functionality is not tied to this setting and cannot be toggled off."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.limit.limitsEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.limit,
            id = "limitsEnabled",
        }),
    })

    page:createYesNoButton({
        label = "Spell Rebalance Enabled",
        description =
            "Yes = Updates every spell in the game according to the settings in the \"Magic Rebalance 4: Spells\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.spell.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.spell,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createYesNoButton({
        label = "Potion Rebalance Enabled",
        description =
            "Yes = Updates basic potions according to the settings in the \"Magic Rebalance 5: Potions\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.alchemy.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.alchemy,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })

    page:createInfo({ text = "------------------------------" })

    page:createYesNoButton({
        label = "Use MCP Area Formula Everywhere",
        description =
            "Yes = The Morrowind Code Patch \"Spellmaker area effect cost\" patch now applies ALL spells and ALL custom enchantments."..
            "\n\nThis setting will only have an effect when the MCP patch is applied."..
            " Non-custom spells will only be affected when \"Spell Rebalance Enabled\" is set to \"Yes\"."..
            " Custom enchantments will only be affected when \"New Enchantment Cost Calculation\" is set to \"Yes\"."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.useMcpAreaFormulaEverywhere),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "useMcpAreaFormulaEverywhere",
        }),
    })

    page:createYesNoButton({
        label = "Fix Spellmaking Target Cost",
        description =
            "Yes = Custom spells with multiple \"Target\" effects no longer cost more than they should."..
            " The spell's magicka cost is corrected when you finish spellmaking."..
            "\n\nIf \"Spell Rebalance Enabled\" is set to \"Yes\", custom spell costs are fixed when you load a save, regardless of this setting."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.fixSpellmakingTargetCost),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "fixSpellmakingTargetCost",
        }),
    })

    page:createYesNoButton({
        label = "New Enchanting Cost Calculation",
        description =
            "Yes = Enchanting now works the same way as spellmaking: you can add multiple effects without increasing the cost."..
            " Multiple \"Target\" effects no longer cost more than they should."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.newEnchantingCostCalculation),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "newEnchantingCostCalculation",
        }),
    })

    page:createSlider({
        label = "Enchantment Constant Duration Mult",
        description =
            "When \"New Enchantment Cost Calculation\" is \"Yes\":"..
            " Custom constant effect enchantments cost the same as spells with this duration."..
            "\n\nThis is not tied to the GMST of the same name, but fulfills the same purpose."..
            " That GMST does not work correctly for effects without a magnitude, or effects with a selected magnitude of 0 or 1."..
            "\n\nThis setting's default value is higher than vanilla so effect costs can be decreased without making constant effect enchantments too powerful."..
            "\n\nDefault Value: " .. defaultMcmConfig.shared.enchantmentConstantDurationMult ..
            "\nVanilla Value: 100",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "enchantmentConstantDurationMult",
        }),
        min = 1,
        max = 500,
        step = 1,
        jump = 20,
        decimalPlaces = 0,
    })

end

local function initModdedMagicEffect(magicEffect)

    if magicEffect.id <= 142 then return end

    local sourceMod = common.getEffectIdSourceMod(magicEffect.id) or "zzz" -- "zzz" replaced later

    if moddedMagicEffects[sourceMod] == nil then
        moddedMagicEffects[sourceMod] = {}
    end

    table.insert(moddedMagicEffects[sourceMod], {
        name = magicEffect.name,
        id = magicEffect.id,
    })

end

local function initModdedMagicEffects()

    for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        initModdedMagicEffect(magicEffect)
    end

end


local this = {}

this.onLoaded = function(e)

    if alreadyLoaded then return end
    alreadyLoaded = true

    initModdedMagicEffects()
    createMagicEffectCostsModdedPage_Full()
    createLimitModdedPages(limitTemplate)

    if limitHomePage_Info == nil then return end
    if mainExcludedEffectsPage == nil then return end
    if magicEffectNoSpellmakingEffectsPage == nil then return end
    if magicEffectNoEnchantingEffectsPage == nil then return end
    if spellWeakEffectsPage == nil then return end
    if spellForbiddenEffectsPage == nil then return end

    limitHomePage_Info.text = ""
    mainExcludedEffectsPage.filters[2].callback = getExclusionsCallback()
    magicEffectNoSpellmakingEffectsPage.filters[2].callback = getExclusionsCallback()
    magicEffectNoEnchantingEffectsPage.filters[2].callback = getExclusionsCallback()
    spellWeakEffectsPage.filters[2].callback = getExclusionsCallback()
    spellForbiddenEffectsPage.filters[2].callback = getExclusionsCallback()

end

this.onModConfigReady = function(e)

    local mainTemplate = mwse.mcm.createTemplate({ name = "Magic Rebalance 1: Main" })
    mainTemplate.onClose = function() config.saveMcmConfig() end
    mainTemplate:register()

    createMainHomePage(mainTemplate)
    createMainExcludedEffectsPage(mainTemplate)
    createMainRestoreDefaultsPage(mainTemplate)

    local magicEffectTemplate = mwse.mcm.createTemplate({ name = "Magic Rebalance 2: Effects" })
    magicEffectTemplate.onClose = function() config.saveMcmConfig() end
    magicEffectTemplate:register()

    createMagicEffectHomePage(magicEffectTemplate)
    createMagicEffectCostsVanillaPage(magicEffectTemplate)
    createMagicEffectCostsModdedPage_Stub(magicEffectTemplate)
    createMagicEffectNoSpellmakingEffectsPage(magicEffectTemplate)
    createMagicEffectNoEnchantingEffectsPage(magicEffectTemplate)
    createMagicEffectRestoreDefaultsPage(magicEffectTemplate)

    limitTemplate = mwse.mcm.createTemplate({ name = "Magic Rebalance 3: Limits" })
    limitTemplate.onClose = function() config.saveMcmConfig() end
    limitTemplate:register()

    createLimitHomePage(limitTemplate)
    createLimitVanillaPages(limitTemplate)

    local spellTemplate = mwse.mcm.createTemplate({ name = "Magic Rebalance 4: Spells" })
    spellTemplate.onClose = function() config.saveMcmConfig() end
    spellTemplate:register()

    createSpellHomePage(spellTemplate)
    createSpellStartEffectsPage(spellTemplate)
    createSpellNpcEffectsPage(spellTemplate)
    createSpellWeakEffectsPage(spellTemplate)
    createSpellForbiddenEffectsPage(spellTemplate)
    createSpellRestoreDefaultsPage(spellTemplate)

    local alchemyTemplate = mwse.mcm.createTemplate({ name = "Magic Rebalance 5: Potions" })
    alchemyTemplate.onClose = function() config.saveMcmConfig() end
    alchemyTemplate:register()

    createAlchemyHomePage(alchemyTemplate)
    createAlchemyTierPage(alchemyTemplate)
    createAlchemyDetectTierBySearchTermPage(alchemyTemplate)
    createAlchemyRestoreDefaultsPage(alchemyTemplate)

end

return this
