-- When translating these, please make sure that punctuation, case, and spacing is preserved. --
------------------------------------------------------------------------------------------------
local this = {}

this.messages = {
	audioWarning = "Master and effect channels should be set to max for the mod to work as intended.",
	buildingSoundsStarted = "Running sound object builder.",
	buildingSoundsFinished = "Sound objects builder finished.",
	loadingFile = "Loading file:",
	oldFolderDeleted = "Old mod folder found and deleted.",
	oldFileDeleted = "Old file found and deleted",

	manifestConfirm = "Are you sure you want to remove the manifest file?",
	manifestRemoved = "Manifest file has been removed.",

	initialised = "initialised.",
	mainSettings = "Main Settings",
	mainLabel = "Lua-based sound overhaul.",

	WtS = "Requires Watch the Skies.",

	by = "by",
	settings = "Settings",
	default = "Default",
	volume = "Volume",
	toggle = "Toggle",
	chance = "Chance",
	version = "Version",

	modLanguage = "Mod language.",

	enableDebug = "Enable debug mode?",
	enableOutdoor = "Enable Outdoor Ambient module?",
	enableInterior = "Enable Interior Ambient module?",
	enablePopulated = "Enable Populated Ambient module?",
	enableInteriorWeather = "Enable Interior Weather module?",
	enableServiceVoices = "Enable Service Voices module?",
	enableUI = "Enable UI module?",
	enableContainers = "Enable Containers module?",
	enablePC = "Enable PC module?",
	enableMisc = "Enable Misc module?",

    volumeSave = "Shift + this key will display a menu where you can adjust the volume for the currently playing AURA tracks.",
    undo = "Undo",
    restoreDefaults = "Restore defaults",
    defaultsRestored = "Defaults restored",
    noTracksPlaying = "No tracks playing",
    findOutdoorShelter = "Find outdoor shelter to adjust this volume. [?]",
    findOutdoorShelterTooltip = "Supported shelter statics are: portable\ntents (such as Ashfall modular tents),\noverhangs, awnings and sheds.",
    fadeInProgress = "Fade in progress. Try later.",
    adjustForInterior = "Adjust for interior",
    adjustForExterior = "Adjust for exterior",
    adjustForUnderwater = "Adjust for underwater",
    big = "big",
    small = "small",
    exteriorVolume = "exterior volume",
    underwater = "underwater",
    adjustingAuto = "Adjusting automatically",

	refreshManifest = "Refresh manifest file",

	OA = "Outdoor Ambient",
	OADesc = "Plays ambient sounds in accordance with local climate, weather, player position, and time.",
	OAVol = "Changes % volume for Outdoor Ambient module.",
	playInteriorAmbient = "Enable exterior ambient sounds in interiors? This means the last exterior loop will play on each door and window leading to an exterior.",

	IA = "Interior Ambient",
	IADesc = "Plays ambient sounds in accordance with interior type. Includes taverns, guilds, shops, libraries, tombs, caves, and ruins.",
	IAVol = "Changes % volume for Interior Ambient module.",

	enableTaverns = "Enable culture-specific music in taverns? Note that this works best if you have empty explore/battle folders and use no music mod.",
	tavernsBlacklist = "Taverns blacklist",
	tavernsDesc = "Select which taverns the music is disabled in.",
	tavernsDisabled = "Disabled taverns",
	tavernsEnabled = "Enabled taverns",

	PA = "Populated Ambient",
	PADesc = "Plays ambient sounds in populated areas, like towns and villages.",
	PAVol = "Changes % volume for Populated Ambient module.",

	IW = "Interior Weather",
	IWDesc = "Plays weather sounds in interiors.",
	IWVol = "Changes % volume for Interior Weather module.",

	SV = "Service Voices",
	SVDesc = "Plays appropriate voice comments on service usage.",
	SVVol = "Changes % volume for Service Voices module.",
	enableRepair = "Enable voice comments on repair service?",
	enableSpells = "Enable voice comments on spells vendor service?",
	enableTraining = "Enable voice comments on training service?",
	enableSpellmaking = "Enable voice comments on spellmaking service?",
	enableEnchantment = "Enable voice comments on enchanting service?",
	enableTravel = "Enable voice comments on travel service?",
	enableBarter = "Enable voice comments on barter service?",
	serviceChance = "Changes % chance for a service comment to play.",

	PC = "PC",
	PCDesc = "Plays sounds related to the player character.",
	enableHealth = "Enable low health sounds?",
	enableFatigue = "Enable low fatigue sounds?",
	enableMagicka = "Enable low magicka sounds?",
	enableDisease = "Enable diseased sounds?",
	enableBlight = "Enable blighted sounds?",
	vsVol = "Changes % volume for for vital signs (health, fatigue, magicka, disease, blight).",
	enableTaunts = "Enable player combat taunts?",
	tauntChance = "Changes % chance for a battle taunt to play.",
	tVol = "Changes % volume for player battle taunts.",

	containers = "Containers",
	containersDesc = "Plays container sound on open/close.",
	CVol = "Changes % volume for Containers module.",

	UI = "UI",
	UIDesc = "Additional immersive UI sounds.",
	UITraining = "Enable training menu sounds?",
	UITravel = "Enable travel menu sounds?",
	UISpells = "Enable spell menu sounds?",
	UIBarter = "Enable barter menu sounds?",
	UIEating = "Enable eating sound for ingredients in inventory menu?",
	UIVol = "Changes % volume for UI module.",

	misc = "Misc",
	miscDesc = "Plays various miscellaneous sounds.",
	rainSounds = "Enable variable rain sounds per max particles?",
	rainOnStaticsSounds = "Enable rain sounds on leather/fur/canvas statics outside? Requires variable rain sounds.",
	windSounds = "Enable variable wind sounds per clouds speed?",
	playInteriorWind = "Enable wind sounds in interiors? This means the last exterior loop will play on each door and window leading to an exterior.",
	windVol = "Changes % volume for wind sounds.",
	playSplash = "Enable splash sounds when going underwater and back to surface?",
	splashVol = "Changes % volume for splash sounds.",
	playYurtFlap = "Enable sounds for yurts and pelt entrances?",
	yurtVol = "Changes % volume for yurt and pelt entrances sounds.",
	underwaterRain = "Enable volume scaling of weather effects when underwater?"
}

this.interiorNames = {
	["alc"] = {
		"Alchemist",
		"Apothecary",
		"Tel Uvirith, Omavel's House",
		"Healer",
	},
	["cou"] = {
		"Telvanni Council House",
		"Redoran Council Hall",
		"Manor District",
		"Guildhall",
		"Morag Tong",
		"Arena Hidden Area",
		"Grand Council",
		"Plaza",
		"Waistworks"
	},
	["mag"] = {
		"Mages Guild",
		"Mage's Guild",
		"Guild of Mages"
	},
	["fig"] = {
		"Fighters Guild",
		"Fighter's Guild",
		"Guild of Fighters",
	},
	["tem"] = {
		"Temple",
		"Maar Gan, Shrine",
		"Vos Chapel",
		"High Fane",
		"Fane of the Ancestors",
		"Tiriramannu",
	},
	["lib"] = {
		"Library",
		"Bookseller",
		"Books"
	},
	["smi"] = {
		"Smith",
		"Armorer",
		"Weapons",
		"Armor",
		"Smithy",
		"Weapon",
		"Armors",
		"Blacksmith",
	},
	["tra"] = {
		"Trader",
		"Pawnbroker",
		"Merchandise",
		"Merchant",
		"Goods",
		"Outfitter",
		"Laborers",
		"Brewers",
		"Tradehouse",
		"Hostel",
	},
	["clo"] = {
		"Clothier",
		"Tailors",
	},
	["tom"] = {
		"Tomb",
		"Burial",
		"Crypt",
		"Barrow",
		"Catacomb",
	}
}

this.tavernNames = {
	["dar"] = {
		"Rat in the Pot",
		"House of Earthly Delights",
		"Elven Nations"
	},
	["imp"] = {
		"Ebonheart, Six Fishes",
		"Arrille"
	},
	["nor"] = {
		"Skaal Village, The Greathall",
		"Solstheim, Thirsk"
	}
}

return this
