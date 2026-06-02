local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

--- Encapsulates logic for resolving mwseSafeObjectHandles to in-game references
---@class handleResolver
local this = {}

--- Resolves the given handle to an in-game reference
---@public
---@param params tryResolveParams The handle resolver parameters
---@return tes3reference|nil reference The resolved in-game reference, or nil if the handle is invalid
function this.tryResolve(params)
    local handle = params.handle

    if not handle:valid() then
        ---@type handleInvalidatedEventData
        local payload = {
            handle = handle,
            hint = params.hint or "<unknown>",
        }
        event.trigger(EVENTS.handleInvalidated, payload)
        return nil
    end

    return handle:getObject() --[[@as tes3reference]]
end

return this
