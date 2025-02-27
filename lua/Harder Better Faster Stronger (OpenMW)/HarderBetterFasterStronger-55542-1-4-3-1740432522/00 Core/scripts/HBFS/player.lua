local T = require('openmw.types')
local I = require("openmw.interfaces")
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local debug = require('openmw.debug')

local mDef = require('scripts.HBFS.definition')
local mSettings = require('scripts.HBFS.settings')
local mDebug = require('scripts.HBFS.debug')

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local actorId = mDebug.actorId(self)
local health = T.Actor.stats.dynamic.health(self)

local healthDamagingEffectIds = {
    [core.magic.EFFECT_TYPE.DrainHealth] = true,
    [core.magic.EFFECT_TYPE.DamageHealth] = true,
    [core.magic.EFFECT_TYPE.AbsorbHealth] = true,
    [core.magic.EFFECT_TYPE.FireDamage] = true,
    [core.magic.EFFECT_TYPE.FrostDamage] = true,
    [core.magic.EFFECT_TYPE.ShockDamage] = true,
    [core.magic.EFFECT_TYPE.Poison] = true,
    [core.magic.EFFECT_TYPE.SunDamage] = true,
}

local state = {
    effectDamage = { time = 0, drain = 0 }
}

local function changeMagicDamageTaken(deltaTime)
    if not mSettings.globalSection():get(mSettings.cfg.enabled.key) or debug.isGodMode() then return end

    state.effectDamage.time = state.effectDamage.time + deltaTime
    if state.effectDamage.time < 0.1 then return end
    local time = state.effectDamage.time
    state.effectDamage.time = 0

    local magicDamagePercent = mSettings.playerSection():get(mSettings.cfg.magicDamagePercent.key).actual
    local sunDamagePercent = mSettings.playerSection():get(mSettings.cfg.sunDamagePercent.key).actual
    if magicDamagePercent == 100 and sunDamagePercent == 100 then return end

    local magicDamageSum = 0
    local sunDamageSum = 0
    local drainDamage = 0
    local numEffects = 0
    for _, effect in pairs(T.Actor.activeEffects(self)) do
        if healthDamagingEffectIds[effect.id] then
            numEffects = numEffects + 1
            if effect.id == core.magic.EFFECT_TYPE.DrainHealth then
                drainDamage = math.max(0, effect.magnitude)
            elseif effect.id == core.magic.EFFECT_TYPE.SunDamage then
                if self.cell.isExterior or self.cell:hasTag("QuasiExterior") then
                    sunDamageSum = sunDamageSum + math.max(0, effect.magnitude)
                end
            else
                magicDamageSum = magicDamageSum + math.max(0, effect.magnitude)
            end
        end
    end

    -- Drain health value changed: Update player health (increase, reduce, cancel drain)
    if drainDamage ~= state.effectDamage.drain then
        local damage = ((magicDamagePercent - 100) / 100) * (drainDamage - state.effectDamage.drain)
        health.current = math.min(health.current - damage, math.max(health.base, health.current))
        mDebug.print(string.format("%s adding %.2f drain health damage to base %.2f", actorId, damage, drainDamage))
        state.effectDamage.drain = drainDamage
    end

    if magicDamageSum ~= 0 or sunDamageSum ~= 0 then
        local damage = ((magicDamagePercent - 100) / 100) * time * magicDamageSum
                + ((sunDamagePercent - 100) / 100) * time * sunDamageSum
        health.current = math.min(health.current - damage, math.max(health.base, health.current))
        mDebug.print(string.format("%s taken magic damage was %s by %.2f from %d effect(s) over %.2f seconds",
                actorId, (damage > 0) and "increased" or "reduced", damage, numEffects, time))
    end
end

local function onUpdate(deltaTime)
    changeMagicDamageTaken(deltaTime)
end

local function showMessage(message)
    ui.showMessage(message)
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data and data.version == mDef.saveVersion then
        state = data.state
    end
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
    },
    eventHandlers = {
        hbfs_showMessage = showMessage,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}