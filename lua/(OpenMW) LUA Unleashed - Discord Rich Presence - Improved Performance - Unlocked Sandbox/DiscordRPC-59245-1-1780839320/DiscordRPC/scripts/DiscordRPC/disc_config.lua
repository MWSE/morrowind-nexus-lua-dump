return {
	-- discord application id
	-- create your own at https://discord.com/developers/applications
	CLIENT_ID = "451539197044719616",

	-- override the displayed "playing X" header
	APP_NAME = "OpenMW",

	-- toggle the race/class/level tooltip (and the optional portrait when mapped below)
	SHOW_CHARACTER_ART = true,

	-- set to "" to drop both image and tooltip for unmapped characters
	DEFAULT_IMAGE = "https://i.imgur.com/VfA0MdJ.jpeg",

	-- character name -> art key registered in the discord application or url
	CHARACTER_IMAGES = {
		-- ["Lyra"]       = "https://example.com/lyra.png",
	},
}
