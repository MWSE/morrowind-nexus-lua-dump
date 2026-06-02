local types = require('openmw.types')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local time = require('openmw_aux.time')


local function onActive()
	anim.playBlended(self, 'ripple', { startkey = 'start', stopkey = 'stop', priority =anim.PRIORITY.Scripted})
end

return {
	eventHandlers = {	},
	engineHandlers = {
		onUpdate=onUpdate,
		onActive=onActive
	}

}