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
local previousWeaponId = nil
local throttleTimer = 0
local previousAttackPressed = false
local trackedThrow = nil
local lastEquippedThrow = nil
local syncedRuntimeSettings = nil
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

local feedbackElement = nil
local feedbackExpiresAt = 0
local feedbackDuration = 1.35

local function destroyFeedbackElement()
    if feedbackElement then
        feedbackElement:destroy()
        feedbackElement = nil
    end
end

local function ensureFeedbackElement()
    if feedbackElement then return feedbackElement end
    feedbackElement = ui.create({
        layer = 'Notification',
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 0.82),
            anchor = util.vector2(0.5, 0.5),
            text = '',
            textSize = 18,
            visible = false,
        },
    })
    return feedbackElement
end

local function updateFeedbackOverlay(msg)
    local element = ensureFeedbackElement()
    element.layout.props.text = tostring(msg or '')
    element.layout.props.visible = true
    element:update()
    feedbackExpiresAt = core.getSimulationTime() + feedbackDuration
end

local function updateFeedbackVisibility()
    if not feedbackElement then return end
    local enabled = getSetting('showFeedback', false)
    local active = enabled and core.getSimulationTime() < feedbackExpiresAt
    if feedbackElement.layout.props.visible ~= active then
        feedbackElement.layout.props.visible = active
        feedbackElement:update()
    end
    if not enabled and feedbackElement then
        destroyFeedbackElement()
    end
end

local function showFeedback(msg)
    if not getSetting('showFeedback', false) then
        updateFeedbackVisibility()
        return
    end

    msg = tostring(msg or '')

    local shown = false
    local ok = pcall(ui.showMessage, msg, { showInDialogue = false })
    if ok then
        shown = true
    else
        ok = pcall(ui.showMessage, msg)
        if ok then
            shown = true
        else
            ok = pcall(updateFeedbackOverlay, msg)
            if ok then
                shown = true
            end
        end
    end

    if not shown and debugEnabled() then
        print('[Throwing!] FEEDBACK fallback failed for: ' .. msg)
    end

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
    })
    return true
end

local function syncRuntimeSettings(force)
    local state = {
        enabled = getSetting('enabled', true),
        quickThrowEnabled = getSetting('quickThrowEnabled', true),
        shortRangeBonusEnabled = getSetting('shortRangeBonusEnabled', true),
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

local function getMarksmanNativeModified()
    local stat = getMarksmanStat()
    return ((stat and stat.modified) or 0) - appliedMarksmanDelta
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
    local nativeMarksman = math.max(0, getMarksmanNativeModified())
    local throwing = getThrowingSkillLevel()
    local carry = math.min(config.marksmanTransferCap, math.floor(nativeMarksman * config.marksmanTransferFactor))
    return clamp(throwing + carry, 0, config.effectiveMarksmanCap)
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

    local nativeMarksman = math.max(0, getMarksmanNativeModified())
    local desiredDelta = 0

    if shouldReplace then
        -- Do not ever depress the displayed/active Marksman stat.
        -- Throwing may supplement ranged accuracy, but should not punish
        -- characters who already have higher native Marksman.
        desiredDelta = math.max(0, getEffectiveThrowingValue() - nativeMarksman)
    end

    if desiredDelta ~= appliedMarksmanDelta then
        stat.modifier = stat.modifier + (desiredDelta - appliedMarksmanDelta)
        appliedMarksmanDelta = desiredDelta
        notifyAAM()
    end
end

local function reconcileClassBonus()
    if not I.SkillFramework or not skillIsRegistered() or not types.Player.isCharGenFinished(self) then return end

    local currentClassId, classRecord = getPlayerClassRecord()
    if not currentClassId or not classRecord then return end

    local desiredAmount = 0
    if classRecord.specialization == 'stealth' then
        desiredAmount = CLASS_BONUS_AMOUNT
    end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return end

    if classBonusState.applied and classBonusState.amount > 0 then
        if classBonusState.classId ~= currentClassId or desiredAmount ~= classBonusState.amount then
            stat.base = stat.base - classBonusState.amount
            debugLog(string.format('Removed class bonus %d from previous class %s', classBonusState.amount, tostring(classBonusState.classId)))
            classBonusState.applied = false
            classBonusState.amount = 0
        end
    end

    if desiredAmount > 0 and (not classBonusState.applied or classBonusState.classId ~= currentClassId) then
        stat.base = stat.base + desiredAmount
        classBonusState.applied = true
        classBonusState.classId = currentClassId
        classBonusState.amount = desiredAmount
        debugLog(string.format('Applied stealth class bonus +%d (class: %s)', desiredAmount, tostring(classRecord.name or currentClassId)))
    else
        classBonusState.classId = currentClassId
        if desiredAmount == 0 then
            classBonusState.applied = false
            classBonusState.amount = 0
        end
    end
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
    local info = rememberEquippedThrown()

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
        scale = trainingScale(fallbackInfo.weight, fallbackInfo.strength),
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
        I.SkillFramework.skillUsed(SKILL_ID, { useType = 'crit' })
    end

    if getSetting('showFeedback', false) then
        local messages = {}
        local shortRangeBonus = tonumber(data.shortRangeBonus or 0) or 0
        if shortRangeBonus >= config.combat.shortRangeFeedbackThreshold then
            table.insert(messages, string.format('Close +%s @%s', percent(shortRangeBonus), formatDistance(data.distance)))
        end
        if data.didCrit then
            table.insert(messages, 'Crit')
        end
        if data.procTwin then
            table.insert(messages, 'Twin')
        end
        if data.procBleed then
            table.insert(messages, 'Bleed')
        end
        if data.procParalyze then
            table.insert(messages, 'Paralyze')
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
    if not skillIsRegistered() then
        tryRegisterSkill()
        if not skillIsRegistered() then return end
    end

    syncRuntimeSettings(false)
    updateFeedbackVisibility()

    reconcileClassBonus()
    updateThrowTracking()
    refreshSkillDescription(false)

    if pendingThrow.active and not pendingThrowIsRecent() then
        debugLog(string.format('Expired pending throw token=%d', pendingThrow.token))
        clearPendingThrow()
    end

    local weapon = getEquippedWeapon()
    local weaponId = weapon and weapon.recordId or nil
    local weaponChanged = weaponId ~= previousWeaponId
    previousWeaponId = weaponId

    if not weaponChanged and dt > 0 then
        throttleTimer = throttleTimer + dt
        if throttleTimer < 0.25 then return end
        throttleTimer = 0
    end

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

local function onConsoleCommand(mode, command, selectedObject)
    local trimmed = tostring(command or ''):match('^%s*(.-)%s*$') or ''
    local root, rest = trimmed:match('^(%S+)%s*(.-)$')
    if root ~= 'throwing' then return end

    if not (I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID)) then
        consolePrintError('Throwing skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: throwing <amount> | throwing set <value> | throwing perk')
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
    tryRegisterSkill()
    classBonusState.applied = data and data.classBonusApplied or false
    classBonusState.classId = data and data.classBonusClassId or nil
    classBonusState.amount = data and data.classBonusAmount or 0
    appliedMarksmanDelta = data and data.appliedMarksmanDelta or 0
    notifyAAM()
    previousWeaponId = nil
    previousAttackPressed = false
    trackedThrow = nil
    lastEquippedThrow = nil
    throttleTimer = 0
    lastTooltipText = nil
    syncedRuntimeSettings = nil
    clearPendingThrow(false)
    syncRuntimeSettings(true)
    updateFeedbackVisibility()
    refreshSkillDescription(true)
end

local function onSave()
    return {
        classBonusApplied = classBonusState.applied,
        classBonusClassId = classBonusState.classId,
        classBonusAmount = classBonusState.amount,
        appliedMarksmanDelta = appliedMarksmanDelta,
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
    },
}
