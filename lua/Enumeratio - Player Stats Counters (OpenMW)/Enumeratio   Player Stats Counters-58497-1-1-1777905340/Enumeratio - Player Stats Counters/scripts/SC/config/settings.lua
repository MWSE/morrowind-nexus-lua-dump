local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mDef = require('scripts.SC.config.definition')

-- Setting group keys — each becomes a separate collapsible section
local healthKey   = "SettingsPlayerHealth"  .. mDef.MOD_NAME
local displayKey  = "Settings/" .. mDef.MOD_NAME .. "/1_Display"
local summaryKey  = "Settings/" .. mDef.MOD_NAME .. "/1a_Summary"
local statsKey    = "Settings/" .. mDef.MOD_NAME .. "/2_Stats"
local needsKey    = "Settings/" .. mDef.MOD_NAME .. "/3_PrimaryNeeds"
local interactKey = "Settings/" .. mDef.MOD_NAME .. "/4_Interactions"
local combatKey   = "Settings/" .. mDef.MOD_NAME .. "/5_Combat"
local magicKey    = "Settings/" .. mDef.MOD_NAME .. "/6_Magic"
local crimeKey    = "Settings/" .. mDef.MOD_NAME .. "/7_Crime"
local miscKey     = "Settings/" .. mDef.MOD_NAME .. "/8_Misc"
local insultKey   = "Settings/" .. mDef.MOD_NAME .. "/9_Insults"

local module = {}

local settingGroups = {
    -- ── Death counter + luck modifier ──────────────────────────
    [healthKey] = {
        order = 0,
        settings = {
            { key = "deathCounter", default = true, renderer = "checkbox" },
            { key = "luckModifierPerDeath", default = -1, renderer = mDef.renderers.number, argument = { min = -10, max = 10 } },
            { key = "showLuckChangeNotification", default = true, renderer = "checkbox" },
        },
    },
    -- ── Display options ────────────────────────────────────────
    [displayKey] = {
        order = 1,
        settings = {
            { key = "hideZeroCounters", default = true, renderer = "checkbox" },
            { key = "abbreviateNumbers", default = true, renderer = "checkbox" },
            { key = "useImperial", default = true, renderer = "checkbox" },
            { key = "statsOnLeftPanel", default = true, renderer = "checkbox" },
            { key = "sortSkillsAlpha", default = false, renderer = "checkbox" },
            {
                key = "sortCounters",
                default = "default",
                renderer = "select",
                argument = {
                    l10n = "StatCounters",
                    items = { "sortCounters_default", "sortCounters_alpha", "sortCounters_highest" },
                },
            },
        },
    },
    -- ── Career summary ────────────────────────────────────────
    [summaryKey] = {
        order = 1.5,
        settings = {
            { key = "enableSummaryPage", default = true, renderer = "checkbox" },
            { key = "summaryOnlyPopup", default = false, renderer = "checkbox" },
            {
                key = "summaryPageHotkey",
                default = "",
                renderer = "inputBinding",
                argument = {
                    key = "SC_ToggleSummaryPage",
                    type = "trigger",
                },
            },
        },
    },
    -- ── Stats ──────────────────────────────────────────────────
    [statsKey] = {
        order = 2,
        settings = {
            { key = "showAllStats", default = true, renderer = "checkbox" },
            { key = "showQuestCount", default = true, renderer = "checkbox" },
            { key = "showDaysPassed", default = true, renderer = "checkbox" },
            { key = "showMostGold", default = true, renderer = "checkbox" },
            { key = "showTotalGoldFound", default = false, renderer = "checkbox" },
            { key = "showBookCount", default = true, renderer = "checkbox" },
            { key = "showArtifactsFound", default = true, renderer = "checkbox" },
            { key = "showDiseasesCaught", default = true, renderer = "checkbox" },
            { key = "showBlightsCaught", default = true, renderer = "checkbox" },
            { key = "showDistOnFoot", default = true, renderer = "checkbox" },
            { key = "showDistLevitated", default = true, renderer = "checkbox" },
            { key = "showDistJumped", default = true, renderer = "checkbox" },
            { key = "showDistSwum", default = true, renderer = "checkbox" },
            { key = "showDistMounted", default = true, renderer = "checkbox" },
            { key = "showDistMountBreakdown", default = false, renderer = "checkbox" },
            { key = "showHighestPoint", default = true, renderer = "checkbox" },
            { key = "showDeepestDive", default = true, renderer = "checkbox" },
            { key = "showLongestFall", default = true, renderer = "checkbox" },
            { key = "showFastestSpeed", default = true, renderer = "checkbox" },
            { key = "showFurthestFromStart", default = false, renderer = "checkbox" },
            { key = "resetStats", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Stats" } },
        },
    },
    -- ── Primary Needs ──────────────────────────────────────────
    [needsKey] = {
        order = 3,
        settings = {
            { key = "showAllNeeds", default = true, renderer = "checkbox" },
            { key = "showSdMealCount", default = true, renderer = "checkbox" },
            { key = "showSdDrinkCount", default = true, renderer = "checkbox" },
            { key = "showSdBathCount", default = true, renderer = "checkbox" },
            { key = "showSdCookCount", default = true, renderer = "checkbox" },
            { key = "showSleepHours", default = true, renderer = "checkbox" },
            { key = "resetNeeds", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Needs" } },
        },
    },
    -- ── Interactions ───────────────────────────────────────────
    [interactKey] = {
        order = 4,
        settings = {
            { key = "showAllInteractions", default = true, renderer = "checkbox" },
            { key = "showTravelCount", default = true, renderer = "checkbox" },
            { key = "showTrainCount", default = true, renderer = "checkbox" },
            { key = "showUnlocksCount", default = true, renderer = "checkbox" },
            { key = "showDisarmsCount", default = true, renderer = "checkbox" },
            { key = "showLockpicksBroken", default = false, renderer = "checkbox" },
            { key = "showProbesBroken", default = false, renderer = "checkbox" },
            { key = "showBruteForceCount", default = true, renderer = "checkbox" },
            { key = "showPlantsForaged", default = true, renderer = "checkbox" },
            { key = "showIngredientsEaten", default = true, renderer = "checkbox" },
            { key = "showPeopleMet", default = true, renderer = "checkbox" },
            { key = "showSlavesFreed", default = true, renderer = "checkbox" },
            { key = "showRepairCount", default = true, renderer = "checkbox" },
            { key = "resetInteractions", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Interactions" } },
        },
    },
    -- ── Combat ─────────────────────────────────────────────────
    [combatKey] = {
        order = 5,
        settings = {
            { key = "showAllCombat", default = true, renderer = "checkbox" },
            { key = "showNpcKillCount", default = true, renderer = "checkbox" },
            { key = "showGodsKilled", default = true, renderer = "checkbox" },
            { key = "showRegicides", default = true, renderer = "checkbox" },
            { key = "showWitchesHunted", default = false, renderer = "checkbox" },
            { key = "showNecromancersSlain", default = false, renderer = "checkbox" },
            { key = "showWarlocksSlain", default = false, renderer = "checkbox" },
            { key = "showWorshippersSlain", default = false, renderer = "checkbox" },
            { key = "showCreatureKillCount", default = true, renderer = "checkbox" },
            { key = "showUndeadKillCount", default = false, renderer = "checkbox" },
            { key = "showDaedraKillCount", default = false, renderer = "checkbox" },
            { key = "showHumanoidKillCount", default = false, renderer = "checkbox" },
            { key = "showKillCount", default = false, renderer = "checkbox" },
            { key = "showDamageTaken", default = false, renderer = "checkbox" },
            { key = "showCombatDamageTaken", default = false, renderer = "checkbox" },
            { key = "showCombatAccuracy", default = false, renderer = "checkbox" },
            { key = "showMissCount", default = true, renderer = "checkbox" },
            { key = "showKnockdownCount", default = false, renderer = "checkbox" },
            { key = "showSneakAttackCount", default = true, renderer = "checkbox" },
            { key = "showHeadshotCount", default = true, renderer = "checkbox" },
            { key = "showKDRatio", default = false, renderer = "checkbox" },
            { key = "showWeaponsUsed", default = true, renderer = "checkbox" },
            { key = "resetCombat", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Combat" } },
        },
    },
    -- ── Magic ──────────────────────────────────────────────────
    [magicKey] = {
        order = 6,
        settings = {
            { key = "showAllMagic", default = true, renderer = "checkbox" },
            { key = "showInterventionCount", default = true, renderer = "checkbox" },
            { key = "showRecallCount", default = true, renderer = "checkbox" },
            { key = "showPotionCount", default = true, renderer = "checkbox" },
            { key = "showSpellsMade", default = true, renderer = "checkbox" },
            { key = "showItemsEnchanted", default = true, renderer = "checkbox" },
            { key = "showAlchemyCount", default = true, renderer = "checkbox" },
            { key = "showTrappedCount", default = true, renderer = "checkbox" },
            { key = "showBlackSoulsTrapped", default = true, renderer = "checkbox" },
            { key = "showSpellEffectsLearned", default = true, renderer = "checkbox" },
            { key = "showSpellsCast", default = true, renderer = "checkbox" },
            { key = "resetMagic", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Magic" } },
        },
    },
    -- ── Crime ──────────────────────────────────────────────────
    [crimeKey] = {
        order = 7,
        settings = {
            { key = "showAllCrime", default = true, renderer = "checkbox" },
            { key = "showHighestBounty", default = true, renderer = "checkbox" },
            { key = "showMurderCount", default = true, renderer = "checkbox" },
            { key = "showAssaultCount", default = true, renderer = "checkbox" },
            { key = "showJailCount", default = true, renderer = "checkbox" },
            { key = "showBountiesPaid", default = true, renderer = "checkbox" },
            { key = "showStolenItemCount", default = true, renderer = "checkbox" },
            { key = "showStolenItemValue", default = true, renderer = "checkbox" },
            { key = "resetCrime", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Crime" } },
        },
    },
    -- ── Misc ───────────────────────────────────────────────────
    [miscKey] = {
        order = 8,
        settings = {
            { key = "showAllMisc", default = true, renderer = "checkbox" },
            { key = "showScribCount", default = true, renderer = "checkbox" },
            { key = "showQuickloadCount", default = true, renderer = "checkbox" },
            { key = "quickloadAsSaveScum", default = true, renderer = "checkbox" },
            { key = "showWorldsDoomed", default = true, renderer = "checkbox" },
            { key = "showSkoomaCount", default = true, renderer = "checkbox" },
            { key = "resetMisc", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Misc" } },
        },
    },
    -- ── Insults ────────────────────────────────────────────────
    [insultKey] = {
        order = 9,
        settings = {
            { key = "showAllInsults", default = true, renderer = "checkbox" },
            { key = "showSwitCount", default = true, renderer = "checkbox" },
            { key = "showFetcherCount", default = true, renderer = "checkbox" },
            { key = "showNwahCount", default = true, renderer = "checkbox" },
            { key = "showScumCount", default = true, renderer = "checkbox" },
            { key = "resetInsults", default = false, renderer = mDef.renderers.resetButton, argument = { label = "Reset Insults" } },
        },
    },
}

local function getStorage(key)
    if storage.playerSection then
        return storage.playerSection(key)
    end
end

module.healthStorage  = getStorage(healthKey)
module.displayStorage = getStorage(displayKey)
module.summaryStorage = getStorage(summaryKey)
module.miscStorage    = getStorage(miscKey)

-- Category storages
local catStorages = {
    stats    = getStorage(statsKey),
    needs    = getStorage(needsKey),
    interact = getStorage(interactKey),
    combat   = getStorage(combatKey),
    magic    = getStorage(magicKey),
    crime    = getStorage(crimeKey),
    misc     = getStorage(miscKey),
    insults  = getStorage(insultKey),
}

-- Map each individual toggle to its category storage and group toggle
local categoryMap = {
    showQuestCount = { s = catStorages.stats, g = "showAllStats" },
    showDaysPassed = { s = catStorages.stats, g = "showAllStats" },
    showTrainCount = { s = catStorages.interact, g = "showAllInteractions" },
    showMostGold = { s = catStorages.stats, g = "showAllStats" },
    showTotalGoldFound = { s = catStorages.stats, g = "showAllStats" },
    showTravelCount = { s = catStorages.interact, g = "showAllInteractions" },
    showInterventionCount = { s = catStorages.magic, g = "showAllMagic" },
    showRecallCount = { s = catStorages.magic, g = "showAllMagic" },
    showPotionCount = { s = catStorages.magic, g = "showAllMagic" },
    showBookCount = { s = catStorages.stats, g = "showAllStats" },
    showArtifactsFound = { s = catStorages.stats, g = "showAllStats" },
    showDiseasesCaught = { s = catStorages.stats, g = "showAllStats" },
    showBlightsCaught = { s = catStorages.stats, g = "showAllStats" },
    showSlavesFreed = { s = catStorages.interact, g = "showAllInteractions" },
    showDistOnFoot = { s = catStorages.stats, g = "showAllStats" },
    showDistLevitated = { s = catStorages.stats, g = "showAllStats" },
    showDistJumped = { s = catStorages.stats, g = "showAllStats" },
    showDistSwum = { s = catStorages.stats, g = "showAllStats" },
    showDistMounted = { s = catStorages.stats, g = "showAllStats" },
    showDistMountBreakdown = { s = catStorages.stats, g = "showAllStats" },
    showHighestPoint = { s = catStorages.stats, g = "showAllStats" },
    showDeepestDive = { s = catStorages.stats, g = "showAllStats" },
    showLongestFall = { s = catStorages.stats, g = "showAllStats" },
    showFastestSpeed = { s = catStorages.stats, g = "showAllStats" },
    showFurthestFromStart = { s = catStorages.stats, g = "showAllStats" },
    showSdMealCount = { s = catStorages.needs, g = "showAllNeeds" },
    showSdDrinkCount = { s = catStorages.needs, g = "showAllNeeds" },
    showSdBathCount = { s = catStorages.needs, g = "showAllNeeds" },
    showSdCookCount = { s = catStorages.needs, g = "showAllNeeds" },
    showSleepHours = { s = catStorages.needs, g = "showAllNeeds" },
    showUnlocksCount = { s = catStorages.interact, g = "showAllInteractions" },
    showDisarmsCount = { s = catStorages.interact, g = "showAllInteractions" },
    showLockpicksBroken = { s = catStorages.interact, g = "showAllInteractions" },
    showProbesBroken = { s = catStorages.interact, g = "showAllInteractions" },
    showBruteForceCount = { s = catStorages.interact, g = "showAllInteractions" },
    showPlantsForaged = { s = catStorages.interact, g = "showAllInteractions" },
    showIngredientsEaten = { s = catStorages.interact, g = "showAllInteractions" },
    showPeopleMet = { s = catStorages.interact, g = "showAllInteractions" },
    showRepairCount = { s = catStorages.interact, g = "showAllInteractions" },
    showNpcKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showGodsKilled = { s = catStorages.combat, g = "showAllCombat" },
    showRegicides = { s = catStorages.combat, g = "showAllCombat" },
    showWitchesHunted = { s = catStorages.combat, g = "showAllCombat" },
    showNecromancersSlain = { s = catStorages.combat, g = "showAllCombat" },
    showWarlocksSlain = { s = catStorages.combat, g = "showAllCombat" },
    showWorshippersSlain = { s = catStorages.combat, g = "showAllCombat" },
    showCreatureKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showUndeadKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showDaedraKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showHumanoidKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showKillCount = { s = catStorages.combat, g = "showAllCombat" },
    showDamageTaken = { s = catStorages.combat, g = "showAllCombat" },
    showCombatDamageTaken = { s = catStorages.combat, g = "showAllCombat" },
    showCombatAccuracy = { s = catStorages.combat, g = "showAllCombat" },
    showMissCount = { s = catStorages.combat, g = "showAllCombat" },
    showKnockdownCount = { s = catStorages.combat, g = "showAllCombat" },
    showSneakAttackCount = { s = catStorages.combat, g = "showAllCombat" },
    showHeadshotCount = { s = catStorages.combat, g = "showAllCombat" },
    showKDRatio = { s = catStorages.combat, g = "showAllCombat" },
    showWeaponsUsed = { s = catStorages.combat, g = "showAllCombat" },
    showSpellsMade = { s = catStorages.magic, g = "showAllMagic" },
    showItemsEnchanted = { s = catStorages.magic, g = "showAllMagic" },
    showAlchemyCount = { s = catStorages.magic, g = "showAllMagic" },
    showTrappedCount = { s = catStorages.magic, g = "showAllMagic" },
    showBlackSoulsTrapped = { s = catStorages.magic, g = "showAllMagic" },
    showSpellEffectsLearned = { s = catStorages.magic, g = "showAllMagic" },
    showSpellsCast = { s = catStorages.magic, g = "showAllMagic" },
    showHighestBounty = { s = catStorages.crime, g = "showAllCrime" },
    showMurderCount = { s = catStorages.crime, g = "showAllCrime" },
    showAssaultCount = { s = catStorages.crime, g = "showAllCrime" },
    showJailCount = { s = catStorages.crime, g = "showAllCrime" },
    showBountiesPaid = { s = catStorages.crime, g = "showAllCrime" },
    showStolenItemCount = { s = catStorages.crime, g = "showAllCrime" },
    showStolenItemValue = { s = catStorages.crime, g = "showAllCrime" },
    showScribCount = { s = catStorages.misc, g = "showAllMisc" },
    showQuickloadCount = { s = catStorages.misc, g = "showAllMisc" },
    showWorldsDoomed = { s = catStorages.misc, g = "showAllMisc" },
    showSkoomaCount = { s = catStorages.misc, g = "showAllMisc" },
    showSwitCount = { s = catStorages.insults, g = "showAllInsults" },
    showFetcherCount = { s = catStorages.insults, g = "showAllInsults" },
    showNwahCount = { s = catStorages.insults, g = "showAllInsults" },
    showScumCount = { s = catStorages.insults, g = "showAllInsults" },
}

-- Check if a counter is visible (respects both individual and category toggle)
function module.isVisible(key)
    local cat = categoryMap[key]
    if not cat then return true end
    if not cat.s:get(cat.g) then return false end
    if not cat.s:get(key) then return false end
    return true
end

-- Check if a specific toggle is on (ignores category master toggle)
function module.isToggledOn(key)
    local cat = categoryMap[key]
    if not cat then return false end
    return cat.s:get(key) == true
end

local function getSetting(groupKey, settingKey)
    local group = settingGroups[groupKey]
    if group then
        for _, setting in ipairs(group.settings) do
            if setting.key == settingKey then return setting end
        end
    end
end

local function updateHealthSettings()
    local hasDeathCounter = module.healthStorage:get("deathCounter")
    local argument = getSetting(healthKey, "luckModifierPerDeath").argument
    argument.disabled = not hasDeathCounter
    I.Settings.updateRendererArgument(healthKey, "luckModifierPerDeath", argument)
end

module.initPlayerSettings = function()
    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description",
    }

    for _, group in pairs(settingGroups) do
        I.Settings.registerGroup(group)
    end

    module.healthStorage:subscribe(async:callback(function(_, key)
        if key == "deathCounter" then
            updateHealthSettings()
        end
    end))

    updateHealthSettings()
end

-- Build the group toggle -> children mapping for use by the player
-- script's onUpdate poll (we can't modify storage from a subscribe
-- handler on the same section — OpenMW forbids it).
module.groupCascades = {}
local groupKeyToStorage = {
    [statsKey]    = catStorages.stats,
    [needsKey]    = catStorages.needs,
    [interactKey] = catStorages.interact,
    [combatKey]   = catStorages.combat,
    [magicKey]    = catStorages.magic,
    [crimeKey]    = catStorages.crime,
    [miscKey]     = catStorages.misc,
    [insultKey]   = catStorages.insults,
}
for gKey, stor in pairs(groupKeyToStorage) do
    local group = settingGroups[gKey]
    if group and #group.settings >= 2 then
        local toggleKey = group.settings[1].key
        local children = {}
        for i = 2, #group.settings do
            children[#children + 1] = group.settings[i].key
        end
        module.groupCascades[#module.groupCascades + 1] = {
            storage = stor,
            toggleKey = toggleKey,
            children = children,
            lastValue = nil,  -- will be initialised on first poll
        }
    end
end

-- Reset-to-zero mapping: each reset toggle key → list of player storage
-- keys to zero out, plus the settings storage section containing the toggle.
module.resetToggles = {
    { toggle = "resetStats", storage = catStorages.stats, keys = {
        "questCount", "deathCount", "mostGold", "totalGoldFound",
        "bookCount", "booksSeenStr",
        "artifactsFound", "artifactsSeenStr",
        "diseaseCaught", "blightCaught", "diseasesSeenStr",
        "distOnFoot", "distLevitated", "distJumped",
        "distSwum", "distMounted",
        "distMount_horse", "distMount_guar", "distMount_donkey",
        "distMount_strident", "distMount_skylamp", "distMount_skyrender",
        "distMount_nix", "distMount_cliffracer", "distMount_boar",
        "highestPoint", "deepestDive", "longestFallSurvived", "fastestSpeed",
        "furthestFromStart",
    }},
    { toggle = "resetNeeds", storage = catStorages.needs, keys = {
        "sdMealCount", "sdDrinkCount", "sdBathCount", "sdCookCount", "sleepHours",
    }},
    { toggle = "resetInteractions", storage = catStorages.interact, keys = {
        "travelCount", "trainCount",
        "unlockCount", "disarmCount", "lockpicksBroken", "probesBroken",
        "repairCount",
        "bruteForceCount", "plantsForaged", "ingredientsEaten",
        "peopleMet", "peopleMetStr", "slavesFreed",
    }},
    { toggle = "resetCombat", storage = catStorages.combat, keys = {
        "npcKillCount", "witchesHunted", "necromancersSlain", "warlocksSlain",
        "worshippersSlain", "creatureKillCount", "undeadKillCount",
        "daedraKillCount", "humanoidKillCount", "killCount",
        "godsKilled", "regicides",
        "damageTaken", "combatDamageTaken", "swingCount", "hitCount",
        "knockdownCount", "sneakAttackCount", "headshotCount",
        "weaponTallyStr", "spellTallyStr",
        "creatureKillsStr", "creatureTypesStr",
    }},
    { toggle = "resetMagic", storage = catStorages.magic, keys = {
        "interventionCount", "recallCount", "potionCount",
        "spellsMade", "itemsEnchanted", "alchemyCount", "trapCount",
        "blackSoulsTrapped", "spellEffectsLearned", "spellEffectsSeenStr", "spellTallyStr",
    }},
    { toggle = "resetCrime", storage = catStorages.crime, keys = {
        "highestBounty", "murderCount", "assaultCount", "jailCount",
        "bountiesPaid", "stolenItemCount", "stolenItemValue",
    }},
    { toggle = "resetMisc", storage = catStorages.misc, keys = {
        "scribCount", "quickloadCount", "worldsDoomed", "skoomaCount",
    }},
    { toggle = "resetInsults", storage = catStorages.insults, keys = {
        "switCount", "fetcherCount", "nwahCount", "scumCount",
    }},
}

-- Finalise l10n keys for all groups
for key, group in pairs(settingGroups) do
    group.key = key
    group.page = mDef.MOD_NAME
    group.name = key .. "_name"
    group.description = key .. "_desc"
    group.l10n = mDef.MOD_NAME
    group.permanentStorage = false
    for _, setting in ipairs(group.settings) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
    end
end

return module
