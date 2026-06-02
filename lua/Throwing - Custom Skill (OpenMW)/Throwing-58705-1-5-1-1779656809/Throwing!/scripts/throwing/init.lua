local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local config = require('scripts.throwing.config')

local MODNAME = 'Throwing'
local NEVER = -1000000000
local SKILL_ID = config.skillId
local CLASS_BONUS_AMOUNT = config.classBonus

local hasSkillFramework = false
local settingsSection = storage.playerSection('Settings_' .. MODNAME)

local classBonusState = {
    applied = false,
    classId = nil,
    amount = 0,
}

local appliedMarksmanDelta = 0
local marksmanNativeSnapshot = nil
local marksmanSnapshotBase = nil
local previousWeaponId = nil
local gameplayUpdateTimer = 0.25
local settingsSyncTimer = 0.5
local tooltipRefreshTimer = 1.0
local previousAttackPressed = false
local trackedThrow = nil
local lastEquippedThrow = nil
local syncedRuntimeSettings = nil
local classDynamicModifierRegistered = false
local legacyClassBonusMigrated = false
local armPendingThrow

local pendingThrow = {
    token = 0,
    releasedAt = NEVER,
    recordId = nil,
    weight = 0,
    throwingSkill = config.startLevel,
    effectiveSkill = config.startLevel,
    strength = 0,
    active = false,
}

local function getSetting(key, default)
    local value = settingsSection:get(key)
    if value == nil then return default end
    return value
end

local function debugEnabled()
    return getSetting('debugMessages', false)
end

local function debugLog(msg)
    if debugEnabled() then
        print('[Throwing!] ' .. msg)
    end
end

-- ─── Perk feedback overlay / independent shared stack ──────────────────────
-- Each skill mod ships this same small popup manager. A lightweight shared
-- heartbeat elects one active manager when multiple skill mods are installed,
-- but every mod can also run alone with no dependency on the others.

local FEEDBACK_DEFAULT_TEXT_RGB = { 255, 113, 24 }
local FEEDBACK_DEFAULT_SHADOW_RGB = { 139, 43, 39 }
local feedbackDuration = 1.35
local popupBusSection = storage.playerSection('SkillPerkPopupShared')
local POPUP_MANAGER_ID = MODNAME
local POPUP_MANAGER_PRIORITY = 30
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

    msg = tostring(msg or '')
    if style == 2 then
        showStandardFeedbackMessage(msg)
        return
    end

    emitSkillPerkPopup(perkPopupPayload(msg))

    if debugEnabled() then
        print('[Throwing!] PERK FEEDBACK ' .. msg)
    end
end

local function showFeedback(msg)
    if not getSetting('showFeedback', false) then
        return
    end

    msg = tostring(msg or '')
    showStandardFeedbackMessage(msg)

    if debugEnabled() then
        print('[Throwing!] FEEDBACK ' .. msg)
    end
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function featureEnabled(key, default)
    return getSetting(key, default) and getSetting('enabled', true)
end

local function xpMultiplier()
    return math.max(0, getSetting('xpMultiplier', 100)) * 0.01
end

local function writePendingRuntime()
    core.sendGlobalEvent('Throwing_UpdatePendingThrow', {
        token = pendingThrow.token,
        releasedAt = pendingThrow.releasedAt,
        recordId = pendingThrow.recordId,
        weight = pendingThrow.weight,
        throwingSkill = pendingThrow.throwingSkill,
        effectiveSkill = pendingThrow.effectiveSkill,
        strength = pendingThrow.strength,
        active = pendingThrow.active,
        perksEnabled = getSetting('perksEnabled', true),
        criticalEnabled = getSetting('criticalEnabled', true),
        twinFlightEnabled = getSetting('twinFlightEnabled', true),
        bleedEnabled = getSetting('bleedEnabled', true),
        paralyzeEnabled = getSetting('paralyzeEnabled', true),
    })
    return true
end

local function syncRuntimeSettings(force)
    local state = {
        enabled = getSetting('enabled', true),
        quickThrowEnabled = getSetting('quickThrowEnabled', true),
        shortRangeBonusEnabled = getSetting('shortRangeBonusEnabled', true),
        perksEnabled = getSetting('perksEnabled', true),
        criticalEnabled = getSetting('criticalEnabled', true),
        twinFlightEnabled = getSetting('twinFlightEnabled', true),
        bleedEnabled = getSetting('bleedEnabled', true),
        paralyzeEnabled = getSetting('paralyzeEnabled', true),
        debugMessages = getSetting('debugMessages', false),
    }

    local changed = force or syncedRuntimeSettings == nil
    if not changed then
        for k, v in pairs(state) do
            if syncedRuntimeSettings[k] ~= v then
                changed = true
                break
            end
        end
    end

    if changed then
        core.sendGlobalEvent('Throwing_UpdateRuntimeSettings', state)
        syncedRuntimeSettings = state
    end
end

local function clearPendingThrow(skipRuntimeWrite)
    pendingThrow.releasedAt = NEVER
    pendingThrow.recordId = nil
    pendingThrow.weight = 0
    pendingThrow.throwingSkill = config.startLevel
    pendingThrow.effectiveSkill = config.startLevel
    pendingThrow.strength = 0
    pendingThrow.active = false

    if not skipRuntimeWrite then
        core.sendGlobalEvent('Throwing_ClearPendingThrow')
    end
end

local function pendingThrowIsRecent()
    if not pendingThrow.active or not pendingThrow.recordId then return false end
    return (core.getSimulationTime() - pendingThrow.releasedAt) <= config.pendingWindow
end

local function isThrownWeaponObject(weapon)
    if not weapon or not types.Weapon.objectIsInstance(weapon) then
        return false
    end
    local record = types.Weapon.record(weapon)
    return (record and record.type == types.Weapon.TYPE.MarksmanThrown) or false
end

local function getThrownWeaponInfo(weapon)
    if not isThrownWeaponObject(weapon) then return nil end
    local record = types.Weapon.record(weapon)
    if not record then return nil end
    return {
        recordId = record.id or weapon.recordId,
        weight = record.weight or 0,
    }
end

local function getEquippedWeapon()
    return types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
end

local function rememberEquippedThrown()
    local info = getThrownWeaponInfo(getEquippedWeapon())
    if info then
        lastEquippedThrow = info
        if not trackedThrow then
            trackedThrow = info
        end
    end
    return info
end

local function getTrackedThrowInfo()
    return trackedThrow or rememberEquippedThrown() or lastEquippedThrow
end

local function isThrownWeaponEquipped()
    return isThrownWeaponObject(getEquippedWeapon())
end

local function getPlayerClassRecord()
    local record = types.NPC.record(self)
    if not record or not record.class then return nil, nil end
    return record.class, types.NPC.classes.record(record.class)
end

local function getMarksmanStat()
    return types.NPC.stats.skills.marksman(self)
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

local function updateMarksmanSnapshot(stat)
    if not stat then return end

    local base = statNumber(stat.base)
    if marksmanNativeSnapshot == nil then
        -- If this is an old save with an already-applied delta but no snapshot,
        -- reconstruct the native value from the current stat and saved delta.
        marksmanNativeSnapshot = statNumber(stat.modified) - statNumber(appliedMarksmanDelta)
        marksmanSnapshotBase = base
        return
    end

    if marksmanSnapshotBase ~= nil and base ~= marksmanSnapshotBase then
        -- Preserve legitimate base-level changes that happen while the override
        -- is active, without treating Restore Skill effects as native growth.
        marksmanNativeSnapshot = statNumber(marksmanNativeSnapshot) + (base - marksmanSnapshotBase)
    end
    marksmanSnapshotBase = base

    if appliedMarksmanDelta ~= 0 then
        -- The previous restore-safe build restored the exact snapshot on
        -- unequip. That fixed Restore Skill overflow, but it could capture a
        -- Fortify Marksman item or enchantment that was removed while the
        -- thrown-weapon override was active, then write that Fortify value back
        -- as a permanent Marksman modifier.
        --
        -- Treat downward movement in the reconstructed native value as a real
        -- external change: expiring/removing Fortify Marksman gear, Damage Skill,
        -- or similar. Do not mirror upward movement here, because Restore Skill
        -- repairing our temporary negative modifier looks exactly like an upward
        -- native change and must not become permanent.
        local nativeCandidate = statNumber(stat.modified) - statNumber(appliedMarksmanDelta)
        if nativeCandidate < statNumber(marksmanNativeSnapshot) then
            marksmanNativeSnapshot = nativeCandidate
        end
    end
end

local function restoreMarksmanSnapshot(stat)
    if not stat then return false end

    local changed = false
    if marksmanNativeSnapshot ~= nil then
        updateMarksmanSnapshot(stat)

        local restoreTarget = statNumber(marksmanNativeSnapshot)
        if appliedMarksmanDelta ~= 0 then
            local nativeCandidate = statNumber(stat.modified) - statNumber(appliedMarksmanDelta)
            if nativeCandidate < restoreTarget then
                restoreTarget = nativeCandidate
            end
        end

        changed = applyStatTarget(stat, restoreTarget) or changed
    elseif appliedMarksmanDelta ~= 0 then
        -- Fallback for pre-fix saves that had a delta but no native snapshot.
        changed = applyStatTarget(stat, statNumber(stat.modified) - statNumber(appliedMarksmanDelta)) or changed
    end

    if appliedMarksmanDelta ~= 0 then changed = true end
    appliedMarksmanDelta = 0
    marksmanNativeSnapshot = nil
    marksmanSnapshotBase = nil
    return changed
end

local function skillIsRegistered()
    return I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID) ~= nil
end

local function getThrowingSkillLevel()
    if I.SkillFramework and skillIsRegistered() then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then return stat.modified end
    end
    return config.startLevel
end

local function getStrength()
    local stat = types.Actor.stats.attributes.strength(self)
    return (stat and stat.modified) or 0
end

local function getSpeedAttribute()
    local stat = types.Actor.stats.attributes.speed(self)
    return (stat and stat.modified) or 0
end

local function getEffectiveThrowingValue()
    -- Strict replacement model: thrown-weapon accuracy should be governed by
    -- Throwing only. Native Marksman must not carry over into thrown attacks.
    return clamp(getThrowingSkillLevel(), 0, config.effectiveMarksmanCap)
end

local function notifyAAM()
    if not (I and I.AAM and I.AAM.reportExternalModifiers) then return end
    if appliedMarksmanDelta ~= 0 then
        I.AAM.reportExternalModifiers(MODNAME, { marksman = appliedMarksmanDelta })
    else
        I.AAM.reportExternalModifiers(MODNAME, {})
    end
end

local function applyMarksmanOverride()
    local stat = getMarksmanStat()
    if not stat then return end

    local shouldReplace = getSetting('enabled', true)
        and getSetting('replaceMarksman', true)
        and isThrownWeaponEquipped()

    local changed = false
    if shouldReplace then
        -- Thrown weapon hit chance is still calculated by the engine's Marksman
        -- stat, so while a thrown weapon is equipped we temporarily offset
        -- Marksman to equal Throwing. This can be positive or negative: thrown
        -- attacks should use Throwing only, never whichever of Throwing/Marksman
        -- happens to be higher.
        --
        -- The native Marksman value is snapshotted and the stat is set to an
        -- exact target each tick. This prevents Restore Skill effects or growth
        -- mods from "repairing" the temporary negative modifier and making the
        -- bookkeeping drift into permanent Marksman bonuses. Cleanup uses a
        -- conservative native-value floor so Fortify Marksman gear or weapon
        -- enchantments that disappear during unequip are not restored as a
        -- permanent modifier.
        updateMarksmanSnapshot(stat)
        local nativeMarksman = statNumber(marksmanNativeSnapshot)
        local desiredDelta = getEffectiveThrowingValue() - nativeMarksman
        local target = nativeMarksman + desiredDelta
        changed = applyStatTarget(stat, target) or changed
        if desiredDelta ~= appliedMarksmanDelta then changed = true end
        appliedMarksmanDelta = desiredDelta
    else
        changed = restoreMarksmanSnapshot(stat) or changed
    end

    if changed then notifyAAM() end
end

local function getClassSpecializationBonus()
    if not types.Player.isCharGenFinished(self) then return 0 end
    local _, classRecord = getPlayerClassRecord()
    if classRecord and classRecord.specialization == 'stealth' then
        return CLASS_BONUS_AMOUNT
    end
    return 0
end

local function registerClassBonusModifier()
    if classDynamicModifierRegistered then return end
    if not (I.SkillFramework and I.SkillFramework.registerDynamicModifier and skillIsRegistered()) then return end

    I.SkillFramework.registerDynamicModifier(SKILL_ID, 'Throwing_ClassSpecializationBonus', getClassSpecializationBonus)
    classDynamicModifierRegistered = true
end

local function migrateLegacyClassBonus()
    if legacyClassBonusMigrated then return end
    if not (I.SkillFramework and I.SkillFramework.getSkillStat and skillIsRegistered()) then return end

    if classBonusState.applied and classBonusState.amount > 0 then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then
            stat.base = math.max(0, (stat.base or 0) - classBonusState.amount)
        end
    end

    classBonusState.applied = false
    classBonusState.amount = 0
    legacyClassBonusMigrated = true
end

local function reconcileClassBonus()
    migrateLegacyClassBonus()
    registerClassBonusModifier()
end


local function skillT(skill, unlock)
    return clamp((skill - unlock) / math.max(1, 100 - unlock), 0, 1)
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

local function criticalChance(skill)
    local p = config.perks.critical
    if skill < p.level then return 0 end
    return p.chance or 0.05
end

local function twinFlightChance(skill)
    local p = config.perks.twinFlight
    return lerp(p.chanceAtUnlock, p.chanceAt100, skillT(skill, p.level))
end

local function bleedChance(skill)
    local p = config.perks.bleed
    return lerp(p.chanceAtUnlock, p.chanceAt100, skillT(skill, p.level))
end

local function paralyzeChance(skill)
    local p = config.perks.paralyze
    return lerp(p.chanceAtUnlock, p.chanceAt100, skillT(skill, p.level))
end

local function paralyzeDuration(skill)
    local p = config.perks.paralyze
    return p.baseDuration + math.floor(lerp(0, p.bonusDurationAt100, skillT(skill, p.level)))
end

local function shortRangeDamageBonus(distance)
    if distance == nil then return 0 end
    local full = config.combat.shortRangeFullDistance
    local maxd = config.combat.shortRangeMaxDistance
    if distance <= full then
        return config.combat.shortRangeBonusAtFull
    end
    if distance >= maxd then
        return 0
    end
    local t = 1 - ((distance - full) / math.max(1, maxd - full))
    return config.combat.shortRangeBonusAtFull * clamp(t, 0, 1)
end

local function throwWindupSpeedMultiplier(skill, speed, weight)
    local quickness = clamp(((skill * 0.7) + (speed * 0.3)) / 100, 0, 1)
    local base = lerp(config.combat.throwWindupSpeedAt0, config.combat.throwWindupSpeedAt100, quickness)
    local weightPenalty = clamp((weight or 0) / config.combat.heavyWeightThreshold, 0, 1) * config.combat.throwWindupWeightPenalty
    return math.max(1.0, base - weightPenalty)
end

local function isAttackWindup(options)
    if not options then return false end
    local stop = options.stopkey or ''
    return #stop > 10 and stop.sub(stop, #stop - 10) == ' max attack'
end

local function percent(value)
    return string.format('%.0f%%', (value or 0) * 100)
end

local function formatDistance(value)
    return string.format('%.0f', tonumber(value or 0) or 0)
end

local function perkSummaryLine(skill, perkId)
    local perks = config.perks
    if perkId == 'critical' then
        local p = perks.critical
        local active = skill >= p.level
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.level)
        return prefix .. string.format('Critical: %s chance to deal %0.2fx damage.', percent(criticalChance(skill)), p.damageMultiplier)
    elseif perkId == 'twinFlight' then
        local p = perks.twinFlight
        local active = skill >= p.level
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.level)
        return prefix .. string.format('Double Tap: %s chance to deal %0.2fx throw damage.', percent(twinFlightChance(skill)), p.damageMultiplier)
    elseif perkId == 'bleed' then
        local p = perks.bleed
        local active = skill >= p.level
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.level)
        return prefix .. string.format('Bleed: %s chance to inflict %d-%d damage per second for %ds.', percent(bleedChance(skill)), p.magnitudeMin, p.magnitudeMax, p.duration)
    elseif perkId == 'paralyze' then
        local p = perks.paralyze
        local active = skill >= p.level
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.level)
        return prefix .. string.format('Paralyze: %s chance to paralyze for %ds.', percent(paralyzeChance(skill)), paralyzeDuration(skill))
    end
    return nil
end

local lastTooltipText = nil

local PERK_SETTINGS = {
    critical = 'criticalEnabled',
    twinFlight = 'twinFlightEnabled',
    bleed = 'bleedEnabled',
    paralyze = 'paralyzeEnabled',
}

local function perkEnabled(perkId)
    if not getSetting('perksEnabled', true) then return false end
    local key = PERK_SETTINGS[perkId]
    if not key then return true end
    return getSetting(key, true)
end

local function buildSkillDescription()
    local skill = getThrowingSkillLevel()
    local showMechanicTooltips = getSetting('showMechanicTooltips', true)
    local showPerkTooltips = getSetting('showPerkTooltips', true)
    local unlockedOnly = getSetting('tooltipUnlockedOnly', false)

    local perkOrder = {
        { id = 'critical', level = config.perks.critical.level },
        { id = 'twinFlight', level = config.perks.twinFlight.level },
        { id = 'bleed', level = config.perks.bleed.level },
        { id = 'paralyze', level = config.perks.paralyze.level },
    }

    local lines = {
        'Governs your effectiveness with thrown weapons.',
        '',
        string.format('Current Throwing: %d', math.floor(skill)),
    }

    if showMechanicTooltips then
        table.insert(lines, string.format('Thrown wind-up speed: %s (up to %s faster).', getSetting('quickThrowEnabled', true) and 'enabled' or 'disabled', percent(throwWindupSpeedMultiplier(skill, getSpeedAttribute(), 0) - 1)))
        table.insert(lines, string.format('Short-range bonus: %s (up to %s extra damage at close range).', getSetting('shortRangeBonusEnabled', true) and 'enabled' or 'disabled', percent(config.combat.shortRangeBonusAtFull)))
    end

    table.insert(lines, '')

    local perkLines = {}
    if showPerkTooltips then
        for _, perk in ipairs(perkOrder) do
            if perkEnabled(perk.id) and ((not unlockedOnly) or skill >= perk.level) then
                local line = perkSummaryLine(skill, perk.id)
                if line then table.insert(perkLines, line) end
            end
        end

        if unlockedOnly and #perkLines == 0 then
            local nextPerk = nil
            for _, perk in ipairs(perkOrder) do
                if perkEnabled(perk.id) and skill < perk.level then
                    nextPerk = perk
                    break
                end
            end
            if nextPerk then
                table.insert(perkLines, string.format('No perks unlocked yet. Next unlock at %d Throwing.', nextPerk.level))
                table.insert(perkLines, perkSummaryLine(skill, nextPerk.id))
            else
                table.insert(perkLines, 'All remaining Throwing perks are disabled in settings.')
            end
        end
    end

    for _, line in ipairs(perkLines) do
        table.insert(lines, line)
    end

    return table.concat(lines, '\n')
end


local function refreshSkillDescription(force)
    if not I.SkillFramework or not skillIsRegistered() then return end
    local description = buildSkillDescription()
    if not force and description == lastTooltipText then
        return
    end
    I.SkillFramework.modifySkill(SKILL_ID, {
        description = description,
    })
    lastTooltipText = description
end

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if not featureEnabled('quickThrowEnabled', true) then return end
    if not isThrownWeaponEquipped() then return end
    if not isAttackWindup(options) then return end

    local info = getThrownWeaponInfo(getEquippedWeapon()) or {}
    local speed = throwWindupSpeedMultiplier(getThrowingSkillLevel(), getSpeedAttribute(), info.weight or 0)
    options.speed = (options.speed or 1.0) * speed
end)

I.AnimationController.addTextKeyHandler('throwweapon', function(_, key)
    local equippedInfo = rememberEquippedThrown()

    if key == 'shoot min hit' then
        local info = equippedInfo or getTrackedThrowInfo()
        if info then
            armPendingThrow(info)
        else
            debugLog('Throw release key seen but no throwable info was available')
        end
    elseif key == 'shoot follow stop' or key == 'unequip start' then
        trackedThrow = nil
    end
end)

local function tryRegisterSkill()
    if not I.SkillFramework then
        debugLog('Skill Framework not found')
        return false
    end

    hasSkillFramework = true

    if skillIsRegistered() then
        return true
    end

    I.SkillFramework.registerSkill(SKILL_ID, {
        name = 'Throwing',
        description = 'With the throwing skill, one is more effective with ranged weapons like throwing stars, knives, and darts.',
        attribute = 'speed',
        specialization = I.SkillFramework.SPECIALIZATION.Stealth,
        startLevel = config.startLevel,
        maxLevel = config.maxLevel,
        skillGain = {
            hit = config.xp.hit,
            crit = config.xp.crit,
            heavyHit = config.xp.heavyHit,
        },
        statsWindowProps = {
            subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Combat,
            shortenedName = 'Throwing',
            visible = true,
        },
        icon = {
            bgr = 'icons/SkillFramework/stealth_blank.dds',
            fgr = 'icons/Throwing/throwing.dds',
            bgrColor = util.color.rgb(1, 1, 1),
            fgrColor = util.color.rgb(0.95, 0.95, 0.95),
        },
    })

    I.SkillFramework.registerRaceModifier(SKILL_ID, 'khajiit', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'wood elf', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'redguard', 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'dark elf', 5)

    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Bm_Naga', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Cathay', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Cathay-raht', 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Dagi-raht', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Ohmes', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Ohmes-raht', 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Els_Suthay', 10)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Pya_SeaElf', 5)
    I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Yok_Duadri', 5)

    -- Skill books — thematic Morag Tong / assassination lore, not vanilla Marksman books
    I.SkillFramework.registerSkillBook('bk_brothersofdarkness', SKILL_ID)
    I.SkillFramework.registerSkillBook('bk_chroniclesofnchuleft', SKILL_ID)
    I.SkillFramework.registerSkillBook('bk_blackglove', SKILL_ID)

    debugLog('Throwing skill registered (governed by Speed)')
    if skillIsRegistered() then
        refreshSkillDescription(true)
    end
    return skillIsRegistered()
end

local function trainingUseType(weight)
    if (weight or 0) >= config.xp.heavyWeight then
        return 'heavyHit'
    end
    return 'hit'
end

local function trainingScale(weight, strength)
    local strengthValue = strength or getStrength()
    local weightT = clamp(((weight or 0) - 1) / 11, 0, 1)
    local strengthT = clamp(strengthValue / 100, 0, 1)
    return clamp(1.0 + weightT * 0.25 - strengthT * 0.10, 0.85, 1.25)
end

armPendingThrow = function(info)
    pendingThrow.token = pendingThrow.token + 1
    pendingThrow.releasedAt = core.getSimulationTime()
    pendingThrow.recordId = info.recordId
    pendingThrow.weight = info.weight or 0
    pendingThrow.throwingSkill = getThrowingSkillLevel()
    pendingThrow.effectiveSkill = getEffectiveThrowingValue()
    pendingThrow.strength = getStrength()
    pendingThrow.active = true
    writePendingRuntime()

    debugLog(string.format(
        'Armed pending throw token=%d record=%s weight=%.2f throw=%d effective=%d strength=%d',
        pendingThrow.token,
        tostring(pendingThrow.recordId),
        pendingThrow.weight,
        pendingThrow.throwingSkill,
        pendingThrow.effectiveSkill,
        pendingThrow.strength
    ))

    if featureEnabled('quickThrowEnabled', true) and getSetting('debugMessages', false) then
        local speedMult = throwWindupSpeedMultiplier(pendingThrow.throwingSkill, getSpeedAttribute(), pendingThrow.weight)
        if (speedMult - 1.0) >= config.combat.throwWindupFeedbackThreshold then
            debugLog(string.format('Throw wind-up multiplier x%.2f', speedMult))
        end
    end
end

local function updateThrowTracking()
    local attackPressed = self.controls and self.controls.attack or false
    local info = nil

    -- Avoid record/GRIP-style weapon checks every frame while idle. During
    -- actual attack wind-up, or immediately after attack release, keep the
    -- tracking path responsive.
    if attackPressed or previousAttackPressed or trackedThrow then
        info = rememberEquippedThrown()
    end

    if attackPressed and info and not trackedThrow then
        trackedThrow = info
        debugLog(string.format('Tracking throw wind-up for %s', tostring(info.recordId)))
    elseif not attackPressed and not info then
        trackedThrow = nil
    end

    previousAttackPressed = attackPressed
end

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if not getSetting('enabled', true) then return end
    if not I.SkillFramework or not skillIsRegistered() then return end
    if skillId ~= 'marksman' then return end
    if not params or params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit then return end

    local handledByPending = pendingThrowIsRecent()
    local fallbackInfo = handledByPending and pendingThrow or getThrownWeaponInfo(getEquippedWeapon())
    if not fallbackInfo or not fallbackInfo.recordId then return end

    I.SkillFramework.skillUsed(SKILL_ID, {
        useType = trainingUseType(fallbackInfo.weight),
        scale = trainingScale(fallbackInfo.weight, fallbackInfo.strength) * xpMultiplier(),
        redirectedFrom = skillId,
        weaponRecordId = fallbackInfo.recordId,
    })

    debugLog(string.format(
        'Redirected marksman XP to Throwing for %s (weight %.2f, pending=%s)',
        tostring(fallbackInfo.recordId),
        fallbackInfo.weight or 0,
        tostring(handledByPending)
    ))

    return false
end)

local function onResolvedHit(data)
    if not I.SkillFramework or not skillIsRegistered() then return end
    if not data or not data.weaponRecordId then return end

    if data.didCrit then
        I.SkillFramework.skillUsed(SKILL_ID, { useType = 'crit', scale = xpMultiplier() })
    end

    local perkMessages = {}
    local hideSensory = shouldSuppressSensoryPopups()
    local function addPerkMessage(text, hasSensoryCue)
        if hasSensoryCue and hideSensory then return end
        table.insert(perkMessages, text)
    end
    if data.didCrit then
        addPerkMessage(config.feedback.critical, true)
    end
    if data.procTwin then
        addPerkMessage(config.feedback.twinFlight, true)
    end
    if data.procBleed then
        addPerkMessage(config.feedback.bleed, true)
    end
    if data.procParalyze then
        addPerkMessage(config.feedback.paralyze, true)
    end
    if #perkMessages > 0 then
        showPerkFeedback(table.concat(perkMessages, ' | '))
    end

    if getSetting('showFeedback', false) then
        local messages = {}
        local shortRangeBonus = tonumber(data.shortRangeBonus or 0) or 0
        if shortRangeBonus >= config.combat.shortRangeFeedbackThreshold then
            table.insert(messages, string.format('Close +%s @%s', percent(shortRangeBonus), formatDistance(data.distance)))
        end
        local damageText = string.format('Dmg %.2f', tonumber(data.damage or 0) or 0)
        table.insert(messages, damageText)
        if #messages > 0 then
            showFeedback(table.concat(messages, ' | '))
        elseif debugEnabled() then
            showFeedback(damageText)
        end
    end

    if data.token and data.token == pendingThrow.token then
        clearPendingThrow()
    end

    debugLog(string.format(
        'Resolved throw token=%s crit=%s twin=%s bleed=%s paralyze=%s damage=%.2f base=%.2f charge=%.2f->%.2f floor=%.2f distance=%.0f closeBonus=%s',
        tostring(data.token),
        tostring(data.didCrit),
        tostring(data.procTwin),
        tostring(data.procBleed),
        tostring(data.procParalyze),
        tonumber(data.damage or 0) or 0,
        tonumber(data.baseDamageSource or 0) or 0,
        tonumber(data.chargeStrength or 0) or 0,
        tonumber(data.effectiveChargeStrength or 0) or 0,
        tonumber(data.quickThrowFloor or 0) or 0,
        tonumber(data.distance or 0) or 0,
        percent(tonumber(data.shortRangeBonus or 0) or 0)
    ))
end

local function onUpdate(dt)
    updatePopupManager(dt)
    dt = tonumber(dt) or 0

    if not skillIsRegistered() then
        tryRegisterSkill()
        if not skillIsRegistered() then return end
    end

    local weapon = getEquippedWeapon()
    local weaponId = weapon and weapon.recordId or nil
    local weaponChanged = weaponId ~= previousWeaponId
    previousWeaponId = weaponId

    updateThrowTracking()

    settingsSyncTimer = settingsSyncTimer + dt
    if settingsSyncTimer >= 0.5 then
        syncRuntimeSettings(false)
        while settingsSyncTimer >= 0.5 do
            settingsSyncTimer = settingsSyncTimer - 0.5
        end
    end

    tooltipRefreshTimer = tooltipRefreshTimer + dt
    if tooltipRefreshTimer >= 1.0 then
        refreshSkillDescription(false)
        while tooltipRefreshTimer >= 1.0 do
            tooltipRefreshTimer = tooltipRefreshTimer - 1.0
        end
    end

    if pendingThrow.active and not pendingThrowIsRecent() then
        debugLog(string.format('Expired pending throw token=%d', pendingThrow.token))
        clearPendingThrow()
    end

    gameplayUpdateTimer = gameplayUpdateTimer + dt
    if not weaponChanged and gameplayUpdateTimer < 0.25 then return end
    while gameplayUpdateTimer >= 0.25 do
        gameplayUpdateTimer = gameplayUpdateTimer - 0.25
    end

    reconcileClassBonus()
    applyMarksmanOverride()
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

local function getThrowingSkillStat()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat) then return nil end
    return I.SkillFramework.getSkillStat(SKILL_ID)
end

local function addThrowingSkill(amount)
    local stat = getThrowingSkillStat()
    if not stat then return nil end
    stat.base = math.max(0, math.min(config.maxLevel, (stat.base or 0) + amount))
    return stat
end

local function setThrowingSkill(target)
    local stat = getThrowingSkillStat()
    if not stat then return nil end
    local modifier = stat.modifier or 0
    local clamped = math.max(0, math.min(config.maxLevel, target))
    stat.base = math.max(0, clamped - modifier)
    return stat
end

local function getThrowingPerkSummary()
    local skill = getThrowingSkillLevel()
    local perkList = {
        { id = 'critical', name = 'Critical', level = config.perks.critical.level },
        { id = 'twinFlight', name = 'Twin Flight', level = config.perks.twinFlight.level },
        { id = 'bleed', name = 'Bleed', level = config.perks.bleed.level },
        { id = 'paralyze', name = 'Paralyze', level = config.perks.paralyze.level },
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

local function clearTrackedModifiers()
    local changed = restoreMarksmanSnapshot(getMarksmanStat())
    if changed then notifyAAM() end
    return changed
end

local function setMarksmanModifiedValue(target)
    local stat = getMarksmanStat()
    if not stat then return false end
    stat.modifier = statNumber(target) - statNumber(stat.base)
    appliedMarksmanDelta = 0
    marksmanNativeSnapshot = nil
    marksmanSnapshotBase = nil
    notifyAAM()
    return true
end

local function onConsoleCommand(mode, command, selectedObject)
    local trimmed = tostring(command or ''):match('^%s*(.-)%s*$') or ''
    local root, rest = trimmed:match('^(%S+)%s*(.-)$')
    if root ~= 'throwing' then return end

    if not (I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID)) then
        consolePrintError('Throwing skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: throwing <amount> | throwing set <value> | throwing perk | throwing repair | throwing repair marksman <value>')
        return true
    end

    local repairMarksmanValue = rest:match('^repair%s+marksman%s+(-?%d+)$')
    if repairMarksmanValue then
        if setMarksmanModifiedValue(tonumber(repairMarksmanValue)) then
            consolePrintInfo(string.format('Marksman modified value repaired to %d. Re-equip the thrown weapon if needed.', tonumber(repairMarksmanValue)))
        else
            consolePrintError('Unable to access Marksman stat.')
        end
        return true
    end

    if rest == 'repair' or rest == 'clear' then
        clearTrackedModifiers()
        consolePrintInfo('Cleared Throwing temporary Marksman modifier. Re-equip the thrown weapon to reapply the current override.')
        return true
    end

    if rest == 'perk' or rest == 'status' then
        local skill, current, nextPerk = getThrowingPerkSummary()
        if nextPerk then
            consolePrintInfo(string.format('Throwing: %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
        else
            consolePrintInfo(string.format('Throwing: %d | current perk: %s | all perks unlocked', skill, current))
        end
        return true
    end

    local setValue = rest:match('^set%s+(-?%d+)$')
    if setValue then
        local stat = setThrowingSkill(tonumber(setValue))
        if not stat then
            consolePrintError('Unable to access Throwing stat.')
        else
            local skill, current, nextPerk = getThrowingPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Throwing set to %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Throwing set to %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    local addValue = rest:match('^([+-]?%d+)$')
    if addValue then
        local stat = addThrowingSkill(tonumber(addValue))
        if not stat then
            consolePrintError('Unable to access Throwing stat.')
        else
            local skill, current, nextPerk = getThrowingPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Throwing is now %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Throwing is now %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    consolePrintError('Bad syntax. Try: throwing help')
    return true
end

local function onLoad(data)
    resetPopupRegistryOnce()
    registerPopupManagerCandidate()
    tryRegisterSkill()
    legacyClassBonusMigrated = false
    classBonusState.applied = data and data.classBonusApplied or false
    classBonusState.classId = data and data.classBonusClassId or nil
    classBonusState.amount = data and data.classBonusAmount or 0
    appliedMarksmanDelta = (data and tonumber(data.appliedMarksmanDelta)) or 0
    marksmanNativeSnapshot = (data and tonumber(data.marksmanNativeSnapshot)) or nil
    marksmanSnapshotBase = (data and tonumber(data.marksmanSnapshotBase)) or nil
    notifyAAM()
    previousWeaponId = nil
    previousAttackPressed = false
    trackedThrow = nil
    lastEquippedThrow = nil
    gameplayUpdateTimer = 0.25
    settingsSyncTimer = 0.5
    tooltipRefreshTimer = 1.0
    lastTooltipText = nil
    syncedRuntimeSettings = nil
    clearPendingThrow(false)
    syncRuntimeSettings(true)
    refreshSkillDescription(true)
end

local function onSave()
    return {
        classBonusApplied = false,
        classBonusClassId = nil,
        classBonusAmount = 0,
        appliedMarksmanDelta = appliedMarksmanDelta,
        marksmanNativeSnapshot = marksmanNativeSnapshot,
        marksmanSnapshotBase = marksmanSnapshotBase,
    }
end

return {
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onInit = onLoad,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        Throwing_ResolvedHit = onResolvedHit,
        SkillPerkPopup_Show = onSkillPerkPopupShow,
    },
}
