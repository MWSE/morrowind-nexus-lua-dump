local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local input = require('openmw.input')
local templates = require('openmw.interfaces').MWUI.templates
local tooltip = require("scripts.proximityTool.ui.tooltip")
local realTimer = require("scripts.proximityTool.realTimer")

---@class proximityTool.ui.button.params
---@field menu any
---@field text string?
---@field textSize integer?
---@field textColor any?
---@field size any? -- util.vector2
---@field hidden boolean?
---@field event function?
---@field intervalEvent function?
---@field tooltipContent any?

---@param params proximityTool.ui.button.params?
return function (params)
    if not params then params = {} end

    local content

    local lockEvent = false
    local timer
    local function stopIntervalTimer()
        if timer then
            timer()
            timer = nil
        end
    end

    local function startIntervalTimer(layout)
        stopIntervalTimer()

        if params.intervalEvent then
            local func
            func = function ()
                params.intervalEvent(layout)
                lockEvent = true
                timer = realTimer.newTimer(0.2, func)
            end
            timer = realTimer.newTimer(0.5, func)
        end
    end

    content = {
        template = templates.boxSolidThick,
        props = {
            propagateEvents = false,
            visible = not params.hidden,
        },
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolid
                layout.userData.pressed = true

                if params.intervalEvent then
                    startIntervalTimer(layout)
                end

                params.menu.element:update()
            end),

            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                content.template = templates.boxSolidThick
                if layout.userData.pressed and params.event and not lockEvent then
                    params.event(layout)
                end
                layout.userData.pressed = false

                if params.intervalEvent then
                    stopIntervalTimer()
                end
                lockEvent = false

                params.menu.element:update()
            end),

            focusLoss = async:callback(function(e, layout)
                layout.userData.pressed = false
                tooltip.destroy(layout)
            end),

            mouseMove = async:callback(function(coord, layout)
                if not params.tooltipContent then return end
                tooltip.createOrMove(coord, layout, params.tooltipContent)
            end),
        },
        userData = {
            pressed = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = params.size and false or true,
                    size = params.size,
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = params.text or "Ok",
                            textSize = params.textSize or 18,
                            textColor = params.textColor,
                            multiline = false,
                            wordWrap = false,
                            textAlignH = ui.ALIGNMENT.Start,
                        },
                    }
                }
            }
        },
    }

    return content
end