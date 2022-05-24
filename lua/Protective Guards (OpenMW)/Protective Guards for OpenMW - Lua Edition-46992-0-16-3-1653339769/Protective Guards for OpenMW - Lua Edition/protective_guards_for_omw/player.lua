local I = require('openmw.interfaces')
local MOD_NAME = "Protective Guards"
local ui = require('openmw.ui')
local types = require("openmw.types")

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = MOD_NAME,
    description = "Guards protect against hostile NPCs and Creatures. Guards will not protect if you are criminal."
}


return {
    engineHandlers = {
    },
    eventHandlers = {
    ProtectiveGuards_guardPursueNotifyPlayer_eqnx = function(pursuer)
        local pursuerName = types.NPC.record(pursuer).name
        ui.showMessage(pursuerName.." joins the pursuit!")
    end
    }
}
