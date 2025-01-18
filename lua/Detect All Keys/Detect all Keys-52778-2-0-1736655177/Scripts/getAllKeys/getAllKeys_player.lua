local ui = require("openmw.ui")
local core = require("openmw.core")
local function ZHAC_ShowMessage(message) ui.showMessage(message) end

return {
    eventHandlers = {ZHAC_ShowMessage = ZHAC_ShowMessage},
    engineHandlers = {
        onInit = function()
            if (core.API_REVISION < 69) then
                ui.showMessage(
                    "DetectAllKeys detected an older version of OpenMW. The mod require OpenMW 0.49!")
            end
        end
    }
}
