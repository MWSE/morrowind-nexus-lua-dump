local menu = require('openmw.menu')
local core = require('openmw.core')
local ui = require('openmw.ui')

local function requireCurrentSaveDir(data)
    
    local currentSaveDir = tostring(menu.getCurrentSaveDir())

    if data ~= nil then
        local temporaryTable = data
        temporaryTable['currentSaveDir'] = currentSaveDir
        core.sendGlobalEvent('getCurrentSaveDir', temporaryTable)
    end

    if data == nil then
        core.sendGlobalEvent('getCurrentSaveDir', {currentSaveDir = currentSaveDir})
    end

end

return {
    eventHandlers = {
        requireCurrentSaveDir = requireCurrentSaveDir
    }
}