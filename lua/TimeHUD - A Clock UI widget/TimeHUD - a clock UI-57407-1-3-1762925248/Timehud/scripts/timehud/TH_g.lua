util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
I = require('openmw.interfaces')
--storage = require('openmw.storage')
-- types = require('openmw.types')
-- ambient = require("openmw.ambient")
-- vfs = require('openmw.vfs')
-- debug = require('openmw.debug')
world = require('openmw.world')

local startTime = 427 * time.day * calendar.daysInYear
for i=0, 6 do -- actually 08 but whatever
	startTime = startTime +  time.day * calendar.daysInMonth(i)
end
startTime = startTime + 14*time.day





local function updateTimeOffsets()
	local gameTime = core.getGameTime()
	
	--print("core gametime:",gameTime, calendar.formatGameTime("%d %m %Y", gameTime))
	for _, player in pairs(world.players) do
		local vars = world.mwscript.getGlobalVariables(player)
		local day = vars.day
		local month = vars.month + 1
		local year = vars.year
		local playerDate = calendar.gameTime({day = day, month = month, year = year}) - startTime
		local diff = (playerDate - gameTime) / time.day

		player:sendEvent("timeHud_receiveDayOffset", math.floor(diff))
		
	end
end


stopTimerFn = time.runRepeatedly(updateTimeOffsets, 30.157 * time.second, {
		type = time.SimulationTime,  -- pauses with game
		initialDelay = 0
	})

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
	},
	eventHandlers = {
	}
}