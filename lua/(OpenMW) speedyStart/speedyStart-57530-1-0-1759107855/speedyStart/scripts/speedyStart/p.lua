local ui = require('openmw.ui')
local util = require('openmw.util')
core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local v2 = util.vector2
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
self = require('openmw.self')
types = require("openmw.types")
async = require('openmw.async')

local sleepMode = "Hours" -- Hours or untilRested
MODNAME = "speedyStart"

settingsSection = storage.playerSection('Settings'..MODNAME)
require('scripts.SpeedyStart.settings')


local function update()
	if types.Player.isCharGenFinished(self) then
		core.sendGlobalEvent("speedyStartSetSimulationTimeScale", 1)
		stopTimerFn()
	end
end

local function onLoad()
	if not types.Player.isCharGenFinished(self) and ENABLED then
		stopTimerFn = time.runRepeatedly(update, 60 * time.second, {
			type = time.GameTime,  -- Uses game time (pauses with game)
			initialDelay = 0
		})
		core.sendGlobalEvent("speedyStartSetSimulationTimeScale", SCALE)
	end
end
return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
	},
	eventHandlers = {
	}
}