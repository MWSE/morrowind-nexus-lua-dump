local core = require("openmw.core")

local this = {}

this.timers = {}


function this.newTimer(duration, callback, ...)
    local timer = {
        endTime = core.getRealTime() + duration,
        callback = callback,
        args = {...},
    }
    local timerId = #this.timers + 1
    this.timers[timerId] = timer
    return function ()
        this.timers[timerId] = nil
    end
end


function this.updateTimers()
    local currentTime = core.getRealTime()
    for i, timer in pairs(this.timers) do
        if currentTime >= timer.endTime then
            timer.callback(table.unpack(timer.args))
            this.timers[i] = nil
        end
    end
end


return this