local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
--local input = require('openmw.input')
local KEY = require('openmw.input').KEY
local resources = types.Actor.stats.dynamic
TAKEALL_KEYBINDING = KEY.F


OPENED_CONTAINER = nil
OPENED_BOOK = nil
OPENED_TIMESTAMP = 0

local function closeUI()
	I.UI.setMode()
end

local function onKey(key)
	--print(core.getRealTime() - OPENED_TIMESTAMP)
	if key.code == TAKEALL_KEYBINDING and core.getRealTime() - OPENED_TIMESTAMP < 0.05 then
		if OPENED_CONTAINER and types.Actor.objectIsInstance(OPENED_CONTAINER) and resources.health(OPENED_CONTAINER).current >0 then
			ui.showMessage("Cannot quickloot living Actors")
			return
		end
		if I.UI.getMode() == "Container" and OPENED_CONTAINER then
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
	if types.Actor.objectIsInstance(obj) and resources.health(obj).current >0 then
		return
	end
	
	--if I.UI.getMode() == "Container" then --prevent looting living actors
		OPENED_CONTAINER = obj
		OPENED_BOOK = nil
		OPENED_TIMESTAMP = 999999999
	--else
	--	OPENED_CONTAINER = nil
	--	OPENED_BOOK = nil
	--end
end

local function openedBook(data)
	local obj = data[1]
	local actor = data[2]
	OPENED_BOOK = obj
	OPENED_CONTAINER = nil
	OPENED_TIMESTAMP = 999999999
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
				OPENED_TIMESTAMP = core.getRealTime()
			end
			if (data.oldMode == "Book" or data.oldMode == "Scroll") and OPENED_BOOK then
				OPENED_BOOK = nil
				OPENED_TIMESTAMP = core.getRealTime()
			end
		end
	}
}