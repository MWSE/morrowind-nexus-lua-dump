local storage = require('openmw.storage')   
local I = require("openmw.interfaces")
local async = require('openmw.async')
local _playerSettings = storage.playerSection('DynamicSoundsSettingsGroup')
local core = require('openmw.core')


I.Settings.registerPage {
        key = 'DynamicSoundsPage',
        l10n = 'DynamicSounds',
        name = 'Dynamic Sounds',
        description = 'Dynamic Sounds Settings',
}

I.Settings.registerGroup {
    key = 'DynamicSoundsSettingsGroup',
    page = 'DynamicSoundsPage',
    l10n = 'DynamicSounds',
    name = 'Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'enableMod',
            renderer = 'checkbox',
            name = 'Enable Dynamic Sounds',
            description = '',
            default = true,
        },  	
        {
            key = 'playChance',
            renderer = 'number',
            name = 'Default Play Change (%)',
            description = 'The default play change of non loop sounds',
            default = 20,
        },  
        {
            key = 'maxDistanceObjectSounds',
            renderer = 'number',
            name = 'Maximum distance for objects sounds',
            description = 'Maximum distance for objects to play sounds',
            default = 2000,
        }, 
        {
            key = 'dayStartingHour',
            renderer = 'number',
            name = 'Day Starting Hour',
            description = '',
            default = 6,
        },  
        {
            key = 'dayEndingHour',
            renderer = 'number',
            name = 'Day Ending Hour',
            description = '',
            default = 19,
        }, 
        {
            key = 'enableCreatureComponent',
            renderer = 'checkbox',
            name = 'Enable Creature Sounds Component',
            description = 'Enables custom sounds for creatures',
            default = true,
        }, 
        {
            key = 'creatureDistanceToPlayer',
            renderer = 'number',
            name = 'Max Creature Distance to Enable Sounds',
            description = 'Creatures will no longer play custom sounds if their distance in superior to this value. Decreasing this can improve performance.',
            default = 3500,
        },                                                 
        {
            key = 'enableDebugMode',
            renderer = 'checkbox',
            name = 'Enable Debug Mode',
            description = '',
            default = false,
        }        
    },
}

core.sendGlobalEvent("setUserSettings", { 
    enableMod = _playerSettings:get('enableMod'), 
    playChance = _playerSettings:get('playChance'),
    enableDebugMode = _playerSettings:get('enableDebugMode'),
    maxDistanceObjectSounds =  _playerSettings:get('maxDistanceObjectSounds'),
    dayStartingHour = _playerSettings:get('dayStartingHour'),
    dayEndingHour = _playerSettings:get('dayEndingHour'),
    enableCreatureComponent = _playerSettings:get('enableCreatureComponent'),
    creatureDistanceToPlayer = _playerSettings:get('creatureDistanceToPlayer'),

 })

_playerSettings:subscribe(async:callback(function(section, key)
    -- if key then
    --     print('Value is changed:', key, '=', _playerSettings:get(key))
    --     core.sendGlobalEvent("userSettingsChanged", { settingsKey=key, settingsValue=_playerSettings:get(key) })
    -- end
    core.sendGlobalEvent("setUserSettings", { 
        enableMod = _playerSettings:get('enableMod'), 
        playChance = _playerSettings:get('playChance'),
        enableDebugMode = _playerSettings:get('enableDebugMode'),
        maxDistanceObjectSounds =  _playerSettings:get('maxDistanceObjectSounds'), 
        dayStartingHour = _playerSettings:get('dayStartingHour'),
        dayEndingHour = _playerSettings:get('dayEndingHour'),    
        enableCreatureComponent = _playerSettings:get('enableCreatureComponent'),    
        creatureDistanceToPlayer = _playerSettings:get('creatureDistanceToPlayer'),
     })
    
end))


