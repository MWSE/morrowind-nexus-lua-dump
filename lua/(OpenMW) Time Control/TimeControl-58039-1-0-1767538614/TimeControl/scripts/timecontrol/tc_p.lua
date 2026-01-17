--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Time Control - Main Script                                          │
│  Handles events and input, delegates to UI module                    │
╰──────────────────────────────────────────────────────────────────────╯
]]
MODNAME = "TimeControl"
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
core = require('openmw.core')
async = require('openmw.async')
storage = require('openmw.storage')
types = require('openmw.types')
self = require("openmw.self")
input = require('openmw.input')
camera = require('openmw.camera')
I = require('openmw.interfaces')
G_onFrameJobs = {}

makeBorder = require("scripts.timecontrol.tc_makeBorder")
require("scripts.timecontrol.tc_helpers")
makeButton = require("scripts.timecontrol.tc_makeButton")
require("scripts.timecontrol.tc_settings")

timeControlUI = require("scripts.timecontrol.tc_ui")
messagebox = require("scripts.timecontrol.tc_messagebox")

G_onFrameJobs["messagebox"] = messagebox.onFrame

-- Actions
local Actions = {
	{
		key = "timecontrolToggleUI",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
	{
		key = "timecontrolIncrease",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
	{
		key = "timecontrolDecrease",
		type = input.ACTION_TYPE.Boolean,
		l10n = "none",
		name = "",
		description = "",
		defaultValue = false,
	},
	{
		key = "timecontrolToggleMode",
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

input.registerActionHandler('timecontrolToggleUI', async:callback(function(down)
	if not I.UI.getMode() and core.isWorldPaused() then return end
	if down then timeControlUI.toggle() end
end))

input.registerActionHandler('timecontrolIncrease', async:callback(function(down)
	if down then
		if not I.UI.getMode() and core.isWorldPaused() then return end
		if HOTKEYS_REQUIRE_UI and not timeControlUI.playerWidget then return end
		timeControlUI.increaseScale()
	end
end))

input.registerActionHandler('timecontrolDecrease', async:callback(function(down)
	if down then
		if not I.UI.getMode() and core.isWorldPaused() then return end
		if HOTKEYS_REQUIRE_UI and not timeControlUI.playerWidget then return end
		timeControlUI.decreaseScale()
	end
end))

input.registerActionHandler('timecontrolToggleMode', async:callback(function(down)
	if down then
		if not I.UI.getMode() and core.isWorldPaused() then return end
		if HOTKEYS_REQUIRE_UI and not timeControlUI.playerWidget then return end
		timeControlUI.toggleMode()
	end
end))

if input.triggers and input.triggers["MenuMouseWheelUp"] then
	input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
		timeControlUI.onMouseWheel(1)
	end))
end
if input.triggers and input.triggers["MenuMouseWheelDown"] then
	input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
		timeControlUI.onMouseWheel(-1)
	end))
end

return {
	engineHandlers = {
		onFrame = function(dt)
			for i, job in pairs(G_onFrameJobs) do
				job(dt)
			end
		end,
	}
}
