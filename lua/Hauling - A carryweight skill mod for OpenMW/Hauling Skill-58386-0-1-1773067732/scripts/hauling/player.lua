-- ============================================================================
-- HAULING SKILL MOD v9
-- If you see "HAULING v9" in the console on load, this file is active.
-- If you do NOT see it, the game is loading an old cached copy.
-- ============================================================================
local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local Actor = types.Actor

local VERSION = 9
local skillId = 'hauling_skill'

print("==============================================")
print("HAULING v" .. VERSION .. " LOADING")
print("==============================================")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local ENCUMBRANCE_THRESHOLD = 0.75
local CHECK_INTERVAL = 5.0
local MIN_MOVE_SPEED = 5

-- XP: Swimming accumulates 0.7 per second.
-- We accumulate 0.5 per 5 seconds = 0.1/s — about 7x slower than Swimming.
local WALK_XP_PER_TICK = 0.5
local PICKUP_XP = 1.0
local HEAVY_ITEM_THRESHOLD = 15.0
local XP_FLUSH_THRESHOLD = 0.3

-- Feather
local CURVE_EXPONENT = 1.6
local MAX_FEATHER_BONUS = 150

-- ============================================================================
-- STATE
-- ============================================================================

local saveData = {}
local checkTimer = 0
local skillRegistered = false

local settingsSection = storage.playerSection('SettingsHauling')
local function getSetting(key, default)
    local val = settingsSection:get(key)
    if val == nil then return default end
    return val
end

-- ============================================================================
-- SKILL REGISTRATION
-- ============================================================================

local function registerSkill()
    if skillRegistered then return end
    local API = I.SkillFramework
    if not API then return end

    local l10n = core.l10n('Hauling')

    API.registerSkill(skillId, {
        name = l10n('skill_hauling_name'),
        description = l10n('skill_hauling_desc'),
        icon = { fgr = "icons/hauling/hauling.dds" },
        attribute = "strength",
        specialization = API.SPECIALIZATION.Combat,
        skillGain = {
            [1] = 0.5,
        },
        startLevel = 5,
        maxLevel = 100,
        statsWindowProps = {
            subsection = API.STATS_WINDOW_SUBSECTIONS.Movement
        }
    })

    API.registerRaceModifier(skillId, 'orc', 15)
    API.registerRaceModifier(skillId, 'nord', 10)
    API.registerRaceModifier(skillId, 'redguard', 5)
    API.registerRaceModifier(skillId, 'imperial', 5)
    API.registerRaceModifier(skillId, 'bosmer', -10)
    API.registerRaceModifier(skillId, 'altmer', -5)
    API.registerRaceModifier(skillId, 'khajiit', -5)

    skillRegistered = true
    print("HAULING v" .. VERSION .. ": Skill registered")
end

-- ============================================================================
-- FEATHER BONUS
-- ============================================================================

local function calculateFeatherBonus()
    local API = I.SkillFramework
    if not API then return 0 end
    local stat = API.getSkillStat(skillId)
    if not stat then return 0 end
    local level = math.max(0, stat.modified)
    local maxBonus = getSetting('MaxFeatherBonus', MAX_FEATHER_BONUS)
    local exponent = getSetting('CurveExponent', CURVE_EXPONENT)
    local fraction = math.min(level / 100.0, 1.0)
    return math.floor((fraction ^ exponent) * maxBonus)
end

local function applyFeatherBonus()
    local newBonus = calculateFeatherBonus()
    if newBonus == saveData.currentFeatherBonus then return end
    local delta = newBonus - saveData.currentFeatherBonus
    if delta ~= 0 then
        Actor.activeEffects(self):modify(delta, 'feather')
    end
    saveData.currentFeatherBonus = newBonus
end

local function removeFeatherBonus()
    if saveData.currentFeatherBonus ~= 0 then
        Actor.activeEffects(self):modify(-saveData.currentFeatherBonus, 'feather')
        saveData.currentFeatherBonus = 0
    end
end

-- ============================================================================
-- UPDATE
-- ============================================================================

local function onUpdate(dt)
    if not skillRegistered then
        registerSkill()
        if not skillRegistered then return end
    end

    if saveData.needsPostLoadCleanup then
        saveData.needsPostLoadCleanup = false
        if saveData.currentFeatherBonus ~= 0 then
            Actor.activeEffects(self):modify(-saveData.currentFeatherBonus, 'feather')
            saveData.currentFeatherBonus = 0
        end
        applyFeatherBonus()
        saveData.lastEncumbrance = Actor.getEncumbrance(self)
        return
    end

    local API = I.SkillFramework
    if not API then return end

    checkTimer = checkTimer + dt
    if checkTimer < CHECK_INTERVAL then return end
    checkTimer = 0

    local capacity = Actor.getCapacity(self)
    local encumbrance = Actor.getEncumbrance(self)

    -- Heavy item pickup detection
    if saveData.lastEncumbrance then
        local weightDelta = encumbrance - saveData.lastEncumbrance
        if weightDelta >= HEAVY_ITEM_THRESHOLD then
            saveData.xpAccum = saveData.xpAccum + PICKUP_XP
            print(string.format("HAULING v%d: PICKUP +%.3f (accum %.3f)", VERSION, PICKUP_XP, saveData.xpAccum))
        end
    end
    saveData.lastEncumbrance = encumbrance

    -- Walking XP
    if capacity > 0 then
        local ratio = encumbrance / capacity
        if ratio >= ENCUMBRANCE_THRESHOLD and Actor.getCurrentSpeed(self) >= MIN_MOVE_SPEED then
            saveData.xpAccum = saveData.xpAccum + WALK_XP_PER_TICK
            print(string.format("HAULING v%d: WALK +%.3f (accum %.3f, ratio %.0f%%)",
                VERSION, WALK_XP_PER_TICK, saveData.xpAccum, ratio * 100))
        end
    end

    -- Flush to framework (same as Swimming)
    if saveData.xpAccum >= XP_FLUSH_THRESHOLD then
        local flushAmount = saveData.xpAccum
        API.skillUsed(skillId, { skillGain = flushAmount, useType = 1, scale = nil })
        saveData.xpAccum = 0
        local stat = API.getSkillStat(skillId)
        print(string.format("HAULING v%d: FLUSH %.3f | progress=%.2f%% level=%d",
            VERSION, flushAmount, stat and (stat.progress * 100) or 0, stat and stat.base or 0))
    end

    applyFeatherBonus()
end

-- ============================================================================
-- CONSOLE — matches Swimming's exact pattern
-- Usage: open console, type:  lua hauling 50
-- ============================================================================

local function onConsoleCommand(mode, command)
    local cmd = command:gsub("^%s*[Ll][Uu][Aa]%s+", "")
    local prefix, arg = cmd:match("^(%S+)%s*(%S*)")
    if not prefix or prefix:lower() ~= "hauling" then return end

    local API = I.SkillFramework
    if not API then return end

    local stat = API.getSkillStat(skillId)
    if not stat then return end

    local level = tonumber(arg)
    if level then
        stat.base = math.max(0, math.min(math.floor(level), 100))
        stat.progress = 0
        applyFeatherBonus()
        ui.showMessage("Hauling set to " .. stat.base)
    elseif arg == 'reset' then
        removeFeatherBonus()
        stat.base = 5
        stat.progress = 0
        saveData.xpAccum = 0
        applyFeatherBonus()
        ui.showMessage("Hauling reset to 5")
    elseif arg == 'info' then
        local capacity = Actor.getCapacity(self)
        local enc = Actor.getEncumbrance(self)
        ui.showMessage(string.format("Hauling: %d (base %d) | %.0f/%.0f (%.0f%%) | feather %d",
            stat.modified, stat.base, enc, capacity,
            capacity > 0 and (enc / capacity * 100) or 0,
            saveData.currentFeatherBonus))
    else
        -- No arg = level up by 1
        API.skillLevelUp(skillId, API.SKILL_INCREASE_SOURCES.Usage, 1)
        applyFeatherBonus()
        stat = API.getSkillStat(skillId)
        ui.showMessage("Hauling leveled up! Now " .. (stat and stat.base or "?"))
    end
end

-- ============================================================================
-- SAVE / LOAD
-- ============================================================================

local function onLoad(data)
    saveData = data or {}
    saveData.currentFeatherBonus = saveData.currentFeatherBonus or 0
    saveData.lastEncumbrance = saveData.lastEncumbrance or 0
    saveData.xpAccum = saveData.xpAccum or 0
    saveData.needsPostLoadCleanup = true
    print("HAULING v" .. VERSION .. ": Save loaded")
end

print("HAULING v" .. VERSION .. ": Script file parsed OK")

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onConsoleCommand = onConsoleCommand,
        onSave = function() return saveData end,
        onLoad = onLoad,
        onInit = onLoad,
    },
}