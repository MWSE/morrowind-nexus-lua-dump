local self = require("openmw.self")


local function onActivated(actor)
    actor:sendEvent("activated",self)
    end

    return {
        engineHandlers = {
            onActivated = onActivated,
            onUpdate = function()
               -- self.controls.run = true
              --  self.controls.sneak = true

            end
        }
    }