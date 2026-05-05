local i18n = mwse.loadTranslations("Pirate.HotkeysForConsoleCommands")
local config = require("Pirate.HotkeysForConsoleCommands.config")
require("Pirate.HotkeysForConsoleCommands.mcm")

local function toggleKey(e)
    if (e.keyCode == config.mcm.RAKey.keyCode
        and e.isAltDown == config.mcm.RAKey.isAltDown
        and e.isControlDown == config.mcm.RAKey.isControlDown
        and e.isShiftDown == config.mcm.RAKey.isShiftDown)
    then
    tes3.runLegacyScript({command = 'ra'})
    end
    if (e.keyCode == config.mcm.FixMeKey.keyCode
        and e.isAltDown == config.mcm.FixMeKey.isAltDown
        and e.isControlDown == config.mcm.FixMeKey.isControlDown
        and e.isShiftDown == config.mcm.FixMeKey.isShiftDown)
    then
    tes3.runLegacyScript({command = 'FixMe'})
    end
end

event.register("keyDown", toggleKey)