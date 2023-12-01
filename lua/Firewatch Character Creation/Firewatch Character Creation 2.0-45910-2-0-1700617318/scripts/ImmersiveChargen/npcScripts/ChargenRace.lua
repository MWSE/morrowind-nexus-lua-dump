

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

local meetPlayerPos = util.vector3(-8914, -73093, 126)
local officeDestination = util.vector3(-9944, -72481, 126)

local meetPlayerPos = util.vector3(140806.688,126500.922,178)
local officeDestination = util.vector3(144183,124073,304)
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
    
    -- done, standing
    if (state == -1) then
        if (getDistanceToPlayer() < 150) then
            timer = timer + dt
            if (timer > 6) then
                if (not I.AI.getActivePackage()) then
                timer = 0
                core.sound.say("sound\\vo\\Misc\\CharGenDock3.wav",self, "Head on in.")
                end
            end
        end
    end
    
    if (state == 0) then
        -- walk him out to dock
        -- AITravel -8593, -73295, 227       ; up on boat
        
        I.AI.startPackage({  type = 'Travel',
        destPosition = meetPlayerPos,
    })
        state = 10
    
    elseif (state == 10) then
        if (getDistanceToPlayer() < 108) then
            state = 20
            I.AI.removePackages()
        end
    
    -- PC has reached him, start talking
    elseif (state == 20) then
        nearby.players[1]:sendEvent("enableControlsICG",false)
        core.sound.say("sound\\Vo\\Misc\\CharGenDock1.wav",self, "You finally arrived, but our records don't show from where.")
        state = 30
    
    elseif (state == 30) then
        if  (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent('SetUiMode', {mode = 'ChargenRace'})
            state = 40
        end
    
    elseif (state == 40) then
        timer = timer + dt
    
        -- let them look around delay
        if (timer >= 1.5) then
            core.sound.say("sound\\Vo\\Misc\\CharGenDock2.wav", self,"Great. I'm sure you'll fit right in. Follow me up to the office, and they'll finish your release.")
            state = 50
            timer = 0
        end
    
    elseif (state == 50) then
        if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent("enableControlsICG",true)
            -- AITravel -9879, -72443, 208     ; goes up to office door
            I.AI.startPackage({  type = 'Travel',
            destPosition = officeDestination,
        })
            -- AIEscort Player, 12, -9944, -72481, 126   ; next to door
            state = -1
        end
    end
end

return {
    engineHandlers = {
onUpdate = onUpdate
    }
}