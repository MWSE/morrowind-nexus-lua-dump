local core = require('openmw.core')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local l10n = core.l10n('Hauling')

local SECTION = 'SettingsHauling'

local function initSettings()
    local section = storage.playerSection(SECTION)
    
    I.Settings.registerPage {
        key = 'HaulingSettings',
        l10n = 'Hauling',
        name = 'Hauling Skill',
        description = l10n('settings_page_desc'),
    }
    
    I.Settings.registerGroup {
        key = SECTION,
        page = 'HaulingSettings',
        l10n = 'Hauling',
        name = l10n('settings_group_balance'),
        description = l10n('settings_group_balance_desc'),
        permanentStorage = false,
        settings = {
            {
                key = 'MaxFeatherBonus',
                renderer = 'number',
                name = l10n('setting_max_feather'),
                description = l10n('setting_max_feather_desc'),
                default = 150,
                argument = {
                    min = 50,
                    max = 500,
                    integer = true,
                },
            },
            {
                key = 'CurveExponent',
                renderer = 'number',
                name = l10n('setting_curve_exponent'),
                description = l10n('setting_curve_exponent_desc'),
                default = 1.6,
                argument = {
                    min = 1.0,
                    max = 3.0,
                },
            },
        },
    }
    
    print("HAULING SKILL MOD: Settings registered")
end

local function onInit()
    initSettings()
end

local function onLoad()
    initSettings()
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
    },
}