local ui = require('openmw.ui')
local menu = require("openmw.menu")

local function try(f, catch_f)
	local status, exception = pcall(f)
	if not status then
		catch_f(exception)
	end
end

local function respondToSaveRequested()
	local saveDir = menu.getCurrentSaveDir()
	local saveName = "Roguelite"
	try(function()
		menu.deleteGame(saveDir, string.format('%s.omwsave', saveName))
	end, function(e)
		print(string.format('delete failed. assume file %s.omwsave does not exist', saveName))
	end)
	print("roguelite saving")
	menu.saveGame(saveName,saveName)
end


return {
	eventHandlers = {
	   Roguelite_saveBeforeStart = respondToSaveRequested
	}
}