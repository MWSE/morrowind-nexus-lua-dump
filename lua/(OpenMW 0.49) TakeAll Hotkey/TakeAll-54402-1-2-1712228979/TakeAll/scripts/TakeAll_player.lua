local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local ambient = require('openmw.ambient')

TAKEALL_KEYBINDING = 'f'


OPENED_CONTAINER = nil
OPENED_BOOK = nil

local function closeUI()
	I.UI.setMode()
end

local function onKey(key)
	if key.symbol == TAKEALL_KEYBINDING then
		if OPENED_CONTAINER then
			if OPENED_CONTAINER.owner.recordId then
				ui.showMessage("This container belongs to "..OPENED_CONTAINER.owner.recordId)
			elseif OPENED_CONTAINER.owner.factionId and types.NPC.getFactionRank(self, OPENED_CONTAINER.owner.factionId) == 0 then
				ui.showMessage("This container belongs to "..OPENED_CONTAINER.owner.factionId)
			elseif OPENED_CONTAINER.owner.factionId and types.NPC.getFactionRank(self, OPENED_CONTAINER.owner.factionId) < OPENED_CONTAINER.owner.factionRank then
				ui.showMessage("You need a higher rank to loot this container")
			else
				core.sendGlobalEvent("TakeAll_takeAll",{self, OPENED_CONTAINER})
			end
		elseif OPENED_BOOK then
			if OPENED_BOOK.owner.recordId then
				ui.showMessage("This book belongs to "..OPENED_BOOK.owner.recordId)
			elseif OPENED_BOOK.owner.factionId and types.NPC.getFactionRank(self, OPENED_BOOK.owner.factionId) == 0 then
				ui.showMessage("This book belongs to "..OPENED_BOOK.owner.factionId)
			elseif OPENED_BOOK.owner.factionId and types.NPC.getFactionRank(self, OPENED_BOOK.owner.factionId) < OPENED_BOOK.owner.factionRank then
				ui.showMessage("You need a higher rank to loot this book")
			else
				core.sendGlobalEvent("TakeAll_takeBook",{self, OPENED_BOOK})
			end
		end
	end
end

local function openedContainer(data)
	local obj = data[1]
	local actor = data[2]
	if I.UI.getMode() == "Container" then --prevent looting living actors
		OPENED_CONTAINER = obj
	end
end

local function openedBook(data)
	local obj = data[1]
	local actor = data[2]
	OPENED_BOOK = obj
end

return {
	engineHandlers = { onKeyPress = onKey },
	eventHandlers = {
		TakeAll_openedContainer = openedContainer,
		TakeAll_openedBook = openedBook,
		TakeAll_closeUI = closeUI,
		TakeAll_PlaySound	= function(sound)
			ambient.playSound(sound)
		end,
		UiModeChanged	= function(data)
			if data.oldMode == "Container" and OPENED_CONTAINER then
				OPENED_CONTAINER = nil
			end
			if (data.oldMode == "Book" or data.oldMode == "Scroll") and OPENED_BOOK then
				OPENED_BOOK = nil
			end
		end
	}
}