local core = require("openmw.core")

local this = {}

this.timers = {}
this.nextTimerId = 0


function this.newTimer(duration, callback, ...)
    local timerId = this.nextTimerId
    this.nextTimerId = timerId + 1

    local timer = {
        endTime = core.getRealTime() + duration,
        callback = callback,
        args = {...},
    }
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