local core = require("openmw.core")
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require("openmw.types")

local skipRepeatedOpening = false

function onUiModeChanged(data)
	if data.newMode == I.UI.MODE.Container then
		local container = data.arg
		if (container and container.type == types.Container) and not types.Container.record(container).isOrganic then
			core.sendGlobalEvent( "transferItemsToContainer", { actor = self.object, container = container } )
		end
	end
end

return {
	eventHandlers = {
		UiModeChanged = onUiModeChanged
	}
}

