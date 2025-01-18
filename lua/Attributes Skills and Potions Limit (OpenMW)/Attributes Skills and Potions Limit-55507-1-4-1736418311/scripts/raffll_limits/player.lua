local ui = require('openmw.ui')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')

return {
	eventHandlers = {
		UiModeChanged = function(data)
			print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
			if types.Player.stats.dynamic.fatigue(self).base <= 0 then
				if data.newMode == 'Alchemy' then
					ui.showMessage('You can\'t create potions right now.')
					interfaces.UI.removeMode('Alchemy')
					interfaces.UI.removeMode('Interface')
				end
				if data.newMode == 'Enchanting' then
					ui.showMessage('You can\'t create enchanted items right now.')
					interfaces.UI.removeMode('Enchanting')
					interfaces.UI.removeMode('Interface')
				end
				if data.newMode == 'Recharge' then
					ui.showMessage('You can\'t recharge right now.')
					interfaces.UI.removeMode('Recharge')
					interfaces.UI.removeMode('Interface')
				end
				if data.newMode == 'Repair' then
					ui.showMessage('You can\'t repair right now.')
					interfaces.UI.removeMode('Repair')
					interfaces.UI.removeMode('Interface')
				end
			end
		end
	}
}