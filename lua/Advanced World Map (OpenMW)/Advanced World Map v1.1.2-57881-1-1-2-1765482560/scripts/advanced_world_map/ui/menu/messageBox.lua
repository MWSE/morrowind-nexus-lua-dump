local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")

local customTemplates = require("scripts.advanced_world_map.ui.templates")
local uiUtils = require("scripts.advanced_world_map.ui.utils")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")

local borders = require("scripts.advanced_world_map.ui.borders")
local button = require("scripts.advanced_world_map.ui.button")
local interval = require("scripts.advanced_world_map.ui.interval")



local this = {}


---@class UI.messageBox.newSimple.params
---@field fontSize number?
---@field relativeSize {x : number, y : number}?
---@field size {x : number, y : number}?
---@field relativePosition {x : number, y : number}?
---@field message string?
---@field yesCallback function?
---@field noCallback function?



---@param params UI.messageBox.newSimple.params
function this.newSimple(params)
    if not params then params = {} end

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or 18

    if params.relativeSize then
        params.size = params.size or util.vector2(screenSize.x * params.relativeSize.x, screenSize.y * params.relativeSize.y)
    end
    params.size = params.size or util.vector2(150, 200)

    if not params.relativePosition then
        params.relativePosition = util.vector2((screenSize.x - params.size.x) / 2 / screenSize.x, (screenSize.y - params.size.y) / 2 / screenSize.y)
    end
    params.message = params.message or ""

    ---@class UI.messageBox.simple.meta
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

    local mainLayout
    mainLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = mainSize,
            position = util.vector2(0, headerSize.y),
        },
        userData = {

        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                }
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = params.message,
                    textSize = params.fontSize,
                    autoSize = false,
                    size = util.vector2(mainSize.x, mainSize.y - params.fontSize * 2),
                    textColor = config.data.ui.defaultColor,
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
                userData = {},
                events = {
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
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    horizontal = true,
                    anchor = util.vector2(0.5, 0),
                    position = util.vector2(mainSize.x / 2, mainSize.y - params.fontSize * 2),
                    size = util.vector2(mainSize.x, params.fontSize * 2),
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    button{
                        updateFunc = meta.update,
                        textSize = params.fontSize,
                        text = core.getGMST("sYes"),
                        event = function (layout)
                            meta:close()
                            if params.yesCallback then params.yesCallback() end
                        end
                    },
                    interval(params.fontSize * 2, 0),
                    button{
                        updateFunc = meta.update,
                        textSize = params.fontSize,
                        text = core.getGMST("sNo"),
                        event = function (layout)
                            meta:close()
                            if params.noCallback then params.noCallback() end
                        end
                    },
                }
            },
            borders(),
        },
    }


    local layout = {
        type = ui.TYPE.Widget,
        layer = commonData.messageLayer,
        props = {
            size = params.size,
            relativePosition = params.relativePosition,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            mainLayout,
        }
    }


    meta.menu = ui.create(layout)

    return meta
end


return this