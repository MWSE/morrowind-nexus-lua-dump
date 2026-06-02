local timerManager = require("tauer.dynamic-conversations.services.timers.timerManager")

local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")

--- Plays back conversations from the conversation history page in the MCM
---@class conversationHistoryPlayer
local this = {}

--- Plays a single dialog line
---@public
---@param dialog dialog The dialog to play
function this.playDialog(dialog)
    this.stop()
    this.say(dialog)
end

--- Plays a full conversation in sequence
---@public
---@param dialog dialog[] The dialog entries to play in sequence
function this.playConversation(dialog)
    local index = 1

    this.stop()
    this.play(index, dialog)
end

--- Stops any ongoing playback
---@public
function this.stop()
    tes3.removeSound({
        reference = tes3.player,
    })

    event.trigger(EVENTS.conversationHistoryPlayStop)
end

---@private
---@param index number
---@param dialog dialog[]
function this.play(index, dialog)
    ---@type conversationHistoryPlayEventData
    local payload = {
        index = index,
    }
    event.trigger(EVENTS.conversationHistoryPlay, payload)

    this.say(dialog[index])

    timerManager.start({
        type = timer.real,
        duration = dialog[index].duration,
        iterations = 1,
        onTick = this.onPlayTick,
        cancellationEvents = { EVENTS.conversationHistoryPlayStop },
        data = {
            index = index,
            dialog = dialog,
        },
    })
end

---@private
---@param dialog dialog
function this.say(dialog)
    tes3.say({
        reference = tes3.player,
        soundPath = dialog.soundPath,
    })
end

---@private
---@param callback mwseTimerCallbackData
function this.onPlayTick(callback)
    local data = callback.timer.data
    if not data then
        return
    end

    local index = data.index
    local dialog = data.dialog

    this.play(
        index + 1,
        dialog
    )
end

return this
