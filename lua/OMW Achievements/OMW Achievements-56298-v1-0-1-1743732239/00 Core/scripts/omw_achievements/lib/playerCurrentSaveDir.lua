local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local function onLoad()
    types.Player.sendMenuEvent(self.object, 'requireCurrentSaveDir')
end

return {
    engineHandlers = {
        onLoad = onLoad
    }
}