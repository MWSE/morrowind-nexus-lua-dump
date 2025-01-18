-- In a player script
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage {
    key = 'MyModPage',
    l10n = 'MyMod',
    name = 'My Mod Name',
    description = 'My Mod Description',
}
I.Settings.registerGroup {
    key = 'SettingsPlayerMyMod',
    page = 'MyModPage',
    l10n = 'MyMod',
    name = 'My Group Name',
    description = 'My Group Description',
    permanentStorage = false,
    settings = {
        {
            key = 'Greeting',
            renderer = 'textLine',
            name = 'Greeting',
            description = 'Text to display when the game starts',
            default = 'Hello, world!',
        },
    },
}
local playerSettings = storage.playerSection('SettingsPlayerMyMod')
...
ui.showMessage(playerSettings:get('Greeting'))
-- ...
-- access a setting page registered by a global script
local globalSettings = storage.globalSection('SettingsGlobalMyMod')