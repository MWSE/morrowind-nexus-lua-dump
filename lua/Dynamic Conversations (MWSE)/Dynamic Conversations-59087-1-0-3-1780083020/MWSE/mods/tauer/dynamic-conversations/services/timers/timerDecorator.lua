local decorator = require("tauer.dynamic-conversations.services.decorators.decorator")
local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

local logger = mwse.Logger.new()

---@class timerDecorator : mwseTimer, decoratedType
---@field public id string
local this = {}

--- Creates a decorated timer with additional functionality.
--- This timer will:
--- - Trigger a `timerFinished` event when it completes all iterations
--- - Trigger a `timerCancelled` event when it is cancelled
--- - Optionally execute an `onExpire` callback when it finishes
---@public
---@param params timerDecoratorStartParams The parameters for starting the timer
---@see EVENTS.timerFinished
---@see EVENTS.timerCancelled
---@return timerDecorator timer The created timer
function this.new(params)
    this.decorateCallback(params)

    local timer = timer.start({
        type = params.type,
        duration = params.duration,
        iterations = params.iterations,
        callback = params.onTick,
        data = params.data,
    })

    local instance = decorator.wrap(timer, this) --[[@as timerDecorator ]]
    instance.id = params.id or "<unknown>"

    timer.data = timer.data or {}
    timer.data.decoratedTimer = instance
    timer.data.onExpire = params.onExpire

    return instance
end

--- Cancels the timer and triggers an event
---@public
---@return boolean canceled
function this:cancel()
    local innerTimer = self.inner --[[@as mwseTimer ]]
    if not innerTimer then
        logger:error("Decorated timer has no inner timer")
        return false
    end

    local canceled = innerTimer:cancel()

    ---@type timerCancelledEventData
    local payload = {
        timer = self,
    }
    event.trigger(EVENTS.timerCancelled, payload)

    return canceled
end

---@private
---@param params timerDecoratorStartParams
function this.decorateCallback(params)
    local originalOnTick = params.onTick

    params.onTick = function(callback)
        local decoratedData = callback.timer.data --[[@as decoratedTimerData ]]
        local decoratedTimer = decoratedData.decoratedTimer --[[@as timerDecorator ]]

        ---@type mwseTimerCallbackData
        local decoratedCallbackData = {
            timer = decoratedTimer, -- Passing in the decorated timer to ensure the correct cancel function is used
        }

        originalOnTick(decoratedCallbackData)

        if decoratedTimer.iterations == 1 then
            ---@type timerFinishedEventData
            local payload = {
                timer = decoratedTimer,
            }
            event.trigger(EVENTS.timerFinished, payload)

            if decoratedData.onExpire then
                decoratedData.onExpire(decoratedCallbackData)
            end
        end
    end
end

return this
