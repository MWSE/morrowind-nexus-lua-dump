local Util = require("CraftingFramework.util.Util")
local Async = require("CraftingFramework.util.Async")

local Fader = {}

---@class CraftingFramework.Util.fadeTimeOutParams
---@field hoursPassed number
---@field secondsToCallback number?
---@field secondsFadeIn number?
---@field secondsFadeOut number?
---@field callback function

---@param e CraftingFramework.Util.fadeTimeOutParams
function Fader.fadeTimeOut(e)
    local async = Async:new()

    local secondsFadeIn = e.secondsFadeIn or 0.5
    local secondsToCallback = e.secondsToCallback or secondsFadeIn
    local secondsFadeOut = e.secondsFadeOut or 0.5

    async:step("start", function(next)
        Util.disableControls()
        --30 iterations per second
        Fader.passTime({ seconds = secondsFadeIn, hoursPassed = e.hoursPassed })
        tes3.fadeOut({ duration = secondsFadeIn })
    end)
    async:wait{ type = timer.real, duration = secondsToCallback }
    async:step("callback", function(next)
        e.callback()
        tes3.fadeIn({ duration = secondsFadeOut })
    end)
    async:wait{ type = timer.real, duration = secondsFadeOut }
    async:step("enableControls", function(next)
        Util.enableControls()
    end)
    async:start()
end

---@param e { seconds: number, hoursPassed: number, callback?: function }
---@return fun(callback?: function) Function
function Fader.passTime(e)
    local iterations = 30 * e.seconds
    timer.start({
        type = timer.real,
        iterations = iterations,
        duration = ( e.seconds / iterations ),
        callback = (
            function()
                local gameHour = tes3.findGlobal("gameHour") --[[@as tes3globalVariable]]
                gameHour.value = gameHour.value + (e.hoursPassed/iterations)
            end
        )
    })

    if e.callback then
        timer.start({
            type = timer.real,
            duration = e.seconds,
            callback = e.callback
        })
    end

    return function(callback)
        if callback then
            timer.start({
                type = timer.real,
                duration = e.seconds,
                callback = callback
            })
        end
    end
end


return Fader