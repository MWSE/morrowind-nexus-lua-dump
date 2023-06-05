-- Here we handle event triggers. --

local eventHandler = {}

local constants = require("tew.Happenstance Hodokinesis.constants")
local controller = require("tew.Happenstance Hodokinesis.controller")

function eventHandler.onEquip(e)
	if e.item then
		if e.item.id then
			if (e.reference == tes3.player) and (e.item.id == constants.ALEAPSYCHON_ID) then
				controller.roll()
			end
		end
	end
end

function eventHandler.onKeyDown(e)
	if (e.isShiftDown) then
		for _, stack in pairs(tes3.player.object.inventory) do
			if stack.object.id == constants.ALEAPSYCHON_ID then
				controller.roll()
				break
			end
		end
	end
end


return eventHandler