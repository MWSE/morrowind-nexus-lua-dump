local self = require('openmw.self')
local input = require('openmw.input')
local vr = require('openmw.vr')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local core = require('openmw.core')
local ui = require('openmw.ui')

local hPos, hDir = nil, nil
local lastPos = nil 
return {
    eventHandlers = {
        BVR_Display = function(data) ui.showMessage(data.text) end
    },
    engineHandlers = {
        onVRFrame = function()
            local pose = I.vrspaces.locateSpaceInWorld(I.vrspaces.actionSpaces.RightHandGrip)
            if pose then
                hPos = pose.position
                hDir = pose.orientation * util.vector3(0, 0, -1) 
            end
        end,
        onUpdate = function(dt)
            if not vr.isVr() or not hPos then return end

            if input.getBooleanActionValue("Use") then    -- this is the input linked to the trigger
                core.sendGlobalEvent('BVR_PhysicsGrab', {
                    hPos = hPos,
                    hDir = hDir,
                    player = self.object,
                    dt = dt
                })
            else
                local throwVelocity = util.vector3(0, 0, 0)
                if lastPos then
                    local rawVelocity = (hPos - lastPos) / dt

                    local boostHorizontal = 1.5  -- to make a better feeling for throwing
                    local dampVertical = 0.5     
        
                     throwVelocity = util.vector3(
                        rawVelocity.x * boostHorizontal,
                        rawVelocity.y * dampVertical,
                        rawVelocity.z * boostHorizontal
                    )
                end

                core.sendGlobalEvent('BVR_PhysicsRelease', { 
                    player = self.object,
                    velocity = throwVelocity 
                })
            end
            lastPos = hPos
        end
    }
}