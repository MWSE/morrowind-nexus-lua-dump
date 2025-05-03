local I = require('openmw.interfaces')

return {
    setPauseMode = function(isPaused)
        if isPaused then
            I.UI.setMode('Interface', { windows = {} })
        else
            I.UI.setMode()
        end
    end 
}


