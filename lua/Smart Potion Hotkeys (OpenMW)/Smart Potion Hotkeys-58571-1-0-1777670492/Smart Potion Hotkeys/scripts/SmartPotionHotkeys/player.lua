-- Smart Potion Hotkeys - Player Script
-- Binds hotkeys to potion EFFECTS rather than specific potion items.
-- When triggered, finds the best matching potion in inventory and uses it.

local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local MODNAME = "SmartPotionHotkeys"
local L10N = MODNAME
local NUM_SLOTS = 9

-- Cooldown to prevent double-firing (in simulation seconds)
local COOLDOWN = 0.5
local lastUseTime = 0

-- Auto-use check interval (seconds) — no need to scan every frame
local AUTO_USE_INTERVAL = 0.3
local nextAutoUseCheck = 0

-- Per-slot auto-use cooldowns to prevent rapid re-triggering
local autoUseCooldowns = {}
local AUTO_USE_COOLDOWN = 2.0

-- Forward declaration: registerTriggers captures this in a closure
-- before its definition further down the file.
local useSmartPotion

-- ============================================================================
-- EFFECT DEFINITIONS
-- ============================================================================

local EFFECT_LIST = {
    { key = "none",                  l10n = "effect_none" },
    { key = "RestoreHealth",         l10n = "effect_RestoreHealth" },
    { key = "RestoreMagicka",        l10n = "effect_RestoreMagicka" },
    { key = "RestoreFatigue",        l10n = "effect_RestoreFatigue" },
    { key = "RestoreAttribute",      l10n = "effect_RestoreAttribute" },
    { key = "RestoreSkill",          l10n = "effect_RestoreSkill" },
    { key = "CurePoison",            l10n = "effect_CurePoison" },
    { key = "CureCommonDisease",     l10n = "effect_CureCommonDisease" },
    { key = "CureBlightDisease",     l10n = "effect_CureBlightDisease" },
    { key = "CureParalyzation",      l10n = "effect_CureParalyzation" },
    { key = "CureCorprusDisease",    l10n = "effect_CureCorprusDisease" },
    { key = "ResistFire",            l10n = "effect_ResistFire" },
    { key = "ResistFrost",           l10n = "effect_ResistFrost" },
    { key = "ResistShock",           l10n = "effect_ResistShock" },
    { key = "ResistMagicka",         l10n = "effect_ResistMagicka" },
    { key = "ResistPoison",          l10n = "effect_ResistPoison" },
    { key = "FortifyHealth",         l10n = "effect_FortifyHealth" },
    { key = "FortifyMagicka",        l10n = "effect_FortifyMagicka" },
    { key = "FortifyFatigue",        l10n = "effect_FortifyFatigue" },
    { key = "FortifyAttribute",      l10n = "effect_FortifyAttribute" },
    { key = "FortifySkill",          l10n = "effect_FortifySkill" },
    { key = "Shield",                l10n = "effect_Shield" },
    { key = "FireShield",            l10n = "effect_FireShield" },
    { key = "FrostShield",           l10n = "effect_FrostShield" },
    { key = "LightningShield",       l10n = "effect_LightningShield" },
    { key = "NightEye",              l10n = "effect_NightEye" },
    { key = "Invisibility",          l10n = "effect_Invisibility" },
    { key = "Chameleon",             l10n = "effect_Chameleon" },
    { key = "Levitate",              l10n = "effect_Levitate" },
    { key = "SlowFall",              l10n = "effect_SlowFall" },
    { key = "WaterBreathing",        l10n = "effect_WaterBreathing" },
    { key = "WaterWalking",          l10n = "effect_WaterWalking" },
    { key = "SwiftSwim",             l10n = "effect_SwiftSwim" },
    { key = "Feather",               l10n = "effect_Feather" },
    { key = "Jump",                  l10n = "effect_Jump" },
    { key = "Dispel",                l10n = "effect_Dispel" },
    { key = "Reflect",               l10n = "effect_Reflect" },
    { key = "SpellAbsorption",       l10n = "effect_SpellAbsorption" },
    { key = "Sanctuary",             l10n = "effect_Sanctuary" },
    { key = "Light",                 l10n = "effect_Light" },
    { key = "Telekinesis",           l10n = "effect_Telekinesis" },
    { key = "Mark",                  l10n = "effect_Mark" },
    { key = "Recall",                l10n = "effect_Recall" },
    { key = "AlmsiviIntervention",   l10n = "effect_AlmsiviIntervention" },
    { key = "DivineIntervention",    l10n = "effect_DivineIntervention" },
    { key = "DetectAnimal",          l10n = "effect_DetectAnimal" },
    { key = "DetectEnchantment",     l10n = "effect_DetectEnchantment" },
    { key = "DetectKey",             l10n = "effect_DetectKey" },
}

local EFFECT_BY_L10N = {}
for _, entry in ipairs(EFFECT_LIST) do
    EFFECT_BY_L10N[entry.l10n] = entry.key
end

local L10N_BY_EFFECT = {}
for _, entry in ipairs(EFFECT_LIST) do
    L10N_BY_EFFECT[entry.key] = entry.l10n
end

local SELECT_ITEMS = {}
for _, entry in ipairs(EFFECT_LIST) do
    table.insert(SELECT_ITEMS, entry.l10n)
end

-- Auto-use stat mapping: effect key -> which dynamic stat to monitor
-- Only effects that map cleanly to a dynamic stat are supported
local AUTO_USE_STAT_MAP = {
    RestoreHealth  = "health",
    RestoreMagicka = "magicka",
    RestoreFatigue = "fatigue",
}

-- ============================================================================
-- INPUT TRIGGER REGISTRATION
-- ============================================================================

local triggersRegistered = false

local function registerTriggers()
    if triggersRegistered then return end
    triggersRegistered = true

    for i = 1, NUM_SLOTS do
        local triggerKey = MODNAME .. "_Use" .. i

        input.registerTrigger {
            key = triggerKey,
            l10n = L10N,
            name = "trigger_slot" .. i .. "_name",
            description = "trigger_slot" .. i .. "_description",
        }

        local slotNum = i
        input.registerTriggerHandler(triggerKey, async:callback(function()
            useSmartPotion(slotNum)
        end))
    end
end

-- ============================================================================
-- SETTINGS REGISTRATION
-- ============================================================================

local settingsRegistered = false

local function registerSettings()
    if settingsRegistered then return end
    settingsRegistered = true

    I.Settings.registerPage {
        key = MODNAME,
        l10n = L10N,
        name = "PageName",
        description = "PageDescription",
    }

    -- General settings group
    I.Settings.registerGroup {
        key = "Settings_" .. MODNAME .. "_General",
        page = MODNAME,
        l10n = L10N,
        name = "GeneralGroupName",
        permanentStorage = true,
        order = 0,
        settings = {
            {
                key = "SORT_ORDER",
                renderer = "select",
                name = "SORT_ORDER_name",
                description = "SORT_ORDER_description",
                default = "sort_weakest",
                argument = {
                    l10n = L10N,
                    items = { "sort_weakest", "sort_strongest", "sort_lowest_effective" },
                },
            },
            {
                key = "MATCH_MODE",
                renderer = "select",
                name = "MATCH_MODE_name",
                description = "MATCH_MODE_description",
                default = "match_primary",
                argument = {
                    l10n = L10N,
                    items = { "match_primary", "match_any" },
                },
            },
            {
                key = "SHOW_MESSAGE",
                renderer = "checkbox",
                name = "SHOW_MESSAGE_name",
                default = true,
            },
        },
    }

    -- Per-slot settings groups
    for i = 1, NUM_SLOTS do
        local triggerKey = MODNAME .. "_Use" .. i

        local defaultEffect = "effect_none"
        if i == 1 then defaultEffect = "effect_RestoreHealth"
        elseif i == 2 then defaultEffect = "effect_RestoreMagicka"
        elseif i == 3 then defaultEffect = "effect_RestoreFatigue"
        elseif i == 4 then defaultEffect = "effect_CurePoison"
        end

        -- NOTE: omitting 'description' entirely (not setting it to false)
        -- suppresses the description line. Setting it to false breaks l10n.
        I.Settings.registerGroup {
            key = "Settings_" .. MODNAME .. "_Slot" .. i,
            page = MODNAME,
            l10n = L10N,
            name = "SlotGroupName_" .. i,
            permanentStorage = true,
            order = i,
            settings = {
                {
                    key = "SLOT_" .. i .. "_EFFECT",
                    renderer = "select",
                    name = "SLOT_" .. i .. "_effect_name",
                    default = defaultEffect,
                    argument = {
                        l10n = L10N,
                        items = SELECT_ITEMS,
                    },
                },
                {
                    key = "SLOT_" .. i .. "_KEY",
                    renderer = "inputBinding",
                    name = "SLOT_" .. i .. "_key_name",
                    default = triggerKey .. "_default",
                    argument = {
                        key = triggerKey,
                        type = "trigger",
                    },
                },
                {
                    key = "SLOT_" .. i .. "_SORT",
                    renderer = "select",
                    name = "SLOT_" .. i .. "_sort_name",
                    description = "SLOT_sort_override_description",
                    default = "sort_use_global",
                    argument = {
                        l10n = L10N,
                        items = { "sort_use_global", "sort_weakest", "sort_strongest", "sort_lowest_effective" },
                    },
                },
                {
                    key = "SLOT_" .. i .. "_AUTO_USE",
                    renderer = "checkbox",
                    name = "SLOT_" .. i .. "_auto_use_name",
                    description = "SLOT_auto_use_description",
                    default = false,
                },
                {
                    key = "SLOT_" .. i .. "_THRESHOLD",
                    renderer = "number",
                    name = "SLOT_" .. i .. "_threshold_name",
                    description = "SLOT_threshold_description",
                    default = 50,
                    argument = {
                        integer = true,
                        min = 5,
                        max = 95,
                    },
                },
            },
        }
    end
end

-- ============================================================================
-- SETTINGS ACCESS
-- ============================================================================

local generalSection = nil
local slotSections = {}

local function getGeneralSection()
    if not generalSection then
        generalSection = storage.playerSection("Settings_" .. MODNAME .. "_General")
    end
    return generalSection
end

local function getSlotSection(slotNum)
    if not slotSections[slotNum] then
        slotSections[slotNum] = storage.playerSection("Settings_" .. MODNAME .. "_Slot" .. slotNum)
    end
    return slotSections[slotNum]
end

local function getGlobalSortOrder()
    local val = getGeneralSection():get("SORT_ORDER") or "sort_weakest"
    if val == "sort_strongest" then return "strongest" end
    if val == "sort_lowest_effective" then return "lowest_effective" end
    return "weakest"
end

local function getSlotSortOrder(slotNum)
    local val = getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_SORT") or "sort_use_global"
    if val == "sort_weakest" then return "weakest" end
    if val == "sort_strongest" then return "strongest" end
    if val == "sort_lowest_effective" then return "lowest_effective" end
    -- "sort_use_global" or anything else: fall back to global
    return getGlobalSortOrder()
end

local function getMatchMode()
    local val = getGeneralSection():get("MATCH_MODE") or "match_primary"
    if val == "match_any" then return "any" end
    return "primary"
end

local function getShowMessage()
    local val = getGeneralSection():get("SHOW_MESSAGE")
    if val == nil then return true end
    return val
end

local function getSlotEffect(slotNum)
    local val = getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_EFFECT") or "effect_none"
    return EFFECT_BY_L10N[val] or "none"
end

local function getSlotAutoUse(slotNum)
    local val = getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_AUTO_USE")
    if val == nil then return false end
    return val
end

local function getSlotThreshold(slotNum)
    local val = getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_THRESHOLD")
    if val == nil then return 50 end
    return val
end

-- ============================================================================
-- POTION FINDING & SORTING
-- ============================================================================

-- Computes three values for a potion against a desired effect:
--   found:         whether the potion carries the effect at all
--   strength:      scalar used for weakest/strongest sorting. For magnitude
--                  effects this reflects total power; for flag effects
--                  (Cure Poison etc.) it's always 0 and the potion's gold
--                  value is used as the tiebreaker instead.
--   actualRestore: the amount the potion will restore to a dynamic stat
--                  (Health/Magicka/Fatigue). 0 for effects that don't map
--                  to a dynamic stat. Used by "lowest effective" sort.
local function getPotionStrength(potionRecord, desiredEffect, matchMode)
    local targetEffectId = core.magic.EFFECT_TYPE[desiredEffect]
    if not targetEffectId then
        return false, 0, 0
    end

    local strength = 0
    local actualRestore = 0
    local found = false
    local isDynamicRestore = (AUTO_USE_STAT_MAP[desiredEffect] ~= nil)

    for _, eff in ipairs(potionRecord.effects) do
        if eff.effect.id == targetEffectId then
            found = true
            local mag = ((eff.magnitudeMin or 0) + (eff.magnitudeMax or 0)) / 2
            local dur = eff.duration or 0

            if mag > 0 and dur > 0 then
                strength = strength + mag * dur
            elseif mag > 0 then
                strength = strength + mag
            elseif dur > 0 then
                strength = strength + dur
            end
            -- Note: we intentionally no longer add 1 for flag effects.
            -- Flag effects (Cure Poison, Dispel, etc.) have mag=0 and dur=0,
            -- so all variants would tie at 1. The caller uses record.value
            -- as a secondary sort key to break the tie meaningfully.

            -- For Restore Health/Magicka/Fatigue, compute the true amount
            -- restored. MW effects are "applied once" when magnitude is the
            -- instant total, or continuous when it restores mag per second
            -- over dur seconds.
            if isDynamicRestore and eff.effect then
                if eff.effect.isAppliedOnce then
                    actualRestore = actualRestore + mag
                elseif mag > 0 and dur > 0 then
                    actualRestore = actualRestore + mag * dur
                else
                    actualRestore = actualRestore + mag
                end
            end
        end
        if matchMode == "primary" then
            break
        end
    end
    return found, strength, actualRestore
end

-- Returns missing amount for the dynamic stat tied to this effect, or nil
-- if the effect has no dynamic stat mapping.
local function getMissingForEffect(desiredEffect)
    local statName = AUTO_USE_STAT_MAP[desiredEffect]
    if not statName then return nil end
    local stat = types.Actor.stats.dynamic[statName](self.object)
    if not stat then return nil end
    local max = stat.base + stat.modifier
    if max <= 0 then return nil end
    local missing = max - stat.current
    if missing < 0 then missing = 0 end
    return missing
end

local function findMatchingPotions(desiredEffect, slotNum)
    local player = self.object
    local inv = types.Actor.inventory(player)
    local allPotions = inv:getAll(types.Potion)
    local matchMode = getMatchMode()
    local matches = {}

    for _, potion in ipairs(allPotions) do
        local record = types.Potion.record(potion)
        if record and record.effects then
            local found, strength, actualRestore = getPotionStrength(record, desiredEffect, matchMode)
            if found then
                table.insert(matches, {
                    item = potion,
                    strength = strength,
                    actualRestore = actualRestore,
                    value = record.value or 0,
                    name = record.name or record.id,
                })
            end
        end
    end

    local order = getSlotSortOrder(slotNum)

    if order == "lowest_effective" then
        local missing = getMissingForEffect(desiredEffect)
        if missing == nil or missing <= 0 then
            -- Effect has no dynamic stat, or stat is already full.
            -- Fall through to weakest-first so we still pick something sensible.
            order = "weakest"
        else
            -- Split into "covers the gap" and "doesn't". Prefer the smallest
            -- that covers; if nothing covers, use the largest available.
            local covers, undershoots = {}, {}
            for _, m in ipairs(matches) do
                if m.actualRestore >= missing then
                    table.insert(covers, m)
                else
                    table.insert(undershoots, m)
                end
            end
            if #covers > 0 then
                table.sort(covers, function(a, b)
                    if a.actualRestore ~= b.actualRestore then
                        return a.actualRestore < b.actualRestore
                    end
                    return a.value < b.value
                end)
                return covers
            else
                table.sort(undershoots, function(a, b)
                    if a.actualRestore ~= b.actualRestore then
                        return a.actualRestore > b.actualRestore
                    end
                    return a.value > b.value
                end)
                return undershoots
            end
        end
    end

    local ascending = (order == "weakest")
    table.sort(matches, function(a, b)
        if a.strength ~= b.strength then
            if ascending then return a.strength < b.strength end
            return a.strength > b.strength
        end
        -- Tiebreaker: gold value (important for flag effects that all score 0)
        if ascending then return a.value < b.value end
        return a.value > b.value
    end)

    return matches
end

-- ============================================================================
-- POTION USAGE
-- ============================================================================

useSmartPotion = function(slotNum)
    local now = core.getSimulationTime()
    if now - lastUseTime < COOLDOWN then return end

    local desiredEffect = getSlotEffect(slotNum)
    if desiredEffect == "none" then
        if getShowMessage() then
            local l10n = core.l10n(L10N)
            ui.showMessage(l10n("msg_slot_empty"))
        end
        return
    end

    local matches = findMatchingPotions(desiredEffect, slotNum)
    if #matches == 0 then
        if getShowMessage() then
            local l10n = core.l10n(L10N)
            local displayKey = L10N_BY_EFFECT[desiredEffect] or desiredEffect
            local effectName = l10n(displayKey)
            ui.showMessage(l10n("msg_no_potion", { effect = effectName }))
        end
        return
    end

    local best = matches[1]
    lastUseTime = now

    core.sendGlobalEvent('UseItem', {
        object = best.item,
        actor = self.object,
        force = true,
    })

    if getShowMessage() then
        local l10n = core.l10n(L10N)
        local remaining = (best.item.count or 1) - 1
        ui.showMessage(l10n("msg_used_count", {
            potion = best.name,
            remaining = remaining,
        }))
    end
end

-- ============================================================================
-- AUTO-USE LOGIC
-- ============================================================================

local function getStatPercent(statName)
    local player = self.object
    local stat = types.Actor.stats.dynamic[statName](player)
    if not stat then return 100 end
    local max = stat.base + stat.modifier
    if max <= 0 then return 100 end
    return (stat.current / max) * 100
end

local function checkAutoUse()
    -- Skip auto-use when any menu/dialogue/cutscene is open, or when the
    -- world is paused. Prevents surprise potion consumption during barter,
    -- book reading, dialogue, etc. The player can still press hotkeys
    -- manually — that path bypasses this check.
    if I.UI.getMode() ~= nil then return end
    if core.isWorldPaused() then return end

    local now = core.getSimulationTime()

    for i = 1, NUM_SLOTS do
        if getSlotAutoUse(i) then
            local desiredEffect = getSlotEffect(i)
            if desiredEffect ~= "none" then
                local statName = AUTO_USE_STAT_MAP[desiredEffect]
                if statName then
                    -- Check per-slot cooldown
                    if not autoUseCooldowns[i] or (now - autoUseCooldowns[i] >= AUTO_USE_COOLDOWN) then
                        local threshold = getSlotThreshold(i)
                        local current = getStatPercent(statName)
                        if current < threshold then
                            -- Check global cooldown too
                            if now - lastUseTime >= COOLDOWN then
                                local matches = findMatchingPotions(desiredEffect, i)
                                if #matches > 0 then
                                    local best = matches[1]
                                    lastUseTime = now
                                    autoUseCooldowns[i] = now

                                    core.sendGlobalEvent('UseItem', {
                                        object = best.item,
                                        actor = self.object,
                                        force = true,
                                    })

                                    if getShowMessage() then
                                        local l10n = core.l10n(L10N)
                                        local remaining = (best.item.count or 1) - 1
                                        ui.showMessage(l10n("msg_auto_used", {
                                            potion = best.name,
                                            remaining = remaining,
                                        }))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ENGINE HANDLERS
-- ============================================================================

local function onInit()
    registerTriggers()
    registerSettings()
end

local function onLoad()
    registerTriggers()
    registerSettings()
end

local function onUpdate(dt)
    local now = core.getSimulationTime()
    if now < nextAutoUseCheck then return end
    nextAutoUseCheck = now + AUTO_USE_INTERVAL
    checkAutoUse()
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
}
