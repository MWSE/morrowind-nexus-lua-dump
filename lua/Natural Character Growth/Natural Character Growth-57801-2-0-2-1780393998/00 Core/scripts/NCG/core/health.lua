local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local mCfg = require('scripts.NCG.config.configuration')
local mS = require('scripts.NCG.config.store')
local mC = require('scripts.NCG.core.common')
local log = require('scripts.NCG.util.log')

local module = {}

module.setAttributes = function(state)
    local changed = false
    local stateBasedHP = mS.settings.stateBasedHp.get()
    for attr, value in pairs(state.health.attributes) do
        local current
        if stateBasedHP then
            current = T.Actor.stats.attributes[attr](self).modified
        else
            current = T.Actor.stats.attributes[attr](self).base
        end
        if current ~= value then
            state.health.attributes[attr] = current
            changed = true
        end
    end
    return changed
end

module.getFactor = function(state)
    local attrFactor = 0
    for attrId, value in pairs(mCfg.healthAttributeFactors) do
        attrFactor = attrFactor + state.health.attributes[attrId] * value
    end
    return mS.settings.baseHpFactor.get() * attrFactor
end

module.getMaxModifier = function(actor)
    local healthMod = 0
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.affectsBaseValues then
            for i = 1, #spell.effects do
                if spell.effects[i].id == core.magic.EFFECT_TYPE.FortifyHealth then
                    healthMod = healthMod + spell.effects[i].magnitudeThisFrame
                end
            end
        end
    end
    return healthMod
end

module.setHealth = function(state)
    local hpPerLevelFactor = mS.settings.perLevelHpFactor.get()
    local currentLevel = mC.self.level.current
    local healthFactor = module.getFactor(state)
    local maxHealthModifier = module.getMaxModifier(self)
    if maxHealthModifier ~= 0 then
        log(string.format("Detected max health modifier: %d", maxHealthModifier))
    end
    local maxHealth = math.floor(healthFactor + (currentLevel - 1) * hpPerLevelFactor * healthFactor + maxHealthModifier)
    state.health.base = maxHealth
    local health = mC.self.health
    local ratio = health.current / health.base
    health.base = maxHealth + state.health.diff
    health.current = ratio * health.base
end

return module