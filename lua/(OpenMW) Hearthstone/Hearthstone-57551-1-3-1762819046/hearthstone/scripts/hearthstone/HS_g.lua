local util = require('openmw.util')
local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local v2 = util.vector2
local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')

I.ItemUsage.addHandlerForType(types.Ingredient, function(potion, actor)
	if potion.recordId:sub(1,#"hearthstone_") == "hearthstone_" and potion.recordId ~= "hearthstone_0" then
		if potion.recordId == "hearthstone_10" then
			actor:sendEvent("hearthstone_messagebox",  "10 hours Cooldown left")
		else
			actor:sendEvent("hearthstone_messagebox",  potion.recordId:sub(-1,-1).." hours Cooldown left")
		end
		return false
	end
end)

local function teleport(data)
	local player = data[1]
	local loc = data[2]
	if loc.cell then
		player:teleport(loc.cell, loc.position, {rotation = loc.rotation})
	else
		player:teleport(world.getExteriorCell(loc.gridX, loc.gridY), loc.position, {rotation = loc.rotation})
	end
end

local function getBack(player)
	world.createObject("hearthstone_0", 1):moveInto(types.Actor.inventory(player))
end

local function setCooldown(data)
	local player = data[1]
	local cooldown = data[2]
	local hasItem = 0
	local countHearthstones = 0
	for _, item in pairs(types.Actor.inventory(player):getAll(types.Ingredient)) do
		if item.recordId == "hearthstone_"..cooldown then
			hasItem = -1000
			countHearthstones = countHearthstones + 1
		elseif item.recordId:sub(1,#"hearthstone_") == "hearthstone_" then
			hasItem = hasItem + 1
			item:remove()
			countHearthstones = countHearthstones + 1
		end
	end
	if hasItem >= 1 then
		world.createObject("hearthstone_"..cooldown, 1):moveInto(types.Actor.inventory(player))
	end
	if countHearthstones > 1 then
		player:sendEvent("hearthstone_messagebox", "You can only have 1 Hearthstone")
	end
	--player:sendEvent("hearthstone_refreshInterface")
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onMouseWheel = onMouseWheel,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		hearthstone_teleport = teleport,
		hearthstone_getBack = getBack,
		hearthstone_setCooldown = setCooldown,
	}
}