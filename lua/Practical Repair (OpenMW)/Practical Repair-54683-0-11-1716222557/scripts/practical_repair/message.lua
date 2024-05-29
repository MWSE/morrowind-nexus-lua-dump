local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local storage = require("openmw.storage")
local settings = storage.globalSection("Settings_practical_repair_main_option")

return {
    eventHandlers = {
        PracticalRepair_message_eqnx = function(status)
            if settings:get("Notification") then
                ui.showMessage(status.msg)
                if status.fail then
                    ambient.playSound("repair fail", {
                        pitch = 2
                    })
                end
            end
        end
    }
}
