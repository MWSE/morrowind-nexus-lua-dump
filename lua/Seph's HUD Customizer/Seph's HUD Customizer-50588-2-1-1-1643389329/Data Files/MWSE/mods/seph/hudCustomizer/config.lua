local seph = require("seph")

local config = seph.Config()

config.autoClean = false
config.persistent["mods"] = {}

config.default = {
	deadzone = 16,
	highlight = {
		visible = true,
		color = {r = 0, g = 100, b = 0},
		alpha = 30
	},
	healthBar = {
		visible = true,
		showValues = false,
		width = 80,
		height = 14,
		position = {x = 0, y = 960},
		color = {r = 78, g = 24, b = 12}
	},
	magicBar = {
		visible = true,
		showValues = false,
		width = 80,
		height = 14,
		position = {x = 0, y = 980},
		color = {r = 21, g = 27, b = 62}
	},
	fatigueBar = {
		visible = true,
		showValues = false,
		width = 80,
		height = 14,
		position = {x = 0, y = 1000},
		color = {r = 0, g = 59, b = 24}
	},
	npcHealthBar = {
		visible = true,
		width = 80,
		height = 14,
		position = {x = 500, y = 550}
	},
	equippedWeapon = {
		visible = true,
		position = {x = 55, y = 1000}
	},
	equippedMagic = {
		visible = true,
		position = {x = 81, y = 1000}
	},
	sneakIndicator = {
		visible = true,
		position = {x = 108, y = 994}
	},
	equippedNotification = {
		visible = true,
		position = {x = 0, y = 935}
	},
	activeMagicEffects = {
		visible = true,
		layout = "top_to_bottom",
		position = {x = 1000, y = 1000}
	},
	map = {
		visible = true,
		width = 96,
		height = 96,
		position = {x = 985, y = 1000}
	},
	mapNotification = {
		visible = true,
		position = {x = 500, y = 20}
	},
	menuNotify = {
		visible = true,
		flipped = false,
		position = {x = 500, y = 0}
	},
	menuSwimFillBar = {
		visible = true,
		position = {x = 500, y = 20}
	},
	deleteInvalidModConfigs = true,
	mods = {}
}

config.updates = {
	{
		type = "file",
		fileName = "Seph's HUD Customizer.json",
		saveConfig = true,
		deleteFile = true,
		callback =
			function(self, update)
				self.current = mwse.loadConfig(update.fileName, config.default)
			end
	}
}

function config:cleanMods()
	if config.current.deleteInvalidModConfigs then
		for modElementName, modElementConfig in pairs(self.current.mods) do
			if not modElementConfig.valid then
				self.current.mods[modElementName] = nil
				self.logger:debug(string.format("Cleaned mod '%s'", modElementName))
			end
		end
		self.logger:debug("Cleaned mods")
	end
end

function config:markModsAsInvalid()
	for _, modElementConfig in pairs(self.current.mods) do
		modElementConfig.valid = false
	end
end

function config:onLoaded()
	self:markModsAsInvalid()
end

function config:onSave()
	self:cleanMods()
	self:clean({"mods"})
end

function config:onReset()
	for modElementName, modElementConfig in pairs(self.current.mods) do
		seph.table.copyContents(modElementConfig.defaults, modElementConfig)
	end
end

return config