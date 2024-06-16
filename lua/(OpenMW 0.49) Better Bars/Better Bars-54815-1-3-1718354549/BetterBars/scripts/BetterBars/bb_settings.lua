
settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "LENGTH_MULT",
			name = "Bar length Multiplier",
			description = "",
			renderer = "number",
			default = 0.9,
			integer = false,
			argument = {
				min = 0.01,
				max = 1000,
				integer = false,
			},
		},
		{
			key = "MAX_LENGTH",
			name = "Max Length",
			description = "Squishes the bars if one exceeds this length",
			renderer = "number",
			default = 3800,
			argument = {
				min = 0.01,
				max = 9999,
			},
		},
		{
			key = "LENGTH_EQUALIZER",
			name = "Bar length Equalizer (0-1)",
			description = "",
			renderer = "number",
			default = 0,
			argument = {
				min = 0,
				max = 1,
			},
		},
		{
			key = "LAGBAR",
			renderer = "checkbox",
			name = "Damage-Bar",
			description = "Visualizes recently lost resources",
			default = true,
		},
		{
			key = "HEALBAR",
			renderer = "checkbox",
			name = "Healbar",
			description = "Visualizes incoming healing",
			default = true,
		},
		{
			key = "TEXT",
			name = "Text",
			description = "Show numbers on the bars",
			default = "current", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"hidden", "current", "current/max"},
			},
		},
		{
			key = "TEXT_POS",
			name = "Text Position",
			description = "If the text isn't left, it will get colored when the bar flashes",
			default = "right outside", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"left", "right", "right outside"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "BORDER_STYLE",
			name = "Border style",
			description = "",
			default = "thin", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "thin", "normal", "thick", "verythick"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "POSITION",
			name = "Position",
			description = "",
			default = "Bottom Left", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Bottom Left", "Top Left"},
			},
		},
		{
			key = "THICKNESS",
			name = "Thickness",
			description = "of the bars",
			renderer = "number",
			default = 12,
			argument = {
				min = 1,
				max = 1000,
			},
		},
		{
			key = "LERPSPEED",
			name = "Animation Speed",
			description = "How fast the bars are animated, for example on physical damage taken",
			default = 128,
			min = 1,
			renderer = "number",
		},
		{
			key = "LAGDURATION",
			name = "Damage Taken Visualizer Duration",
			description = "For how long the damage bar will indicate recently lost resources",
			default = 0.7, 
			min = 0.1,
			renderer = "number",
		},
		{
			key = "HEALTH_FLASHING_THRESHOLD",
			name = "Health Flashing Threshold",
			description = "in percent",
			default = 0.35, 
			argument = {
				min = 0,
				max = 1,
			},
			renderer = "number",
		},
		{
			key = "FATIGUE_FLASHING_THRESHOLD",
			name = "Fatigue Flashing Threshold",
			description = "in percent",
			default = 0.15, 
			argument = {
				min = 0,
				max = 1,
			},
			renderer = "number",
		},
		{
			key = "MAGICKA_FLASHING_THRESHOLD",
			name = "Magicka Flashing Threshold",
			description = "in percent",
			default = 0.25, 
			argument = {
				min = 0,
				max = 1,
			},
			renderer = "number",
		},
		{
			key = "HEALTH_COL",
			name = "Health Color",
			description = "",
			disabled = false,
			default =  util.color.hex("c83c1e"), --red
			--default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("b7b7b7"), --white
			renderer = "color",
		},
		{
			key = "HEALTHLAG_COL",
			name = "Health Damage Color",
			description = "Color of recently lost health",
			disabled = false,
			default =  util.color.hex("9b050a"), --red
			--default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("b7b7b7"), --white
			renderer = "color",
		},
		{
			key = "HEALING_COL",
			name = "Healing Color",
			description = "Color of incoming healing",
			disabled = false,
			default = util.color.hex("3ca01e"), --green
			renderer = "color",
		},
		{
			key = "FATIGUE_COL",
			name = "Fatigue Color",
			description = "",
			disabled = false,
			default = util.color.hex("00963c"), --yellow
			renderer = "color",
		},
		{
			key = "FATIGUELAG_COL",
			name = "Fatigue Damage Color",
			description = "Color of recently lost fatigue",
			disabled = false,
			default = util.color.hex("f3ed16"), --yellow
			renderer = "color",
		},
		{
			key = "MAGICKA_COL",
			name = "Magicka Color",
			description = "",
			disabled = false,
			default = util.color.hex("35459f"), --green
			renderer = "color",
		},
		{
			key = "MAGICKALAG_COL",
			name = "Magicka Damage Color",
			description = "Color of recently lost magicka",
			disabled = false,
			default = util.color.hex("5a0f8c"), --green
			renderer = "color",
		},
	}
}




local function updateSettings()
	calculateBarPositions()
	if container then
		container:destroy()
	end
	container = nil
	--makeUI()
end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = MODNAME
}


playerSettings:subscribe(async:callback(updateSettings))
return true