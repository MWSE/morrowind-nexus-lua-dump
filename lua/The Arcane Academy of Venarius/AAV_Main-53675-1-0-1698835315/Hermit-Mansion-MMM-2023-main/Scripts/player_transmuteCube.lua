local ui = require('openmw.ui')
local self = require('openmw.self')
local core = require('openmw.core')
local input = require('openmw.input')
local types = require('openmw.types')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local hadCube = false
local settings = nil

local savedData = storage.playerSection('openmw_transmuteCube')


local function onLoad()
	settings = savedData:asTable()["settings"]

	if settings == nil then
		settings = {}
	end

	hadCube = settings["hadCube"]
end

local function onSave()
	savedData:set("settings", {hadCube = hadCube})
end

local function e_tx_hadCube(data)
	core.sendGlobalEvent("e_rx_hadCube", {player = self, hadCube = hadCube})
end

local function event_openCube(data)
	I.UI.addMode('Container', {target = data.container})
end

local function event_setCubeChest(cubeContainer)
	cubeChest = cubeContainer
end

local function onInputAction(actionId)
	if actionId == input.ACTION.QuickKey9 then
		core.sendGlobalEvent("event_openCube", self)
	end

	if actionId == input.ACTION.QuickKey10 then
		core.sendGlobalEvent("event_transmute", self)
	end

end

return {
	engineHandlers = { 
		onLoad = onLoad, 
		onSave = onSave, 
		onInputAction = onInputAction
	},
	eventHandlers = {
		e_tx_hadCube = e_tx_hadCube,
		event_notify = event_notify,
		event_openCube = event_openCube
	} 
}

