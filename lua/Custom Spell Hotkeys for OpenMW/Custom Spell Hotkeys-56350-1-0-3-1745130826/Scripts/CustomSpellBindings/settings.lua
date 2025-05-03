local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local modInfo = require('Scripts.CustomSpellBindings.modInfo')

I.Settings.registerRenderer(
	'inputKeySelection',
	function(value, set)
		local name = 'No Key Set'
		if value then
			name = input.getKeyName(value)
		end
		return {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.padding,
					content = ui.content {
						{
							template = I.MWUI.templates.textEditLine,
							props = {
								text = name,
							},
							events = {
								keyPress = async:callback(function(e)
									if e.code == input.KEY.Escape then 
                                        return
                                    end

									set(e.code)
								end),
							},
						},
					},
				},
			},
		}
	end
)

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = 'Custom Spell Hotkeys',
	description = 'Allows you to set a spell hotkey to any key on your keyboard'
}

I.Settings.registerGroup {
	key = 'CustomSpellHotkeysSection',
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = 'General',
	permanentStorage = false,
	settings = {
        {
            key = 'modEnabled',
            renderer = 'checkbox',
            argument = {},
            name = 'Enable Mod',
            description = 'Is the mod enabled?',
            default = true,
        },
        {
            key = 'spellListKey',
            renderer = 'inputKeySelection',
            argument = {},
            name = 'List hotkeys',
            description = 'Show an interactive list of hotkeys',
            default = input.KEY.Delete,
        },
        {
            key = 'setHotkeyKey',
            renderer = 'inputKeySelection',
            argument = {},
            name = 'Add hotkey',
            description = 'Add a new hotkey',
            default = input.KEY.Insert,
        },
	}
}