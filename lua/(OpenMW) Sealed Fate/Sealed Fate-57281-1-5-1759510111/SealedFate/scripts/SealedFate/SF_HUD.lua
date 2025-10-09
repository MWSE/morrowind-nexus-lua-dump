ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
async = require('openmw.async')
v2 = util.vector2



local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size


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