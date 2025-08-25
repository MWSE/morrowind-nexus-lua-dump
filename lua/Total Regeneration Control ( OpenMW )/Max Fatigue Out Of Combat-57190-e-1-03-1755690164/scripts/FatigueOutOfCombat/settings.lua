local I       = require('openmw.interfaces')
local storage = require('openmw.storage')


local function initSettings()
    I.Settings.registerGroup({
        key = 'Settings_Fatigue_Out_Of_Combat_key',
        page = 'Fatigue_Out_Of_Combat_page',
        l10n = 'FatigueOutOfCombat',
        name = 'Fatigue_Out_Of_Combat_name',
        permanentStorage = true,
        settings = {
            {
                key = 'disatance',
                name = 'disatance_name',
                description = 'disatance_description',
                default = 8000,
                renderer = 'number',
                argument = {
                    min = 100,
                },
            },
            {
                key = 'delay',
                name = 'delay_name',
                description = 'delay_description',
                default = 7,
                renderer = 'number',
                argument = {
                    min = 0,
                },
            },
        }
    })
end

local globalSettings = storage.globalSection('Settings_Fatigue_Out_Of_Combat_key')

return {
    initSettings = initSettings,
    globalSettings = globalSettings,
}