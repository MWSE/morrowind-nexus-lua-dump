local configFile = "Command Menu"

--- @class CommandMenu.modConfigTable
local defaultConfig = {
	--- @type mwseLoggerLogLevel
	logLevel = "TRACE",
	asetting = 300,
	--- @type mwseKeyMouseCombo
	openMenuKey = {
		keyCode = tes3.scanCode.c,
		isShiftDown = false,
		isAltDown = true,
		isControlDown = false,
	},
	--- @type mwseKeyMouseCombo
	sampleLandscapeKey = {
		keyCode = false,
		isShiftDown = false,
		mouseWheel = false,
		mouseButton = false,
		isAltDown = false,
		isControlDown = false
	},
	godMode = false,
	collision = true,
	fov = true,
	aiEnabled = true,
	wireframe = false,
	combatEnabled = true,
	restInterruptEnabled = true,
	unlockEnabled = false,
	stealingFree = false,
	alwaysHit = false,
	castingAlwaysSucceeds = false,
	spellsConsumeNoMagicka = false,
	enchantmentsConsumeNoCharge = false,
	potionBrewingAlwaysSucceeds = false,
	repairingAlwaysSucceeds = false,
	lockPickNotCrime = false,
	lockPickAlwaysSucceeds = false,
	blockDetection = false,
	blockDamageForEssentialActors = false,
	blockSunDamage = false,
	fatiguelessJumping = false,

	filterOutDeprecated = false,
}

local cachedConfig = mwse.loadConfig(configFile, defaultConfig)
local this = {
	version = "2.0.0",
	--- @type CommandMenu.modConfigTable
	config = {},
	default = defaultConfig,
}

setmetatable(this.config, { __index = cachedConfig })

--- Returns a copy of the current config table.
--- This function should only be used in mcm\init.lua
--- @return CommandMenu.modConfigTable
this.getConfig = function()
	return table.copy(cachedConfig)
end

--- Saves the config table to mod's config file.
--- This function should only be used in mcm\init.lua
--- @param mcmConfig CommandMenu.modConfigTable
this.saveConfig = function(mcmConfig)
	table.copy(mcmConfig, cachedConfig)
	mwse.saveConfig(configFile, cachedConfig)
end

return this
