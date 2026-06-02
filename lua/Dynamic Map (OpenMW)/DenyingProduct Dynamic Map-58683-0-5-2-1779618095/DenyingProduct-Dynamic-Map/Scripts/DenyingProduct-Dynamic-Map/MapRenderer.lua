local ui = require("openmw.ui")
local util = require("openmw.util")
local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require('openmw.core')
local async = require("openmw.async")
local Utilities = require("scripts/DenyingProduct-Dynamic-Map/Utilities")

local MapRenderer = {}

--check which mods you have installed
local SOLSTHEIM_MOVED = core.contentFiles.has("Anthology Solstheim.esm") or
    core.contentFiles.has("Anthology Solstheim.esp") or
    core.contentFiles.has("Solstheim Tomb of The Snow Prince.esm")
local TAMRIEL_REBUILD_ENABLED = core.contentFiles.has("TR_Mainland.esm")
local CYRODIIL_ENABLED = core.contentFiles.has("Cyr_Main.esm")
local SKYRIM_ENABLED= core.contentFiles.has("Sky_Main.esm")


local layerSize = ui.layers[1].size
local screenSize = ui.screenSize()
local scale = screenSize.x / layerSize.x

local curReplacingMap = false

local mapFrameSize = util.vector2(layerSize.x * 0.4, layerSize.y * 0.4)
local buttonFrameSize = util.vector2(layerSize.x * 0.9, layerSize.y * 0.9)
local curFrameSize = mapFrameSize

local mapFramePos = util.vector2(layerSize.x - mapFrameSize.x - 20,20)
local buttonFramePos = util.vector2((layerSize.x - buttonFrameSize.x) / 2,(layerSize.y - buttonFrameSize.y) / 2)
local curFramePos = mapFramePos

local FRAME_CONTROL_SIZE = 32
local minSizeX = 600
local minSizeY = 150

-- data used for UI
local CELL_ICON_SIZE = 4 -- size of  cell Icon
local MAP_ZERO_POSITION = util.vector2(4611, 1410.5) 
local MAP_SCALE = 0.002443
local layer = 0 -- 0=clear 1=fast
local cells = {} -- LOD subset of cells with additional data
local exteriorGroupedCells = {}
local exteriorCells = {}
local interiorCells = {}
local curRenderedCell = {}
local currentCellMode = nil
local MAP_COLUMNS = 6
local MAP_ROWS = 4
local OnlyOpenMapOutside = true
local MaskInstalledMods = true
local lastMinX, lastMinY, lastMaxX, lastMaxY = nil, nil, nil, nil
local selectedCell = nil

--fast travel
local FastTravel = require("scripts/DenyingProduct-Dynamic-Map/FastTravel")
local processedFastTravelSilt = nil
local processedFastTravelBoat = nil
local processedFastTravelGuide = nil
local altFTColor = false

--zoom
local zoom = 2
local zoomIndex = 3
local ZOOM_STEPS = {
    0.25,
    0.5,
    2,
    4,
    8,
    32
}
local curInCityZoom = false

--pan
local mapOffset = util.vector2(0,0)

--Textures
local MapTextures = require("scripts/DenyingProduct-Dynamic-Map/mapTextures")
local baseMapTexture = {}

--player Pos
local playerGamePos = util.vector2(0, 0)

local discoveredCells = {}

local isResizing = false
local isMoving = false
local isFocused = false

local mapUI_A = {
    frame = nil,
        background = nil,
        viewport = nil,
            mapTexture = nil,
            mapTextureSolstheim = nil,
            marker = nil,
            fastTravel = nil,
            player = nil,
            selectedMarker = nil,
        controlFastTravelButtons = nil,
        frameMoveControl = nil,
        frameResizeControl = nil
}

local mapUI_B = {
    frame = nil,
        fastTravelUI = nil,
        selectedMarkerUI = nil,
}



local viewState = {
    minX = 0,
    minY = 0,
    maxX = 0,
    maxY = 0
}
local subTileAmount = 4

----------------------------------------------
-- Cell
----------------------------------------------

local function buildRenderableCells(source)

    local result = {}

    for _, c in ipairs(source) do

        local wx
        local wy

        if c.worldX and c.worldY then
            wx = c.worldX
            wy = c.worldY
        else
            wx, wy = Utilities.gridToWorld( c.x, c.y )
        end

        local gridMapPos = Utilities.getMapPositionFromWorld(MAP_SCALE, MAP_ZERO_POSITION.x, MAP_ZERO_POSITION.y, wx, wy )

        table.insert(
            result,
            {
                name = c.name,
                color = c.color,
                cellType = c.cellType,
                mapX = gridMapPos.x,
                mapY = gridMapPos.y,

                even =
                    c.x
                    and math.floor(c.x) % 2 == 0
                    or false,

                mergeCount =
                    c.mergeCount
                    or 1
            }
        )
    end

    return result
end

local function updateCurrentCells()

    local newMode = nil

    if zoom <= 2 then
        newMode = "grouped"
    elseif zoom < 16 then
        newMode = "exterior"
    else
        newMode = "interior"
    end

    if currentCellMode == newMode then
        return false
    end

    currentCellMode = newMode

    if newMode == "grouped" then
        cells = exteriorGroupedCells

    elseif newMode == "exterior" then
        cells = exteriorCells

    else
        cells = interiorCells
    end

    return true
end

local function buildCells(config) 
    cells = {}
    exteriorCells = {}
    exteriorGroupedCells = {}
    interiorCells = {}
    currentCellMode = nil
    local grouped = {}
    for _, cell in ipairs(config.exteriorCells) do
        table.insert(
            exteriorCells,
            {
                name = cell.name,
                x = cell.x,
                y = cell.y
            }
        )
        local groupName =
            cell.name:match("^(.-),")
            or cell.name:match("^(.-)%s+[Nn]orth$")
            or cell.name:match("^(.-)%s+[Ss]outh$")
            or cell.name:match("^(.-)%s+[Ee]ast$")
            or cell.name:match("^(.-)%s+[Ww]est$")
            or cell.name
        if not grouped[groupName] then
            grouped[groupName] = {
                name = groupName,
                sumX = 0,
                sumY = 0,
                count = 0
            }
        end
        local g = grouped[groupName]
        g.sumX = g.sumX + cell.x
        g.sumY = g.sumY + cell.y
        g.count = g.count + 1
    end
    for _, g in pairs(grouped) do
        table.insert(
            exteriorGroupedCells,
            {
                name = g.name,
                x = g.sumX / g.count,
                y = g.sumY / g.count,
                mergeCount = g.count
            }
        )
    end
    for _, cell in ipairs(config.interiorCells) do
        table.insert(
            interiorCells,
            {
                name = cell.name,
                color = cell.color,
                cellType = cell.cellType,

                worldX = cell.doorX,
                worldY = cell.doorY
            }
        )
    end
    exteriorCells = buildRenderableCells(exteriorCells)
    exteriorGroupedCells = buildRenderableCells(exteriorGroupedCells)
    interiorCells = buildRenderableCells(interiorCells)
    updateCurrentCells()
end

----------------------------------------------
-- Build Map
----------------------------------------------


local function getVisibleTileBounds()
    
    local tileSize = 1024 * zoom

    local left   = -mapOffset.x
    local top    = -mapOffset.y
    local right  = curFrameSize.x - mapOffset.x
    local bottom = curFrameSize.y - mapOffset.y

    --round down to nearest quarter tile
    
    local minX = math.floor((left / tileSize) * subTileAmount) / subTileAmount
    local minY = math.floor((top / tileSize) * subTileAmount) / subTileAmount
    local maxX = math.ceil((right / tileSize) * subTileAmount) / subTileAmount
    local maxY = math.ceil((bottom / tileSize) * subTileAmount) / subTileAmount

    return minX, minY, maxX, maxY
end

local function updateViewBounds()
    viewState.minX, viewState.minY, viewState.maxX, viewState.maxY = getVisibleTileBounds()
end

local function backgroundLayer()
    return {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/background.dds" },
            relativeSize = util.vector2(1, 1),
            position = util.vector2(0, 0),
			anchor = util.vector2(0, 0),
		}
	}
end

local function mapTextureLayer()

    local content = {}
    local tileSize = 1024 * zoom

    local minX = math.floor(viewState.minX)
    local minY = math.floor(viewState.minY)
    local maxX = math.floor(viewState.maxX) 
    local maxY = math.floor(viewState.maxY) 

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
    
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(1024 * (MAP_COLUMNS + 1), 1024 * (MAP_ROWS + 1)) * zoom,
            position = mapOffset,
            anchor = util.vector2(0, 0),
        },
        content = ui.content(content)
    }
end

local function mapTextureSolstheim()
    
    local pos = util.vector2(16208,3399) / 4 * zoom
    if (SOLSTHEIM_MOVED) then
        pos = util.vector2(16766,2918) /4 * zoom
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/Solstheim.dds"},
            position = pos + mapOffset,
            size = util.vector2(256,256) * zoom,
            anchor = util.vector2(0,0),
        }
    }
end

local function updateSelectedMarkerUILayer(newSelectedCell)

    --Unless one is provided find closest cell to the center of the frame
    if(newSelectedCell == nil and #curRenderedCell ~= 0) then
        local closestDistance = math.huge
        local centerMapPoint = ((curFrameSize / 2 - mapOffset) )
        for _, cell in ipairs(curRenderedCell) do
            local position = util.vector2(cell.mapX, cell.mapY) * zoom
            local dx = position.x - centerMapPoint.x
            local dy = position.y - centerMapPoint.y
            local distance = (dx * dx) + (dy * dy)
            if distance < closestDistance then
                newSelectedCell = cell
                closestDistance = distance
            end
        end
    end

    -- Only update if new cell. always update position
    if(selectedCell ~= nil) then
        mapUI_B.selectedMarker.props.position =  mapOffset + (util.vector2(selectedCell.mapX, selectedCell.mapY) * zoom)
        mapUI_B.frame:update()
    end
    if(newSelectedCell ~= selectedCell )then

        selectedCell = newSelectedCell
        
        local position = util.vector2(0,0)
        local textColor = util.color.rgb(0.78, 0.65, 0.39)
        local areaName = ""
        local subName = ""
        local size = util.vector2(512, 128) 
        local path = "textures/DenyingProduct-Dynamic-Map/CityLevel/CityLevel.dds"

        if(selectedCell ~= nil) then
            areaName, subName = selectedCell.name:match("^(.-),(.*)$")
            if not subName then subName = selectedCell.name end

            if(selectedCell.color ~= nil) then
                textColor = selectedCell.color
            end

            local cellType = selectedCell.cellType
            if(cellType ~= nil) then
                path = "textures/DenyingProduct-Dynamic-Map/CityLevel/".. cellType .. ".dds"
            end

            position = mapOffset + (util.vector2(selectedCell.mapX, selectedCell.mapY) * zoom)
        end

        -- set selected
        mapUI_B.selectedMarker.props.color = textColor
        mapUI_B.selectedMarker.props.position = position

        -- set UI
        local content = {}
        table.insert(content,{
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = path },
                size = size,
                position = util.vector2(0,0),
                anchor = util.vector2(0, 0),
            }
        })
        table.insert(content,{
            type = ui.TYPE.Text,
            props = {
                position = util.vector2((size.x) / 2,65),
                anchor = util.vector2(0.5, 0),
                text = areaName,
                textSize = 18,
                textColor = textColor,
                textShadow = true,
                autosize = true,
            }
        })
        table.insert(content,{
            type = ui.TYPE.Text,
            props = {
                position = util.vector2((size.x) / 2,90),
                anchor = util.vector2(0.5, 0),
                text = subName,
                textSize = 24,
                textColor = textColor,
                textShadow = true,
                autosize = true,
            }
        })
        mapUI_B.selectedMarkerUI.content = ui.content(content)
        mapUI_B.frame:update()
    end
end

local function selectedMarkerUILayer()

    local content = {}

    local size = util.vector2(512, 128)
    if(not curInCityZoom) then
        size = util.vector2(0, 0)
    end

    return {        
        props = {
            size = size,
            position = util.vector2(0,curFrameSize.y - 4),
            anchor = util.vector2(0, 1),
        },
        events = {
            focusGain = async:callback(function() isFocused = true end),
            focusLoss = async:callback(function() isFocused = false end)
        },
        content = ui.content(content)
    }
end

local function selectedMarkerLayer()

    return {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(0, 0),
            position = util.vector2(0, 0),
            anchor = util.vector2(0.5, 0.5),
            resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/POI.dds"},
        }
    }
end

local function markerLayer()
    local content = {}
    curRenderedCell = {}

    local rendered = 0
    local culled = 0
    local iconSize = CELL_ICON_SIZE * zoom

    for _, cell in ipairs(cells) do
        local position = util.vector2(cell.mapX, cell.mapY) * zoom
        local textsize = Utilities.getTextSize(cell.mergeCount, zoom)
        if textsize * zoom > 9 then
            local markerColor = util.color.rgb(0.77,.65,0.39)
            if curInCityZoom then
                iconSize = CELL_ICON_SIZE * 5
                markerColor = util.color.rgb(.8,.8,.8)
            end
            if(cell.color ~= nil) then
                markerColor = cell.color
            end
            local textHeight = math.floor(textsize * zoom)
            local padding = math.max(iconSize, textHeight * 2)


            local tileSize = 1024 

            local tx = cell.mapX / tileSize
            local ty = cell.mapY / tileSize

            if tx >= viewState.minX  and tx <= viewState.maxX  and ty >= viewState.minY  and ty <= viewState.maxY then

                rendered = rendered + 1
                local markerObj ={
                    type = ui.TYPE.Image,
                    props = {
                        position = position,
                        size = util.vector2(iconSize, iconSize),
                        anchor = util.vector2(0.5, 0.5),
                        color = markerColor,
                        resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/POI.dds"},
                    },
                    events = {
                        focusGain = async:callback(function() 
                            if(curInCityZoom) then
                                updateSelectedMarkerUILayer(cell)
                            end
                        end)
                    }
                }

                table.insert(curRenderedCell,cell)
                table.insert(content,markerObj)
                --(145862.921875, 46262.28125)
                --Balmora, Guild of Mages
                if not curInCityZoom then
                    local textColor = util.color.rgb(0.78, 0.65, 0.39)
                    if cell.even then
                        local changeAmount = 0.15

                        textColor = util.color.rgb(
                            textColor.r + changeAmount,
                            textColor.g + changeAmount,
                            textColor.b + changeAmount
                        )
                    end

                    if cell.mergeCount > 3 then
                        local changeAmount = 0.3
                        textColor = util.color.rgb(
                            textColor.r + changeAmount,
                            textColor.g + changeAmount,
                            textColor.b + changeAmount
                        )
                    end

                    table.insert(content,{
                        type = ui.TYPE.Text,
                        props = {
                            position = util.vector2(position.x, position.y - (iconSize / 2)),
                            anchor = util.vector2(0.5, 1),
                            text = Utilities.wrapWords(cell.name, 10),
                            textSize = textHeight,
                            textColor = textColor,
                            textShadow = true,
                            autosize = true,
                            multiline = true,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        }
                    })
                end
            else
                culled = culled + 1
            end
        end
    end
    
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(1024 * (MAP_COLUMNS + 1), 1024 * (MAP_ROWS + 1)) * zoom,
            position = mapOffset,
            anchor = util.vector2(0, 0),
        },
        content = ui.content(content)
    }
end

local function fastTravelLayer()
    local content = {}

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

    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(1024 * (MAP_COLUMNS + 1), 1024 * (MAP_ROWS + 1)) * zoom,
            position = mapOffset,
            anchor = util.vector2(0, 0),
        },
        content = ui.content(content)
    }
end

local function playerLayer()
    if(self.cell.isExterior) then
        playerGamePos = self.position
    end
    local playerMapPos = Utilities.getMapPositionFromWorld(MAP_SCALE, MAP_ZERO_POSITION.x, MAP_ZERO_POSITION.y,playerGamePos.x, playerGamePos.y) 
    local yawDeg = math.deg(self.rotation:getYaw())
    if yawDeg < 0 then yawDeg = yawDeg + 360 end
    local playerRotationArrowNumber = math.floor((yawDeg / 45) + 0.5) % 8
        
    return {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = "textures/DenyingProduct-Dynamic-Map/playerArrow/arrow-" .. playerRotationArrowNumber .. ".dds" },
            size = util.vector2(50,50),
            position = (util.vector2(playerMapPos.x, playerMapPos.y) * zoom) + mapOffset,
            anchor = util.vector2(0.5,0.5),
        }
    }
end

local function FastTravelUILayer()
    
    local path = "textures/DenyingProduct-Dynamic-Map/NoRoutes.dds"

    if layer == 1 then
        path = "textures/DenyingProduct-Dynamic-Map/LandRoutes.dds"
    elseif layer == 2 then
        path = "textures/DenyingProduct-Dynamic-Map/WaterRoutes.dds"
    elseif layer == 3 then
        path = "textures/DenyingProduct-Dynamic-Map/GuideRoutes.dds"
    end

    local size = util.vector2(512, 128)
    if(curInCityZoom) then
        size = util.vector2(0, 0)
    end

    return {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = path },
            size = size,
            position = util.vector2(0,curFrameSize.y - 4),
            anchor = util.vector2(0, 1),
        },
        events = {
            focusGain = async:callback(function() isFocused = true end),
            focusLoss = async:callback(function() isFocused = false end)
        }
    }
end

local function viewportLayer(content)
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(
                curFrameSize.x,
                curFrameSize.y
            ),
            position = util.vector2(0, 0),
            anchor = util.vector2(0, 0),
        },
        content = content
    }
end

local function updateFastTravelUILayer()

    --update map itself
    if(not curInCityZoom) then
        mapUI_A.fastTravel = fastTravelLayer() 
        mapUI_A.viewport.content = ui.content({
            mapUI_A.mapTexture,
            mapUI_A.mapTextureSolstheim,
            mapUI_A.fastTravel,
            mapUI_A.marker,
            mapUI_A.player
        })
        mapUI_A.frame:update()
    end

    --update the UI
    local path = "textures/DenyingProduct-Dynamic-Map/NoRoutes.dds"
    if layer == 1 then
        path = "textures/DenyingProduct-Dynamic-Map/LandRoutes.dds"
    elseif layer == 2 then
        path = "textures/DenyingProduct-Dynamic-Map/WaterRoutes.dds"
    elseif layer == 3 then
        path = "textures/DenyingProduct-Dynamic-Map/GuideRoutes.dds"
    end
    mapUI_B.fastTravelUI.props.resource = ui.texture { path = path }

    local size = util.vector2(512, 128)
    if(curInCityZoom) then
        size = util.vector2(0, 0)
    end
    mapUI_B.fastTravelUI.props.size = size

    mapUI_B.frame:update()
end

local function controlFastTravelButtonsLayer()
    local buttonSize = util.vector2(93, 55)
    local buttonPos1 = util.vector2(0, 0)
    local buttonPos2 = util.vector2(buttonPos1.x + 93, 0)
    local buttonPos3 = util.vector2(buttonPos2.x + 93, 0)
    local buttonPos4 = util.vector2(buttonPos3.x + 93, 0)
    
    return {
        type = ui.TYPE.Widget,
        --template = I.MWUI.templates.bordersThick,
        props = {
            size = util.vector2(buttonPos4.x + buttonSize.x, buttonSize.y),
            position = util.vector2(90, curFrameSize.y - buttonSize.y),
            anchor = util.vector2(0, 0),
        },
        content = ui.content({
            {
                --template = I.MWUI.templates.bordersThick,
                props = {
                    size = buttonSize,
                    position = buttonPos1,
                    anchor = util.vector2(0, 0),
                },
                events = {
                    mousePress = async:callback(function()
                        layer = 0
                        updateFastTravelUILayer()
                    end)
                }
            },
            {
                --template = I.MWUI.templates.bordersThick,
                props = {
                    size = buttonSize,
                    position = buttonPos2,
                    anchor = util.vector2(0, 0),
                },
                events = {
                    mousePress = async:callback(function()
                        layer = 1
                        updateFastTravelUILayer()
                    end)
                }
            },
            {
                --template = I.MWUI.templates.bordersThick,
                props = {
                    size = buttonSize,
                    position = buttonPos3,
                    anchor = util.vector2(0, 0),
                },
                events = {
                    mousePress = async:callback(function()
                        layer = 2
                        updateFastTravelUILayer()
                    end)
                }
            },
            {
                --template = I.MWUI.templates.bordersThick,
                props = {
                    size = buttonSize,
                    position = buttonPos4,
                    anchor = util.vector2(0, 0),
                },
                events = {
                    mousePress = async:callback(function()
                        layer = 3
                        updateFastTravelUILayer()
                    end)
                }
            }
        })
    }
end

local function frameResizeControlLayer()
    return {
        type = ui.TYPE.Widget,
        --template = I.MWUI.templates.bordersThick,
        props = {
            size = util.vector2(FRAME_CONTROL_SIZE, curFrameSize.y),
            position = util.vector2(curFrameSize.x - FRAME_CONTROL_SIZE, 0),
            anchor = util.vector2(0, 0),
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1,1),
                    relativePosition = util.vector2(1, 1),
                    anchor = util.vector2(1, 1),
                    pointer = "dresize",
                },
                events = {
                    mousePress = async:callback(function()
                        isResizing = true
                    end),

                    mouseRelease = async:callback(function()
                        isResizing = false
                    end)
                }
            },
        })
    }
end

local function frameMoveControlLayer()
    return {
        type = ui.TYPE.Widget,
        --template = I.MWUI.templates.bordersThick,
        props = {
            size = util.vector2(curFrameSize.x,FRAME_CONTROL_SIZE * 1.5),
            position = util.vector2(0,0),
            anchor = util.vector2(0, 0),
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1,1),
                    relativePosition = util.vector2(1, 1),
                    anchor = util.vector2(1, 1),
                    pointer = "move",
                },
                events = {
                    mousePress = async:callback(function()
                        isMoving = true
                    end),

                    mouseRelease = async:callback(function()
                        isMoving = false
                    end)
                }
            },
        })
    }
end

local function frameLayer(content,layer)
   
    if(layer == "DP_DM_A") then
        return ui.create({
            layer = layer,
            template = I.MWUI.templates.bordersThick,
            props = {
                size = curFrameSize,
                position = curFramePos,
                anchor = util.vector2(0, 0),
            },
            content = content,
            events = {
                focusGain = async:callback(function()
                    isFocused = true
                end),

                focusLoss = async:callback(function()
                    isFocused = false
                end)
            }
        })
    end

    if(layer == "DP_DM_B_NotInteractive") then
        return ui.create({
            layer = layer,
            template = I.MWUI.templates.bordersThick,
            props = {
                size = curFrameSize,
                position = curFramePos,
                anchor = util.vector2(0, 0),
            },
            content = content,
            events = {
                focusGain = async:callback(function()
                    isFocused = true
                end),

                focusLoss = async:callback(function()
                    isFocused = false
                end)
            }
        })
    end


end

function MapRenderer.showMap(centerOnPlayer,curReplacingMap)

    if mapUI_A.frame then
        return
    end
    
    if(OnlyOpenMapOutside and not self.cell.isExterior) then return end

    if(curReplacingMap) then 
        curFrameSize = mapFrameSize
        curFramePos = mapFramePos
    else
        curFrameSize = buttonFrameSize
        curFramePos = buttonFramePos
    end

    --update incase the player resized the game
	layerSize = ui.layers[1].size
    screenSize = ui.screenSize()
    
    --center on player if true
    if(self.cell.isExterior) then
        playerGamePos = self.position
    end
    if(centerOnPlayer) then
        local playerMapPos = Utilities.getMapPositionFromWorld(MAP_SCALE, MAP_ZERO_POSITION.x, MAP_ZERO_POSITION.y,playerGamePos.x, playerGamePos.y) 
        mapOffset = util.vector2(
            curFrameSize.x / 2 - (playerMapPos.x * zoom),
            curFrameSize.y / 2 - (playerMapPos.y * zoom)
        )
    end

    updateViewBounds()

	mapUI_A.background = backgroundLayer()
    mapUI_A.mapTexture = mapTextureLayer()
    mapUI_A.mapTextureSolstheim = mapTextureSolstheim()
    mapUI_A.marker = markerLayer()
    mapUI_A.player = playerLayer()
    mapUI_A.fastTravel = fastTravelLayer()
    mapUI_B.selectedMarkerUI = selectedMarkerUILayer()
    mapUI_B.selectedMarker = selectedMarkerLayer()
    local viewportContent = ui.content({
        mapUI_A.mapTexture,
        mapUI_A.mapTextureSolstheim,
        mapUI_A.fastTravel,
        mapUI_A.marker,
        mapUI_A.player
    })
    mapUI_A.viewport = viewportLayer(viewportContent)
    mapUI_B.fastTravelUI = FastTravelUILayer()
    mapUI_A.controlFastTravelButtons = controlFastTravelButtonsLayer()
    mapUI_A.frameResizeControl = frameResizeControlLayer()
    mapUI_A.frameMoveControl = frameMoveControlLayer()

    mapUI_A.frame = frameLayer(ui.content({
        mapUI_A.background,
        mapUI_A.viewport,
        mapUI_A.frameResizeControl,
        mapUI_A.frameMoveControl,
        mapUI_A.controlFastTravelButtons,
    }),"DP_DM_A")

    mapUI_B.frame = frameLayer(ui.content({
        mapUI_B.fastTravelUI,
        mapUI_B.selectedMarker,
        mapUI_B.selectedMarkerUI,
    }),"DP_DM_B_NotInteractive")

    -- if zooemd in, select a cell
    if(curInCityZoom) then 
        mapUI_B.selectedMarker.props.size = util.vector2(CELL_ICON_SIZE * 5 * 2, CELL_ICON_SIZE * 5 * 2) 
        mapUI_B.selectedMarkerUI.props.size = util.vector2(512, 128)
        updateSelectedMarkerUILayer() 
    end
end

function MapRenderer.hideMap(curReplacingMap)

    if(curReplacingMap) then 
        mapFrameSize = curFrameSize
        mapFramePos = curFramePos
    else
        buttonFrameSize = curFrameSize
        buttonFramePos = curFramePos
    end


    if mapUI_A.frame then
        mapUI_A.frame:destroy()
        mapUI_B.frame:destroy()
        mapUI_A = {
            frame = nil,
                background = nil,
                viewport = nil,
                    mapTexture = nil,
                    mapTextureSolstheim = nil,
                    marker = nil,
                    fastTravel = nil,
                    player = nil,
                    selectedMarker = nil,
        }

        mapUI_B = {
            frame = nil,
                selectedMarkerUI = nil,
                controlFastTravelButtons = nil,
                frameMoveControl = nil,
                frameResizeControl = nil
        }
        FastTravelUI = nil
        selectedCell = nil
    end
end

-- used when player presses their selected key. not used when opening with built in UI so overriding interfaces
function MapRenderer.toggleMap(centerOnPlayer,curReplacingMap)
    if mapUI_A.frame then
        I.UI.setMode(I.UI.MODE.Interface, { windows = {I.UI.WINDOW.Map, I.UI.WINDOW.Inventory, I.UI.WINDOW.Stats, I.UI.WINDOW.Magic} })
		I.UI.removeMode(I.UI.MODE.Interface)
		I.GamepadControls.setGamepadCursorActive(true)
        MapRenderer.hideMap(curReplacingMap)
    else
        I.UI.setMode("Interface", { windows = {} })
        I.GamepadControls.setGamepadCursorActive(false)
        MapRenderer.showMap(centerOnPlayer,curReplacingMap)
    end
end


----------------------------------------------
-- Misc
----------------------------------------------

function MapRenderer.initialize(config)

    --build layers
    if( ui.layers.indexOf("DP_DM_A") == nil ) then
        ui.layers.insertAfter('Windows', 'DP_DM_A', { interactive = true })
    end
    if( ui.layers.indexOf("DP_DM_B_NotInteractive") == nil ) then
        ui.layers.insertAfter('DP_DM_A', 'DP_DM_B_NotInteractive', { interactive = false })
    end

    --saved data
    if config.mapFrameSize ~= nil then mapFrameSize = config.mapFrameSize end
    if config.buttonFrameSize ~= nil then buttonFrameSize = config.buttonFrameSize end
    if config.mapFramePos ~= nil then mapFramePos = config.mapFramePos end
    if config.buttonFramePos ~= nil then buttonFramePos = config.buttonFramePos end
    if config.playerGamePos ~= nil then playerGamePos = config.playerGamePos end

    --build exteriorCells exteriorGroupedCells and interiorCells
    buildCells(config) 

    --get Fast Travel Data
    processedFastTravelSilt, processedFastTravelBoat, processedFastTravelGuide =  FastTravel.buildFastTravel(exteriorCells,TAMRIEL_REBUILD_ENABLED,CYRODIIL_ENABLED,SKYRIM_ENABLED)
end

function MapRenderer.applySettings(config)

    OnlyOpenMapOutside = config.onlyOpenMapOutside

    MaskInstalledMods = config.maskInstalledMods

    altFTColor = config.altFTColor

    baseMapTexture =
        MapTextures.build(
            MAP_ROWS,
            MAP_COLUMNS,
            MaskInstalledMods,
            TAMRIEL_REBUILD_ENABLED,
            CYRODIIL_ENABLED,
            SKYRIM_ENABLED
        )
end

function MapRenderer.getState()
    return {
        buttonFrameSize = buttonFrameSize,
        mapFrameSize = mapFrameSize,
        buttonFramePos = buttonFramePos,
        mapFramePos = mapFramePos,
        playerGamePos = playerGamePos,
    }
end

function MapRenderer.isMapOpen()
     if mapUI_A.frame then
        return true
     else
        return false
     end
end

function MapRenderer.canControl()
    return mapUI_A.frame
        and isFocused
        and not isMoving
        and not isResizing
end

function MapRenderer.isResizing()
    return isResizing
end

function MapRenderer.resize(dx,dy)
    curFrameSize = util.vector2(
        math.max(minSizeX, curFrameSize.x + (dx / scale)),
        math.max(minSizeY, curFrameSize.y + (dy / scale))
    )

    --update size of windows
    mapUI_A.frame.layout.props.size = curFrameSize
    mapUI_A.background.props.size = curFrameSize
    mapUI_B.frame.layout.props.size = curFrameSize
    mapUI_A.viewport.props.size = curFrameSize

    mapUI_B.fastTravelUI.props.position = util.vector2(0,curFrameSize.y - 4)
    mapUI_B.selectedMarkerUI.props.position = util.vector2(0, curFrameSize.y - 4)
    mapUI_A.controlFastTravelButtons.props.position = util.vector2(90, curFrameSize.y - 55)

    mapUI_A.frameResizeControl.props.size = util.vector2(FRAME_CONTROL_SIZE, curFrameSize.y)
    mapUI_A.frameResizeControl.props.position = util.vector2(curFrameSize.x - FRAME_CONTROL_SIZE, 0)
    
    mapUI_A.frameMoveControl.props.size = util.vector2(curFrameSize.x,FRAME_CONTROL_SIZE * 1.5)

    --update map content if you have too (culling)
    mapUI_A.frame:update()
    mapUI_B.frame:update()
end

function MapRenderer.isMoving()
    return isMoving
end

function MapRenderer.move(dx,dy)
    curFramePos = util.vector2(
        curFramePos.x + (dx / scale),
        curFramePos.y + (dy / scale)
    )
    local minX = 0
    local minY = 0
    local maxX = layerSize.x - curFrameSize.x
    local maxY = layerSize.y - curFrameSize.y

    curFramePos = util.vector2(
        Utilities.clamp(curFramePos.x, minX, maxX),
        Utilities.clamp(curFramePos.y, minY, maxY)
    )

    
    mapUI_B.fastTravelUI.props.position = util.vector2(0,curFrameSize.y - 4)
    mapUI_A.frame.layout.props.position = curFramePos
    mapUI_B.frame.layout.props.position = curFramePos
    mapUI_A.frame:update()
    mapUI_B.frame:update()
end

function MapRenderer.pan(panAmount)
    if(not MapRenderer.isMapOpen()) then return end
    
    mapOffset = util.vector2( mapOffset.x + panAmount.x, mapOffset.y + panAmount.y )

    mapOffset = Utilities.clampMapOffset(MAP_COLUMNS, MAP_ROWS, zoom, curFrameSize, mapOffset)
    updateViewBounds()
    mapUI_A.mapTexture.props.position = mapOffset
    mapUI_A.fastTravel.props.position = mapOffset
    mapUI_A.marker.props.position = mapOffset
    mapUI_A.player.props.position = playerLayer().props.position
   
    mapUI_A.mapTextureSolstheim.props.position =
        (
            SOLSTHEIM_MOVED
            and util.vector2(16766,2918) / 4
            or util.vector2(16208,3399) / 4
        ) * zoom + mapOffset

    -- only refresh if panned into new cell
    local minX, minY, maxX, maxY = getVisibleTileBounds()
    if not (minX == lastMinX and minY == lastMinY and maxX == lastMaxX and maxY == lastMaxY) then
        lastMinX, lastMinY, lastMaxX, lastMaxY = minX, minY, maxX, maxY
        updateCurrentCells()
        mapUI_A.mapTexture = mapTextureLayer()
        mapUI_A.mapTextureSolstheim = mapTextureSolstheim()
        mapUI_A.fastTravel = fastTravelLayer()
        mapUI_A.marker = markerLayer()
        mapUI_A.player = playerLayer()
    end
    if(curInCityZoom) then 
        updateSelectedMarkerUILayer() 
    end
    mapUI_A.viewport.content = ui.content({
        mapUI_A.mapTexture,
        mapUI_A.mapTextureSolstheim,
        mapUI_A.fastTravel,
        mapUI_A.marker,
        mapUI_A.player
    })
    mapUI_A.frame:update()
end

function MapRenderer.zoom(zoomIn)
    if(not MapRenderer.isMapOpen()) then return end
    
    local centerScreen = curFrameSize / 2
    local centerMapPoint = (centerScreen - mapOffset) / zoom
    if(zoomIn)then
        zoomIndex = math.min( zoomIndex + 1, #ZOOM_STEPS )
    else
        zoomIndex = math.max( zoomIndex - 1, 1 )
    end
    zoom = ZOOM_STEPS[zoomIndex]
    mapOffset = centerScreen - centerMapPoint * zoom
    mapOffset = Utilities.clampMapOffset(MAP_COLUMNS,MAP_ROWS,zoom,curFrameSize,mapOffset)
    if (zoom > 16 ) then 
        curInCityZoom = true
        layer = 0 
        mapUI_B.selectedMarker.props.size = util.vector2(CELL_ICON_SIZE * 5 * 2, CELL_ICON_SIZE * 5 * 2) 
        mapUI_B.selectedMarkerUI.props.size = util.vector2(512, 128)
    else
        curInCityZoom = false
        mapUI_B.selectedMarker.props.size = util.vector2(0, 0) 
        mapUI_B.selectedMarkerUI.props.size = util.vector2(0, 0) 
        selectedCell = nil
    end
    updateCurrentCells()
    updateViewBounds()
    updateFastTravelUILayer()
    mapUI_A.mapTexture = mapTextureLayer()
    mapUI_A.mapTextureSolstheim = mapTextureSolstheim()
    mapUI_A.fastTravel = fastTravelLayer()
    mapUI_A.marker = markerLayer()
    mapUI_A.player = playerLayer()
    mapUI_A.viewport.content = ui.content({
        mapUI_A.mapTexture,
        mapUI_A.mapTextureSolstheim,
        mapUI_A.fastTravel,
        mapUI_A.marker,
        mapUI_A.player
    })
    mapUI_A.frame:update()
    mapUI_B.frame:update()
    updateSelectedMarkerUILayer() 
end

function MapRenderer.switchFastTravelLayer()
    layer = layer + 1
    if(layer > 3) then layer = 0 end
    updateFastTravelUILayer()
end

return MapRenderer