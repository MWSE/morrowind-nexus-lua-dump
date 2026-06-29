--[[
    Evasion! — Player Script (v2: perk ladder)

    Adds a custom Evasion skill that grants Sanctuary (dodge chance)
    based on armor loadout, stamina, encumbrance, and movement state.

    Perk ladder (mirrors Throwing!):
      25  Second Wind — chance to restore fatigue when dodging while tired
      50  Riposte     — rare chance to redirect estimated dodged damage as health
      75  Pocket Ash    — chance to blind the attacker on a successful dodge
      100 Vanish      — become briefly unseen and Calm the attacker
]]

local ui       = require('openmw.ui')
local util     = require('openmw.util')
local core     = require('openmw.core')
local async    = require('openmw.async')
local storage  = require('openmw.storage')
local types    = require('openmw.types')
local self     = require('openmw.self')
local I        = require('openmw.interfaces')

local config   = require('scripts.Evasion.config')

local MODNAME = "Evasion"
local SKILL_ID = config.skillId
local EFFECT_ID = core.magic.EFFECT_TYPE.Sanctuary

local settingsSection = storage.playerSection("Settings_" .. MODNAME)
local function getSetting(key, default)
    local val = settingsSection:get(key)
    if val == nil then return default end
    return val
end

local function debugEnabled()
    return getSetting("debugMessages", false)
end

local function debugMessage(text)
    if not debugEnabled() then return end
    ui.showMessage(text)
    print("[Evasion! DEBUG] " .. text)
end

-- ─── Perk feedback overlay / independent shared stack ──────────────────────
-- Each skill mod ships this same small popup manager. A lightweight shared
-- heartbeat elects one active manager when multiple skill mods are installed,
-- but every mod can also run alone with no dependency on the others.

local FEEDBACK_DEFAULT_TEXT_RGB = { 24, 187, 207 }
local FEEDBACK_DEFAULT_SHADOW_RGB = { 132, 42, 39 }
local feedbackDuration = 1.35
local popupBusSection = storage.playerSection('SkillPerkPopupShared')
local POPUP_MANAGER_ID = MODNAME
local POPUP_MANAGER_PRIORITY = 10
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
    if legacyShow == nil then legacyShow = getRawSetting('showFeedback') end
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

local function showFeedback(text)
    local style = getPerkMessageStyle()
    if style <= 0 then return end

    local msg = tostring(text or '')
    if style == 2 then
        showStandardFeedbackMessage(msg)
        return
    end

    emitSkillPerkPopup(perkPopupPayload(msg))
end

local function showPerkFeedback(baseText, detailText, hasSensoryCue)
    if hasSensoryCue and shouldSuppressSensoryPopups() then return end

    if getPerkPopupDetail() >= 1 and detailText and detailText ~= "" then
        showFeedback(baseText .. " " .. detailText)
    else
        showFeedback(baseText)
    end
end

local function xpMultiplier()
    return math.max(0, getSetting("xpMultiplier", 100)) * 0.01
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
local classDynamicModifierRegistered = false
local legacyClassBonusMigrated = false

local function skillIsRegistered()
    return I.SkillFramework and I.SkillFramework.getSkillRecord
        and I.SkillFramework.getSkillRecord(SKILL_ID) ~= nil
end

local function tryRegisterSkill()
    if not I.SkillFramework then
        print("[Evasion!] Skill Framework not found!")
        return
    end
    hasSkillFramework = true

    if skillIsRegistered() then return end

    I.SkillFramework.registerSkill(SKILL_ID, {
        name = "Evasion",
        description = "Governs your ability to dodge incoming attacks. Lighter armor, good fatigue, low encumbrance, and active movement preserve more evasion.",
        attribute = "agility",
        specialization = I.SkillFramework.SPECIALIZATION.Stealth,
        startLevel = config.startLevel, maxLevel = config.maxLevel,
        skillGain = { dodge = 1.0 },
        statsWindowProps = {
            subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Movement,
            visible = true,
        },
        icon = {
            bgr = 'icons/SkillFramework/stealth_blank.dds',
            fgr = 'icons/Evasion/evasion.dds',
            bgrColor = util.color.rgb(1, 1, 1),
            fgrColor = util.color.rgb(0.95, 0.95, 0.95),
        },
    })

    I.SkillFramework.registerRaceModifier(SKILL_ID, "khajiit", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "wood elf", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "redguard", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "dark elf", 5)

    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Bm_Naga", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Cathay", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Cathay-raht", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Dagi-raht", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Ohmes", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Ohmes-raht", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Els_Suthay", 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Pya_SeaElf", 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, "T_Yok_Duadri", 5)

    I.SkillFramework.registerSkillBook("bk_guylainesarchitecture", SKILL_ID)

    print("[Evasion!] Evasion skill registered (governed by Agility)")
end

tryRegisterSkill()

-- ─── Stealth Class Bonus (+10 native base) ──────────────────────────────

local classBonusApplied = false
local classBonusMode = "none"
local appliedClassBonusAmount = 0
local cachedClassSpecialization = nil
local cachedClassId = nil

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
    if cachedClassSpecialization then return cachedClassSpecialization end
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
        cachedClassSpecialization = bestSpec
        return cachedClassSpecialization
    end

    return nil
end

local function getPlayerClassSpecialization()
    local classId, classRecord = getPlayerClassRecord()
    local classIdText = classId and tostring(classId) or ''
    if cachedClassId ~= classIdText then
        cachedClassId = classIdText
        cachedClassSpecialization = nil
    end

    local directSpecialization = normalizeSpecialization(classRecord and classRecord.specialization)
    if directSpecialization then
        cachedClassSpecialization = directSpecialization
        return directSpecialization
    end

    return inferClassSpecializationFromVanillaSkills()
end

local function getClassSpecializationBonus()
    -- Ultimate Leveling handles Skill Framework custom-skill starting specialization bonuses itself.
    if core.contentFiles.has('UltimateLeveling.omwaddon') then return 0 end
    if getPlayerClassSpecialization() == 'stealth' then
        return config.classBonus
    end
    return 0
end

local function removeSavedModifierClassBonus(stat, amount)
    amount = tonumber(amount) or 0
    if classBonusMode ~= 'modifier' then return amount end
    if amount ~= 0 then
        stat.modifier = (tonumber(stat.modifier) or 0) - amount
    end
    return 0
end

local function reconcileClassBonusMode()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat and skillIsRegistered()) then return end
    if types.Player and types.Player.isCharGenFinished and not types.Player.isCharGenFinished(self) then return end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return end

    local desired = getClassSpecializationBonus()
    local current = tonumber(appliedClassBonusAmount) or 0
    current = removeSavedModifierClassBonus(stat, current)

    if desired ~= current then
        stat.base = math.max(0, math.min(config.maxLevel, (tonumber(stat.base) or 0) - current + desired))
        appliedClassBonusAmount = desired
    end

    classBonusApplied = desired ~= 0
    classBonusMode = 'base'
end

local function applyClassBonus()
    reconcileClassBonusMode()
end

-- ─── Armor Helpers ──────────────────────────────────────────────────────────

local SLOT = types.Actor.EQUIPMENT_SLOT
local ARMOR_TYPE = types.Armor.TYPE
local armorSlotWeights = {
    [SLOT.Helmet] = 0.08,
    [SLOT.Cuirass] = 0.28,
    [SLOT.LeftPauldron] = 0.05,
    [SLOT.RightPauldron] = 0.05,
    [SLOT.Greaves] = 0.14,
    [SLOT.Boots] = 0.14,
    [SLOT.LeftGauntlet] = 0.04,
    [SLOT.RightGauntlet] = 0.04,
    [SLOT.CarriedLeft] = 0.18,
}

local armorTypeWeights = {
    [ARMOR_TYPE.Helmet] = armorSlotWeights[SLOT.Helmet],
    [ARMOR_TYPE.Cuirass] = armorSlotWeights[SLOT.Cuirass],
    [ARMOR_TYPE.LPauldron] = armorSlotWeights[SLOT.LeftPauldron],
    [ARMOR_TYPE.RPauldron] = armorSlotWeights[SLOT.RightPauldron],
    [ARMOR_TYPE.Greaves] = armorSlotWeights[SLOT.Greaves],
    [ARMOR_TYPE.Boots] = armorSlotWeights[SLOT.Boots],
    [ARMOR_TYPE.LGauntlet] = armorSlotWeights[SLOT.LeftGauntlet],
    [ARMOR_TYPE.RGauntlet] = armorSlotWeights[SLOT.RightGauntlet],
    [ARMOR_TYPE.LBracer] = armorSlotWeights[SLOT.LeftGauntlet],
    [ARMOR_TYPE.RBracer] = armorSlotWeights[SLOT.RightGauntlet],
    [ARMOR_TYPE.Shield] = armorSlotWeights[SLOT.CarriedLeft],
}

local armorWeightGMST = {
    [ARMOR_TYPE.Boots]      = core.getGMST("iBootsWeight"),
    [ARMOR_TYPE.Cuirass]    = core.getGMST("iCuirassWeight"),
    [ARMOR_TYPE.Greaves]    = core.getGMST("iGreavesWeight"),
    [ARMOR_TYPE.Helmet]     = core.getGMST("iHelmWeight"),
    [ARMOR_TYPE.LBracer]    = core.getGMST("iGauntletWeight"),
    [ARMOR_TYPE.RBracer]    = core.getGMST("iGauntletWeight"),
    [ARMOR_TYPE.LGauntlet]  = core.getGMST("iGauntletWeight"),
    [ARMOR_TYPE.RGauntlet]  = core.getGMST("iGauntletWeight"),
    [ARMOR_TYPE.LPauldron]  = core.getGMST("iPauldronWeight"),
    [ARMOR_TYPE.RPauldron]  = core.getGMST("iPauldronWeight"),
    [ARMOR_TYPE.Shield]     = core.getGMST("iShieldWeight"),
}
local lightMaxMod = core.getGMST("fLightMaxMod")
local medMaxMod = core.getGMST("fMedMaxMod")

local function getArmorWeightClass(armorRecord)
    local weight = armorRecord.weight
    if weight == 0 then return "unarmored" end

    local refWeight = armorWeightGMST[armorRecord.type] or 0
    if refWeight <= 0 then return "heavy" end

    local eps = 5e-4
    if weight <= refWeight * lightMaxMod + eps then return "light"
    elseif weight <= refWeight * medMaxMod + eps then return "medium"
    else return "heavy" end
end

local function getEvasionSkillLevel()
    if hasSkillFramework and I.SkillFramework then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then return stat.modified end
    end
    return types.NPC.stats.skills.unarmored(self).modified
end

local function getArmorRetentionSettings()
    return {
        unarmored = 1.0,
        light = getSetting("lightMult", 60) * 0.01,
        medium = getSetting("mediumMult", 35) * 0.01,
        heavy = getSetting("heavyMult", 15) * 0.01,
    }
end

local recentJumpTimer = 0
local dodgeHistory = {}
local previousEvasion = 0
local evasionCheckEvery = 0.25
local evasionUpdateTime = evasionCheckEvery
local tooltipCheckEvery = 1.0
local tooltipUpdateTime = tooltipCheckEvery

local function consumeInterval(timer, interval)
    if interval <= 0 then return 0, true end
    if timer < interval then return timer, false end
    repeat
        timer = timer - interval
    until timer < interval
    return timer, true
end

-- ─── Perk state ─────────────────────────────────────────────────────────────

local secondWindCooldownUntil = 0
local ashSandCooldownUntil = 0
local vanishCooldownUntil = 0
local vanishChameleonApplied = 0
local vanishChameleonExpireTime = 0

local function getFatigueFactor(actor)
    local fatigue = types.Actor.stats.dynamic.fatigue(actor)
    local maxFatigue = math.max(1, fatigue.base + fatigue.modifier)
    local ratio = math.max(0, math.min(1, fatigue.current / maxFatigue))
    return 0.2 + 0.8 * ratio, ratio
end

local function getEncumbranceFactor(actor)
    local capacity = math.max(1, types.Actor.getCapacity(actor))
    local ratio = math.max(0, types.Actor.getEncumbrance(actor) / capacity)
    if ratio <= 0.5 then
        return 1.0, ratio
    end
    local t = math.min(1, (ratio - 0.5) / 0.45)
    return math.max(0.05, 1.0 - 0.95 * t), ratio
end

local function getMovementFactor()
    local bonus = 1.0
    local moving = (math.abs(self.controls.movement) > 0.01 or math.abs(self.controls.sideMovement) > 0.01)
        and types.Actor.getCurrentSpeed(self) > 5
    if moving then
        bonus = bonus + getSetting("movementBonus", 5) * 0.01
    end

    local equipment = types.Actor.getEquipment(self)
    if not equipment[SLOT.CarriedRight] then
        bonus = bonus + getSetting("unarmedBonus", 5) * 0.01
    end

    if recentJumpTimer > 0 then
        bonus = bonus + getSetting("recentJumpBonus", 3) * 0.01
    end

    return bonus
end

local function getBaseRetentionData(actor)
    local retentionSettings = getArmorRetentionSettings()
    local unarm, light, med, heavy = 0, 0, 0, 0
    local equipment = types.Actor.getEquipment(actor)

    for slot, w in pairs(armorSlotWeights) do
        local item = equipment[slot]
        if item and types.Armor.objectIsInstance(item) then
            local wc = getArmorWeightClass(types.Armor.record(item))
            if wc == "light" then light = light + w
            elseif wc == "medium" then med = med + w
            elseif wc == "heavy" then heavy = heavy + w
            else unarm = unarm + w end
        else
            if slot ~= SLOT.CarriedLeft or not item then
                unarm = unarm + w
            end
        end
    end

    local retention = unarm
        + (light * retentionSettings.light)
        + (med * retentionSettings.medium)
        + (heavy * retentionSettings.heavy)

    return {
        retention = retention,
        unarmoredWeight = unarm,
        lightWeight = light,
        mediumWeight = med,
        heavyWeight = heavy,
        retentionSettings = retentionSettings,
    }
end

local function calcEvasionBreakdown()
    local skill = getEvasionSkillLevel()
    local maxSanc = getSetting("maxSanctuary", 30)
    local base = getBaseRetentionData(self)
    local fatigueFactor, fatigueRatio = getFatigueFactor(self)
    local encFactor, encRatio = getEncumbranceFactor(self)
    local movementFactor = getMovementFactor()

    local evasion = math.floor(skill * base.retention * maxSanc / 100 * fatigueFactor * encFactor * movementFactor)

    return {
        skill = skill,
        maxSanctuary = maxSanc,
        retention = base.retention,
        fatigueFactor = fatigueFactor,
        fatigueRatio = fatigueRatio,
        encumbranceFactor = encFactor,
        encumbranceRatio = encRatio,
        movementFactor = movementFactor,
        total = evasion,
    }
end

local function applyEvasion()
    local effects = types.Actor.activeEffects(self)
    local breakdown = calcEvasionBreakdown()
    local newEv = breakdown.total
    local delta = newEv - previousEvasion
    if delta ~= 0 then
        effects:modify(delta, EFFECT_ID)
        previousEvasion = newEv
    end
end

-- ─── Perk scaling functions ─────────────────────────────────────────────────

local function riposteChance(skill)
    local p = config.perks.riposte
    return lerp(p.chanceAtUnlock or 1.0, p.chanceAt100 or p.chanceAtUnlock or 1.0, skillT(skill, p.level))
end

local function riposteFraction(skill)
    local p = config.perks.riposte
    return lerp(p.fractionAtUnlock, p.fractionAt100, skillT(skill, p.level))
end

local function secondWindChance(skill)
    local p = config.perks.secondWind
    return lerp(p.chanceAtUnlock or 1.0, p.chanceAt100 or p.chanceAtUnlock or 1.0, skillT(skill, p.level))
end

local function secondWindRestore(skill)
    local p = config.perks.secondWind
    return math.floor(lerp(p.restoreAtUnlock, p.restoreAt100, skillT(skill, p.level)) + 0.5)
end

local function ashSandChance(skill)
    local p = config.perks.ashSand
    return lerp(p.chanceAtUnlock, p.chanceAt100, skillT(skill, p.level))
end

local function applySelfVanish()
    local magnitude = math.max(0, config.perks.vanish.chameleonMagnitude or 0)
    local duration = math.max(0, config.perks.vanish.chameleonDuration or 0)
    if magnitude <= 0 or duration <= 0 then return end
    local effects = types.Actor.activeEffects(self)
    if vanishChameleonApplied ~= 0 then
        effects:modify(-vanishChameleonApplied, core.magic.EFFECT_TYPE.Chameleon)
    end
    effects:modify(magnitude, core.magic.EFFECT_TYPE.Chameleon)
    vanishChameleonApplied = magnitude
    vanishChameleonExpireTime = core.getSimulationTime() + duration
end

-- ─── Riposte: estimate attacker's damage output ─────────────────────────────
-- AttackInfo.damage is not populated for failed attacks, so we synthesise
-- it from the attacker's equipped weapon record, then apply skill-scaled
-- riposte fraction as health damage.

local function estimateAttackerDamage(attacker)
    if not attacker then return 0 end

    -- Melee: try equipped weapon record
    local weapon
    local ok = pcall(function()
        weapon = types.Actor.getEquipment(attacker, SLOT.CarriedRight)
    end)
    if not ok then weapon = nil end

    local meanWeaponDamage = 0
    if weapon and types.Weapon.objectIsInstance(weapon) then
        local rec = types.Weapon.record(weapon)
        if rec then
            local maxD = math.max(
                tonumber(rec.chopMaxDamage) or 0,
                tonumber(rec.slashMaxDamage) or 0,
                tonumber(rec.thrustMaxDamage) or 0
            )
            local minD = math.max(
                tonumber(rec.chopMinDamage) or 0,
                tonumber(rec.slashMinDamage) or 0,
                tonumber(rec.thrustMinDamage) or 0
            )
            meanWeaponDamage = (minD + maxD) * 0.5
        end
    end

    -- Fallback: use attacker strength as a proxy for unarmed / creature attacks
    if meanWeaponDamage <= 0 then
        local strStat
        local ok2 = pcall(function()
            strStat = types.Actor.stats.attributes.strength(attacker)
        end)
        if ok2 and strStat then
            meanWeaponDamage = (strStat.modified or 0) * 0.10   -- e.g. str 50 -> 5
        else
            meanWeaponDamage = 5
        end
    end

    return meanWeaponDamage
end

-- ─── Skill Training from Dodging + Perk Procs ───────────────────────────────

local function getAttackerKey(attacker)
    if not attacker then return "unknown" end
    if attacker.id then return tostring(attacker.id) end
    if attacker.recordId then return tostring(attacker.recordId) end
    return tostring(attacker)
end

local function getRepeatedMissGain(attacker)
    local now = core.getSimulationTime()
    local window = math.max(1, getSetting("repeatMissWindow", 4))
    local minGain = math.max(0.2, math.min(1.0, getSetting("repeatMissMinGain", 50) * 0.01))
    local key = getAttackerKey(attacker)
    local entry = dodgeHistory[key]

    local gain = 1.0
    if entry and (now - entry.lastTime) <= window then
        entry.count = entry.count + 1
        gain = math.max(minGain, 1.0 - 0.15 * (entry.count - 1))
        entry.lastTime = now
    else
        dodgeHistory[key] = { lastTime = now, count = 1 }
    end

    for attackerKey, attackerEntry in pairs(dodgeHistory) do
        if (now - attackerEntry.lastTime) > (window * 2) then
            dodgeHistory[attackerKey] = nil
        end
    end

    return gain
end

local function onDodgePerks(attacker)
    if not getSetting("perksEnabled", true) then return end

    local skill = getEvasionSkillLevel()
    local now = core.getSimulationTime()

    -- 25: Second Wind
    if skill >= config.perks.secondWind.level
        and getSetting("secondWindEnabled", true)
        and now >= secondWindCooldownUntil then

        local _, fatigueRatio = getFatigueFactor(self)
        if fatigueRatio < config.perks.secondWind.fatigueThreshold
            and math.random() <= secondWindChance(skill) then
            local amt = secondWindRestore(skill)
            local fat = types.Actor.stats.dynamic.fatigue(self)
            local maxF = fat.base + fat.modifier
            fat.current = math.min(maxF, fat.current + amt)
            secondWindCooldownUntil = now + config.perks.secondWind.cooldown
            showPerkFeedback(config.feedback.secondWind, "(+" .. amt .. " fatigue)")
        end
    end

    -- 50: Riposte
    if skill >= config.perks.riposte.level
        and getSetting("riposteEnabled", true)
        and attacker then

        if math.random() <= riposteChance(skill) then
            local estimated = estimateAttackerDamage(attacker)
            local healthDmg = estimated * riposteFraction(skill)
            healthDmg = clamp(healthDmg, config.riposteMinHealthDamage, config.riposteMaxHealthDamage)

            core.sendGlobalEvent("Evasion_Riposte", {
                target = attacker,
                attacker = self,
                healthDamage = healthDmg,
                sound = config.perks.riposte.sound,
            })
            showPerkFeedback(config.feedback.riposte, string.format("(%.0f health)", healthDmg), true)
        end
    end

    -- 75: Pocket Ash
    if skill >= config.perks.ashSand.level
        and getSetting("ashSandEnabled", true)
        and attacker
        and now >= ashSandCooldownUntil then

        if math.random() <= ashSandChance(skill) then
            core.sendGlobalEvent("Evasion_AshSand", {
                target = attacker,
                attacker = self,
                sound = config.perks.ashSand.sound,
            })

            local cooldown = config.perks.ashSand.cooldown
            ashSandCooldownUntil = now + cooldown
            showPerkFeedback(config.feedback.ashSand, string.format("(Blind %s for %ds)",
                tostring(config.perks.ashSand.blindMagnitude),
                config.perks.ashSand.blindDuration
            ), true)
        end
    end

    -- 100: Vanish
    if skill >= config.perks.vanish.level
        and getSetting("vanishEnabled", true)
        and attacker
        and now >= vanishCooldownUntil then

        applySelfVanish()
        core.sendGlobalEvent("Evasion_Vanish", {
            target = attacker,
            attacker = self,
            sound = config.perks.vanish.sound,
        })

        vanishCooldownUntil = now + config.perks.vanish.cooldown
        showPerkFeedback(config.feedback.vanish, string.format("(%s Chameleon, Calm, %.0fs CD)",
            percent(config.perks.vanish.chameleonMagnitude * 0.01),
            config.perks.vanish.cooldown
        ), true)
    end
end

local function isWeaponAttack(attackInfo)
    if not attackInfo or not I.Combat or not I.Combat.ATTACK_SOURCE_TYPES then return false end
    local sourceTypes = I.Combat.ATTACK_SOURCE_TYPES
    return attackInfo.sourceType == sourceTypes.Melee or attackInfo.sourceType == sourceTypes.Ranged
end

local function zeroAttackDamage(attackInfo)
    if not attackInfo or not attackInfo.damage then return end
    for key, value in pairs(attackInfo.damage) do
        if type(value) == "number" then
            attackInfo.damage[key] = 0
        end
    end
end

local function awardDodgeTraining(attacker, gainOverride)
    local gain = gainOverride or getRepeatedMissGain(attacker)
    I.SkillFramework.skillUsed(SKILL_ID, {
        useType = "dodge",
        skillGain = gain * xpMultiplier(),
    })
    onDodgePerks(attacker)

    local breakdown = calcEvasionBreakdown()
    debugMessage(string.format(
        "Evasion %d total | XP gain x%.2f | Ret %.0f%% Fat %.0f%% Enc %.0f%% Move %.0f%%",
        breakdown.total,
        gain * xpMultiplier(),
        breakdown.retention * 100,
        breakdown.fatigueFactor * 100,
        breakdown.encumbranceFactor * 100,
        breakdown.movementFactor * 100
    ))
end

local function onHit(attackInfo)
    if not hasSkillFramework or not I.SkillFramework then return end

    if attackInfo and attackInfo.successful == false and attackInfo.attacker then
        awardDodgeTraining(attackInfo.attacker)
    end
end

-- ─── Dynamic Skill Tooltip (ported from Throwing) ───────────────────────────

local function perkSummaryLine(skill, perkId)
    local p = config.perks
    if perkId == "secondWind" then
        local q = p.secondWind
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Second Wind: dodging while below %s fatigue has a %s chance to restore %d fatigue (once every %.0fs).",
            percent(q.fatigueThreshold), percent(secondWindChance(skill)), secondWindRestore(skill), q.cooldown
        )
    elseif perkId == "riposte" then
        local q = p.riposte
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Riposte: on a dodge, %s chance to redirect %s of the attacker's estimated damage back at them as health damage.",
            percent(riposteChance(skill)), percent(riposteFraction(skill))
        )
    elseif perkId == "ashSand" then
        local q = p.ashSand
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Pocket Ash: on a dodge, %s chance to blind the attacker by %d points for %ds.",
            percent(ashSandChance(skill)), q.blindMagnitude, q.blindDuration
        )
    elseif perkId == "vanish" then
        local q = p.vanish
        local active = skill >= q.level
        local prefix = active and "[Active] " or string.format("[Unlock %d] ", q.level)
        return prefix .. string.format(
            "Vanish: on a dodge, gain %s Chameleon for %ds and Calm your attacker for %ds. %.0fs cooldown.",
            percent(q.chameleonMagnitude * 0.01), q.chameleonDuration, q.calmDuration, q.cooldown
        )
    end
    return nil
end

local lastTooltipText = nil
local function evasionPerkEnabled(perkId)
    if not getSetting("perksEnabled", true) then return false end
    if perkId == "secondWind" then return getSetting("secondWindEnabled", true) end
    if perkId == "riposte" then return getSetting("riposteEnabled", true) end
    if perkId == "ashSand" then return getSetting("ashSandEnabled", true) end
    if perkId == "vanish" then return getSetting("vanishEnabled", true) end
    return true
end

local function buildSkillDescription()
    local skill = getEvasionSkillLevel()
    local showMechanicTooltips = getSetting("showMechanicTooltips", true)
    local showPerkTooltips = getSetting("showPerkTooltips", true)
    local unlockedOnly = getSetting("tooltipUnlockedOnly", false)

    local perkOrder = {
        { id = "secondWind", level = config.perks.secondWind.level },
        { id = "riposte",    level = config.perks.riposte.level },
        { id = "ashSand", level = config.perks.ashSand.level },
        { id = "vanish", level = config.perks.vanish.level },
    }

    local lines = {
        "Governs your ability to dodge incoming attacks. Lighter armor, good fatigue, low encumbrance, and active movement preserve more evasion.",
    }

    if showMechanicTooltips then
        table.insert(lines, "")
        table.insert(lines, string.format("Current Evasion: %d", math.floor(skill)))
    end

    table.insert(lines, "")

    local perkLines = {}
    if showPerkTooltips then
        for _, perk in ipairs(perkOrder) do
            if evasionPerkEnabled(perk.id) and ((not unlockedOnly) or skill >= perk.level) then
                local line = perkSummaryLine(skill, perk.id)
                if line then table.insert(perkLines, line) end
            end
        end
    end

    if showPerkTooltips and unlockedOnly and #perkLines == 0 then
        local nextPerk = nil
        for _, perk in ipairs(perkOrder) do
            if evasionPerkEnabled(perk.id) and skill < perk.level then
                nextPerk = perk
                break
            end
        end
        if nextPerk then
            table.insert(perkLines, string.format("No perks unlocked yet. Next unlock at %d Evasion.", nextPerk.level))
            table.insert(perkLines, perkSummaryLine(skill, nextPerk.id))
        else
            table.insert(perkLines, "All Evasion perks are disabled in settings.")
        end
    end

    for _, line in ipairs(perkLines) do table.insert(lines, line) end
    return table.concat(lines, "\n")
end

local function refreshSkillDescription(force)
    if not hasSkillFramework or not I.SkillFramework or not I.SkillFramework.modifySkill then return end
    local description = buildSkillDescription()
    if not force and description == lastTooltipText then return end
    I.SkillFramework.modifySkill(SKILL_ID, { description = description })
    lastTooltipText = description
end

-- ─── InventoryExtender Tooltip (unchanged from v1) ──────────────────────────

local function calcItemTooltipContribution(item)
    if not types.Armor.objectIsInstance(item) then return nil end

    local record = types.Armor.record(item)
    local weight = armorTypeWeights[record.type]
    if not weight then return nil end

    local retentionSettings = getArmorRetentionSettings()
    local armorClass = getArmorWeightClass(record)
    local retention = retentionSettings[armorClass] or 1.0
    local skill = getEvasionSkillLevel()
    local maxSanc = getSetting("maxSanctuary", 30)
    local fatigueFactor = getFatigueFactor(self)
    local encFactor = getEncumbranceFactor(self)
    local movementFactor = getMovementFactor()

    return math.floor(skill * weight * retention * maxSanc / 100 * fatigueFactor * encFactor * movementFactor), armorClass, weight
end

local function tryRegisterIE()
    if not I.InventoryExtender then return end
    I.InventoryExtender.registerTooltipModifier("Evasion_Rating", function(item, layout)
        if not types.Armor.objectIsInstance(item) then return layout end

        local ev, armorClass, slotWeight = calcItemTooltipContribution(item)
        if not ev then return layout end

        local ok, inner = pcall(function() return layout.content[1].content[1].content end)
        if not ok or not inner then return layout end

        local BASE = I.InventoryExtender.Templates.BASE
        local C = I.InventoryExtender.Constants
        inner:add(BASE.intervalV(2))
        inner:add({
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content {
                { template = BASE.textNormal, props = { text = "Evasion Contribution: ", textColor = C.Colors.DEFAULT } },
                { template = BASE.textNormal, props = { text = tostring(ev), textColor = C.Colors.DEFAULT_LIGHT } },
            },
        })
        inner:add(BASE.intervalV(1))
        inner:add({
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content {
                { template = BASE.textSmall, props = {
                    text = string.format("%s armor • slot weight %.2f", armorClass:gsub("^%l", string.upper), slotWeight),
                    textColor = C.Colors.DEFAULT,
                } },
            },
        })
        return layout
    end)
    print("[Evasion!] Registered with InventoryExtender")
end
async:newUnsavableSimulationTimer(0.2, tryRegisterIE)

-- ─── Engine Handlers ────────────────────────────────────────────────────────

local function onUpdate(dt)
    updatePopupManager(dt)

    reconcileClassBonusMode()

    recentJumpTimer = math.max(0, recentJumpTimer - dt)
    if self.controls.jump and types.Actor.isOnGround(self) then
        recentJumpTimer = 0.75
    end

    if vanishChameleonApplied ~= 0 and core.getSimulationTime() >= vanishChameleonExpireTime then
        types.Actor.activeEffects(self):modify(-vanishChameleonApplied, core.magic.EFFECT_TYPE.Chameleon)
        vanishChameleonApplied = 0
        vanishChameleonExpireTime = 0
    end

    tooltipUpdateTime = tooltipUpdateTime + dt
    local shouldRefreshTooltip
    tooltipUpdateTime, shouldRefreshTooltip = consumeInterval(tooltipUpdateTime, tooltipCheckEvery)
    if shouldRefreshTooltip then
        refreshSkillDescription(false)
    end

    evasionUpdateTime = evasionUpdateTime + dt
    local shouldUpdateEvasion
    evasionUpdateTime, shouldUpdateEvasion = consumeInterval(evasionUpdateTime, evasionCheckEvery)
    if not shouldUpdateEvasion then return end

    applyEvasion()
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

local function getEvasionSkillStat()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat) then return nil end
    return I.SkillFramework.getSkillStat(SKILL_ID)
end

local function addEvasionSkill(amount)
    local stat = getEvasionSkillStat()
    if not stat then return nil end
    stat.base = math.max(0, math.min(config.maxLevel, (stat.base or 0) + amount))
    return stat
end

local function setEvasionSkill(target)
    local stat = getEvasionSkillStat()
    if not stat then return nil end
    local modifier = stat.modifier or 0
    local clamped = math.max(0, math.min(config.maxLevel, target))
    stat.base = math.max(0, clamped - modifier)
    return stat
end

local function getEvasionPerkSummary()
    local skill = getEvasionSkillLevel()
    local perkList = {
        { id = 'secondWind', name = 'Second Wind', level = config.perks.secondWind.level },
        { id = 'riposte', name = 'Riposte', level = config.perks.riposte.level },
        { id = 'ashSand', name = 'Pocket Ash', level = config.perks.ashSand.level },
        { id = 'vanish', name = 'Vanish', level = config.perks.vanish.level },
    }
    local unlocked = {}
    local nextPerk = nil
    for _, perk in ipairs(perkList) do
        if skill >= perk.level then
            unlocked[#unlocked + 1] = perk.name
        elseif not nextPerk then
            nextPerk = perk
        end
    end
    local current = (#unlocked > 0) and unlocked[#unlocked] or 'None'
    return skill, current, nextPerk
end

local function onConsoleCommand(mode, command, selectedObject)
    local trimmed = tostring(command or ''):match('^%s*(.-)%s*$') or ''
    local root, rest = trimmed:match('^(%S+)%s*(.-)$')
    if root ~= 'evasion' then return end

    if not (I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID)) then
        consolePrintError('Evasion skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: evasion <amount> | evasion set <value> | evasion perk')
        return true
    end

    if rest == 'perk' or rest == 'status' then
        local skill, current, nextPerk = getEvasionPerkSummary()
        if nextPerk then
            consolePrintInfo(string.format('Evasion: %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
        else
            consolePrintInfo(string.format('Evasion: %d | current perk: %s | all perks unlocked', skill, current))
        end
        return true
    end

    local setValue = rest:match('^set%s+(-?%d+)$')
    if setValue then
        local stat = setEvasionSkill(tonumber(setValue))
        if not stat then
            consolePrintError('Unable to access Evasion stat.')
        else
            local skill, current, nextPerk = getEvasionPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Evasion set to %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Evasion set to %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    local addValue = rest:match('^([+-]?%d+)$')
    if addValue then
        local stat = addEvasionSkill(tonumber(addValue))
        if not stat then
            consolePrintError('Unable to access Evasion stat.')
        else
            local skill, current, nextPerk = getEvasionPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Evasion is now %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Evasion is now %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    consolePrintError('Bad syntax. Try: evasion help')
    return true
end

local function onLoad(data)
    resetPopupRegistryOnce()
    registerPopupManagerCandidate()
    previousEvasion = (data and data.previousEvasion) or 0
    evasionUpdateTime = evasionCheckEvery
    tooltipUpdateTime = tooltipCheckEvery
    recentJumpTimer = 0
    classBonusApplied = (data and data.classBonusApplied) or false
    appliedClassBonusAmount = (data and tonumber(data.classBonusAmount)) or ((classBonusApplied and config.classBonus) or 0)
    legacyClassBonusMigrated = false
    dodgeHistory = {}
    secondWindCooldownUntil = 0
    ashSandCooldownUntil = 0
    vanishCooldownUntil = 0
    vanishChameleonApplied = (data and data.vanishChameleonApplied) or 0
    vanishChameleonExpireTime = (data and data.vanishChameleonExpireTime) or 0
    if vanishChameleonApplied ~= 0 then
        if core.getSimulationTime() >= vanishChameleonExpireTime then
            types.Actor.activeEffects(self):modify(-vanishChameleonApplied, core.magic.EFFECT_TYPE.Chameleon)
            vanishChameleonApplied = 0
            vanishChameleonExpireTime = 0
        end
    end
    lastTooltipText = nil
    classBonusMode = (data and data.classBonusMode) or ((classBonusApplied and "base") or "none")
    reconcileClassBonusMode()
end

local function onSave()
    return {
        classBonusApplied = appliedClassBonusAmount ~= 0,
        classBonusMode = "base",
        classBonusAmount = appliedClassBonusAmount,
        previousEvasion = previousEvasion,
        vanishChameleonApplied = vanishChameleonApplied,
        vanishChameleonExpireTime = vanishChameleonExpireTime,
    }
end

return {
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onUpdate = onUpdate,
        onLoad = onLoad, onInit = onLoad, onSave = onSave,
    },
    eventHandlers = {
        Hit = onHit,
        SkillPerkPopup_Show = onSkillPerkPopupShow,
    },
}
