local T = require('openmw.types')
local I = require("openmw.interfaces")
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local debug = require('openmw.debug')

local mDef = require('scripts.HBFS.config.definition')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')
local log = require('scripts.HBFS.util.log')

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local settings = {}

for key, setting in pairs(mStore.settings) do
    if setting.section.key == mStore.sections.player.key then
        settings[key] = setting.get()
    end
end

local actorId = mTools.actorId(self)
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
    if debug.isGodMode()
            or settings[mStore.settings.magicDamagePercent.key].actual == 100
            and settings[mStore.settings.sunDamagePercent.key].actual == 100 then return end

    state.effectDamage.time = state.effectDamage.time + deltaTime
    if state.effectDamage.time < 0.1 then return end
    local time = state.effectDamage.time
    state.effectDamage.time = 0

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
        local damage = ((settings[mStore.settings.magicDamagePercent.key].actual - 100) / 100) * (drainDamage - state.effectDamage.drain)
        health.current = math.min(health.current - damage, math.max(health.base, health.current))
        log(string.format("%s adding %.2f drain health damage to base %.2f", actorId, damage, drainDamage))
        state.effectDamage.drain = drainDamage
    end

    if magicDamageSum ~= 0 or sunDamageSum ~= 0 then
        local damage = ((settings[mStore.settings.magicDamagePercent.key].actual - 100) / 100) * time * magicDamageSum
                + ((settings[mStore.settings.sunDamagePercent.key].actual - 100) / 100) * time * sunDamageSum
        health.current = math.min(health.current - damage, math.max(health.base, health.current))
        log(string.format("%s taken magic damage was %s by %.2f from %d effect(s) over %.2f seconds",
                actorId, (damage > 0) and "increased" or "reduced", damage, numEffects, time))
    end
end

local function noBackRunning()
    if not settings[mStore.settings.noBackRunning.key] then return end
    if self.controls.run == true and self.controls.movement < 0 then
        self.controls.run = false
    end
end

local function onUpdate(deltaTime)
    changeMagicDamageTaken(deltaTime)
end

local function onFrame()
    noBackRunning() -- doesn't work with onUpdate
end

local function showMessage(message)
    ui.showMessage(message)
end

local function updateSetting(key, value)
    settings[key] = value
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        state = data.state
    end
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
    },
    eventHandlers = {
        [mDef.events.updatePlayerSetting] = function(data) updateSetting(data.key, data.value) end,
        [mDef.events.showMessage] = showMessage,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame,
        onSave = onSave,
        onLoad = onLoad,
    },
}