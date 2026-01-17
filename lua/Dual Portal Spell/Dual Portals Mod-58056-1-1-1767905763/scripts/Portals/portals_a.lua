local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")

local player
local sound

local wasInRange = false
local adist = 120
return {
    engineHandlers = {
        onUpdate = function()
            if not sound then
                core.sound.playSound3d("T_SndObj_LargeFire", self, { loop = true })
                sound = true
            end
            if not player then
                player = nearby.players[1]
            end
            local dist = (player.position - self.position):length()
            local actors = 0
            if dist < adist and not wasInRange then
                print("In Range")
                for i,x in ipairs(nearby.actors) do
                    if x ~= nearby.players[1] then
                        x:sendEvent("PortalFollowerCheck")
                        actors = actors + 1
                    end
                end
                wasInRange = true
                core.sendGlobalEvent("ActivatePortal", {portal = self, actors = actors})
            elseif dist < adist then
            else
                wasInRange = false
            end
        end
    }
}
