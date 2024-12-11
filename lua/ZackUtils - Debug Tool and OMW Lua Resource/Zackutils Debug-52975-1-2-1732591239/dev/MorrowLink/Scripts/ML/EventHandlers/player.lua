--This file registers events for the player.

local MorrowLinkEvents = {}

local heldEvents = {}

MorrowLinkEvents.EVENTS = {onDeath = 1, onFrame = 2, onCellChange = 3, }

MorrowLinkEvents.register = function(eventId, handler)
    if not heldEvents[eventId] then
        heldEvents[eventId] = {}
    end
    table.insert(heldEvents[eventId],handler)
end
return MorrowLinkEvents