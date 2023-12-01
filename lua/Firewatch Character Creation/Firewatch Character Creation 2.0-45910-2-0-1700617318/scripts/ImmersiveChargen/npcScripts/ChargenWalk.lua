

local self = require("openmw.self")


local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local I = require("openmw.interfaces")
local time = require('openmw_aux.time')
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local types = require("openmw.types")
if types.Player.isCharGenFinished(nearby.players[1]) then return end

local function getDistanceToPlayer()
return distanceBetweenPos(self.position,nearby.players[1].position)
end

local function getDistanceToActor(id)
    local target
    for index, value in ipairs(nearby.actors) do
        if value.recordId == id:lower() then
            target = value
        end
    end
    return distanceBetweenPos(self.position,target)
    end

local state = 0
local timer = 0
local wandering = 0
local state = 0
local timer = 0

local function onUpdate (dt)

-- Done, standing
if (state == -1) then
    if (getDistanceToPlayer() < 150) then
        timer = timer + dt
        if (timer > 6) then
            timer = 0
            core.sound.say("Sound\\Vo\\Misc\\CharGenWalk3.wav",self, "On deck now, prisoner.")
        end
    end
end

-- Start walking to below deck
if (state == 0) then
    timer = timer + dt
    if (timer > 8) then
        I.AI.startPackage({  type = 'Travel',
        destPosition = util.vector3(90, -90, -88),
    })
        state = 10
    end

-- Walk on down after pause
elseif (state == 5) then
    

elseif (state == 10) then
    if (not I.AI.getActivePackage()) then
        state = 20
    end

-- He's at the PC, start talking
elseif (state == 20) then
    core.sound.say("Sound\\Vo\\Misc\\CharGenWalk1.wav",self, "This is where you get off, come with me.")
    state = 30
    timer = 0

-- Give message on how to move
elseif (state == 30) then
    if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent("showMessageICG","W and S move forward and back. A and D move side to side, and the mouse looks around.", "Ok")
        state = 40
    end

-- You now have to walk up to dock
elseif (state == 40) then
    nearby.players[1]:sendEvent("enableControlsICG")
    I.AI.startPackage({  type = 'Escort',
    target = nearby.players[1],
    destPosition = util.vector3(195, 100, 170),
    duration = 12 * time.hour,
})
    state = 50

elseif (state == 50) then
    if (not I.AI.getActivePackage()) then
        state = 53
    end

-- Get him to travel back a little so he turns around
elseif (state == 53) then
    I.AI.startPackage({  type = 'Travel',
    destPosition = util.vector3(185, 174, 170),
})
    state = 57

elseif (state == 57) then
    if (not I.AI.getActivePackage()) then
        state = 60
    end

-- He's at the stairs, tell PC to get up on board
elseif (state == 60) then
    if (getDistanceToPlayer() <= 200) then
        core.sound.say("Sound\\Vo\\Misc\\CharGenWalk2.wav",self, "Get yourself up on deck, and let's keep this as civil as possible.")
        state = -1
    end
end
end

return {
    engineHandlers = {
onUpdate = onUpdate
    }
}