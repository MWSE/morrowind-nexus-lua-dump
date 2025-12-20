local util = require("openmw.util")
local ui = require("openmw.ui")
local core = require("openmw.core")
local async = require("openmw.async")
local input = require("openmw.input")
local playerRef = require("openmw.self")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.config")
local playerPos = require("scripts.advanced_world_map.playerPosition")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local stringLib = require("scripts.advanced_world_map.utils.string")

local widgetData = require("scripts.advanced_world_map.widgets.notes.data")

local l10n = core.l10n(commonData.l10nKey)

local scrollBox = require("scripts.advanced_world_map.ui.scrollBox")
local borders = require("scripts.advanced_world_map.ui.borders")
local button = require("scripts.advanced_world_map.ui.button")
local interval = require('scripts.advanced_world_map.ui.interval')

local thinLineTexture = ui.texture{ path = "textures/menu_thin_border_top.dds" }


local this = {}

this.update = function () end


---@param menu AdvancedWorldMap.Menu.Map
---@param sb advancedWorldMap.ui.scrollBox
---@param filter string
local function fill(menu, sb, filter)
    sb:clearContent()

    local sbSize = sb:getSize()

    ---@type Content
    local content = sb:getMainFlex().content
    local contentHeight = 0


    ---@param dt advancedWorldMap.widget.notes.data.markerData
    ---@param filterTags string?
    local function add(dt, filterTags)

        local text = widgetData.getDataText(dt)

        if filter and filter ~= "" then
            local textLower = (filterTags or "")..stringLib.utf8_lower(text)
            if not textLower:find(filter) then return end
        end

        local textHeight = uiUtils.getTextHeight(text, config.data.ui.fontSize, sbSize.x, config.data.ui.textHeightMul, 1)

        local textLay
        textLay = {
            type = ui.TYPE.Text,
            props = {
                text = text,
                textSize = config.data.ui.fontSize,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(sbSize.x, textHeight),
                position = util.vector2(0, 2),
                multiline = true,
                wordWrap = true,
                textShadow = true,
                textAlignV = ui.ALIGNMENT.Center,
                textAlignH = ui.ALIGNMENT.Center,
                propagateEvents = false,
            },
            userData = {

            },
            events = {
                mousePress = async:callback(function(e, layout)
                    sb:mousePress(e)
                end),

                focusLoss = async:callback(function(e, layout)
                    sb:focusLoss(e)

                    if layout.props.textShadowColor then
                        layout.props.textShadowColor = nil
                        menu:update()
                    end
                end),

                mouseMove = async:callback(function(e, layout)
                    sb:mouseMove(e)

                    if layout.props.textShadowColor ~= config.data.ui.textShadowColor then
                        layout.props.textShadowColor = config.data.ui.textShadowColor
                        menu:update()
                    end
                end),

                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end

                    sb:mouseRelease(e)

                    if sb.lastMovedDistance < 20 then
                        if menu.mapWidget.cellId ~= dt.cellId then
                            menu:updateMapWidgetCell(dt.cellId)
                        end
                        menu.mapWidget:focusOnWorldPosition(dt.pos)
                        menu.mapWidget:updateMarkers()

                        menu:update()
                    end
                end),
            },
        }

        local height = textHeight + 2

        local layout = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(sbSize.x, textHeight),
            },
            content = ui.content{
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = thinLineTexture,
                        tileH = true,
                        tileV = false,
                        size = util.vector2(0, 2),
                        relativeSize = util.vector2(1, 0),
                        anchor = util.vector2(0, 0),
                        relativePosition = util.vector2(0, 0),
                    },
                },
                textLay,
            }
        }

        content:add(layout)
        contentHeight = contentHeight + height
    end

    local widgetCellId = menu.mapWidget.cellId or commonData.exteriorMapId
    local playerExPos = playerPos.gexExteriorPos()

    local noteData = {}

    for cellId, _, dt in widgetData.getIterator() do
        local tags = ""
        local isEx = false

        if cellId == widgetCellId then
            tags = tags..":here:"
        end
        if cellId == commonData.exteriorMapId then
            tags = tags..":world:"
            isEx = true
        else
            tags = tags..":local:"
        end

        table.insert(noteData, {dt, tags, isEx, commonData.distance2D(isEx and playerExPos or playerRef.position, dt.pos)})
    end

    -- Sort first by location type (exterior/interior), then by distance to the player
    table.sort(noteData, function (a, b)
        if a[3] ~= b[3] then
            return a[3]
        end
        return a[4] < b[4]
    end)

    for _, data in ipairs(noteData) do
        add(data[1], data[2])
    end

    sb:setContentHeight(contentHeight)
end


---@param menu AdvancedWorldMap.Menu.Map
---@param content Content
function  this.create(menu, content)
    -- Get the size of the map widget to set our window size
    local mapWidgetSize = menu.mapWidget:getSize()

    local size = util.vector2(
        math.max(mapWidgetSize.x / 3, 250),
        mapWidgetSize.y
    )
    local searchBarFontSize = config.data.ui.fontSize * 1.25

    local scrollBoxContent = ui.content{}

    local scrollBoxSize = util.vector2(size.x, size.y - (searchBarFontSize + config.data.ui.fontSize / 2 + 6))

    local scrollBoxLayout = scrollBox{
        updateFunc = menu.update,
        contentHeight = 0,
        leftOffset = 2,
        size = scrollBoxSize,
        position = util.vector2(0, size.y - scrollBoxSize.y),
        scrollAmount = config.data.ui.fontSize * 2,
        content = scrollBoxContent,
    }

    ---@type advancedWorldMap.ui.scrollBox
    local scrollBoxMeta = scrollBoxLayout.userData.scrollBoxMeta ---@diagnostic disable-line: need-check-nil

    local textFilter = ":here:"

    fill(menu, scrollBoxMeta, textFilter)

    local searchBarLayout
    searchBarLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(size.x, searchBarFontSize + 6),
        },
        content = ui.content {
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = textFilter,
                    anchor = util.vector2(0, 0.5),
                    size = util.vector2(size.x - 114, searchBarFontSize),
                    textAlignV = ui.ALIGNMENT.Center,
                    textSize = searchBarFontSize,
                    position = util.vector2(2, searchBarFontSize / 2 + 3),
                    textColor = config.data.ui.defaultColor,
                },
                events = {
                    textChanged = async:callback(function(text, layout)
                        textFilter = stringLib.utf8_lower(text)
                    end),
                    keyRelease = async:callback(function(e, layout)
                        if e.code == input.KEY.Enter then
                            layout.props.text = textFilter
                            fill(menu, scrollBoxMeta, textFilter)
                            menu:update()
                        end
                    end),
                    focusLoss = async:callback(function(_, layout)
                        layout.props.text = textFilter
                    end),
                }
            },
            button{
                updateFunc = menu.update,
                text = l10n("Search"),
                size = util.vector2(100, config.data.ui.fontSize * 0.9),
                textSize = config.data.ui.fontSize * 0.9,
                anchor = util.vector2(1, 0.5),
                position = util.vector2(size.x - 2, searchBarFontSize / 2 + 3),
                event = function (layout)
                    fill(menu, scrollBoxMeta, textFilter)
                    menu:update()
                end
            },
            borders()
        }
    }

    local windowLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = size,
            color = config.data.ui.defaultColor,
        },
        userData = {

        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                    resource = uiUtils.whiteTexture,
                },
            },
            searchBarLayout,
            scrollBoxLayout,
            borders()
        }
    }

    this.update = function ()
        if menu:isWidgetActive("AdvancedWorldMap:Notes") then
            fill(menu, scrollBoxMeta, textFilter)
        end
    end


    content:add(windowLayout)
end


return this