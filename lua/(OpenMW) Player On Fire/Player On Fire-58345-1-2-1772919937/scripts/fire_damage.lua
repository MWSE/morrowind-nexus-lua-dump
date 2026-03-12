local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local shared   = require('scripts.fire_shared')
local DEFAULTS = shared.DEFAULTS

local section = storage.playerSection('SettingsFireDamage')

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    DAMAGE_TICK  = get('DAMAGE_TICK'),
    BASE_DAMAGE  = get('BASE_DAMAGE'),
    BURN_RADIUS  = get('BURN_RADIUS'),
    BURN_HEIGHT  = get('BURN_HEIGHT'),
    MOD_ENABLED = get('MOD_ENABLED'),
}

section:subscribe(async:callback(function(_, key)
    if key then
        cachedSettings[key] = get(key)
        if key == 'BURN_RADIUS' then
            cachedSettings.BURN_RADIUS_SQ = cachedSettings.BURN_RADIUS * cachedSettings.BURN_RADIUS
        end
    else
        for k in pairs(cachedSettings) do
            cachedSettings[k] = get(k)
        end
        cachedSettings.BURN_RADIUS_SQ = cachedSettings.BURN_RADIUS * cachedSettings.BURN_RADIUS
    end
end))

local BURN_RADIUS_SQ = cachedSettings.BURN_RADIUS * cachedSettings.BURN_RADIUS
cachedSettings.BURN_RADIUS_SQ = BURN_RADIUS_SQ

local activeFires    = {}
local lastDamageTime = 0
local lastCell       = nil

local function calcFireDamage(base)
    local effects    = types.Actor.activeEffects(self)
    local weakness   = 0
    local resist     = 0
    local idWeakness = core.magic.EFFECT_TYPE.WeaknessToFire
    local idResist   = core.magic.EFFECT_TYPE.ResistFire
    for _, effect in pairs(effects) do
        if effect.id == idWeakness then
            weakness = effect.magnitude
        elseif effect.id == idResist then
            resist = effect.magnitude
        end
        if weakness ~= 0 and resist ~= 0 then break end
    end
    local netResist = math.min(100, math.max(-100, resist - weakness))
    return math.max(0, base * (1.0 - netResist / 100.0))
end

return {
    eventHandlers = {
        UpdateFireList = function(fires)
            activeFires = fires or {}
        end,
    },
    engineHandlers = {
        onUpdate = function()
            if not cachedSettings.MOD_ENABLED then return end
            local currentTime = core.getSimulationTime()
            if currentTime - lastDamageTime < cachedSettings.DAMAGE_TICK then return end
            local currentCell = self.cell
            if currentCell ~= lastCell then
                lastCell    = currentCell
                activeFires = {}
                core.sendGlobalEvent('RequestFireScan')
                return
            end
            if #activeFires == 0 then return end
            local pPos     = self.position
            local hitFound = false
            for i = 1, #activeFires do
                local fire = activeFires[i]
                if fire and fire:isValid() then
                    local fPos = fire.position
                    local dz   = fPos.z - pPos.z
                    if math.abs(dz) < cachedSettings.BURN_HEIGHT then
                        local dx      = fPos.x - pPos.x
                        local dy      = fPos.y - pPos.y
                        local hDistSq = dx*dx + dy*dy
                        if hDistSq < cachedSettings.BURN_RADIUS_SQ then
                            hitFound = true
                            break
                        end
                    end
                end
            end
            if hitFound then
                local damage = calcFireDamage(cachedSettings.BASE_DAMAGE)
                if damage > 0 then
                    local health = types.Actor.stats.dynamic.health(self)
                    health.current = health.current - damage
                    ambient.playSound('destruction bolt', { volume = 1.0 })
                    ambient.playSound('Health Damage', { volume = 0.1 })
                end
                lastDamageTime = currentTime
            end
        end,
    },
}