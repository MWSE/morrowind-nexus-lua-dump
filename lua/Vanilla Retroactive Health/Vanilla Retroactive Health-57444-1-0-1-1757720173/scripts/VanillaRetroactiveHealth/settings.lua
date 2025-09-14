local async = require('openmw.async')
local self = require('openmw.self')
local storage = require('openmw.storage')

local common = require('scripts.VanillaRetroactiveHealth.common')

local retroactiveHealthModeKey = 'SettingsRetroactiveHealthMode' .. common.metadata.modId

local retroactiveHealthModeSetting = 'RetroactiveHealthMode'

local page = {
    key = common.metadata.modId,
    l10n = common.metadata.modId,
    name = common.metadata.modName,
}

local retroactiveHealthModeGroup = {
    key = retroactiveHealthModeKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Retroactive Health Mode',
    description = 'The mode used to calculate health.\n' ..
        '  Minimized: Take all endurance levels as late as possible.\n' ..
        '  Maximized: Take all endurance levels as early as possible.\n' ..
        '  Balanced: Spread endurance levels out evenly.',
    permanentStorage = false,
    settings = {
        {
            key = retroactiveHealthModeSetting,
            name = 'Mode',
            renderer = 'select',
            argument = {
                l10n = common.metadata.modId,
                items = {
                    "Minimized",
                    "Maximized",
                    "Balanced",
                }
            },
            default = "Maximized",
        },
    },
}

storage.playerSection(retroactiveHealthModeKey):subscribe(async:callback(function(_, _)
    self:sendEvent(common.events.RetroactiveHealthModeChanged)
end))

local function getSetting(group, setting)
    local settings = storage.playerSection(group)
    return settings:get(setting)
end

local function getRetroactiveHealthMode()
    return getSetting(retroactiveHealthModeKey, retroactiveHealthModeSetting)
end

return {
    page = page,
    groups = {
        retroactiveHealthModeGroup,
    },
    getRetroactiveHealthMode = getRetroactiveHealthMode,
}
