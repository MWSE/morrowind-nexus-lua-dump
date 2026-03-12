local core = require("openmw.core")
local playerRef = require("openmw.self").object

local this = {}

this.timers = {}
this.nextTimerId = 0
this.time = core.getRealTime()


function this.newTimer(duration, callback, ...)
    local timerId = this.nextTimerId
    this.nextTimerId = timerId + 1

    local timer = {
        endTime = this.time + duration,
        callback = callback,
        args = {...},
    }
    this.timers[timerId] = timer
    return function ()
        this.timers[timerId] = nil
    end
end


function this.executeTimer(id)
    local timer = this.timers[id]
    if not timer then return end

    timer.callback(table.unpack(timer.args))
    this.timers[id] = nil
end


function this.updateTimers()
    this.time = core.getRealTime()
    for i, timer in pairs(this.timers) do
        if this.time > timer.endTime then
            playerRef:sendEvent("AdvWMap:tmCall", i)
            timer.endTime = math.huge
        end
    end
end


return this