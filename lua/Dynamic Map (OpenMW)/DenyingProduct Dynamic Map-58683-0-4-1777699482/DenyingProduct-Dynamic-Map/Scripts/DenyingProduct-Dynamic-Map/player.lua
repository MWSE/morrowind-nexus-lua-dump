local ui = require("openmw.ui")
local util = require("openmw.util")
local input = require("openmw.input")
local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require('openmw.core')
local storage = require("openmw.storage")
local async = require("openmw.async")
local Utilities = require("scripts/DenyingProduct-Dynamic-Map/Utilities")

--check which mods you have installed
local SOLSTHEIM_MOVED = core.contentFiles.has("Anthology Solstheim.esm") or
    core.contentFiles.has("Anthology Solstheim.esp") or
    core.contentFiles.has("Solstheim Tomb of The Snow Prince.esm")
local TAMRIEL_REBUILD_ENABLED = core.contentFiles.has("TR_Mainland.esm")
local CYRODIIL_ENABLED = core.contentFiles.has("Cyr_Main.esm")
local SKYRIM_ENABLED= core.contentFiles.has("Sky_Main.esm")

--UI Elements
local UIElement_Controls = nil
local UIElement_FastTravel = nil
local UIElements_MainFrame
local UIElements_MainViewPort
local screenSize = ui.layers[1].size
local frameSize = util.vector2(screenSize.x * 0.9, screenSize.y * 0.9)

-- data used for UI
local CELL_ICON_SIZE = 4 -- size of  cell Icon
local MAP_ZERO_POSITION = util.vector2(4611, 1410.5) 
local MAP_SCALE = 0.002443
local layer = 0 -- 0=clear 1=fast
local rawCells = nil -- data received from Game
local cells = {} -- LOD subset of cells with additional data
local curLOD = false;
local MAP_COLUMNS = 6
local MAP_ROWS = 4
local OnlyOpenMapOutside = true
local MaskInstalledMods = true
local lastMinX, lastMinY, lastMaxX, lastMaxY = nil, nil, nil, nil

--fast travel
local FastTravel = require("scripts/DenyingProduct-Dynamic-Map/FastTravel")
local fastTravelNodes = require("scripts/DenyingProduct-Dynamic-Map/fastTravelRoutes")
local processedFastTravelSilt = nil
local processedFastTravelBoat = nil
local processedFastTravelGuide = nil
local altFTColor = false

--zoom
local ZOOM_AMOUNT = 2
local MIN_ZOOM = 0.25
local MAX_ZOOM = 8
local curZoomReset = 0.25
local zoom = 2 -- current zoom level

--pan
local mapOffset = util.vector2(0,0)
local PAN_SPEED = 800

--controller
local DEADZONE = 0.25
local curToolTip = "textures/DenyingProduct-Dynamic-Map/KBM_ToolTip.dds"
local KBM_TOOLTIP = "textures/DenyingProduct-Dynamic-Map/KBM_ToolTip.dds"
local CONTROLLER_TOOLTIP = "textures/DenyingProduct-Dynamic-Map/Controller_ToolTip.dds"

--Textures
local MapTextures = require("scripts/DenyingProduct-Dynamic-Map/mapTextures")
local baseMapTexture = {}

--player Pos
local playerGamePos = util.vector2(0, 0)

local discoveredCells = {}

----------------------------------------------
-- Save and Load
----------------------------------------------
local function onSave()
    return {
        playerGamePos = playerGamePos,
        discoveredCells = discoveredCells,
    }
end
local function onLoad(data)
    if not data then
        return
    end
    playerGamePos = data.playerGamePos or util.vector2(0, 0)
    discoveredCells = data.discoveredCells or {}
end

----------------------------------------------
-- Settings
----------------------------------------------
I.Settings.registerPage{
    key = "DenyingProductDynamicMap",
    l10n = "DenyingProductDynamicMap",
    name = "Dynamic Map",
    description = "DenyingProduct Dynamic Map."
}

I.Settings.registerGroup{
    key = "DenyingProductDynamicMap",
    page = "DenyingProductDynamicMap",
    l10n = "DenyingProductDynamicMap",
    name = "Mod Options",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "OnlyShowDiscoveredMarkers",
            renderer = "checkbox",
            name = "Only Show Discovered Markers (Coming Soon)",
            description = "Only show markers you have visited",
            default = true
        },
        {
            key = "FastTravelMode",
            renderer = "checkbox",
            name = "Only Show Discovered Travel Routes (Coming Soon)",
            description = "Only show paths between markers you have visited",
            default = true
        },
        {
            key = "ReplaceBuiltInMap",
            renderer = "checkbox",
            name = "Replace Built-in Map (Coming Soon)",
            description = "No = Open the map with M or Select\nYes = Replace the built-in map in the default UI with the Dynamic Map",
            default = true
        },
        {
            key = "OnlyOpenMapOutside",
            renderer = "checkbox",
            name = "Only Open Map Outside",
            description = "While indoors the Player position uses last known exterior position",
            default = false
        },
        {
            key = "MaskInstalledMods",
            renderer = "checkbox",
            name = "Mask Installed Mods (Gray out not installed zones)",
            description = "Currently supports the following (April 2026 Versions)\n   *Solstheim Tomb of The Snow Prince\n   *Anthology Solstheim\n   *Tamriel Rebuilt\n   *Project Cyrodiil\n   *Skyrim: Home of the Nords",
            default = true
        },
        {
            key = "altFTColor",
            renderer = "checkbox",
            name = "Use Original Travel Route Colors",
            description = "Use Yellow/Red/Blue instead of the orange for Travel routes. This is like the old versions",
            default = false
        },
        {
            key = "PanSpeed",
            renderer = "number",
            name = "Map Pan Speed",
            description = "How fast to pan.",
            default = PAN_SPEED,
        },
    }
}
local playerSettings = storage.playerSection("DenyingProductDynamicMap")
local function updateSettings()
    PAN_SPEED = playerSettings:get("PanSpeed") or 800
    OnlyOpenMapOutside = playerSettings:get("OnlyOpenMapOutside")
    MaskInstalledMods = playerSettings:get("MaskInstalledMods")
    altFTColor = playerSettings:get("altFTColor")
    baseMapTexture = MapTextures.build(MAP_ROWS,MAP_COLUMNS,MaskInstalledMods,TAMRIEL_REBUILD_ENABLED,CYRODIIL_ENABLED,SKYRIM_ENABLED)
end
updateSettings()
playerSettings:subscribe(async:callback(function(section, key)
	updateSettings()
end))


----------------------------------------------
-- Utilities
----------------------------------------------

local function getVisibleTileBounds()

    local tileSize = 1024 * zoom

    local left   = -mapOffset.x
    local top    = -mapOffset.y
    local right  = frameSize.x - mapOffset.x
    local bottom = frameSize.y - mapOffset.y

    local minX = math.floor(left / tileSize)
    local minY = math.floor(top / tileSize)
    local maxX = math.floor(right / tileSize)
    local maxY = math.floor(bottom / tileSize)

    return
        minX ,
        minY,
        maxX,
        maxY
end

local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end

local function clampMapOffset()
    local mapWidth =  1024 * (MAP_COLUMNS) * zoom
    local mapHeight = 1024 * (MAP_ROWS) * zoom
    local halfFrameX = frameSize.x / 2
    local halfFrameY = frameSize.y / 2
    local minX = halfFrameX - mapWidth
    local minY = halfFrameY - mapHeight
    local maxX = halfFrameX
    local maxY = halfFrameY

    mapOffset = util.vector2(
        clamp(mapOffset.x, minX, maxX),
        clamp(mapOffset.y, minY, maxY)
    )
end

local function getMapPositionFromWorld(x, y)
	return util.vector2(
        MAP_ZERO_POSITION.x + x * MAP_SCALE,
        MAP_ZERO_POSITION.y - y * MAP_SCALE
    )
end

local function gridToWorld(gridX, gridY)
    local cellSize = 8192
    local cellOffset = cellSize / 2 -- to center of cell
    return gridX * cellSize + cellOffset, gridY * cellSize + cellOffset
end


----------------------------------------------
-- Update which cells should be shown based on LOD Swap. further filtering in the GUI based on textsize
----------------------------------------------
local function updateCurrentCells()
    if not rawCells then return end

    local lodDistance = 2.5

    -- just return if already in correct LOD
    if zoom >= lodDistance and not curLOD then return end
    if zoom < lodDistance and curLOD then return end

    -- get current cells based on LOD
    local currentCells = {}
    if zoom >= lodDistance then
        -- High detail: use raw list
        currentCells = rawCells
        curLOD = false
    else
        curLOD = true
        -- Low detail: aggregated list
        local groups = {}
        for _, cell in ipairs(rawCells) do
            
            -- Collapse anything before comma
            -- "Vivec, Arena" -> "Vivec"
            local groupName =
            cell.name:match("^(.-),")
            or cell.name:match("^(.-)%s+[Nn]orth$")
            or cell.name:match("^(.-)%s+[Ss]outh$")
            or cell.name:match("^(.-)%s+[Ee]ast$")
            or cell.name:match("^(.-)%s+[Ww]est$")
            or cell.name
            if not groups[groupName] then
                groups[groupName] = {
                    name = groupName,
                    sumX = 0,
                    sumY = 0,
                    count = 0
                }
            end
            local g = groups[groupName]
            g.sumX = g.sumX + cell.x
            g.sumY = g.sumY + cell.y
            g.count = g.count + 1
        end
        for _, g in pairs(groups) do
            table.insert(currentCells, {
                name = g.name,
                x = g.sumX / g.count,
                y = g.sumY / g.count,
                mergeCount = g.count
            })
        end
    end

    cells = {}
    for _, c in ipairs(currentCells) do
        local wx, wy = gridToWorld(c.x, c.y)
        local gridMapPos = getMapPositionFromWorld(wx, wy) 
        table.insert(cells, {
            name = c.name,
            mapX = gridMapPos.x,
            mapY = gridMapPos.y,
            even = math.floor(c.x) % 2 == 0,
            mergeCount = c.mergeCount or 1 
        })
    end
end

----------------------------------------------
-- Update / Build Map
----------------------------------------------

local function drawTabFrame(path,framePos,frameSize)
    if (UIElement_FastTravel) then
        UIElement_FastTravel:destroy()
        UIElement_FastTravel = nil
    end
    UIElement_FastTravel = ui.create({
        layer = "Notification",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture {path = path} ,
            size = util.vector2(512, 512),
            position = util.vector2(framePos.x + 4, framePos.y + frameSize.y - 4),
            anchor = util.vector2(0, 1),
        }
    })
end

local function buildMapMapLayer()
    local content = {}
    
    	-- Map Base
        local tileSize = 1024 * zoom
        local minX, minY, maxX, maxY = getVisibleTileBounds()
        for row = minY, maxY do
            for col = minX, maxX do
                local path = "textures/DenyingProduct-Dynamic-Map/Base_Map/Base_Map-" .. row .. "-" .. col .. ".dds"
                local tex = baseMapTexture[path]
                if tex then
                    table.insert(content, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = tex },
                            size = util.vector2(tileSize, tileSize),
                            position = util.vector2(col * tileSize, row * tileSize),
                            anchor = util.vector2(0, 0),
                        }
                    })
                end
            end
        end

    --divide by 4 because actual texture is 4 times bigger
    local pos = util.vector2(16208,3399) / 4 * zoom
    if (SOLSTHEIM_MOVED) then
        pos = util.vector2(16766,2918) /4 * zoom
    end
    table.insert(content,{
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/Solstheim.dds"},
            position = pos,
            size = util.vector2(256,256) * zoom,
            anchor = util.vector2(0,0),
        }
    })

    if(layer == 1) then -- Silt
        local color = util.color.rgb(0.871, 0.667, 0.388)
        if(altFTColor) then color = util.color.rgb(1, 1, 0) end
        FastTravel.draw(content, zoom, processedFastTravelSilt,color)
    elseif(layer == 2) then -- Boat
        local color = util.color.rgb(0.871, 0.667, 0.388)
        if(altFTColor) then color = util.color.rgb(0, 0, 1) end
        FastTravel.draw(content, zoom, processedFastTravelBoat,color)
    elseif(layer == 3) then -- Guide
        local color = util.color.rgb(0.871, 0.667, 0.388)
        if(altFTColor) then color = util.color.rgb(1, 0, 0) end
        FastTravel.draw(content, zoom, processedFastTravelGuide,color)
    end

    -- Markers
    for _, cell in ipairs(cells) do
        
        local position = (util.vector2(cell.mapX, cell.mapY) * zoom)
        local textColor = util.color.rgb(0.78, 0.65, 0.39)
        if(cell.even) then
            local changeAmount = 0.15
            textColor = util.color.rgb(textColor.r + changeAmount, textColor.g + changeAmount, textColor.b + changeAmount)
        end
        if(cell.mergeCount > 3) then
            local changeAmount = 0.3
            textColor = util.color.rgb(textColor.r + changeAmount, textColor.g + changeAmount, textColor.b + changeAmount)
        end
        local textsize = Utilities.getTextSize(cell.mergeCount,zoom)

        --only show if textsize relation to zoom is appropriate 
        if(textsize * zoom > 9) then
            table.insert(content,{
                type = ui.TYPE.Image,
                props = {
                    position = position,
                    size = util.vector2(CELL_ICON_SIZE * zoom, CELL_ICON_SIZE * zoom),
                    anchor = util.vector2(0.5, 0.5),
                    resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/POI.dds"},
                }
            })
            table.insert(content,{
                type = ui.TYPE.Text,
                props = {
                    position = util.vector2(position.x, position.y - (CELL_ICON_SIZE * zoom / 2)),
                    anchor = util.vector2(0.5, 1),
                    text = Utilities.wrapWords(cell.name, 10),
                    --text = cell.name,
                    textSize = textsize * zoom,
                    textColor = textColor,
                    textShadow = true,
                    autosize = true,
                    multiline = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                }
            })
        end
    end

	--Player
    if(self.cell.isExterior) then
        playerGamePos = self.position
    end
    local playerMapPos = getMapPositionFromWorld(playerGamePos.x, playerGamePos.y) 
    local yawDeg = math.deg(self.rotation:getYaw())
    if yawDeg < 0 then yawDeg = yawDeg + 360 end
    local playerRotationArrowNumber = math.floor((yawDeg / 45) + 0.5) % 8
    
    table.insert(content,{
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/playerArrow/arrow-" .. playerRotationArrowNumber .. ".dds" },
            size = util.vector2(50,50),
            position = (util.vector2(playerMapPos.x, playerMapPos.y) * zoom),
            anchor = util.vector2(0.5,0.5),
        }
    })
    return content

end

local function buildMap(centerOnPlayer)

	screenSize = ui.layers[1].size
	frameSize = util.vector2(screenSize.x * 0.9, screenSize.y * 0.9)

    --center on player
    if(self.cell.isExterior) then
        playerGamePos = self.position
    end
    if(centerOnPlayer) then
        local playerMapPos = getMapPositionFromWorld(playerGamePos.x, playerGamePos.y) 
        mapOffset = util.vector2(
            frameSize.x / 2 - (playerMapPos.x * zoom),
            frameSize.y / 2 - (playerMapPos.y * zoom)
        )
    end

	--background
	local UIElement_background = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/background.dds" },
            relativeSize = util.vector2(1, 1),
            position = util.vector2(0, 0),
			anchor = util.vector2(0, 0),
		}
	}
    
    -- viewport
    UIElements_MainViewPort = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(1024 * (MAP_COLUMNS + 1), 1024 * (MAP_ROWS + 1)) * zoom,
            position = mapOffset,
            anchor = util.vector2(0, 0),
        },
        content = ui.content(buildMapMapLayer())
    }
    
    --frame
    local framePos = util.vector2((screenSize.x - frameSize.x) / 2,(screenSize.y - frameSize.y) / 2)
    UIElements_MainFrame = ui.create({
        layer = "Windows",
        template = I.MWUI.templates.bordersThick,
        props = {
            size = frameSize,
            position = framePos,
            anchor = util.vector2(0, 0),
        },
        content = ui.content({
            UIElement_background,
            UIElements_MainViewPort
        })
    })

	-- Controls Overlay
    -- Rendered seperate because if rendered in Frame the text gets rendered over it. I think this is an OpenMW Bug
    if (UIElement_Controls == nil) then
        UIElement_Controls = ui.create({
            layer = "Notification",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture {path = curToolTip} ,
                size = util.vector2(512, 512),
                position = util.vector2(framePos.x + 4, framePos.y + frameSize.y - 4),
                anchor = util.vector2(0, 1),
            }
        })
    end

    if(layer == 1) then -- Silt
        drawTabFrame("textures/DenyingProduct-Dynamic-Map/LandRoutes.dds",framePos,frameSize)
    elseif(layer == 2) then -- Boat
        drawTabFrame("textures/DenyingProduct-Dynamic-Map/WaterRoutes.dds",framePos,frameSize)
    elseif(layer == 3) then -- Guide
        drawTabFrame("textures/DenyingProduct-Dynamic-Map/GuideRoutes.dds",framePos,frameSize)
    else -- None
        drawTabFrame("textures/DenyingProduct-Dynamic-Map/NoRoutes.dds",framePos,frameSize)
    end
end

----------------------------------------------
-- Show Hide Map
----------------------------------------------

local function showMap(centerOnPlayer)
    
    I.UI.setMode("Interface", { windows = {} })
    I.GamepadControls.setGamepadCursorActive(false)
    if not UIElements_MainFrame then
        buildMap(centerOnPlayer)
    end
end

local function hideMap()
	if UIElements_MainFrame then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {I.UI.WINDOW.Map, I.UI.WINDOW.Inventory, I.UI.WINDOW.Stats, I.UI.WINDOW.Magic} })
		I.UI.removeMode(I.UI.MODE.Interface)
		I.GamepadControls.setGamepadCursorActive(true)
        if(UIElements_MainFrame) then
            UIElements_MainFrame:destroy()
            UIElements_MainFrame = nil
        end
        if (UIElement_Controls) then
            UIElement_Controls:destroy()
            UIElement_Controls = nil
        end
        if (UIElement_FastTravel) then
            UIElement_FastTravel:destroy()
            UIElement_FastTravel = nil
        end
    end
end

local function toggleMap()
	if UIElements_MainFrame then 
		hideMap() 
	else 
        if(not OnlyOpenMapOutside or self.cell.isExterior) then
		    showMap(true) 
        end
	end
end

----------------------------------------------
-- Pan And Zoom
----------------------------------------------

--rebuild when switching tiles
local function panMap(dt)
    if not UIElements_MainViewPort or not UIElements_MainFrame then return end

	local changeMade = false
	local moveAmount = PAN_SPEED * dt  -- consistent across framerates
    
    -- Keyboard
	if input.isKeyPressed(input.KEY.A) or input.isKeyPressed(input.KEY.LeftArrow) then mapOffset = util.vector2(mapOffset.x + moveAmount , mapOffset.y);changeMade=true end
	if input.isKeyPressed(input.KEY.D) or input.isKeyPressed(input.KEY.RightArrow) then mapOffset = util.vector2(mapOffset.x - moveAmount , mapOffset.y);changeMade=true end
	if input.isKeyPressed(input.KEY.W) or input.isKeyPressed(input.KEY.UpArrow) then mapOffset = util.vector2(mapOffset.x, mapOffset.y + moveAmount );changeMade=true end
	if input.isKeyPressed(input.KEY.S) or input.isKeyPressed(input.KEY.DownArrow) then mapOffset = util.vector2(mapOffset.x, mapOffset.y - moveAmount );changeMade=true end

    -- Mouse drag
    if input.isMouseButtonPressed(1) then
        local dx = input.getMouseMoveX()
        local dy = input.getMouseMoveY()
        if dx ~= 0 or dy ~= 0 then
            mapOffset = util.vector2(mapOffset.x + dx,mapOffset.y + dy);changeMade = true
        end
    end

	-- Controller DPad
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadLeft) then mapOffset = util.vector2(mapOffset.x + moveAmount , mapOffset.y);changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadRight) then mapOffset = util.vector2(mapOffset.x - moveAmount , mapOffset.y);changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then mapOffset = util.vector2(mapOffset.x, mapOffset.y + moveAmount );changeMade=true end
	if input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then mapOffset = util.vector2(mapOffset.x, mapOffset.y - moveAmount );changeMade=true end

	-- Controller analog
	local axisX = input.getAxisValue(input.CONTROLLER_AXIS.LeftX)
	local axisY = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
	if math.abs(axisX) > DEADZONE then mapOffset = util.vector2(mapOffset.x - axisX * moveAmount , mapOffset.y);changeMade=true end
	if math.abs(axisY) > DEADZONE then mapOffset = util.vector2(mapOffset.x, mapOffset.y - axisY * moveAmount );changeMade=true end

    if changeMade then
        clampMapOffset()

        UIElements_MainViewPort.props.position = mapOffset

        local minX, minY, maxX, maxY = getVisibleTileBounds()

        if minX ~= lastMinX or minY ~= lastMinY
        or maxX ~= lastMaxX or maxY ~= lastMaxY then

            lastMinX, lastMinY, lastMaxX, lastMaxY = minX, minY, maxX, maxY

            UIElements_MainViewPort.content = ui.content(buildMapMapLayer())
        end

        UIElements_MainFrame:update()
    end
	
end

local function zoomMap(dt, zoomControl)
    if not UIElements_MainViewPort or not UIElements_MainFrame then return end

    --only allow zoom every 0.25s to prevent spam
     if(curZoomReset < 0.2)then
        curZoomReset = curZoomReset + dt
    else
        local axisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
        if zoom > MIN_ZOOM and (axisY > DEADZONE or zoomControl < 0) then
            curZoomReset = 0
            local centerScreen = frameSize / 2
            local centerMapPoint = (centerScreen - mapOffset) / zoom
            zoom = clamp(zoom / ZOOM_AMOUNT, MIN_ZOOM, MAX_ZOOM)
            mapOffset = centerScreen - centerMapPoint * zoom
            clampMapOffset()
            hideMap()
            updateCurrentCells()
            showMap(false)
        elseif zoom < MAX_ZOOM and (axisY < -DEADZONE or zoomControl > 0) then
            curZoomReset = 0
            local centerScreen = frameSize / 2
            local centerMapPoint = (centerScreen - mapOffset) / zoom
            zoom = clamp(zoom * ZOOM_AMOUNT, MIN_ZOOM, MAX_ZOOM)
            mapOffset = centerScreen - centerMapPoint * zoom
            clampMapOffset()
            hideMap()
            updateCurrentCells()
            showMap(false)
        end
    end
end

local function onUpdate()
    local dt = core.getRealFrameDuration()
	panMap(dt)
    zoomMap(dt,0)
end

----------------------------------------------
-- Controls - more in Zoom and Pan
----------------------------------------------

local function onKeyPress(key)
    if key.code==input.KEY.M then
		curToolTip = KBM_TOOLTIP
        toggleMap()
    elseif key.code==input.KEY.T or key.code==input.KEY.J or key.code==input.KEY.Escape then
        hideMap()
	elseif key.code==input.KEY.E then
		if UIElements_MainFrame then
			layer = layer + 1 
			if layer > 3 then layer = 0 end
            hideMap()
            showMap(false)
		end
	elseif key.code==input.KEY.H then
        hideMap()
    elseif key.code==input.KEY.Minus or key.code==input.KEY.NP_Minus then
        zoomMap(0,-1)
    elseif key.code==input.KEY.Equals or key.code==input.KEY.NP_Plus then
        zoomMap(0,1)
    end
end

local function onMouseWheel(vertical, horizontal)
	local dt = core.getRealFrameDuration()
	zoomMap(dt,vertical)
end

local function onMouseButtonPress(button)
    if(button ~= 1) then
        hideMap()
    end
end

local function onControllerButtonPress(id)

	if id == input.CONTROLLER_BUTTON.Back then
		curToolTip = CONTROLLER_TOOLTIP
        toggleMap()
	elseif id == input.CONTROLLER_BUTTON.Y then	
		if UIElements_MainFrame then
			layer = layer + 1 
			if layer > 3 then layer = 0 end
            hideMap()
            showMap(false)
		end
    elseif id == input.CONTROLLER_BUTTON.B
        or id == input.CONTROLLER_BUTTON.RightShoulder
        or id == input.CONTROLLER_BUTTON.LeftShoulder
        or id == input.CONTROLLER_BUTTON.Start then
			hideMap()
    end
end

--get data from Global Script
local function fromGlobal(data)
    rawCells = data.value

    updateCurrentCells()

    local siltNodes = fastTravelNodes.silt_vanilla
    local boatNodes = fastTravelNodes.boat_vanilla
    local guideNodes = fastTravelNodes.guide_vanilla
    if(TAMRIEL_REBUILD_ENABLED) then
         siltNodes = FastTravel.mergeNodes(siltNodes, fastTravelNodes.silt_tr)
         boatNodes = FastTravel.mergeNodes(boatNodes, fastTravelNodes.boat_tr)
         guideNodes = FastTravel.mergeNodes(guideNodes, fastTravelNodes.guide_tr)
    end 
    if(CYRODIIL_ENABLED) then
         siltNodes = FastTravel.mergeNodes(siltNodes, fastTravelNodes.silt_pc)
         boatNodes = FastTravel.mergeNodes(boatNodes, fastTravelNodes.boat_pc)
         guideNodes = FastTravel.mergeNodes(guideNodes, fastTravelNodes.guide_pc)
    end     
    if(SKYRIM_ENABLED) then
         siltNodes = FastTravel.mergeNodes(siltNodes, fastTravelNodes.silt_sky)
         boatNodes = FastTravel.mergeNodes(boatNodes, fastTravelNodes.boat_sky)
         guideNodes = FastTravel.mergeNodes(guideNodes, fastTravelNodes.guide_sky)
    end 

    processedFastTravelSilt = FastTravel.processNodes(rawCells, siltNodes, gridToWorld, getMapPositionFromWorld)
    processedFastTravelBoat = FastTravel.processNodes(rawCells, boatNodes, gridToWorld, getMapPositionFromWorld)
    processedFastTravelGuide = FastTravel.processNodes(rawCells, guideNodes, gridToWorld, getMapPositionFromWorld)

    if UIElements_MainFrame then 
        hideMap()
        showMap(false) 
	end
end
core.sendGlobalEvent('sendPlayerCells', {
    actor = self.object
})

return {
    engineHandlers = {
        onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
        onMouseButtonPress = onMouseButtonPress,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
		onLoad = onLoad,
		onSave = onSave,
    },
    eventHandlers = {
        fromGlobal = fromGlobal
    }
}