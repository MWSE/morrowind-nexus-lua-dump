--[[
    Spellsword! Skill — Player Script (init.lua)

    Responsibilities (player scope):
      * Register the "spellsword" skill via Skill Framework
      * Apply race modifiers (Breton/Dunmer/etc.) and class bonus
      * Register thematic skill books
      * Mirror player-section settings into a global runtime section so
        global.lua can read them (player scripts can write playerSection
        but not globalSection; global.lua does the inverse)
      * Receive Skill-XP grant events forwarded by global.lua and call
        I.SkillFramework.skillUsed
      * Listen to IW_RemoveMagicka (sent by Spellsword's hit script when
        Active mode burns magicka) — refund part of the cost based on the
        current skill efficiency, and grant magickaSpend XP
      * Build the dynamic skill tooltip showing current max charges, the
        next-milestone preview, and the calculated Active-mode usage count
        derived from current max magicka

    Architecture note: this file mirrors the Toxicology! init.lua scope split.
    It does NOT itself talk to types.Potion or any of the imbue weapon logic;
    that belongs to the base Spellsword mod and to our global.lua bridge.
]]

local core    = require('openmw.core')
local I       = require('openmw.interfaces')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local util    = require('openmw.util')

local config = require('scripts.spellsword_skill.config')

local MODNAME  = 'Spellsword'
local SKILL_ID = config.skillId

-- ─── Settings helpers ───────────────────────────────────────────────────────
-- Toxicology pattern: every group is its own storage section, suffix-keyed.

local settingsSections = {}

local function settingSection(groupSuffix)
    local sectionName = 'Settings_' .. MODNAME
    if groupSuffix and groupSuffix ~= '' then
        sectionName = sectionName .. '_' .. groupSuffix
    end
    local section = settingsSections[sectionName]
    if not section then
        section = storage.playerSection(sectionName)
        settingsSections[sectionName] = section
    end
    return section
end

local function readSetting(groupSuffix, key, default)
    local val = settingSection(groupSuffix):get(key)
    if val == nil then return default end
    return val
end

local function debugEnabled(category)
    if not readSetting('UI', 'debugMessages', false) then return false end
    if not category then return true end
    return readSetting('UI', category, false)
end

local function debugLog(msg, category)
    if debugEnabled(category) then
        print('[Imbuement!] ' .. tostring(msg))
    end
end

-- ─── One-way settings sync: player → global ────────────────────────────────
-- Global scripts can't read playerSection. We bundle every setting global.lua
-- needs into a single dictionary and dispatch it via SpellswordSkill_SyncSettings.
-- The global handler writes the payload to its Runtime_SpellswordSkill section
-- and any subsequent read in global.lua hits that mirror.

local SYNCED_KEYS = {
    -- General
    { section = '',          key = 'enabled' },
    { section = '',          key = 'driveBaseElementalBuff' },
    { section = '',          key = 'driveSpellStacking' },
    { section = '',          key = 'driveActiveMagickaEfficiency' },
    { section = '',          key = 'driveCharges' },
    -- Skill & progression
    { section = 'Skill',     key = 'xpOnApply' },
    { section = 'Skill',     key = 'xpOnChargeSpend' },
    { section = 'Skill',     key = 'xpOnMagickaSpend' },
    { section = 'Skill',     key = 'xpOnFirstUseFree' },
    { section = 'Skill',     key = 'xpMultiplier' },
    -- Mechanics
    { section = 'Mechanics', key = 'baseCharges' },
    { section = 'Mechanics', key = 'chargesPerMilestone' },
    { section = 'Mechanics', key = 'milestoneInterval' },
    { section = 'Mechanics', key = 'maxCharges' },
    { section = 'Mechanics', key = 'activeStepPercent' },
    { section = 'Mechanics', key = 'activeMaxReductionPercent' },
    { section = 'Mechanics', key = 'baseElementalBuff' },
    { section = 'Mechanics', key = 'elementalStepPerMilestone' },
    { section = 'Mechanics', key = 'maxElementalBuff' },
    { section = 'Mechanics', key = 'spellStackingUnlockLevel' },
    { section = 'Mechanics', key = 'allowSpellStacking' },
    -- Perks
    { section = 'Perks',     key = 'enableAllPerks' },
    { section = 'Perks',     key = 'enableLingeringImbue' },
    { section = 'Perks',     key = 'enableArcaneFlow' },
    { section = 'Perks',     key = 'arcaneFlowMagickaPerHit' },
    { section = 'Perks',     key = 'arcaneFlowCooldownSec' },
    { section = 'Perks',     key = 'enablePerfectConduit' },
    { section = 'Perks',     key = 'perfectConduitMagnitude' },
    { section = 'Perks',     key = 'perfectConduitDurationSec' },
    { section = 'Perks',     key = 'enableArcaneOverdrive' },
    { section = 'Perks',     key = 'arcaneOverdriveDurationSec' },
    { section = 'Perks',     key = 'arcaneOverdriveCooldownSec' },
    -- UI
    { section = 'UI',        key = 'imbueSpellCost' },
    { section = 'UI',        key = 'debugMessages' },
    { section = 'UI',        key = 'debugXpMessages' },
    { section = 'UI',        key = 'debugOverrideMessages' },
    { section = 'UI',        key = 'debugIntegrationMessages' },
}

local lastSyncedPayload = nil

local function payloadChanged(payload)
    if not lastSyncedPayload then return true end
    for k, v in pairs(payload) do
        if lastSyncedPayload[k] ~= v then return true end
    end
    for k, _ in pairs(lastSyncedPayload) do
        if payload[k] == nil then return true end
    end
    return false
end

local function syncSettingsToGlobal(force)
    local payload = {}
    for _, entry in ipairs(SYNCED_KEYS) do
        payload[entry.key] = settingSection(entry.section):get(entry.key)
    end
    if not force and not payloadChanged(payload) then return end
    core.sendGlobalEvent('SpellswordSkill_SyncSettings', payload)
    lastSyncedPayload = payload
end

-- ─── XP scaling ────────────────────────────────────────────────────────────

local function xpMultiplier()
    local value = tonumber(readSetting('Skill', 'xpMultiplier', 100)) or 100
    if value < 0 then value = 0 end
    return value * 0.01
end

-- ─── Skill registration ────────────────────────────────────────────────────

local skillRegistered = false

local function skillIsRegistered()
    return I.SkillFramework
        and I.SkillFramework.getSkillRecord
        and I.SkillFramework.getSkillRecord(SKILL_ID) ~= nil
end

local function registerSkill()
    if not I.SkillFramework then
        debugLog('Skill Framework not found — skill will not appear.', 'debugIntegrationMessages')
        return false
    end
    if skillIsRegistered() then
        skillRegistered = true
        return true
    end

    -- Spellsword is a Combat-spec, Willpower-governed skill in The Elder Scrolls
    -- tradition (Spellsword class uses Long Blade + Destruction). Pinning the
    -- governing attribute to Willpower keeps the magicka-efficiency theme
    -- coherent without colliding with the Toxicology-style stealth bucket.
    I.SkillFramework.registerSkill(SKILL_ID, {
        name = 'Imbuement',
        description = 'Governs your discipline with imbued-weapon magic. A practised imbuer extracts more charges from each imbuement, sustains the Active mode longer per point of magicka, and unleashes stronger elemental synergy on every strike.',
        attribute = 'willpower',
        specialization = I.SkillFramework.SPECIALIZATION.Combat,
        startLevel = config.startLevel,
        maxLevel   = config.maxLevel,
        skillGain = {
            apply        = config.xp.apply,
            chargeSpend  = config.xp.chargeSpend,
            magickaSpend = config.xp.magickaSpend,
            firstUseFree = config.xp.firstUseFree,
        },
        statsWindowProps = {
            subsection = 'Combat',
            shortenedName = 'Imbuement',
            visible = true,
        },
        icon = {
            -- The user's arcanist.dds is a fully-opaque standalone icon (it
            -- contains its own blue background frame), not a transparent
            -- silhouette intended to layer over a Skill Framework frame.
            -- We therefore use it as BOTH the bgr and fgr so the layered
            -- compositor still has something to draw if Skill Framework
            -- expects both, but the visible result is just the user's tile.
            bgr = 'icons/ImbuementSkill/arcanist.dds',
            fgr = 'icons/ImbuementSkill/arcanist.dds',
            bgrColor = util.color.rgb(1, 1, 1),
            fgrColor = util.color.rgb(1, 1, 1),
        },
    })

    if readSetting('Skill', 'enableRaceBonuses', true) then
        for _, entry in ipairs(config.raceBonuses) do
            local ok, err = pcall(function()
                I.SkillFramework.registerRaceModifier(SKILL_ID, entry.id, entry.amount)
            end)
            if not ok then
                debugLog('registerRaceModifier failed for ' .. tostring(entry.id) .. ': ' .. tostring(err), 'debugIntegrationMessages')
            end
        end
    end

    if readSetting('Skill', 'enableSkillBooks', true) then
        for _, bookId in ipairs(config.skillBooks) do
            local ok, err = pcall(function()
                I.SkillFramework.registerSkillBook(bookId, SKILL_ID)
            end)
            if not ok then
                debugLog('registerSkillBook failed for ' .. tostring(bookId) .. ': ' .. tostring(err), 'debugIntegrationMessages')
            end
        end
    end

    debugLog('Spellsword skill registered (Willpower, Combat spec).', 'debugIntegrationMessages')
    skillRegistered = true
    return true
end

local function getSpellswordSkillLevel()
    if I.SkillFramework and skillRegistered then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then return stat.modified end
    end
    return config.startLevel
end

local lastSyncedSkill = nil

local function syncRuntimeSkillToGlobal(force)
    local skill = math.floor(getSpellswordSkillLevel() or config.startLevel or 1)
    if not force and lastSyncedSkill == skill then return end
    lastSyncedSkill = skill
    core.sendGlobalEvent('SpellswordSkill_SyncSettings', { currentSkill = skill })
end

-- ─── Class bonus (Combat specialisation) ───────────────────────────────────

local classBonusApplied = false
local classBonusMode = 'none'
local classDynamicModifierRegistered = false

local function getPlayerClassRecord()
    local npcRec = types.NPC.record(self)
    if not npcRec or not npcRec.class then return nil, nil end
    return npcRec.class, types.NPC.classes.record(npcRec.class)
end

local function getClassSpecializationBonus()
    if not readSetting('Skill', 'enableClassBonus', true) then return 0 end
    if not types.Player.isCharGenFinished(self) then return 0 end
    local _, classRec = getPlayerClassRecord()
    if classRec and classRec.specialization == 'combat' then
        return config.classBonus
    end
    return 0
end

local function registerClassBonusModifier()
    if classDynamicModifierRegistered then return end
    if not (I.SkillFramework and I.SkillFramework.registerDynamicModifier and skillIsRegistered()) then return end
    I.SkillFramework.registerDynamicModifier(SKILL_ID, 'SpellswordSkill_ClassSpecializationBonus', getClassSpecializationBonus)
    classDynamicModifierRegistered = true
    classBonusApplied = true
    classBonusMode = 'dynamic'
end

local function applyClassBonus()
    if classBonusApplied and classBonusMode == 'dynamic' then return end
    registerClassBonusModifier()
end

local function reconcileClassBonusMode()
    if not classDynamicModifierRegistered then return end
    -- Dynamic modifier reads the setting live, no further work needed.
end

local lastAAMClassBonus = nil

local function notifyAAM(force)
    if not (I and I.AAM and I.AAM.reportExternalModifiers) then return end
    local amount = getClassSpecializationBonus()
    if not force and lastAAMClassBonus == amount then return end
    lastAAMClassBonus = amount
    local report = {}
    if amount ~= 0 then report[SKILL_ID] = amount end
    I.AAM.reportExternalModifiers(MODNAME, next(report) and report or {})
end

-- ─── Mechanic calculations (mirrored from global.lua so tooltip can use them
--     without round-tripping through events) ──────────────────────────────

local function clampInt(value, fallback, lo, hi)
    value = tonumber(value) or fallback
    value = math.floor(value)
    if value < lo then value = lo end
    if value > hi then value = hi end
    return value
end

local function clampNum(value, fallback, lo, hi)
    value = tonumber(value) or fallback
    if value < lo then value = lo end
    if value > hi then value = hi end
    return value
end

local function effectiveMilestoneInterval()
    return clampInt(readSetting('Mechanics', 'milestoneInterval', config.charges.milestoneInterval),
        config.charges.milestoneInterval, 1, 100)
end

local function milestonesPassedAt(skill, interval)
    interval = interval or effectiveMilestoneInterval()
    if interval <= 0 then return 0 end
    return math.floor((tonumber(skill) or 0) / interval)
end

local function chargesAtSkill(skill)
    local base = clampInt(readSetting('Mechanics', 'baseCharges', config.charges.baseCharges),
        config.charges.baseCharges, 0, 9999)
    local step = clampInt(readSetting('Mechanics', 'chargesPerMilestone', config.charges.chargesPerMilestone),
        config.charges.chargesPerMilestone, 0, 9999)
    local cap = clampInt(readSetting('Mechanics', 'maxCharges', config.charges.maxCharges),
        config.charges.maxCharges, 0, 9999)
    local interval = effectiveMilestoneInterval()
    local total = base + milestonesPassedAt(skill, interval) * step
    if total > cap then total = cap end
    if total < 0 then total = 0 end
    return total
end

local function activeReductionPercentAtSkill(skill)
    local step = clampInt(readSetting('Mechanics', 'activeStepPercent', config.activeMagickaEfficiency.stepPercent),
        config.activeMagickaEfficiency.stepPercent, 0, 100)
    local cap = clampInt(readSetting('Mechanics', 'activeMaxReductionPercent', config.activeMagickaEfficiency.maxReductionPercent),
        config.activeMagickaEfficiency.maxReductionPercent, 0, 99)
    local interval = effectiveMilestoneInterval()
    local pct = milestonesPassedAt(skill, interval) * step
    if pct > cap then pct = cap end
    if pct < 0 then pct = 0 end
    return pct
end

local function elementalBuffAtSkill(skill)
    local base = clampNum(readSetting('Mechanics', 'baseElementalBuff', config.elementalBuff.baseBuff),
        config.elementalBuff.baseBuff, 0, 999)
    local step = clampNum(readSetting('Mechanics', 'elementalStepPerMilestone', config.elementalBuff.stepPerMilestone),
        config.elementalBuff.stepPerMilestone, 0, 999)
    local cap = clampNum(readSetting('Mechanics', 'maxElementalBuff', config.elementalBuff.maxBuff),
        config.elementalBuff.maxBuff, 0, 999)
    local interval = effectiveMilestoneInterval()
    local total = base + milestonesPassedAt(skill, interval) * step
    if total > cap then total = cap end
    if total < 0 then total = 0 end
    return total
end

local function spellStackingUnlocked(skill)
    if not readSetting('Mechanics', 'allowSpellStacking', true) then return false end
    local unlock = clampInt(readSetting('Mechanics', 'spellStackingUnlockLevel', config.spellStacking.unlockLevel),
        config.spellStacking.unlockLevel, 0, 9999)
    return (tonumber(skill) or 0) >= unlock
end

local function chargesAtNextMilestone(skill)
    local interval = effectiveMilestoneInterval()
    local cap = clampInt(readSetting('Mechanics', 'maxCharges', config.charges.maxCharges),
        config.charges.maxCharges, 0, 9999)
    local current = chargesAtSkill(skill)
    if current >= cap then return nil, nil end -- already capped
    local nextMilestone = (milestonesPassedAt(skill, interval) + 1) * interval
    return nextMilestone, chargesAtSkill(nextMilestone)
end

local function getMaxMagicka()
    local ok, value = pcall(function()
        return types.Actor.stats.dynamic.magicka(self).base
    end)
    if not ok or not value then return 0 end
    return value
end

local function effectiveImbueSpellCost(skill)
    local raw = clampInt(readSetting('UI', 'imbueSpellCost', config.ui.imbueSpellCost),
        config.ui.imbueSpellCost, 1, 9999)
    local reductionPct = activeReductionPercentAtSkill(skill)
    local effective = raw * (1 - reductionPct * 0.01)
    if effective < 1 then effective = 1 end
    return effective, raw, reductionPct
end

local function activeModeUsesAtSkill(skill)
    local effective, _raw, _pct = effectiveImbueSpellCost(skill)
    local maxMag = getMaxMagicka()
    if effective <= 0 then return 0 end
    -- "First hit free" model: 1 free + floor(magicka / cost)
    local additional = math.floor(maxMag / effective)
    return additional + 1, effective, maxMag
end

-- ─── Perk helpers ──────────────────────────────────────────────────────────
-- All four perks share a common pattern: a skill-level unlock threshold + an
-- individual on/off toggle, gated by the master `enableAllPerks` switch. This
-- mirrors Toxicology's perk-gating exactly so the user experience is identical
-- across the two mods.

local function allPerksEnabled()
    return readSetting('Perks', 'enableAllPerks', true)
end

local function perkEnabledSetting(perkId)
    local key = ({
        lingeringImbue  = 'enableLingeringImbue',
        arcaneFlow      = 'enableArcaneFlow',
        perfectConduit  = 'enablePerfectConduit',
        arcaneOverdrive = 'enableArcaneOverdrive',
    })[perkId]
    if not key then return true end
    return readSetting('Perks', key, true)
end

local function perkLevel(perkId)
    local key = ({
        lingeringImbue  = 'lingeringImbueLevel',
        arcaneFlow      = 'arcaneFlowLevel',
        perfectConduit  = 'perfectConduitLevel',
        arcaneOverdrive = 'arcaneOverdriveLevel',
    })[perkId]
    if not key then return 999 end
    return tonumber(config.perks[key]) or 999
end

local function perkActive(perkId, skill)
    if not allPerksEnabled() then return false end
    if not perkEnabledSetting(perkId) then return false end
    return (tonumber(skill) or 0) >= perkLevel(perkId)
end

-- Arcane Flow tuning lookups
local function arcaneFlowMagickaPerHit()
    return clampInt(readSetting('Perks', 'arcaneFlowMagickaPerHit', config.perks.arcaneFlowMagickaPerHit),
        config.perks.arcaneFlowMagickaPerHit, 0, 9999)
end
local function arcaneFlowCooldownSec()
    return clampNum(readSetting('Perks', 'arcaneFlowCooldownSec', config.perks.arcaneFlowCooldownSec),
        config.perks.arcaneFlowCooldownSec, 0, 9999)
end

-- Perfect Conduit tuning lookups
local function perfectConduitMagnitude()
    return clampInt(readSetting('Perks', 'perfectConduitMagnitude', config.perks.perfectConduitMagnitude),
        config.perks.perfectConduitMagnitude, 0, 9999)
end
local function perfectConduitDurationSec()
    return clampInt(readSetting('Perks', 'perfectConduitDurationSec', config.perks.perfectConduitDurationSec),
        config.perks.perfectConduitDurationSec, 1, 9999)
end

-- Perfect Conduit transition table.
-- Cycle: Fire → Shock → Frost → Fire.
-- The third entry's keys are the spell IDs, the values are the stat to fortify.
local PERFECT_CONDUIT_TRANSITIONS = {
    spellsword_fire = {
        target = 'spellsword_shock',
        stat   = 'speed',     -- attack speed feel
        label  = 'Fire → Shock: Fortify Speed',
    },
    spellsword_shock = {
        target = 'spellsword_frost',
        stat   = 'agility',   -- stagger resistance (Morrowind stagger ↔ Agility)
        label  = 'Shock → Frost: Fortify Agility',
    },
    spellsword_frost = {
        target = 'spellsword_fire',
        stat   = 'strength',  -- weapon damage (scales with Strength)
        label  = 'Frost → Fire: Fortify Strength',
    },
}

-- Arcane Overdrive tuning lookups
local function arcaneOverdriveDurationSec()
    return clampInt(readSetting('Perks', 'arcaneOverdriveDurationSec', config.perks.arcaneOverdriveDurationSec),
        config.perks.arcaneOverdriveDurationSec, 1, 9999)
end
local function arcaneOverdriveCooldownSec()
    return clampInt(readSetting('Perks', 'arcaneOverdriveCooldownSec', config.perks.arcaneOverdriveCooldownSec),
        config.perks.arcaneOverdriveCooldownSec, 1, 9999)
end

-- ─── Runtime state for the new perks ──────────────────────────────────────
-- Arcane Flow: tracks the last simulation time we procced so the cooldown
-- can gate rapid follow-up hits.
local arcaneFlowLastProcTime = -math.huge

-- Perfect Conduit: active stat buffs we've applied. Each entry is
-- { stat = 'speed' | 'agility' | 'strength', amount = N, expiresAt = T }.
-- The amount is the delta we ADDED to the stat's modifier — we subtract that
-- same delta on expiry, so other simultaneously-running magic effects on the
-- same stat are preserved.
local perfectConduitBuffs = {}

-- Arcane Overdrive: window-active flag, window-end time, last-trigger time.
local arcaneOverdriveActive  = false
local arcaneOverdriveEndsAt  = 0
local arcaneOverdriveLastTrigger = -math.huge

local function nowTime()
    return core.getSimulationTime() or 0
end

-- ─── Arcane Flow application ──────────────────────────────────────────────
-- Called once per successful imbued hit (Charges mode via the forwarded
-- SpellswordSkill_ChargeSpent event from global, or Active mode via our own
-- IW_RemoveMagicka observer). Restores a small amount of magicka, subject to
-- the cooldown gate.

local function applyArcaneFlow(skill)
    if not perkActive('arcaneFlow', skill) then return false end
    local amount = arcaneFlowMagickaPerHit()
    if amount <= 0 then return false end
    local cd = arcaneFlowCooldownSec()
    local t  = nowTime()
    if t - arcaneFlowLastProcTime < cd then return false end
    arcaneFlowLastProcTime = t

    local ok, stat = pcall(function() return types.Actor.stats.dynamic.magicka(self) end)
    if not ok or not stat then return false end
    local current = stat.current or 0
    local base    = stat.base or current
    local newVal  = current + amount
    if newVal > base then newVal = base end
    stat.current = newVal
    debugLog(string.format('Arcane Flow: +%d magicka (now %.1f / %.1f)', amount, newVal, base),
        'debugOverrideMessages')
    return true
end

-- ─── Perfect Conduit application ──────────────────────────────────────────
-- Called when global detects a cross-element transition along the elemental
-- cycle. Adds a Fortify-style modifier to the relevant stat and schedules its
-- expiry. Re-triggering the same buff refreshes the timer rather than stacking.

local function readAttribute(name)
    local ok, stat = pcall(function() return types.Actor.stats.attributes[name](self) end)
    if not ok then return nil end
    return stat
end

local function findActiveBuff(statName)
    for i, b in ipairs(perfectConduitBuffs) do
        if b.stat == statName then return i, b end
    end
    return nil, nil
end

local function expirePerfectConduitBuff(index, reason)
    local buff = perfectConduitBuffs[index]
    if not buff then return end
    local stat = readAttribute(buff.stat)
    if stat then
        local cur = tonumber(stat.modifier) or 0
        stat.modifier = cur - buff.amount
        debugLog(string.format('Perfect Conduit: expired %s buff (-%d). reason=%s',
            buff.stat, buff.amount, tostring(reason or 'time')), 'debugOverrideMessages')
    end
    table.remove(perfectConduitBuffs, index)
end

local function applyPerfectConduit(transitionFrom, transitionTo, skill)
    if not perkActive('perfectConduit', skill) then return false end
    local from = PERFECT_CONDUIT_TRANSITIONS[transitionFrom]
    if not from or from.target ~= transitionTo then
        -- Not a forward-cycle transition; perk gives nothing here.
        return false
    end
    local magnitude = perfectConduitMagnitude()
    local duration  = perfectConduitDurationSec()
    if magnitude <= 0 or duration <= 0 then return false end

    local stat = readAttribute(from.stat)
    if not stat then return false end

    -- Refresh existing buff on this stat (don't stack with self).
    local idx, existing = findActiveBuff(from.stat)
    if existing then
        existing.expiresAt = nowTime() + duration
        debugLog(string.format('Perfect Conduit: refreshed %s buff (+%d, %ds)',
            from.stat, existing.amount, duration), 'debugOverrideMessages')
        return true
    end

    local cur = tonumber(stat.modifier) or 0
    stat.modifier = cur + magnitude
    table.insert(perfectConduitBuffs, {
        stat      = from.stat,
        amount    = magnitude,
        expiresAt = nowTime() + duration,
        label     = from.label,
    })
    debugLog(string.format('Perfect Conduit: applied %s (+%d, %ds) — %s',
        from.stat, magnitude, duration, from.label), 'debugOverrideMessages')
    return true
end

local function tickPerfectConduitExpiry()
    if #perfectConduitBuffs == 0 then return end
    local t = nowTime()
    -- Iterate backwards so removals don't reindex what we haven't checked yet.
    for i = #perfectConduitBuffs, 1, -1 do
        if perfectConduitBuffs[i].expiresAt <= t then
            expirePerfectConduitBuff(i, 'time')
        end
    end
end

local function clearAllPerfectConduitBuffs(reason)
    for i = #perfectConduitBuffs, 1, -1 do
        expirePerfectConduitBuff(i, reason)
    end
end

-- ─── Arcane Overdrive control ─────────────────────────────────────────────
-- Triggered via the `spellsword overdrive` console command. Manages the
-- window-active flag, its expiry, and the cooldown gate. The actual mechanic
-- (charge refund, magicka refund, cross-element carry-over) lives elsewhere
-- and reads `arcaneOverdriveActive` via the shared runtime mirror.

local function isArcaneOverdriveActive() return arcaneOverdriveActive end

local function arcaneOverdriveCooldownRemaining()
    local cd = arcaneOverdriveCooldownSec()
    local elapsed = nowTime() - arcaneOverdriveLastTrigger
    if elapsed >= cd then return 0 end
    return cd - elapsed
end

local function tryStartArcaneOverdrive(skill)
    if not perkActive('arcaneOverdrive', skill) then
        return false, 'Arcane Overdrive perk is locked or disabled.'
    end
    local remaining = arcaneOverdriveCooldownRemaining()
    if remaining > 0 then
        return false, string.format('Arcane Overdrive cooldown: %.0fs remaining.', remaining)
    end
    arcaneOverdriveActive     = true
    arcaneOverdriveLastTrigger = nowTime()
    arcaneOverdriveEndsAt     = arcaneOverdriveLastTrigger + arcaneOverdriveDurationSec()
    debugLog(string.format('Arcane Overdrive: STARTED (%ds duration)',
        arcaneOverdriveDurationSec()), 'debugOverrideMessages')
    return true, string.format('Arcane Overdrive engaged for %ds.', arcaneOverdriveDurationSec())
end

local function tickArcaneOverdriveExpiry()
    if not arcaneOverdriveActive then return end
    if nowTime() >= arcaneOverdriveEndsAt then
        arcaneOverdriveActive = false
        debugLog('Arcane Overdrive: window ended.', 'debugOverrideMessages')
    end
end

-- Sync state to global runtime mirror so global handlers can check the
-- "Overdrive active" flag without a round-trip event.
local lastSyncedOverdrive = nil
local function syncOverdriveToGlobal(force)
    local active = arcaneOverdriveActive and true or false
    if not force and lastSyncedOverdrive == active then return end
    lastSyncedOverdrive = active
    core.sendGlobalEvent('SpellswordSkill_SyncSettings', { overdriveActive = active })
end

-- ─── Tooltip / status summaries ───────────────────────────────────────────
-- Tooltip-summary line for a single perk. Format matches Toxicology's
-- "[Active] " / "[Unlock N] " prefix convention exactly.
local function perkSummary(skill, perkId)
    local level = perkLevel(perkId)
    local active = (tonumber(skill) or 0) >= level
    local prefix = active and '[Active] ' or string.format('[Unlock %d] ', level)
    if perkId == 'lingeringImbue' then
        return prefix .. 'Lingering Imbue: casting a fresh imbue carries over any remaining charges from a previously active imbue, even across elements.'
    elseif perkId == 'arcaneFlow' then
        return prefix .. string.format(
            'Arcane Flow: each successful imbued hit restores %d magicka (%.1fs cooldown).',
            arcaneFlowMagickaPerHit(), arcaneFlowCooldownSec()
        )
    elseif perkId == 'perfectConduit' then
        return prefix .. string.format(
            'Perfect Conduit: switching elements along the cycle (Fire→Shock→Frost→Fire) grants +%d to Speed/Agility/Strength for %ds.',
            perfectConduitMagnitude(), perfectConduitDurationSec()
        )
    elseif perkId == 'arcaneOverdrive' then
        local extra = ''
        if active then
            if arcaneOverdriveActive then
                local left = math.max(0, arcaneOverdriveEndsAt - nowTime())
                extra = string.format(' [ACTIVE — %.0fs left]', left)
            else
                local cd = arcaneOverdriveCooldownRemaining()
                if cd > 0 then extra = string.format(' [cooldown %.0fs]', cd) end
            end
        end
        return prefix .. string.format(
            'Arcane Overdrive: console "spellsword overdrive" engages a %ds window (%ds cooldown) — charges and magicka costs are fully refunded, and any cross-element cast carries charges forward.%s',
            arcaneOverdriveDurationSec(), arcaneOverdriveCooldownSec(), extra
        )
    end
    return nil
end

local PERK_ORDER = {
    'lingeringImbue',
    'arcaneFlow',
    'perfectConduit',
    'arcaneOverdrive',
}

-- ─── Dynamic skill tooltip ─────────────────────────────────────────────────

local lastBuiltDescription = nil

local function fmtPct(pct)
    return string.format('%d%%', math.floor(pct + 0.5))
end

local function fmtBuff(buff)
    -- Show as percentage with one decimal where helpful (matches base
    -- Spellsword's intuition: 0.15 → "+15.0%").
    local pct = buff * 100
    if math.abs(pct - math.floor(pct + 0.5)) < 0.05 then
        return string.format('+%d%%', math.floor(pct + 0.5))
    end
    return string.format('+%0.1f%%', pct)
end

local function buildSkillDescription()
    local skill = math.floor(getSpellswordSkillLevel())
    local enabled = readSetting('', 'enabled', true)
    local showMechanic = readSetting('UI', 'showMechanicTooltips', true)
    local showMilestone = readSetting('UI', 'showMilestonePreview', true)
    local showActive = readSetting('UI', 'showActiveModePreview', true)

    local lines = {
        'Governs your discipline with imbued-weapon magic.',
        '',
        string.format('Current Imbuement: %d', skill),
    }

    if not enabled then
        table.insert(lines, '')
        table.insert(lines, '[Skill mod disabled in settings — base Spellsword behaviour is unchanged.]')
        return table.concat(lines, '\n')
    end

    if showMechanic then
        local charges = chargesAtSkill(skill)
        local buff = elementalBuffAtSkill(skill)
        local reductionPct = activeReductionPercentAtSkill(skill)
        local stacking = spellStackingUnlocked(skill)

        table.insert(lines, string.format('Charges per imbue cast: %d', charges))
        table.insert(lines, string.format('Elemental synergy bonus: %s', fmtBuff(buff)))
        table.insert(lines, string.format('Active-mode magicka drain reduction: %s', fmtPct(reductionPct)))
        table.insert(lines, string.format('Spell stacking: %s', stacking and 'unlocked' or 'locked'))
    end

    if showActive then
        local uses, effectiveCost, maxMag = activeModeUsesAtSkill(skill)
        if maxMag and maxMag > 0 then
            table.insert(lines, '')
            table.insert(lines, string.format(
                'Active-mode uses at current magicka: ~%d hits, cost %0.1f/%d magicka',
                uses, effectiveCost, math.floor(maxMag)
            ))
        end
    end

    if showMilestone then
        local nextLevel, nextCharges = chargesAtNextMilestone(skill)
        if nextLevel and nextCharges then
            local delta = nextCharges - chargesAtSkill(skill)
            table.insert(lines, '')
            table.insert(lines, string.format(
                'Next milestone at Imbuement %d: +%d charges (total %d).',
                nextLevel, delta, nextCharges
            ))
        else
            local cap = clampInt(readSetting('Mechanics', 'maxCharges', config.charges.maxCharges),
                config.charges.maxCharges, 0, 9999)
            table.insert(lines, '')
            table.insert(lines, string.format('Charges capped at %d — no further milestone gains.', cap))
        end
    end

    -- ─── Perks block ────────────────────────────────────────────────────────
    -- Mirrors Toxicology's tooltip layout: one line per enabled perk with the
    -- standard [Active] / [Unlock N] prefix. Honours the unlockedOnly toggle
    -- (which keeps low-level tooltips short by showing only what the player
    -- has already earned, plus a hint about the next unlock).
    if readSetting('UI', 'showPerkTooltips', true) and allPerksEnabled() then
        local unlockedOnly = readSetting('UI', 'tooltipUnlockedOnly', false)
        local perkLines = {}
        for _, perkId in ipairs(PERK_ORDER) do
            if perkEnabledSetting(perkId) and ((not unlockedOnly) or skill >= perkLevel(perkId)) then
                local line = perkSummary(skill, perkId)
                if line then table.insert(perkLines, line) end
            end
        end
        if unlockedOnly and #perkLines == 0 then
            local nextPerkId = nil
            for _, perkId in ipairs(PERK_ORDER) do
                if perkEnabledSetting(perkId) and skill < perkLevel(perkId) then
                    nextPerkId = perkId
                    break
                end
            end
            if nextPerkId then
                table.insert(perkLines, string.format(
                    'No perks unlocked yet. Next unlock at Imbuement %d.',
                    perkLevel(nextPerkId)
                ))
                table.insert(perkLines, perkSummary(skill, nextPerkId))
            else
                table.insert(perkLines, 'All remaining Imbuement perks are disabled in settings.')
            end
        end
        if #perkLines > 0 then
            table.insert(lines, '')
            table.insert(lines, 'Perks:')
            for _, line in ipairs(perkLines) do table.insert(lines, line) end
        end
    end

    return table.concat(lines, '\n')
end

local function refreshSkillDescription(force)
    if not I.SkillFramework or not I.SkillFramework.modifySkill then return end
    if not skillRegistered then return end
    local description = buildSkillDescription()
    if not force and description == lastBuiltDescription then return end
    local ok, err = pcall(function()
        I.SkillFramework.modifySkill(SKILL_ID, { description = description })
    end)
    if ok then
        lastBuiltDescription = description
    else
        debugLog('refreshSkillDescription: modifySkill failed: ' .. tostring(err), 'debugIntegrationMessages')
    end
end

-- ─── XP grant entry points ─────────────────────────────────────────────────

local function callSkillUsed(useType, extraScale)
    if not skillRegistered then return end
    if not I.SkillFramework or not I.SkillFramework.skillUsed then
        debugLog('callSkillUsed: SkillFramework.skillUsed unavailable', 'debugXpMessages')
        return
    end
    local scale = xpMultiplier() * (tonumber(extraScale) or 1)
    local ok, err = pcall(function()
        I.SkillFramework.skillUsed(SKILL_ID, { useType = useType, scale = scale })
    end)
    if not ok then
        debugLog('callSkillUsed: skillUsed (' .. tostring(useType) .. ') failed: ' .. tostring(err), 'debugXpMessages')
    else
        debugLog('Granted ' .. tostring(useType) .. ' XP (scale=' .. tostring(scale) .. ')', 'debugXpMessages')
    end
end

-- Called by global.lua when it observes an IW_SpellCast / IW_DecrementSpellCharge
-- event for a valid Spellsword imbue spell. The global script is responsible
-- for the validity check; this handler just routes to skillUsed.
local function onGrantXp(evt)
    if type(evt) ~= 'table' then return end
    local useType = evt.useType
    if not useType then return end
    if not readSetting('', 'enabled', true) then return end

    if useType == 'apply'        and not readSetting('Skill', 'xpOnApply',        true) then return end
    if useType == 'chargeSpend'  and not readSetting('Skill', 'xpOnChargeSpend',  true) then return end
    if useType == 'magickaSpend' and not readSetting('Skill', 'xpOnMagickaSpend', true) then return end
    if useType == 'firstUseFree' and not readSetting('Skill', 'xpOnFirstUseFree', true) then return end

    callSkillUsed(useType, evt.scale)
end

-- ─── IW_RemoveMagicka: refund + grant XP ───────────────────────────────────
-- Spellsword's hit script sends `IW_RemoveMagicka { amount = spell.cost }` to
-- the player whenever the Active mode pays for a hit. The base mod's player
-- handler then subtracts `amount` from current magicka.
--
-- Our handler runs in parallel (both event listeners receive the event). We:
--   1. Read the live active-spell from the IW_ActiveSpell global section
--      (Spellsword stores it there) and verify the spell id is one of the
--      three valid imbue spells.
--   2. Refund a fraction of `amount` based on the current skill's efficiency
--      reduction. Net magicka cost becomes amount * (1 - reduction).
--   3. Grant magickaSpend XP.
--
-- Order safety: refund + deduct are commutative; whether our handler runs
-- before or after Spellsword's, the final magicka value is identical.

local function readActiveImbueSpellId()
    local ok, section = pcall(storage.globalSection, 'IW_ActiveSpell')
    if not ok or not section then return nil end
    local spell = section:get('activeSpell')
    if type(spell) ~= 'table' then return nil end
    return spell.id
end

local function isValidImbueSpellId(id)
    if type(id) ~= 'string' then return false end
    return config.validImbueSpellIds[id] == true
end

local function refundMagicka(amount)
    if not amount or amount <= 0 then return end
    local ok, stat = pcall(function() return types.Actor.stats.dynamic.magicka(self) end)
    if not ok or not stat then return end
    -- Do NOT clamp to base here. If we ran AFTER base Spellsword's deduct,
    -- the deduct already brought us below max, and refund lands cleanly.
    -- If we ran BEFORE the deduct and the player was near full magicka,
    -- a clamp would discard refund the deduct will later make room for —
    -- producing inconsistent net costs depending on event-handler order.
    -- The engine will settle any momentary overshoot on the next tick.
    stat.current = (stat.current or 0) + amount
end

local function onRemoveMagickaObserved(data)
    if type(data) ~= 'table' then return end
    if not readSetting('', 'enabled', true) then return end

    -- Identify the spell that triggered the drain. If we can't confirm it's
    -- one of our three valid imbue spells, do nothing — no refund, no XP.
    -- This is the gate that excludes spellmaking-crafted "absorb"-based
    -- spells from progression.
    local spellId = readActiveImbueSpellId()
    if not isValidImbueSpellId(spellId) then
        debugLog('IW_RemoveMagicka observed but active spell is not a Spellsword imbue: '
            .. tostring(spellId), 'debugXpMessages')
        return
    end

    local skill = math.floor(getSpellswordSkillLevel())
    local amount = tonumber(data.amount) or 0

    -- Refund: efficiency milestone (continuous scaling track)
    if readSetting('', 'driveActiveMagickaEfficiency', true) then
        local reductionPct = activeReductionPercentAtSkill(skill)
        if reductionPct > 0 then
            local refund = amount * (reductionPct * 0.01)
            refundMagicka(refund)
            debugLog(string.format('Refunded %.2f magicka (%.0f%% efficiency at skill %d)',
                refund, reductionPct, skill), 'debugOverrideMessages')
        end
    end

    -- Arcane Overdrive (Perk 100): if the window is active, refund the
    -- REMAINING magicka cost on top of the standard efficiency refund.
    -- Together with the milestone refund this brings Active-mode net cost
    -- to zero during the window.
    if arcaneOverdriveActive and perkActive('arcaneOverdrive', skill) then
        local reductionPct = activeReductionPercentAtSkill(skill)
        local efficiencyRefund = amount * (reductionPct * 0.01)
        local remaining = amount - efficiencyRefund
        if remaining > 0 then
            refundMagicka(remaining)
            debugLog(string.format('Arcane Overdrive: refunded remaining %.2f magicka', remaining),
                'debugOverrideMessages')
        end
    end

    -- Arcane Flow (Perk 50): each successful Active-mode hit may restore a
    -- small fixed amount of magicka, subject to cooldown.
    applyArcaneFlow(skill)

    -- XP
    if readSetting('Skill', 'xpOnMagickaSpend', true) then
        callSkillUsed('magickaSpend')
    end
end

-- ─── Charge-spend event from global (drives Arcane Flow in Charges mode) ──
-- Global is the script that hears IW_DecrementSpellCharge; it forwards a
-- summary to us so the player-side Arcane Flow cooldown runs in one place,
-- with the same cooldown gate for both Charges and Active modes.

local function onChargeSpent(data)
    if not readSetting('', 'enabled', true) then return end
    if type(data) ~= 'table' then return end
    local skill = math.floor(getSpellswordSkillLevel())
    applyArcaneFlow(skill)
end

-- ─── Perfect Conduit trigger from global ──────────────────────────────────
-- Global detects the spell-id transition during applyPendingOverride and
-- forwards (from, to) to us. Player decides whether the perk is enabled and
-- applies the buff if so.

local function onPerfectConduitTrigger(data)
    if not readSetting('', 'enabled', true) then return end
    if type(data) ~= 'table' then return end
    if type(data.from) ~= 'string' or type(data.to) ~= 'string' then return end
    local skill = math.floor(getSpellswordSkillLevel())
    applyPerfectConduit(data.from, data.to, skill)
end

-- ─── Engine handlers ───────────────────────────────────────────────────────

local updateTimer = 0
local initRequested = false

local function onUpdate(dt)
    dt = tonumber(dt) or 0

    -- ─── Per-frame perk maintenance (runs ungated by the throttle) ─────────
    -- Perfect Conduit buffs and Arcane Overdrive both expire by simulation
    -- time. Tick them every frame so the timer resolution matches the
    -- engine's actual update rate.
    if dt > 0 and readSetting('', 'enabled', true) then
        tickPerfectConduitExpiry()
        tickArcaneOverdriveExpiry()
    end

    -- Throttle the heavier work to ~2 Hz; settings sync + skill registration
    -- don't need per-frame attention.
    updateTimer = updateTimer + dt
    if updateTimer < 0.5 then return end
    while updateTimer >= 0.5 do updateTimer = updateTimer - 0.5 end

    -- Always push current settings to global so it can read them.
    syncSettingsToGlobal(not initRequested)
    syncRuntimeSkillToGlobal(not initRequested)
    syncOverdriveToGlobal(not initRequested)

    if not readSetting('', 'enabled', true) then
        -- Even when disabled, refresh the description so the player sees
        -- the "disabled" tooltip text.
        if skillRegistered then refreshSkillDescription() end
        return
    end

    -- Skill Framework can take a few frames to be ready; retry until success.
    if not skillRegistered then
        registerSkill()
    end
    if skillRegistered and not classBonusApplied then
        applyClassBonus()
    elseif skillRegistered then
        reconcileClassBonusMode()
    end
    if skillRegistered then
        notifyAAM()
    end

    if not initRequested then
        syncRuntimeSkillToGlobal(true)
        core.sendGlobalEvent('SpellswordSkill_RequestInit', { player = self.object })
        initRequested = true
    end

    refreshSkillDescription()
end

local function onSave()
    -- Roll back any active Perfect Conduit stat modifiers so the saved game
    -- doesn't carry a phantom Fortify on Strength/Speed/Agility that we'd be
    -- unable to clean up after a load (our Lua state resets, but the engine
    -- stat persists).
    clearAllPerfectConduitBuffs('save')
    return {
        classBonusApplied = false,
        classBonusMode = 'dynamic',
    }
end

local function onLoad(data)
    classBonusApplied = (data and data.classBonusApplied) or false
    classBonusMode = (data and data.classBonusMode) or ((classBonusApplied and 'base') or 'none')
    classDynamicModifierRegistered = false
    reconcileClassBonusMode()
    lastSyncedSkill = nil
    lastSyncedPayload = nil
    updateTimer = 0.5
    lastAAMClassBonus = nil
    notifyAAM(true)
    -- Reset perk runtime state — buffs / cooldowns / windows start fresh
    -- on every load. This is intentional: a save in the middle of a perk's
    -- window resumes with a clean slate, which is the safe default for
    -- short-duration effects.
    perfectConduitBuffs       = {}
    arcaneFlowLastProcTime    = -math.huge
    arcaneOverdriveActive     = false
    arcaneOverdriveEndsAt     = 0
    arcaneOverdriveLastTrigger = -math.huge
    lastSyncedOverdrive       = nil
end

-- ─── Console commands ─────────────────────────────────────────────────────

local function onConsoleCommand(mode, command, selectedObject)
    if type(command) ~= 'string' then return end
    -- Match anything starting with "imbuement " (the canonical command word).
    -- The legacy "spellsword " prefix is kept as a silent alias so anyone with
    -- muscle memory from earlier versions of the mod continues to work.
    -- Players can type:
    --   imbuement 10        → add 10 Imbuement levels
    --   imbuement set 75    → set Imbuement to 75
    --   imbuement status    → print current charges / buff / perk states
    --   imbuement overdrive → engage Arcane Overdrive (capstone perk)
    local lower = command:lower():gsub('^%s+', ''):gsub('%s+$', '')
    local prefix
    if lower:match('^imbuement%s') or lower == 'imbuement' then
        prefix = 'imbuement'
    elseif lower:match('^spellsword%s') or lower == 'spellsword' then
        prefix = 'spellsword'   -- legacy alias
    else
        return
    end

    if not (I.SkillFramework and I.SkillFramework.getSkillStat) then
        print('[Imbuement!] Skill Framework not available.')
        return
    end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then
        print('[Imbuement!] Skill not yet registered.')
        return
    end

    local rest = lower:match('^' .. prefix .. '%s+(.*)$') or ''
    local setMatch = rest:match('^set%s+(%-?%d+)$')
    if setMatch then
        stat.base = tonumber(setMatch)
        print(string.format('[Imbuement!] Imbuement skill set to %d.', math.floor(stat.modified)))
        return
    end
    local addMatch = rest:match('^(%-?%d+)$')
    if addMatch then
        stat.base = (stat.base or 0) + tonumber(addMatch)
        print(string.format('[Imbuement!] Imbuement now at %d.', math.floor(stat.modified)))
        return
    end
    if rest == 'overdrive' or rest == 'od' then
        local skill = math.floor(stat.modified)
        local ok, msg = tryStartArcaneOverdrive(skill)
        print('[Imbuement!] ' .. tostring(msg or (ok and 'Overdrive engaged.' or 'Overdrive denied.')))
        if ok then syncOverdriveToGlobal(true) end
        return
    end
    if rest == '' or rest == 'status' or rest == 'perk' or rest == 'perks' then
        local skill = math.floor(stat.modified)
        local charges = chargesAtSkill(skill)
        local buff = elementalBuffAtSkill(skill)
        local pct = activeReductionPercentAtSkill(skill)
        local stacking = spellStackingUnlocked(skill)
        print(string.format(
            '[Imbuement!] level=%d charges=%d elementalBuff=%s drainReduction=%s stacking=%s',
            skill, charges, fmtBuff(buff), fmtPct(pct), tostring(stacking)
        ))
        local nl, nc = chargesAtNextMilestone(skill)
        if nl and nc then
            print(string.format('             next milestone at %d → %d charges', nl, nc))
        else
            print('             charge progression is at its cap.')
        end
        print('             perks:')
        for _, perkId in ipairs(PERK_ORDER) do
            local active = perkActive(perkId, skill)
            local lvl = perkLevel(perkId)
            local label = ({
                lingeringImbue  = 'Lingering Imbue',
                arcaneFlow      = 'Arcane Flow',
                perfectConduit  = 'Perfect Conduit',
                arcaneOverdrive = 'Arcane Overdrive',
            })[perkId] or perkId
            local extra = ''
            if perkId == 'arcaneOverdrive' and active then
                if arcaneOverdriveActive then
                    local left = math.max(0, arcaneOverdriveEndsAt - nowTime())
                    extra = string.format(' [ACTIVE — %.0fs left]', left)
                else
                    local cd = arcaneOverdriveCooldownRemaining()
                    if cd > 0 then extra = string.format(' [cooldown %.0fs]', cd) end
                end
            end
            print(string.format('               [%s] %s (Lvl %d)%s',
                active and 'ON' or 'off', label, lvl, extra))
        end
        return
    end
    print('[Imbuement!] Unknown subcommand. Try: imbuement 10 / imbuement set 75 / imbuement status / imbuement overdrive')
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
        onInit   = onLoad,
        onConsoleCommand = onConsoleCommand,
    },
    eventHandlers = {
        -- Forwarded from global.lua after it validates the imbue spell.
        SpellswordSkill_GrantXp = onGrantXp,

        -- Global forwards charge-spend events here so Arcane Flow (Perk 50)
        -- runs through one common procced-with-cooldown path for both modes.
        SpellswordSkill_ChargeSpent = onChargeSpent,

        -- Global forwards cross-element transitions here so Perfect Conduit
        -- (Perk 75) can apply the appropriate stat buff.
        SpellswordSkill_PerfectConduitTrigger = onPerfectConduitTrigger,

        -- Spellsword sends IW_RemoveMagicka to the PLAYER when Active mode
        -- consumes magicka. Both Spellsword's own handler and ours receive it.
        IW_RemoveMagicka = onRemoveMagickaObserved,
    },
}
