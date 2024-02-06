local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local settingsBase = require('scripts.xaade.autosave.settingsBase')

local omwNavigationAutosave = 'OMWNavigationAutosave'

I.Settings.registerPage({
    key = omwNavigationAutosave,
    l10n = omwNavigationAutosave,
    name = 'NavigationAutosave',
    description = 'Creates autosaves when traveling between internal and external cells.',
})

local function floatSetting(prefix, key, name, description, default)
    return {
        key = key,
        renderer = 'number',
        name = name,
        description = description,
        default = default,
    }
end

local function boolSetting(prefix, key, name, description, default)
    return {
        key = key,
        renderer = 'checkbox',
        name = name,
        description = description,
        default = default,
    }
end


I.Settings.registerGroup({
    key = settingsBase.navigationAutosaveGroup,
    page = omwNavigationAutosave,
    l10n = omwNavigationAutosave,
    name = 'SaveFileCount',
	--description = 'The max number of saves created when autosaving',
    permanentStorage = true,
    order = 0,
    settings = {
        floatSetting('','numberOfSaves', 'Number of Saves', 'The number of saves is limited to this number. They are named NavigationAutosave and suffixed with the counter.', 3),
        boolSetting('', 'interiorSave', 'Interior to Interior Save', 'Save when moving from one interior to another interior cell', true),
		boolSetting('', 'sneakNoSave', 'Prevent saving while sneaking', 'Prevent saving while sneaking', false),
    },
})
