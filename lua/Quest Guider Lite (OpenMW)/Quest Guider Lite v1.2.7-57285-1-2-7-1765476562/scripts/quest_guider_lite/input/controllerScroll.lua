local input = require("openmw.input")

local realTimer = require("scripts.quest_guider_lite.realTimer")

local this = {}

this.timer = nil


this.callback = nil


local function callback()
    local rAxisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
    if this.callback then this.callback(rAxisY) end
    this.timer = realTimer.newTimer(0.2, callback)
end


function this.start()
    if this.timer then return end

    this.timer = realTimer.newTimer(0.2, callback)
end


function this.stop()
    if this.timer then
        this.timer()
        this.timer = nil
    end
end


return this