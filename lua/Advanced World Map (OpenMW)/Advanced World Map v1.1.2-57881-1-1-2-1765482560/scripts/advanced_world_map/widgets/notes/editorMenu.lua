local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local UI = require('openmw.interfaces').UI

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

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or config.data.ui.fontSize

    params.size = params.size or util.vector2(screenSize.x * 0.3, screenSize.y * 0.4)

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

    local headerSize = util.vector2(params.size.x, params.fontSize)

    local mainSize = util.vector2(params.size.x, params.size.y - headerSize.y)


    local yesCallback = function ()
        if params.yesCallback then params.yesCallback(params.data) end
        meta:close()
    end

    local noCallback = function ()
        if params.noCallback then params.noCallback(params.data) end
        meta:close()
    end

    local removeCallback = function ()
        if params.removeCallback then params.removeCallback(params.data) end
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
                    size = util.vector2(params.fontSize, params.fontSize) * 1.25,
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
            }
        }
    }


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


    local markerColor = params.data and params.data.colorId and
        widgetData.colors[params.data.colorId] or config.data.ui.defaultColor

    local checkBoxes

    local function resetCheckBoxes()
        for _, cb in pairs(checkBoxes) do
            ---@type questGuider.ui.checkBox
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
                ---@type questGuider.ui.checkBox
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
                ---@type questGuider.ui.checkBox
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
                ---@type questGuider.ui.checkBox
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
                ---@type questGuider.ui.checkBox
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
            interval(params.fontSize, params.fontSize),
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    anchor = util.vector2(0.5, 0.5),
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content{
                    checkBoxes[4],
                    interval(params.fontSize, params.fontSize),
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = iconTexture,
                            size = util.vector2(1, 1) * params.fontSize * 1.25,
                            color = markerColor,
                            anchor = util.vector2(0.5, 0.5)
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
                                    params.data.colorId = params.data.colorId or 1
                                    params.data.colorId = params.data.colorId + 1
                                    if params.data.colorId > #widgetData.colors then params.data.colorId = 1 end

                                    namePosLayout.content[3].content[3].props.color = widgetData.colors[params.data.colorId]

                                    meta:update()
                                end

                                layout.userData.pressed = false
                            end),
                        }
                    },
                    interval(params.fontSize, params.fontSize),
                    checkBoxes[2],
                }
            },
            interval(params.fontSize, params.fontSize),
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