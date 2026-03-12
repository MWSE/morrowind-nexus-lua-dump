local input = require("openmw.input")

local realTimer = require("scripts.quest_guider_lite.realTimer")

local this = {}

this.timer = nil


this.callback = nil
this.triggerCallback = nil


local function callback()
    if this.callback then
        local rAxisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
        this.callback(rAxisY)
    end

    if this.triggerCallback then
        local rTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
        local lTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft)
        this.triggerCallback(lTrigger, rTrigger)
    end

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