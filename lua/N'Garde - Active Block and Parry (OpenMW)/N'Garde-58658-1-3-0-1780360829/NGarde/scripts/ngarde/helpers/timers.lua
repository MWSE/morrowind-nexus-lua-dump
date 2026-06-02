---@omw-context local
local logging = require("scripts.ngarde.helpers.logger").new()
local Timer = {}
Timer.__index = Timer


---create new timer, optionally specify callback, default duration and if it's active as soon as it was created
function Timer.new(callback, duration, active, repeating)
    local self = setmetatable({}, Timer)
    local durationFunc = duration or function () return 0 end
    self.active = active or false
    self.duration = durationFunc()
    self.elapsed = 0
    self.callback = callback or nil
    self.repeating = repeating or false
    return self
end

---start timer at 0 with specified duration, and if it should restart on its own when elapsed
function Timer.startTimer(self, duration, duration_args, repeating)
    if not self.active then
        local args = duration_args or {}
        local durationFunc = duration or function () return 0 end
        self.active = true
        self.duration = durationFunc(unpack(args))
        self.elapsed = 0
        self.repeating = repeating or false
    end
end

---increment timer by dT, if elapsed execute calback if exists. If repeating - restart.
---dT : float seconds
function Timer.processTimer(self, dT)
    if self.active then
        self:increment(dT)
        if self:isElapsed() then
            if self.callback then
                self.callback()
            end
            if self.repeating then
                self:resetTimer()
            else
                self:stopTimer()
            end
        end
    end
end

---set timer's elapsed to 0 without stopping the timer
function Timer.resetTimer(self)
    self.elapsed = 0
end

---stop timer, set duration and elapsed to 0
function Timer.stopTimer(self)
    self.active = false
    self.duration = 0
    self.elapsed = 0
end

---check if timer ran out
function Timer.isElapsed(self)
    if self.elapsed >= self.duration then
        return true
    else
        return false
    end
end

---increment timer by dT
function Timer.increment(self, dT)
    self.elapsed = self.elapsed + dT
end

return Timer
