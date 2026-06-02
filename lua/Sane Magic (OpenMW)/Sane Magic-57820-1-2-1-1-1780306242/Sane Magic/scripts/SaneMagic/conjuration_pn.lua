local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local combat = require('openmw.interfaces').Combat

local storage = require('openmw.storage')
local conj = require('Scripts.SaneMagic.conjuration_s')
local conjData = storage.globalSection('SaneMagicConjuration')

local active = {}

local function onUpdate(dt)

    if core.isWorldPaused() then
        return
    end

    local mode = conjData:get('smConjurationMode')

    -- Skip damage sharing if disabled or only summon breach
    if mode == "Disabled" or mode == "DamageShare" then
        return
    end

    local activeEffects = types.Actor.activeEffects(self)

    for _, weapon in ipairs(conj.summonedWeaponsEffects) do
        local effect = activeEffects:getEffect(weapon)
        if effect and effect.magnitude > 0 then
            if not active[weapon] then
                -- print("Summoning ", weapon)
                active[weapon] = true
                core.sendGlobalEvent("smNewSummonConjuration", {
                    summon = weapon,
                    cell = self.cell.name,
                    pos = self.position
                })
            end
        else
            active[weapon] = nil
        end
    end
end

local STAT_ORDER = {
    Magicka = { 'magicka', 'fatigue', 'health' },
    Fatigue = { 'fatigue', 'magicka', 'health' },
    Health  = { 'health' },
}

local function applyConjurationDamage(actor, healthLostPercent, kDamage, mode)
    if healthLostPercent <= 0 or kDamage <= 0 then return end
    
    -- Процент урона от максимальных статов владельца
    local damagePercent = healthLostPercent * kDamage  -- например: 0.5 * 0.33 = 0.165 (16.5%)
    
    local order = STAT_ORDER[mode] or STAT_ORDER.Health
    local remainingPercent = damagePercent  -- начинаем с полного процента
    local dynamicStats = types.Actor.stats.dynamic
    
    for _, statName in ipairs(order) do
        if remainingPercent <= 0 then break end
        
        local stat = dynamicStats[statName](actor)
        local maxValue = stat.base
        local currentValue = stat.current
        
        if maxValue > 0 and currentValue > 0 then
            -- Сколько максимум можем снять в абсолютных единицах
            local maxPossibleDamage = maxValue * remainingPercent
            -- Но не больше, чем есть текущего значения
            local actualDamage = math.min(currentValue, maxPossibleDamage)
            
            dynamicStats[statName](actor).current = currentValue - actualDamage
            
            -- Сколько процентов от максимума этого стата мы реально сняли
            local actualPercentDrained = actualDamage / maxValue
            remainingPercent = remainingPercent - actualPercentDrained
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },

    eventHandlers = {
        smConjurationHurt = function(data)

            if not types.Player.objectIsInstance(self) then
                return
            end -- Only players

            -- local attackInfo = {
            --     damage = { heailth = data.damage , fatigue = 0, magicka = 0 },
            --     successful = true,
            --     strength = 1,
            --     sourceType = combat.ATTACK_SOURCE_TYPES.Magic,
            --     attacker = data.summon, --self
            -- }
            -- combat.onHit(attackInfo)
            
            local mode = data.damageType or conjData:get('smConjurationDamageType') or 'Health'

            local healthLostPercent = data.healthLostPercent or 0
            local kDamage = data.kDamage or 0

            if not types.Player.objectIsInstance(self) then
                return
            end
        
            local mode = data.damageType or "Health"
            local healthLostPercent = data.healthLostPercent or 0
            local kDamage = data.kDamage or 0
        
            if healthLostPercent <= 0 or kDamage <= 0 then
                return
            end
        
            applyConjurationDamage(self, healthLostPercent, kDamage, mode)

            -- кровь только если задели здоровье (опционально)
            local health = types.Actor.stats.dynamic.health(self)
            -- если нужна кровь при любом уроне — уберите проверку
            if mode == 'Health' or health.current < health.base then
                combat.spawnBloodEffect(self.position)
            end
        end
    }
}
