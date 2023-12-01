--global events registered to player, can be called by any part of comprehensive rebalance

local ui = require('openmw.ui')

local function showMessageEvent(msg)
	if msg then
		ui.showMessage(msg)
	else
		print("Blank message was shown!")
	end
end

local function showErrorEvent(msg)
	error(msg)
end

return {
    eventHandlers = {
        showMessage = showMessageEvent,
        showError = showErrorEvent
    }
}