local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

--- A finalizer for conversations that triggers callbacks and ends the conversation properly
---@class conversationFinalizer : initializedService
local this = {}

---@public
---@return boolean
function this.initialize()
    event.register(EVENTS.lastDialogueSpoken, this.onLastDialogueSpoken)
    return true
end

---@private
---@param eventData lastDialogueSpokenEventData
function this.onLastDialogueSpoken(eventData)
    local conversation = eventData.conversation

    for _, callback in pairs(conversation.configuration.callbacks) do
        ---@type conversationCallbackData
        local data = {
            conversation = conversation,
        }
        callback.execute(data)
    end

    ---@type conversationEndedEventData
    local payload = {
        conversation = conversation,
    }
    event.trigger(EVENTS.conversationEnded, payload)
end

return this
