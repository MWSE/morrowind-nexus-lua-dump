local core = require('openmw.core')
local frameCount = 0

local function getGlobalVariable()
   core.sendGlobalEvent("getGlobalVariable")
end

local function onFrame()
    frameCount = frameCount + 1
    if frameCount > 10 then 
        getGlobalVariable()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    }
}