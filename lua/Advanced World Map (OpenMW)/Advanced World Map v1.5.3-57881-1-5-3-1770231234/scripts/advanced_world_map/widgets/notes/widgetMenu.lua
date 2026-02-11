local util = require("openmw.util")
local ui = require("openmw.ui")
local core = require("openmw.core")
local async = require("openmw.async")
local input = require("openmw.input")
local playerRef = require("openmw.self")
local vfs = require("openmw.vfs")
local NPC = require("openmw.types").NPC

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")
local playerPos = require("scripts.advanced_world_map.playerPosition")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local stringLib = require("scripts.advanced_world_map.utils.string")

local widgetData = require("scripts.advanced_world_map.widgets.notes.data")
local editorMenu = require("scripts.advanced_world_map.widgets.notes.editorMenu")

local l10n = core.l10n(commonData.l10nKey)

local scrollBox = require("scripts.advanced_world_map.ui.scrollBox")
local borders = require("scripts.advanced_world_map.ui.borders")
local button = require("scripts.advanced_world_map.ui.button")
local interval = require('scripts.advanced_world_map.ui.interval')
local checkBox = require("scripts.advanced_world_map.ui.checkBox")

local thinLineTexture = ui.texture{ path = "textures/menu_thin_border_top.dds" }
local defaultMarkerTexture = ui.texture{ path = commonData.noteMarkerPath }


local this = {}

this.update = function () end


---@param menu AdvancedWorldMap.Menu.Map
---@param sb advancedWorldMap.ui.scrollBox
---@param filter string
local function fill(menu, sb, filter)
    sb:clearContent()

    local playerName = NPC.record(playerRef.recordId).name or ""

    local sbSize = sb:getSize()
    sbSize = util.vector2(sbSize.x - 4, sbSize.y)

    ---@type Content
    local content = sb:getMainFlex().content
    local contentHeight = 0


    ---@param dt advancedWorldMap.widget.notes.data.markerData
    ---@param filterTags string?
    local function add(dt, filterTags)

        local text = widgetData.getDataText(dt, false)

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
                textShadow = false,
                textAlignV = ui.ALIGNMENT.Center,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }

        local posText = widgetData.getPosText(dt)
        if dt.plName ~= playerName then
            posText = ""..dt.plName..", "..posText
        end
        local posTextHeight = uiUtils.getTextHeight(posText, config.data.ui.fontSize * 0.9, sbSize.x - config.data.ui.fontSize,
            config.data.ui.textHeightMul, 0)
        local posLay = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content{
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = dt.icon and vfs.fileExists(dt.icon) and ui.texture{ path = dt.icon } or defaultMarkerTexture,
                        size = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize),
                        anchor = util.vector2(0, 0.5),
                        position = util.vector2(config.data.ui.fontSize / 2, 0),
                        color = dt and dt.colorId and widgetData.colors[dt.colorId] or config.data.ui.defaultColor
                    },
                    userData = {},
                    events = {
                        mousePress = async:callback(function(e, layout)
                            sb:mousePress(e)
                        end),

                        focusLoss = async:callback(function(e, layout)
                            sb:focusLoss(e)
                        end),

                        mouseMove = async:callback(function(e, layout)
                            sb:mouseMove(e)
                        end),

                        mouseRelease = async:callback(function(e, layout)
                            sb:mouseRelease(e)

                            if e.button ~= 1 then return end

                            if sb.lastMovedDistance < 20 then
                                editorMenu.create{
                                    data = dt,
                                    yesCallback = function (dt)
                                        if dt.pos then
                                            widgetData.addMarkerData(dt)
                                            require("scripts.advanced_world_map.widgets.notes.marker").create(dt, nil, true)
                                            menu.mapWidget:updateMarkers()
                                            fill(menu, sb, filter)
                                        end
                                    end,
                                    removeCallback = function (dt)
                                        widgetData.removeMarkerDataAlt(dt)
                                        require("scripts.advanced_world_map.widgets.notes.marker").remove(dt, true)
                                        menu.mapWidget:updateMarkers()
                                        fill(menu, sb, filter)
                                    end
                                }
                            end
                        end),
                    },
                },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = " "..posText,
                        textSize = config.data.ui.fontSize * 0.9,
                        size = util.vector2(sbSize.x - config.data.ui.fontSize, posTextHeight),
                        autoSize = false,
                        textColor = config.data.ui.defaultColor,
                        textShadow = false,
                        multiline = true,
                        wordWrap = true,

                    },
                }
            }
        }

        local height = textHeight + 2

        local layout = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(sbSize.x, height + posTextHeight + 6),
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
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                        position = util.vector2(0, 4),
                        size = util.vector2(sbSize.x, height),
                    },
                    userData = {},
                    events = {
                        mousePress = async:callback(function(e, layout)
                            sb:mousePress(e)
                        end),

                        focusLoss = async:callback(function(e, layout)
                            sb:focusLoss(e)

                            if textLay.props.textShadowColor then
                                textLay.props.textShadow = nil
                                textLay.props.textShadowColor = nil
                                posLay.content[2].props.textShadow = nil
                                posLay.content[2].props.textShadowColor = nil
                                menu:update()
                            end
                        end),

                        mouseMove = async:callback(function(e, layout)
                            sb:mouseMove(e)

                            if textLay.props.textShadowColor ~= config.data.ui.textShadowColor then
                                textLay.props.textShadow = true
                                textLay.props.textShadowColor = config.data.ui.textShadowColor
                                posLay.content[2].props.textShadow = true
                                posLay.content[2].props.textShadowColor = config.data.ui.textShadowColor
                                menu:update()
                            end
                        end),

                        mouseRelease = async:callback(function(e, layout)
                            sb:mouseRelease(e)

                            if e.button ~= 1 and e.button ~= 3 then return end

                            if sb.lastMovedDistance < 20 then

                                if e.button == 1 then
                                    if menu.mapWidget.cellId ~= dt.cellId then
                                        menu:updateMapWidgetCell(dt.cellId)
                                    end

                                    if menu.mapWidget:isInZoomInMode() and dt.onWorldMap then
                                        menu.mapWidget:setZoom(config.data.tileset.zoomToShow * 0.9)
                                    elseif not menu.mapWidget:isInZoomInMode() and not dt.onWorldMap then
                                        menu.mapWidget:setZoom(config.data.tileset.zoomToShow * 3)
                                    end

                                    menu.mapWidget:focusOnWorldPosition(dt.pos)
                                    menu.mapWidget:updateMarkers()

                                elseif e.button == 3 then
                                    editorMenu.create{
                                        data = dt,
                                        yesCallback = function (dt)
                                            if dt.pos then
                                                widgetData.addMarkerData(dt)
                                                require("scripts.advanced_world_map.widgets.notes.marker").create(dt, nil, true)
                                                menu.mapWidget:updateMarkers()
                                                fill(menu, sb, filter)
                                            end
                                        end,
                                        removeCallback = function (dt)
                                            widgetData.removeMarkerDataAlt(dt)
                                            require("scripts.advanced_world_map.widgets.notes.marker").remove(dt, true)
                                            menu.mapWidget:updateMarkers()
                                            fill(menu, sb, filter)
                                        end
                                    }
                                end

                                menu:update()
                            end
                        end),
                    },
                    content = ui.content{
                        posLay,
                        textLay,
                    }
                }
            }
        }

        content:add(layout)
        contentHeight = contentHeight + height
    end

    local widgetCellId = menu.mapWidget.cellId or commonData.exteriorMapId
    local playerExPos = playerPos.gexExteriorPos()

    local noteData = {}

    for cellId, _, dt in widgetData.getIterator() do
        if not config.data.notes.listForAllCharacters and (not dt.plName or dt.plName ~= playerName) then
            goto continue
        end

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

        ::continue::
    end

    -- Sort first by location type (exterior/interior), then by distance to the player
    table.sort(noteData, function (a, b)
        if a[3] ~= b[3] then
            return a[3]
        end
        return a[4] > b[4]
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

    local scrollBoxSize = util.vector2(size.x, size.y - (searchBarFontSize + config.data.ui.fontSize * 2 + 8))

    local scrollBoxLayout = scrollBox{
        updateFunc = menu.update,
        contentHeight = 0,
        leftOffset = 4,
        size = scrollBoxSize,
        scrollAmount = config.data.ui.fontSize * 2,
        content = scrollBoxContent,
    }

    ---@type advancedWorldMap.ui.scrollBox
    local scrollBoxMeta = scrollBoxLayout.userData.scrollBoxMeta ---@diagnostic disable-line: need-check-nil

    local textFilter = ":here:"

    fill(menu, scrollBoxMeta, textFilter)

    local allNotesCB = checkBox{
        updateFunc = menu.update,
        text = l10n("ListAllCharactersNotes"),
        textSize = config.data.ui.fontSize * 0.9,
        anchor = util.vector2(0, 0.5),
        position = util.vector2(4, config.data.ui.fontSize * 1),
        checked = config.data.notes.listForAllCharacters,
        event = function (checked, layout)
            config.setValue("notes.listForAllCharacters", checked)
            fill(menu, scrollBoxMeta, textFilter)
        end
    }

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
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    size = size,
                },
                content = ui.content{
                    searchBarLayout,
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(size.x, config.data.ui.fontSize * 2),
                        },
                        content = ui.content{
                            allNotesCB,
                        }
                    },
                    scrollBoxLayout,
                }
            },
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