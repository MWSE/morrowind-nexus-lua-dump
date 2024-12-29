local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local oldCell = nil

local function hasCellChanged()
    if self.cell == oldCell then return
    else 
        oldCell = self.cell
        core.sendGlobalEvent('noDarkLights', {player = self.object})
    end
end

return {
    engineHandlers = {
        onUpdate = function()
            hasCellChanged()
        end
    }
}