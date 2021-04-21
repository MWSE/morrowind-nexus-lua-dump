local config = require('merz.improved_vanilla_leveling.config')
local function SetupMenu()
    local template = mwse.mcm.createTemplate({ name = 'Improved Vanilla Leveling' })
    template:saveOnClose('improved_vanilla_leveling', config)
    template:register()
    local preferences = template:createSideBarPage({ label = 'Preferences' })
    local toggles = preferences:createCategory({ label = 'Options' })
    toggles:createOnOffButton({
        label = 'Enhanced Tooltip',
        description = 'Changes the Level Up Progress tooltip to include attribute potential and skill level ups per '
            .. 'attribute.\nTakes the place of the MCP tooltip, if that tooltip is enabled.',
        variable = mwse.mcm:createTableVariable({
            id = 'levelup_tooltip',
            table = config
        })
    })
    toggles:createOnOffButton({
        label = 'Retroactive Health Calculation',
        description = 'Set to "Off" to disable the retroactive health calculation, allowing for use of another mod to '
            .. 'calculate health.',
        variable = mwse.mcm:createTableVariable({
            id = 'retroactive_health',
            table = config
        })
    })
end
event.register('modConfigReady', SetupMenu)