--[[
    Toxicology! — Player Script (init.lua)

    Responsibilities:
      * Register the Toxicology skill (via Skill Framework)
      * Race modifiers (including Tamriel Data races)
      * Class bonus (+10 for Stealth-specialisation classes)
      * Skill books (Poison Song VI, Special Flora of Tamriel)
      * Show the apply-or-drink confirmation dialog
      * Display tooltip overlay for poisoned weapons in inventory
      * Show HUD indicator when wielding a poisoned weapon
      * Fire skillUsed events for XP progression
      * Register Inventory Extender tooltip modifier if IE is present
]]

local core    = require('openmw.core')
local I       = require('openmw.interfaces')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local ui      = require('openmw.ui')
local util    = require('openmw.util')
local input   = require('openmw.input')

local config = require('scripts.toxicology.config')

local MODNAME = 'Toxicology'
local SKILL_ID = config.skillId

-- ─── Settings helpers ───────────────────────────────────────────────────────

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

-- Global scripts can't read playerSection. We send our settings to global.lua
-- via the Toxicology_UpdateRuntimeSettings event; global writes them to its
-- Runtime_Toxicology section. Same pattern Throwing! uses.

-- Per-weapon poison data lives in this globalSection, written by global.lua
-- and read here for tooltip/HUD display. (ItemData doesn't accept custom
-- properties, so we use our own keyed store.)
local weaponPoisonSection = storage.globalSection('Runtime_ToxicologyWeaponPoison')
local projectileRuntimeSection = storage.globalSection('Runtime_ToxicologyProjectile')

local THROWN_POISON_PREFIX = 'thrown:'
local WEAPON_POISON_NAMESPACE_KEY = '__activeNamespace'

local function liveWeaponPoisonStorageKey(key)
    if not key then return nil end
    local ns = weaponPoisonSection:get(WEAPON_POISON_NAMESPACE_KEY)
    if ns == nil then return nil end
    return tostring(ns) .. '|' .. tostring(key)
end

local TOXICOLOGY_ICON = 'icons/Toxicology/toxicology.dds'
local POISON_BADGE_ICON = 'icons/Toxicology/poison_badge.dds'
local INVENTORY_BADGE_NAME = 'ToxicologyPoisonBadge'
local VANILLA_INVENTORY_INDICATOR_NAME = 'ToxicologyVanillaInventoryIndicator'
local VANILLA_INVENTORY_INDICATOR_MAX_ROWS = 10

local function objectIsAvailable(obj)
    if not obj then return false end
    local ok, valid = pcall(function()
        if obj.isValid then return obj:isValid() end
        return true
    end)
    return ok and valid ~= false
end

local function safeWeaponRecord(item)
    if not objectIsAvailable(item) then return nil end
    local ok, isWeapon = pcall(types.Weapon.objectIsInstance, item)
    if not ok or not isWeapon then return nil end
    local okRec, rec = pcall(types.Weapon.record, item)
    if not okRec then return nil end
    return rec
end

local function safeObjectField(item, field)
    if not objectIsAvailable(item) then return nil end
    local ok, value = pcall(function() return item[field] end)
    if not ok then return nil end
    return value
end

local function isThrownWeaponObject(item)
    local rec = safeWeaponRecord(item)
    return rec and rec.type == types.Weapon.TYPE.MarksmanThrown
end

local function isProjectileWeaponType(weaponType)
    return weaponType == types.Weapon.TYPE.MarksmanThrown
        or weaponType == types.Weapon.TYPE.MarksmanBow
        or weaponType == types.Weapon.TYPE.MarksmanCrossbow
end

local function poisonStorageKey(item)
    local rec = safeWeaponRecord(item)
    if not rec then return nil end
    if rec.type == types.Weapon.TYPE.MarksmanThrown then
        local recordId = safeObjectField(item, 'recordId')
        if not recordId then return nil end
        return THROWN_POISON_PREFIX .. tostring(recordId)
    end
    return safeObjectField(item, 'id')
end

local function getWeaponPoisonData(item)
    local key = poisonStorageKey(item)
    local liveKey = liveWeaponPoisonStorageKey(key)
    if not liveKey then return nil end
    return weaponPoisonSection:get(liveKey)
end

-- All the keys global.lua cares about, grouped by their settings section.
-- The sync is one-way: player → global.
local SYNCED_KEYS = {
    { section = '',        key = 'enabled' },
    { section = '',        key = 'blockInCombat' },
    { section = '',        key = 'ignoreAlcoholPotions' },
    { section = '',        key = 'warnOverwrite' },
    { section = 'Skill',   key = 'xpOnApply' },
    { section = 'Skill',   key = 'xpOnStrike' },
    { section = 'Skill',   key = 'xpOnKill' },
    { section = 'Skill',   key = 'xpOnBrew' },
    { section = 'Skill',   key = 'xpMultiplier' },
    { section = 'Perks',   key = 'enableAllPerks' },
    { section = 'Perks',   key = 'enableMasterCoating' },
    { section = 'Perks',   key = 'enableEfficientCoating' },
    { section = 'Perks',   key = 'enableCompoundBlend' },
    { section = 'Perks',   key = 'enableToxicPrecision' },
    { section = 'Distribution', key = 'enableExistingPoisonDistribution' },
    { section = 'Distribution', key = 'distributeExistingPoisonsToContainers' },
    { section = 'Distribution', key = 'distributeExistingPoisonsToMerchants' },
    { section = 'Distribution', key = 'allowMixedEffectPoisons' },
    { section = 'Distribution', key = 'existingPoisonMerchantStock' },
    { section = 'Distribution', key = 'existingPoisonContainerChance' },
    { section = 'UI',      key = 'showTooltip' },
    { section = 'UI',      key = 'showHudIndicator' },
    { section = 'UI',      key = 'alchemyGatedTooltip' },
    { section = 'UI',      key = 'hitVfx' },
    { section = 'UI',      key = 'hitSound' },
    { section = 'UI',      key = 'showRangedCoatingSpentMessage' },
    { section = 'UI',      key = 'debugMessages' },
    { section = 'UI',      key = 'debugCombatMessages' },
    { section = 'UI',      key = 'debugDistributionMessages' },
    { section = 'UI',      key = 'debugUiMessages' },
    { section = 'UI',      key = 'debugXpMessages' },
    { section = 'UI',      key = 'debugActorMessages' },
    { section = 'UI',      key = 'debugIntegrationMessages' },
}


local lastSyncedSettingsPayload = nil

local function settingsPayloadChanged(payload)
    if not lastSyncedSettingsPayload then return true end
    for k, v in pairs(payload) do
        if lastSyncedSettingsPayload[k] ~= v then return true end
    end
    for k, _ in pairs(lastSyncedSettingsPayload) do
        if payload[k] == nil then return true end
    end
    return false
end

local function syncSettingsToGlobal(force)
    -- Player scripts can't WRITE to globalSection. Collect all settings
    -- into a table and send to global.lua which will perform the writes.
    local payload = {}
    for _, entry in ipairs(SYNCED_KEYS) do
        local value = settingSection(entry.section):get(entry.key)
        payload[entry.key] = value
    end
    if not force and not settingsPayloadChanged(payload) then return end
    core.sendGlobalEvent('Toxicology_UpdateRuntimeSettings', payload)
    lastSyncedSettingsPayload = payload
end

local function debugEnabled(category)
    if not readSetting('UI', 'debugMessages', false) then return false end
    if not category then return true end
    return readSetting('UI', category, false)
end

local function debugLog(msg, category)
    if debugEnabled(category) then
        print('[Toxicology!] ' .. tostring(msg))
    end
end

local projectileTokenCounter = 0
local previousAttackPressed = false

local function weaponHasActivePoisonData(data)
    return data and (data.poisonId ~= nil or data.layer2PoisonId ~= nil or data.layer3PoisonId ~= nil)
end


local function copyWeaponPoisonData(raw)
    if not raw then return nil end

    local function copySnapshot(s)
        if not s then return nil end
        local out = {}
        for pid, pr in pairs(s) do
            local effs = {}
            if pr.effects then
                for i = 1, #pr.effects do
                    local e = pr.effects[i]
                    effs[#effs + 1] = {
                        id                = e.id,
                        affectedAttribute = e.affectedAttribute,
                        affectedSkill     = e.affectedSkill,
                        magnitudeMin      = e.magnitudeMin,
                        magnitudeMax      = e.magnitudeMax,
                        duration          = e.duration,
                        range             = e.range,
                        area              = e.area,
                    }
                end
            end
            out[pid] = { name = pr.name, effects = effs }
        end
        return out
    end

    return {
        poisonId       = raw.poisonId,
        charges        = raw.charges,
        layer2PoisonId = raw.layer2PoisonId,
        layer2Charges  = raw.layer2Charges,
        layer3PoisonId = raw.layer3PoisonId,
        layer3Charges  = raw.layer3Charges,
        snapshot       = copySnapshot(raw.snapshot),
    }
end

local function getEquippedProjectileContext()
    local equipment = types.Actor.getEquipment(self)
    local weapon = equipment and equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    local rec = safeWeaponRecord(weapon)
    if not rec or not isProjectileWeaponType(rec.type) then return nil end

    local key = poisonStorageKey(weapon)
    if not key then return nil end
    local liveKey = liveWeaponPoisonStorageKey(key)
    local data = liveKey and weaponPoisonSection:get(liveKey) or nil

    return {
        weaponKey = key,
        recordId = safeObjectField(weapon, 'recordId'),
        weaponType = rec.type,
        weaponName = rec.name or 'weapon',
        poisonData = weaponHasActivePoisonData(data) and copyWeaponPoisonData(data) or nil,
    }
end

local function spendProjectilePoisonOnAttackStart(ctx)
    -- Ranged poison consumption is keyed to the attack button down-edge: the
    -- moment the player starts drawing a bow/crossbow or starts a thrown attack.
    -- This avoids relying on projectile Hit events, miss fallbacks, release edge
    -- timing, or animation text keys. One left-click draw/throw attempt spends
    -- exactly one coating charge from every active layer, whether the projectile
    -- later hits, misses, or is cancelled.
    if not readSetting('', 'enabled', true) then return end

    ctx = ctx or getEquippedProjectileContext()
    if not ctx then return end

    if not weaponHasActivePoisonData(ctx.poisonData) then
        -- A later unpoisoned ranged attack must not inherit a stale projectile
        -- snapshot from a previous poisoned shot.
        core.sendGlobalEvent('Toxicology_ClearProjectileRuntime', {
            reason = 'unpoisoned-ranged-attack-start',
        })
        return
    end

    projectileTokenCounter = projectileTokenCounter + 1
    local pending = {
        token = projectileTokenCounter,
        -- Kept as releasedAt for compatibility with the actor/global scripts;
        -- semantically this now means "attack started / draw began".
        releasedAt = core.getSimulationTime(),
        weaponKey = ctx.weaponKey,
        recordId = ctx.recordId,
        weaponType = ctx.weaponType,
        poisonData = ctx.poisonData,
    }

    -- Publish the pre-spend poison snapshot before spending the live coating;
    -- ranged Hit handlers use this snapshot so the projectile can still apply
    -- poison after the charge has already been deducted at draw/start time.
    core.sendGlobalEvent('Toxicology_UpdateProjectileRuntime', pending)
    core.sendGlobalEvent('Toxicology_ConsumeRangedAttack', {
        actor = self.object,
        token = pending.token,
        weaponKey = pending.weaponKey,
        recordId = pending.recordId,
        weaponType = pending.weaponType,
    })

    debugLog('Spent projectile poison on attack start token=' .. tostring(pending.token)
        .. ' key=' .. tostring(pending.weaponKey), 'debugCombatMessages')
end

local function isGameplayInputMode()
    -- I.UI.getMode() is nil during normal gameplay and non-nil while a UI mode
    -- such as dialogue, inventory, barter, journal, container, console, etc. is
    -- active. The Use action still reports mouse clicks in those modes, so the
    -- poison spend edge must be suppressed until the player is back in the world.
    local uiInterface = I and I.UI
    if not uiInterface then return true end

    if uiInterface.getMode then
        local ok, mode = pcall(uiInterface.getMode)
        if ok then return mode == nil end
    end

    local modes = uiInterface.modes
    if type(modes) == 'table' then
        return #modes == 0
    end

    return true
end

local function projectileUseActionPressedRaw()
    -- For the default attack binding, read the physical left mouse button state
    -- directly. The Boolean "Use" action can pulse once when a bow begins drawing
    -- and again when the shot is released, which spends two coatings for one
    -- arrow. isMouseButtonPressed(1) stays true for the whole draw and becomes
    -- false on release, giving one clean down-edge per shot/throw.
    if input.isMouseButtonPressed then
        local okMouse, mousePressed = pcall(input.isMouseButtonPressed, 1)
        if okMouse then return mousePressed == true end
    end

    -- Fallback for older API revisions where direct mouse state is unavailable.
    -- This preserves compatibility, but the mouse path above is the reliable path
    -- for the normal left-click bow/throwing flow.
    local ok, value = pcall(input.getBooleanActionValue, 'Use')
    if ok and value == true then return true end

    -- Compatibility with older API revisions where numeric ACTION constants were
    -- still the common way to read bindings.
    if input.ACTION and input.ACTION.Use and input.isActionPressed then
        local okLegacy, legacyValue = pcall(input.isActionPressed, input.ACTION.Use)
        if okLegacy and legacyValue == true then return true end
    end

    local controls = self.controls
    if controls and controls.use ~= nil then
        local noAttack = self.ATTACK_TYPE and self.ATTACK_TYPE.NoAttack or 0
        return controls.use ~= noAttack
    end

    return false
end

local function updateProjectileAttackStartConsumption()
    local attackPressed = projectileUseActionPressedRaw()

    if not isGameplayInputMode() then
        -- Keep the edge state synchronized while menus consume the click. This
        -- prevents a held menu click from spending a coating on the first frame
        -- after the menu closes.
        previousAttackPressed = attackPressed
        return
    end

    if attackPressed and not previousAttackPressed then
        spendProjectilePoisonOnAttackStart(getEquippedProjectileContext())
    end

    previousAttackPressed = attackPressed
end

local function xpMultiplier()
    local value = tonumber(readSetting('Skill', 'xpMultiplier', 100)) or 100
    if value < 0 then value = 0 end
    return value * 0.01
end

-- ─── Feedback overlay / independent shared popup stack ─────────────────────
-- Each skill mod ships this same small popup manager. A lightweight shared
-- heartbeat elects one active manager when multiple skill mods are installed,
-- but every mod can also run alone with no dependency on the others. The
-- standard-message toggle still applies only to Toxicology's own perk feedback.

local feedbackStyle = {
    textRgb = { 190, 0, 194 },
    shadowRgb = { 0, 77, 42 },
    stackBaseX = 0.5,
    stackBaseY = 0.72,
    stackAnchorX = 0.5,
    stackAnchorY = 0.5,
    stackSpacing = 0.045,
    stackLimit = 5,
    counter = 0,
    duration = 1.35,
    heartbeatTimer = 0,
    entries = {},
    popupBusSection = storage.playerSection('SkillPerkPopupShared'),
    managerId = 'Toxicology',
    managerPriority = 40,
    registryReset = false,
    knownManagers = {
        { id = 'Evasion', priority = 10 },
        { id = 'Staves', priority = 20 },
        { id = 'Throwing', priority = 30 },
        { id = 'Toxicology', priority = 40 },
    },
}

function feedbackStyle.clamp(value, default, minValue, maxValue)
    value = tonumber(value) or default
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function feedbackStyle.perkMessageStyle()
    local style = settingSection('UI'):get('perkMessageStyle')
    if style ~= nil then
        return feedbackStyle.clamp(style, 1, 0, 2)
    end
    local legacyShow = settingSection('UI'):get('showPerkFeedback')
    if legacyShow == false then return 0 end
    if readSetting('UI', 'useVanillaMessageBoxes', false) then return 2 end
    return 1
end

function feedbackStyle.perkPopupDetail()
    local detail = settingSection('UI'):get('perkPopupDetail')
    if detail ~= nil then
        return feedbackStyle.clamp(detail, 0, 0, 1)
    end
    return readSetting('UI', 'detailedPerkFeedback', false) and 1 or 0
end

function feedbackStyle.suppressSensoryPopups()
    return readSetting('UI', 'hideSensoryPerkPopups', false)
end

function feedbackStyle.popupColor(prefix, defaults)
    if feedbackStyle.clamp(readSetting('UI', 'popupColourPreset', 0), 0, 0, 1) < 1 then
        return defaults
    end
    return {
        feedbackStyle.clamp(readSetting('UI', prefix .. 'R', defaults[1]), defaults[1], 0, 255),
        feedbackStyle.clamp(readSetting('UI', prefix .. 'G', defaults[2]), defaults[2], 0, 255),
        feedbackStyle.clamp(readSetting('UI', prefix .. 'B', defaults[3]), defaults[3], 0, 255),
    }
end

function feedbackStyle.layoutForPosition(position)
    local p = feedbackStyle.clamp(position, 4, 0, 4)
    if p == 0 then return 0.04, 0.18, 0.0, 0.5 end
    if p == 1 then return 0.50, 0.18, 0.5, 0.5 end
    if p == 2 then return 0.50, 0.50, 0.5, 0.5 end
    if p == 3 then return 0.04, 0.72, 0.0, 0.5 end
    return 0.50, 0.72, 0.5, 0.5
end

function feedbackStyle.applyStackSettings(payload)
    payload = payload or {}
    feedbackStyle.stackLimit = feedbackStyle.clamp(payload.maxVisible, 5, 1, 10)
    feedbackStyle.stackBaseX, feedbackStyle.stackBaseY, feedbackStyle.stackAnchorX, feedbackStyle.stackAnchorY = feedbackStyle.layoutForPosition(payload.popupPosition)
end

function feedbackStyle.now()
    local ok, value = pcall(core.getRealTime)
    if ok and tonumber(value) then return tonumber(value) end
    return core.getSimulationTime()
end

function feedbackStyle.resetRegistryOnce()
    if feedbackStyle.registryReset then return end
    feedbackStyle.registryReset = true
    for _, candidate in ipairs(feedbackStyle.knownManagers) do
        feedbackStyle.popupBusSection:set('priority_' .. candidate.id, nil)
        feedbackStyle.popupBusSection:set('heartbeat_' .. candidate.id, nil)
    end
end

function feedbackStyle.registerCandidate()
    feedbackStyle.popupBusSection:set('priority_' .. feedbackStyle.managerId, feedbackStyle.managerPriority)
    feedbackStyle.popupBusSection:set('heartbeat_' .. feedbackStyle.managerId, feedbackStyle.now())
end

function feedbackStyle.electedManagerId()
    feedbackStyle.registerCandidate()
    local now = feedbackStyle.now()
    local bestId = feedbackStyle.managerId
    local bestPriority = feedbackStyle.managerPriority
    for _, candidate in ipairs(feedbackStyle.knownManagers) do
        local heartbeat = tonumber(feedbackStyle.popupBusSection:get('heartbeat_' .. candidate.id))
        local priority = tonumber(feedbackStyle.popupBusSection:get('priority_' .. candidate.id)) or candidate.priority
        if heartbeat and heartbeat <= now + 0.25 and now - heartbeat <= 5 then
            if not bestPriority or priority < bestPriority then
                bestId = candidate.id
                bestPriority = priority
            end
        end
    end
    return bestId
end

function feedbackStyle.rgb(r, g, b, defaults)
    defaults = defaults or { 255, 255, 255 }
    return util.color.rgb(
        feedbackStyle.clamp(r, defaults[1], 0, 255) / 255,
        feedbackStyle.clamp(g, defaults[2], 0, 255) / 255,
        feedbackStyle.clamp(b, defaults[3], 0, 255) / 255
    )
end

function feedbackStyle.color(prefix, defaults)
    return feedbackStyle.rgb(
        readSetting('UI', prefix .. 'R', defaults[1]),
        readSetting('UI', prefix .. 'G', defaults[2]),
        readSetting('UI', prefix .. 'B', defaults[3]),
        defaults
    )
end

function feedbackStyle.useStandardMessages()
    return feedbackStyle.perkMessageStyle() == 2
end

function feedbackStyle.showStandardMessage(msg)
    local ok = pcall(ui.showMessage, msg, { showInDialogue = false })
    if not ok then
        pcall(ui.showMessage, msg)
    end
end

function feedbackStyle.destroyEntry(index)
    local entry = feedbackStyle.entries[index]
    if entry and entry.element then
        entry.element:destroy()
    end
    table.remove(feedbackStyle.entries, index)
end

function feedbackStyle.destroyAll()
    for i = #feedbackStyle.entries, 1, -1 do
        feedbackStyle.destroyEntry(i)
    end
end

function feedbackStyle.reflow()
    local now = core.getSimulationTime()
    for i = #feedbackStyle.entries, 1, -1 do
        local entry = feedbackStyle.entries[i]
        if not entry or not entry.element or (entry.expiresAt and entry.expiresAt <= now) then
            feedbackStyle.destroyEntry(i)
        end
    end
    while #feedbackStyle.entries > feedbackStyle.stackLimit do
        feedbackStyle.destroyEntry(#feedbackStyle.entries)
    end
    for i, entry in ipairs(feedbackStyle.entries) do
        entry.element.layout.props.relativePosition = util.vector2(feedbackStyle.stackBaseX, feedbackStyle.stackBaseY + (i - 1) * feedbackStyle.stackSpacing)
        entry.element.layout.props.anchor = util.vector2(feedbackStyle.stackAnchorX, feedbackStyle.stackAnchorY)
        entry.element.layout.props.visible = true
        entry.element:update()
    end
end

function feedbackStyle.showCustom(payload)
    if type(payload) ~= 'table' then return end
    local text = tostring(payload.text or '')
    if text == '' then return end

    feedbackStyle.applyStackSettings(payload)
    feedbackStyle.reflow()
    feedbackStyle.counter = feedbackStyle.counter + 1

    local defaultText = type(payload.defaultTextRgb) == 'table' and payload.defaultTextRgb or feedbackStyle.textRgb
    local defaultShadow = type(payload.defaultShadowRgb) == 'table' and payload.defaultShadowRgb or feedbackStyle.shadowRgb
    local textColor = feedbackStyle.rgb(payload.textR, payload.textG, payload.textB, defaultText)
    local shadowColor = feedbackStyle.rgb(payload.shadowR, payload.shadowG, payload.shadowB, defaultShadow)
    local textSize = feedbackStyle.clamp(payload.textSize, 20, 10, 72)
    local duration = feedbackStyle.clamp(payload.duration, feedbackStyle.duration, 0.5, 10)

    local element = ui.create({
        layer = 'Notification',
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(feedbackStyle.stackBaseX, feedbackStyle.stackBaseY),
            anchor = util.vector2(feedbackStyle.stackAnchorX, feedbackStyle.stackAnchorY),
            text = text,
            textSize = textSize,
            textColor = textColor,
            textShadow = true,
            textShadowColor = shadowColor,
            visible = true,
        },
    })

    table.insert(feedbackStyle.entries, 1, {
        element = element,
        expiresAt = core.getSimulationTime() + duration,
    })
    feedbackStyle.reflow()
end

function feedbackStyle.update(dt)
    feedbackStyle.heartbeatTimer = (feedbackStyle.heartbeatTimer or 0) + (tonumber(dt) or 0)
    if feedbackStyle.heartbeatTimer >= 0.5 then
        feedbackStyle.heartbeatTimer = 0
        feedbackStyle.registerCandidate()
    end
    feedbackStyle.reflow()
end

local function updateFeedbackVisibility()
    feedbackStyle.update(0)
end

function feedbackStyle.onSkillPerkPopupShow(payload)
    feedbackStyle.registerCandidate()
    if feedbackStyle.electedManagerId() == feedbackStyle.managerId then
        feedbackStyle.showCustom(payload)
    end
end

function feedbackStyle.emit(payload)
    feedbackStyle.registerCandidate()
    if feedbackStyle.electedManagerId() == feedbackStyle.managerId then
        feedbackStyle.showCustom(payload)
        return
    end
    if self.object and self.object.sendEvent then
        self.object:sendEvent('SkillPerkPopup_Show', payload)
    end
end

local function showFeedback(msg, hasSensoryCue)
    local style = feedbackStyle.perkMessageStyle()
    if style <= 0 then return end
    if hasSensoryCue and feedbackStyle.suppressSensoryPopups() then return end
    if style == 2 then
        feedbackStyle.showStandardMessage(tostring(msg or ''))
        debugLog('STANDARD MESSAGE FEEDBACK ' .. tostring(msg), 'debugUiMessages')
        return
    end

    local textRgb = feedbackStyle.popupColor('perkMessageText', feedbackStyle.textRgb)
    local shadowRgb = feedbackStyle.popupColor('perkMessageShadow', feedbackStyle.shadowRgb)
    feedbackStyle.emit({
        source = 'Toxicology',
        text = tostring(msg or ''),
        textR = textRgb[1],
        textG = textRgb[2],
        textB = textRgb[3],
        shadowR = shadowRgb[1],
        shadowG = shadowRgb[2],
        shadowB = shadowRgb[3],
        defaultTextRgb = feedbackStyle.textRgb,
        defaultShadowRgb = feedbackStyle.shadowRgb,
        textSize = 20,
        duration = feedbackStyle.clamp(readSetting('UI', 'popupDuration', feedbackStyle.duration), feedbackStyle.duration, 0.5, 10),
        popupPosition = feedbackStyle.clamp(readSetting('UI', 'popupPosition', 4), 4, 0, 4),
        maxVisible = feedbackStyle.clamp(readSetting('UI', 'popupMaxVisible', 5), 5, 1, 10),
    })
    debugLog('FEEDBACK ' .. tostring(msg), 'debugUiMessages')
end

-- ─── Skill registration ─────────────────────────────────────────────────────

local hasSkillFramework = false
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
    hasSkillFramework = true
    if skillIsRegistered() then
        skillRegistered = true
        return true
    end

    I.SkillFramework.registerSkill(SKILL_ID, {
        name = 'Toxicology',
        description = 'Governs your ability to apply and master weapon poisons. A Toxicologist knows how to coat a blade, preserve a coating, layer complex blends, and strike with toxic perfection. Applied coatings last for a limited number of hits that scales with skill.',
        attribute = 'intelligence',
        specialization = I.SkillFramework.SPECIALIZATION.Stealth,
        startLevel = config.startLevel,
        maxLevel = config.maxLevel,
        skillGain = {
            apply = config.xp.apply,
            strike = config.xp.strike,
            kill = config.xp.kill,
            -- Brewing a harmful potion redirects a fraction of its Alchemy XP
            -- to Toxicology (default 50%). The amount is computed live from
            -- the Alchemy gain in the SkillUsedHandler below.
            brew = config.xp.apply, -- placeholder; actual value set per-call via `scale`
        },
        statsWindowProps = {
            subsection = 'Stealth',
            shortenedName = 'Toxicology',
            visible = true,
        },
        icon = {
            bgr = 'icons/SkillFramework/stealth_blank.dds',
            fgr = 'icons/Toxicology/toxicology.dds',
            bgrColor = util.color.rgb(1, 1, 1),
            fgrColor = util.color.rgb(0.95, 0.95, 0.95),
        },
    })

    if readSetting('Skill', 'enableRaceBonuses', true) then
        -- Vanilla races
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'dark elf', 10)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'argonian', 10)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'wood elf', 5)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'breton', 5)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'high elf', 5)

        -- Tamriel Data races (mirrored from your other skill mods)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Bm_Naga', 5)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Yne_Ynesai', 5)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Sky_Reachman', 10)
        I.SkillFramework.registerRaceModifier(SKILL_ID, 'T_Pya_SeaElf', 10)
    end

    if readSetting('Skill', 'enableSkillBooks', true) then
        -- Thematic poison and flora texts. Chosen to avoid collisions with
        -- the other skill mods' book assignments.
        I.SkillFramework.registerSkillBook('bk_poisonsong6', SKILL_ID)
        I.SkillFramework.registerSkillBook('bk_specialfloraoftamriel', SKILL_ID)
    end

    debugLog('Toxicology skill registered (governed by Intelligence, Stealth spec.)', 'debugIntegrationMessages')
    skillRegistered = true
    return true
end

-- ─── Dynamic skill description ──────────────────────────────────────────────
-- Rebuilds the Toxicology tooltip in the stats window to reflect the
-- player's current level: shows active vs locked perks with live chances,
-- max charges at current skill, etc. Refreshed on level-up.

local function getToxicologySkillLevel()
    if I.SkillFramework and skillRegistered then
        local stat = I.SkillFramework.getSkillStat(SKILL_ID)
        if stat then return stat.modified end
    end
    return config.startLevel
end

local lastSyncedSkill = nil

local function syncRuntimeSkillToGlobal(force)
    local skill = math.floor(getToxicologySkillLevel() or config.startLevel or 1)
    if not force and lastSyncedSkill == skill then return end
    lastSyncedSkill = skill
    core.sendGlobalEvent('Toxicology_UpdateRuntimeSettings', { currentSkill = skill })
end

local function chargesAtSkill(skill)
    local n = math.floor(skill / config.charges.chargesPerTier) + 1
    if n < config.charges.minCharges then n = config.charges.minCharges end
    if n > config.charges.maxCharges then n = config.charges.maxCharges end
    return n
end

local function allPerksEnabled()
    return readSetting('Perks', 'enableAllPerks', true)
end

local function coatingsAtSkill(skill)
    if allPerksEnabled()
        and skill >= config.perks.compoundBlendLevel
        and readSetting('Perks', 'enableCompoundBlend', true) then
        return config.perks.compoundBlendMaxLayers or 3
    end
    return 1
end

local function efficientCoatingChance(skill)
    local p = config.perks
    if not allPerksEnabled() or not readSetting('Perks', 'enableEfficientCoating', true) then return 0 end
    if skill < p.efficientCoatingLevel then return 0 end
    return p.efficientCoatingChance or 15
end

local function percentStr(value)
    return string.format('%0.0f%%', value)
end

local PERK_SETTINGS = {
    masterCoating = 'enableMasterCoating',
    compoundBlend = 'enableCompoundBlend',
    efficientCoating = 'enableEfficientCoating',
    toxicPrecision = 'enableToxicPrecision',
}

local function toxicologyPerkEnabled(perkId)
    if not allPerksEnabled() then return false end
    local key = PERK_SETTINGS[perkId]
    if not key then return true end
    return readSetting('Perks', key, true)
end

local function perkSummary(skill, perkId)
    local p = config.perks
    if perkId == 'efficientCoating' then
        local active = skill >= p.efficientCoatingLevel
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.efficientCoatingLevel)
        return prefix .. string.format('Efficient Coating: %s chance per poisoned strike to preserve every active coating layer.', percentStr(efficientCoatingChance(skill)))
    elseif perkId == 'compoundBlend' then
        local active = skill >= p.compoundBlendLevel
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.compoundBlendLevel)
        return prefix .. string.format('Compound Blend: unlocks %d simultaneous poison coatings.', coatingsAtSkill(skill))
    elseif perkId == 'masterCoating' then
        local active = skill >= p.masterCoatingLevel
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.masterCoatingLevel)
        return prefix .. 'Master Coating: re-applying the same poison reinforces an existing coating.'
    elseif perkId == 'toxicPrecision' then
        local active = skill >= p.toxicPrecisionLevel
        local prefix = active and '[Active] ' or string.format('[Unlock %d] ', p.toxicPrecisionLevel)
        return prefix .. string.format('Toxic Perfection: %s chance to apply %d%% Weakness to Poison for %d seconds before the coating payload.',
            percentStr(p.toxicPrecisionChance or 35),
            tonumber(p.toxicPrecisionMagnitude) or 25,
            tonumber(p.toxicPrecisionDuration) or 10)
    end
    return nil
end

local lastBuiltDescription = nil

local function buildSkillDescription()
    local skill = getToxicologySkillLevel()
    local charges = chargesAtSkill(skill)
    local coatings = coatingsAtSkill(skill)
    local showMechanicTooltips = readSetting('UI', 'showMechanicTooltips', true)
    local showPerkTooltips = readSetting('UI', 'showPerkTooltips', true)
    local unlockedOnly = readSetting('UI', 'tooltipUnlockedOnly', false)

    local lines = {
        'Governs your ability to apply and master weapon poisons.',
        '',
        string.format('Current Toxicology: %d', math.floor(skill)),
    }

    if showMechanicTooltips then
        table.insert(lines, string.format('Charges per application: %d', charges))
        table.insert(lines, string.format('Simultaneous coatings: %d', coatings))
    end

    table.insert(lines, '')

    local perkOrder = {
        { id = 'masterCoating',    level = config.perks.masterCoatingLevel },
        { id = 'compoundBlend',    level = config.perks.compoundBlendLevel },
        { id = 'efficientCoating', level = config.perks.efficientCoatingLevel },
        { id = 'toxicPrecision',  level = config.perks.toxicPrecisionLevel },
    }

    if showPerkTooltips then
        local perkLines = {}
        for _, perk in ipairs(perkOrder) do
            if toxicologyPerkEnabled(perk.id) and ((not unlockedOnly) or skill >= perk.level) then
                local line = perkSummary(skill, perk.id)
                if line then table.insert(perkLines, line) end
            end
        end

        if unlockedOnly and #perkLines == 0 then
            local nextPerk = nil
            for _, perk in ipairs(perkOrder) do
                if toxicologyPerkEnabled(perk.id) and skill < perk.level then
                    nextPerk = perk
                    break
                end
            end
            if nextPerk then
                table.insert(perkLines, string.format('No perks unlocked yet. Next unlock at %d Toxicology.', nextPerk.level))
                table.insert(perkLines, perkSummary(skill, nextPerk.id))
            else
                table.insert(perkLines, 'All remaining Toxicology perks are disabled in settings.')
            end
        end

        for _, line in ipairs(perkLines) do table.insert(lines, line) end
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

-- ─── Class bonus (native base) ───────────────────────────────────────────────

local classBonusApplied = false
local classBonusMode = 'none'
local appliedClassBonusAmount = 0
local classDynamicModifierRegistered = false
local legacyClassBonusMigrated = false
local lastAAMClassBonus = nil

local function getPlayerClassSpecialization()
    local function norm(value)
        if value == nil then return nil end
        local text = string.lower(tostring(value))
        if text == 'combat' or text == 'magic' or text == 'stealth' then return text end
        return nil
    end

    local ok, npcRec = pcall(function() return types.NPC.record(self) end)
    if not (ok and npcRec and npcRec.class) then return nil, nil end

    local classId = tostring(npcRec.class)
    local function classRecord(id)
        if not (types.NPC and types.NPC.classes) then return nil end
        local okClass, rec
        if types.NPC.classes.record then
            okClass, rec = pcall(function() return types.NPC.classes.record(id) end)
            if okClass and rec then return rec end
            okClass, rec = pcall(function() return types.NPC.classes.record(string.lower(id)) end)
            if okClass and rec then return rec end
        end
        if types.NPC.classes.records then
            okClass, rec = pcall(function()
                return types.NPC.classes.records[id] or types.NPC.classes.records[string.lower(id)]
            end)
            if okClass and rec then return rec end
            okClass, rec = pcall(function()
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
            if okClass and rec then return rec end
        end
        return nil
    end

    local rec = classRecord(classId)
    local spec = norm(rec and rec.specialization)
    if spec then return spec, classId end

    if types.Player and types.Player.isCharGenFinished and not types.Player.isCharGenFinished(self) then return nil, classId end

    local specSkills = {
        combat = { 'block', 'armorer', 'mediumarmor', 'heavyarmor', 'bluntweapon', 'longblade', 'axe', 'spear', 'athletics' },
        magic = { 'enchant', 'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration', 'alchemy', 'unarmored' },
        stealth = { 'security', 'sneak', 'acrobatics', 'lightarmor', 'shortblade', 'marksman', 'mercantile', 'speechcraft', 'handtohand' },
    }
    local order = { 'combat', 'magic', 'stealth' }

    local raceRec = nil
    if npcRec.race and types.NPC and types.NPC.races then
        local raceId = tostring(npcRec.race)
        if types.NPC.races.record then
            local okRace
            okRace, raceRec = pcall(function() return types.NPC.races.record(raceId) end)
            if not (okRace and raceRec) then
                okRace, raceRec = pcall(function() return types.NPC.races.record(string.lower(raceId)) end)
            end
        end
        if not raceRec and types.NPC.races.records then
            local okRace
            okRace, raceRec = pcall(function()
                return types.NPC.races.records[raceId] or types.NPC.races.records[string.lower(raceId)]
            end)
            if not okRace then raceRec = nil end
        end
    end

    local function raceBonus(skillId)
        if not raceRec or not raceRec.skills then return 0 end
        local okBonus, value = pcall(function()
            return raceRec.skills[skillId] or raceRec.skills[string.lower(skillId)]
        end)
        if okBonus then return tonumber(value) or 0 end
        return 0
    end

    local function skillBase(skillId)
        if not (types.NPC and types.NPC.stats and types.NPC.stats.skills) then return nil end
        local getter = types.NPC.stats.skills[skillId]
        if type(getter) ~= 'function' then return nil end
        local okStat, stat = pcall(function() return getter(self) end)
        if not (okStat and stat) then return nil end
        return tonumber(stat.base or stat.modified)
    end

    local bestSpec = nil
    local bestScore = nil
    local secondScore = nil
    local bestMin = nil
    local bestMedian = nil

    for _, candidateSpec in ipairs(order) do
        local residuals = {}
        for _, skillId in ipairs(specSkills[candidateSpec]) do
            local base = skillBase(skillId)
            if base then residuals[#residuals + 1] = base - 5 - raceBonus(skillId) end
        end
        if #residuals >= 7 then
            table.sort(residuals)
            local minResidual = residuals[1]
            local count = #residuals
            local mid = math.floor((count + 1) / 2)
            local medianResidual = (count % 2 == 1) and residuals[mid] or ((residuals[mid] + residuals[mid + 1]) * 0.5)
            local score = (minResidual * 4) + medianResidual
            if not bestScore or score > bestScore then
                secondScore = bestScore
                bestScore = score
                bestSpec = candidateSpec
                bestMin = minResidual
                bestMedian = medianResidual
            elseif not secondScore or score > secondScore then
                secondScore = score
            end
        end
    end

    if bestSpec and bestMin and bestMedian and bestMin >= 4 and bestMedian >= 4
        and (not secondScore or (bestScore - secondScore) >= 3) then
        return bestSpec, classId
    end

    return nil, classId
end

local function getClassSpecializationBonus()
    if not readSetting('Skill', 'enableClassBonus', true) then return 0 end
    -- Ultimate Leveling handles Skill Framework custom-skill starting specialization bonuses itself.
    if core.contentFiles.has('UltimateLeveling.omwaddon') then return 0 end
    local spec = getPlayerClassSpecialization()
    if spec == 'stealth' then return config.classBonus end
    return 0
end

local function notifyAAM(force)
    if not (I and I.AAM and I.AAM.reportExternalModifiers) then return end
    if not force and lastAAMClassBonus == 0 then return end
    lastAAMClassBonus = 0
    I.AAM.reportExternalModifiers(MODNAME, {})
end

local function reconcileClassBonusMode()
    if not (I.SkillFramework and I.SkillFramework.getSkillStat and skillIsRegistered()) then return end
    if types.Player and types.Player.isCharGenFinished and not types.Player.isCharGenFinished(self) then return end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return end

    local desired = getClassSpecializationBonus()
    local current = tonumber(appliedClassBonusAmount) or 0
    if classBonusMode == 'modifier' and current ~= 0 then
        stat.modifier = (tonumber(stat.modifier) or 0) - current
        current = 0
    end

    if desired ~= current then
        stat.base = math.max(0, math.min(config.maxLevel, (tonumber(stat.base) or 0) - current + desired))
        appliedClassBonusAmount = desired
    end

    classBonusApplied = desired ~= 0
    classBonusMode = 'base'
    notifyAAM()
end

local function applyClassBonus()
    reconcileClassBonusMode()
end

-- ─── Dialog: Apply-or-Drink prompt ──────────────────────────────────────────
--
-- Custom modal dialog with three buttons (Apply, Drink, Cancel). We construct
-- the widget tree manually — ui.showMessage doesn't support buttons in
-- OpenMW 0.49/0.50.
--
-- Pattern:
--   * Build a container widget on the 'Windows' layer covering the screen
--   * Put a centered panel inside with a prompt text and three buttons
--   * Each button has a mouseClick event that resolves the prompt
--   * After any button click, destroy the modal element

local async = require('openmw.async')

local activeDialog = nil  -- Element; nil when no dialog is up
local pendingContext = nil

-- Destroy the UI element only. Does NOT clear pendingContext. That needs to
-- be separate because showDialog() calls this at the start as belt-and-braces,
-- and we set pendingContext just before calling showDialog.
local function destroyDialogUi()
    if activeDialog then
        activeDialog:destroy()
        activeDialog = nil
    end
end

-- Full teardown: destroy UI + clear pending context. Use this from button
-- handlers (after acting on the context).
local function destroyDialog()
    destroyDialogUi()
    pendingContext = nil
end

local function resolveApply()
    debugLog('resolveApply fired. pendingContext=' .. tostring(pendingContext ~= nil), 'debugUiMessages')
    if not pendingContext then destroyDialog(); return end
    debugLog('resolveApply: sending ConfirmApply with potion=' ..
          tostring(pendingContext.potion) .. ' actor=' .. tostring(self.object), 'debugUiMessages')
    core.sendGlobalEvent('Toxicology_ConfirmApply', {
        actor = self.object,
        potion = pendingContext.potion,
        weapon = pendingContext.weapon,
        layer = 1,
    })
    destroyDialog()
end

local function resolveDrink()
    debugLog('resolveDrink fired. pendingContext=' .. tostring(pendingContext ~= nil), 'debugUiMessages')
    if not pendingContext then destroyDialog(); return end
    debugLog('resolveDrink: sending UseItem', 'debugUiMessages')
    core.sendGlobalEvent('UseItem', {
        object = pendingContext.potion,
        actor = self.object,
        force = true,
    })
    destroyDialog()
end

local function resolveCancel()
    destroyDialog()
end

-- ─── MWUI-based dialog styling ──────────────────────────────────────────────
-- Vanilla-friendly styling using the Skill Framework / StatsWindow pattern:
-- MWUI.templates.boxSolidThick for the outer frame, boxSolid for buttons,
-- padding template for margins, Flex for layout, whiteTexture from mwui
-- constants for solid fills. This matches the look of Enumeratio's summary
-- page and the vanilla stat window's tooltips.

local MWUI = I.MWUI
local MWUIConstants = require('scripts.omw.mwui.constants')
local WHITE_TEX = MWUIConstants.whiteTexture

-- Morrowind-palette colours matching Enumeratio.
local COL_GOLD       = util.color.rgb(0.98, 0.92, 0.78)
local COL_PALE_GOLD  = util.color.rgb(0.90, 0.83, 0.68)
local COL_TEXT       = util.color.rgb(0.96, 0.95, 0.92)
local COL_VALUE      = util.color.rgb(1.00, 0.99, 0.98)
local COL_SUBTLE     = util.color.rgb(0.72, 0.70, 0.66)
local COL_DIM        = util.color.rgb(0, 0, 0)

-- Small text builder mirroring Enumeratio's makeText
local function dlgText(text, opts)
    opts = opts or {}
    return {
        type = ui.TYPE.Text,
        props = {
            text = text or '',
            textSize = opts.size or 16,
            textColor = opts.color or COL_TEXT,
            autoSize = opts.autoSize ~= false,
            size = opts.boxSize,
            textShadow = opts.shadow ~= false,
            textShadowColor = util.color.rgb(0, 0, 0),
            textAlignH = opts.alignH,
            textAlignV = opts.alignV,
        },
    }
end

local function dlgSpacer(w, h)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(w or 1, h or 1) },
    }
end

local function dlgHStack(children, size)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, autoSize = false, size = size,
                  align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content(children),
    }
end

local function dlgVStack(children, size)
    return {
        type = ui.TYPE.Flex,
        props = { autoSize = false, size = size,
                  align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content(children),
    }
end

-- Button: a boxSolid-bordered clickable widget with padding and centred text.
local function mwuiButton(label, width, onClick)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, 34) },
        events = {
            mouseClick = async:callback(onClick),
        },
        content = ui.content({
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.92 },
                content = ui.content({
                    {
                        template = MWUI.templates.padding,
                        props = { padding = 6 },
                        content = ui.content({
                            dlgText(label, {
                                size = 16,
                                color = COL_VALUE,
                                alignH = ui.ALIGNMENT.Center,
                                alignV = ui.ALIGNMENT.Center,
                                autoSize = false,
                                boxSize = util.vector2(width - 12, 20),
                            }),
                        }),
                    },
                }),
            },
        }),
    }
end

local function showDialog(potionName, weaponName)
    destroyDialogUi()  -- belt-and-braces: destroy any leftover UI element only.
                       -- Do NOT use destroyDialog() here; it would clear
                       -- pendingContext which onPromptApply just set up.

    local promptLine = string.format(
        'Apply %s to your %s, or drink it?',
        potionName or 'the potion',
        weaponName or 'weapon'
    )


    -- Panel layout constants
    local PANEL_W = 460
    local PROMPT_H = 60
    local BUTTON_W = 120
    local BUTTON_H = 34
    local BUTTON_GAP = 12
    local OUTER_PAD = 14
    local GAP = 12
    local BUTTONS_ROW_W = 3 * BUTTON_W + 2 * BUTTON_GAP  -- 384
    -- Inner content height = prompt + gap + button row
    local INNER_H = PROMPT_H + GAP + BUTTON_H
    local PANEL_H = INNER_H + 2 * OUTER_PAD + 8  -- +8 for template border

    -- Header text: small subtitle labelling what the prompt is about
    local headerText = dlgText('Toxicology — Coat Weapon', {
        size = 15,
        color = COL_GOLD,
        alignH = ui.ALIGNMENT.Center,
        alignV = ui.ALIGNMENT.Center,
        autoSize = false,
        boxSize = util.vector2(PANEL_W - 2 * OUTER_PAD, 20),
    })

    -- Prompt text: main question, word-wrapped
    local promptBody = dlgText(promptLine, {
        size = 18,
        color = COL_TEXT,
        alignH = ui.ALIGNMENT.Center,
        alignV = ui.ALIGNMENT.Center,
        autoSize = false,
        boxSize = util.vector2(PANEL_W - 2 * OUTER_PAD, PROMPT_H - 20),
    })

    -- Button row
    local buttonRow = dlgHStack({
        mwuiButton('Apply',  BUTTON_W, resolveApply),
        dlgSpacer(BUTTON_GAP, 1),
        mwuiButton('Drink',  BUTTON_W, resolveDrink),
        dlgSpacer(BUTTON_GAP, 1),
        mwuiButton('Cancel', BUTTON_W, resolveCancel),
    }, util.vector2(BUTTONS_ROW_W, BUTTON_H))

    -- Inner vertical stack: header / prompt / gap / buttons
    local innerStack = dlgVStack({
        headerText,
        dlgSpacer(1, 6),
        promptBody,
        dlgSpacer(1, GAP),
        buttonRow,
    }, util.vector2(PANEL_W - 2 * OUTER_PAD, INNER_H + 26))

    -- Outer panel: boxSolidThick template gives the proper Morrowind
    -- heavy gold frame with grey-black fill.
    local panelSize = util.vector2(PANEL_W, PANEL_H + 26)
    local panel = {
        type = ui.TYPE.Widget,
        name = 'tox_panel',
        props = {
            size = panelSize,
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content({
            {
                template = MWUI.templates.boxSolidThick,
                content = ui.content({
                    {
                        template = MWUI.templates.padding,
                        props = { padding = OUTER_PAD },
                        content = ui.content({ innerStack }),
                    },
                }),
            },
        }),
    }

    -- Fullscreen dimmer + panel on the Windows layer.
    -- The dimmer is visual only — it does NOT have a click handler because that
    -- would intercept clicks intended for the panel's buttons. Use the Cancel
    -- button (or Esc binding if added later) to dismiss.
    local modal = {
        layer = 'Windows',
        name = 'Toxicology_ApplyDialog',
        type = ui.TYPE.Widget,
        props = {
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    color = COL_DIM,
                    alpha = 0.45,
                    relativeSize = util.vector2(1, 1),
                },
                -- no click handler — dimmer is visual only
            },
            panel,
        }),
    }

    activeDialog = ui.create(modal)
end

local function onPromptApply(evt)
    -- The global script has identified a harmful potion + equipped weapon.
    -- Find the potion GameObject in our inventory by id.
    local inv = types.Actor.inventory(self)
    if not inv then return end
    local potion = nil
    for _, item in ipairs(inv:getAll()) do
        if item.id == evt.potionId then
            potion = item
            break
        end
    end
    if not potion then
        debugLog('onPromptApply: could not find potion by id ' .. tostring(evt.potionId), 'debugUiMessages')
        return
    end

    -- Combat guard: block the prompt entirely when weapon is drawn in combat stance.
    if readSetting('', 'blockInCombat', true) then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Weapon or stance == types.Actor.STANCE.Spell then
            ui.showMessage('Cannot apply poison with weapon drawn. Sheath first.')
            return
        end
    end

    -- Resolve names for the prompt
    local potionName
    local ok1, potRec = pcall(types.Potion.record, potion)
    if ok1 and potRec then potionName = potRec.name end
    potionName = potionName or (types.Potion.records[evt.potionRecord] and types.Potion.records[evt.potionRecord].name) or 'potion'

    local weaponName
    if evt.weaponRecord and types.Weapon.records[evt.weaponRecord] then
        weaponName = types.Weapon.records[evt.weaponRecord].name
    end
    weaponName = weaponName or 'weapon'

    pendingContext = {
        potion = potion,
        potionRecord = evt.potionRecord,
        weaponRecord = evt.weaponRecord,
    }
    showDialog(potionName, weaponName)
end

-- ─── Message display ────────────────────────────────────────────────────────

local function onMessage(evt)
    if evt.text then
        ui.showMessage(evt.text)
    end
end

-- Incoming: { perk = 'efficientCoating' | 'masterCoating' | 'toxicPrecision' }
-- Flashes a brief banner so the player sees their perks actually procced.
local function onPerkFired(evt)
    if not evt or not evt.perk then return end
    local perk = evt.perk
    if perk == 'efficientCoating' then
        showFeedback('Efficient Coating!', false)
    elseif perk == 'masterCoating' then
        showFeedback('Master Coating!', false)
    elseif perk == 'toxicPrecision' then
        showFeedback('Toxic Perfection!', true)
    end
end

-- ─── XP grant ───────────────────────────────────────────────────────────────

local lastKillTrack = { victim = nil, time = -math.huge }

local function onGrantXp(evt)
    if not skillRegistered then return end
    local useType = evt.useType
    if not useType then return end
    if useType == 'apply' and not readSetting('Skill', 'xpOnApply', true) then return end
    if useType == 'strike' and not readSetting('Skill', 'xpOnStrike', true) then return end
    if useType == 'kill' and not readSetting('Skill', 'xpOnKill', true) then return end

    -- Use the Skill Framework's skillUsed (NOT engine's SkillProgression) —
    -- custom skills are unknown to the engine's progression system. Skill
    -- Framework looks up the XP value in the skillGain table we declared
    -- at registration time using `useType` as the key.
    if not I.SkillFramework or not I.SkillFramework.skillUsed then
        debugLog('Toxicology_GrantXp: SkillFramework.skillUsed unavailable', 'debugXpMessages')
        return
    end
    local ok, err = pcall(function()
        I.SkillFramework.skillUsed(SKILL_ID, { useType = useType, scale = xpMultiplier() })
    end)
    if not ok then
        debugLog('Toxicology_GrantXp: skillUsed failed: ' .. tostring(err), 'debugXpMessages')
    else
        debugLog('Toxicology_GrantXp: granted ' .. useType .. ' XP', 'debugXpMessages')
    end
end

-- ─── Alchemy brew → Toxicology XP redirect ─────────────────────────────────
-- When the player brews a potion with harmful effects, redirect part of the
-- Alchemy XP to Toxicology. SkillProgression tells us that an Alchemy create
-- event happened, but not which potion stack changed. OpenMW can reuse the
-- same Generated:0x... record for same-name/same-recipe potions, so checking
-- only for a newer generated record misses every later potion in that stack.
-- Track generated-potion stack counts instead and credit every harmful count
-- increase.

local function isEffectHarmfulLocal(effect)
    local id = effect.id
    if not id then return false end
    id = id:lower()
    if config.alwaysHarmfulEffects and config.alwaysHarmfulEffects[id] then return true end
    local rec = core.magic.effects.records[id]
    if rec and rec.harmful then return true end
    return false
end

local function lowerLocal(s)
    if type(s) ~= 'string' then return '' end
    return s:lower()
end

local function alcoholTermMatchesLocal(hay, term)
    if type(term) ~= 'string' or term == '' then return false end
    term = term:lower()

    -- ID-style terms are expected to be matched literally.
    if term:find('_', 1, true) then
        return hay:find(term, 1, true) ~= nil
    end

    local start = 1
    while true do
        local i, j = hay:find(term, start, true)
        if not i then return false end
        local before = i > 1 and hay:sub(i - 1, i - 1) or ''
        local after = j < #hay and hay:sub(j + 1, j + 1) or ''
        local beforeWord = before ~= '' and before:match('%w') ~= nil
        local afterWord = after ~= '' and after:match('%w') ~= nil
        if not beforeWord and not afterWord then return true end
        start = j + 1
    end
end

local function recordLooksAlcoholicLocal(id, record)
    local alcohol = config.alcohol or {}
    local recordIds = alcohol.recordIds or {}
    local key = lowerLocal(id)

    -- Accept mixed-case config entries so mod-added drink IDs do not need
    -- perfect casing to be recognised by Toxicology's alcohol filters.
    if key ~= '' then
        if recordIds[key] or recordIds[tostring(id or '')] then return true end
        for recordId, enabled in pairs(recordIds) do
            if enabled and lowerLocal(recordId) == key then return true end
        end
    end

    local hay = key .. ' ' .. lowerLocal(record and record.name or '')
    for _, term in ipairs(alcohol.terms or {}) do
        if alcoholTermMatchesLocal(hay, term) then return true end
    end
    return false
end

local function potionIsIgnoredAlcoholLocal(potionObj, record)
    if not readSetting('', 'ignoreAlcoholPotions', true) then return false end
    return recordLooksAlcoholicLocal(potionObj and potionObj.recordId, record)
end

local function potionIsHarmfulLocal(potionObj)
    local rec = types.Potion.records[potionObj.recordId]
    if not rec or not rec.effects then return false end
    if potionIsIgnoredAlcoholLocal(potionObj, rec) then return false end
    for _, eff in ipairs(rec.effects) do
        if isEffectHarmfulLocal(eff) then return true end
    end
    return false
end

-- Parse "Generated:0x2e53" → 0x2e53 as number. Returns 0 for non-generated ids.
local function generatedIndex(recordId)
    if type(recordId) ~= 'string' then return 0 end
    local hex = recordId:match('^Generated:0x(%x+)$')
    if not hex then return 0 end
    return tonumber(hex, 16) or 0
end

-- Keep this as a single top-level local. OpenMW/Lua caps the main chunk at
-- 200 locals, and this script already runs close to that ceiling.
local highestSeenGenIndex = { highWater = 0, counts = {} }

-- Initialise or refresh the generated-potion count snapshot from inventory.
-- Passing a reason emits a debug line; normal periodic refreshes stay quiet.
local function seedGeneratedIndex(reason)
    local inv = types.Actor.inventory(self)
    local counts = {}
    local highest = 0

    if inv then
        for _, item in ipairs(inv:getAll(types.Potion)) do
            local recordId = item and item.recordId
            local idx = generatedIndex(recordId)
            if idx > 0 then
                local ok, value = pcall(function() return item.count end)
                local count = ok and tonumber(value) or 1
                if not count or count < 1 then count = 1 end
                counts[recordId] = (counts[recordId] or 0) + math.floor(count)
                if idx > highest then highest = idx end
            end
        end
    end

    highestSeenGenIndex.counts = counts
    highestSeenGenIndex.highWater = highest
    if reason then
        debugLog('syncGeneratedPotionSnapshot: ' .. tostring(reason) ..
            '; high-water = 0x' .. string.format('%x', highest),
            'debugXpMessages')
    end
end

local function onAlchemySkillUsed(skillId, params)
    if skillId ~= 'alchemy' then return end
    if not params or not I.SkillProgression then return end
    if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion then
        return
    end
    if not readSetting('Skill', 'xpOnBrew', true) then
        seedGeneratedIndex()
        return
    end
    if not skillRegistered then
        seedGeneratedIndex()
        return
    end
    if not I.SkillFramework or not I.SkillFramework.skillUsed then
        seedGeneratedIndex()
        return
    end

    local inv = types.Actor.inventory(self)
    if not inv then return end

    local currentCounts = {}
    local currentItems = {}
    local highest = 0

    for _, item in ipairs(inv:getAll(types.Potion)) do
        local recordId = item and item.recordId
        local idx = generatedIndex(recordId)
        if idx > 0 then
            local ok, value = pcall(function() return item.count end)
            local count = ok and tonumber(value) or 1
            if not count or count < 1 then count = 1 end
            currentCounts[recordId] = (currentCounts[recordId] or 0) + math.floor(count)
            currentItems[recordId] = item
            if idx > highest then highest = idx end
        end
    end

    local harmfulBrewCount = 0
    local changedRecords = {}
    for recordId, currentCount in pairs(currentCounts) do
        local previousCount = highestSeenGenIndex.counts[recordId] or 0
        local delta = currentCount - previousCount
        if delta > 0 then
            table.insert(changedRecords, string.format('%s +%d', tostring(recordId), delta))
            if potionIsHarmfulLocal(currentItems[recordId]) then
                harmfulBrewCount = harmfulBrewCount + delta
            else
                debugLog('onAlchemySkillUsed: brewed potion ' .. tostring(recordId) ..
                    ' is not harmful — skipping redirect for this stack increase',
                    'debugXpMessages')
            end
        end
    end

    highestSeenGenIndex.counts = currentCounts
    highestSeenGenIndex.highWater = highest

    if #changedRecords == 0 then
        debugLog('onAlchemySkillUsed: no generated potion stack increase found', 'debugXpMessages')
        return
    end

    debugLog('onAlchemySkillUsed: generated potion stack changes: ' ..
        table.concat(changedRecords, ', '), 'debugXpMessages')

    if harmfulBrewCount <= 0 then return end

    local share = config.xp.brewAlchemyShare or 0.5
    local scale = share * xpMultiplier() * harmfulBrewCount
    local ok, err = pcall(function()
        I.SkillFramework.skillUsed(SKILL_ID, {
            useType = 'brew',
            scale = scale,
            redirectedFrom = 'alchemy',
        })
    end)
    if ok then
        debugLog(string.format(
            'onAlchemySkillUsed: granted Toxicology XP for %d harmful brewed potion(s) (scale=%.2f)',
            harmfulBrewCount, scale), 'debugXpMessages')
    else
        debugLog('onAlchemySkillUsed: SkillFramework.skillUsed failed: ' .. tostring(err), 'debugXpMessages')
    end
end

-- ─── Poison ID map from global ──────────────────────────────────────────────
-- Existing-record distribution leaves these maps empty. The handler remains for
-- backward compatibility with older saves/interface consumers.

local poisonIdMap = {}
local specialtyIdMap = {}

local function onPoisonIdMap(evt)
    poisonIdMap = evt.idMap or {}
    specialtyIdMap = evt.specialtyIdMap or {}
end

-- ─── Tooltip integration (vanilla + Inventory Extender) ────────────────────

local tooltipRegistered = false
local ieRowClickRegistered = false
local lastInventoryBadgeSignature = nil
local pendingBadgeRepaint = false

local function isSupportedWeaponRowItem(item)
    if not item or not types.Weapon.objectIsInstance(item) then return false end
    local rec = types.Weapon.record(item)
    if not rec or not rec.type then return false end
    for typeName, allowed in pairs(config.weapons.allowedTypes) do
        if allowed and types.Weapon.TYPE[typeName] == rec.type then
            return true
        end
    end
    return false
end

local function inventoryHasObjectId(objectId)
    if not objectId then return false end
    local inv = types.Actor.inventory(self)
    if not inv then return false end
    for _, item in ipairs(inv:getAll()) do
        if item.id == objectId then return true end
    end
    return false
end

local function promptApplyToSpecificWeapon(potion, weapon)
    if not potion or not weapon then return false end
    if not potionIsHarmfulLocal(potion) then return false end
    if not isSupportedWeaponRowItem(weapon) then return false end
    if not inventoryHasObjectId(potion.id) or not inventoryHasObjectId(weapon.id) then return false end

    if readSetting('', 'blockInCombat', true) then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Weapon or stance == types.Actor.STANCE.Spell then
            ui.showMessage('Cannot apply poison with weapon drawn. Sheath first.')
            return true
        end
    end

    local potionName
    local ok1, potRec = pcall(types.Potion.record, potion)
    if ok1 and potRec then potionName = potRec.name end
    potionName = potionName or (types.Potion.records[potion.recordId] and types.Potion.records[potion.recordId].name) or 'potion'

    local weaponRec = types.Weapon.record(weapon)
    local weaponName = (weaponRec and weaponRec.name) or 'weapon'

    pendingContext = {
        potion = potion,
        potionRecord = potion.recordId,
        weapon = weapon,
        weaponRecord = weapon.recordId,
    }
    showDialog(potionName, weaponName)
    return true
end

local function registerInventoryExtenderRowClickHandler()
    if ieRowClickRegistered then return end
    if not I.InventoryExtender then return end

    local api = I.InventoryExtender.API or I.InventoryExtender.api or I.InventoryExtender
    if not api or type(api.registerRowClickHandler) ~= 'function' then return end

    api.registerRowClickHandler(MODNAME, function(row, ctx)
        local draggedItem = ctx and ctx.dragAndDrop and ctx.dragAndDrop.draggingObject
        local targetItem = row and row.item
        if not draggedItem or not targetItem then return end
        if not types.Potion.objectIsInstance(draggedItem) then return end
        if not isSupportedWeaponRowItem(targetItem) then return end
        if promptApplyToSpecificWeapon(draggedItem, targetItem) then
            return false
        end
    end)

    ieRowClickRegistered = true
    debugLog('Registered Inventory Extender row-click handler', 'debugIntegrationMessages')
end

local function contentKey(content, key)
    if not content or key == nil then return nil end
    local ok, value = pcall(function() return content[key] end)
    if ok then return value end
    return nil
end

local function tooltipContent(layout)
    -- OpenMW's ui.content throws on unknown named children, so every keyed
    -- lookup is guarded. Inventory Extender's tooltip layout has changed shape
    -- a couple of times; support both the named MWUI path and the older nested
    -- content path used by early integration examples.
    local rootContent = layout and layout.content
    local padding = contentKey(rootContent, 'padding')
    local paddingInner = padding and padding.content
    local tooltip = contentKey(paddingInner, 'tooltip')
    if tooltip and tooltip.content then
        return tooltip.content
    end

    local first = contentKey(rootContent, 1)
    local firstInner = first and first.content
    local nestedTooltip = contentKey(firstInner, 1)
    if nestedTooltip and nestedTooltip.content then
        return nestedTooltip.content
    end

    return nil
end

local function poisonRecordOrSnapshot(data, poisonId)
    if not poisonId then return nil end
    local rec = types.Potion.records[poisonId]
    if rec then return rec end
    return data and data.snapshot and data.snapshot[poisonId] or nil
end

local function poisonName(data, poisonId)
    local rec = poisonRecordOrSnapshot(data, poisonId)
    return (rec and rec.name) or tostring(poisonId or 'Poison')
end

local function activePoisonLayers(data)
    if not weaponHasActivePoisonData(data) then return {} end

    local layerDefs = {
        { label = 'Primary coating',  poisonId = data.poisonId,       charges = data.charges },
        { label = 'Compound coating', poisonId = data.layer2PoisonId, charges = data.layer2Charges },
        { label = 'Master coating',   poisonId = data.layer3PoisonId, charges = data.layer3Charges },
    }

    local layers = {}
    for _, layer in ipairs(layerDefs) do
        if layer.poisonId then
            layer.record = poisonRecordOrSnapshot(data, layer.poisonId)
            layer.name = poisonName(data, layer.poisonId)
            layers[#layers + 1] = layer
        end
    end
    return layers
end

local function chargeText(charges)
    local count = math.max(0, tonumber(charges) or 0)
    if count == 1 then
        return '1 strike remaining'
    end
    return tostring(count) .. ' strikes remaining'
end

local function affectedStatName(effect)
    if effect.affectedAttribute then
        local record = core.stats.Attribute.records[effect.affectedAttribute]
        return record and record.name or tostring(effect.affectedAttribute)
    elseif effect.affectedSkill then
        local record = core.stats.Skill.records[effect.affectedSkill]
        return record and record.name or tostring(effect.affectedSkill)
    end
    return nil
end

local function magnitudeText(effect)
    local minMagnitude = effect.magnitudeMin or effect.magnitude or effect.magnitudeMax
    local maxMagnitude = effect.magnitudeMax or effect.magnitude or effect.magnitudeMin
    if not minMagnitude and not maxMagnitude then return nil end
    minMagnitude = tonumber(minMagnitude) or 0
    maxMagnitude = tonumber(maxMagnitude) or minMagnitude
    if minMagnitude == maxMagnitude then
        return tostring(minMagnitude) .. ' pts'
    end
    return tostring(minMagnitude) .. '-' .. tostring(maxMagnitude) .. ' pts'
end

local function effectTooltipText(effect)
    local effectRecord = core.magic.effects.records[effect.id]
    local effectName = effectRecord and effectRecord.name or tostring(effect.id)
    local statName = affectedStatName(effect)
    local text = statName and (effectName .. ' ' .. statName) or effectName

    local magnitude = magnitudeText(effect)
    if magnitude then
        text = text .. ': ' .. magnitude
    end

    if effect.duration and effect.duration > 0 then
        text = text .. ' for ' .. tostring(effect.duration) .. 's'
    end

    if effect.area and effect.area > 0 then
        text = text .. ', ' .. tostring(effect.area) .. 'ft'
    end

    return text
end

local function tooltipText(text, template, color, size)
    local props = {
        text = text or '',
        autoSize = true,
    }
    if color then props.textColor = color end
    if size then props.textSize = size end
    return {
        type = ui.TYPE.Text,
        template = template or (I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal),
        props = props,
    }
end

local function tooltipInterval(width, height)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width or 0, height or 0) },
    }
end

local function addTooltipDivider(innerContent)
    innerContent:add(tooltipInterval(0, 5))
    if I.MWUI and I.MWUI.templates and I.MWUI.templates.horizontalLine then
        innerContent:add({
            template = I.MWUI.templates.horizontalLine,
            props = { size = util.vector2(0, 2) },
            external = { stretch = 1 },
        })
    end
    innerContent:add(tooltipInterval(0, 5))
end

local function addPoisonLayerTooltip(innerContent, layer, data, alchemyGated)
    local headerColor = util.color.rgb(
        config.ui.tooltipPoisonColor[1],
        config.ui.tooltipPoisonColor[2],
        config.ui.tooltipPoisonColor[3]
    )
    local chargeColor = util.color.rgb(
        config.ui.tooltipChargesColor[1],
        config.ui.tooltipChargesColor[2],
        config.ui.tooltipChargesColor[3]
    )

    innerContent:add({
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            autoSize = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = POISON_BADGE_ICON },
                    size = util.vector2(16, 16),
                },
            },
            tooltipInterval(5, 0),
            tooltipText(layer.label .. ': ' .. layer.name,
                I.MWUI and I.MWUI.templates and I.MWUI.templates.textHeader,
                headerColor),
        },
    })

    innerContent:add(tooltipText('  ' .. chargeText(layer.charges),
        I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal,
        chargeColor,
        13))

    local rec = layer.record
    if rec and rec.effects then
        local alchemy = types.NPC.stats.skills.alchemy(self).modified
        for i, effect in ipairs(rec.effects) do
            if alchemyGated and alchemy < i * 15 then
                innerContent:add(tooltipText('  ?'))
            else
                local effectRecord = core.magic.effects.records[effect.id]
                local rowContent = ui.content {}
                if effectRecord and effectRecord.icon then
                    rowContent:add({
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = effectRecord.icon },
                            size = util.vector2(16, 16),
                        },
                    })
                    rowContent:add(tooltipInterval(5, 0))
                end
                rowContent:add(tooltipText(effectTooltipText(effect)))
                innerContent:add({
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                        autoSize = true,
                    },
                    content = rowContent,
                })
            end
        end
    end
end

local function addInventoryExtenderPoisonTooltip(item, layout)
    if not readSetting('UI', 'showTooltip', true) then return layout end
    if not safeWeaponRecord(item) then return layout end

    local data = getWeaponPoisonData(item)
    if not weaponHasActivePoisonData(data) then return layout end

    layout.userData = layout.userData or {}
    if layout.userData.ToxicologyPoisonTooltip then return layout end

    local innerContent = tooltipContent(layout)
    if not innerContent then return layout end
    layout.userData.ToxicologyPoisonTooltip = true

    addTooltipDivider(innerContent)

    innerContent:add({
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            autoSize = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = TOXICOLOGY_ICON },
                    size = util.vector2(18, 18),
                    color = util.color.rgb(0.62, 0.90, 0.62),
                },
            },
            tooltipInterval(6, 0),
            tooltipText('Toxicology coating',
                I.MWUI and I.MWUI.templates and I.MWUI.templates.textHeader,
                util.color.rgb(0.82, 0.94, 0.72)),
        },
    })
    innerContent:add(tooltipInterval(0, 3))

    local alchemyGated = readSetting('UI', 'alchemyGatedTooltip', true)
    local layers = activePoisonLayers(data)
    for i, layer in ipairs(layers) do
        if i > 1 then innerContent:add(tooltipInterval(0, 6)) end
        addPoisonLayerTooltip(innerContent, layer, data, alchemyGated)
    end

    return layout
end

local function registerInventoryExtenderTooltip()
    if tooltipRegistered then return end
    if not I.InventoryExtender then return end
    if not I.InventoryExtender.registerTooltipModifier then return end

    I.InventoryExtender.registerTooltipModifier(MODNAME, function(item, layout)
        return addInventoryExtenderPoisonTooltip(item, layout)
    end)
    tooltipRegistered = true
    debugLog('Registered Inventory Extender tooltip modifier', 'debugIntegrationMessages')
end

local function removeNamedContent(content, name)
    if not content then return false end
    local ok, len = pcall(function() return #content end)
    if not ok then return false end

    local changed = false
    for i = len, 1, -1 do
        local entry = contentKey(content, i)
        if entry and entry.name == name then
            table.remove(content, i)
            changed = true
        end
    end
    return changed
end

local function makePoisonBadge(size)
    size = math.max(10, math.min(18, math.floor(size or 14)))
    return {
        name = INVENTORY_BADGE_NAME,
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = POISON_BADGE_ICON },
            size = util.vector2(size, size),
            anchor = util.vector2(1, 0),
            relativePosition = util.vector2(0.98, 0.02),
        },
    }
end

local function iconBadgeSize(iconLayout)
    local size = iconLayout and iconLayout.props and iconLayout.props.size
    local dim = size and math.min(size.x or 0, size.y or 0) or 32
    if dim <= 0 then dim = 32 end
    return math.max(10, math.min(18, math.floor(dim * 0.40)))
end

local function syncPoisonBadge(iconLayout, shouldShow)
    if not iconLayout then return false end
    iconLayout.userData = iconLayout.userData or {}

    local size = shouldShow and iconBadgeSize(iconLayout) or nil
    local currentShown = iconLayout.userData.ToxicologyPoisonBadge == true
    local currentSize = iconLayout.userData.ToxicologyPoisonBadgeSize
    if currentShown == (shouldShow == true) and currentSize == size then
        return false
    end

    iconLayout.content = iconLayout.content or ui.content {}
    removeNamedContent(iconLayout.content, INVENTORY_BADGE_NAME)

    if shouldShow then
        iconLayout.content:add(makePoisonBadge(size))
        iconLayout.userData.ToxicologyPoisonBadge = true
        iconLayout.userData.ToxicologyPoisonBadgeSize = size
    else
        iconLayout.userData.ToxicologyPoisonBadge = false
        iconLayout.userData.ToxicologyPoisonBadgeSize = nil
    end
    return true
end

local function itemHasPoisonBadge(item)
    if not safeWeaponRecord(item) then return false end
    return weaponHasActivePoisonData(getWeaponPoisonData(item))
end

local function inventoryExtenderPoisonSignature()
    local parts = {}
    local inv = types.Actor.inventory(self)
    if inv then
        local ok, weapons = pcall(function() return inv:getAll(types.Weapon) end)
        if not ok or type(weapons) ~= 'table' then
            ok, weapons = pcall(function() return inv:getAll() end)
        end
        if ok and type(weapons) == 'table' then
            for _, item in ipairs(weapons) do
                if safeWeaponRecord(item) then
                    local key = poisonStorageKey(item)
                    local data = key and getWeaponPoisonData(item)
                    if weaponHasActivePoisonData(data) then
                        parts[#parts + 1] = table.concat({
                            tostring(key or item.id or ''),
                            tostring(data.poisonId or ''),
                            tostring(data.charges or 0),
                            tostring(data.layer2PoisonId or ''),
                            tostring(data.layer2Charges or 0),
                            tostring(data.layer3PoisonId or ''),
                            tostring(data.layer3Charges or 0),
                        }, ':')
                    end
                end
            end
        end
    end
    table.sort(parts)
    return table.concat(parts, '|')
end

-- recursive search for a named child in a cached row widget
local function findNamedChild(node, name)
    if not node then return nil end
    local layout = type(node) == 'userdata' and node.layout or node
    if not layout then return nil end
    if layout.name == name then return layout end
    local content = layout.content
    if not content then return nil end
    for _, child in pairs(content) do
        local hit = findNamedChild(child, name)
        if hit then return hit end
    end
    return nil
end

-- grid view uses 'itemIcon' (inventory.lua gridItemRenderer)
-- table view uses the column id 'Icon'
local IE_ICON_NAMES = { 'itemIcon', 'Icon' }

local function findRowIconLayout(rowWidget)
    for _, name in ipairs(IE_ICON_NAMES) do
        local hit = findNamedChild(rowWidget, name)
        if hit then return hit end
    end
    return nil
end

-- walk every IE window's row cache and sync the badge on weapon rows.
-- IE's registerCellContentModifier only fires on the initial table-view
-- render, so we paint directly into the cached widgets instead.
local function paintInventoryExtenderBadges()
    pendingBadgeRepaint = false
    if not I.InventoryExtender or not I.InventoryExtender.getWindows then return end
    local windows = I.InventoryExtender.getWindows()
    if type(windows) ~= 'table' then return end

    for _, window in pairs(windows) do
        local itemTable = window and window.itemTable
        local layout = itemTable and itemTable.layout
        local userData = layout and layout.userData
        local state = userData and userData.getState and userData.getState()
        if state and type(state.rowCache) == 'table' then
            for _, rowWidget in pairs(state.rowCache) do
                local row = rowWidget
                    and rowWidget.layout
                    and rowWidget.layout.userData
                    and rowWidget.layout.userData.row
                local item = row and row.item
                if item and safeWeaponRecord(item) then
                    local icon = findRowIconLayout(rowWidget)
                    if icon then
                        local shouldShow = itemHasPoisonBadge(item)
                        if syncPoisonBadge(icon, shouldShow) then
                            rowWidget:update()
                        end
                    end
                end
            end
        end
    end
end

-- defer to next frame: IE's renderVisibleRows runs after MI_Update and
-- after UiModeChanged, and would overwrite earlier edits
local function scheduleBadgeRepaint()
    if pendingBadgeRepaint then return end
    if not I.InventoryExtender then return end
    pendingBadgeRepaint = true
end

local function updateInventoryExtenderBadges()
    if not I.InventoryExtender then return end
    local signature = inventoryExtenderPoisonSignature()
    if signature ~= lastInventoryBadgeSignature then
        lastInventoryBadgeSignature = signature
    end
    scheduleBadgeRepaint()
end

local vanillaInventoryIndicator = nil
local currentUiMode = nil
local hudElement = nil

local function currentModeName()
    local uiInterface = I and I.UI
    if not uiInterface then return nil end
    if uiInterface.getMode then
        local ok, mode = pcall(uiInterface.getMode)
        if ok and mode ~= nil then return mode end
    end
    if currentUiMode ~= nil then return currentUiMode end
    local modes = uiInterface.modes
    if type(modes) == 'table' then return modes[#modes] end
    return nil
end

local function isInventoryLikeMode(mode)
    -- OpenMW reports the regular inventory/stat/magic/map screen as
    -- "Interface", not "Inventory". Container/barter/companion keep their
    -- own modes, so include both the broad inventory UI and those submodes.
    return mode == 'Interface'
        or mode == 'Inventory'
        or mode == 'Container'
        or mode == 'Barter'
        or mode == 'Companion'
end

local function destroyVanillaInventoryIndicator()
    if vanillaInventoryIndicator then
        vanillaInventoryIndicator:destroy()
        vanillaInventoryIndicator = nil
    end
end

local function collectPoisonedInventoryWeapons()
    local inv = types.Actor.inventory(self)
    if not inv then return {} end

    local ok, items = pcall(function() return inv:getAll(types.Weapon) end)
    if not ok or type(items) ~= 'table' then
        items = inv:getAll()
    end

    local rows = {}
    local seen = {}
    for _, item in ipairs(items) do
        if safeWeaponRecord(item) and itemHasPoisonBadge(item) and not seen[item.id] then
            local rec = types.Weapon.record(item)
            local data = getWeaponPoisonData(item)
            local layers = activePoisonLayers(data)
            local layer = layers[1]
            if layer then
                seen[item.id] = true
                local extra = #layers > 1 and (' +' .. tostring(#layers - 1)) or ''
                rows[#rows + 1] = {
                    item = item,
                    icon = rec and rec.icon or 'icons/default icon.dds',
                    weaponName = rec and rec.name or tostring(item.recordId or item.id),
                    poisonText = layer.name .. extra .. ' — ' .. chargeText(layer.charges),
                }
            end
        end
    end
    return rows
end

local function vanillaInventoryIndicatorRow(row)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            autoSize = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(30, 30) },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = row.icon },
                            size = util.vector2(28, 28),
                            anchor = util.vector2(0.5, 0.5),
                            relativePosition = util.vector2(0.5, 0.5),
                        },
                    },
                    makePoisonBadge(13),
                },
            },
            tooltipInterval(7, 0),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                },
                content = ui.content {
                    tooltipText(row.weaponName,
                        I.MWUI and I.MWUI.templates and I.MWUI.templates.textHeader,
                        util.color.rgb(0.92, 0.88, 0.74),
                        13),
                    tooltipText(row.poisonText,
                        I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal,
                        util.color.rgb(0.60, 0.88, 0.60),
                        12),
                },
            },
        },
    }
end

local function updateVanillaInventoryIndicator()
    -- The engine's built-in inventory window is not exposed as mutable Lua UI.
    -- This compact strip gives vanilla users the same at-a-glance poisoned-weapon
    -- state without replacing the whole inventory implementation.
    if I.InventoryExtender then
        destroyVanillaInventoryIndicator()
        return
    end
    if not readSetting('UI', 'showTooltip', true) then
        destroyVanillaInventoryIndicator()
        return
    end
    if not isInventoryLikeMode(currentModeName()) then
        destroyVanillaInventoryIndicator()
        return
    end

    local rows = collectPoisonedInventoryWeapons()
    if #rows == 0 then
        destroyVanillaInventoryIndicator()
        return
    end

    local content = ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                autoSize = true,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = TOXICOLOGY_ICON },
                        size = util.vector2(17, 17),
                        color = util.color.rgb(0.62, 0.90, 0.62),
                    },
                },
                tooltipInterval(5, 0),
                tooltipText('Coated weapons',
                    I.MWUI and I.MWUI.templates and I.MWUI.templates.textHeader,
                    util.color.rgb(0.92, 0.88, 0.74),
                    14),
            },
        },
        tooltipInterval(0, 4),
    }

    local limit = math.min(#rows, VANILLA_INVENTORY_INDICATOR_MAX_ROWS)
    for i = 1, limit do
        content:add(vanillaInventoryIndicatorRow(rows[i]))
        if i < limit then content:add(tooltipInterval(0, 3)) end
    end
    if #rows > limit then
        content:add(tooltipInterval(0, 4))
        content:add(tooltipText('+' .. tostring(#rows - limit) .. ' more coated weapon(s)',
            I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal,
            util.color.rgb(0.75, 0.75, 0.72),
            12))
    end

    local layout = {
        layer = 'Windows',
        name = VANILLA_INVENTORY_INDICATOR_NAME,
        type = ui.TYPE.Widget,
        props = {
            anchor = util.vector2(1, 0),
            relativePosition = util.vector2(0.985, 0.145),
            autoSize = true,
        },
        content = ui.content {
            {
                template = I.MWUI and I.MWUI.templates and I.MWUI.templates.boxSolid,
                props = { alpha = 0.92 },
                content = ui.content {
                    {
                        template = I.MWUI and I.MWUI.templates and I.MWUI.templates.padding,
                        props = { padding = 7 },
                        content = content,
                    },
                },
            },
        },
    }

    -- Recreate rather than mutating the root layout. OpenMW UI elements are
    -- reliable when their props/content are updated, but replacing a root layout
    -- table in-place is not part of the stable contract.
    destroyVanillaInventoryIndicator()
    vanillaInventoryIndicator = ui.create(layout)
end


local function onUiModeChanged(data)
    if data and data.newMode ~= nil then
        currentUiMode = data.newMode
    elseif data and data.oldMode ~= nil then
        currentUiMode = nil
    end

    if hudElement and hudElement.layout and hudElement.layout.userData then
        hudElement.layout.userData.dragging = false
        hudElement.layout.userData.lastMousePos = nil
    end

    -- Refresh immediately when entering/leaving vanilla inventory-like modes,
    -- rather than waiting for the next throttled onUpdate tick.
    if not I.InventoryExtender then
        if isInventoryLikeMode(currentUiMode) then
            updateVanillaInventoryIndicator()
        else
            destroyVanillaInventoryIndicator()
        end
    elseif isInventoryLikeMode(currentUiMode) then
        scheduleBadgeRepaint()
    end
end

-- ─── HUD indicator ──────────────────────────────────────────────────────────
-- Small icon next to the equipped-weapon area when a poisoned weapon is out.
-- Minimal for v1; can be expanded with icon textures later.

local function destroyHud()
    if hudElement then
        hudElement:destroy()
        hudElement = nil
    end
end

-- Build the HUD element as a horizontal Flex with: icon | " Name (N) "
-- The icon uses our Toxicology DDS so we avoid unicode glyphs that the
-- vanilla bitmap font can't render (the "?" / box the user reported).
local hudTextPath = { 'content', 2, 'props', 'text' }  -- path to text widget's text prop

local HUD_INDICATOR_DEFAULT_X_REL = 0.98
local HUD_INDICATOR_DEFAULT_Y_REL = 0.92

local function hudLayerSize()
    local ok, layerId = pcall(function() return ui.layers.indexOf('HUD') end)
    if ok and layerId and ui.layers[layerId] and ui.layers[layerId].size then
        return ui.layers[layerId].size
    end
    return util.vector2(1280, 720)
end

local function hudIndicatorIconSize()
    local value = tonumber(readSetting('UI', 'hudIndicatorIconSize', 18)) or 18
    return math.max(8, math.min(96, value))
end

local function hudIndicatorTextSize()
    return math.max(8, math.floor(hudIndicatorIconSize() * 0.78))
end

local function clampHudIndicatorPosition(pos)
    local layerSize = hudLayerSize()
    return util.vector2(
        math.floor(math.max(0, math.min(pos.x, layerSize.x))),
        math.floor(math.max(0, math.min(pos.y, layerSize.y)))
    )
end

local function hudIndicatorPosition()
    local layerSize = hudLayerSize()
    local storedX = tonumber(readSetting('UI', 'hudIndicatorX', 0)) or 0
    local storedY = tonumber(readSetting('UI', 'hudIndicatorY', 0)) or 0

    local x = storedX > 0 and storedX or math.floor(layerSize.x * HUD_INDICATOR_DEFAULT_X_REL)
    local y = storedY > 0 and storedY or math.floor(layerSize.y * HUD_INDICATOR_DEFAULT_Y_REL)

    return clampHudIndicatorPosition(util.vector2(x, y))
end

local function storeHudIndicatorPosition(pos)
    local clamped = clampHudIndicatorPosition(pos)
    local uiSettings = settingSection('UI')
    uiSettings:set('hudIndicatorX', clamped.x)
    uiSettings:set('hudIndicatorY', clamped.y)
    return clamped
end

local function canDragHudIndicator()
    if readSetting('UI', 'hudIndicatorLockPosition', false) then return false end
    return isInventoryLikeMode(currentModeName())
end


local function ensureHud()
    if hudElement then return hudElement end
    local iconSize = hudIndicatorIconSize()
    local textSize = hudIndicatorTextSize()

    hudElement = ui.create({
        layer = 'Modal',
        type = ui.TYPE.Flex,
        name = 'ToxicologyHudIndicator',
        props = {
            position = hudIndicatorPosition(),
            anchor = util.vector2(1, 1),
            horizontal = true,
            autoSize = true,
            align = ui.ALIGNMENT.Center,
            visible = false,
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture({
                        path = 'icons\\Toxicology\\toxicology.dds',
                    }),
                    size = util.vector2(iconSize, iconSize),
                    color = util.color.rgb(0.55, 0.85, 0.55),
                },
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = '',
                    textSize = textSize,
                    textColor = util.color.rgb(0.55, 0.85, 0.55),
                    textShadow = true,
                    textShadowColor = util.color.rgb(0, 0, 0),
                },
            },
        }),
        userData = {
            dragging = false,
            lastMousePos = nil,
        },
    })

    local function rootLayout()
        return hudElement and hudElement.layout
    end

    local function hudMousePress(data, _)
        if not data or data.button ~= 1 or not canDragHudIndicator() then return end
        local layout = rootLayout()
        if not layout then return end
        layout.userData = layout.userData or {}
        layout.userData.dragging = true
        layout.userData.lastMousePos = data.position
    end

    local function hudMouseRelease(_, _)
        local layout = rootLayout()
        if layout and layout.userData then
            layout.userData.dragging = false
            layout.userData.lastMousePos = nil
        end
    end

    local function hudMouseMove(data, _)
        local layout = rootLayout()
        if not data or not layout or not layout.userData or not layout.userData.dragging or not layout.userData.lastMousePos then return end
        if not canDragHudIndicator() then
            layout.userData.dragging = false
            layout.userData.lastMousePos = nil
            return
        end

        local delta = data.position - layout.userData.lastMousePos
        layout.userData.lastMousePos = data.position

        local currentPosition = layout.props.position or hudIndicatorPosition()
        layout.props.position = storeHudIndicatorPosition(currentPosition + delta)
        hudElement:update()
    end

    local dragEvents = {
        mousePress = async:callback(hudMousePress),
        mouseRelease = async:callback(hudMouseRelease),
        mouseMove = async:callback(hudMouseMove),
    }

    -- Event dispatch goes to the concrete child under the pointer in some
    -- OpenMW builds/layouts. Attach the same drag callbacks to both the root
    -- and its visible children so dragging works when the cursor is over either
    -- the Toxicology icon or the poison text.
    hudElement.layout.events = dragEvents
    hudElement.layout.content[1].events = dragEvents
    hudElement.layout.content[2].events = dragEvents

    return hudElement
end

local function updateHud()
    if not readSetting('UI', 'showHudIndicator', true) then
        destroyHud()
        return
    end
    local equipment = types.Actor.getEquipment(self)
    local weapon = equipment and equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    if not safeWeaponRecord(weapon) then
        if hudElement then hudElement.layout.props.visible = false; hudElement:update() end
        return
    end
    local data = getWeaponPoisonData(weapon)
    if not data or not (data.poisonId or data.layer2PoisonId or data.layer3PoisonId) then
        if hudElement then hudElement.layout.props.visible = false; hudElement:update() end
        return
    end
    local parts = {}
    for _, pair in ipairs({
        { data.poisonId, data.charges },
        { data.layer2PoisonId, data.layer2Charges },
        { data.layer3PoisonId, data.layer3Charges },
    }) do
        local poisonId, charges = pair[1], pair[2]
        if poisonId then
            local potionRec = types.Potion.records[poisonId]
            local name = (potionRec and potionRec.name) or (data.snapshot and data.snapshot[poisonId] and data.snapshot[poisonId].name) or 'Poisoned'
            parts[#parts + 1] = string.format('%s (%d)', name, charges or 0)
        end
    end
    local text = ' ' .. table.concat(parts, ' | ')
    local el = ensureHud()
    local iconSize = hudIndicatorIconSize()
    local textSize = hudIndicatorTextSize()

    -- Update the Image/Text widgets inside our Flex.
    el.layout.content[1].props.size = util.vector2(iconSize, iconSize)
    el.layout.content[2].props.text = text
    el.layout.content[2].props.textSize = textSize
    el.layout.props.position = hudIndicatorPosition()
    el.layout.props.visible = true
    el:update()
end


-- ─── Console helpers ───────────────────────────────────────────────────────

local function consolePrintInfo(msg)
    if ui.printToConsole and ui.CONSOLE_COLOR then
        ui.printToConsole('[Toxicology] ' .. tostring(msg), ui.CONSOLE_COLOR.Info)
    else
        print('[Toxicology] ' .. tostring(msg))
    end
end

local function consolePrintError(msg)
    if ui.printToConsole and ui.CONSOLE_COLOR then
        ui.printToConsole('[Toxicology] ' .. tostring(msg), ui.CONSOLE_COLOR.Error)
    else
        print('[Toxicology] ' .. tostring(msg))
    end
end

local function getToxicologySkillLevel()
    if not I.SkillFramework then return 0 end
    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    local val = stat and stat.modified or config.startLevel
    return math.floor(tonumber(val) or 0)
end

local function setToxicologySkill(target)
    if not I.SkillFramework then return nil end
    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return nil end
    target = math.max(0, math.floor(tonumber(target) or 0))
    local modified = tonumber(stat.modified) or tonumber(stat.base) or config.startLevel
    stat.base = (tonumber(stat.base) or config.startLevel) + (target - modified)
    return stat
end

local function addToxicologySkill(delta)
    local current = getToxicologySkillLevel()
    return setToxicologySkill(current + (tonumber(delta) or 0))
end

local function getToxicologyPerkSummary()
    local skill = getToxicologySkillLevel()
    local perkList = {
        { level = config.perks.masterCoatingLevel, name = 'Master Coating' },
        { level = config.perks.compoundBlendLevel, name = 'Compound Blend' },
        { level = config.perks.efficientCoatingLevel, name = 'Efficient Coating' },
        { level = config.perks.toxicPrecisionLevel, name = 'Toxic Perfection' },
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
    if root ~= 'toxicology' then return end

    if not (I.SkillFramework and I.SkillFramework.getSkillRecord and I.SkillFramework.getSkillRecord(SKILL_ID)) then
        consolePrintError('Toxicology skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: toxicology <amount> | toxicology set <value> | toxicology perk')
        return true
    end

    if rest == 'perk' or rest == 'status' then
        local skill, current, nextPerk = getToxicologyPerkSummary()
        if nextPerk then
            consolePrintInfo(string.format('Toxicology: %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
        else
            consolePrintInfo(string.format('Toxicology: %d | current perk: %s | all perks unlocked', skill, current))
        end
        return true
    end

    local setValue = rest:match('^set%s+(-?%d+)$')
    if setValue then
        local stat = setToxicologySkill(tonumber(setValue))
        if not stat then
            consolePrintError('Unable to access Toxicology stat.')
        else
            local skill, current, nextPerk = getToxicologyPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Toxicology set to %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Toxicology set to %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    local addValue = rest:match('^([+-]?%d+)$')
    if addValue then
        local stat = addToxicologySkill(tonumber(addValue))
        if not stat then
            consolePrintError('Unable to access Toxicology stat.')
        else
            local skill, current, nextPerk = getToxicologyPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Toxicology is now %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Toxicology is now %d | current perk: %s | all perks unlocked', skill, current))
            end
            refreshSkillDescription(true)
        end
        return true
    end

    consolePrintError('Bad syntax. Try: toxicology help')
    return true
end


-- ─── Frame update ──────────────────────────────────────────────────────────
local updateTimer = 0.5
local initRequested = false
local lastDistributedCellKey = nil

local function onFrame(dt)
    -- Input actions are resolved immediately before onFrame. Reading the built-in
    -- Use action here catches the left-click attack/draw edge reliably for bows,
    -- crossbows, and thrown weapons, including shots that later miss.
    updateProjectileAttackStartConsumption()

    -- drain deferred IE badge repaints
    if pendingBadgeRepaint then
        paintInventoryExtenderBadges()
    end
end

local function currentCellKey(obj)
    if not obj or not obj.cell then return nil end
    local cell = obj.cell
    local name = cell.name or ''
    if name ~= '' then return string.lower(name) end
    return string.format('%s,%s', tostring(cell.gridX), tostring(cell.gridY))
end

local function onUpdate(dt)
    dt = tonumber(dt) or 0
    feedbackStyle.update(dt)

    -- Periodic throttled work. Accumulate frame time rather than polling
    -- simulation time for throttling.
    updateTimer = updateTimer + dt
    if updateTimer < 0.5 then return end
    while updateTimer >= 0.5 do
        updateTimer = updateTimer - 0.5
    end


    local enabled = readSetting('', 'enabled', true)

    -- Keep generated-potion count baselines current between brewing sessions.
    -- The actual brew-XP handler still compares against this snapshot at the
    -- moment SkillProgression reports a successful Alchemy create event.
    seedGeneratedIndex()

    -- Mirror player settings into the global runtime section so global.lua
    -- can read them (global scripts can't touch storage.playerSection).
    syncSettingsToGlobal(not initRequested)
    syncRuntimeSkillToGlobal(not initRequested)

    if not enabled then
        updateFeedbackVisibility()
        destroyVanillaInventoryIndicator()
        if hudElement then hudElement.layout.props.visible = false; hudElement:update() end
        return
    end

    -- Try to register skill and apply class bonus during early frames
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

    -- One-shot: once settings are synced, ask global to scan existing poison
    -- records and process the current cell.
    if not initRequested then
        syncRuntimeSkillToGlobal(true)
        core.sendGlobalEvent('Toxicology_RequestInit', { player = self.object })
        initRequested = true
    end

    local cellKey = currentCellKey(self.object)
    if cellKey and cellKey ~= lastDistributedCellKey then
        core.sendGlobalEvent('Toxicology_DistributeCell', { player = self.object })
        lastDistributedCellKey = cellKey
    end

    -- IE tooltip is idempotent — register once IE is available
    if I.InventoryExtender then
        if not tooltipRegistered then
            registerInventoryExtenderTooltip()
        end
        if not ieRowClickRegistered then
            registerInventoryExtenderRowClickHandler()
        end
        updateInventoryExtenderBadges()
    else
        updateVanillaInventoryIndicator()
    end

    -- Refresh the dynamic skill description to reflect current level / perks.
    -- Cached via lastBuiltDescription so this is a no-op when nothing changed.
    refreshSkillDescription()

    -- Expire feedback overlay when its duration is up
    updateFeedbackVisibility()

    -- HUD indicator
    updateHud()
end

-- ─── GRIP compatibility ───────────────────────────────────────────────────

-- GRIP swaps the equipped weapon object for a runtime 1H/2H/sheathed variant
-- and then removes the old object. Toxicology keys ordinary weapon coatings by
-- object id, so the coating must move to the replacement object during GRIP's
-- local equip event. This stays object-id based; using record ids for all GRIP
-- variants would make two identical weapons share one coating state.
local function unsafeObjectField(item, field)
    if not item then return nil end
    local ok, value = pcall(function() return item[field] end)
    if not ok then return nil end
    return value
end

local function poisonTransferKey(item)
    -- Prefer the normal key for valid objects so thrown/projectile special cases
    -- keep their existing behaviour. If GRIP's remove handler has already run,
    -- fall back to the raw object id; non-thrown Toxicology state is stored there.
    local key = poisonStorageKey(item)
    if key then return key end
    return unsafeObjectField(item, 'id')
end

local function transferWeaponPoisonState(oldWeapon, newWeapon, reason)
    local oldKey = poisonTransferKey(oldWeapon)
    local newKey = poisonTransferKey(newWeapon)
    if not oldKey or not newKey or oldKey == newKey then return false end

    -- Player scripts can read ToxicologyWeaponPoison but cannot write it; the
    -- writable owner is global.lua. Keep this local handler as a resolver only:
    -- capture the object-id keys while GRIP's old/new objects are both still
    -- addressable, then ask the global script to perform the actual transfer.
    local oldLiveKey = liveWeaponPoisonStorageKey(oldKey)
    local data = oldLiveKey and copyWeaponPoisonData(weaponPoisonSection:get(oldLiveKey)) or nil
    if not weaponHasActivePoisonData(data) then return false end

    core.sendGlobalEvent('Toxicology_TransferWeaponPoisonState', {
        actor = self.object,
        oldKey = oldKey,
        newKey = newKey,
        reason = reason or 'weapon swap',
    })
    debugLog('Requested weapon coating state transfer ' .. tostring(oldKey) .. ' -> ' .. tostring(newKey)
        .. ' (' .. tostring(reason or 'weapon swap') .. ')', 'debugIntegrationMessages')
    return true
end

local function refreshPoisonUiAfterTransfer(_evt)
    lastInventoryBadgeSignature = nil
    -- The HUD and Inventory Extender icon badge read from the same keyed
    -- storage. Refresh immediately so toggling stance does not leave stale UI.
    updateHud()
    updateInventoryExtenderBadges()
    updateVanillaInventoryIndicator()
end

local function onGripLocalEquip(evt)
    if type(evt) ~= 'table' then return end
    transferWeaponPoisonState(evt.old, evt.object, 'GRIP stance swap')
end

-- ─── Engine handlers / events ──────────────────────────────────────────────

local function onSave()
    return {
        classBonusApplied = appliedClassBonusAmount ~= 0,
        classBonusMode = 'base',
        classBonusAmount = appliedClassBonusAmount,
    }
end

local function onLoad(data)
    feedbackStyle.resetRegistryOnce()
    feedbackStyle.registerCandidate()
    classBonusApplied = (data and data.classBonusApplied) or false
    classBonusMode = (data and data.classBonusMode) or ((classBonusApplied and 'base') or 'none')
    appliedClassBonusAmount = (data and tonumber(data.classBonusAmount)) or ((classBonusApplied and config.classBonus) or 0)
    legacyClassBonusMigrated = false
    classDynamicModifierRegistered = false
    reconcileClassBonusMode()
    -- Seed the brew-detection high-water mark from the current inventory so
    -- existing Generated:0x... potions (carried over from before this mod,
    -- or from previous save sessions) are not incorrectly treated as new
    -- brews on first skillUsed event after load.
    seedGeneratedIndex('seed')
    lastSyncedSkill = nil
    lastSyncedSettingsPayload = nil
    previousAttackPressed = false
    updateTimer = 0.5
    lastAAMClassBonus = nil
    destroyVanillaInventoryIndicator()
    notifyAAM(true)
end

-- Register the alchemy-brew → Toxicology XP redirect. This must be called at
-- script top level (not inside an init function), because SkillProgression
-- replays its registrations on reload.
if I.SkillProgression and I.SkillProgression.addSkillUsedHandler then
    I.SkillProgression.addSkillUsedHandler(onAlchemySkillUsed)
end

return {
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
    eventHandlers = {
        Toxicology_PromptApply = onPromptApply,
        Toxicology_Message     = onMessage,
        Toxicology_GrantXp     = onGrantXp,
        Toxicology_PoisonIdMap = onPoisonIdMap,
        Toxicology_PerkFired             = onPerkFired,
        SkillPerkPopup_Show               = feedbackStyle.onSkillPerkPopupShow,
        Toxicology_PoisonTransferComplete = refreshPoisonUiAfterTransfer,
        OHS_LocalEquip                    = onGripLocalEquip,
        UiModeChanged                     = onUiModeChanged,
        IE_Update                         = scheduleBadgeRepaint,
        MI_Update                         = scheduleBadgeRepaint,
    },
}