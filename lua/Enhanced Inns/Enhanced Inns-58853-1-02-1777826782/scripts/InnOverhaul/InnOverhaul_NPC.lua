
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local guideState = nil
local destPosition = nil
local guideDoor = nil
if types.NPC.record(self).class:lower() ~= "publican" then return end

local function onUpdate()
    if guideState == "Start" then
        local doorDist = (self.position - destPosition):length()
      --  local vDist = 
        if doorDist < 100  then
            I.AI.startPackage({type='Wander'})
            guideState = "Wait"
            if guideDoor then
                
                core.sendGlobalEvent("openDoor",guideDoor)
            
            end
            async:newUnsavableSimulationTimer(10, function()
                    
            guideState = "Return"
            I.AI.startPackage({type='Travel', destPosition=self.startingPosition})
            end)
        end

    end
end

local function StartGuiding(data)
    guideDoor = data.doorObj
    I.AI.startPackage({type='Travel', destPosition=data.destPosition})
    guideState = "Start"
    destPosition = data.destPosition
end

return {
    interfaceName = "ZS_InnOverhaul",
    interface = {
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        StartGuiding = StartGuiding,
    }
}
