--[[
	Nudge 'Em
	config.lua

	Default settings and saved configuration loading.

	This file defines the mod's default values, loads the user's saved configuration, and fills in any missing settings after updates.
	
	If making edits to this file, be sure to remove "\Data Files\MWSE\config\NudgeEm.json", first.
]]

local config = {}

config.modName = "Nudge 'Em"
config.configPath = "NudgeEm"

config.defaults = {
	enabled = true,
	nudgeDistance = 128,
	nudgeRange = 100,
	showMessages = false,
	instantNudge = false,
	debugLog = false,
	

	-- NPC Reaction Voice:
	-- -2 = Random
	-- -1 = None
	--  0 = Hello
	--  1 = Idle
	--  2 = Intruder
	--  3 = Thief
	--  4 = Hit
	--  5 = Attack
	--  6 = Flee
	reactionVoice = 6,

	-- Creature Reaction Sound:
	-- -2 = Random
	-- -1 = None
	--  0 = Moan
	--  1 = Roar
	--  2 = Scream
	creatureReactionSound = 0,

	-- Reaction Animation:
	-- false = None
	-- true = Random valid hit animation
	playNpcReactionAnimation = true,
	playCreatureReactionAnimation = true,

	keyCombo = {
		keyCode = tes3.scanCode.n,
		isShiftDown = false,
		isAltDown = false,
		isControlDown = false,
	},
}

config.current = mwse.loadConfig(config.configPath, config.defaults)

for key, value in pairs(config.defaults) do
	if config.current[key] == nil then
		config.current[key] = value
	end
end

if type(config.current.keyCombo) ~= "table" then
	config.current.keyCombo = config.defaults.keyCombo
end

for key, value in pairs(config.defaults.keyCombo) do
	if config.current.keyCombo[key] == nil then
		config.current.keyCombo[key] = value
	end
end

return config