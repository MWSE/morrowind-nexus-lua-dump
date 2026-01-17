local ui = require("openmw.ui")
local util = require("openmw.util")
local input = require("openmw.input")
local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require('openmw.core')

--global
local mapElement
local mapZeroPosition = util.vector2(11269, 2819)
local mapScale = 0.004886
local screenSize = ui.layers[1].size
local frameSize = util.vector2(screenSize.x * 0.9, screenSize.y * 0.9)
local layer = 0 -- 0=fast 1=all
		
--zoom
local zoom = 1
local zoomSpeed = 3
local minZoom = 0.2
local maxZoom = 1.5

--pan
local mapOffset = util.vector2(0,0)
local panSpeed = 1000

--controller
local deadzone = 0.25
local toolTip = "textures/DenyingProduct/Controller_ToolTip.dds" -- DDS BC3 / DXT5

-- Utilities
local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end

local function getMapPositionFromWorld(x, y)
	return util.vector2(
        mapZeroPosition.x + x * mapScale,
        mapZeroPosition.y - y * mapScale
    )
end

local function hideMap()
	if mapElement then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {I.UI.WINDOW.Map, I.UI.WINDOW.Inventory, I.UI.WINDOW.Stats, I.UI.WINDOW.Magic} })
		I.UI.removeMode(I.UI.MODE.Interface)
		I.GamepadControls.setGamepadCursorActive(true)
        mapElement:destroy()
        mapElement = nil
    end
end

local function showMap(centerOnPlayer)

	if mapElement then
        mapElement:destroy()
        mapElement = nil
    end
	
	screenSize = ui.layers[1].size
	frameSize = util.vector2(screenSize.x * 0.9, screenSize.y * 0.9)
    local framePos = util.vector2((screenSize.x - frameSize.x) / 2,(screenSize.y - frameSize.y) / 2)
	
    I.UI.setMode("Interface", { windows = {} })
    I.GamepadControls.setGamepadCursorActive(false)

	local content = {}
	
	--center on player
	local playerGamePos = self.position
	local playerMapPos = getMapPositionFromWorld(playerGamePos.x, playerGamePos.y) 
	if centerOnPlayer then
		mapOffset = util.vector2(
			frameSize.x / 2 - (playerMapPos.x * zoom),
			frameSize.y / 2 - (playerMapPos.y * zoom)
		)
	end
	-- Clamp to map bounds
	local mapWidth = 4096 * 4 * zoom  -- 4 tiles horizontally
	local mapHeight = 4096 * 2 * zoom -- 2 tiles vertically	
	mapOffset = util.vector2(
		clamp(mapOffset.x, frameSize.x - mapWidth, 0),
		clamp(mapOffset.y, frameSize.y - mapHeight, 0)
	)
	
	--background
	local texturePath = "textures/DenyingProduct/background.dds"
	local backgroundImage = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = texturePath },
            size = frameSize,
            position = util.vector2(0, 0),
			anchor = util.vector2(0, 0),
		}
	}
	table.insert(content, backgroundImage)
			
	-- Map Base
	for i = 0, 3 do
		for j = 0, 1 do
			local texturePath = "textures/DenyingProduct/base/Base_Map-" .. i .. "-" .. j .. ".dds"
			local tileSize = math.ceil(4096 * zoom)   -- round up to integer pixels
			local Base_Map = {
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture { path = texturePath },
					size = util.vector2(tileSize, tileSize),
					position = util.vector2(i * tileSize, j * tileSize) + mapOffset,
					anchor = util.vector2(0, 0),
				}
			}
			table.insert(content, Base_Map)
		end
	end
	
	-- Map Fast
	if layer == 0 then
		for i = 0, 3 do
			for j = 0, 1 do
				local texturePath = "textures/DenyingProduct/fast/fast_map-" .. i .. "-" .. j .. ".dds"
				local tileSize = math.ceil(4096 * zoom)   -- round up to integer pixels
				local fast_map = {
					type = ui.TYPE.Image,
					props = {
						resource = ui.texture { path = texturePath },
						size = util.vector2(tileSize, tileSize),
						position = util.vector2(i * tileSize, j * tileSize) + mapOffset,
						anchor = util.vector2(0, 0),
					}
				}
				table.insert(content, fast_map)
			end
		end
		table.insert(content, {
			type = ui.TYPE.Image,
			template = I.MWUI.templates.bordersThick,
			props = {
				resource = ui.texture { path = "textures/DenyingProduct/FastTravel_ToolTip.dds" },
				size = util.vector2(192, 96),
				position = util.vector2(frameSize.x - 192 - 10, frameSize.y - 192 -20),
				anchor = util.vector2(0, 0),
			}
		})
	end
	
	-- Map All
	if layer == 1 then
		for i = 0, 3 do
			for j = 0, 1 do
				local texturePath = "textures/DenyingProduct/all/All_map-" .. i .. "-" .. j .. ".dds"
				local tileSize = math.ceil(4096 * zoom)   -- round up to integer pixels
				local All_map = {
					type = ui.TYPE.Image,
					props = {
						resource = ui.texture { path = texturePath },
						size = util.vector2(tileSize, tileSize),
						position = util.vector2(i * tileSize, j * tileSize) + mapOffset,
						anchor = util.vector2(0, 0),
					}
				}
				table.insert(content, All_map)
			end
		end
	end
	
	--Player
    if self.cell.isExterior then
		local yawDeg = math.deg(self.rotation:getYaw())
		if yawDeg < 0 then yawDeg = yawDeg + 360 end
		local playerRotationArrowNumber = math.floor((yawDeg / 45) + 0.5) % 8
		local playerImage = {
			type = ui.TYPE.Image,
			props = {
				resource = ui.texture { path = "textures/DenyingProduct/playerArrow/arrow-" .. playerRotationArrowNumber .. ".dds" },
				size = util.vector2(50,50),
				position = (util.vector2(playerMapPos.x, playerMapPos.y) * zoom) + mapOffset,
				anchor = util.vector2(0.5,0.5),
			}
		}
		table.insert(content,playerImage)
	end

	-- Controls Overlay
	table.insert(content, {
		type = ui.TYPE.Image,
		template = I.MWUI.templates.bordersThick,
		props = {
			resource = ui.texture {path = toolTip} ,
			size = util.vector2(192, 96),
			position = util.vector2(frameSize.x - 192 - 10, frameSize.y - 96 - 10),
			anchor = util.vector2(0, 0),
		}
	})

    -- viewport
    mapElement = ui.create({
        layer = "Windows",
		template = I.MWUI.templates.bordersThick,
        props = {
            size = frameSize,
            position = framePos,
            anchor = util.vector2(0, 0),
        },
        content = ui.content(content)
	})
end

local function toggleMap()
	if mapElement then 
		hideMap() 
	else 
		showMap(true) 
	end
end

local function panMap(dt)
    if not mapElement then return end

	local changeMade = false
	local moveAmount = panSpeed * dt  -- consistent across framerates

    -- Keyboard
	if input.isKeyPressed(input.KEY.A) or input.isKeyPressed(input.KEY.LeftArrow) then mapOffset = util.vector2(mapOffset.x + moveAmount , mapOffset.y);changeMade=true end
	if input.isKeyPressed(input.KEY.D) or input.isKeyPressed(input.KEY.RightArrow) then mapOffset = util.vector2(mapOffset.x - moveAmount , mapOffset.y);changeMade=true end
	if input.isKeyPressed(input.KEY.W) or input.isKeyPressed(input.KEY.UpArrow) then mapOffset = util.vector2(mapOffset.x, mapOffset.y + moveAmount );changeMade=true end
	if input.isKeyPressed(input.KEY.S) or input.isKeyPressed(input.KEY.DownArrow) then mapOffset = util.vector2(mapOffset.x, mapOffset.y - moveAmount );changeMade=true end

	-- Controller DPad
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadLeft) then mapOffset = util.vector2(mapOffset.x + moveAmount , mapOffset.y);changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadRight) then mapOffset = util.vector2(mapOffset.x - moveAmount , mapOffset.y);changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then mapOffset = util.vector2(mapOffset.x, mapOffset.y + moveAmount );changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then mapOffset = util.vector2(mapOffset.x, mapOffset.y - moveAmount );changeMade=true end

	-- Controller analog
	local axisX = input.getAxisValue(input.CONTROLLER_AXIS.LeftX)
	local axisY = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
	if math.abs(axisX) > deadzone then mapOffset = util.vector2(mapOffset.x - axisX * moveAmount , mapOffset.y);changeMade=true end
	if math.abs(axisY) > deadzone then mapOffset = util.vector2(mapOffset.x, mapOffset.y - axisY * moveAmount );changeMade=true end
	
	if changeMade then
		showMap()
	end
	
end

local function zoomMap(dt,mouseWheel)
    if not mapElement then return end

	local zoomAmount = zoomSpeed * dt  -- consistent across framerates
    local oldZoom = zoom

    -- Controller Right Stick
    local axisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
    if axisY > deadzone then
        zoom = clamp(zoom - zoomAmount, minZoom, maxZoom)
    elseif axisY < -deadzone then
        zoom = clamp(zoom + zoomAmount, minZoom, maxZoom)
	end

    -- Mouse wheel
    if mouseWheel ~= 0 then
        zoom = clamp(zoom + zoomAmount * mouseWheel, minZoom, maxZoom)
    end
	
	if zoom ~= oldZoom then
		local centerMapPoint = (frameSize / 2 - mapOffset) / oldZoom
        mapOffset = frameSize / 2 - centerMapPoint * zoom
		showMap()
	end
end


-- Engine handler
local function onUpdate()
    local dt = core.getRealFrameDuration()
	panMap(dt)
    zoomMap(dt,0)

end

-- Key press handling
local function onKeyPress(key)
    if key.code==input.KEY.M then
		toolTip = "textures/DenyingProduct/KBM_ToolTip.dds"
        toggleMap()
    elseif key.code==input.KEY.T or key.code==input.KEY.J or key.code==input.KEY.Escape then
        hideMap()
	elseif key.code==input.KEY.E then
		if mapElement then
			layer = layer + 1 
			if layer > 1 then layer = 0 end
			showMap(false)
		end
	elseif key.code==input.KEY.H then
        hideMap()
        print("************** DENYING PRODUCT - Mod is On **************")
    end
end

local function onMouseWheel(vertical, horizontal)
	local dt = core.getRealFrameDuration()
	zoomMap(dt,vertical)
end

local function onMouseButtonPress(button)
    hideMap()
end

local function onControllerButtonPress(id)

	if id == input.CONTROLLER_BUTTON.Back then
		toolTip = "textures/DenyingProduct/Controller_ToolTip.dds"
        toggleMap()
	elseif id == input.CONTROLLER_BUTTON.Y then	
		if mapElement then
			layer = layer + 1 
			if layer > 1 then layer = 0 end
			showMap(false)
		end
    elseif id == input.CONTROLLER_BUTTON.B
        or id == input.CONTROLLER_BUTTON.RightShoulder
        or id == input.CONTROLLER_BUTTON.LeftShoulder
        or id == input.CONTROLLER_BUTTON.Start then
			hideMap()
    end
end

return {
    engineHandlers = {
        onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
        onMouseButtonPress = onMouseButtonPress,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
    },
}
