local I = require('openmw.interfaces')

-- Settings page
I.Settings.registerGroup {
    key = 'Settings/Bardcraft/3_GlobalOptions',
    page = 'Bardcraft',
    l10n = 'Bardcraft',
    name = 'ConfigCategoryGlobalOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'bJamMode',
            renderer = 'checkbox',
            name = 'ConfigJamMode',
            description = 'ConfigJamModeDesc',
            default = false,
        },
        {
            key = 'bEnablePracticeEfficiency',
            renderer = 'checkbox',
            name = 'ConfigEnablePracticeEfficiency',
            description = 'ConfigEnablePracticeEfficiencyDesc',
            default = true,
        },
        {
            key = 'bEnableTimeRestriction',
            renderer = 'checkbox',
            name = 'ConfigEnableTimeRestriction',
            description = 'ConfigEnableTimeRestrictionDesc',
            default = true,
        },
        {
            key = 'bEnableAnimations',
            renderer = 'checkbox',
            name = 'ConfigEnableAnimations',
            description = 'ConfigEnableAnimationsDesc',
            default = true,
        },
        {
            key = 'bInfiniteLuteRelease',
            renderer = 'checkbox',
            name = 'ConfigInfiniteLuteRelease',
            description = 'ConfigInfiniteLuteReleaseDesc',
            default = false,
        },
		{
			key = 'fInstrumentVolume',
			renderer = 'number',
			name = 'ConfigInstrumentVolume',
			default = 1.0,
			argument = {
				min = 0.0,
			}
		},
        {
            key = 'fOverallGoldMult',
            renderer = 'number',
            name = 'ConfigOverallGoldMult',
            default = 1.0,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fTavernGoldMult',
            renderer = 'number',
            name = 'ConfigTavernGoldMult',
            default = 1.0,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fStreetGoldMult',
            renderer = 'number',
            name = 'ConfigStreetGoldMult',
            default = 1.0,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fBaseXpPerNote',
            renderer = 'number',
            name = 'ConfigBaseXpPerNote',
            default = 1.0,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fTavernXpMult',
            renderer = 'number',
            name = 'ConfigTavernXpMult',
            default = 1.5,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fStreetXpMult',
            renderer = 'number',
            name = 'ConfigStreetXpMult',
            default = 0.2,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fPracticeXpMult',
            renderer = 'number',
            name = 'ConfigPracticeXpMult',
            default = 1.0,
            argument = {
                min = 0.0,
            }
        },
        {
            key = 'fTroupeDiminishMult',
            renderer = 'number',
            name = 'ConfigTroupeDiminishMult',
            description = 'ConfigTroupeDiminishMultDesc',
            default = 0.5,
            argument = {
                min = 0.0,
                max = 1.0,
            }
        },
    },
}