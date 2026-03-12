local storage = require('openmw.storage')

local MOD_NAME = 'AdjustableMerchantGold'
local SETTINGS_KEY = 'SettingsPlayer' .. MOD_NAME
local DEFAULT_MULTIPLIER = 5

local page = {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = 'PageName',
    description = 'PageDescription',
}

local group = {
    key = SETTINGS_KEY,
    page = MOD_NAME,
    l10n = MOD_NAME,
    name = 'GroupName',
    description = 'GroupDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'GoldMultiplier',
            renderer = 'number',
            name = 'GoldMultiplier_name',
            description = 'GoldMultiplier_description',
            default = DEFAULT_MULTIPLIER,
            argument = {
                min = 1,
                max = 100,
                integer = true,
            },
        },
    },
}

local function getMultiplier()
    local section = storage.playerSection(SETTINGS_KEY)
    return section:get('GoldMultiplier') or DEFAULT_MULTIPLIER
end

return {
    MOD_NAME = MOD_NAME,
    SETTINGS_KEY = SETTINGS_KEY,
    DEFAULT_MULTIPLIER = DEFAULT_MULTIPLIER,
    page = page,
    group = group,
    getMultiplier = getMultiplier,
}
