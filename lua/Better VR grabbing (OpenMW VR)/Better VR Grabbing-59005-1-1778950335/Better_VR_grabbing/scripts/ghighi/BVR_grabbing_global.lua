local world = require('openmw.world')
local core = require('openmw.core')
local D = require('scripts/MaxYari/LuaPhysics/scripts/physics_defs')

local grabbedObjects = {}

return {
    eventHandlers = {
        BVR_PhysicsGrab = function(data)
            local pId = data.player.id
            local targetPos = data.hPos + (data.hDir * 15)
            
            if not grabbedObjects[pId] then
                local radius = 40 
                local bestItem = nil
                local minD = radius
                for _, object in ipairs(data.player.cell:getAll(core.GameObject)) do
                    if object:isValid() and object ~= data.player then
                        local dist = (object.position - targetPos):length()
                        if dist < minD then
                            minD = dist
                            bestItem = object
                        end
                    end
                end

                if bestItem then
                    grabbedObjects[pId] = bestItem
                    bestItem:sendEvent(D.e.HeldBy, { actor = data.player })

                    bestItem:sendEvent(D.e.SetPhysicsProperties, {  
                        ignoreWorldCollisions = true, 
                        ignorePhysObjectCollisions = false, 
                        culprit = data.player 
                    })
                end
            end


            local currentObj = grabbedObjects[pId]
            if currentObj and currentObj:isValid() then
                currentObj:sendEvent(D.e.MoveTo, { 
                    position = targetPos, 
                    maxImpulse = 400, 
                    culprit = data.player 
                })
            end
        end,

        BVR_PhysicsRelease = function(data)
            local pId = data.player.id
            local obj = grabbedObjects[pId]
            
            if obj and obj:isValid() then
                -- 1. Réactiver les collisions
                obj:sendEvent(D.e.SetPhysicsProperties, {
                    ignoreWorldCollisions = false,
                    ignorePhysObjectCollisions = false,
                    culprit = data.player
                })


                local throwMultiplier = 1.4 
                local impulse = data.velocity * throwMultiplier

                if impulse:length() > 1000 then
                    impulse = impulse:normalize() * 1000
                end

                obj:sendEvent(D.e.ApplyImpulse, {
                    impulse = impulse,
                    culprit = data.player
                })

                -- 3. Libérer l'objet
                obj:sendEvent(D.e.HeldBy, { actor = nil })
                grabbedObjects[pId] = nil
            end
        end
    }
}