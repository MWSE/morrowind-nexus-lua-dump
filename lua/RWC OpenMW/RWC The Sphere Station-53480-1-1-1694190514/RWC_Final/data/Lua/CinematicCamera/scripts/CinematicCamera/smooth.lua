local storage = require('openmw.storage')

local smoothingSettings = storage.playerSection('SettingsCinematicCameraSmoothing')

return {
    rotation = function(new, current, dt) -- LPS normalized by time
        local k = math.min(1, math.pow(1 - smoothingSettings:get('rotationSmoothing'), dt))
        return current * k + new * (1 - k)
    end
}
