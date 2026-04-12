local core = require('openmw.core')
local menu = require('openmw.menu')

local L = core.l10n('WakeUp')

local function cleanSaves()
	local saveDir = menu.getCurrentSaveDir()
	local latestAutoSave = nil
	local saveName

	if not saveDir then return end

	for save, info in pairs(menu.getSaves(saveDir)) do
		if save == 'Quicksave.omwsave' or string.find(save, '^Quicksave %- %d*%.omwsave$') then
			menu.deleteGame(saveDir, save)
		elseif save == 'Autosave.omwsave' or string.find(save, '^Autosave %- %d*%.omwsave$') then
			if not saveName then
				latestAutoSave = info
				saveName = save
			elseif latestAutoSave.creationTime < info.creationTime then
				menu.deleteGame(saveDir, saveName)

				latestAutoSave = info
				saveName = save
			else
				menu.deleteGame(saveDir, save)
			end
		end
	end
end

local function doSave()
	cleanSaves()

	local saveDir = menu.getCurrentSaveDir()

	local status, result = pcall(function()
		menu.deleteGame(saveDir, L('save_name'):gsub('[ %[%]]', '_') .. '.omwsave')
	end)

	menu.saveGame(L('save_name'), 0)
end

local function loadLatestSave()
	local saveDir = menu.getCurrentSaveDir()
	local latestSave
	local saveName

	for key, data in pairs(menu.getSaves(saveDir)) do
		if not latestSave or data.creationTime > latestSave.creationTime then
			latestSave = data
			saveName = key
		end
	end	

	if latestSave then
		menu.loadGame(saveDir, saveName)
	end
end

return {
	eventHandlers = {
		wu_cleanSaves = cleanSaves,
		wu_doSave = doSave,
		wu_loadLatestSave = loadLatestSave
	}
}
