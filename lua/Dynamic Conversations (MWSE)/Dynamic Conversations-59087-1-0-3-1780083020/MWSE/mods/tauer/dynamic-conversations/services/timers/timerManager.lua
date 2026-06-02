local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local timerDecorator = require("tauer.dynamic-conversations.services.timers.timerDecorator")

local logger = mwse.Logger.new()

---@class timerManager : initializedService
local this = {}

---@type { [mwseTimer] : { [eventId] : function } }
this.cancellationHandlers = {}

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.timerFinished, this.onTimerFinished)
    event.register(EVENTS.timerCancelled, this.onTimerCancelled)
    return true
end

--- Starts a timer with additional functionality.
--- This timer will:
--- - Optionally be cancelled when any of the specified events in `cancellationEvents` are triggered.
--- - The returned timer will be decorated with the functionality from `timerDecorator` as well.
---@public
---@param params timerManagerStartParams The parameters for starting the timer
---@see timerManagerStartParams.cancellationEvents
---@see timerDecorator.new
---@return mwseTimer timer The created timer
function this.start(params)
    local timer = timerDecorator.new(params)
    this.registerCancellationHandlers(timer, params.cancellationEvents)

    return timer
end

---@private
---@param eventData timerFinishedEventData
function this.onTimerFinished(eventData)
    this.unregisterCancellationHandlers(eventData.timer)
end

---@private
---@param eventData timerCancelledEventData
function this.onTimerCancelled(eventData)
    this.unregisterCancellationHandlers(eventData.timer)
end

---@private
---@param timer timerDecorator
function this.unregisterCancellationHandlers(timer)
    local data = timer.data --[[@as timerDataWithCancellationHandlers ]]
    if data and data.cancellationHandlers then
        for evt, handler in pairs(data.cancellationHandlers) do
            if event.isRegistered(evt, handler) then
                logger:debug("Unregistering cancellation handler for event '%s' on timer '%s'", evt, timer.id)
                event.unregister(evt, handler)
            end
        end
    end
end

---@private
---@param timer timerDecorator
---@param events eventId[]
function this.registerCancellationHandlers(timer, events)
    if not events or table.size(events) < 1 then
        return
    end

    ---@type timerDataWithCancellationHandlers
    local handlers = {}

    for _, evt in ipairs(events) do
        handlers[evt] = function()
            if not timer then
                return
            end
            timer:cancel()
        end

        if not event.isRegistered(evt, handlers[evt]) then
            event.register(evt, handlers[evt])
        end
    end

    timer.data = timer.data or {}
    timer.data.cancellationHandlers = handlers
end

return this
