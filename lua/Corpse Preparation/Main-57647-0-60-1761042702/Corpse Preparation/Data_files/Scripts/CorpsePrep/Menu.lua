local I = require('openmw.interfaces')
local input = require('openmw.input')


input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CorpsePreparationSettings',
    key = "CorpsePreparation",
})


I.Settings.registerPage {
    key = 'CorpsePreparationSettingsPage',
    l10n = 'CorpsePreparationSettings',
    name = 'CorpsePreparation  Settings',
    description = 'CorpsePreparation configurations.',
}

I.Settings.registerGroup {
    key = 'CorpsePreparationcontrols',
    page = 'CorpsePreparationSettingsPage',
    l10n = 'CorpsePreparationSettings',
    name = 'CorpsePreparation controls',
    description = 'Configuration of controls for CorpsePreparation.',
    permanentStorage = true,
    settings = {
        {
            key = "CorpsePreparation",
            renderer = "inputBinding",
            name = "Start CorpsePreparation",
            description = 'Start CorpsePreparation',
            default = "t",
            argument = {
                type = "trigger",
                key = "CorpsePreparation"
        	},
		},
	}
}
