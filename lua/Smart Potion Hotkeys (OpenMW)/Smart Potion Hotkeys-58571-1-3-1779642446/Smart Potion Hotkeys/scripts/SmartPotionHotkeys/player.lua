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
local belt = require('scripts.SmartPotionHotkeys.ui.belt')

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

-- If the player's potion key overlaps a vanilla quick-key, OpenMW can still run
-- its own quick-key/castable selection path independently of this script. Guard
-- the player's pre-hotkey combat state only for the same key press, then release
-- immediately so weapon/spell readiness remains responsive.
local HOTKEY_GUARD_DURATION = 0.05
local pendingHotkeyGuard = nil
local lastObservedState = nil
local digitKeySlotMap = nil

-- Inventory Extender button hook check interval. The window can be recreated,
-- so the hook is attempted periodically and de-duplicated by the UI module.
local INVENTORY_BUTTON_HOOK_INTERVAL = 0.8
local nextInventoryButtonHook = 0

-- Forward declaration: input handlers capture this in closures
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

local EFFECT_INDEX_BY_KEY = {}
for index, entry in ipairs(EFFECT_LIST) do
    EFFECT_INDEX_BY_KEY[entry.key] = index
end

local SORT_ITEMS = {
    "sort_use_global",
    "sort_weakest",
    "sort_strongest",
    "sort_lowest_effective",
}

local SORT_INDEX_BY_KEY = {}
for index, key in ipairs(SORT_ITEMS) do
    SORT_INDEX_BY_KEY[key] = index
end

-- Auto-use stat mapping: effect key -> which dynamic stat to monitor
-- Only effects that map cleanly to a dynamic stat are supported
local AUTO_USE_STAT_MAP = {
    RestoreHealth  = "health",
    RestoreMagicka = "magicka",
    RestoreFatigue = "fatigue",
}

-- ============================================================================
-- INPUT ACTION REGISTRATION
-- ============================================================================

local inputRegistered = false
local slotActionKeys = {}

local function anySlotActionPressed(...)
    for i = 1, select('#', ...) do
        if select(i, ...) then return true end
    end
    return false
end

local function registerSmartPotionSuppressors()
    local dependencies = {}
    for i = 1, NUM_SLOTS do
        dependencies[i] = slotActionKeys[i]
    end

    -- If the user binds an SPH slot to a key that is also mapped to an engine
    -- action, try to make SPH win for that frame. Some OpenMW builds expose only
    -- a subset of built-in actions as bindable string keys, so every binding here
    -- is guarded and non-fatal.
    if not input.actions then return end

    local actionKeys = { 'ToggleSpell' }
    for i = 1, 10 do
        table.insert(actionKeys, 'QuickKey' .. i)
    end

    for _, actionKey in ipairs(actionKeys) do
        if input.actions[actionKey] then
            local ok, err = pcall(function()
                input.bindAction(actionKey, async:callback(function(dt, vanillaValue, ...)
                    if not vanillaValue then return false end
                    if anySlotActionPressed(...) then return false end
                    return vanillaValue
                end), dependencies)
            end)
            if not ok then
                print('[' .. MODNAME .. '] Built-in action suppression unavailable for ' .. actionKey .. ': ' .. tostring(err))
            end
        end
    end
end

local function registerInput()
    if inputRegistered then return end
    inputRegistered = true

    for i = 1, NUM_SLOTS do
        local actionKey = MODNAME .. "_Use" .. i
        slotActionKeys[i] = actionKey

        input.registerAction {
            key = actionKey,
            type = input.ACTION_TYPE.Boolean,
            l10n = L10N,
            name = "trigger_slot" .. i .. "_name",
            description = "trigger_slot" .. i .. "_description",
            defaultValue = false,
        }

        local slotNum = i
        input.registerActionHandler(actionKey, async:callback(function(value)
            if value then
                useSmartPotion(slotNum)
            end
        end))

        -- Compatibility for saves/settings created by earlier SPH versions where
        -- slot hotkeys were triggers. Old input bindings may still refer to
        -- trigger SmartPotionHotkeys_UseN; registering this shim keeps those
        -- bindings usable instead of requiring every slot to be rebound.
        local ok, err = pcall(function()
            input.registerTrigger {
                key = actionKey,
                l10n = L10N,
                name = "trigger_slot" .. i .. "_name",
                description = "trigger_slot" .. i .. "_description",
            }
            input.registerTriggerHandler(actionKey, async:callback(function()
                useSmartPotion(slotNum)
            end))
        end)
        if not ok then
            print('[' .. MODNAME .. '] Legacy trigger compatibility unavailable for ' .. actionKey .. ': ' .. tostring(err))
        end
    end

    registerSmartPotionSuppressors()
    belt.registerTrigger()
end

-- ============================================================================
-- HOTKEY STATE GUARD
-- ============================================================================

local function safeCall(fn, ...)
    if not fn then return false, nil end
    return pcall(fn, ...)
end

local function safeField(value, fieldName)
    if value == nil then return nil end
    local ok, result = pcall(function() return value[fieldName] end)
    if ok then return result end
    return nil
end

local function objectIsStillValid(object)
    if object == nil then return false end
    local ok, result = pcall(function()
        if object.isValid then return object:isValid() end
        return true
    end)
    return ok and result ~= false
end

local function identityOf(value)
    if value == nil then return nil end
    if type(value) == 'string' then return value end

    local id = safeField(value, 'id')
    if id ~= nil then return tostring(id) end

    local recordId = safeField(value, 'recordId')
    if recordId ~= nil then return tostring(recordId) end

    return tostring(value)
end

local function captureCurrentActorState()
    local state = {}
    local Actor = types.Actor
    local Player = types.Player

    if Actor and Actor.getStance then
        local ok, stance = pcall(Actor.getStance, self.object)
        if ok then state.stance = stance end
    end

    if Actor and Actor.getSelectedSpell then
        local ok, spell = pcall(Actor.getSelectedSpell, self.object)
        if ok then
            state.selectedSpell = spell
            state.selectedSpellId = identityOf(spell)
        end
    end

    if Actor and Actor.getSelectedEnchantedItem then
        local ok, item = pcall(Actor.getSelectedEnchantedItem, self.object)
        if ok then
            state.selectedEnchantedItem = item
            state.selectedEnchantedItemId = identityOf(item)
        end
    end


    return state
end

local function snapshotCurrentState()
    lastObservedState = captureCurrentActorState()
end

local function restoreSelectedCastable(state)
    local Actor = types.Actor
    if not Actor then return end

    local changed = false

    if Actor.getSelectedSpell then
        local ok, currentSpell = pcall(Actor.getSelectedSpell, self.object)
        if ok and identityOf(currentSpell) ~= state.selectedSpellId then
            changed = true
        end
    end

    if Actor.getSelectedEnchantedItem then
        local ok, currentItem = pcall(Actor.getSelectedEnchantedItem, self.object)
        if ok and identityOf(currentItem) ~= state.selectedEnchantedItemId then
            changed = true
        end
    end

    if not changed then return end

    if Actor.clearSelectedCastable then
        pcall(Actor.clearSelectedCastable, self)
    end

    -- Prefer restoring an enchanted item if that was the selected castable. If no
    -- enchanted item was selected, restore the previous spell. Selecting a castable
    -- should not require entering spell stance; the stance is restored separately.
    if state.selectedEnchantedItem ~= nil and objectIsStillValid(state.selectedEnchantedItem) and Actor.setSelectedEnchantedItem then
        pcall(Actor.setSelectedEnchantedItem, self, state.selectedEnchantedItem)
    elseif state.selectedSpell ~= nil and Actor.setSelectedSpell then
        pcall(Actor.setSelectedSpell, self, state.selectedSpell)
    end
end

local function restoreGuardedStance(state)
    local Actor = types.Actor
    if not (Actor and Actor.getStance and Actor.setStance) then return end
    if state.stance == nil then return end

    -- If the player deliberately started in magic stance, leave it alone.
    if Actor.STANCE and state.stance == Actor.STANCE.Spell then return end

    local okCurrent, currentStance = pcall(Actor.getStance, self.object)
    if not okCurrent then return end

    if currentStance ~= state.stance then
        local okSet, err = pcall(Actor.setStance, self, state.stance)
        if not okSet then
            print('[' .. MODNAME .. '] Stance guard unavailable: ' .. tostring(err))
        end
    end
end

local function queueHotkeyGuard()
    local state = lastObservedState or captureCurrentActorState()
    if not state then return end

    pendingHotkeyGuard = {
        state = state,
        untilTime = core.getSimulationTime() + HOTKEY_GUARD_DURATION,
    }

    -- Restore once immediately and then again for a few frames. The immediate
    -- restore is harmless if vanilla processing has not run yet; the short
    -- follow-up window catches the overlapping quick-key path without preventing
    -- the player from readying a weapon or spell afterwards.
    restoreSelectedCastable(state)
    restoreGuardedStance(state)
end

local function restoreHotkeyGuard(now)
    local pending = pendingHotkeyGuard
    if not pending then return end

    if now > pending.untilTime then
        pendingHotkeyGuard = nil
        return
    end

    restoreSelectedCastable(pending.state)
    restoreGuardedStance(pending.state)
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
            {
                key = "BELT_HOTKEY",
                renderer = "inputBinding",
                name = "BELT_HOTKEY_name",
                description = "BELT_HOTKEY_description",
                default = "",
                argument = {
                    key = "SmartPotionHotkeys_ToggleBelt",
                    type = "trigger",
                },
            },
        },
    }

    -- Per-slot settings groups
    for i = 1, NUM_SLOTS do
        local actionKey = MODNAME .. "_Use" .. i

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
                    default = actionKey .. "_default",
                    argument = {
                        key = actionKey,
                        type = "action",
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

local function getSlotSortSetting(slotNum)
    return getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_SORT") or "sort_use_global"
end

local function getSlotSortOrder(slotNum)
    local val = getSlotSortSetting(slotNum)
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

local function getSlotEffectSetting(slotNum)
    return getSlotSection(slotNum):get("SLOT_" .. slotNum .. "_EFFECT") or "effect_none"
end

local function getSlotEffect(slotNum)
    local val = getSlotEffectSetting(slotNum)
    return EFFECT_BY_L10N[val] or "none"
end

local function buildDigitKeySlotMap()
    if digitKeySlotMap then return digitKeySlotMap end

    digitKeySlotMap = {}

    local function add(code, slot)
        if code ~= nil then digitKeySlotMap[code] = slot end
    end

    if input.KEY then
        add(input.KEY._1, 1)
        add(input.KEY._2, 2)
        add(input.KEY._3, 3)
        add(input.KEY._4, 4)
        add(input.KEY._5, 5)
        add(input.KEY._6, 6)
        add(input.KEY._7, 7)
        add(input.KEY._8, 8)
        add(input.KEY._9, 9)

        -- Some users bind the numpad instead of the number row. Treat it the same
        -- for proactive guarding, but only when the matching SPH slot is configured.
        add(input.KEY.NP_1, 1)
        add(input.KEY.NP_2, 2)
        add(input.KEY.NP_3, 3)
        add(input.KEY.NP_4, 4)
        add(input.KEY.NP_5, 5)
        add(input.KEY.NP_6, 6)
        add(input.KEY.NP_7, 7)
        add(input.KEY.NP_8, 8)
        add(input.KEY.NP_9, 9)
    end

    return digitKeySlotMap
end

local function slotFromDigitKey(key)
    if not key then return nil end
    if key.withAlt or key.withCtrl or key.withShift or key.withSuper then return nil end

    if key.symbol ~= nil and #key.symbol == 1 then
        local slot = tonumber(key.symbol)
        if slot and slot >= 1 and slot <= NUM_SLOTS then return slot end
    end

    return buildDigitKeySlotMap()[key.code]
end

local function onKeyPress(key)
    -- Proactively guard the number-row/numpad key before the rest of OpenMW's
    -- quick-key/castable processing can ready magic. This only runs for configured
    -- SPH slots and ignores menus/text input/modifier combinations.
    if I.UI.getMode() ~= nil then return end
    local slotNum = slotFromDigitKey(key)
    if not slotNum then return end
    if getSlotEffect(slotNum) == "none" then return end

    queueHotkeyGuard()
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

local function clampNumber(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function isAutoUseSupported(effectKey)
    return AUTO_USE_STAT_MAP[effectKey] ~= nil
end

local function setSlotEffect(slotNum, effectSetting)
    if not EFFECT_BY_L10N[effectSetting] then return false end
    getSlotSection(slotNum):set("SLOT_" .. slotNum .. "_EFFECT", effectSetting)

    -- Keep the belt menu from leaving impossible auto-use states behind.
    local effectKey = EFFECT_BY_L10N[effectSetting] or "none"
    if not isAutoUseSupported(effectKey) then
        getSlotSection(slotNum):set("SLOT_" .. slotNum .. "_AUTO_USE", false)
    end
    return true
end

local function cycleSlotEffect(slotNum, delta)
    local currentKey = getSlotEffect(slotNum)
    local index = EFFECT_INDEX_BY_KEY[currentKey] or 1
    local count = #EFFECT_LIST
    index = ((index - 1 + (delta or 1)) % count) + 1
    return setSlotEffect(slotNum, EFFECT_LIST[index].l10n)
end

local function cycleSlotSort(slotNum, delta)
    local current = getSlotSortSetting(slotNum)
    local index = SORT_INDEX_BY_KEY[current] or 1
    local count = #SORT_ITEMS
    index = ((index - 1 + (delta or 1)) % count) + 1
    getSlotSection(slotNum):set("SLOT_" .. slotNum .. "_SORT", SORT_ITEMS[index])
    return true
end

local function toggleSlotAutoUse(slotNum)
    local effectKey = getSlotEffect(slotNum)
    local l10n = core.l10n(L10N)
    if effectKey == "none" then
        ui.showMessage(l10n("msg_belt_auto_no_effect"))
        return false
    end
    if not isAutoUseSupported(effectKey) then
        ui.showMessage(l10n("msg_belt_auto_unsupported"))
        return false
    end
    getSlotSection(slotNum):set("SLOT_" .. slotNum .. "_AUTO_USE", not getSlotAutoUse(slotNum))
    return true
end

local function adjustSlotThreshold(slotNum, delta)
    local effectKey = getSlotEffect(slotNum)
    if not isAutoUseSupported(effectKey) then return false end
    local current = tonumber(getSlotThreshold(slotNum)) or 50
    local nextValue = clampNumber(current + (delta or 0), 5, 95)
    getSlotSection(slotNum):set("SLOT_" .. slotNum .. "_THRESHOLD", nextValue)
    return true
end

local beltActions = {
    cycleEffect = cycleSlotEffect,
    setEffect = setSlotEffect,
    cyclePriority = cycleSlotSort,
    toggleAutoUse = toggleSlotAutoUse,
    adjustThreshold = adjustSlotThreshold,
}

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
                    count = potion.count or 1,
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
-- POTION BELT SNAPSHOT
-- ============================================================================

local function getLocalizedEffectName(effectKey)
    if effectKey == "none" then
        return core.l10n(L10N)("effect_none")
    end
    local l10nKey = L10N_BY_EFFECT[effectKey]
    if not l10nKey then return tostring(effectKey or "") end
    return core.l10n(L10N)(l10nKey)
end

local function getSortLabel(order)
    local l10n = core.l10n(L10N)
    if order == "strongest" then return l10n("sort_strongest") end
    if order == "lowest_effective" then return l10n("sort_lowest_effective") end
    return l10n("sort_weakest")
end

local function getSortSettingLabel(slotNum)
    local l10n = core.l10n(L10N)
    local setting = getSlotSortSetting(slotNum)
    if setting == "sort_use_global" then
        return l10n("belt_priority_default", { priority = getSortLabel(getGlobalSortOrder()) })
    end
    return l10n(setting)
end

local function getMatchModeLabel()
    local l10n = core.l10n(L10N)
    if getMatchMode() == "any" then return l10n("match_any") end
    return l10n("match_primary")
end

local function getPotionInventoryTotals()
    local inv = types.Actor.inventory(self.object)
    local allPotions = inv:getAll(types.Potion)
    local stacks, count = 0, 0
    for _, potion in ipairs(allPotions) do
        stacks = stacks + 1
        count = count + (potion.count or 1)
    end
    return stacks, count
end

local function buildPotionBeltSnapshot()
    local l10n = core.l10n(L10N)
    local potionStacks, potionCount = getPotionInventoryTotals()
    local slots = {}
    local configuredSlots = 0

    for i = 1, NUM_SLOTS do
        local desiredEffect = getSlotEffect(i)
        local effectName = getLocalizedEffectName(desiredEffect)
        local matches = {}
        local totalMatches = 0
        local bestName = l10n("belt_no_potion")
        local bestPower = l10n("belt_dash")

        if desiredEffect ~= "none" then
            configuredSlots = configuredSlots + 1
            matches = findMatchingPotions(desiredEffect, i)
            for _, match in ipairs(matches) do
                totalMatches = totalMatches + (match.count or (match.item and match.item.count) or 1)
            end
            if #matches > 0 then
                local best = matches[1]
                bestName = best.name or l10n("belt_unknown")
                if best.actualRestore and best.actualRestore > 0 then
                    bestPower = string.format("%.0f", best.actualRestore)
                elseif best.strength and best.strength > 0 then
                    bestPower = string.format("%.0f", best.strength)
                else
                    bestPower = l10n("belt_dash")
                end
            end
        end

        local autoUse = l10n("belt_auto_off")
        if getSlotAutoUse(i) then
            if AUTO_USE_STAT_MAP[desiredEffect] then
                autoUse = l10n("belt_auto_threshold", { threshold = tostring(getSlotThreshold(i)) })
            else
                autoUse = l10n("belt_auto_unsupported")
            end
        end

        table.insert(slots, {
            slot = i,
            effect = effectName,
            effectKey = desiredEffect,
            effectSetting = getSlotEffectSetting(i),
            bestPotion = desiredEffect == "none" and l10n("belt_unassigned") or bestName,
            count = desiredEffect == "none" and l10n("belt_dash") or tostring(totalMatches),
            power = bestPower,
            priority = getSortSettingLabel(i),
            sortSetting = getSlotSortSetting(i),
            autoUse = autoUse,
            autoEnabled = getSlotAutoUse(i),
            autoSupported = isAutoUseSupported(desiredEffect),
            threshold = getSlotThreshold(i),
            configured = desiredEffect ~= "none",
        })
    end

    return {
        totalPotionStacks = potionStacks,
        totalPotionCount = potionCount,
        configuredSlots = configuredSlots,
        defaultPriority = getSortLabel(getGlobalSortOrder()),
        matchMode = getMatchModeLabel(),
        slots = slots,
    }
end

-- ============================================================================
-- POTION USE DISPATCH
-- ============================================================================

local function applyAndRemovePotion(best)
    local item = best and best.item
    if not item or not item:isValid() then
        return false, 'selected potion is invalid'
    end

    if not types.Potion.objectIsInstance(item) then
        return false, 'selected item is not a potion'
    end

    -- Let the engine consume the potion through the standard item-use path.
    -- Third-party animation/behavior mods can observe this event, and OpenMW
    -- handles potion effects, stack removal, and any item-specific semantics.
    core.sendGlobalEvent('UseItem', {
        object = item,
        actor = self.object,
        force = true,
    })

    return true
end

-- ============================================================================
-- POTION USAGE
-- ============================================================================

-- Sends a public notification when SPH has selected and dispatched a potion
-- through OpenMW's standard UseItem path. Dedicated animation mods should
-- prefer observing UseItem; this event remains as an SPH-specific companion hook.
local function notifyPotionUsed(slotNum, desiredEffect, best, isAutoUse)
    local remaining = math.max(0, (best.item.count or 1) - 1)

    local payload = {
        actor = self.object,
        object = best.item,
        potion = best.item, -- Alias for readability in third-party handlers.
        potionName = best.name,
        effect = desiredEffect,
        slot = slotNum,
        autoUse = isAutoUse == true,
        remaining = remaining,
    }

    -- Local/player-script hook. This is the hook animation mods generally want,
    -- because player/local scripts can use openmw.animation.
    self.object:sendEvent(MODNAME .. '_PotionUsed', payload)

    -- Optional global-script hook for non-animation integrations.
    core.sendGlobalEvent(MODNAME .. '_PotionUsed', payload)
end

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

    -- Arm the guard for every configured SPH hotkey press, even when no
    -- matching potion exists. Otherwise the same physical key can fall through
    -- to OpenMW's vanilla quick-key and ready spell stance on empty slots.
    queueHotkeyGuard()

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

    local applied, applyErr = applyAndRemovePotion(best)
    if not applied then
        print('[' .. MODNAME .. '] Potion use failed; potion was not consumed: ' .. tostring(applyErr))
        return
    end

    notifyPotionUsed(slotNum, desiredEffect, best, false)

    if getShowMessage() then
        local l10n = core.l10n(L10N)
        local remaining = math.max(0, (best.item.count or 1) - 1)
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

                                    local applied, applyErr = applyAndRemovePotion(best)
                                    if not applied then
                                        print('[' .. MODNAME .. '] Potion use failed; potion was not consumed: ' .. tostring(applyErr))
                                        return
                                    end

                                    notifyPotionUsed(i, desiredEffect, best, true)

                                    if getShowMessage() then
                                        local l10n = core.l10n(L10N)
                                        local remaining = math.max(0, (best.item.count or 1) - 1)
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
    registerInput()
    registerSettings()
    belt.init(buildPotionBeltSnapshot, beltActions)
    snapshotCurrentState()
end

local function onLoad()
    registerInput()
    registerSettings()
    belt.init(buildPotionBeltSnapshot, beltActions)
    snapshotCurrentState()
end

local function onFrame(dt)
    local now = core.getSimulationTime()
    restoreHotkeyGuard(now)
    if not pendingHotkeyGuard then
        snapshotCurrentState()
    end
end

local function onUpdate(dt)
    local now = core.getSimulationTime()

    restoreHotkeyGuard(now)
    if not pendingHotkeyGuard then
        snapshotCurrentState()
    end

    if now >= nextInventoryButtonHook then
        belt.hookInventoryButton()
        nextInventoryButtonHook = now + INVENTORY_BUTTON_HOOK_INTERVAL
    end

    if now < nextAutoUseCheck then return end
    nextAutoUseCheck = now + AUTO_USE_INTERVAL
    checkAutoUse()
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onFrame = onFrame,
        onKeyPress = onKeyPress,
    },
}
