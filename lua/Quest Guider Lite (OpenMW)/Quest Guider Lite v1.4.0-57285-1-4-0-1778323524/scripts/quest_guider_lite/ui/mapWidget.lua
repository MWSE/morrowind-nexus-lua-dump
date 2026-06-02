local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local playerRef = require("openmw.self")

local config = require("scripts.quest_guider_lite.configLib")
local commonData = require("scripts.quest_guider_lite.common")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local log = require("scripts.quest_guider_lite.utils.log")

local tooltip = require("scripts.quest_guider_lite.ui.tooltip")

local l10n = core.l10n(commonData.l10nKey)


local mapMarkerTexture = ui.texture{ path = commonData.mapMarkerPath }
local playerMarkerTexture = ui.texture{ path = commonData.playerMapMarkerPath }

local mapTexture


local this = {}


---@class questGuider.ui.mapWidgetMeta
local mapWidgetMeta = {}
mapWidgetMeta.__index = mapWidgetMeta


function mapWidgetMeta:getMapImageWidget()
    return self.layout.content[2]
end

function mapWidgetMeta:getNameLayout()
    return self:getMapImageWidget().content[2]
end

function mapWidgetMeta:getMarkerLayout()
    return self:getMapImageWidget().content[4]
end

function mapWidgetMeta:getPlayerLayout()
    return self:getMapImageWidget().content[3]
end


function mapWidgetMeta:getRelativeCenter()
    return util.vector2(
        (0 - self.mapInfo.gridX.min) / (self.mapInfo.gridX.max - self.mapInfo.gridX.min + 1),
        (0 - self.mapInfo.gridY.min) / (self.mapInfo.gridY.max - self.mapInfo.gridY.min + 1)
    )
end

function mapWidgetMeta:getRelativePositionByWorldPosition(worldPos)
    local center = self:getRelativeCenter()
    local x = worldPos.x / 8192
    local y = worldPos.y / 8192

    return util.vector2(
        center.x + x * self.mapInfo.pixelsPerCell / self.mapInfo.width,
        1 - center.y - y * self.mapInfo.pixelsPerCell / self.mapInfo.height
    )
end


function mapWidgetMeta:getAbsolutePositionByWorldPosition(worldPos, ignoreNorthAngle)
    local cellSize = self.mapInfo.cellSize or 8192
    local cellX = worldPos.x / cellSize
    local cellY = worldPos.y / cellSize
    local x = (cellX - self.mapInfo.gridX.min) * self.mapInfo.pixelsPerCell
    local y = (self.mapInfo.gridY.max - cellY) * self.mapInfo.pixelsPerCell

    local pos = util.vector2(x, y)

    return pos * self.zoom
end


local function clampAndCenterPosition(pos, mapSize, mainSize)
    local newX, newY

    if mapSize.x <= mainSize.x then
        newX = (mainSize.x - mapSize.x) / 2
    else
        newX = util.clamp(pos.x, mainSize.x - mapSize.x, 0)
    end

    if mapSize.y <= mainSize.y then
        newY = (mainSize.y - mapSize.y) / 2
    else
        newY = util.clamp(pos.y, mainSize.y - mapSize.y, 0)
    end

    return util.vector2(newX, newY)
end


---@param zoom number
function mapWidgetMeta:setZoom(zoom)
    local widget = self:getMapImageWidget()

    local oldZoom = self.zoom
    local oldSize = util.vector2(self.mapInfo.width * oldZoom, self.mapInfo.height * oldZoom)

    zoom = util.clamp(zoom, self.minZoom, self.maxZoom)

    local textureVersion = self.mapInfo.version or 0
    if textureVersion == 2 or textureVersion == 3 then
        local tileSize = self.mapInfo.tileSize or (self.mapInfo.pixelsPerCell * 16)
        local newTileSize = math.floor(tileSize * zoom + 0.5)
        zoom = newTileSize / tileSize
    end

    local newSize = util.vector2(self.mapInfo.width * zoom, self.mapInfo.height * zoom)
    local oldPos = widget.props.position

    local mouseOffset = self.layout.userData.mainMouseOffset + self.layout.userData.additiveMouseOffset
    local mouseOnMap = mouseOffset - oldPos

    local rel = util.vector2(mouseOnMap.x / oldSize.x, mouseOnMap.y / oldSize.y)
    local newPos = mouseOffset - util.vector2(newSize.x * rel.x, newSize.y * rel.y)

    local mainSize = self.layout.props.size
    newPos = clampAndCenterPosition(newPos, newSize, mainSize)

    widget.props.size = newSize
    widget.props.position = newPos
    self.zoom = zoom

    self:updateMarkersScale()
end


function mapWidgetMeta:focusOnWorldPosition(worldPos)
    local widget = self:getMapImageWidget()
    local mainSize = self.layout.props.size

    local relPos = self:getRelativePositionByWorldPosition(worldPos)
    local mapSize = widget.props.size
    local newPos = util.vector2(
        mapSize.x * relPos.x - mainSize.x / 2,
        mapSize.y * relPos.y - mainSize.y / 2
    ) * -1

    newPos = clampAndCenterPosition(newPos, widget.props.size, mainSize)

    widget.props.position = newPos
end


local function getCityNameFontSize(size, zoom)
    return size * zoom
end


local function getMarkerSize(size, zoom)
    return size * math.sqrt(math.sqrt(zoom))
end


function mapWidgetMeta:updateMarkersScale()
    local markerLayoutContent = self:getMarkerLayout().content
    local nameLayoutContent = self:getNameLayout().content
    local playerLayoutContent = self:getPlayerLayout().content

    local playerMarkerLayout = playerLayoutContent[1]
    if not playerMarkerLayout then return end

    local playerMarkerFontSize = getMarkerSize(playerMarkerLayout.content[1].userData.size, self.zoom)
    local playerMarkerImageSize = getMarkerSize(playerMarkerLayout.content[2].userData.size, self.zoom)
    playerMarkerLayout.props.size = util.vector2(
        playerMarkerFontSize * stringLib.length(playerMarkerLayout.content[1].userData.name),
        playerMarkerImageSize.y + playerMarkerFontSize
    )

    playerMarkerLayout.content[2].props.size = playerMarkerImageSize
    playerMarkerLayout.content[2].props.position = util.vector2(playerMarkerLayout.props.size.x / 2, playerMarkerFontSize)
    playerMarkerLayout.content[1] = {
        type = ui.TYPE.Text,
        props = {
            text = playerMarkerLayout.content[1].props.text,
            autoSize = true,
            anchor = util.vector2(0.5, 0),
            relativePosition = util.vector2(0.5, 0),
            textColor = config.data.ui.shadowColor,
            textSize = playerMarkerFontSize,
            visible = true,
            alpha = 0.6,
        },
        userData = {
            size = playerMarkerLayout.content[1].userData.size,
            name = playerMarkerLayout.content[1].userData.name,
        },
    }

    for i = 1, #nameLayoutContent do
        local elem = nameLayoutContent[i]
        if not elem then break end

        nameLayoutContent[i] = {
            type = ui.TYPE.Text,
            props = {
                text = elem.props.text,
                autoSize = true,
                anchor = util.vector2(0.5, 0.5),
                relativePosition = elem.props.relativePosition,
                textColor = config.data.ui.defaultColor,
                textSize = getCityNameFontSize(elem.userData.size, self.zoom),
                visible = true,
                alpha = 0.4,
            },
            userData = {
                size = elem.userData.size,
            },
            events = {
                focusLoss = async:callback(function(e, layout)
                    self.layout.userData.inFocus = false
                    self.layout.events.focusLoss(e, layout)
                end),

                mouseMove = async:callback(function(e, layout)
                    self.layout.userData.inFocus = true
                    self.layout.events.mouseMove(e, layout)
                end),

                mousePress = async:callback(function(e, layout)
                    self.layout.events.mousePress(e, layout)
                end),

                mouseRelease = async:callback(function(e, layout)
                    self.layout.events.mouseRelease(e, layout)
                end),
            }
        }
    end

    for i = 1, #markerLayoutContent do
        local elem = markerLayoutContent[i]
        if not elem then break end

        elem.props.size = getMarkerSize(elem.userData.size, self.zoom)
    end
end


function mapWidgetMeta:createMarker(pos, color, events, tooltipContent)
    if not events then events = {} end
    local content = self:getMarkerLayout().content
    local relPos = self:getRelativePositionByWorldPosition(pos)

    local size = util.vector2(24, 24)

    local marker
    marker = {
        type = ui.TYPE.Image,
        props = {
            resource = mapMarkerTexture,
            size = getMarkerSize(size, self.zoom),
            anchor = util.vector2(0.5, 1),
            relativePosition = relPos,
            color = color,
            visible = true,
            alpha = 1,
        },
        userData = {
            size = size,
        },
        events = {
            focusLoss = async:callback(function(e, layout)
                self.layout.userData.inFocus = false
                marker.userData.pressed = false
                if events.focusLoss then events.focusLoss(e, layout) end
                self.layout.events.focusLoss(e, layout, marker)
                tooltip.destroy(layout)
            end),

            mouseMove = async:callback(function(e, layout)
                self.layout.userData.inFocus = true
                self.layout.userData.additiveMouseOffset = e.offset
                if events.mouseMove then events.mouseMove(e, layout) end
                self.layout.events.mouseMove({offset = e.offset, position = e.position}, layout, marker)

                if not tooltipContent then return end
                tooltip.createOrMove(e, layout, tooltipContent)
            end),

            mousePress = async:callback(function(e, layout)
                marker.userData.pressed = true
                if events.mousePress then events.mousePress(e, layout) end
                self.layout.events.mousePress(e, layout, marker)
            end),

            mouseRelease = async:callback(function(e, layout)
                if events.mouseRelease then events.mouseRelease(e, layout, marker.userData.pressed) end
                marker.userData.pressed = false
                self.layout.events.mouseRelease(e, layout, marker)
            end),
        }
    }
    content:add(marker)

    return marker
end


function mapWidgetMeta:createCityNames()
    local content = self:getNameLayout().content

    for _, info in ipairs(this.cityInfo or {}) do

        local fontSize = 10 + math.min(8, info.count) * 2

        local marker
        marker = {
            type = ui.TYPE.Text,
            props = {
                text = info.name,
                autoSize = true,
                anchor = util.vector2(0.5, 0.5),
                relativePosition = self:getRelativePositionByWorldPosition(util.vector2(info.posX, info.posY)),
                textColor = config.data.ui.defaultColor,
                textSize = getCityNameFontSize(fontSize, self.zoom),
                visible = true,
                alpha = 0.4,
            },
            userData = {
                size = fontSize,
            },
            events = {
                focusLoss = async:callback(function(e, layout)
                    self.layout.userData.inFocus = false
                    self.layout.events.focusLoss(e, layout)
                end),

                mouseMove = async:callback(function(e, layout)
                    self.layout.userData.inFocus = true
                    self.layout.events.mouseMove(e, layout)
                end),

                mousePress = async:callback(function(e, layout)
                    self.layout.events.mousePress(e, layout)
                end),

                mouseRelease = async:callback(function(e, layout)
                    self.layout.events.mouseRelease(e, layout)
                end),
            }
        }

        content:add(marker)
    end
end


local function getMapBackgroundColor(self)
    if self.mapInfo and self.mapInfo.bColor then
        local bCol = self.mapInfo.bColor
        return util.color.rgb(bCol[1] or 1, bCol[2] or 1, bCol[3] or 1)
    else
        return commonData.mapWaterColor
    end
end


---@type {name : string, count : integer, posX : number, posY : number}[]?
this.cityInfo = nil


---@class questGuider.ui.mapWidget.params
---@field size any
---@field fontSize integer?
---@field position any?
---@field relativePosition any?
---@field anchor any?
---@field updateFunc function

---@param params questGuider.ui.mapWidget.params
---@return table?
---@return questGuider.ui.mapWidgetMeta?
function this.new(params)
    if not playerDataHandler.data.mapInfo then return end

    local textureVersion = playerDataHandler.data.mapInfo.version or 0

    params.fontSize = params.fontSize or 18

    ---@class questGuider.ui.mapWidgetMeta
    local meta = setmetatable({}, mapWidgetMeta)

    meta.mapInfo = playerDataHandler.data.mapInfo
    meta.params = params
    meta.mapInfo = playerDataHandler.data.mapInfo

    meta.zoom = 1
    meta.maxZoom = math.min(params.size.x / meta.mapInfo.pixelsPerCell, params.size.y / meta.mapInfo.pixelsPerCell) / 2
    meta.minZoom = math.min(params.size.x / meta.mapInfo.width, params.size.y / meta.mapInfo.height)

    meta.update = function(self)
        params.updateFunc()
    end

    meta.displayMapSize = meta.displayMapSize or util.vector2(meta.mapInfo.width, meta.mapInfo.height)

    local mapTextureLayout
    if textureVersion == 1 then
        local mapImagePath = "questData/"..playerDataHandler.data.mapInfo.file

        if not vfs.fileExists(mapImagePath) then return end

        mapTexture = ui.texture{ path = mapImagePath }

        mapTextureLayout = {
            type = ui.TYPE.Image,
            props = {
                resource = mapTexture,
                relativeSize = util.vector2(1, 1),
            }
        }

    elseif textureVersion == 2 or textureVersion == 3 then

        local minGridX = meta.mapInfo.gridX.min
        local maxGridX = meta.mapInfo.gridX.max
        local minGridY = meta.mapInfo.gridY.min
        local maxGridY = meta.mapInfo.gridY.max

        mapTextureLayout = {
            type = ui.TYPE.Widget,
            props = {
                position = util.vector2(0, 0),
                relativeSize = util.vector2(1, 1),
            },
            userData = {},
            content = ui.content{}
        }

        local function getWorldMapTextureV2(x, y)
            local path = "questData/"..string.format("(%d,%d).png", x, y)
            if not vfs.fileExists(path) then return end

            local texture = ui.texture{ path = path }
            return texture
        end

        local mapWidth = (maxGridX - minGridX + 1) * meta.mapInfo.pixelsPerCell
        local mapHeight = (maxGridY - minGridY + 1) * meta.mapInfo.pixelsPerCell

        local tileSize = meta.mapInfo.tileSize or (meta.mapInfo.pixelsPerCell * 16)
        local tileGridSize = tileSize / meta.mapInfo.pixelsPerCell

        local gridTileMinX = math.floor(minGridX / tileGridSize)
        local gridTileMaxX = math.floor(maxGridX / tileGridSize)
        local gridTileMinY = math.floor(minGridY / tileGridSize)
        local gridTileMaxY = math.floor(maxGridY / tileGridSize)

        for tx = gridTileMinX, gridTileMaxX do
            for ty = gridTileMinY, gridTileMaxY do
                local texture = getWorldMapTextureV2(tx, ty)
                if texture then
                    local offPixelsX = (tx * tileGridSize - minGridX) * meta.mapInfo.pixelsPerCell
                    local offPixelsY = (maxGridY - (ty * tileGridSize + tileGridSize - 1)) * meta.mapInfo.pixelsPerCell

                    mapTextureLayout.content:add{
                        type = ui.TYPE.Image,
                        props = {
                            resource = texture,
                            relativePosition = util.vector2(offPixelsX / mapWidth, offPixelsY / mapHeight),
                            relativeSize = util.vector2((tileSize + 1) / mapWidth, (tileSize + 1) / mapHeight),
                            anchor = util.vector2(0, 0)
                        }
                    }
                end
            end
        end
    else
        return
    end


    local main
    main = {
        type = ui.TYPE.Widget,
        props = {
            size = params.size,
            position = params.position,
            relativePosition = params.relativePosition,
            anchor = params.anchor,
        },
        userData = {
            meta = meta,
            onMouseWheel = function(value)
                if not meta.layout.userData.inFocus then return end
                meta:setZoom(value > 0 and meta.zoom * 1.25 or meta.zoom * 0.75)
                meta:update()
            end,

            inFocus = false,
            mainMouseOffset = util.vector2(0, 0),
            additiveMouseOffset = util.vector2(0, 0),
        },
        events = {
            mousePress = async:callback(function(e, layout, markerElement)
                e.marker = markerElement
                if markerElement then
                    e.offset = main.userData.mainMouseOffset + e.offset
                end

                if e.button == 1 then
                    main.userData.lastMousePos = e.position
                end
            end),

            mouseRelease = async:callback(function(e, layout, markerElement)
                if e.button == 1 then
                    main.userData.lastMousePos = nil
                end
            end),

            focusLoss = async:callback(function(_, layout, markerElement)
                main.userData.lastMousePos = nil
                main.userData.inFocus = false
            end),

            mouseMove = async:callback(function(e, layout, markerElement)
                if not markerElement then
                    main.userData.mainMouseOffset = e.offset
                    main.userData.additiveMouseOffset = util.vector2(0, 0)
                end
                main.userData.inFocus = true

                if not main.userData.lastMousePos then return end

                local props = meta:getMapImageWidget().props
                local mainSize = main.props.size
                local mapSize = props.size

                local newX = props.position.x - (main.userData.lastMousePos.x - e.position.x)
                local newY = props.position.y - (main.userData.lastMousePos.y - e.position.y)
                local newPos = util.vector2(newX, newY)

                newPos = clampAndCenterPosition(newPos, mapSize, mainSize)
                props.position = newPos

                meta:update()

                main.userData.lastMousePos = e.position
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = commonData.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = getMapBackgroundColor(meta),
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    position = util.vector2(0, 0),
                    size = meta.displayMapSize,
                },
                userData = {},
                content = ui.content {
                    mapTextureLayout,
                    -- for city and region names
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            position = util.vector2(0, 0),
                            relativeSize = util.vector2(1, 1),
                        },
                        userData = {},
                        content = ui.content {

                        },
                    },
                    -- player marker
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            position = util.vector2(0, 0),
                            relativeSize = util.vector2(1, 1),
                        },
                        userData = {},
                        content = ui.content {
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    relativePosition = meta:getRelativePositionByWorldPosition(playerRef.position),
                                    size = util.vector2(14 * stringLib.length(l10n("you")), 58),
                                    anchor = util.vector2(0.5, 1),
                                    visible = playerRef.cell.isExterior,
                                },
                                userData = {},
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Text,
                                        props = {
                                            text = l10n("you"),
                                            autoSize = true,
                                            anchor = util.vector2(0.5, 0),
                                            relativePosition = util.vector2(0.5, 0),
                                            textColor = config.data.ui.shadowColor,
                                            textSize = 14,
                                            visible = true,
                                            alpha = 0.6,
                                        },
                                        userData = {
                                            size = 14,
                                            name = l10n("you"),
                                        },
                                    },
                                    {
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = playerMarkerTexture,
                                            size = util.vector2(22, 44),
                                            anchor = util.vector2(0.5, 0),
                                            position = util.vector2((14 * stringLib.length(l10n("you"))) / 2, 14),
                                            color = config.data.ui.defaultColor,
                                            visible = true,
                                            alpha = 0.6,
                                        },
                                        userData = {
                                            size = util.vector2(22, 44),
                                        },
                                    },
                                },
                            },
                        },
                    },
                    -- for markers
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            position = util.vector2(0, 0),
                            relativeSize = util.vector2(1, 1),
                        },
                        userData = {},
                        content = ui.content {

                        },
                    },
                }
            }
        }
    }

    meta.layout = main

    meta:createCityNames()

    return main, meta
end


return this