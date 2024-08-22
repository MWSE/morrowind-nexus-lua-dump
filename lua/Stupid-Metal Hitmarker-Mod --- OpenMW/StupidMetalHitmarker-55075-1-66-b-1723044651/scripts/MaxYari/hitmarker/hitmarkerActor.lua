local mp = "scripts/MaxYari/hitmarker/"

local I = require('openmw.interfaces')
local omwself = require('openmw.self')
local gutils = require(mp.."gutils")

local selfActor = gutils.Actor:new(omwself)

local lastHealth = selfActor.stats.dynamic:health().current

DebugLevel = 1

local function onUpdate(dt)
    local baseHealth = selfActor.stats.dynamic:health().base
    local currentHealth = selfActor.stats.dynamic:health().current
    local damageValue = lastHealth - currentHealth

    local targets = I.AI.getTargets("Combat")

    if damageValue > 0 then
        for _, actor in ipairs(targets) do
            actor:sendEvent('HostileDamaged', { hostile = omwself.object, damage = damageValue, damageFrac = damageValue/baseHealth, currentHealth = currentHealth })
        end
    end
    
    lastHealth = currentHealth
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}