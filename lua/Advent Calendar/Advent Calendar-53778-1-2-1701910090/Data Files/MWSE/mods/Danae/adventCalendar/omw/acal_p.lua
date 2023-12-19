local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local ambient = require('openmw.ambient')
local debug = require('openmw.debug')

local messageBox = require("MWSE.mods.Danae.adventCalendar.omw.MessageBox")

local function AdventCalendarShowMessage(message)
    ui.showMessage(message)
end

if core.API_REVISION < 51 then
    I.Settings.registerPage {
        key = 'AdventCalendar',
        l10n = 'AdventCalendar',
        name = 'AdventCalendar',
        description = 'This version of OpenMW is too old. Update to the latest 0.49 or development release.',
    }
    error("This version of OpenMW is too old. Update to the latest 0.49 or development release.")
end
local function AdventCalendarShowMessageList(data)
    local message = data.message
    local buttons = data.buttons

    local winName = data.winName
    if not winName then
        winName = ""
    end
    messageBox.showMessageBox(winName, message, buttons)
end

local function AdventCalendarPlaySound(soundID)
    ambient.playSound(soundID)
end
local function AdventCalendarPlaySoundPath(soundID)
    ambient.playSoundFile(soundID)
end
return {
    engineHandlers = {

    },
    eventHandlers = { AdventCalendarShowMessage = AdventCalendarShowMessage, AdventCalendarPlaySound = AdventCalendarPlaySound, AdventCalendarPlaySoundPath = AdventCalendarPlaySoundPath, AdventCalendarShowMessageList = AdventCalendarShowMessageList
    ,
    UiModeChanged       = function(data)
        if not data.newMode and messageBox.getMessageBox() then
            -- I.UI.setMode("Interface", { windows = {} })
            messageBox.closeMessageBox()
        end
    end
 }
}
