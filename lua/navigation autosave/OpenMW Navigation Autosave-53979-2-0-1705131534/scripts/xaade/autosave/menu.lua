local ui = require('openmw.ui')
local menu = require("openmw.menu")
require('scripts.xaade.autosave.settings')

local function try(f, catch_f)
	local status, exception = pcall(f)
	if not status then
		catch_f(exception)
	end
end

local function respondToSaveRequested(data)
	print('Landed at save requested event')
	local saveDir = menu.getCurrentSaveDir()
	local saveName = string.format('NavigationAutosave%s', data.saveSlot)
	print('Save Requested')
	
	try(function()
		menu.deleteGame(saveDir, string.format('%s.omwsave', saveName))
	end, function(e)
		print(string.format('delete failed. assume file %s.omwsave does not exist', saveName))
	end)
	menu.saveGame(saveName,saveName)
end


return {
	eventHandlers = {
	    omw_cflare_autosave_save = respondToSaveRequested
	}
}