local core = require("openmw.core")


return {
	eventHandlers = {
		soundSay = function(e) core.sound.say(e.file, e.obj) end,
		soundStopSay = function(e) core.sound.stopSay(e) end
	},
}
