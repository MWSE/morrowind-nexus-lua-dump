local defaultConfig = {
	enableMod = false,
	logLevel = "INFO",
	lootNotification = false,
	checkDistance = false,
	distance = 500,
	weigthValueRatio = 0,
	enableTimer = false,
	enableSteal = false,
	enableHiddenSteal = true,
	useLOSdetection = false,
	keepOwner = true,
	enableBounty = true,
	lootItems = false,
	ignoreLock = false,
	ignoreEncumberance = false,
	timer = 3000,
	hotkey = {
		keyCode = 35,
		isShiftDown = false,
		isAltDown = true,
		isControlDown = false
	},
	npcs = {
		lootBodies = false,
		useWhitelist = false,
		useBlacklist = true,
		whitelist = {},
		blacklist = {}
	},
	containers = {
		lootContainers = false,
		useWhitelist = false,
		useBlacklist = true,
		whitelist = {},
		blacklist = {}
	},
	cells = {
		useWhitelist = false,
		useBlacklist = true,
		whitelist = {},
		blacklist = {
			["Indarys Manor"] = true,
			["indarys manor, manor services"] = true,
			["Indarys Manor, Manor Services"] = true,
			["Indarys Manor, Raram's House"] = true,
			["Indarys Manor, Berendas' House"] = true,
			["Tel Uvirith, Seleth's House"] = true,
			["Tel Uvirith, Tower Upper"] = true,
			["Tel Uvirith, Arelas' House"] = true,
			["Tel Uvirith, Omavel's House"] = true,
			["Tel Uvirith, Menas' House"] = true,
			["Tel Uvirith, Tower Lower"] = true,
			["Tel Uvirith, Tower Dungeon"] = true,
			["Rethan Manor"] = true,
			["Rethan Manor, Tures' House"] = true,
			["Rethan Manor, Drelas' House"] = true,
			["Rethan Manor, Berendas' House"] = true,
			["Rethan Manor, Gols' House"] = true,
			["Raven Rock, Factor's Estate"] = true,
		}
	},
	categories = {
		Weapon = {
			type = tes3.objectType.weapon,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Armor = {
			type = tes3.objectType.armor,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Clothing = {
			type = tes3.objectType.clothing,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Ammunition = {
			type = tes3.objectType.ammunition,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Alchemy = {
			type = tes3.objectType.alchemy,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Book = {
			type = tes3.objectType.book,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Ingredient = {
			type = tes3.objectType.ingredient,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {},
			blacklist = {}
		},
		Misc = {
			type = tes3.objectType.miscItem,
			enabled = false,
			useWhitelist = true,
			useBlacklist = false,
			useWeigthValueRatio = false,
			whitelist = {
				["Gold_001"] = true
			},
			blacklist = {}
		}
	}
}

return mwse.loadConfig("autoloot", defaultConfig)