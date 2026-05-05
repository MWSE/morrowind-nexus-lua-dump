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

local settingsSection = storage.playerSection("Settings_" .. MODNAME)
local function getSetting(key, default)
    local val = settingsSection:get(key)
    if val == nil then return default end
    return val
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

local function showFeedback(msg)
    if getSetting("showFeedback", false) then
        ui.showMessage(msg)
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
        name = "Staves",
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

-- ─── Magic Class Bonus (+10) ────────────────────────────────────────────────

local classBonusState = {
    applied = false,
    classId = nil,
    amount = 0,
}

local function getPlayerClassRecord()
    local record = types.NPC.record(self)
    if not record or not record.class then return nil, nil end
    return record.class, types.NPC.classes.record(record.class)
end

local function reconcileClassBonus()
    if not hasSkillFramework or not skillIsRegistered() then return end
    if not types.Player.isCharGenFinished(self) then return end

    local currentClassId, classRecord = getPlayerClassRecord()
    if not currentClassId or not classRecord then return end

    local desiredAmount = 0
    if classRecord.specialization == "magic" then
        desiredAmount = CLASS_BONUS_AMOUNT
    end

    local stat = I.SkillFramework.getSkillStat(SKILL_ID)
    if not stat then return end

    if classBonusState.applied and classBonusState.amount > 0 then
        if classBonusState.classId ~= currentClassId or desiredAmount ~= classBonusState.amount then
            stat.base = stat.base - classBonusState.amount
            classBonusState.applied = false
            classBonusState.amount = 0
        end
    end

    if desiredAmount > 0 and (not classBonusState.applied or classBonusState.classId ~= currentClassId) then
        stat.base = stat.base + desiredAmount
        classBonusState.applied = true
        classBonusState.classId = currentClassId
        classBonusState.amount = desiredAmount
    else
        classBonusState.classId = currentClassId
        if desiredAmount == 0 then
            classBonusState.applied = false
            classBonusState.amount = 0
        end
    end
end

-- ─── Staff Detection ────────────────────────────────────────────────────────

local function getEquippedStaff()
    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then return nil end
    if not types.Weapon.objectIsInstance(weapon) then return nil end
    local record = types.Weapon.record(weapon)
    if record.type == types.Weapon.TYPE.BluntTwoWide then
        return weapon
    end
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
            skillGain = 1.5,
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
        local duplicatedGain = sourceGain * (sharePercent / 100)

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
for _, school in ipairs(MAGIC_SCHOOLS) do
    appliedBonuses[school] = 0
    schoolStats[school] = types.NPC.stats.skills[school](self)
end

local function notifyAAM()
    if not (I and I.AAM and I.AAM.reportExternalModifiers) then return end

    local report = {}
    for _, school in ipairs(MAGIC_SCHOOLS) do
        local amount = tonumber(appliedBonuses[school]) or 0
        if amount ~= 0 then
            report[school] = amount
        end
    end

    I.AAM.reportExternalModifiers(MODNAME, next(report) and report or {})
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

    for _, school in ipairs(MAGIC_SCHOOLS) do
        local current = appliedBonuses[school]
        if current ~= targetBonus then
            local stat = schoolStats[school]
            if stat then
                stat.modifier = stat.modifier + (targetBonus - current)
                appliedBonuses[school] = targetBonus
            end
        end
    end

    notifyAAM()
    return targetBonus
end

-- ─── Enchantment Charge Efficiency ─────────────────────────────────────────────

local lastStaffCharge = nil
local lastStaffId = nil

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

    local currentCharge = idata.charge
    local staffId = staff.recordId

    if staffId == lastStaffId and lastStaffCharge and currentCharge then
        local chargeUsed = lastStaffCharge - currentCharge
        if chargeUsed > 0 then
            local skill = getStavesSkillLevel()
            local maxChance = getSetting("maxSaveChance", 50)
            local chance = skill * maxChance / 100
            local roll = math.random(1, 100)
            if roll <= chance then
                idata.charge = lastStaffCharge
                showFeedback("Staves: enchant charge saved")
            end
        end
    end

    lastStaffCharge = idata.charge
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

-- ─── Pending-hit sync (the Throwing! pattern) ───────────────────────────────
-- When the player has a staff equipped and is attacking, we push a "pending
-- staff swing" record into a Runtime_Staves global storage section so the
-- NPC's onHit actor script can apply perk procs. Staves are melee so we
-- don't need animation keys — we just keep state current whenever a staff
-- is equipped. The actor reads: staff recordId, current skill, perk enables.

local function syncRuntimeState()
    local staff = getEquippedStaff()
    local skill = getStavesSkillLevel()
    core.sendGlobalEvent("Staves_UpdateRuntime", {
        active = staff ~= nil and getSetting("enabled", true),
        staffRecordId = staff and staff.recordId or nil,
        skill = skill,

        -- Tuned values so the actor script does not have to re-import config
        concussiveEnabled = getSetting("concussiveEnabled", true),
        concussiveChance = concussiveChance(),
        concussiveFatigue = concussiveFatigue(skill),
        concussiveLevel = config.perks.concussive.level,
        concussiveSound = config.perks.concussive.sound,

        arcaneSiphonEnabled = isArcaneSiphonEnabled(),
        arcaneSiphonChance = arcaneSiphonChance(),
        arcaneSiphonAmount = arcaneSiphonAmount(skill),
        arcaneSiphonLevel = config.perks.arcaneSiphon.level,
        arcaneSiphonSound = config.perks.arcaneSiphon.sound,

        resonantConduitEnabled = isResonantConduitEnabled(),
        resonantConduitChance = resonantConduitChance(),
        resonantConduitCharge = resonantConduitCharge(skill),
        resonantConduitLevel = config.perks.resonantConduit.level,

        nullPulseEnabled = isNullPulseEnabled(),
        nullPulseChance = nullPulseChance(),
        nullPulseDuration = nullPulseDuration(),
        nullPulseLevel = config.perks.nullPulse.level,
        nullPulseSound = config.perks.nullPulse.sound,
    })
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

    if data.procConcussive and getSetting("showFeedback", false) then
        showFeedback(string.format("%s (%.0f fatigue)",
            config.feedback.concussive, data.concussiveFatigue or 0))
    end

    if data.procArcaneSiphon then
        local drained = tonumber(data.arcaneSiphonAmount) or 0
        local restored = restorePlayerMagicka(drained * (config.perks.arcaneSiphon.restoreMultiplier or 1.0))
        if getSetting("showFeedback", false) then
            if restored > 0 then
                showFeedback(string.format("%s (-%.0f target magicka, +%.0f magicka)",
                    config.feedback.arcaneSiphon, drained, restored))
            else
                showFeedback(string.format("%s (-%.0f target magicka)",
                    config.feedback.arcaneSiphon, drained))
            end
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
                local maxCharge = tonumber(record.enchantCapacity) or tonumber(record.charge) or 0
                local amount = tonumber(data.resonantConduitCharge) or 0
                if maxCharge > 0 and amount > 0 then
                    local before = tonumber(idata.charge) or 0
                    local newCharge = math.min(maxCharge, before + amount)
                    idata.charge = newCharge
                    -- Refresh our cached charge so the enchant-saving logic
                    -- doesn't see this as free casting on the next tick.
                    lastStaffCharge = newCharge
                    playPlayerSound(config.perks.resonantConduit.sound)
                    if getSetting("showFeedback", false) then
                        showFeedback(string.format("%s (+%.0f)",
                            config.feedback.resonantConduit, newCharge - before))
                    end
                end
            end
        end
    end

    if data.procNullPulse and getSetting("showFeedback", false) then
        showFeedback(config.feedback.nullPulse)
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

local function stavesPerkEnabled(perkId)
    if perkId == 'concussive' then return getSetting('concussiveEnabled', true) end
    if perkId == 'arcaneSiphon' then return isArcaneSiphonEnabled() end
    if perkId == 'resonantConduit' then return isResonantConduitEnabled() end
    if perkId == 'nullPulse' then return isNullPulseEnabled() end
    return true
end

local function buildSkillDescription()
    local skill = getStavesSkillLevel()
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
        string.format("Current Staves: %d", math.floor(skill)),
    }

    if showMechanicTooltips then
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
                table.insert(perkLines, string.format("No perks unlocked yet. Next unlock at %d Staves.", nextPerk.level))
                table.insert(perkLines, perkSummaryLine(skill, nextPerk.id))
            else
                table.insert(perkLines, "All remaining Staves perks are disabled in settings.")
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
    if not force and description == lastTooltipText then return end
    I.SkillFramework.modifySkill(SKILL_ID, { description = description })
    lastTooltipText = description
end

-- ─── Engine Handlers ────────────────────────────────────────────────────────

local lastStaffState = false
local lastBonus = 0
local previousEq = nil
local throttleTimer = 0
local runtimeSyncThrottle = 0

local function flushSpellXpFeedback(force)
    if pendingSpellXpFeedback <= 0 then return end
    if not force and pendingSpellXpFeedbackTimer > 0 then return end
    showFeedback(string.format("Staves training +%.2f from spellcasting", pendingSpellXpFeedback))
    pendingSpellXpFeedback = 0
    pendingSpellXpFeedbackTimer = 0
end

local function onUpdate(dt)
    if not skillIsRegistered() then
        tryRegisterSkill()
        if not skillIsRegistered() then return end
    end

    reconcileClassBonus()
    checkEnchantEfficiency()
    refreshSkillDescription(false)

    if pendingSpellXpFeedbackTimer > 0 then
        pendingSpellXpFeedbackTimer = math.max(0, pendingSpellXpFeedbackTimer - dt)
    end
    flushSpellXpFeedback(false)

    -- Push runtime state to global section on equipment change OR every ~0.5s
    -- (skill-level changes / setting changes need to propagate too).
    local currentEq = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local currentId = currentEq and currentEq.recordId or nil
    local eqChanged = (currentId ~= previousEq)
    previousEq = currentId

    runtimeSyncThrottle = runtimeSyncThrottle + dt
    if eqChanged or runtimeSyncThrottle >= 0.5 then
        syncRuntimeState()
        runtimeSyncThrottle = 0
    end

    if not eqChanged and dt > 0 then
        throttleTimer = throttleTimer + dt
        if throttleTimer < 0.5 then return end
        throttleTimer = 0
    end

    local staffNow = isStaffEquipped()
    local bonus = applySpellBonus()

    if staffNow ~= lastStaffState or bonus ~= lastBonus then
        if staffNow and bonus > 0 then
            showFeedback("Staves: magic schools +" .. bonus)
        elseif not staffNow and lastStaffState then
            showFeedback("Staves: magic school bonus removed")
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
        consolePrintError('Staves skill is not registered.')
        return true
    end

    if rest == '' or rest == 'help' then
        consolePrintInfo('Usage: staves <amount> | staves set <value> | staves perk')
        return true
    end

    if rest == 'perk' or rest == 'status' then
        local skill, current, nextPerk = getStavesPerkSummary()
        if nextPerk then
            consolePrintInfo(string.format('Staves: %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
        else
            consolePrintInfo(string.format('Staves: %d | current perk: %s | all perks unlocked', skill, current))
        end
        return true
    end

    local setValue = rest:match('^set%s+(-?%d+)$')
    if setValue then
        local stat = setStavesSkill(tonumber(setValue))
        if not stat then
            consolePrintError('Unable to access Staves stat.')
        else
            local skill, current, nextPerk = getStavesPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Staves set to %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Staves set to %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    local addValue = rest:match('^([+-]?%d+)$')
    if addValue then
        local stat = addStavesSkill(tonumber(addValue))
        if not stat then
            consolePrintError('Unable to access Staves stat.')
        else
            local skill, current, nextPerk = getStavesPerkSummary()
            if nextPerk then
                consolePrintInfo(string.format('Staves is now %d | current perk: %s | next: %s at %d', skill, current, nextPerk.name, nextPerk.level))
            else
                consolePrintInfo(string.format('Staves is now %d | current perk: %s | all perks unlocked', skill, current))
            end
        end
        return true
    end

    consolePrintError('Bad syntax. Try: staves help')
    return true
end

local function onLoad(data)
    local savedBonuses = data and data.appliedBonuses or nil
    for _, school in ipairs(MAGIC_SCHOOLS) do
        appliedBonuses[school] = (type(savedBonuses) == 'table' and tonumber(savedBonuses[school])) or 0
    end
    notifyAAM()
    lastStaffState = false
    lastBonus = 0
    previousEq = nil
    throttleTimer = 0
    runtimeSyncThrottle = 0
    lastStaffCharge = nil
    lastStaffId = nil
    pendingSpellXpFeedback = 0
    pendingSpellXpFeedbackTimer = 0
    lastTooltipText = nil

    classBonusState.applied = data and data.classBonusApplied or false
    classBonusState.classId = data and data.classBonusClassId or nil
    classBonusState.amount = data and data.classBonusAmount or 0
end

local function onSave()
    local savedBonuses = {}
    for _, school in ipairs(MAGIC_SCHOOLS) do
        savedBonuses[school] = tonumber(appliedBonuses[school]) or 0
    end

    return {
        classBonusApplied = classBonusState.applied,
        classBonusClassId = classBonusState.classId,
        classBonusAmount = classBonusState.amount,
        appliedBonuses = savedBonuses,
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
    },
}
