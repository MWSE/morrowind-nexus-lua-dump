local ui = require('openmw.ui')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local Saving = require('openmw.interfaces').Saving

local function PressX(key)
	if key.symbol == 'x' then
		ui.showMessage('Save Restrictions - Player has pressed "X"')
		core.sendGlobalEvent('playerSaved', {origin = self.object})
    end
end

local function processSave(id)
	if id == input.ACTION.QuickSave then
		--core.sendGlobalEvent("playerSaved")
		ui.showMessage('Save Restrictions - You have quicksaved')
	end
end

return {

    engineHandlers = {
		onKeyPress = PressX,
		onInputAction = processSave
    }
}