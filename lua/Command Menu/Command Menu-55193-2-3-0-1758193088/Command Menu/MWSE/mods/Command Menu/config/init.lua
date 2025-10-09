local fileName = "Command Menu"

--- @class CommandMenu.config
--- @field version string A [semantic version](https://semver.org/).
--- @field default CommandMenu.config Access to the default config can be useful in the MCM.
--- @field fileName string
local default = {
	logLevel = mwse.logLevel.info,
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

local config = mwse.loadConfig(fileName, default)
config.version = "2.3.0"
config.default = default
config.fileName = fileName

return config
