local T = require('openmw.types')
local I = require("openmw.interfaces")
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local debug = require('openmw.debug')

local mSettings = require('scripts.HBFS.settings')
local mTools = require('scripts.HBFS.tools')

I.Settings.registerPage {
    key = mSettings.MOD_NAME,
    l10n = mSettings.MOD_NAME,
    name = "name",
    description = "description",
}

local interfaceVersion = 1.0
local actorId = mTools.actorId(self)

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
    effectDamage = { time = 0, sum = 0, drain = 0 }
}

local function changeMagicDamageTaken(deltaTime)
    if not mSettings.globalSection():get("enabled") or debug.isGodMode() then return end

    state.effectDamage.time = state.effectDamage.time + deltaTime
    if state.effectDamage.time < 0.1 then return end

    local magicDamagePercent = mSettings.playerSection():get("magicDamagePercent").actual
    if magicDamagePercent == 100 then return end

    local drainDamage = 0
    local numEffects = 0
    for _, effect in pairs(T.Actor.activeEffects(self)) do
        if healthDamagingEffectIds[effect.id] then
            numEffects = numEffects + 1
            if effect.id == core.magic.EFFECT_TYPE.DrainHealth then
                drainDamage = effect.magnitude
            elseif effect.id ~= core.magic.EFFECT_TYPE.SunDamage or self.cell.isExterior or self.cell:hasTag("QuasiExterior") then
                state.effectDamage.sum = state.effectDamage.sum + effect.magnitude
            end
        end
    end

    -- Drain health value changed: Update player health (increase, reduce, cancel drain)
    if drainDamage ~= state.effectDamage.drain then
        T.Actor.stats.dynamic.health(self).current = T.Actor.stats.dynamic.health(self).current
                - ((magicDamagePercent - 100) / 100) * (drainDamage - state.effectDamage.drain)
        state.effectDamage.drain = drainDamage
    end

    if state.effectDamage.sum ~= 0 then
        local damage = ((magicDamagePercent - 100) / 100) * state.effectDamage.time * state.effectDamage.sum
        mTools.debugPrint(string.format("%s taken magic damage was %s by %.2f from %d effect(s) over %.2f seconds",
                actorId, (damage > 0) and "increased" or "reduced", damage, numEffects, state.effectDamage.time))
        state.effectDamage.sum = 0

        T.Actor.stats.dynamic.health(self).current = math.max(0, T.Actor.stats.dynamic.health(self).current - damage)
    end
    state.effectDamage.time = 0
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
        version = mSettings.saveVersion,
    }
end

local function onLoad(data)
    if data.version == mSettings.saveVersion then
        state = data.state
    end
end

return {
    interfaceName = mSettings.MOD_NAME,
    interface = {
        version = interfaceVersion,
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