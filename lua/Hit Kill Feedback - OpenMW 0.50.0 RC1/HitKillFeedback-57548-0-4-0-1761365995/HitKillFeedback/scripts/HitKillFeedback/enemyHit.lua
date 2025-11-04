local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')



---@param attackInfo AttackInfo2
local function handler(attackInfo)
        if types.Actor.stats.dynamic.health(self).current > 0 then
                if attackInfo.attacker and types.Player.objectIsInstance(attackInfo.attacker) then
                        attackInfo.victim = self
                        attackInfo.attacker:sendEvent('damageNumbers', attackInfo)
                end
        end
end

I.Combat.addOnHitHandler(handler)
