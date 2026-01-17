---@class RealisticRepair.PassTime
---@field frequency integer Time updates per second
---@field duration integer Duration of the time update in seconds
---@field hoursPassed integer Number of hours to pass
local PassTime = {}
PassTime.__index = PassTime -- Ensure methods are accessible

---@param e? { frequency: integer?, duration: integer?, hoursPassed: integer? }
---@return RealisticRepair.PassTime
function PassTime.new(e)
    e = e or {}
    e.frequency = e.frequency or 30
    setmetatable(e, PassTime) -- Set the metatable
    return e
end

--- Run the pass time function
function PassTime:run()
    local iterations = self.frequency * self.duration
    timer.start({
        type = timer.real,
        iterations = iterations,
        duration = (self.duration / iterations),
        callback = function()
            local gameHour = tes3.findGlobal("gameHour") --[[@as tes3globalVariable]]
            gameHour.value = gameHour.value + (self.hoursPassed / iterations)
        end
    })
end

return PassTime