MODNAME = "Banishing"
I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
core = require('openmw.core')
storage = require('openmw.storage')
async = require('openmw.async')
vfs = require('openmw.vfs')

local function unhookObject(object)
	object:removeScript("scripts/Banishing/ban_a.lua")
end

local function deleteObject(object)
	object:remove()
end

local function onObjectActive(object)
	if types.Actor.objectIsInstance(object) then
		object:addScript("scripts/Banishing/ban_a.lua")
	end
end

return {
	engineHandlers = {
		onObjectActive = onObjectActive,
	},
	eventHandlers = {
		Banishing_Unhook = unhookObject,
		Banishing_deleteMe = deleteObject
	},
}
