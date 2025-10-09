ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
I = require('openmw.interfaces')
storage = require('openmw.storage')
input = require('openmw.input')
types = require('openmw.types')
self = require("openmw.self")
ambient = require("openmw.ambient")
MODNAME = "Hearthstone"


settingsSection = storage.playerSection('Settings'..MODNAME)
require('scripts.hearthstone.HS_settings')
teleport = require"scripts.hearthstone.HS_castbar"

timeHud = nil
timeText = nil

local stopTimerFn = nil

local function updateHearthstone()
	local newCooldown = math.max(0, 10 - math.floor((calendar.gameTime() - saveData.lastHearthstoneUsage) / time.hour))
	--if saveData.currentCooldown ~= newCooldown then
		core.sendGlobalEvent("hearthstone_setCooldown", {self, newCooldown})
		saveData.currentCooldown = newCooldown
	--end
end


function onLoad(data) -- also onInit
	--if not data then
	--	core.sendGlobalEvent("hearthstone_getBack", self)
	--	types.Player.addTopic(self, "Hearthstone")
	--end
	
	saveData = data or {
		lastHearthstoneUsage = calendar.gameTime() - time.hour*10,
		currentCooldown = 0,
	}
	
	stopTimerFn = time.runRepeatedly(updateHearthstone, 10 * time.second, {
		type = time.RealTime,
		initialDelay = 0
	})
end


function onSave()
	return saveData
end

local function onFrame(dt)
	updateCastProgress(dt)
end

function castSuccessful()
	core.sendGlobalEvent("hearthstone_teleport", {self, saveData.hearthstoneLocation})
	core.sendGlobalEvent("hearthstone_setCooldown", {self, 10})
	saveData.lastHearthstoneUsage = calendar.gameTime()
	saveData.currentCooldown = 10
end

function castFailed()
end


function UiModeChanged(data)
	--print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
	--if data.oldMode == "Interface" then
	--	updateHearthstone()
	--end
	if data.oldMode == "Rest" then
		updateHearthstone()
	end
	if data.oldMode == "Dialogue" then
		local hasDummySpell = false
		for _, spell in pairs(types.Actor.spells(self)) do
			if spell.id == "hearthstone_dummy" then
				hasDummySpell = true
			end
		end
		if hasDummySpell then
			types.Actor.spells(self):remove("hearthstone_dummy")
			--saveData.hearthstoneLocation = { name = self.cell.name, cell = self.cell.id, position = self.position, rotation = self.rotation}
			print("Heartstone set to ", self.cell.name)
			ui.showMessage("Heartstone set to "..tostring(self.cell.name))
			local name = self.cell.name
			if not name or name == "" then
				name = self.cell.region 
				if not name or name == "" then
					name = self.cell.id
				elseif core.regions then
					name = core.regions.records[name].name
				end
			end
			if self.cell.isExterior then
				name = name.." "..self.cell.gridX.."/"..self.cell.gridY
				saveData.hearthstoneLocation = {name = name, gridX = self.cell.gridX, gridY = self.cell.gridY, position = self.position, rotation = self.rotation}
			else
				saveData.hearthstoneLocation = {name = name, cell = self.cell.id, position = self.position, rotation = self.rotation}
			end
		end
		updateHearthstone()
	end
		
end


local function onConsume(item)
	if item.recordId == "hearthstone_0" then
		core.sendGlobalEvent("hearthstone_getBack", self)
		if not types.Player.isTeleportingEnabled(self) then
			ui.showMessage("Can't be used right now")
		elseif saveData.hearthstoneLocation then
			teleport({})
			ui.showMessage("")
			ui.showMessage("")
			ui.showMessage("")
		else
			ui.showMessage("No hearthstone location set")
		end
		for _, spell in pairs(types.Actor.activeSpells(self)) do
			if spell.id == "hearthstone_0" then
				types.Actor.activeSpells(self):remove(spell.activeSpellId)
			end
		end
	end
end

local function messagebox(message)
	ui.showMessage(message)
end

local function refreshInterface()
	--if I.UI.getMode == "Interface" then
	--	I.UI.setMode()
	--	I.Ui
end


return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onConsume = onConsume,
		onFrame = onFrame,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		hearthstone_messagebox = messagebox,
		hearthstone_refreshInterface = refreshInterface
	}
}