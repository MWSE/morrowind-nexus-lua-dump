--[[
    Evasion! — Actor Script (CUSTOM)
    Calculates and applies evasion Sanctuary for NPCs.
    Also receives local perk effects from the player script/global bridge.
]]

local core    = require('openmw.core')
local async   = require('openmw.async')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local self    = require('openmw.self')
local anim    = require('openmw.animation')

local EFFECT_ID = core.magic.EFFECT_TYPE.Sanctuary
local BLIND_ID = core.magic.EFFECT_TYPE.Blind
local CALM_HUMANOID_ID = core.magic.EFFECT_TYPE.CalmHumanoid
local CALM_CREATURE_ID = core.magic.EFFECT_TYPE.CalmCreature

local floor = math.floor
local max = math.max
local min = math.min

local isNpcActor = (not types.Player.objectIsInstance(self)) and types.NPC.objectIsInstance(self)

local function playBlindFx()
    local mgef = core.magic.effects.records[BLIND_ID]
    if not mgef then return end
    if mgef.hitStatic and types.Static.records[mgef.hitStatic] then
        local model = types.Static.records[mgef.hitStatic].model
        if model then
            anim.addVfx(self, model)
        end
    end
    if mgef.school then
        core.sound.playSound3d(mgef.school .. ' hit', self)
    else
        core.sound.playSound3d('illusion hit', self)
    end
end

local DEFAULT_SETTINGS = {
    maxSanctuary = 30,
    lightMult = 60,
    mediumMult = 35,
    heavyMult = 15,
    npcMult = 100,
}

-- Custom actor scripts cannot access player storage. Keep the values local and
-- optionally read a global mirror if one exists. Storage access is relatively
-- expensive when multiplied across every active actor, so values are cached and
-- refreshed periodically instead of fetched on every Sanctuary recalculation.
local settingsSection = storage.globalSection and storage.globalSection("Settings_Evasion") or nil
local function getSetting(key, default)
    local fallback = default
    if fallback == nil then fallback = DEFAULT_SETTINGS[key] end
    if settingsSection then
        local val = settingsSection:get(key)
        if val ~= nil then return val end
    end
    return fallback
end

local cachedMaxSanctuary = DEFAULT_SETTINGS.maxSanctuary
local cachedLightPct = DEFAULT_SETTINGS.lightMult * 0.01
local cachedMediumPct = DEFAULT_SETTINGS.mediumMult * 0.01
local cachedHeavyPct = DEFAULT_SETTINGS.heavyMult * 0.01
local cachedNpcMult = DEFAULT_SETTINGS.npcMult * 0.01
local settingsRefreshEvery = 2.0
local nextSettingsRefreshTime = 0

local function refreshSettings(force)
    local now = core.getSimulationTime()
    if not force and now < nextSettingsRefreshTime then return end

    cachedMaxSanctuary = getSetting("maxSanctuary", 30)
    cachedLightPct = getSetting("lightMult", 60) * 0.01
    cachedMediumPct = getSetting("mediumMult", 35) * 0.01
    cachedHeavyPct = getSetting("heavyMult", 15) * 0.01
    cachedNpcMult = getSetting("npcMult", 100) * 0.01
    nextSettingsRefreshTime = now + settingsRefreshEvery
end

local SLOT = types.Actor.EQUIPMENT_SLOT
local ARMOR_TYPE = types.Armor.TYPE
local armorSlotWeights = {
    [SLOT.Helmet] = 0.08, [SLOT.Cuirass] = 0.28,
    [SLOT.LeftPauldron] = 0.05, [SLOT.RightPauldron] = 0.05,
    [SLOT.Greaves] = 0.14, [SLOT.Boots] = 0.14,
    [SLOT.LeftGauntlet] = 0.04, [SLOT.RightGauntlet] = 0.04,
    [SLOT.CarriedLeft] = 0.18,
}

local armorSlots = {
    { slot = SLOT.Helmet,       weight = armorSlotWeights[SLOT.Helmet] },
    { slot = SLOT.Cuirass,      weight = armorSlotWeights[SLOT.Cuirass] },
    { slot = SLOT.LeftPauldron, weight = armorSlotWeights[SLOT.LeftPauldron] },
    { slot = SLOT.RightPauldron,weight = armorSlotWeights[SLOT.RightPauldron] },
    { slot = SLOT.Greaves,      weight = armorSlotWeights[SLOT.Greaves] },
    { slot = SLOT.Boots,        weight = armorSlotWeights[SLOT.Boots] },
    { slot = SLOT.LeftGauntlet, weight = armorSlotWeights[SLOT.LeftGauntlet] },
    { slot = SLOT.RightGauntlet,weight = armorSlotWeights[SLOT.RightGauntlet] },
    { slot = SLOT.CarriedLeft,  weight = armorSlotWeights[SLOT.CarriedLeft] },
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

local armorWeightClassCache = {}
local function getArmorWeightClass(armorRecord)
    local cacheKey = armorRecord.id or armorRecord
    local cached = armorWeightClassCache[cacheKey]
    if cached then return cached end

    local weight = armorRecord.weight
    local result
    if weight == 0 then
        result = "unarmored"
    else
        local refWeight = armorWeightGMST[armorRecord.type] or 0
        if refWeight <= 0 then
            result = "heavy"
        else
            local eps = 5e-4
            if weight <= refWeight * lightMaxMod + eps then result = "light"
            elseif weight <= refWeight * medMaxMod + eps then result = "medium"
            else result = "heavy" end
        end
    end

    armorWeightClassCache[cacheKey] = result
    return result
end

local previousEvasion = 0
local blindMagnitudeApplied = 0
local blindExpireTime = 0
local calmHumanoidApplied = 0
local calmCreatureApplied = 0
local calmExpireTime = 0

local equipmentCacheValid = false
local cachedEquipment = {}
local cachedUnarmoredWeight = 1.0
local cachedLightWeight = 0
local cachedMediumWeight = 0
local cachedHeavyWeight = 0

local function getFatigueFactor(actor)
    local fatigue = types.Actor.stats.dynamic.fatigue(actor)
    local maxFatigue = max(1, fatigue.base + fatigue.modifier)
    local ratio = max(0, min(1, fatigue.current / maxFatigue))
    return 0.2 + 0.8 * ratio
end

local function getEncumbranceFactor(actor)
    local capacity = max(1, types.Actor.getCapacity(actor))
    local ratio = max(0, types.Actor.getEncumbrance(actor) / capacity)
    if ratio <= 0.5 then return 1.0 end
    local t = min(1, (ratio - 0.5) / 0.45)
    return max(0.05, 1.0 - 0.95 * t)
end

local function refreshArmorMixIfNeeded()
    local equipment = types.Actor.getEquipment(self)
    local changed = not equipmentCacheValid

    if not changed then
        for _, data in ipairs(armorSlots) do
            if cachedEquipment[data.slot] ~= equipment[data.slot] then
                changed = true
                break
            end
        end
    end

    if not changed then return end

    local unarm, light, med, heavy = 0, 0, 0, 0
    for _, data in ipairs(armorSlots) do
        local slot = data.slot
        local item = equipment[slot]
        local w = data.weight
        cachedEquipment[slot] = item

        if item and types.Armor.objectIsInstance(item) then
            local wc = getArmorWeightClass(types.Armor.record(item))
            if wc == "light" then light = light + w
            elseif wc == "medium" then med = med + w
            elseif wc == "heavy" then heavy = heavy + w
            else unarm = unarm + w end
        else
            if slot ~= SLOT.CarriedLeft or not item then unarm = unarm + w end
        end
    end

    cachedUnarmoredWeight = unarm
    cachedLightWeight = light
    cachedMediumWeight = med
    cachedHeavyWeight = heavy
    equipmentCacheValid = true
end

local function setSanctuaryMagnitude(evasion)
    local delta = evasion - previousEvasion
    if delta ~= 0 then
        types.Actor.activeEffects(self):modify(delta, EFFECT_ID)
        previousEvasion = evasion
    end
end

local function calcAndApplySanctuary()
    if not isNpcActor then return end

    refreshSettings(false)
    if cachedMaxSanctuary <= 0 or cachedNpcMult <= 0 then
        setSanctuaryMagnitude(0)
        return
    end

    refreshArmorMixIfNeeded()

    local skill = types.NPC.stats.skills.unarmored(self).modified
    local retention = cachedUnarmoredWeight
        + (cachedLightWeight * cachedLightPct)
        + (cachedMediumWeight * cachedMediumPct)
        + (cachedHeavyWeight * cachedHeavyPct)
    local fatigueFactor = getFatigueFactor(self)
    local encumbranceFactor = getEncumbranceFactor(self)
    local evasion = floor(skill * retention * cachedMaxSanctuary / 100 * fatigueFactor * encumbranceFactor * cachedNpcMult)
    setSanctuaryMagnitude(evasion)
end

local function updateTemporaryEffects()
    if blindMagnitudeApplied == 0 and calmHumanoidApplied == 0 and calmCreatureApplied == 0 then return end

    local now = core.getSimulationTime()
    local effects = types.Actor.activeEffects(self)

    if blindMagnitudeApplied ~= 0 and now >= blindExpireTime then
        effects:modify(-blindMagnitudeApplied, BLIND_ID)
        blindMagnitudeApplied = 0
        blindExpireTime = 0
    end

    if (calmHumanoidApplied ~= 0 or calmCreatureApplied ~= 0) and now >= calmExpireTime then
        if calmHumanoidApplied ~= 0 then
            effects:modify(-calmHumanoidApplied, CALM_HUMANOID_ID)
            calmHumanoidApplied = 0
        end
        if calmCreatureApplied ~= 0 then
            effects:modify(-calmCreatureApplied, CALM_CREATURE_ID)
            calmCreatureApplied = 0
        end
        calmExpireTime = 0
    end
end

-- Use simulation timers instead of an onUpdate poll on every active actor. The
-- old 0.25s polling loop produced measurable Lua ops across crowded scenes even
-- when an actor's equipment and settings had not changed. A 1s actor timer keeps
-- NPC Sanctuary current enough for combat while avoiding per-frame script work.
local sanctuaryCheckEvery = 1.0
local initialSanctuaryDelay = 0.1 + math.random() * sanctuaryCheckEvery
local minimumTimerDelay = 0.05
local sanctuaryTimerActive = false

local function scheduleSanctuaryUpdate(delay)
    if not isNpcActor or sanctuaryTimerActive then return end

    sanctuaryTimerActive = true
    async:newUnsavableSimulationTimer(max(minimumTimerDelay, delay or sanctuaryCheckEvery), function()
        sanctuaryTimerActive = false
        calcAndApplySanctuary()
        scheduleSanctuaryUpdate(sanctuaryCheckEvery)
    end)
end

local function scheduleBlindExpiry()
    if blindMagnitudeApplied == 0 then return end

    local expectedExpireTime = blindExpireTime
    async:newUnsavableSimulationTimer(max(minimumTimerDelay, expectedExpireTime - core.getSimulationTime()), function()
        updateTemporaryEffects()
        if blindMagnitudeApplied ~= 0 and blindExpireTime ~= expectedExpireTime then
            scheduleBlindExpiry()
        end
    end)
end

local function scheduleCalmExpiry()
    if calmHumanoidApplied == 0 and calmCreatureApplied == 0 then return end

    local expectedExpireTime = calmExpireTime
    async:newUnsavableSimulationTimer(max(minimumTimerDelay, expectedExpireTime - core.getSimulationTime()), function()
        updateTemporaryEffects()
        if (calmHumanoidApplied ~= 0 or calmCreatureApplied ~= 0) and calmExpireTime ~= expectedExpireTime then
            scheduleCalmExpiry()
        end
    end)
end

local function startTimers()
    if isNpcActor then
        refreshSettings(true)
        scheduleSanctuaryUpdate(initialSanctuaryDelay)
    end
    scheduleBlindExpiry()
    scheduleCalmExpiry()
end

local function onLoad(data)
    previousEvasion = (data and data.previousEvasion) or 0
    blindMagnitudeApplied = (data and data.blindMagnitudeApplied) or 0
    blindExpireTime = (data and data.blindExpireTime) or 0
    calmHumanoidApplied = (data and data.calmHumanoidApplied) or 0
    calmCreatureApplied = (data and data.calmCreatureApplied) or 0
    calmExpireTime = (data and data.calmExpireTime) or 0
    updateTemporaryEffects()
    startTimers()
end

local function onSave()
    return {
        previousEvasion = previousEvasion,
        blindMagnitudeApplied = blindMagnitudeApplied,
        blindExpireTime = blindExpireTime,
        calmHumanoidApplied = calmHumanoidApplied,
        calmCreatureApplied = calmCreatureApplied,
        calmExpireTime = calmExpireTime,
    }
end

local function applyRiposte(data)
    local amount = tonumber(data and data.amount) or 0
    if amount <= 0 or types.Actor.isDead(self) then return end
    local health = types.Actor.stats.dynamic.health(self)
    health.current = health.current - amount
end

local function applyAshSand(data)
    local magnitude = max(0, tonumber(data and data.magnitude) or 0)
    local duration = max(0, tonumber(data and data.duration) or 0)
    if magnitude <= 0 or duration <= 0 or types.Actor.isDead(self) then return end

    local effects = types.Actor.activeEffects(self)
    if blindMagnitudeApplied ~= 0 then
        effects:modify(-blindMagnitudeApplied, BLIND_ID)
    end
    effects:modify(magnitude, BLIND_ID)
    blindMagnitudeApplied = magnitude
    blindExpireTime = core.getSimulationTime() + duration
    playBlindFx()
    scheduleBlindExpiry()
end

local function applyVanishCalm(data)
    local magnitude = max(0, tonumber(data and data.magnitude) or 0)
    local duration = max(0, tonumber(data and data.duration) or 0)
    if magnitude <= 0 or duration <= 0 or types.Actor.isDead(self) then return end

    local effects = types.Actor.activeEffects(self)
    if calmHumanoidApplied ~= 0 then
        effects:modify(-calmHumanoidApplied, CALM_HUMANOID_ID)
    end
    if calmCreatureApplied ~= 0 then
        effects:modify(-calmCreatureApplied, CALM_CREATURE_ID)
    end
    effects:modify(magnitude, CALM_HUMANOID_ID)
    effects:modify(magnitude, CALM_CREATURE_ID)
    calmHumanoidApplied = magnitude
    calmCreatureApplied = magnitude
    calmExpireTime = core.getSimulationTime() + duration
    scheduleCalmExpiry()
end

return {
    engineHandlers = {
        onActive = function()
            calcAndApplySanctuary()
            startTimers()
        end,
        onLoad = onLoad, onInit = onLoad, onSave = onSave,
    },
    eventHandlers = {
        Evasion_ApplyRiposte = applyRiposte,
        Evasion_ApplyAshSand = applyAshSand,
        Evasion_ApplyVanishCalm = applyVanishCalm,
    },
}
