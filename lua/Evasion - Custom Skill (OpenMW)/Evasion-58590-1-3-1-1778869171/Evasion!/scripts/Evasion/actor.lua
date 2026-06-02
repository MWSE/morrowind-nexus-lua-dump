--[[
    Evasion! — Actor Script (CUSTOM)
    Calculates and applies evasion Sanctuary for NPCs.
    Also receives local perk effects from the player script/global bridge.
]]

local core    = require('openmw.core')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local self    = require('openmw.self')
local anim    = require('openmw.animation')

local EFFECT_ID = core.magic.EFFECT_TYPE.Sanctuary
local BLIND_ID = core.magic.EFFECT_TYPE.Blind
local CALM_HUMANOID_ID = core.magic.EFFECT_TYPE.CalmHumanoid
local CALM_CREATURE_ID = core.magic.EFFECT_TYPE.CalmCreature


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
-- optionally read a global mirror if one exists.
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

local SLOT = types.Actor.EQUIPMENT_SLOT
local ARMOR_TYPE = types.Armor.TYPE
local armorSlotWeights = {
    [SLOT.Helmet] = 0.08, [SLOT.Cuirass] = 0.28,
    [SLOT.LeftPauldron] = 0.05, [SLOT.RightPauldron] = 0.05,
    [SLOT.Greaves] = 0.14, [SLOT.Boots] = 0.14,
    [SLOT.LeftGauntlet] = 0.04, [SLOT.RightGauntlet] = 0.04,
    [SLOT.CarriedLeft] = 0.18,
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

local previousEvasion = 0
local blindMagnitudeApplied = 0
local blindExpireTime = 0
local calmHumanoidApplied = 0
local calmCreatureApplied = 0
local calmExpireTime = 0

local function getFatigueFactor(actor)
    local fatigue = types.Actor.stats.dynamic.fatigue(actor)
    local maxFatigue = math.max(1, fatigue.base + fatigue.modifier)
    local ratio = math.max(0, math.min(1, fatigue.current / maxFatigue))
    return 0.2 + 0.8 * ratio
end

local function getEncumbranceFactor(actor)
    local capacity = math.max(1, types.Actor.getCapacity(actor))
    local ratio = math.max(0, types.Actor.getEncumbrance(actor) / capacity)
    if ratio <= 0.5 then return 1.0 end
    local t = math.min(1, (ratio - 0.5) / 0.45)
    return math.max(0.05, 1.0 - 0.95 * t)
end

local function calcAndApplySanctuary()
    if types.Player.objectIsInstance(self) or not types.NPC.objectIsInstance(self) then return end

    local maxSanc = getSetting("maxSanctuary", 30)
    local lightPct = getSetting("lightMult", 60) * 0.01
    local medPct = getSetting("mediumMult", 35) * 0.01
    local heavyPct = getSetting("heavyMult", 15) * 0.01
    local npcMult = getSetting("npcMult", 100) * 0.01
    local skill = types.NPC.stats.skills.unarmored(self).modified

    local unarm, light, med, heavy = 0, 0, 0, 0
    local equipment = types.Actor.getEquipment(self)
    for slot, w in pairs(armorSlotWeights) do
        local item = equipment[slot]
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

    local retention = unarm + (light * lightPct) + (med * medPct) + (heavy * heavyPct)
    local fatigueFactor = getFatigueFactor(self)
    local encumbranceFactor = getEncumbranceFactor(self)
    local evasion = math.floor(skill * retention * maxSanc / 100 * fatigueFactor * encumbranceFactor * npcMult)
    local delta = evasion - previousEvasion
    if delta ~= 0 then
        types.Actor.activeEffects(self):modify(delta, EFFECT_ID)
        previousEvasion = evasion
    end
end

local function updateTemporaryEffects()
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

local sanctuaryCheckEvery = 0.25
local sanctuaryUpdateTime = math.random() * sanctuaryCheckEvery

local function consumeInterval(timer, interval)
    if interval <= 0 then return 0, true end
    if timer < interval then return timer, false end
    repeat
        timer = timer - interval
    until timer < interval
    return timer, true
end

local function onUpdate(dt)
    sanctuaryUpdateTime = sanctuaryUpdateTime + dt
    local shouldUpdate
    sanctuaryUpdateTime, shouldUpdate = consumeInterval(sanctuaryUpdateTime, sanctuaryCheckEvery)
    if not shouldUpdate then return end

    updateTemporaryEffects()
    calcAndApplySanctuary()
end

local function onLoad(data)
    previousEvasion = (data and data.previousEvasion) or 0
    blindMagnitudeApplied = (data and data.blindMagnitudeApplied) or 0
    blindExpireTime = (data and data.blindExpireTime) or 0
    calmHumanoidApplied = (data and data.calmHumanoidApplied) or 0
    calmCreatureApplied = (data and data.calmCreatureApplied) or 0
    calmExpireTime = (data and data.calmExpireTime) or 0
    updateTemporaryEffects()
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
    local magnitude = math.max(0, tonumber(data and data.magnitude) or 0)
    local duration = math.max(0, tonumber(data and data.duration) or 0)
    if magnitude <= 0 or duration <= 0 or types.Actor.isDead(self) then return end

    local effects = types.Actor.activeEffects(self)
    if blindMagnitudeApplied ~= 0 then
        effects:modify(-blindMagnitudeApplied, BLIND_ID)
    end
    effects:modify(magnitude, BLIND_ID)
    blindMagnitudeApplied = magnitude
    blindExpireTime = core.getSimulationTime() + duration
    playBlindFx()
end

local function applyVanishCalm(data)
    local magnitude = math.max(0, tonumber(data and data.magnitude) or 0)
    local duration = math.max(0, tonumber(data and data.duration) or 0)
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
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = function() calcAndApplySanctuary() end,
        onLoad = onLoad, onInit = onLoad, onSave = onSave,
    },
    eventHandlers = {
        Evasion_ApplyRiposte = applyRiposte,
        Evasion_ApplyAshSand = applyAshSand,
        Evasion_ApplyVanishCalm = applyVanishCalm,
    },
}
