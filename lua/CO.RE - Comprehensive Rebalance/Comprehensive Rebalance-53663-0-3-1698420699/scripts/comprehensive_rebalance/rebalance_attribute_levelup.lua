local ui = require('openmw.ui')
local storage = require('openmw.storage')

local MOD_NAME = "comprehensive_rebalance"
local playerSettings = storage.globalSection("SettingsGlobal" .. MOD_NAME .. "char")

local function SetRealtimeMenus(data)
	if data.newMode == 'LevelUp' then
		--ui.showMessage('Opened LevelUp')
	end
end

return {
    eventHandlers = {
		UiModeChanged = SetRealtimeMenus
	}
}