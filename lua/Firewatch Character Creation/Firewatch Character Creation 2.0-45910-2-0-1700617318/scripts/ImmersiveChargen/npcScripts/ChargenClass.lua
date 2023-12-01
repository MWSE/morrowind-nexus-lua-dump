local self = require("openmw.self")


local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local time = require('openmw_aux.time')

local talkDistance = 100
if types.Player.isCharGenFinished(nearby.players[1]) then 
    
    return end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function StartScript(name)
--script name
end
local function EnableStatsMenu()

end
local function getDistanceToPlayer()
    return distanceBetweenPos(self.position, nearby.players[1].position)
end

local function GetDistance(id)
    local target
    for index, value in ipairs(nearby.actors) do
        if value.recordId == id:lower() then
            target = value
        end
    end
    return distanceBetweenPos(self.position, target.position)
end

local state = 0
local timer = 0
local function onActivated()
    if (state == 0) then
        core.sound.say("sound\\vo\\Misc\\CharGen Class1.wav", self,
            "Ahh yes, we've been expecting you. You'll have to be recorded before you're officially released. There are a few ways we can do this, and the choice is yours.")
        nearby.players[1]:sendEvent("enableControlsICG", false)
        state = 10
    end
end
local function onUpdate(dt)

    if (state == 0) then
        core.sendGlobalEvent("setObjectState_ICG", { state = false, id = "CharGen StatsSheet" })


        if (GetDistance("player") < talkDistance) then
            onActivated()
        end
    elseif (state == 10) then
        if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent('SetUiMode', {mode = 'ChargenClass'})
            state = 12
        end
    elseif (state == 12) then
        if (not core.sound.isSayActive(self)) then
            timer = timer + dt

            if (timer > 1) then
                core.sound.say("sound\\vo\\Misc\\CharGen Birth.wav", self,
                    "Very good. The letter that preceded you mentioned you were born under a certain sign. And what would that be?")
                state = 14
                timer = 0
            end
        end
    elseif (state == 14) then
        if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent('SetUiMode', {mode = 'ChargenBirth'})
            state = 15
        end
    elseif (state == 15) then
        timer = timer + dt

        if (timer > 1) then
            core.sound.say("sound\\vo\\Misc\\CharGen Class2.wav", self,
                "Interesting. Now before I stamp these papers, make sure this information is correct.")
            state = 16
            timer = 0
        end
    elseif (state == 16) then
        if (not core.sound.isSayActive(self)) then
            nearby.players[1]:sendEvent('SetUiMode', {mode = 'ChargenClassReview'})
            state = 17
        end
    elseif (state == 17) then
        if (not core.sound.isSayActive(self)) then
            timer = timer + dt

            if (timer > 1) then
                timer = 0
                EnableStatsMenu()
                nearby.players[1]:sendEvent("enableControlsICG", true)
                StartScript("RaceCheck") -- sets the PCRace global flag for dialogue and such
                
        nearby.players[1]:sendEvent("showMessageICG", "You now have a Stats Menu, where you can always view your information.", "Ok")
                state = 18
            end
        end
    elseif (state == 18) then
        nearby.players[1]:sendEvent("showMessageICG", 
            "Right Clicking allows you to use your menus. When you are done with them, right click again to close them.",
            "Ok")


        state = 20

        -- show papers
    elseif (state == 20) then
        core.sound.say("sound\\vo\\Misc\\CharGen Class3.wav", self,
            "Show your papers to the Captain when you exit to get your release fee.")
        core.sendGlobalEvent("setObjectState_ICG", { state = true, id = "CharGen StatsSheet" })
      
        state = 30

        -- show how to pick them up
    elseif (state == 30) then
        if (not core.sound.isSayActive(self)) then
            timer = timer + dt

            if (timer > 1) then
                timer = 0

                nearby.players[1]:sendEvent("showMessageICG", 
                    "Read your papers by pressing Spacebar while looking at them. Then select 'Take' to pick them up.",
                    "Ok")

                nearby.players[1]:sendEvent("enableCameraControlsICG", false)

                state = -1
            end
        end
    elseif (state == -1) then
     if (not types.Player.isCharGenFinished(nearby.players[1]) ) then
        -- this may need to be here for flow

        if (GetDistance("player") < 180) then
            local itemCount = types.Actor.inventory(nearby.players[1]):countOf("CharGen StatsSheet")
            if (itemCount == 0) then     -- does not have sheet yet
                if (not core.sound.isSayActive(self)) then
                    timer = timer + dt

                    if (timer > 5) then
                        timer = 0
                        core.sound.say("sound\\vo\\Misc\\CharGen Class4.wav", self,
                            "Take your papers off the table and go see Captain Gravius.")
                    end
                end
            end
        end
        end
    end
end
local function onInit(data)

    if data then
talkDistance = data.distance
    end
end
return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = onInit,
    }
}
