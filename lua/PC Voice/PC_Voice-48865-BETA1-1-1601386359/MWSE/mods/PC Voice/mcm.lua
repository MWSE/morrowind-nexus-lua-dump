local config = require("PC Voice.config")
local template = mwse.mcm.createTemplate("PC Voice")
template:saveOnClose("PC Voice", config)

local page = template:createSideBarPage()
page.label = "Player Character Voice Settings"
page.description =(
	"Auto detect. For vanilla races only. Coming Soon...\n\n" ..
	"Manual configuration:\n\n" ..
	"   Race Selection\n\n" ..
	"   1 = Argonian\n" ..
	"   2 = Breton\n" ..
	"   3 = Dunmer\n" ..
	"   4 = High Elf\n" ..
	"   5 = Imperial\n" ..
	"   6 = Khajiit\n" ..
	"   7 = Nord\n" ..
	"   8 = Orc\n" ..
	"   9 = Redguard\n" ..
	"   10 = Wood Elf\n\n" ..
	"   Player sex\n" ..
	"   Turn on if you want to talk with female voice\n\n" ..
	"Delay\n" ..
	"Timer that prevents talking too much\n\n" ..
	"Personality Threshold\n" ..
	"Level at which player personality attribute changes voice lines"
)

page.noScroll = false

local category = page:createCategory("Settings")

	category:createOnOffButton({
	label = "Auto Detect",
	description = "Coming Soon (TM)",
	variable = mwse.mcm:createTableVariable{id = "helloAuto", table = config},
})

category:createOnOffButton({
	label = "Player is female",
	description = "Turn on if you want to talk with female voice",
	variable = mwse.mcm:createTableVariable{id = "helloFem", table = config},
})

category:createSlider({
	label = "Player Race",
	description = "Choose a race to sound like\n\n" ..
	"1 = Argonian\n" ..
	"2 = Breton\n" ..
	"3 = Dunmer\n" ..
	"4 = High Elf\n" ..
	"5 = Imperial\n" ..
	"6 = Khajii\n" ..
	"7 = Nord\n" ..
	"8 = Orc\n" ..
	"9 = Redguard\n" ..
	"10 = Wood Elf\n",
	min = 1,
	max = 10,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable{id = "helloRace", table = config },
})

	category:createSlider({
	label = "Delay",
	description = "Timer that prevents talking too much",
	min = 1,
	max = 30,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{id = "helloTime", table = config },

})

category:createSlider({
	label = "Personality Threshold",
	description = "Level at which player personality attribute changes voice lines",
	min = 1,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "helloPer", table = config },
})

	--page:createTextField({
	--label = "Player Pitch",
	--description = "pitch, doesn't seem to work :(",
	--numbersOnly = true,
	--variable = mwse.mcm.createTableVariable{id = "helloPitch", table = config },
--})

	--page:createTextField({
	--label = "Player Volume",
	--description = "loudness, does not work :(",
	--numbersOnly = true,
	--variable = mwse.mcm.createTableVariable{id = "helloVol", table = config },
--})

mwse.mcm.register(template)