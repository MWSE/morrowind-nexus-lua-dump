local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')

local function getBaseHealth()
    return types.Actor.stats.dynamic.health(self).base
end

local function getExperience()
    if types.Creature.objectIsInstance(self) then
        local health = getBaseHealth()
        if health >= 2 then
            return math.floor(health / 2)
        end
        local level = types.Actor.stats.level(self).current
        return 5 * level
    end
    local level = types.Actor.stats.level(self).current
    return 5 * level + 15
end

if getBaseHealth() <= 0 then
    return
end

local alive = nil
local function onUpdate()
    local dead = types.Actor.isDead(self)
    if dead and alive then
        for i, player in pairs(nearby.players) do
            player:sendEvent('EE_MLua_Kill', { xp = getExperience() })
        end
    end
    alive = not dead
end

return {
    engineHandlers = { onUpdate = onUpdate }
}