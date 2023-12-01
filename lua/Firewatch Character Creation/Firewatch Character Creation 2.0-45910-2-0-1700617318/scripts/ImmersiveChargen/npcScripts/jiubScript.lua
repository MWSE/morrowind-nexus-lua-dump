

local self = require("openmw.self")


local core = require("openmw.core")
local nearby = require("openmw.nearby")
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
    return distanceBetweenPos(self.position,target.position)
    end

local state = 0
local timer = 0
local wandering = 0
local function onUpdate (dt)
    
    -- done, standing
    if (state == -1) then
        if (getDistanceToPlayer()< 150) then
            timer = timer + dt
            if (timer > 14) then
                timer = 0
                    core.sound.say("Sound\\Vo\\Misc\\CharGenName4.wav",self,"You better do what they say.")
            end
        end
    end
    
    
    if (state == 0) then
        timer = timer + dt
    
        if (timer >= 1) then -- fader delay
            core.sound.say("Sound\\Vo\\Misc\\CharGenName1.wav",self,"Stand up, there you go. You were dreaming. What's your name?" )
            state = 10
            timer = 0
        end
    
        -- show name menu when done talking
    elseif (state == 10) then
        if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent('SetUiMode', {mode = 'ChargenName'})
            state = 20
        end
    
        -- name is entered, guy says we're there
    elseif (state == 20) then
        timer = timer + dt
    
        if (timer >= 1) then -- delay
            core.sound.say("Sound\\Vo\\Misc\\CharGenName2.wav",self, "Well, not even last night's storm could wake you. I heard them say we've reached Morrowind. I'm sure they'll let us go." )
            
            state = 40
            timer = 0
        end
    
        -- says the guard is coming when he gets close
    elseif (state == 40) then
        if (not core.sound.isSayActive(self)) then
            local guardDistance = getDistanceToActor("CharGen Boat Guard 2")
            if (guardDistance <= 400) then
                core.sound.say("Sound\\Vo\\Misc\\CharGenName3.wav",self, "Quiet, here comes the guard." )
                state = -1
                timer = 5 -- force him to say next line a little earlier
            end
        end
    end

end

return {
    engineHandlers = {
onUpdate = onUpdate
    }
}