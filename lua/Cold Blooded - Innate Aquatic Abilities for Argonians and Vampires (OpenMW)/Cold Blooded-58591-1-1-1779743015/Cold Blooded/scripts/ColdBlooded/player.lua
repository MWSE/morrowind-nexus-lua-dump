--[[
    Cold Blooded - Player Script

    Owns the settings page and group (player section). Pushes a full
    snapshot of NPC-relevant settings to the global script on load
    and on every settings change.

    Implements the underwater-state-dependent features:
      - Night Eye (depth-scaled)
      - Argonian fatigue regen
      - Vampire sun-damage suppression while submerged
      - Puzzle Canal breath suppression + once-per-save message

    Release-readiness notes:
      - Magnitudes applied with ActorActiveEffects:modify are persisted
        through onSave/onLoad so save/load and reloadlua do not stack
        this mod's contributions.
      - Vampire sun-shelter uses three layers while submerged:
        (1) legacy vanilla->sheltered ability swap when available,
        (2) active Sun Damage suppression for non-vanilla sources, and
        (3) small bounded health compensation if the engine already ticked
        sun damage before Lua can reconcile the active effects.
]]

local core    = require('openmw.core')
local types   = require('openmw.types')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local I       = require('openmw.interfaces')
local ui      = require('openmw.ui')

local MODNAME              = "ColdBlooded"
local L10N                 = "ColdBlooded"
local SETTINGS_GROUP       = "SettingsPlayer" .. MODNAME
local LEGACY_GLOBAL_GROUP  = "SettingsGlobal" .. MODNAME
local LEGACY_OLDEST_GROUP  = "Settings_" .. MODNAME
local SAVE_SCHEMA_VERSION  = 2

-- Approximate vertical offset from actor origin to the player's head.
local HEAD_OFFSET_Z = 128

-- How deep (units) the head must be below water to count as fully
-- submerged for depth-scaled effects.
local FULL_SUBMERSION_DEPTH = 128

-- Hysteresis for vampire sun-shelter. We prefer head-depth detection,
-- but also accept OpenMW's actor swimming state because some player
-- skeleton/camera setups report the actor origin differently.
local SUN_SHELTER_ENTER_DEPTH = 16

-- Health compensation is only a fail-safe for a timing edge case where
-- Sun Damage has already ticked before Lua suppresses it. Keep this small
-- so unrelated damage is not meaningfully masked.
local SUN_COMPENSATION_MARGIN = 0.75

local VANILLA_VAMPIRE_SUN_DAMAGE_ABILITY = 'vampire sun damage'
local SHELTERED_VAMPIRE_ABILITY          = 'kd_vampire sun damage'
local BUNDLED_PLUGIN                     = 'Cold Blooded.esp'

-- Throttle: how often applyEffects runs (seconds).
local APPLY_INTERVAL = 0.25

-- -----------------------------------------------------------------
-- Settings registration (player section)
-- -----------------------------------------------------------------

I.Settings.registerPage {
    key         = MODNAME,
    l10n        = L10N,
    name        = "settings_page_name",
    description = "settings_page_desc",
}

I.Settings.registerGroup {
    key              = SETTINGS_GROUP,
    page             = MODNAME,
    l10n             = L10N,
    name             = "settings_group_name",
    description      = "settings_group_desc",
    permanentStorage = true,
    settings = {
        { key = "enabled", renderer = "checkbox", default = true,
          name = "setting_enabled", description = "setting_enabled_desc" },

        { key = "breathArgonian", renderer = "checkbox", default = true,
          name = "setting_breathArgonian", description = "setting_breathArgonian_desc" },
        { key = "breathVampire", renderer = "checkbox", default = true,
          name = "setting_breathVampire", description = "setting_breathVampire_desc" },

        { key = "swiftSwim", renderer = "checkbox", default = true,
          name = "setting_swiftSwim", description = "setting_swiftSwim_desc" },
        { key = "swimBonus", renderer = "number", default = 25,
          name = "setting_swimBonus", description = "setting_swimBonus_desc",
          argument = { integer = true, min = 0, max = 100 } },

        { key = "visionArgonian", renderer = "checkbox", default = true,
          name = "setting_visionArgonian", description = "setting_visionArgonian_desc" },
        { key = "visionVampire", renderer = "checkbox", default = true,
          name = "setting_visionVampire", description = "setting_visionVampire_desc" },
        { key = "visionBonus", renderer = "number", default = 15,
          name = "setting_visionBonus", description = "setting_visionBonus_desc",
          argument = { integer = true, min = 0, max = 100 } },

        { key = "fatigueArgonian", renderer = "checkbox", default = true,
          name = "setting_fatigueArgonian", description = "setting_fatigueArgonian_desc" },
        { key = "fatigueBonus", renderer = "number", default = 0.25,
          name = "setting_fatigueBonus", description = "setting_fatigueBonus_desc",
          argument = { integer = false, min = 0, max = 5 } },

        { key = "vampireSunShelter", renderer = "checkbox", default = true,
          name = "setting_vampireSunShelter", description = "setting_vampireSunShelter_desc" },
    },
}

local settingsSection   = storage.playerSection(SETTINGS_GROUP)
local legacyGlobalSec   = storage.globalSection(LEGACY_GLOBAL_GROUP)
local legacyOldestSec   = storage.playerSection(LEGACY_OLDEST_GROUP)

local SETTING_DEFAULTS = {
    enabled           = true,
    breathArgonian    = true,
    breathVampire     = true,
    swiftSwim         = true,
    swimBonus         = 25,
    visionArgonian    = true,
    visionVampire     = true,
    visionBonus       = 15,
    fatigueArgonian   = true,
    fatigueBonus      = 0.25,
    vampireSunShelter = true,
}

local function getSetting(key)
    local val = settingsSection:get(key)
    if val == nil then val = legacyGlobalSec:get(key) end
    if val == nil then val = legacyOldestSec:get(key) end
    if val == nil then val = SETTING_DEFAULTS[key] end
    return val
end

-- -----------------------------------------------------------------
-- NPC-relevant settings snapshot sent to global script
-- -----------------------------------------------------------------

local function pushSettingsToGlobal()
    core.sendGlobalEvent("ColdBlooded_SettingsChanged", {
        enabled         = getSetting("enabled"),
        breathArgonian  = getSetting("breathArgonian"),
        breathVampire   = getSetting("breathVampire"),
        swiftSwim       = getSetting("swiftSwim"),
        swimBonus       = getSetting("swimBonus"),
    })
end

-- Whenever any player-side setting changes, push the NPC-relevant
-- subset to the global script. Subscribed once at script start.
settingsSection:subscribe(async:callback(function(_, _)
    pushSettingsToGlobal()
end))

-- -----------------------------------------------------------------
-- Puzzle Canal
-- -----------------------------------------------------------------

local PUZZLE_CANAL_CELLS = {
    ["vivec, puzzle canal, center"] = true,
}

local PUZZLE_CANAL_MSG_KEYS = {
    "puzzle_canal_msg_1",
    "puzzle_canal_msg_2",
    "puzzle_canal_msg_3",
    "puzzle_canal_msg_4",
    "puzzle_canal_msg_5",
}

-- -----------------------------------------------------------------
-- State
-- -----------------------------------------------------------------

local applied = { breath = 0, swim = 0, vision = 0, sun = 0 }
local puzzleCanalActive = false
local lastCellId        = nil
local lastUpdateTime    = nil
local nextApplyTime     = 0
local saveData          = nil
local sunShelterActive  = false
local lastHealth        = nil
local warnedMissingShelterAbility = false

-- -----------------------------------------------------------------
-- Small utilities
-- -----------------------------------------------------------------

local function positiveNumber(value)
    local num = tonumber(value) or 0
    if num < 0 then return 0 end
    return num
end

local function numberOrZero(value)
    return tonumber(value) or 0
end

local function copyAppliedState()
    return {
        breath = positiveNumber(applied.breath),
        swim   = positiveNumber(applied.swim),
        vision = positiveNumber(applied.vision),
        sun    = numberOrZero(applied.sun),
    }
end

local function readAppliedState(data)
    local state = data and data.applied
    if type(state) ~= "table" then
        return nil
    end
    return {
        breath = positiveNumber(state.breath),
        swim   = positiveNumber(state.swim),
        vision = positiveNumber(state.vision),
        sun    = numberOrZero(state.sun),
    }
end

local function persistAppliedState()
    if saveData then
        saveData.applied = copyAppliedState()
        saveData.sunShelterActive = sunShelterActive
        saveData.schemaVersion = SAVE_SCHEMA_VERSION
    end
end

local function currentCellId()
    local cell = self.cell
    if not cell then return "" end
    return (cell.name and cell.name:lower()) or ""
end

local function isPuzzleCanalCell()
    return PUZZLE_CANAL_CELLS[currentCellId()] or false
end

-- -----------------------------------------------------------------
-- Detection
-- -----------------------------------------------------------------

local function isArgonian()
    local record = types.NPC.record(self)
    return record and record.race and record.race:lower() == "argonian"
end

local function isVampire()
    local effects = types.Actor.activeEffects(self)
    if not effects then return false end
    local eff = effects:getEffect(core.magic.EFFECT_TYPE.Vampirism)
    return eff and eff.magnitude and eff.magnitude > 0
end

local function actorIsSwimmingSafe()
    local ok, result = pcall(function()
        return types.Actor.isSwimming(self)
    end)
    return ok and result == true
end

local function headSubmersionDepth()
    local cell = self.cell
    if not cell or not cell.hasWater then return 0 end
    local waterLevel = cell.waterLevel
    if not waterLevel then return 0 end
    local headZ = self.position.z + HEAD_OFFSET_Z
    local depth = waterLevel - headZ
    if depth <= 0 then return 0 end
    return depth
end

local function shouldUseSunShelter()
    local depth = headSubmersionDepth()
    local swimming = actorIsSwimmingSafe()
    if sunShelterActive then
        return depth > 0 or swimming
    end
    return depth >= SUN_SHELTER_ENTER_DEPTH or swimming
end

local function hasSpell(actorSpells, spellId)
    if not actorSpells then return false end

    -- Direct lookup is the documented fast path. The iteration fallback
    -- covers API/version edge cases and keeps detection robust if the
    -- userdata proxy does not support string indexing in a specific build.
    if actorSpells[spellId] ~= nil then return true end
    for _, spell in pairs(actorSpells) do
        if spell and spell.id == spellId then return true end
    end
    return false
end

local function contentFileLoaded(fileName)
    local ok, result = pcall(function()
        return core.contentFiles and core.contentFiles.has(fileName)
    end)
    return ok and result == true
end

local function spellRecordAvailable(spellId)
    local ok, result = pcall(function()
        return core.magic
           and core.magic.spells
           and core.magic.spells.records
           and core.magic.spells.records[spellId] ~= nil
    end)
    return ok and result == true
end

local function currentEffectMagnitude(effectId)
    if effectId == nil then return 0 end
    local effects = types.Actor.activeEffects(self)
    if not effects then return 0 end
    local eff = effects:getEffect(effectId)
    return positiveNumber(eff and eff.magnitude)
end

local function externalSunDamageMagnitude()
    local observedMagnitude = currentEffectMagnitude(core.magic.EFFECT_TYPE.SunDamage)
    local sourceMagnitude = observedMagnitude - numberOrZero(applied.sun)
    if sourceMagnitude < 0 then sourceMagnitude = 0 end
    return sourceMagnitude
end

local function healthSnapshot()
    local ok, health = pcall(function()
        return types.Actor.stats.dynamic.health(self)
    end)
    if not ok or not health then return nil, nil, nil end

    local current = tonumber(health.current)
    if not current then return nil, nil, nil end

    local maxHealth = positiveNumber(health.base) + numberOrZero(health.modifier)
    if maxHealth <= 0 then maxHealth = nil end

    return current, maxHealth, health
end

local function compensateShelteredSunDamage(deltaTime, shouldSuppress, sourceMagnitude)
    local current, maxHealth, health = healthSnapshot()
    if not current then
        lastHealth = nil
        return
    end

    if shouldSuppress and lastHealth and current < lastHealth then
        local dt = positiveNumber(deltaTime)
        if dt <= 0 then dt = APPLY_INTERVAL end

        -- If we saw a source Sun Damage magnitude, use it. If the spell
        -- layer was removed before activeEffects reported a magnitude, still
        -- allow one vanilla-strength point per second as a conservative
        -- timing guard.
        local effectiveMagnitude = positiveNumber(sourceMagnitude)
        if effectiveMagnitude <= 0 then effectiveMagnitude = 1 end

        local maxCompensation = effectiveMagnitude * dt + SUN_COMPENSATION_MARGIN
        local lost = lastHealth - current
        local restore = lost
        if restore > maxCompensation then restore = maxCompensation end

        if restore > 0 then
            local target = current + restore
            if maxHealth and target > maxHealth then target = maxHealth end
            if target > current then
                health.current = target
                current = target
            end
        end
    end

    lastHealth = current
end

local function submersionFraction()
    local depth = headSubmersionDepth()
    if depth <= 0 then return 0 end
    local frac = depth / FULL_SUBMERSION_DEPTH
    if frac > 1 then frac = 1 end
    return frac
end

-- -----------------------------------------------------------------
-- Morroswim detection (best-effort)
-- -----------------------------------------------------------------

local PROBE_NAMES = { "SwimmingSkill", "Morroswim" }

local function morroswimManagingBreath()
    for _, name in ipairs(PROBE_NAMES) do
        local iface = I[name]
        if type(iface) == "table" then
            if type(iface.isManagingBreath) == "function" then
                local ok, result = pcall(iface.isManagingBreath)
                if ok and result then return true end
            end
            if type(iface.isActive) == "function" then
                local ok, result = pcall(iface.isActive)
                if ok and result then return true end
            end
        end
    end
    return false
end

-- -----------------------------------------------------------------
-- Effect tracking (player side)
-- -----------------------------------------------------------------

local function setTrackedEffect(key, effectId, targetMagnitude)
    targetMagnitude = positiveNumber(targetMagnitude)
    local current = positiveNumber(applied[key])
    local delta = targetMagnitude - current
    if delta == 0 then return end
    local effects = types.Actor.activeEffects(self)
    if not effects then return end
    effects:modify(delta, effectId)
    applied[key] = targetMagnitude
    persistAppliedState()
end

local function setTrackedEffectSigned(key, effectId, targetContribution)
    if effectId == nil then return end
    targetContribution = numberOrZero(targetContribution)
    local current = numberOrZero(applied[key])
    local delta = targetContribution - current
    if delta == 0 then return end
    local effects = types.Actor.activeEffects(self)
    if not effects then return end
    effects:modify(delta, effectId)
    applied[key] = targetContribution
    persistAppliedState()
end

local function clearAllEffects()
    setTrackedEffect("breath", core.magic.EFFECT_TYPE.WaterBreathing, 0)
    setTrackedEffect("swim",   core.magic.EFFECT_TYPE.SwiftSwim,      0)
    setTrackedEffect("vision", core.magic.EFFECT_TYPE.NightEye,       0)
    setTrackedEffectSigned("sun", core.magic.EFFECT_TYPE.SunDamage,   0)
end

local function computeEffectTargets()
    if not getSetting("enabled") then
        return 0, 0, 0
    end

    local argonian = isArgonian()
    local vampire  = isVampire()
    local depthFrac = submersionFraction()

    local breathTarget = 0
    if getSetting("breathArgonian") and argonian then breathTarget = 1 end
    if getSetting("breathVampire")  and vampire  then breathTarget = 1 end
    if puzzleCanalActive or isPuzzleCanalCell() then breathTarget = 0 end
    if morroswimManagingBreath() then breathTarget = 0 end

    local swimTarget = 0
    if getSetting("swiftSwim") and argonian then
        local bonus = positiveNumber(getSetting("swimBonus"))
        if bonus > 0 then swimTarget = bonus end
    end

    local visionTarget = 0
    local visionEnabled = (argonian and getSetting("visionArgonian"))
                       or (vampire  and getSetting("visionVampire"))
    if visionEnabled and depthFrac > 0 then
        local maxMag = positiveNumber(getSetting("visionBonus"))
        visionTarget = math.floor(maxMag * depthFrac + 0.5)
    end

    return breathTarget, swimTarget, visionTarget
end

local function inferAppliedStateForLegacySave()
    local breathTarget, swimTarget, visionTarget = computeEffectTargets()
    return {
        breath = breathTarget,
        swim   = swimTarget,
        vision = visionTarget,
        sun    = 0,
    }
end

-- -----------------------------------------------------------------
-- Per-tick regen
-- -----------------------------------------------------------------

local function restoreFatigue(deltaTime)
    if deltaTime <= 0 then return end
    if not getSetting("enabled") then return end
    if not isArgonian() then return end
    if not getSetting("fatigueArgonian") then return end
    if submersionFraction() < 1 then return end

    local perSecond = getSetting("fatigueBonus")
    if not perSecond or perSecond <= 0 then return end
    if perSecond > 5 then perSecond = 5 end

    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    if not fatigue then return end

    local maxFatigue = (fatigue.base or 0) + (fatigue.modifier or 0)
    if maxFatigue <= 0 then return end

    local newValue = (fatigue.current or 0) + perSecond * deltaTime
    if newValue < 0          then newValue = 0 end
    if newValue > maxFatigue then newValue = maxFatigue end
    fatigue.current = newValue
end

-- -----------------------------------------------------------------
-- Vampire sun shelter
-- -----------------------------------------------------------------

local function warnShelterAbilityUnavailable(reason)
    if warnedMissingShelterAbility then return end
    warnedMissingShelterAbility = true

    local espLoaded = contentFileLoaded(BUNDLED_PLUGIN)
    local recordAvailable = spellRecordAvailable(SHELTERED_VAMPIRE_ABILITY)
    local detail = tostring(reason or "unknown error")

    print("[Cold Blooded] Unable to apply underwater vampire shelter ability '"
          .. SHELTERED_VAMPIRE_ABILITY .. "'. "
          .. "ESP loaded=" .. tostring(espLoaded)
          .. ", record available=" .. tostring(recordAvailable)
          .. ", error=" .. detail)

    local L = core.l10n(L10N)
    if not espLoaded or not recordAvailable then
        ui.showMessage(L("missing_shelter_ability_msg"))
    else
        ui.showMessage(L("failed_shelter_ability_msg"))
    end
end

local function safeAddSpell(spells, spellId)
    if hasSpell(spells, spellId) then return true end

    if spellId == SHELTERED_VAMPIRE_ABILITY and not spellRecordAvailable(spellId) then
        warnShelterAbilityUnavailable("record not available")
        return false
    end

    local ok, err = pcall(function()
        spells:add(spellId)
    end)
    if not ok then
        if spellId == SHELTERED_VAMPIRE_ABILITY then
            warnShelterAbilityUnavailable(err)
        else
            print("[Cold Blooded] Could not add ability '" .. spellId .. "': " .. tostring(err))
        end
        return false
    end

    -- Do not immediately re-read actorSpells here. In OpenMW, mutation
    -- can be accepted by the engine while the local userdata view still
    -- reflects the pre-mutation spell list during the current update.
    return true
end

local function safeRemoveSpell(spells, spellId)
    if not hasSpell(spells, spellId) then return true end
    local ok, err = pcall(function()
        spells:remove(spellId)
    end)
    if not ok then
        print("[Cold Blooded] Could not remove ability '" .. spellId .. "': " .. tostring(err))
        return false
    end

    -- See safeAddSpell: successful engine mutation is sufficient.
    return true
end

-- Cancel the active Sun Damage magnitude without assuming which spell
-- supplied it. This is the compatibility path for vampire overhauls.
local function updateSunDamageSuppression(shouldSuppress, sourceMagnitude)
    if not shouldSuppress then
        setTrackedEffectSigned("sun", core.magic.EFFECT_TYPE.SunDamage, 0)
        return 0
    end

    local magnitude = sourceMagnitude
    if magnitude == nil then
        magnitude = externalSunDamageMagnitude()
    end
    magnitude = positiveNumber(magnitude)

    local targetContribution = 0
    if magnitude > 0 then
        targetContribution = -magnitude
    end

    setTrackedEffectSigned("sun", core.magic.EFFECT_TYPE.SunDamage, targetContribution)
    return magnitude
end

local function restoreVanillaSunAbilityIfNeeded(spells)
    if not spells then return end
    if hasSpell(spells, SHELTERED_VAMPIRE_ABILITY) then
        if not hasSpell(spells, VANILLA_VAMPIRE_SUN_DAMAGE_ABILITY) then
            safeAddSpell(spells, VANILLA_VAMPIRE_SUN_DAMAGE_ABILITY)
        end
        safeRemoveSpell(spells, SHELTERED_VAMPIRE_ABILITY)
    end
end

-- Suppress Sun Damage while submerged. The first layer is the original
-- vanilla->sheltered ability swap, because that removes the engine's Sun
-- Damage source cleanly while preserving Vampirism. The second layer cancels
-- any remaining Sun Damage magnitude from vampire overhauls. The last layer
-- compensates a small bounded amount of health if the engine ticked damage
-- earlier in the frame.
local function updateVampireSunShelter(deltaTime)
    local spells = types.Actor.spells(self)
    local sourceMagnitude = externalSunDamageMagnitude()

    local shouldSuppress = getSetting("enabled")
        and getSetting("vampireSunShelter")
        and isVampire()
        and shouldUseSunShelter()

    if shouldSuppress and spells then
        local hasVanillaAbility = hasSpell(spells, VANILLA_VAMPIRE_SUN_DAMAGE_ABILITY)
        local hasShelteredAbility = hasSpell(spells, SHELTERED_VAMPIRE_ABILITY)

        if hasVanillaAbility and not hasShelteredAbility then
            hasShelteredAbility = safeAddSpell(spells, SHELTERED_VAMPIRE_ABILITY)
        end

        if hasVanillaAbility and hasShelteredAbility then
            safeRemoveSpell(spells, VANILLA_VAMPIRE_SUN_DAMAGE_ABILITY)
        end
    elseif spells then
        restoreVanillaSunAbilityIfNeeded(spells)
    end

    local suppressedMagnitude = updateSunDamageSuppression(shouldSuppress, sourceMagnitude)
    if suppressedMagnitude > sourceMagnitude then
        sourceMagnitude = suppressedMagnitude
    end

    compensateShelteredSunDamage(deltaTime, shouldSuppress, sourceMagnitude)
    sunShelterActive = shouldSuppress
    persistAppliedState()
end

local function applyEffects()
    local breathTarget, swimTarget, visionTarget = computeEffectTargets()
    setTrackedEffect("breath", core.magic.EFFECT_TYPE.WaterBreathing, breathTarget)
    setTrackedEffect("swim",   core.magic.EFFECT_TYPE.SwiftSwim,      swimTarget)
    setTrackedEffect("vision", core.magic.EFFECT_TYPE.NightEye,       visionTarget)
end

-- -----------------------------------------------------------------
-- Cell monitoring + Puzzle Canal message
-- -----------------------------------------------------------------

local function showPuzzleCanalMessage()
    if saveData and saveData.shownPuzzleCanalMessage then return end

    local argonian = isArgonian()
    local vampire  = isVampire()
    local wouldHaveBreathed =
        (argonian and getSetting("breathArgonian"))
        or (vampire and getSetting("breathVampire"))
    if not wouldHaveBreathed then return end

    local L = core.l10n(L10N)
    local mix = (math.random() * 1000) + core.getSimulationTime()
    local idx = 1 + (math.floor(mix) % #PUZZLE_CANAL_MSG_KEYS)
    ui.showMessage(L(PUZZLE_CANAL_MSG_KEYS[idx]))

    if saveData then saveData.shownPuzzleCanalMessage = true end
end

local function checkCell()
    local cellId = currentCellId()
    if cellId == lastCellId then return end
    lastCellId = cellId

    local wasPuzzle = puzzleCanalActive
    puzzleCanalActive = PUZZLE_CANAL_CELLS[cellId] or false
    if puzzleCanalActive and not wasPuzzle then
        showPuzzleCanalMessage()
    end
    applyEffects()
end

-- -----------------------------------------------------------------
-- Engine handlers
-- -----------------------------------------------------------------

local function onUpdate()
    local now = core.getSimulationTime()
    local deltaTime = 0
    if lastUpdateTime ~= nil then
        deltaTime = now - lastUpdateTime
        if deltaTime < 0    then deltaTime = 0 end
        if deltaTime > 0.25 then deltaTime = 0.25 end
    end
    lastUpdateTime = now

    checkCell()

    if now >= nextApplyTime then
        nextApplyTime = now + APPLY_INTERVAL
        applyEffects()
    end

    restoreFatigue(deltaTime)
    updateVampireSunShelter(deltaTime)
end

local function resetTransientState()
    puzzleCanalActive = false
    lastCellId     = nil
    lastUpdateTime = nil
    nextApplyTime  = 0
    warnedMissingShelterAbility = false
    lastHealth = nil
end

local function inferSunShelterActive()
    local spells = types.Actor.spells(self)
    return hasSpell(spells, SHELTERED_VAMPIRE_ABILITY)
end

local function normalizeSaveData(data)
    local normalized = data or {}
    if normalized.shownPuzzleCanalMessage == nil then
        normalized.shownPuzzleCanalMessage = false
    end
    normalized.schemaVersion = SAVE_SCHEMA_VERSION
    return normalized
end

local function onInit()
    saveData = normalizeSaveData({ shownPuzzleCanalMessage = false })
    applied = { breath = 0, swim = 0, vision = 0, sun = 0 }
    sunShelterActive = inferSunShelterActive()
    resetTransientState()
    persistAppliedState()
    -- Push settings to global so NPCs pick up the current config
    -- from the moment the game starts.
    pushSettingsToGlobal()
end

local function onLoad(data)
    local hadPriorSaveData = type(data) == "table"
    saveData = normalizeSaveData(data)
    resetTransientState()

    local savedApplied = readAppliedState(saveData)
    if savedApplied then
        applied = savedApplied
    elseif hadPriorSaveData then
        -- Migration path for saves produced by earlier releases that
        -- modified active effects but did not persist their contribution
        -- bookkeeping. This prevents the first load after upgrade from
        -- adding a second copy of the same contribution.
        applied = inferAppliedStateForLegacySave()
    else
        -- First install into an existing save: there is no previous
        -- Cold Blooded contribution to preserve.
        applied = { breath = 0, swim = 0, vision = 0, sun = 0 }
    end

    if type(saveData.sunShelterActive) == "boolean" then
        sunShelterActive = saveData.sunShelterActive
    else
        sunShelterActive = inferSunShelterActive()
    end

    persistAppliedState()
    pushSettingsToGlobal()
end

local function onSave()
    if not saveData then
        saveData = normalizeSaveData({ shownPuzzleCanalMessage = false })
    end
    persistAppliedState()
    return saveData
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit   = onInit,
        onLoad   = onLoad,
        onSave   = onSave,
    },
}
