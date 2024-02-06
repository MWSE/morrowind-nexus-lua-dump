local ui = require("openmw.ui")
local core = require("openmw.core")
local I = require("openmw.interfaces")
if  core.API_REVISION < 42 then
    local errorM = "Your OpenMW version is too old to use this mod! Please update to 0.49, or the latest development build."
I.Settings.registerPage {
    key = "SettingsBSG",
    l10n = "SettingsBSG",
    name = "Black Soul Gems",
    description = errorM
}
error(errorM)
end
local function BSG_ShowMessage(mess)
ui.showMessage(mess)

end

local ambient = require('openmw.ambient')
local function playSoundEvent(soundId)
    ambient.playSound(soundId)
end
return {eventHandlers = {BSG_ShowMessage = BSG_ShowMessage, BSG_playSoundEvent = playSoundEvent}}