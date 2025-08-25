local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'zoomKey',
	l10n = 'SmoothZoom',
    name = 'zoom_page_name',
})

I.Settings.registerGroup({
    key = 'Settings_main_Key',
    page = 'zoomKey',
    l10n = 'SmoothZoom',
    name = "group_name",
    permanentStorage = true,
    settings = {
		{
            key = 'DefaultFOV_Degrees',
            name = 'DefaultFOV_Degrees_name',
            description = 'DefaultFOV_Degrees_description',
            default = 60,
            renderer = 'number',
            argument = {
                min = 0,
                max = 180,
            },
        },
        {
            key = 'PressedFOV_Degrees',
            name = 'PressedFOV_Degrees_name',
            description = 'PressedFOV_Degrees_description',
            default = 20,
            renderer = 'number',
            argument = {
                min = 0,
                max = 180,
            },
        },
        {
            key = 'TransitionDuration_Seconds',
            name = 'TransitionDuration_Seconds_name',
            description = 'TransitionDuration_Seconds_description',
            default = 0.3,
            renderer = 'number',
        },
		{
			key = 'InputButtonCode',
			name = 'InputButtonCode_name',
			description = 'InputButtonCode_description',
			default = '2',
			renderer = 'textLine',
		},
		{
			key = 'InputDevice',
			name = 'Input_device_name',
			default = 'mouse',
			renderer = 'select',
			argument = {
				l10n = 'SmoothZoom',
				items = { 'mouse', 'keyboard' }
			}
		},
		{
			key = 'ApplyNow',
			name = 'Apply_now_name',
			description = 'Apply_now_description',
			default = false,
			renderer = 'checkbox',
		},
        {
			key = 'stop_the_mod',
			name = 'stop_the_mod_name',
			description = 'stop_the_mod_description',
			default = false,
			renderer = 'checkbox',
		},
    },
})

