local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsAttendMeMechanics',
    page = 'AttendMe',
    l10n = 'AttendMe',
    name = "Gameplay Settings",
    permanentStorage = false,
    settings = {
        {
            key = 'teleportFollowers',
            name = "Teleport Followers",
            default = true,
            renderer = 'checkbox',
            permanentStorage = false,
        },
    }
}

local mechanicSettings = storage.globalSection('SettingsAttendMeMechanics')

return {
    eventHandlers = {
        AttendMeTeleport = function(e)
            if mechanicSettings:get('teleportFollowers') then
                e.actor:teleport(e.cellName, e.position)
            end
        end
    }
}