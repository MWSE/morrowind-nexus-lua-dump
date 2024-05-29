local ui = require("openmw.ui")
local core = require("openmw.core")
local self = require("openmw.self")
local ambient = require("openmw.ambient")

return {
    eventHandlers = {
        CF_ShowMessage = function(msg)
            ui.showMessage(msg)
        end,
        CF_PlaySound = function(sound)
            ambient.playSound(sound)
        end,
    },
    engineHandlers = {
        onLoad = function()
            core.sendGlobalEvent("CF_SetPlayer", self.object)
        end
    }
}
