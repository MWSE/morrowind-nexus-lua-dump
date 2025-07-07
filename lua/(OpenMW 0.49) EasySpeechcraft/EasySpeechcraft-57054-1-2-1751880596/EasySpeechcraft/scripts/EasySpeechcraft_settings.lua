local async = require('openmw.async')

settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = "EasySpeechcraft",
    name = "EasySpeechcraft",
	description = "",
    permanentStorage = true,
    settings = {
		
		{
			key = "enabled",
			name = "Enabled",
			description = "mod enabled?",
			renderer = "checkbox",
			default = true
		},
		{
			key = "Bribe10exp",
			name = "Bribe 10 exp",
			description = "mercantile exp for bribing 10",
			renderer = "number",
			default = 0.8,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "Bribe100exp",
			name = "Bribe 100 exp",
			description = "mercantile exp for bribing 100",
			renderer = "number",
			default = 8,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "Bribe1000exp",
			name = "Bribe 1000 exp",
			description = "mercantile exp for bribing 1000",
			renderer = "number",
			default = 80,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "DispoFlatterModifier",
			name = "Flatter disposition modifier",
			description = "increase minimum disposition for making a compliment",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "Dispo10modifier",
			name = "Bribe 10 disposition modifier",
			description = "increase minimum disposition for bribing 10",
			renderer = "number",
			default = 2.2,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "Dispo100modifier",
			name = "Bribe 100 disposition modifier",
			description ="increase minimum disposition for bribing 100",
			renderer = "number",
			default = 22,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "Dispo1000modifier",
			name = "Bribe 1000 disposition modifier",
			description = "increase minimum disposition for bribing 1000",
			renderer = "number",
			default = 100,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		
		{
			key = "SpeechcraftDispoMult",
			name = "Speechcraft Disposition mult",
			description = "Multiplier on your speechcraft skill to increase min disposition",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "MercantileDispoMult",
			name = "Mercantile Disposition mult",
			description = "Multiplier on your mercantile skill to increase min disposition",
			renderer = "number",
			default = 0.3,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		
		{
			key = "PersonalityDispoMult",
			name = "Personality Disposition mult",
			description = "Multiplier on your personality attribute to increase min disposition",
			renderer = "number",
			default = 0.3,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		
		{
			key = "LuckDispoMult",
			name = "Luck Disposition mult",
			description = "Multiplier on your luck attribute to increase min disposition",
			renderer = "number",
			default = 0.15,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		
	}
		
}




local function updateSettings()

end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = MODNAME,
    l10n = "EasySpeechcraft",
    name = "EasySpeechcraft",
    description = ""
}


playerSection:subscribe(async:callback(updateSettings))
return true