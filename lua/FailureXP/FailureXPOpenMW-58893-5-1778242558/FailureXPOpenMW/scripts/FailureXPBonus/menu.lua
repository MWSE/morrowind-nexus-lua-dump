local ui       = require('openmw.ui')
local util     = require('openmw.util')
local storage  = require('openmw.storage')
local settings = require('scripts.FailureXPBonus.settings')

local v2 = util.vector2

local menuElement = nil
local sliderValue = settings.get()


local function onToggle(open)
    if open then
        if not menuElement then
            menuElement = buildMenu()
        end
    else
        if menuElement then
            settings.set(sliderValue)
            menuElement:destroy()
            menuElement = nil
        end
    end
end

return {
    engineHandlers = {
        onUiEvent = function(name, data)
            if name == 'FailureXPBonus_menu' then
                onToggle(data)
            end
        end
    }
}