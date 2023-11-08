local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')

local function PressX(key)
	if key.symbol == 'x' then
		ui.showMessage('Save Restrictions - Player has pressed "X"')
    end
end

local function processSave(id)
	if id == input.ACTION.QuickSave then
		ui.showMessage('Save Restrictions - You have quicksaved')
	end
end

return {

    engineHandlers = {
		--onKeyPress = PressX,
		--onInputAction = processSave
    }
}