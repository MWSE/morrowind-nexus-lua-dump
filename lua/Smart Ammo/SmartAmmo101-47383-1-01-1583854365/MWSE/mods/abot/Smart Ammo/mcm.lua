local this = {}

local lib = require('abot.lib')

this.config = {}

function this.onCreate(container)
	local mainPane = lib.createMainPane(container)
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Autoequip arrows?",
		config = this.config,
		key = "autoEquipArrows",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Autoequip bolts?",
		config = this.config,
		key = "autoEquipBolts",
	})
	lib.createBooleanConfig({
		parent = mainPane,
		label = "Autoequip thrown weapons?",
		config = this.config,
		key = "autoEquipThrown",
	})
	lib.createSliderConfig({
		parent = mainPane,
		label = "Ammo auto equip sorting (default 1 = less valuable first)",
		config = this.config,
		key = "autoEquipSort",
		min = 0, max = 4, step = 1, jump = 1,
		info = "0 = no order, 1 = less valuable first, 2 = more available first, 3 = less available first, 4 = more valuable first",
	})
	lib.createSliderConfig({
		parent = mainPane,
		label = "Debug level (default 0 = off)",
		config = this.config,
		key = "debugLevel",
		min = 0, max = 5, step = 1, jump = 1,
		info = "0 = off, 1 = log, 2 = messages, 3 = log + messages, 4 = modal messages, 5 = log + modal messages",
	})
 end

return this
