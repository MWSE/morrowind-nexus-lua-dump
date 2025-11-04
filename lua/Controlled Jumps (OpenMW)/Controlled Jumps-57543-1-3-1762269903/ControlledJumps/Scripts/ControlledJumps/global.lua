local world = require('openmw.world')
local time = require('openmw_aux.time')

local player = world.players[1]
local stopfn = nil
local count = 0

local function cjStart()

    if stopfn ~= nil then 
        stopfn()
    end
    count = 0
    stopfn = time.runRepeatedly(
        function()
            count = count + 1
            player:sendEvent('cjCount', { count = count })
        end, time.second*0.01
    )
end

local function cjDone()
    if stopfn ~= nil then 
        stopfn() 
        stopfn = nil
    end
    player:sendEvent('destroyTimerWindow')
end

return {
    eventHandlers = {
        cjStart = cjStart,
        cjDone = cjDone
    }
}
