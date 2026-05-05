local core = require('openmw.core')

return {
    eventHandlers = {
        VR_ImpactRequest = function(data)
            -- You can change the radius and force if you want your impact to be huge or minimalistic!
            local radius = 30       
            local force = 600
            local impactPos = data.hitPos
            local player = data.culprit

            for _, object in ipairs(player.cell:getAll(core.GameObject)) do
                if object:isValid() and object ~= player then
                    local diff = object.position - impactPos
                    local dist = diff:length()

                    if dist < radius then
                        local pushDir = diff:normalize()
                        if dist < 5 then pushDir = data.direction end
                        
                        local impulseForce = pushDir * force

                        object:sendEvent("LuaPhysics_ApplyImpulse", {
                            impulse = impulseForce,
                            culprit = player
                        })
                        
                        object:sendEvent("LuaPhysics_DestructibleHit", {
                            damage = 30,
                            impulse = impulseForce,
                            culprit = player
                        })
                    end
                end
            end
        end
    }
}