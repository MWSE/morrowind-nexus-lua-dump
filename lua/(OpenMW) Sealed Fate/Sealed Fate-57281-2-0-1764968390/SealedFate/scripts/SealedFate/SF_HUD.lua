ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
async = require('openmw.async')
v2 = util.vector2
local addTooltip = require("scripts.SealedFate.SF_simpleTooltip")


local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size

local function makeTooltipText()
	if currentDangerLevel == 0 then
		return "Safe"
	end
	
	local lines = {}
	local remaining = currentDangerLevel
	
	table.insert(lines, "")
	-- Extreme Temperatures: 100,000,000
	if remaining >= 100000000 then
		table.insert(lines, "  Extreme Temps!")
		remaining = remaining % 100000000
	end
	
	-- Falling: 10,000,000
	if remaining >= 10000000 then
		table.insert(lines, "  Lethal drop!")
		remaining = remaining % 10000000
	end
	
	-- Underwater: 1,000,000
	if remaining >= 1000000 then
		table.insert(lines, "  Drowning!")
		remaining = remaining % 1000000
	end
	
	-- Sun damage: 100,000
	if remaining >= 100000 then
		table.insert(lines, "  Sun Damage!")
		remaining = remaining % 100000
	end
	
	-- Aggro actors: 1000 each
	local aggroCount = math.floor(remaining / 1000)
	if aggroCount > 0 then
		table.insert(lines, "  Enemies: " .. aggroCount)
		remaining = remaining % 1000
	end
	
	-- Harmful effects: 2 each
	local effectCount = math.floor(remaining / 2)
	if effectCount > 0 then
		table.insert(lines, "  Harmful Effects: " .. effectCount)
	end
	table.insert(lines, "")
	
	return table.concat(lines, "  \n")
end



function createSkull()
	if not saveData.windowPos then
		saveData.windowPos = v2(hudLayerSize.x*0.01, hudLayerSize.y*0.01)
	end
	
	if hudSkull then
		hudSkull:destroy()
	end
	
	saveData.windowPos = v2(math.max(0,math.min(saveData.windowPos.x, hudLayerSize.x-settingsSection:get("SKULL_SIZE"))), math.max(0,math.min(saveData.windowPos.y, hudLayerSize.y-settingsSection:get("SKULL_SIZE"))))

	hudSkull = ui.create({
		type = ui.TYPE.Container,
		layer = 'Modal',
		name = "hudSkull",
		props = {
			anchor = util.vector2(0, 0),
			position = saveData.windowPos,
			alpha = lastDangerousState and 0.9 or 0
		},
		content = ui.content {},
		userData = {
			windowStartPosition =saveData.windowPos,
		}
	})
	
	hudSkull.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				if not elem.userData then
					elem.userData = {}
				end
				elem.userData.isDragging = true
				elem.userData.dragStartPosition = data.position
				elem.userData.windowStartPosition = hudSkull.layout.props.position or v2(0, 0)
			end
		--	topBarBackground.props.alpha = 0.2
			hudSkull:update()
		end),
		
		mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
		--	topBarBackground.props.alpha = 0.1
			hudSkull:update()
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local deltaX = data.position.x - elem.userData.dragStartPosition.x
				local deltaY = data.position.y - elem.userData.dragStartPosition.y
				local newPosition = v2(
					elem.userData.windowStartPosition.x + deltaX,
					elem.userData.windowStartPosition.y + deltaY
				)
				saveData.windowPos = newPosition
				hudSkull.layout.props.position = newPosition
				hudSkull:update()
			end
		end),
	}
	addTooltip(hudSkull, makeTooltipText)
	-- Create the text element
	skullGraphic = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "textures/sealedFate/"..settingsSection:get("SKULL_STYLE")..".png" },
			tileH = false,
			tileV = false,
			size = v2(settingsSection:get("SKULL_SIZE"),settingsSection:get("SKULL_SIZE"))
		},
	}
	hudSkull.layout.content:add(skullGraphic)
end

function onMouseWheel(vertical)
	if hudSkull.layout.userData.isDragging then
		settingsSection:set("SKULL_SIZE", settingsSection:get("SKULL_SIZE") + vertical*2)
		skullGraphic.props.size = v2(settingsSection:get("SKULL_SIZE"),settingsSection:get("SKULL_SIZE"))
		hudSkull:update()
	end
end