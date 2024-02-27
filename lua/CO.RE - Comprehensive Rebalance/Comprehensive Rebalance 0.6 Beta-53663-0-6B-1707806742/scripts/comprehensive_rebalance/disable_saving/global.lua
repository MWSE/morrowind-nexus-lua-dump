local menu = require('openmw.menu')
local I = require('openmw.interfaces')

local function handleSaveEvent(data)
	I.Saving.enableSave(false)
	world.saveGame("testsave","testsave")
	--print(tostring(data.origin))
end

return
{
	eventHandlers =
	{
		playerSaved = handleSaveEvent
	},
}