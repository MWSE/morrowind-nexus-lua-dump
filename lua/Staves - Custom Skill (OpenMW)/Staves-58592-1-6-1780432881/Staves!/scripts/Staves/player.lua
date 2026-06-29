--[[
    Staves! — Player Script

    Separates staves (BluntTwoWide) from Blunt Weapon into a custom
    "Staves" skill via Skill Framework.

    Features:
    1) Weapon skill — trains from staff hits, replaces Blunt XP
    2) Spellcasting — while a staff is equipped, magic school skills
       gain a modifier bonus scaling with Staves skill
    3) Spell training — while a staff is equipped, a configurable share of
       successful spellcasting XP is duplicated to Staves
    4) Enchantment efficiency — using enchanted staves costs less charge
    5) Skill books — specific books grant Staves skill

    Four-perk ladder at skill 25 / 50 / 75 / 100.

    Governing attribute: Agility
    Specialization: Magic
    Class bonus: +10 for Magic-specialization classes
]]

local core    = require('openmw.core')
local types   = require('openmw.types')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local ui      = require('openmw.ui')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')

local config  = require('scripts.Staves.config')

local MODNAME = "Staves"
local SKILL_ID = config.skillId
local CLASS_BONUS_AMOUNT = config.classBonus
local SPELL_XP_FEEDBACK_INTERVAL = 2.0

local classDynamicModifierRegistered = false
local legacyClassBonusMigrated = false
local appliedBluntDelta = 0
local bluntNativeSnapshot = nil
local bluntSnapshotBase = nil
local notifyAAM

local settingsSection = storage.playerSection("Settings_" .. MODNAME)
local function getSetting(key, default)
    local val = settingsSection:get(key)
    if val == nil then return default end
    return val
end

local function xpMultiplier()
    return math.max(0, getSetting("xpMultiplier", 100)) * 0.01
end

local function skillDisplayName()
    return getSetting("renameSkillToStaff", false) and "Staff" or "Staves"
end

local function getMigratedToggle(newKey, legacyKeys, default)
    local value = settingsSection:get(newKey)
    if value ~= nil then return value end
    for _, key in ipairs(legacyKeys or {}) do
        value = settingsSection:get(key)
        if value ~= nil then return value end
    end
    return default
end

local function isArcaneSiphonEnabled()
    return getMigratedToggle('arcaneSiphonEnabled', { 'magickaBurnEnabled' }, true)
end

local function isResonantConduitEnabled()
    return getMigratedToggle('resonantConduitEnabled', { 'staffFocusEnabled' }, true)
end

local function isNullPulseEnabled()
    return getMigratedToggle('nullPulseEnabled', { 'spellshockEnabled', 'runebreakEnabled' }, true)
end

local function debugLog(msg)
    if getSetting("debugLogging", false) then
        print("[Staves!] " .. msg)
    end
end

-- ─── Perk feedback overlay / independent shared stack ──────────────────────
-- Each skill mod ships this same small popup manager. A lightweight shared
-- heartbeat elects one active manager when multiple skill mods are installed,
-- but every mod can also run alone with no dependency on the others.

local FEEDBACK_DEFAULT_TEXT_RGB = { 186, 255, 96 }
local FEEDBACK_DEFAULT_SHADOW_RGB = { 130, 43, 41 }
local feedbackDuration = 1.35
local popupBusSection = storage.playerSection('SkillPerkPopupShared')
local POPUP_MANAGER_ID = MODNAME
local POPUP_MANAGER_PRIORITY = 20
local POPUP_KNOWN_MANAGERS = {
    { id = 'Evasion', priority = 10 },
    { id = 'Staves', priority = 20 },
    { id = 'Throwing', priority = 30 },
    { id = 'Toxicology', priority = 40 },
}
local popupRegistryReset = false
local popupManager = {
    stackBaseX = 0.5,
    stackBaseY = 0.72,
    stackAnchorX = 0.5,
    stackAnchorY = 0.5,
    stackSpacing = 0.045,
    stackLimit = 5,
    counter = 0,
    heartbeatTimer = 0,
    entries = {},
}

local function clampSettingNumber(value, default, minValue, maxValue)
    value = tonumber(value) or default
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function getRawSetting(key)
    return settingsSection:get(key)
end

local function getPerkMessageStyle()
    local style = getRawSetting('perkMessageStyle')
    if style ~= nil then
        return clampSettingNumber(style, 1, 0, 2)
    end
    local legacyShow = getRawSetting('showPerkFeedback')
    if legacyShow == false then return 0 end
    if getSetting('useStandardPerkMessages', false) then return 2 end
    return 1
end

local function getPerkPopupDetail()
    local detail = getRawSetting('perkPopupDetail')
    if detail ~= nil then
        return clampSettingNumber(detail, 0, 0, 1)
    end
    if getSetting('detailedPerkFeedback', false) or getSetting('detailedFeedback', false) then return 1 end
    return 0
end

local function shouldSuppressSensoryPopups()
    return getSetting('hideSensoryPerkPopups', false)
end

local function getPopupColor(prefix, defaults)
    if clampSettingNumber(getSetting('popupColourPreset', 0), 0, 0, 1) < 1 then
        return defaults
    end
    return {
        clampSettingNumber(getSetting(prefix .. 'R', defaults[1]), defaults[1], 0, 255),
        clampSettingNumber(getSetting(prefix .. 'G', defaults[2]), defaults[2], 0, 255),
        clampSettingNumber(getSetting(prefix .. 'B', defaults[3]), defaults[3], 0, 255),
    }
end

local function popupLayoutForPosition(position)
    local p = clampSettingNumber(position, 4, 0, 4)
    if p == 0 then return 0.04, 0.18, 0.0, 0.5 end -- top-left
    if p == 1 then return 0.50, 0.18, 0.5, 0.5 end -- top-center
    if p == 2 then return 0.50, 0.50, 0.5, 0.5 end -- center
    if p == 3 then return 0.04, 0.72, 0.0, 0.5 end -- bottom-left
    return 0.50, 0.72, 0.5, 0.5 -- bottom-center
end

local function applyPopupStackSettings(payload)
    payload = payload or {}
    popupManager.stackLimit = clampSettingNumber(payload.maxVisible, 5, 1, 10)
    popupManager.stackBaseX, popupManager.stackBaseY, popupManager.stackAnchorX, popupManager.stackAnchorY = popupLayoutForPosition(payload.popupPosition)
end

local function popupNow()
    local ok, value = pcall(core.getRealTime)
    if ok and tonumber(value) then return tonumber(value) end
    return core.getSimulationTime()
end

local function resetPopupRegistryOnce()
    if popupRegistryReset then return end
    popupRegistryReset = true
    for _, candidate in ipairs(POPUP_KNOWN_MANAGERS) do
        popupBusSection:set('priority_' .. candidate.id, nil)
        popupBusSection:set('heartbeat_' .. candidate.id, nil)
    end
end

local function registerPopupManagerCandidate()
    popupBusSection:set('priority_' .. POPUP_MANAGER_ID, POPUP_MANAGER_PRIORITY)
    popupBusSection:set('heartbeat_' .. POPUP_MANAGER_ID, popupNow())
end

local function electedPopupManagerId()
    registerPopupManagerCandidate()
    local now = popupNow()
    local bestId = POPUP_MANAGER_ID
    local bestPriority = POPUP_MANAGER_PRIORITY
    for _, candidate in ipairs(POPUP_KNOWN_MANAGERS) do
        local heartbeat = tonumber(popupBusSection:get('heartbeat_' .. candidate.id))
        local priority = tonumber(popupBusSection:get('priority_' .. candidate.id)) or candidate.priority
        if heartbeat and heartbeat <= now + 0.25 and now - heartbeat <= 5 then
            if not bestPriority or priority < bestPriority then
                bestId = candidate.id
                bestPriority = priority
            end
        end
    end
    return bestId
end

local function showStandardFeedbackMessage(msg)
    local ok = pcall(ui.showMessage, msg, { showInDialogue = false })
    if not ok then
        pcall(ui.showMessage, msg)
    end
end

local function popupRgb(r, g, b, defaults)
    defaults = defaults or { 255, 255, 255 }
    return util.color.rgb(
        clampSettingNumber(r, defaults[1], 0, 255) / 255,
        clampSettingNumber(g, defaults[2], 0, 255) / 255,
        clampSettingNumber(b, defaults[3], 0, 255) / 255
    )
end

local function perkPopupPayload(msg)
    local textRgb = getPopupColor('perkMessageText', FEEDBACK_DEFAULT_TEXT_RGB)
    local shadowRgb = getPopupColor('perkMessageShadow', FEEDBACK_DEFAULT_SHADOW_RGB)
    return {
        source = MODNAME,
        text = tostring(msg or ''),
        textR = textRgb[1],
        textG = textRgb[2],
        textB = textRgb[3],
        shadowR = shadowRgb[1],
        shadowG = shadowRgb[2],
        shadowB = shadowRgb[3],
        defaultTextRgb = FEEDBACK_DEFAULT_TEXT_RGB,
        defaultShadowRgb = FEEDBACK_DEFAULT_SHADOW_RGB,
        textSize = 20,
        duration = clampSettingNumber(getSetting('popupDuration', feedbackDuration), feedbackDuration, 0.5, 10),
        popupPosition = clampSettingNumber(getSetting('popupPosition', 4), 4, 0, 4),
        maxVisible = clampSettingNumber(getSetting('popupMaxVisible', 5), 5, 1, 10),
    }
end

local function destroyPopupEntry(index)
    local entry = popupManager.entries[index]
    if entry and entry.element then
        entry.element:destroy()
    end
    table.remove(popupManager.entries, index)
end

local function reflowPopupStack()
    local now = core.getSimulationTime()
    for i = #popupManager.entries, 1, -1 do
        local entry = popupManager.entries[i]
        if not entry or not entry.element or (entry.expiresAt and entry.expiresAt <= now) then
            destroyPopupEntry(i)
        end
    end
    while #popupManager.entries > popupManager.stackLimit do
        destroyPopupEntry(#popupManager.entries)
    end
    for i, entry in ipairs(popupManager.entries) do
        entry.element.layout.props.relativePosition = util.vector2(popupManager.stackBaseX, popupManager.stackBaseY + (i - 1) * popupManager.stackSpacing)
        entry.element.layout.props.anchor = util.vector2(popupManager.stackAnchorX, popupManager.stackAnchorY)
        entry.element.layout.props.visible = true
        entry.element:update()
    end
end

local function showCustomPopup(payload)
    if type(payload) ~= 'table' then return end
    local text = tostring(payload.text or '')
    if text == '' then return end

    applyPopupStackSettings(payload)
    reflowPopupStack()
    popupManager.counter = popupManager.counter + 1

    local defaultText = type(payload.defaultTextRgb) == 'table' and payload.defaultTextRgb or FEEDBACK_DEFAULT_TEXT_RGB
    local defaultShadow = type(payload.defaultShadowRgb) == 'table' and payload.defaultShadowRgb or FEEDBACK_DEFAULT_SHADOW_RGB
    local textColor = popupRgb(payload.textR, payload.textG, payload.textB, defaultText)
    local shadowColor = popupRgb(payload.shadowR, payload.shadowG, payload.shadowB, defaultShadow)
    local textSize = clampSettingNumber(payload.textSize, 20, 10, 72)
    local duration = clampSettingNumber(payload.duration, feedbackDuration, 0.5, 10)

    local element = ui.create({
        layer = 'Notification',
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(popupManager.stackBaseX, popupManager.stackBaseY),
            anchor = util.vector2(popupManager.stackAnchorX, popupManager.stackAnchorY),
            text = text,
            textSize = textSize,
            textColor = textColor,
            textShadow = true,
            textShadowColor = shadowColor,
            visible = true,
        },
    })

    table.insert(popupManager.entries, 1, {
        element = element,
        expiresAt = core.getSimulationTime() + duration,
    })
    reflowPopupStack()
end

local function onSkillPerkPopupShow(payload)
    registerPopupManagerCandidate()
    if electedPopupManagerId() == POPUP_MANAGER_ID then
        showCustomPopup(payload)
    end
end

local function emitSkillPerkPopup(payload)
    registerPopupManagerCandidate()
    if electedPopupManagerId() == POPUP_MANAGER_ID then
        showCustomPopup(payload)
        return
    end
    if self.object and self.object.sendEvent then
        self.object:sendEvent('SkillPerkPopup_Show', payload)
    end
end

local function updatePopupManager(dt)
    popupManager.heartbeatTimer = (popupManager.heartbeatTimer or 0) + (tonumber(dt) or 0)
    if popupManager.heartbeatTimer >= 0.5 then
        popupManager.heartbeatTimer = 0
        registerPopupManagerCandidate()
    end
    reflowPopupStack()
end

local function showPerkFeedback(msg)
    local style = getPerkMessageStyle()
    if style <= 0 then return end

    local text = tostring(msg or '')
    if style == 2 then
        showStandardFeedbackMessage(text)
        return
    end

    emitSkillPerkPopup(perkPopupPayload(text))
end

local function showFeedback(msg)
    if getSetting("showFeedback", false) then
        showStandardFeedbackMessage(tostring(msg or ''))
    end
end

-- ─── Math helpers ───────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

local function skillT(skill, unlock)
    return clamp((skill - unlock) / math.max(1, 100 - unlock), 0, 1)
end

local function percent(v) return string.format("%.0f%%", (v or 0) * 100) end

-- ─── Skill Registration ─────────────────────────────────────────────────────

local hasSkillFramework = false

local function skillIsRegistered()
    return I.SkillFramework and I.SkillFramework.getSkillRecord
        and I.SkillFramework.getSkillRecord(SKILL_ID) ~= nil
end

local function tryRegisterSkill()
    if not I.SkillFramework then
        debugLog("Skill Framework not found")
        return
    end
    hasSkillFramework = true
    if skillIsRegistered() then return end

    I.SkillFramework.registerSkill(SKILL_ID, {
        name = skillDisplayName(),
        description = "Governs your effectiveness with staves as weapons and enhances spellcasting while a staff is equipped.",
        attribute = "agility",
        specialization = I.SkillFramework.SPECIALIZATION.Magic,
        startLevel = config.startLevel,
        maxLevel = config.maxLevel,
        skillGain = {
            hit = 1.5,
        },
        statsWindowProps = {
            subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Magic,
            visible = true,
        },
        icon = {
            bgr = 'icons/SkillFramework/magic_blank.dds',
            fgr = 'icons/Staves/staves.dds',
            bgrColor = util.color.rgb(1, 1, 1),
            fgrColor = util.color.rgb(0.95, 0.95, 0.95),
        },
    })

    -- Race modifiers
    I.SkillFramework.registerRaceModifier(SKILL_ID, "breton", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "argonian", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "high elf", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "dark elf", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "orc", 5)

    -- Tamriel Data races
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Bm_Naga", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Cyr_Ayleid", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Dagi-raht", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Sky_Reachman", 5)

    -- Skill books
    I.SkillFramework.registerSkillBook("bk_biographybarenziah3", SKILL_ID)
    I.SkillFramework.registerSkillBook("bk_fellowshiptemple", SKILL_ID)

    debugLog("Staves skill registered (governed by Agility)")
end

tryRegisterSkill()

-- ─── Magic Class Bonus (+10 native base) ──────────────────────────────

local classBonusState = {
    applied = false,
    classId = nil,
    amount = 0,
    mode = "base",
    cachedClassId = nil,
    cachedSpecialization = nil,
}

local CLASS_SPECIALIZATION_SKILLS = {
    combat = {
        'block', 'armorer', 'mediumarmor', 'heavyarmor', 'bluntweapon', 'longblade', 'axe', 'spear', 'athletics',
    },
    magic = {
        'enchant', 'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration', 'alchemy', 'unarmored',
    },
    stealth = {
        'security', 'sneak', 'acrobatics', 'lightarmor', 'shortblade', 'marksman', 'mercantile', 'speechcraft', 'handtohand',
    },
}
local CLASS_SPECIALIZATION_ORDER = { 'combat', 'magic', 'stealth' }

local function normalizeSpecialization(value)
    if value == nil then return nil end
    local text = string.lower(tostring(value))
    if text == 'combat' or text == 'magic' or text == 'stealth' then return text end
    return nil
end

local function getClassRecordById(classId)
    if classId == nil then return nil end
    local id = tostring(classId)
    if id == '' then return nil end

    local ok, record
    if types.NPC and types.NPC.classes and types.NPC.classes.record then
        ok, record = pcall(function() return types.NPC.classes.record(id) end)
        if ok and record then return record end
        ok, record = pcall(function() return types.NPC.classes.record(string.lower(id)) end)
        if ok and record then return record end
    end

    if types.NPC and types.NPC.classes and types.NPC.classes.records then
        ok, record = pcall(function()
            return types.NPC.classes.records[id] or types.NPC.classes.records[string.lower(id)]
        end)
        if ok and record then return record end

        ok, record = pcall(function()
            local wanted = string.lower(id)
            for _, candidate in pairs(types.NPC.classes.records) do
                if candidate then
                    local cid = candidate.id and string.lower(tostring(candidate.id)) or nil
                    local cname = candidate.name and string.lower(tostring(candidate.name)) or nil
                    if cid == wanted or cname == wanted then return candidate end
                end
            end
            return nil
        end)
        if ok and record then return record end
    end

    return nil
end

local function getPlayerClassRecord()
    local ok, record = pcall(function() return types.NPC.record(self) end)
    if not (ok and record and record.class) then return nil, nil end
    return record.class, getClassRecordById(record.class)
end

local function getPlayerRaceRecord()
    local ok, record = pcall(function() return types.NPC.record(self) end)
    if not (ok and record and record.race) then return nil end

    local raceId = tostring(record.race)
    if types.NPC and types.NPC.races and types.NPC.races.record then
        local raceOk, raceRecord = pcall(function() return types.NPC.races.record(raceId) end)
        if raceOk and raceRecord then return raceRecord end
        raceOk, raceRecord = pcall(function() return types.NPC.races.record(string.lower(raceId)) end)
        if raceOk and raceRecord then return raceRecord end
    end

    if types.NPC and types.NPC.races and types.NPC.races.records then
        local raceOk, raceRecord = pcall(function()
            return types.NPC.races.records[raceId] or types.NPC.races.records[string.lower(raceId)]
        end)
        if raceOk and raceRecord then return raceRecord end
    end

    return nil
end

local function getRaceSkillBonus(raceRecord, skillId)
    if not raceRecord or not raceRecord.skills then return 0 end
    local ok, value = pcall(function()
        return raceRecord.skills[skillId] or raceRecord.skills[string.lower(skillId)]
    end)
    if ok then return tonumber(value) or 0 end
    return 0
end

local function getVanillaSkillBase(skillId)
    if not (types.NPC and types.NPC.stats and types.NPC.stats.skills) then return nil end
    local getter = types.NPC.stats.skills[skillId]
    if type(getter) ~= 'function' then return nil end

    local ok, stat = pcall(function() return getter(self) end)
    if not (ok and stat) then return nil end
    return tonumber(stat.base or stat.modified)
end

local function medianValue(values)
    table.sort(values)
    local count = #values
    if count == 0 then return nil end
    local mid = math.floor((count + 1) / 2)
    if count % 2 == 1 then return values[mid] end
    return (values[mid] + values[mid + 1]) * 0.5
end

local function inferClassSpecializationFromVanillaSkills()
    if classBonusState.cachedSpecialization then return classBonusState.cachedSpecialization end
    if types.Player and types.Player.isCharGenFinished and not types.Player.isCharGenFinished(self) then return nil end

    local raceRecord = getPlayerRaceRecord()
    local bestSpec = nil
    local bestScore = nil
    local secondScore = nil
    local bestMin = nil
    local bestMedian = nil

    for _, spec in ipairs(CLASS_SPECIALIZATION_ORDER) do
        local residuals = {}
        for _, skillId in ipairs(CLASS_SPECIALIZATION_SKILLS[spec]) do
            local base = getVanillaSkillBase(skillId)
            if base then
                residuals[#residuals + 1] = base - 5 - getRaceSkillBonus(raceRecord, skillId)
            end
        end

        if #residuals >= 7 then
            table.sort(residuals)
            local minResidual = residuals[1]
            local medianResidual = medianValue(residuals) or 0
            local score = (minResidual * 4) + medianResidual
            if not bestScore or score > bestScore then
                secondScore = bestScore
                bestScore = score
                bestSpec = spec
                bestMin = minResidual
                bestMedian = medianResidual
            elseif not secondScore or score > secondScore then
                secondScore = score
            end
        end
    end

    if bestSpec and bestMin and bestMedian and bestMin >= 4 and bestMedian >= 4
        and (not secondScore or (bestScore - secondScore) >= 3) then
        classBonusState.cachedSpecialization = bestSpec
        return classBonusState.cachedSpecialization
    end

    return nil
end

local function getPlayerClassSpecialization()
    local classId, classRecord = getPlayerClassRecord()
    local classIdText = classId and tostring(classId) or ''
    if classBonusState.cachedClassId ~= classIdText then
        classBonusState.cachedClassId = classIdText
        classBonusState.cachedSpecialization = nil
    end

    local directSpecialization = normalizeSpecialization(classRecord and classRecord.specialization)
    if directSpecialization then
        classBonusState.cachedSpecialization = directSpecialization
        return directSpecialization
    end

    return inferClassSpecializationFromVanillaSkills()
end

local function getClassSpecializationBonus()
    -- Ultimate Leveling handles Skill Framework custom-skill starting specialization bonuses itself.
    if core.contentFiles.has('UltimateLeveling.omwaddon') then return 0 end
    if getPlayerClassSpecialization() == 'magic' then
        return CLASS_BONUS_AMOUNT
    end
    return 0
end

local function removeSavedModifierClassBonus(stat, amount)
    amount = tonumber(amount) or 0
    if classBonusState.mode ~= 'modifier' then return amount end
    if amount ~= 0 then
        stat.modifier = (tonumber(stat.modifier) or 0) - amount
    end
    return 0
end

local function reconcileClassBonus()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat and skillIsRegistered()) then return end
    if types.Player and types.Player.isCharGenFinished and not types.Player.isCharGenFinished(self) then return end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return end

    local desired = getClassSpecializationBonus()
    local current = tonumber(classBonusState.amount) or 0
    current = removeSavedModifierClassBonus(stat, current)

    if desired ~= current then
        stat.base = math.max(0, math.min(config.maxLevel, (tonumber(stat.base) or 0) - current + desired))
        classBonusState.amount = desired
    end

    local classId = getPlayerClassRecord()
    classBonusState.classId = classId
    classBonusState.applied = desired ~= 0
    classBonusState.mode = 'base'
end

-- ─── Staff Detection ────────────────────────────────────────────────────────

-- GRIP converts two-handed staves into generated one-handed records. Depending
-- on timing and OpenMW's dynamic record ID normalization, the equipped object's
-- recordId is not always the same string GRIP stored in its maps. Resolve using
-- both object.recordId and Weapon.record(...).id, plus lower-case variants, then
-- fall back to GRIP's own visible convention: generated staff variants are named
-- from the original staff and suffixed with " (1H)" / " (2H)".
local gripRecordsSection = storage.globalSection('GRIPRecords')

local function addIdCandidate(ids, seen, recordId)
    if recordId == nil then return end
    recordId = tostring(recordId)
    if recordId == '' then return end
    if not seen[recordId] then
        seen[recordId] = true
        ids[#ids + 1] = recordId
    end
    local lower = string.lower(recordId)
    if lower ~= recordId and not seen[lower] then
        seen[lower] = true
        ids[#ids + 1] = lower
    end
end

local function weaponIdCandidates(weapon, record)
    local ids, seen = {}, {}
    addIdCandidate(ids, seen, record and record.id)
    addIdCandidate(ids, seen, weapon and weapon.recordId)
    return ids
end

local function weaponRecordById(recordId)
    if not recordId then return nil end
    local ok, record = pcall(function() return types.Weapon.records[recordId] end)
    if ok then return record end
    return nil
end

local function firstMapValue(map, ids)
    if type(map) ~= 'table' then return nil end
    for _, recordId in ipairs(ids or {}) do
        local value = map[recordId]
        if value ~= nil then return value end
    end
    return nil
end

local function gripOriginalRecordFor(ids)
    if type(ids) ~= 'table' then return nil end

    -- GRIP may temporarily equip a sheath-marker record. Resolve that back to
    -- the normal GRIP replacement first, then resolve replacement -> original.
    local sheathToNormal = gripRecordsSection:get('SheathToNormal')
    local normalId = firstMapValue(sheathToNormal, ids)
    if normalId then
        local normalRecord = weaponRecordById(normalId)
        addIdCandidate(ids, {}, normalId)
        if normalRecord then addIdCandidate(ids, {}, normalRecord.id) end
    end

    local newToOld = gripRecordsSection:get('NewToOldRecords')
    local originalId = firstMapValue(newToOld, ids)
    return weaponRecordById(originalId)
end

local function recordNameLooksLikeGripStaff(record)
    if not record then return false end
    local name = string.lower(tostring(record.name or ''))
    local id = string.lower(tostring(record.id or ''))
    local hasStaffName = name:find('staff', 1, true) ~= nil or id:find('staff', 1, true) ~= nil
    if not hasStaffName then return false end

    -- GRIP appends these suffixes to generated variants. This avoids treating
    -- every arbitrary one-handed blunt weapon with "staff" somewhere in an ID as
    -- a Staves weapon unless it is visibly a GRIP variant.
    return name:find('%(1h%)') ~= nil or name:find('%(2h%)') ~= nil
        or id:find('%(1h%)') ~= nil or id:find('%(2h%)') ~= nil
        or id:find('1h', 1, true) ~= nil or id:find('2h', 1, true) ~= nil
end

local function isStaffRecord(record)
    if not record then return false end
    return record.type == types.Weapon.TYPE.BluntTwoWide
        or recordNameLooksLikeGripStaff(record)
end

local function isStaffWeapon(weapon)
    if not weapon or not types.Weapon.objectIsInstance(weapon) then return false end

    local ok, record = pcall(types.Weapon.record, weapon)
    if not ok or not record then return false end

    if isStaffRecord(record) then return true end

    local original = gripOriginalRecordFor(weaponIdCandidates(weapon, record))
    return isStaffRecord(original)
end

local function getEquippedStaff()
    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if isStaffWeapon(weapon) then return weapon end
    return nil
end

local function isStaffEquipped()
    return getEquippedStaff() ~= nil
end

local function getStavesSkillLevel()
    if hasSkillFramework and skillIsRegistered() then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then return stat.modified end
    end
    return config.startLevel
end

local function getBluntStat()
    return types.NPC.stats.skills.bluntweapon(self)
end

local function statNumber(value)
    return tonumber(value) or 0
end

local function applyStatTarget(stat, target)
    if not stat then return false end
    local current = statNumber(stat.modified)
    local diff = statNumber(target) - current
    if math.abs(diff) <= 0.0001 then return false end
    stat.modifier = statNumber(stat.modifier) + diff
    return true
end

local function applyStatModifierDelta(stat, delta)
    if not stat then return false end
    delta = statNumber(delta)
    if math.abs(delta) <= 0.0001 then return false end
    stat.modifier = statNumber(stat.modifier) + delta
    return true
end

local function updateBluntSnapshot(stat)
    if not stat then return end

    local base = statNumber(stat.base)
    if bluntNativeSnapshot == nil then
        -- If this is an old save with an already-applied delta but no snapshot,
        -- reconstruct the native value from the current stat and saved delta.
        bluntNativeSnapshot = statNumber(stat.modified) - statNumber(appliedBluntDelta)
        bluntSnapshotBase = base
        return
    end

    if bluntSnapshotBase ~= nil and base ~= bluntSnapshotBase then
        -- Preserve legitimate base-level changes that happen while the override
        -- is active, without treating Restore Skill effects as native growth.
        bluntNativeSnapshot = statNumber(bluntNativeSnapshot) + (base - bluntSnapshotBase)
    end
    bluntSnapshotBase = base
end

local function restoreBluntSnapshot(stat)
    if not stat then return false end

    local changed = false
    if bluntNativeSnapshot ~= nil then
        updateBluntSnapshot(stat)
        changed = applyStatTarget(stat, bluntNativeSnapshot) or changed
    elseif appliedBluntDelta ~= 0 then
        -- Fallback for pre-fix saves that had a delta but no native snapshot.
        changed = applyStatTarget(stat, statNumber(stat.modified) - statNumber(appliedBluntDelta)) or changed
    end

    if appliedBluntDelta ~= 0 then changed = true end
    appliedBluntDelta = 0
    bluntNativeSnapshot = nil
    bluntSnapshotBase = nil
    return changed
end

local function applyBluntOverride()
    local stat = getBluntStat()
    if not stat then return end

    local shouldReplace = getSetting("enabled", true)
        and getSetting("replaceBlunt", true)
        and isStaffEquipped()

    local changed = false
    if shouldReplace then
        -- Staff hit chance is still calculated by the engine's Blunt Weapon stat,
        -- so while a staff is equipped we temporarily offset Blunt to equal Staves.
        -- This can be positive or negative: staff attacks should use Staves only,
        -- never whichever of Staves/Blunt happens to be higher.
        --
        -- The native Blunt value is snapshotted and the stat is set to an exact
        -- target each tick. This prevents Restore Skill effects or growth mods
        -- from "repairing" our temporary negative modifier and making the
        -- bookkeeping drift into permanent Blunt bonuses.
        updateBluntSnapshot(stat)
        local nativeBlunt = statNumber(bluntNativeSnapshot)
        local desiredDelta = getStavesSkillLevel() - nativeBlunt
        local target = nativeBlunt + desiredDelta
        changed = applyStatTarget(stat, target) or changed
        if desiredDelta ~= appliedBluntDelta then changed = true end
        appliedBluntDelta = desiredDelta
    else
        changed = restoreBluntSnapshot(stat) or changed
    end

    if changed then notifyAAM() end
end

-- ─── Blunt XP Redirect & Spell XP Duplication ──────────────────────────────────

local MAGIC_SCHOOLS_LOOKUP = {
    destruction = true, alteration = true, illusion = true,
    conjuration = true, mysticism = true, restoration = true,
}

local pendingSpellXpFeedback = 0
local pendingSpellXpFeedbackTimer = 0

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if not getSetting("enabled", true) then return end
    if not hasSkillFramework or not skillIsRegistered() then return end

    if skillId == "bluntweapon"
        and getSetting("redirectXP", true)
        and params.useType == I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit
        and isStaffEquipped()
    then
        I.SkillFramework.skillUsed(SKILL_ID, {
            useType = "hit",
            skillGain = 1.5 * xpMultiplier(),
            redirectedFrom = skillId,
        })
        debugLog("Redirected blunt XP to Staves skill")
        return false
    end

    if MAGIC_SCHOOLS_LOOKUP[skillId]
        and params.useType == I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success
        and isStaffEquipped()
    then
        local sharePercent = getSetting("spellXpShare", 25)
        local sourceGain = tonumber(params.skillGain)
        if not sourceGain or sourceGain <= 0 then sourceGain = 1 end
        local duplicatedGain = sourceGain * (sharePercent / 100) * xpMultiplier()

        if duplicatedGain > 0 then
            I.SkillFramework.skillUsed(SKILL_ID, {
                skillGain = duplicatedGain,
                useType = "hit",
                sourceSkill = skillId,
                duplicatedFromSpell = true,
            })
            pendingSpellXpFeedback = pendingSpellXpFeedback + duplicatedGain
            pendingSpellXpFeedbackTimer = SPELL_XP_FEEDBACK_INTERVAL
        end
    end
end)

-- ─── Spellcasting Bonus via stat.modifier ──────────────────────────────────────

local MAGIC_SCHOOLS = {
    "destruction", "alteration", "illusion",
    "conjuration", "mysticism", "restoration",
}

local appliedBonuses = {}
local schoolStats = {}
local spellNativeSnapshots = {}
local spellSnapshotBases = {}
for _, school in ipairs(MAGIC_SCHOOLS) do
    appliedBonuses[school] = 0
    schoolStats[school] = types.NPC.stats.skills[school](self)
end

function notifyAAM()
    if not (I and I.AAM and I.AAM.reportExternalModifiers) then return end

    local report = {}
    for _, school in ipairs(MAGIC_SCHOOLS) do
        local amount = tonumber(appliedBonuses[school]) or 0
        if amount ~= 0 then
            report[school] = amount
        end
    end
    if appliedBluntDelta ~= 0 then
        report.bluntweapon = appliedBluntDelta
    end

    I.AAM.reportExternalModifiers(MODNAME, next(report) and report or {})
end

-- Magic-school bonuses are positive Fortify-style deltas.  Keep these as a
-- ledgered modifier delta instead of forcing each skill to an exact target.
-- Exact target restoration is necessary for the Blunt hit-chance override
-- because it may apply a negative modifier that Restore Skill can repair.
-- For magic schools, a ledger is safer: it preserves external Fortify Skill
-- effects from equipment/spells, including Fortify effects on the staff that
-- is being equipped or unequipped.
local function updateSpellSnapshot(school, stat)
    -- Retained as a compatibility no-op for saves created by the previous
    -- restore-safe build. New magic-school handling no longer snapshots the
    -- native value because item Fortify Skill effects legitimately alter the
    -- native value while a staff is equipped.
    if not stat then return end
    if spellNativeSnapshots[school] ~= nil then
        spellNativeSnapshots[school] = nil
        spellSnapshotBases[school] = nil
    end
end

local function restoreSpellSnapshot(school, stat)
    if not stat then
        appliedBonuses[school] = 0
        spellNativeSnapshots[school] = nil
        spellSnapshotBases[school] = nil
        return false
    end

    local currentBonus = statNumber(appliedBonuses[school])
    local changed = false
    if currentBonus ~= 0 then
        changed = applyStatModifierDelta(stat, -currentBonus) or changed
    end

    appliedBonuses[school] = 0
    spellNativeSnapshots[school] = nil
    spellSnapshotBases[school] = nil
    return changed
end

local function applySpellBonus()
    local maxBonus = getSetting("spellBonus", 25)
    local enabled = getSetting("enabled", true)
    local staffEquipped = enabled and isStaffEquipped()
    local skill = getStavesSkillLevel()

    local targetBonus = 0
    if staffEquipped then
        targetBonus = math.floor(skill * maxBonus / 100)
    end

    local changed = false
    for _, school in ipairs(MAGIC_SCHOOLS) do
        local stat = schoolStats[school]
        local currentBonus = statNumber(appliedBonuses[school])
        if staffEquipped then
            local delta = targetBonus - currentBonus
            if stat then
                changed = applyStatModifierDelta(stat, delta) or changed
            end
            if currentBonus ~= targetBonus then changed = true end
            appliedBonuses[school] = targetBonus
            spellNativeSnapshots[school] = nil
            spellSnapshotBases[school] = nil
        else
            changed = restoreSpellSnapshot(school, stat) or changed
        end
    end

    if changed then notifyAAM() end
    return targetBonus
end

local function clearTrackedModifiers()
    local changed = false
    changed = restoreBluntSnapshot(getBluntStat()) or changed
    for _, school in ipairs(MAGIC_SCHOOLS) do
        changed = restoreSpellSnapshot(school, schoolStats[school]) or changed
    end
    if changed then notifyAAM() end
    return changed
end

local function setBluntModifiedValue(target)
    local stat = getBluntStat()
    if not stat then return false end
    stat.modifier = statNumber(target) - statNumber(stat.base)
    appliedBluntDelta = 0
    bluntNativeSnapshot = nil
    bluntSnapshotBase = nil
    notifyAAM()
    return true
end

local MAGIC_SCHOOL_NAMES = {
    alteration = 'Alteration',
    conjuration = 'Conjuration',
    destruction = 'Destruction',
    illusion = 'Illusion',
    mysticism = 'Mysticism',
    restoration = 'Restoration',
}

local function setMagicSchoolModifiedValue(school, target)
    school = string.lower(tostring(school or ''))
    if not MAGIC_SCHOOL_NAMES[school] then return false, nil end

    local stat = schoolStats[school]
    if not stat then return false, MAGIC_SCHOOL_NAMES[school] end

    stat.modifier = statNumber(target) - statNumber(stat.base)
    appliedBonuses[school] = 0
    spellNativeSnapshots[school] = nil
    spellSnapshotBases[school] = nil
    notifyAAM()
    return true, MAGIC_SCHOOL_NAMES[school]
end

-- ─── Enchantment Charge Efficiency ─────────────────────────────────────────────

local lastStaffCharge = nil
local lastStaffId = nil

local function getItemEnchantmentCharge(idata)
    if not idata then return nil end
    if idata.enchantmentCharge ~= nil then return idata.enchantmentCharge end
    return idata.charge
end

local function requestItemEnchantmentCharge(item, value)
    if not item or value == nil then return end
    -- ItemData can be read here, but OpenMW only permits mutation from
    -- global scripts or scripts attached to the item itself. Route the write
    -- through the global script to avoid local/player-script ownership errors.
    core.sendGlobalEvent('Staves_SetItemEnchantmentCharge', {
        item = item,
        value = tonumber(value),
    })
end

local function getWeaponMaxCharge(record)
    if not record or not record.enchant or record.enchant == '' then return 0 end

    local enchant = core.magic.enchantments.records[record.enchant]
    if enchant and enchant.charge then return tonumber(enchant.charge) or 0 end

    return tonumber(record.enchantCapacity) or tonumber(record.charge) or 0
end

local function checkEnchantEfficiency()
    if not getSetting("enabled", true) then return end
    if not getSetting("enchantSaving", true) then return end

    local staff = getEquippedStaff()
    if not staff then
        lastStaffCharge = nil
        lastStaffId = nil
        return
    end

    local record = types.Weapon.record(staff)
    if not record.enchant or record.enchant == "" then
        lastStaffCharge = nil
        lastStaffId = nil
        return
    end

    local idata = types.Item.itemData(staff)
    if not idata then
        lastStaffCharge = nil
        lastStaffId = nil
        return
    end

    local currentCharge = getItemEnchantmentCharge(idata)
    local staffId = staff.recordId

    if staffId == lastStaffId and lastStaffCharge and currentCharge then
        local chargeUsed = lastStaffCharge - currentCharge
        if chargeUsed > 0 then
            local skill = getStavesSkillLevel()
            local maxChance = getSetting("maxSaveChance", 50)
            local chance = skill * maxChance / 100
            local roll = math.random(1, 100)
            if roll <= chance then
                requestItemEnchantmentCharge(staff, lastStaffCharge)
                currentCharge = lastStaffCharge
                showFeedback(skillDisplayName() .. ": enchant charge saved")
            end
        end
    end

    lastStaffCharge = currentCharge
    lastStaffId = staffId
end

-- ─── Perk scaling ───────────────────────────────────────────────────────────

local function concussiveChance()
    return config.perks.concussive.chance or 0
end

local function concussiveFatigue(skill)
    local p = config.perks.concussive
    return lerp(p.fatigueAtUnlock, p.fatigueAt100, skillT(skill, p.level))
end

local function arcaneSiphonChance()
    return config.perks.arcaneSiphon.chance or 0
end

local function arcaneSiphonAmount(skill)
    local p = config.perks.arcaneSiphon
    return lerp(p.drainAtUnlock, p.drainAt100, skillT(skill, p.level))
end

local function resonantConduitChance()
    return config.perks.resonantConduit.chance or 0
end

local function resonantConduitCharge(skill)
    local p = config.perks.resonantConduit
    return lerp(p.chargeAtUnlock, p.chargeAt100, skillT(skill, p.level))
end

local function nullPulseChance()
    return config.perks.nullPulse.chance or 0
end

local function nullPulseDuration()
    return config.perks.nullPulse.silenceDuration or 0
end

local function stavesPerkEnabled(perkId)
    if not getSetting('perksEnabled', true) then return false end
    if perkId == 'concussive' then return getSetting('concussiveEnabled', true) end
    if perkId == 'arcaneSiphon' then return isArcaneSiphonEnabled() end
    if perkId == 'resonantConduit' then return isResonantConduitEnabled() end
    if perkId == 'nullPulse' then return isNullPulseEnabled() end
    return true
end

-- ─── Pending-hit sync (the Throwing! pattern) ───────────────────────────────
-- When the player has a staff equipped and is attacking, we push a "pending
-- staff swing" record into a Runtime_Staves global storage section so the
-- NPC's onHit actor script can apply perk procs. Staves are melee so we
-- don't need animation keys — we just keep state current whenever a staff
-- is equipped. The actor reads: staff recordId, current skill, perk enables.

local lastRuntimeState = nil

local function runtimeStateChanged(state)
    if not lastRuntimeState then return true end
    for k, v in pairs(state) do
        if lastRuntimeState[k] ~= v then return true end
    end
    for k, _ in pairs(lastRuntimeState) do
        if state[k] == nil then return true end
    end
    return false
end

local function syncRuntimeState(force)
    local staff = getEquippedStaff()
    local skill = getStavesSkillLevel()
    local state = {
        active = staff ~= nil and getSetting("enabled", true),
        staffRecordId = staff and staff.recordId or nil,
        skill = skill,

        -- Tuned values so the actor script does not have to re-import config
        concussiveEnabled = stavesPerkEnabled("concussive"),
        concussiveChance = concussiveChance(),
        concussiveFatigue = concussiveFatigue(skill),
        concussiveLevel = config.perks.concussive.level,
        concussiveSound = config.perks.concussive.sound,

        arcaneSiphonEnabled = stavesPerkEnabled("arcaneSiphon"),
        arcaneSiphonChance = arcaneSiphonChance(),
        arcaneSiphonAmount = arcaneSiphonAmount(skill),
        arcaneSiphonLevel = config.perks.arcaneSiphon.level,
        arcaneSiphonSound = config.perks.arcaneSiphon.sound,

        resonantConduitEnabled = stavesPerkEnabled("resonantConduit"),
        resonantConduitChance = resonantConduitChance(),
        resonantConduitCharge = resonantConduitCharge(skill),
        resonantConduitLevel = config.perks.resonantConduit.level,

        nullPulseEnabled = stavesPerkEnabled("nullPulse"),
        nullPulseChance = nullPulseChance(),
        nullPulseDuration = nullPulseDuration(),
        nullPulseLevel = config.perks.nullPulse.level,
        nullPulseSound = config.perks.nullPulse.sound,
    }

    if not force and not runtimeStateChanged(state) then return end
    core.sendGlobalEvent("Staves_UpdateRuntime", state)
    lastRuntimeState = state
end

-- ─── Hit feedback from actor script ─────────────────────────────────────────
-- The NPC-side script sends us a Staves_ResolvedHit event after each hit
-- with details of which perks fired, so we can show on-screen feedback
-- and handle staff-side effects (like restoring enchant charge).

local function restorePlayerMagicka(amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return 0 end
    local magicka = types.Actor.stats.dynamic.magicka(self)
    if not magicka then return 0 end

    local current = tonumber(magicka.current) or 0
    local maxMagicka = math.max(0, (tonumber(magicka.base) or 0) + (tonumber(magicka.modifier) or 0))
    local restored = math.min(amount, math.max(0, maxMagicka - current))
    if restored > 0 then
        magicka.current = current + restored
    end
    return restored
end

local function playPlayerSound(sound)
    if not sound or sound == '' then return end
    pcall(function() core.sound.playSound3d(sound, self) end)
end

local function onResolvedHit(data)
    if not data then return end

    local perkMessages = {}
    local hideSensory = shouldSuppressSensoryPopups()
    local detailed = getPerkPopupDetail() >= 1
    local function addPerkMessage(text, hasSensoryCue)
        if hasSensoryCue and hideSensory then return end
        table.insert(perkMessages, text)
    end
    if data.procConcussive then
        if detailed then
            addPerkMessage(string.format("%s (%.0f fatigue)",
                config.feedback.concussive, data.concussiveFatigue or 0), true)
        else
            addPerkMessage(config.feedback.concussive, true)
        end
    end

    if data.procArcaneSiphon then
        local drained = tonumber(data.arcaneSiphonAmount) or 0
        local restored = restorePlayerMagicka(drained * (config.perks.arcaneSiphon.restoreMultiplier or 1.0))
        if detailed then
            if restored > 0 then
                addPerkMessage(string.format("%s (-%.0f target magicka, +%.0f magicka)",
                    config.feedback.arcaneSiphon, drained, restored), true)
            else
                addPerkMessage(string.format("%s (-%.0f target magicka)",
                    config.feedback.arcaneSiphon, drained), true)
            end
        else
            addPerkMessage(config.feedback.arcaneSiphon, true)
        end
    end

    if data.procResonantConduit then
        -- Resonant Conduit must restore charge on the PLAYER's own staff here,
        -- since the actor script can only read/write its own object's state.
        local staff = getEquippedStaff()
        if staff and staff.recordId == data.staffRecordId then
            local idata = types.Item.itemData(staff)
            local record = types.Weapon.record(staff)
            if idata and record and record.enchant and record.enchant ~= "" then
                local maxCharge = getWeaponMaxCharge(record)
                local amount = tonumber(data.resonantConduitCharge) or 0
                if maxCharge > 0 and amount > 0 then
                    local before = tonumber(getItemEnchantmentCharge(idata)) or maxCharge
                    local newCharge = math.min(maxCharge, before + amount)
                    requestItemEnchantmentCharge(staff, newCharge)
                    -- Refresh our cached charge so the enchant-saving logic
                    -- doesn't see this as free casting on the next tick.
                    lastStaffCharge = newCharge
                    playPlayerSound(config.perks.resonantConduit.sound)
                    if detailed then
                        addPerkMessage(string.format("%s (+%.0f)",
                            config.feedback.resonantConduit, newCharge - before), true)
                    else
                        addPerkMessage(config.feedback.resonantConduit, true)
                    end
                end
            end
        end
    end

    if data.procNullPulse then
        addPerkMessage(config.feedback.nullPulse, true)
    end

    if #perkMessages > 0 then
        showPerkFeedback(table.concat(perkMessages, ' | '))
    end
end

-- ─── Dynamic Skill Tooltip ──────────────────────────────────────────────────

local function perkSummaryLine(skill, perkId)
    local p = config.perks
    if perkId == "concussive" then
        local q = p.concussive
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Concussive Strike: %s chance on staff hit to deal %.0f bonus fatigue damage.",
            percent(concussiveChance()), concussiveFatigue(skill))
    elseif perkId == "arcaneSiphon" then
        local q = p.arcaneSiphon
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Arcane Siphon: %s chance on hit to drain %.0f target magicka and restore it to you.",
            percent(arcaneSiphonChance()), arcaneSiphonAmount(skill))
    elseif perkId == "resonantConduit" then
        local q = p.resonantConduit
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Resonant Conduit: %s chance on hit with an enchanted staff to recover %.0f charge.",
            percent(resonantConduitChance()), resonantConduitCharge(skill))
    elseif perkId == "nullPulse" then
        local q = p.nullPulse
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Null Pulse: %s chance on hit to Silence the target for %ds.",
            percent(nullPulseChance()), nullPulseDuration())
    end
    return nil
end

local lastTooltipText = nil
local lastSkillDisplayName = nil

local function buildSkillDescription()
    local skill = getStavesSkillLevel()
    local displayName = skillDisplayName()
    local showMechanicTooltips = getSetting("showMechanicTooltips", true)
    local showPerkTooltips = getSetting("showPerkTooltips", true)
    local unlockedOnly = getSetting("tooltipUnlockedOnly", false)

    local perkOrder = {
        { id = "concussive",       level = config.perks.concussive.level },
        { id = "arcaneSiphon",     level = config.perks.arcaneSiphon.level },
        { id = "resonantConduit",  level = config.perks.resonantConduit.level },
        { id = "nullPulse",        level = config.perks.nullPulse.level },
    }

    local maxSpellBonus = getSetting("spellBonus", 25)
    local currentSpellBonus = math.floor(skill * maxSpellBonus / 100)
    local maxSaveChance = getSetting("maxSaveChance", 50)
    local currentSaveChance = skill * maxSaveChance / 100

    local lines = {
        "Governs your effectiveness with staves and enhances spellcasting while a staff is equipped.",
        "",
        string.format("Current %s: %d", displayName, math.floor(skill)),
    }

    if showMechanicTooltips then
        table.insert(lines, string.format("Staff hit chance governed by %s only: %s", displayName, getSetting("replaceBlunt", true) and "enabled" or "disabled"))
        table.insert(lines, string.format("Magic school bonus (staff equipped): +%d", currentSpellBonus))
        table.insert(lines, string.format("Enchant charge save chance: %.0f%%", currentSaveChance))
    end

    table.insert(lines, "")

    local perkLines = {}
    if showPerkTooltips then
        for _, perk in ipairs(perkOrder) do
            if stavesPerkEnabled(perk.id) and ((not unlockedOnly) or skill >= perk.level) then
                local line = perkSummaryLine(skill, perk.id)
                if line then table.insert(perkLines, line) end
            end
        end

        if unlockedOnly and #perkLines == 0 then
            local nextPerk = nil
            for _, perk in ipairs(perkOrder) do
                if stavesPerkEnabled(perk.id) and skill < perk.level then
                    nextPerk = perk
                    break
                end
            end
            if nextPerk then
                table.insert(perkLines, string.format("No perks unlocked yet. Next unlock at %d %s.", nextPerk.level, displayName))
                table.insert(perkLines, perkSummaryLine(skill, nextPerk.id))
            else
                table.insert(perkLines, string.format("All remaining %s perks are disabled in settings.", displayName))
            end
        end
    end

    for _, line in ipairs(perkLines) do table.insert(lines, line) end
    return table.concat(lines, "\n")
end

local function refreshSkillDescription(force)
    if not hasSkillFramework or not skillIsRegistered() then return end
    if not I.SkillFramework.modifySkill then return end
    local description = buildSkillDescription()
    local displayName = skillDisplayName()
    if not force and description == lastTooltipText and displayName == lastSkillDisplayName then return end
    I.SkillFramework.modifySkill(SKILL_ID, { name = displayName, description = description })
    lastTooltipText = description
    lastSkillDisplayName = displayName
end

-- ─── Engine Handlers ────────────────────────────────────────────────────────

local lastStaffState = false
local lastBonus = 0
local previousEq = nil
local gameplayUpdateTimer = 0.25
local runtimeSyncThrottle = 0.5
local tooltipRefreshTimer = 1.0

local function flushSpellXpFeedback(force)
    if pendingSpellXpFeedback <= 0 then return end
    if not force and pendingSpellXpFeedbackTimer > 0 then return end
    showFeedback(string.format("%s training +%.2f from spellcasting", skillDisplayName(), pendingSpellXpFeedback))
    pendingSpellXpFeedback = 0
    pendingSpellXpFeedbackTimer = 0
end

local function onUpdate(dt)
    updatePopupManager(dt)
    dt = tonumber(dt) or 0
    if not skillIsRegistered() then
        tryRegisterSkill()
        if not skillIsRegistered() then return end
    end

    if pendingSpellXpFeedbackTimer > 0 then
        pendingSpellXpFeedbackTimer = math.max(0, pendingSpellXpFeedbackTimer - dt)
    end
    flushSpellXpFeedback(false)

    -- Cheap per-frame equipment ID check; expensive staff/GRIP resolution is
    -- only performed on change or on throttled maintenance ticks.
    local currentEq = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local currentId = currentEq and currentEq.recordId or nil
    local eqChanged = (currentId ~= previousEq)
    previousEq = currentId

    runtimeSyncThrottle = runtimeSyncThrottle + dt
    if eqChanged or runtimeSyncThrottle >= 0.5 then
        syncRuntimeState(eqChanged)
        while runtimeSyncThrottle >= 0.5 do
            runtimeSyncThrottle = runtimeSyncThrottle - 0.5
        end
    end

    tooltipRefreshTimer = tooltipRefreshTimer + dt
    if tooltipRefreshTimer >= 1.0 then
        refreshSkillDescription(false)
        while tooltipRefreshTimer >= 1.0 do
            tooltipRefreshTimer = tooltipRefreshTimer - 1.0
        end
    end

    gameplayUpdateTimer = gameplayUpdateTimer + dt
    if not eqChanged and gameplayUpdateTimer < 0.25 then return end
    while gameplayUpdateTimer >= 0.25 do
        gameplayUpdateTimer = gameplayUpdateTimer - 0.25
    end

    reconcileClassBonus()
    applyBluntOverride()
    checkEnchantEfficiency()

    local staffNow = isStaffEquipped()
    local bonus = applySpellBonus()

    if staffNow ~= lastStaffState or bonus ~= lastBonus then
        if staffNow and bonus > 0 then
            showFeedback(skillDisplayName() .. ": magic schools +" .. bonus)
        elseif not staffNow and lastStaffState then
            showFeedback(skillDisplayName() .. ": magic school bonus removed")
        end
        lastStaffState = staffNow
        lastBonus = bonus or 0
    end
end


local function consolePrintInfo(msg)
    local ok = pcall(ui.printToConsole, '[' .. MODNAME .. '] ' .. tostring(msg), ui.CONSOLE_COLOR.Info)
    if not ok then
        print('[' .. MODNAME .. '] ' .. tostring(msg))
    end
end

local function consolePrintError(msg)
    local ok = pcall(ui.printToConsole, '[' .. MODNAME .. '] ' .. tostring(msg), ui.CONSOLE_COLOR.Error)
    if not ok then
        print('[' .. MODNAME .. '] ERROR: ' .. tostring(msg))
    end
end

local function getStavesSkillStat()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat) then return nil end
    return I.SkillFramework.getSkillStat(SKILL_ID)
end

local function addStavesSkill(amount)
    local stat = getStavesSkillStat()
    if not stat then return nil end
    stat.base = math.max(0, math.min(config.maxLevel, (stat.base or 0) + amount))
    return stat
end

local function setStavesSkill(target)
    local stat = getStavesSkillStat()
    if not stat then return nil end
    local modifier = stat.modifier or 0
    local clamped = math.max(0, math.min(config.maxLevel, target))
    stat.base = math.max(0, clamped - modifier)
    return stat
end

local function getStavesPerkSummary()
    local skill = getStavesSkillLevel()
    local perkList = {
        { id = 'concussive', name = 'Concussive Strike', level = config.perks.concussive.level },
        { id = 'arcaneSiphon', name = 'Arcane Siphon', level = config.perks.arcaneSiphon.level },
        { id = 'resonantConduit', name = 'Resonant Conduit', level = config.perks.resonantConduit.level },
        { id = 'nullPulse', name = 'Null Pulse', level = config.perks.nullPulse.level },
    }
    local unlocked = {}
    local nextPerk = nil
    for _, perk in ipairs(perkList) do
        if stavesPerkEnabled(perk.id) then
            if skill >= perk.level then
                unlocked[#unlocked + 1] = perk.name
            elseif not nextPerk then
                nextPerk = perk
            end
        end
    end
    local current = (#unlocked > 0) and unlocked[#unlocked] or 'None'
    return skill, current, nextPerk
end

local function onConsoleCommand(mode, command, selectedObject)
    local trimmed = tostring(command or ''):match('^%s*(.-)%s*$') or ''
    local root, rest = trimmed:match('^(%S+)%s*(.-)$')
    if root ~= 'staves' then return end

    if not (I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID)) then
        consolePrintError(skillDisplayName() .. ' skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: staves <amount> | staves set <value> | staves perk | staves grip | staves repair | staves repair blunt <value> | staves repair <school> <value>')
        return true
    end

    local repairBluntValue = rest:match('^repair%s+blunt%s+(-?%d+)$')
    if repairBluntValue then
        if setBluntModifiedValue(tonumber(repairBluntValue)) then
            consolePrintInfo(string.format('Blunt Weapon modified value repaired to %d. Re-equip the staff if needed.', tonumber(repairBluntValue)))
        else
            consolePrintError('Unable to access Blunt Weapon stat.')
        end
        return true
    end

    local repairSchool, repairSchoolValue = rest:match('^repair%s+(%a+)%s+(-?%d+)$')
    if repairSchool and repairSchoolValue then
        local ok, schoolName = setMagicSchoolModifiedValue(repairSchool, tonumber(repairSchoolValue))
        if ok then
            consolePrintInfo(string.format('%s modified value repaired to %d. Re-equip the staff if needed.', schoolName, tonumber(repairSchoolValue)))
        elseif schoolName then
            consolePrintError('Unable to access ' .. schoolName .. ' stat.')
        else
            consolePrintError('Unknown repair skill. Use one of: alteration, conjuration, destruction, illusion, mysticism, restoration, or blunt.')
        end
        return true
    end

    if rest == 'repair' or rest == 'clear' then
        clearTrackedModifiers()
        consolePrintInfo('Cleared Staves temporary Blunt and magic-school modifiers. Re-equip the staff to reapply current bonuses.')
        return true
    end

    if rest == 'grip' or rest == 'debug' then
        local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if not weapon then
            consolePrintInfo('No right-hand weapon equipped.')
            return true
        end

        local ok, record = pcall(types.Weapon.record, weapon)
        if not ok or not record then
            consolePrintError('Right-hand item is not readable as a weapon record.')
            return true
        end

        local original = gripOriginalRecordFor(weaponIdCandidates(weapon, record))
        local originalText = original and string.format('%s | %s | type=%s', tostring(original.id), tostring(original.name), tostring(original.type)) or 'none'
        consolePrintInfo(string.format(
            'equipped recordId=%s | record.id=%s | name=%s | type=%s | detectedStaff=%s | GRIP original=%s',
            tostring(weapon.recordId), tostring(record.id), tostring(record.name), tostring(record.type),
            tostring(isStaffWeapon(weapon)), originalText))
        return true
    end

    if rest == 'perk' or rest == 'status' then
        local skill, current, nextPerk = getStavesPerkSummary()
        if nextPerk then
            consolePrintInfo(string.format('%s: %d | current perk: %s | next: %s at %d', skillDisplayName(), skill, current, nextPerk.name, nextPerk.level))
        else
            consolePrintInfo(string.format('%s: %d | current perk: %s | all perks unlocked', skillDisplayName(), skill, current))
        end
        return true
    end

    local setValue = rest:match('^set%s+(-?%d+)$')
    if setValue then
        local stat = setStavesSkill(tonumber(setValue))
        if not stat then
            consolePrintError('Unable to access ' .. skillDisplayName() .. ' stat.')
        else
            local skill, current, nextPerk = getStavesPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('%s set to %d | current perk: %s | next: %s at %d', skillDisplayName(), skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('%s set to %d | current perk: %s | all perks unlocked', skillDisplayName(), skill, current))
            end
        end
        return true
    end

    local addValue = rest:match('^([+-]?%d+)$')
    if addValue then
        local stat = addStavesSkill(tonumber(addValue))
        if not stat then
            consolePrintError('Unable to access ' .. skillDisplayName() .. ' stat.')
        else
            local skill, current, nextPerk = getStavesPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('%s is now %d | current perk: %s | next: %s at %d', skillDisplayName(), skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('%s is now %d | current perk: %s | all perks unlocked', skillDisplayName(), skill, current))
            end
        end
        return true
    end

    consolePrintError('Bad syntax. Try: staves help')
    return true
end

local function onLoad(data)
    local savedBonuses = data and data.appliedBonuses or nil
    local savedSpellSnapshots = data and data.spellNativeSnapshots or nil
    local savedSpellBases = data and data.spellSnapshotBases or nil
    for _, school in ipairs(MAGIC_SCHOOLS) do
        appliedBonuses[school] = (type(savedBonuses) == 'table' and tonumber(savedBonuses[school])) or 0
        spellNativeSnapshots[school] = (type(savedSpellSnapshots) == 'table' and tonumber(savedSpellSnapshots[school])) or nil
        spellSnapshotBases[school] = (type(savedSpellBases) == 'table' and tonumber(savedSpellBases[school])) or nil
    end

    lastStaffState = false
    lastBonus = 0
    previousEq = nil
    gameplayUpdateTimer = 0.25
    runtimeSyncThrottle = 0.5
    tooltipRefreshTimer = 1.0
    lastRuntimeState = nil
    lastStaffCharge = nil
    lastStaffId = nil
    pendingSpellXpFeedback = 0
    pendingSpellXpFeedbackTimer = 0
    lastTooltipText = nil
    lastSkillDisplayName = nil
    legacyClassBonusMigrated = false
    appliedBluntDelta = (data and tonumber(data.appliedBluntDelta)) or 0
    bluntNativeSnapshot = (data and tonumber(data.bluntNativeSnapshot)) or nil
    bluntSnapshotBase = (data and tonumber(data.bluntSnapshotBase)) or nil

    classBonusState.applied = data and data.classBonusApplied or false
    classBonusState.classId = data and data.classBonusClassId or nil
    classBonusState.amount = data and tonumber(data.classBonusAmount) or 0
    classBonusState.mode = data and data.classBonusMode or 'base'
    classBonusState.cachedClassId = nil
    classBonusState.cachedSpecialization = nil
    reconcileClassBonus()

    notifyAAM()
end

local function onSave()
    local savedBonuses = {}
    local savedSpellSnapshots = {}
    local savedSpellBases = {}
    for _, school in ipairs(MAGIC_SCHOOLS) do
        savedBonuses[school] = tonumber(appliedBonuses[school]) or 0
        savedSpellSnapshots[school] = spellNativeSnapshots[school]
        savedSpellBases[school] = spellSnapshotBases[school]
    end

    return {
        classBonusApplied = classBonusState.amount ~= 0,
        classBonusClassId = classBonusState.classId,
        classBonusAmount = classBonusState.amount,
        classBonusMode = 'base',
        appliedBluntDelta = appliedBluntDelta,
        bluntNativeSnapshot = bluntNativeSnapshot,
        bluntSnapshotBase = bluntSnapshotBase,
        appliedBonuses = savedBonuses,
        spellNativeSnapshots = savedSpellSnapshots,
        spellSnapshotBases = savedSpellBases,
    }
end

return {
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        Staves_ResolvedHit = onResolvedHit,
        SkillPerkPopup_Show = onSkillPerkPopupShow,
    },
}
