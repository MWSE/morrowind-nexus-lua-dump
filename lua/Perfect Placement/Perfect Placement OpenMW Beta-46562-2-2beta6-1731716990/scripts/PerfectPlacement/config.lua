--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local async = require('openmw.async')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')

local options = storage.playerSection('Settings/PerfectPlacement/Options')
local keybinds = storage.playerSection('Settings/PerfectPlacement/Keybinds')
local config = {}

local function updateConfig()
	config.options = options:asTable()
	config.options.snapN = 90 / tonumber(config.options.snapN:sub(5))
    config.options.snapQuantizer = (0.5 / config.options.snapN) * math.pi
	config.keybinds = keybinds:asTable()
end
updateConfig()
options:subscribe(async:callback(updateConfig))
keybinds:subscribe(async:callback(updateConfig))

return config