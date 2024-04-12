local ui = require('openmw.ui')



local function Restock_showMessage(msg)
	ui.showMessage(msg)
end

return {
	eventHandlers = {
		Restock_showMessage = showMessage,
	}
}