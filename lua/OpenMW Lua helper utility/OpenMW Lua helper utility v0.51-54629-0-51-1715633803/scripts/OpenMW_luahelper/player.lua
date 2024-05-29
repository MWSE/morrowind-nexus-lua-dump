local core = require("openmw.core")
local self = require("openmw.self")

local dialogModes = {
	Barter = true,
	Companion = true,
	Dialogue = true,
	Enchanting = true,
	MerchantRepair = true,
	Travel = true,
	Training = true,
	SpellBuying = true,
	SpellCreation = true,
	Persuasion = true,
		}

local dialogTarget = nil
local dialogNearby = false

local function objectsNearby(k, v)
	local valid = false
	if k.cell.isExterior then valid = (k.position - v.position):length() < 7000
	else valid = k.cell == v.cell end
	return valid
end

local function UiModeChanged(data)
	if dialogModes[data.newMode] and not dialogModes[data.oldMode] and data.arg and dialogTarget ~= data.arg then
		if data.arg ~= nil then
			if objectsNearby(self, data.arg) then dialogNearby = true else dialogNearby = false end
			data["near"], data["player"] = dialogNearby, self
			core.sendGlobalEvent("onDialogOpened", data)
			self:sendEvent("onDialogOpened", data)
			dialogTarget = data.arg
		end
--	elseif dialogModes[data.oldMode] and not dialogModes[data.newMode] and dialogTarget ~= data.arg then
	elseif data.newMode == nil and dialogTarget then
		data["near"] = dialogNearby
		core.sendGlobalEvent("onDialogClosed", data)
		self:sendEvent("onDialogClosed", data)
		dialogTarget = nil
		dialogNearby = false
	end
end

return {
	engineHandlers = { onFrame = function(data)
		if dialogTarget then core.sendGlobalEvent("onFrameOlh", data) end
		end,
--		onTeleported = function() print("player onTeleported triggered") end
	},
	eventHandlers = { UiModeChanged = UiModeChanged },
}
