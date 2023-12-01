local self = require("openmw.self")


local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local time = require('openmw_aux.time')
local readyForPapers = false
local talkDistance = 100
if types.Player.isCharGenFinished(nearby.players[1]) then
    return
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local done = 0
local timer = 0

local function getDistanceToPlayer()
    return distanceBetweenPos(self.position,nearby.players[1].position)
    end
local function onUpdate(dt)
    if done == 0 then
        local distanceToPlayer = getDistanceToPlayer()

        if distanceToPlayer < 180 and readyForPapers then
            local statsSheetCount = types.Actor.inventory(nearby.players[1]):countOf("CharGen StatsSheet")

            if statsSheetCount >= 1 then
                if (not core.sound.isSayActive(self)) then
                    core.sound.say("sound\\vo\\Misc\\CharGen Door2.wav", self,
                        "Continue through and talk to Sellus Gravius."
                    )
                    core.sendGlobalEvent("unlockHallwayDoors")
                    done = 1
                end
            else
                timer = timer + dt

                if timer > 3 then
                    timer = 0
                end

                if (not core.sound.isSayActive(self)) then
                    if timer == 0  then
                        
                    core.sound.say("sound\\vo\\Misc\\CharGen Door1.wav", self,
                    "You'll go no further until you have your papers."
                )
                    end
                end
            end
        end
    end
end
local function setreadyForPapers()
    readyForPapers = true
end
return { engineHandlers = { onUpdate = onUpdate } , eventHandlers = {
    setreadyForPapers = setreadyForPapers
}}
