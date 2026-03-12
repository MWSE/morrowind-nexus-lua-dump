local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local UI = require("openmw.interfaces").UI
local plRef = require("openmw.self")
local types = require("openmw.types")
local vfs = require("openmw.vfs")

local customTemplates = require("scripts.advanced_world_map.ui.templates")
local uiUtils = require("scripts.advanced_world_map.ui.utils")
local tableLib = require("scripts.advanced_world_map.utils.table")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")

local widgetData = require("scripts.advanced_world_map.widgets.notes.data")

local borders = require("scripts.advanced_world_map.ui.borders")
local button = require("scripts.advanced_world_map.ui.button")
local interval = require("scripts.advanced_world_map.ui.interval")
local checkBox = require("scripts.advanced_world_map.ui.checkBox")

local l10n = core.l10n(commonData.l10nKey)

local iconTexture = ui.texture{ path = commonData.noteMarkerPath }
local arrowLeftTexture = ui.texture{ path = "textures/omw_menu_scroll_left.dds" }
local arrowRightTexture = ui.texture{ path = "textures/omw_menu_scroll_right.dds" }

local borderTextures = {
    ui.texture{ path = "textures/menu_thin_border_left.dds" },
    ui.texture{ path = "textures/menu_thin_border_right.dds" },
    ui.texture{ path = "textures/menu_thin_border_top.dds" },
}


local this = {}


---@class advancedWorldMap.widget.notes.editorMenu.meta

---@class advancedWorldMap.widget.notes.editorMenu.params
---@field data advancedWorldMap.widget.notes.data.markerData?
---@field yesCallback fun(data : advancedWorldMap.widget.notes.data.markerData)?
---@field noCallback fun(data : advancedWorldMap.widget.notes.data.markerData)?
---@field removeCallback fun(data : advancedWorldMap.widget.notes.data.markerData)?


---@param params advancedWorldMap.widget.notes.editorMenu.params
function this.create(params)
    if not params then params = {} end
    ---@class advancedWorldMap.widget.notes.editorMenu.params
    params = params

    params.data = params.data and tableLib.copy(params.data) or {}

    params.data.plName = params.data.plName or types.NPC.record(plRef.recordId).name or ""
    params.data.size = params.data.size or 2
    params.data.icon = params.data.icon or commonData.widgetIconsDir.."default/featherico.png"

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or config.data.ui.fontSize

    params.size = params.size or util.vector2(screenSize.x * 0.4, screenSize.y * 0.4)

    if not params.relativePosition then
        params.relativePosition = util.vector2((screenSize.x - params.size.x) / 2 / screenSize.x, (screenSize.y - params.size.y) / 2 / screenSize.y)
    end

    ---@class advancedWorldMap.widget.notes.editorMenu.meta
    local meta = setmetatable({}, {})

    meta.params = params
    meta.update = function ()
        meta.menu:update()
    end

    function meta:close()
        if not self.menu then return end
        self.menu:destroy()
    end

    local headerSize = util.vector2(params.size.x, params.fontSize * 1.6)

    local mainSize = util.vector2(params.size.x, params.size.y - headerSize.y)


    local yesCallback = function ()
        if params.yesCallback then params.yesCallback(params.data) end
        widgetData.saveData()
        meta:close()
    end

    local noCallback = function ()
        if params.noCallback then params.noCallback(params.data) end
        meta:close()
    end

    local removeCallback = function ()
        if params.removeCallback then params.removeCallback(params.data) end
        widgetData.saveData()
        meta:close()
    end



    local moveEvents = {
        mousePress = async:callback(function(coord, layout)
            layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
        end),

        mouseRelease = async:callback(function(_, layout)
            layout.userData.lastMousePos = nil
        end),

        mouseMove = async:callback(function(coord, layout)
            if not layout.userData.lastMousePos then return end

            local props = meta.menu.layout.props
            local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

            props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
            meta:update()

            layout.userData.lastMousePos = relativePos
        end),
    }


    local headerLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = headerSize,
            anchor = util.vector2(0.5, 0.5)
        },
        userData = {},
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                },
                userData = {},
                events = moveEvents,
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = params.data.plName..":",
                    textColor = config.data.ui.defaultColor,
                    textSize = config.data.ui.fontSize * 1.5,
                    anchor = util.vector2(0, 0.5),
                    relativePosition = util.vector2(0, 0.5),
                }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTextures[1],
                    tileH = false,
                    tileV = true,
                    size = util.vector2(2, 0),
                    relativeSize = util.vector2(0, 1),
                    anchor = util.vector2(0, 0),
                    relativePosition = util.vector2(0, 0),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTextures[2],
                    tileH = false,
                    tileV = true,
                    size = util.vector2(2, 0),
                    relativeSize = util.vector2(0, 1),
                    anchor = util.vector2(1, 0),
                    relativePosition = util.vector2(1, 0),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = borderTextures[3],
                    tileH = true,
                    tileV = false,
                    size = util.vector2(0, 2),
                    relativeSize = util.vector2(1, 0),
                    anchor = util.vector2(0, 0),
                    relativePosition = util.vector2(0, 0),
                },
            },
        }
    }


    local buttonLayout = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = true,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(mainSize.x, params.fontSize * 2),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            button{
                updateFunc = meta.update,
                textSize = params.fontSize,
                text = core.getGMST("sYes"),
                event = yesCallback,
            },
            interval(params.fontSize * 2, 0),
            button{
                updateFunc = meta.update,
                textSize = params.fontSize,
                text = core.getGMST("sNo"),
                event = noCallback,
            },
        }
    }

    if params.removeCallback then
        buttonLayout.content:add(interval(params.fontSize * 2, 0))
        buttonLayout.content:add(button{
            updateFunc = meta.update,
            textSize = params.fontSize,
            text = l10n("Remove"),
            event = removeCallback,
        })
    end


    local nameColor = params.data and params.data.nameColorId and
        widgetData.colors[params.data.nameColorId] or config.data.ui.defaultColor

    local nameEditLayout
    nameEditLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            anchor = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content{
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(params.fontSize * 1.75, params.fontSize* 1.25),
                    anchor = util.vector2(0.5, 0.5),
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = uiUtils.whiteTexture,
                            relativeSize = util.vector2(1, 1),
                            color = nameColor,
                        },
                        userData = {},
                        events = {
                            mousePress = async:callback(function(e, layout)
                                if e.button ~= 1 then return end
                                layout.userData.pressed = true
                            end),

                            mouseRelease = async:callback(function(e, layout)
                                if e.button ~= 1 then return end

                                if layout.userData.pressed then
                                    params.data.nameColorId = params.data.nameColorId or 1
                                    params.data.nameColorId = params.data.nameColorId + 1
                                    if params.data.nameColorId > #widgetData.colors then params.data.nameColorId = 1 end

                                    nameEditLayout.content[1].content[1].props.color = widgetData.colors[params.data.nameColorId]

                                    meta:update()
                                end

                                layout.userData.pressed = false
                            end),
                        }
                    },
                    borders()
                }
            },
            {
                template = customTemplates.boxSolid,
                props = {
                    anchor = util.vector2(0.5, 0.5),
                },
                content = ui.content{
                    {
                        type = ui.TYPE.TextEdit,
                        props = {
                            text = params.data.name or "",
                            anchor = util.vector2(0, 0),
                            size = util.vector2(params.size.x - screenSize.x * 0.075, config.data.ui.fontSize * 1.25),
                            textAlignH = ui.ALIGNMENT.Center,
                            textSize = config.data.ui.fontSize * 1.25,
                            textColor = config.data.ui.defaultColor,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                params.data.name = text
                            end),
                            focusLoss = async:callback(function(_, layout)
                                layout.props.text = params.data.name
                            end),
                        }
                    },
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(params.fontSize * 1.75, params.fontSize * 1.25),
                    anchor = util.vector2(0.5, 0.5),
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = widgetData.markerSizeNames[params.data.size or 2],
                            textSize = config.data.ui.fontSize,
                            textColor = config.data.ui.defaultColor,
                            autoSize = false,
                            size = util.vector2(params.fontSize * 1.75, params.fontSize * 1.25),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                    },
                    borders()
                },
                userData = {},
                events = {
                    mousePress = async:callback(function(e, layout)
                        if e.button ~= 1 then return end
                        layout.userData.pressed = true
                    end),

                    mouseRelease = async:callback(function(e, layout)
                        if e.button ~= 1 then return end

                        if layout.userData.pressed then
                            params.data.size = params.data.size or 2
                            params.data.size = params.data.size + 1
                            if params.data.size > #widgetData.markerSizeNames then params.data.size = 1 end

                            layout.content[1].props.text = widgetData.markerSizeNames[params.data.size]

                            meta:update()
                        end

                        layout.userData.pressed = false
                    end),
                }
            },
        }
    }

-- ######################################################################################
-- Icon selection layout
    local maxRows = 3
    local iconsLay = {
        type = ui.TYPE.Flex,
        props = {
            anchor = util.vector2(0.5, 0.5),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            horizontal = false,
            autoSize = false,
            size = util.vector2(mainSize.x - params.fontSize * 5, 0),
        },
        content = ui.content{}
    }

    local maxIconsInRow = math.floor(iconsLay.props.size.x / (params.fontSize * 1.8))
    local maxIcons = maxRows * maxIconsInRow
    local horizontalFlex

    local lastIcon
    local function clearLastIconParams()
        if not lastIcon then return end
        for i = #lastIcon.content, 2, -1 do
            uiUtils.removeFromContent(lastIcon.content, i)
        end
        lastIcon.content[1].props.color = util.color.rgb(1, 1, 1)
    end

    local dirFile = vfs.open(commonData.widgetIconsDir.."dir.txt")
    ---@type string[]
    local icons = {}
    local iconEndIndexes = {}
    for line in dirFile:lines() do
        local hasIcon = false
        pcall(function ()
            line = line and line:gsub("%c", "") or nil
            local nextFile = vfs.pathsWithPrefix(commonData.widgetIconsDir..line)
            local file
            repeat
                file = nextFile()
                local extension = file and string.lower(file:sub(-4))
                if file and (extension == ".png" or extension == ".dds") then
                    table.insert(icons, file)
                    hasIcon = true
                end
            until file == nil
        end)
        if hasIcon then
            table.insert(iconEndIndexes, #icons)
        end
    end

    local lastIconIndex = 0
    local function clearIcons()
        lastIconIndex = 0
        for i = #iconsLay.content, 1, -1 do
            uiUtils.removeFromContent(iconsLay.content, i)
        end
        horizontalFlex = nil
    end

    local function placeIcon(path)
        if not path then return end

        if not horizontalFlex or #horizontalFlex.content >= maxIconsInRow then
            local rows = #iconsLay.content
            if rows == maxRows then return end

            iconsLay.props.size = util.vector2(iconsLay.props.size.x, params.fontSize * 1.8 * (rows + 1))

            horizontalFlex = {
                type = ui.TYPE.Flex,
                props = {
                    anchor = util.vector2(0.5, 0.5),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    horizontal = true,
                    autoSize = false,
                    size = util.vector2(mainSize.x, params.fontSize * 1.8),
                },
                content = ui.content{}
            }
            iconsLay.content:add(horizontalFlex)
        end

        local isSelected = path == params.data.icon

        horizontalFlex.content:add{
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(params.fontSize, params.fontSize) * 1.8
            },
            content = ui.content{
                {
                    type = ui.TYPE.Image,
                    props = {
                        position = util.vector2(params.fontSize * 0.9, params.fontSize * 0.9),
                        anchor = util.vector2(0.5, 0.5),
                        size = util.vector2(params.fontSize, params.fontSize) * 1.25,
                        resource = ui.texture{ path = path },
                    },
                }
            },
            userData = {},
            events = {
                mousePress = async:callback(function(e, layout)
                    if e.button ~= 1 then return end
                    layout.userData.pressed = true
                end),
                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end

                    if layout.userData.pressed then
                        params.data.icon = path

                        if lastIcon ~= layout then
                            clearLastIconParams()
                            for _, border in pairs({borders()}) do
                                layout.content:add(border)
                            end

                            layout.content[1].props.color = widgetData.colors[params.data.colorId or 1]

                            lastIcon = layout
                        else
                            params.data.colorId = params.data.colorId or 1
                            params.data.colorId = params.data.colorId + 1
                            if params.data.colorId > #widgetData.colors then params.data.colorId = 1 end

                            layout.content[1].props.color = widgetData.colors[params.data.colorId]
                        end

                        meta:update()
                    end

                    layout.userData.pressed = false
                end),
            }
        }

        if isSelected then
            clearLastIconParams()
            lastIcon = horizontalFlex.content[#horizontalFlex.content]
            lastIcon.content[1].props.color = widgetData.colors[params.data.colorId or 1]
            for _, border in pairs({borders()}) do
                lastIcon.content:add(border)
            end
        end

        return true
    end


    for i, iconPath in ipairs(icons) do
        if not iconEndIndexes[1] or iconEndIndexes[1] < i then break end
        if not placeIcon(iconPath) then
            break
        else
            lastIconIndex = i
        end
    end


    local lastStartIndex = 1
    local btnLeftLayout = button{
        updateFunc = meta.update,
        iconTexture = arrowLeftTexture,
        iconSize = util.vector2(params.fontSize * 1.25 - 6, params.fontSize * 1.25 - 6),
        anchor = util.vector2(0.5, 0.5),
        event = function ()
            local startIndex = math.max(lastStartIndex - maxIcons, 1)
            local endIndex = startIndex + maxIcons - 1

            if lastStartIndex == startIndex and iconEndIndexes[1] then
                endIndex = iconEndIndexes[1]
            end
            lastStartIndex = startIndex

            clearIcons()
            clearLastIconParams()

            for i = startIndex, endIndex do
                if not placeIcon(icons[i]) then
                    break
                else
                    lastIconIndex = i
                end
            end

            meta:update()
        end,
    }

    local btnRightLayout = button{
        updateFunc = meta.update,
        iconTexture = arrowRightTexture,
        iconSize = util.vector2(params.fontSize * 1.25 - 6, params.fontSize * 1.25 - 6),
        anchor = util.vector2(0.5, 0.5),
        event = function ()
            local endIndex = math.min(lastIconIndex + maxIcons, #icons)
            local startIndex = endIndex - maxIcons + 1
            lastStartIndex = startIndex

            clearIcons()
            clearLastIconParams()

            for i = startIndex, endIndex do
                if not placeIcon(icons[i]) then
                    break
                else
                    lastIconIndex = i
                end
            end

            meta:update()
        end,
    }
-- ######################################################################################


    local descriptionLayout = {
        template = customTemplates.boxSolid,
        props = {
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content{
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = params.data.descr or "",
                    size = util.vector2(params.size.x - 12, config.data.ui.fontSize * 5),
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textSize = config.data.ui.fontSize * 1,
                    textColor = config.data.ui.defaultColor,
                },
                events = {
                    textChanged = async:callback(function(text, layout)
                        params.data.descr = text
                    end),
                    focusLoss = async:callback(function(_, layout)
                        layout.props.text = params.data.descr
                    end),
                }
            },
        }
    }


    local checkBoxes

    local function resetCheckBoxes()
        for _, cb in pairs(checkBoxes) do
            ---@type advancedWorldMap.ui.checkBox
            local cbMeta = cb.userData.meta

            cbMeta:setChecked(false)
        end
    end

    checkBoxes = {
        checkBox{
            updateFunc = meta.update,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(1, 1) * params.fontSize * 1.25,
            checked = params.data.namePosId == 0,
            event = function (checked, layout)
                ---@type advancedWorldMap.ui.checkBox
                local cbMeta = layout.userData.meta
                resetCheckBoxes()
                cbMeta:setChecked(checked)
                params.data.namePosId = checked and 0 or nil
            end,
        },
        checkBox{
            updateFunc = meta.update,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(1, 1) * params.fontSize * 1.25,
            checked = params.data.namePosId == 1,
            event = function (checked, layout)
                ---@type advancedWorldMap.ui.checkBox
                local cbMeta = layout.userData.meta
                resetCheckBoxes()
                cbMeta:setChecked(checked)
                params.data.namePosId = checked and 1 or nil
            end,
        },
        checkBox{
            updateFunc = meta.update,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(1, 1) * params.fontSize * 1.25,
            checked = params.data.namePosId == 2,
            event = function (checked, layout)
                ---@type advancedWorldMap.ui.checkBox
                local cbMeta = layout.userData.meta
                resetCheckBoxes()
                cbMeta:setChecked(checked)
                params.data.namePosId = checked and 2 or nil
            end,
        },
        checkBox{
            updateFunc = meta.update,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(1, 1) * params.fontSize * 1.25,
            checked = params.data.namePosId == 3,
            event = function (checked, layout)
                ---@type advancedWorldMap.ui.checkBox
                local cbMeta = layout.userData.meta
                resetCheckBoxes()
                cbMeta:setChecked(checked)
                params.data.namePosId = checked and 3 or nil
            end,
        },
    }

    local namePosLayout
    namePosLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            anchor = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content{
            checkBoxes[1],
            interval(params.fontSize / 2, params.fontSize / 2),
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    anchor = util.vector2(0.5, 0.5),
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        },
                        content = ui.content{
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    size = util.vector2(math.ceil(params.fontSize * 1.25), math.ceil(params.fontSize * 1.25)),
                                    arrange = ui.ALIGNMENT.Center,
                                    align = ui.ALIGNMENT.Center,
                                    autoSize = false,
                                },
                                content = ui.content{
                                    btnLeftLayout,
                                }
                            },
                            interval(params.fontSize / 2, params.fontSize / 2),
                            checkBoxes[4],
                        }
                    },
                    interval(params.fontSize / 2, params.fontSize / 2),
                    iconsLay,
                    interval(params.fontSize / 2, params.fontSize / 2),
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        },
                        content = ui.content{
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    size = util.vector2(math.ceil(params.fontSize * 1.25), math.ceil(params.fontSize * 1.25)),
                                    arrange = ui.ALIGNMENT.Center,
                                    align = ui.ALIGNMENT.Center,
                                    autoSize = false,
                                },
                                content = ui.content{
                                    btnRightLayout,
                                }
                            },
                            interval(params.fontSize / 2, params.fontSize / 2),
                            checkBoxes[2],
                        }
                    },
                }
            },
            interval(params.fontSize / 2, params.fontSize / 2),
            checkBoxes[3],
        }
    }


    local layout
    layout = {
        type = ui.TYPE.Flex,
        layer = commonData.messageLayer,
        props = {
            autoSize = true,
            horizontal = false,
            relativePosition = params.relativePosition,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        userData = {
            meta = meta,
        },
        events = moveEvents,
        content = ui.content {
            headerLayout,
            {
                template = customTemplates.boxSolid,
                props = {
                    anchor = util.vector2(0.5, 0.5)
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = false,
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        },
                        content = ui.content{
                            {
                                type = ui.TYPE.Text,
                                props = {
                                    text = l10n("Name")..":",
                                    textSize = config.data.ui.fontSize,
                                    textColor = config.data.ui.defaultColor,
                                    anchor = util.vector2(0.5, 0.5)
                                }
                            },
                            nameEditLayout,
                            interval(params.fontSize, params.fontSize),
                            {
                                type = ui.TYPE.Text,
                                props = {
                                    text = l10n("Description")..":",
                                    textSize = config.data.ui.fontSize,
                                    textColor = config.data.ui.defaultColor,
                                    anchor = util.vector2(0.5, 0.5)
                                }
                            },
                            descriptionLayout,
                            interval(params.fontSize, params.fontSize),
                            namePosLayout,
                            interval(params.fontSize, params.fontSize),
                            buttonLayout,
                        }
                    }
                }
            },
        },
    }

    meta.menu = ui.create(layout)

    if core.isWorldPaused() then
        local timer = async:newUnsavableSimulationTimer(0.1, function ()
            meta:close()
        end)
    else
        local timer
        timer = time.runRepeatedly(function ()
            if UI.getMode() == nil then
                timer()
                meta:close()
            end
        end, 0.2)
    end

    return meta
end


return this