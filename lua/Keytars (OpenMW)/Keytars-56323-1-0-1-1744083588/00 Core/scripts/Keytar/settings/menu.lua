local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')

local l10n = core.l10n('Keytar')
local versionString = "1.0.1"

-- inputKeySelection by Pharis
I.Settings.registerRenderer('Keytar/inputKeySelection', function(value, set)
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
								if e.code == input.KEY.Escape then return end
								set(e.code)
							end),
						},
					},
				},
			},
		},
	}
end)

-- Settings page
I.Settings.registerPage {
    key = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}
I.Settings.registerGroup {
    key = 'Settings/Keytar/Keybinds',
    page = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'toggleKeytar',
            renderer = 'Keytar/inputKeySelection',
            name = 'ToggleKeytar',
            default = input.KEY.V
        }
    },
}
