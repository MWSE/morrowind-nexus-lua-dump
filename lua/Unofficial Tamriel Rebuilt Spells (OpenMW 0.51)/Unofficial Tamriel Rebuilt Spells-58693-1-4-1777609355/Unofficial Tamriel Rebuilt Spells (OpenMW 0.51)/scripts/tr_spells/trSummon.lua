-- actor script to change ai fight value

local self = require('openmw.self')
local types = require('openmw.types')

local function init()
	types.Actor.stats.ai.fight(self).base = 0
end

return {
	engineHandlers = {
		onInit = init,
		onLoad = init,
		onActive = init,
	},
}