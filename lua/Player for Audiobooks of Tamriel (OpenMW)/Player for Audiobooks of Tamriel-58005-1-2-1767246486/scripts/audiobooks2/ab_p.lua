--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Audiobook Player - Main Script                                      │
│  Handles events and delegates to player module                       │
╰──────────────────────────────────────────────────────────────────────╯
]]
MODNAME = "Audiobooks2"
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
core = require('openmw.core')
async = require('openmw.async')
storage = require('openmw.storage')
types = require('openmw.types')
self = require("openmw.self")
ambient = require("openmw.ambient")
vfs = require('openmw.vfs')
input = require('openmw.input')
G_onFrameJobs = {}
local showedOldPlayerWarning = false


presetColors = {
    "d4edfc", -- thirst
    "bfd4bc", -- hunger
    "cfbddb", -- sleep
    "81cded", -- fav color of blue
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

favColor = util.color.hex("81cded")

makeBorder = require("scripts.audiobooks2.ab_makeBorder")
require("scripts.audiobooks2.ab_helpers")
makeButton = require("scripts.audiobooks2.ab_makeButton")
require("scripts.audiobooks2.ab_settings")

-- Load the database (defines sound_map and durations globals)
local dbLoaded, dbErr = pcall(function() require("scripts.audiobooks2.ab_db") end)
if not dbLoaded then
	print("Audiobook: Failed to load database - " .. tostring(dbErr))
end

sound_map = sound_map or {}
durations = durations or {}

-- Validate audio files
for bookId, audioPath in pairs(sound_map) do
	if not vfs.fileExists("Sound\\" .. audioPath) then
		sound_map[bookId] = nil
	end
end

-- Load the player module
audiobookPlayer = require("scripts.audiobooks2.ab_ui")

-- State
local isReading = false

-- Actions
local Actions = {
	{
		key = "audiobooks2PlayTrigger",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
	{
		key = "audiobooks2StopTrigger",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
	{
		key = "audiobooks2NextTrigger",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
}

for _, action in ipairs(Actions) do
	input.registerAction(action)
end

input.registerActionHandler('audiobooks2PlayTrigger', async:callback(function(down)
	if down then audiobookPlayer.togglePlayPause() end
end))

input.registerActionHandler('audiobooks2StopTrigger', async:callback(function(down)
	if down then audiobookPlayer.stop() end
end))

input.registerActionHandler('audiobooks2NextTrigger', async:callback(function(down)
	if down then audiobookPlayer.playNext() end
end))

if input.triggers["MenuMouseWheelUp"] then
	input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
		audiobookPlayer.onMouseWheel(1)
	end))
end
if input.triggers["MenuMouseWheelDown"] then
	input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
		audiobookPlayer.onMouseWheel(-1)
	end))
end

local function getFileSize(path)
	local f = vfs.open(path)
	if f then
		local size = f:seek("end")
		f:close()
		return size
	else
		return 0
	end
end

local function onLoad()
	if not showedOldPlayerWarning then
		showedOldPlayerWarning = true
		local luaFileSize = getFileSize("scripts/audiobook.lua")
		if luaFileSize and luaFileSize > 0 then
			for _, name in ipairs(core.contentFiles.list) do
				if name:lower():find("audiobook") then
					local size = getFileSize(name)
					if size == 29 then
						ui.showMessage("Pls disable the old audiobook plugin ("..name..")")
						error("Pls disable the old audiobook plugin ("..name..")")
					end
				end
			end
		end
	end
end


return {
	eventHandlers = {
		UiModeChanged = function(data)
			if data.newMode == "Book" or data.newMode == "Scroll" then
				isReading = true
				audiobookPlayer.openBook(data.arg)
			else
				if isReading then
					audiobookPlayer.tryAutoClose()
				end
				isReading = false
			end
		end
	},

	engineHandlers = {
		onFrame = function(dt)
			for i, job in pairs(G_onFrameJobs) do
				job()
			end
		end,
		onSave = function()
			audiobookPlayer.onSave()
			return {}
		end,
		onLoad = onLoad,
		onInit = onLoad,
	}
}