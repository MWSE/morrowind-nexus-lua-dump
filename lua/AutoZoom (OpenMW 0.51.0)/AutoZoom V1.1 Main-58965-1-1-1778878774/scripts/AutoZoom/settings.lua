local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local constants = require('scripts.AutoZoom.constants')

local section = storage.playerSection(constants.GROUP_KEY)
local registered = false
local keyByToken = {
    key_a = input.KEY.A,
    key_b = input.KEY.B,
    key_c = input.KEY.C,
    key_d = input.KEY.D,
    key_e = input.KEY.E,
    key_f = input.KEY.F,
    key_g = input.KEY.G,
    key_h = input.KEY.H,
    key_i = input.KEY.I,
    key_j = input.KEY.J,
    key_k = input.KEY.K,
    key_l = input.KEY.L,
    key_m = input.KEY.M,
    key_n = input.KEY.N,
    key_o = input.KEY.O,
    key_p = input.KEY.P,
    key_q = input.KEY.Q,
    key_r = input.KEY.R,
    key_s = input.KEY.S,
    key_t = input.KEY.T,
    key_u = input.KEY.U,
    key_v = input.KEY.V,
    key_w = input.KEY.W,
    key_x = input.KEY.X,
    key_y = input.KEY.Y,
    key_z = input.KEY.Z,
}
local selectableKeys = {
    'key_a', 'key_b', 'key_c', 'key_d', 'key_e', 'key_f', 'key_g',
    'key_h', 'key_i', 'key_j', 'key_k', 'key_l', 'key_m', 'key_n',
    'key_o', 'key_p', 'key_q', 'key_r', 'key_s', 'key_t', 'key_u',
    'key_v', 'key_w', 'key_x', 'key_y', 'key_z',
}

local function makeTriggerSetting(key, name, description)
    return {
        key = key,
        renderer = 'checkbox',
        name = name,
        description = description,
        default = constants.DEFAULTS[key],
    }
end

local function registerSettings()
    I.Settings.registerPage({
        key = constants.PAGE_KEY,
        l10n = constants.L10N,
        name = 'SettingsPageName',
        description = 'SettingsPageDescription',
    })

    I.Settings.registerGroup({
        key = constants.GROUP_KEY,
        page = constants.PAGE_KEY,
        l10n = constants.L10N,
        name = 'SettingsGroupName',
        description = 'SettingsGroupDescription',
        permanentStorage = false,
        settings = {
            {
                key = 'enableInFirstPerson',
                renderer = 'checkbox',
                name = 'Enable1st',
                description = 'Enable1stDescription',
                default = constants.DEFAULTS.enableInFirstPerson,
            },
            {
                key = 'enableInThirdPerson',
                renderer = 'checkbox',
                name = 'Enable3rd',
                description = 'Enable3rdDescription',
                default = constants.DEFAULTS.enableInThirdPerson,
            },
            makeTriggerSetting('triggerCreatures', 'TriggerCreatures', 'TriggerCreaturesDescription'),
            makeTriggerSetting('triggerNPC', 'TriggerNPC', 'TriggerNPCDescription'),
            makeTriggerSetting('triggerActivators', 'TriggerActivators', 'TriggerActivatorsDescription'),
            makeTriggerSetting('triggerContainers', 'TriggerContainers', 'TriggerContainersDescription'),
            makeTriggerSetting('triggerDoors', 'TriggerDoors', 'TriggerDoorsDescription'),
            makeTriggerSetting('triggerWeapons', 'TriggerWeapons', 'TriggerWeaponsDescription'),
            makeTriggerSetting('triggerArmor', 'TriggerArmor', 'TriggerArmorDescription'),
            makeTriggerSetting('triggerClothing', 'TriggerClothing', 'TriggerClothingDescription'),
            makeTriggerSetting('triggerIngredients', 'TriggerIngredients', 'TriggerIngredientsDescription'),
            makeTriggerSetting('triggerBooks', 'TriggerBooks', 'TriggerBooksDescription'),
            makeTriggerSetting('triggerLights', 'TriggerLights', 'TriggerLightsDescription'),
            makeTriggerSetting('triggerMisc', 'TriggerMisc', 'TriggerMiscDescription'),
            makeTriggerSetting('triggerPotions', 'TriggerPotions', 'TriggerPotionsDescription'),
            makeTriggerSetting('triggerLockpicks', 'TriggerLockpicks', 'TriggerLockpicksDescription'),
            makeTriggerSetting('triggerProbes', 'TriggerProbes', 'TriggerProbesDescription'),
            makeTriggerSetting('triggerRepairs', 'TriggerRepairs', 'TriggerRepairsDescription'),
            makeTriggerSetting('triggerApparatus', 'TriggerApparatus', 'TriggerApparatusDescription'),
            {
                key = 'manualZoomKey',
                renderer = 'select',
                name = 'ManualKey',
                description = 'ManualKeyDescription',
                argument = {
                    l10n = constants.L10N,
                    items = selectableKeys,
                },
                default = constants.DEFAULTS.manualZoomKey,
            },
            {
                key = 'focusTime',
                renderer = 'number',
                name = 'FocusTime',
                description = 'FocusTimeDescription',
                default = constants.DEFAULTS.focusTime,
                argument = { min = 0, max = 10 },
            },
            {
                key = 'zoomSpeed',
                renderer = 'number',
                name = 'ZoomSpeed',
                description = 'ZoomSpeedDescription',
                default = constants.DEFAULTS.zoomSpeed,
                argument = { min = 0.1, max = 10 },
            },
            {
                key = 'magnification',
                renderer = 'number',
                name = 'Magnification',
                description = 'MagnificationDescription',
                default = constants.DEFAULTS.magnification,
                argument = { min = 1.05, max = 10 },
            },
            {
                key = 'snapBackTime',
                renderer = 'number',
                name = 'SnapBackTime',
                description = 'SnapBackTimeDescription',
                default = constants.DEFAULTS.snapBackTime,
                argument = { min = 0, max = 5 },
            },
            {
                key = 'debugLogging',
                renderer = 'checkbox',
                name = 'DebugLogging',
                description = 'DebugLoggingDescription',
                default = constants.DEFAULTS.debugLogging,
            },
        },
    })
end

local function register()
    if registered then
        return
    end
    registerSettings()
    registered = true
end

local function get(key)
    local value = section:get(key)
    if value == nil then
        return constants.DEFAULTS[key]
    end
    return value
end

return {
    register = register,
    get = get,
    getKeyCode = function(token)
        return keyByToken[token]
    end,
}
