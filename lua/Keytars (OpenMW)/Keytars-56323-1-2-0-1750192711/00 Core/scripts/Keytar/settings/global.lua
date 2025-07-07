local I = require('openmw.interfaces')

local wavParser = require('scripts.Keytar.util.wav_parser')
local genres = wavParser.Genre
local genresList = {}
for k, v in pairs(genres) do
    genresList[v] = k
end

-- Settings page
I.Settings.registerGroup {
    key = 'Settings/Keytar/3_Options',
    page = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigCategoryOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'silenceAmbientMusic',
            renderer = 'checkbox',
            name = 'ConfigAmbientMusic',
            description = 'ConfigAmbientMusicDesc',
            default = true,
        },
        {
            key = 'nearbyNpcsDance',
            renderer = 'checkbox',
            name = 'ConfigNearbyNpcsDance',
            description = 'ConfigNearbyNpcsDanceDesc',
            default = true,
        },
        {
            key = 'danceTimingVariation',
            renderer = 'checkbox',
            name = 'ConfigDanceTimingVariation',
            description = 'ConfigDanceTimingVariationDesc',
            default = true,
        },
        {
            key = 'enableFollowerAI',
            renderer = 'checkbox',
            name = 'ConfigFollowerAI',
            description = 'ConfigFollowerAIDesc',
            default = true,
        },
        {
            key = 'immortalKeytarists',
            renderer = 'checkbox',
            name = 'ConfigKeytaristsImmortal',
            description = 'ConfigKeytaristsImmortalDesc',
            default = true,
        },
        {
            key = 'untargetableKeytarists',
            renderer = 'checkbox',
            name = 'ConfigKeytaristsUntargetable',
            description = 'ConfigKeytaristsUntargetableDesc',
            default = true,
        },
        {
            key = 'pacifistKeytarists',
            renderer = 'checkbox',
            name = 'ConfigKeytaristsPacifist',
            description = 'ConfigKeytaristsPacifistDesc',
            default = true,
        },
        {
            key = 'inspiringKeytarists',
            renderer = 'checkbox',
            name = 'ConfigKeytaristsInspiring',
            description = 'ConfigKeytaristsInspiringDesc',
            default = true,
        },
        {
            key = 'teleportingKeytarists',
            renderer = 'checkbox',
            name = 'ConfigKeytaristsTeleporting',
            description = 'ConfigKeytaristsTeleportingDesc',
            default = true,
        }
    },
}

I.Settings.registerGroup {
    key = 'Settings/Keytar/4_Technical',
    page = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigCategoryTechnical',
    description = 'ConfigCategoryTechnicalDesc',
    permanentStorage = true,
    settings = {
        {
            key = 'silenceAmbientMusicInterval',
            renderer = 'number',
            name = 'ConfigSilenceAmbientMusicInterval',
            description = 'ConfigSilenceAmbientMusicIntervalDesc',
            default = 30,
            min = 1,
            max = 60,
        },
        {
            key = 'playerKeytarVolume',
            renderer = 'number',
            name = 'ConfigPlayerKeytarVolume',
            description = 'ConfigPlayerKeytarVolumeDesc',
            default = 1.0,
            min = 0.0,
            max = 50.0,
        },
        {
            key = 'npcKeytarVolume',
            renderer = 'number',
            name = 'ConfigNpcKeytarVolume',
            description = 'ConfigNpcKeytarVolumeDesc',
            default = 3.0,
            min = 0.0,
            max = 50.0,
        },
        {
            key = 'dagothKeytarVolume',
            renderer = 'number',
            name = 'ConfigDagothKeytarVolume',
            description = 'ConfigDagothKeytarVolumeDesc',
            default = 5.0,
            min = 0.0,
            max = 50.0,
        },
        {
            key = 'dagothReverbVolume',
            renderer = 'number',
            name = 'ConfigDagothReverbVolume',
            description = 'ConfigDagothReverbVolumeDesc',
            default = 1,
            min = 0.0,
            max = 50.0,
        },
        {
            key = 'validKeytaristRecheckInterval',
            renderer = 'number',
            name = 'ConfigValidKeytaristRecheckInterval',
            description = 'ConfigValidKeytaristRecheckIntervalDesc',
            default = 5,
            min = 0,
            max = 60,
        },
        {
            key = 'playerFreezeDistance',
            renderer = 'number',
            name = 'ConfigPlayerFreezeDistance',
            description = 'ConfigPlayerFreezeDistanceDesc',
            default = 200,
            min = 0,
            max = 1000,
        },
        {
            key = 'targetFreezeDistance',
            renderer = 'number',
            name = 'ConfigTargetFreezeDistance',
            description = 'ConfigTargetFreezeDistanceDesc',
            default = 300,
            min = 0,
            max = 1000,
        },
        {
            key = 'playerMoveDistance',
            renderer = 'number',
            name = 'ConfigPlayerMoveDistance',
            description = 'ConfigPlayerMoveDistanceDesc',
            default = 100,
            min = 0,
            max = 1000,
        },
        {
            key = 'teleportingKeytaristsDistance',
            renderer = 'number',
            name = 'ConfigKeytaristsTeleportingDistance',
            description = 'ConfigKeytaristsTeleportingDistanceDesc',
            default = 3000,
            min = 500,
            max = 10000,
        },
        {
            key = 'npcDanceDistance',
            renderer = 'number',
            name = 'ConfigNpcDanceDistance',
            description = 'ConfigNpcDanceDistanceDesc',
            default = 1500,
            min = 0,
            max = 10000,
        },
        {
            key = 'musicResetTime',
            renderer = 'number',
            name = 'ConfigMusicResetTime',
            description = 'ConfigMusicResetTimeDesc',
            default = 3,
            min = 0,
            max = 300,
        }
    },
}
I.Settings.registerGroup {
	key = 'Settings/Keytar/2_CustomMusic',
	page = 'Keytar',
	l10n = 'Keytar',
	name = 'ConfigCategoryCustomMusic',
	description = 'ConfigCategoryCustomMusicDesc',
	permanentStorage = true,
	settings = {
		{
			key = 'customMusicPath',
			renderer = 'Keytar/betterTextInput',
			name = 'ConfigCustomMusicPath',
			default = 'dagoth.mp3',
            argument = {
                number = false
            }
		},
		{
			key = 'customMusicLength',
			renderer = 'Keytar/betterTextInput',
			name = 'ConfigCustomMusicLength',
			default = 1 / (147/60) * 480,
            argument = {
                number = true,
                numMin = 1,
                numMax = 10000,
                numPrecision = 3,
                callbackGroup = 'Settings/Keytar/2_CustomMusic',
                callbackSetting = 'customMusicLength',
            }
		},
		{
			key = 'customMusicBpm',
			renderer = 'Keytar/betterTextInput',
			name = 'ConfigCustomMusicBpm',
			default = 147,
            argument = {
                number = true,
                numMin = 1,
                numMax = 1000,
                numPrecision = 1,
                callbackGroup = 'Settings/Keytar/2_CustomMusic',
                callbackSetting = 'customMusicBpm',
            }
		},
		{
			key = 'autoDetectBPM',
			renderer = 'Keytar/autoDetectButton',
			name = 'ConfigCustomMusicAutoDetect',
            default = false
		},
		{
			key = 'customMusicGenre',
			renderer = 'select',
			name = 'ConfigCustomMusicGenre',
			description = 'ConfigCustomMusicGenreDesc',
			default = "DEFAULT",
			argument = {
				l10n = 'Keytar',
				items = genresList,
			},
		},
        {
            key = 'autoDetectBatchSize',
            renderer = 'number',
            name = 'ConfigCustomMusicAutoDetectBatchSize',
            description = 'ConfigCustomMusicAutoDetectBatchSizeDesc',
            default = 1,
            minValue = 0.1,
            maxValue = 10
        },
        {
            key = 'autoDetectVerbose',
            renderer = 'checkbox',
            name = 'ConfigCustomMusicAutoDetectVerbose',
            description = 'ConfigCustomMusicAutoDetectVerboseDesc',
            default = false
        }
	}
}

return {
    eventHandlers = {
        UpdateGlobalSettingArg = function(data)
            I.Settings.updateRendererArgument(data.groupKey, data.settingKey, data.args)
        end
    }
}