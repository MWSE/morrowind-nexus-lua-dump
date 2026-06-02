local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local templates = require('openmw.interfaces').MWUI.templates

local commonData = require("scripts.quest_guider_lite.common")
local configData = require("scripts.quest_guider_lite.config")

local interval = require("scripts.quest_guider_lite.ui.interval")
local tooltip = require("scripts.quest_guider_lite.ui.tooltip")


---@class questGuider.ui.checkBox.params
---@field text string?
---@field checked boolean?
---@field textSize integer?
---@field boxSize any?
---@field textElementSize any?
---@field visible boolean?
---@field position any? util.vector2
---@field relativePosition any? util.vector2
---@field anchor any? util.vector2
---@field textAlignH any?
---@field textAlignV any?
---@field tooltipContent any?
---@field getScrollBoxMeta (fun() : questGuider.ui.scrollBox)?
---@field event fun(checked : boolean, layout : any)?
---@field updateFunc fun()


---@param params questGuider.ui.checkBox.params
return function(params)
    local boxSize = params.boxSize or util.vector2((params.textSize or 18) - 10, (params.textSize or 18) - 10)
    local texture = ui.texture { path = "white" }

    local visible
    if params.visible ~= nil then
        visible = params.visible
    else
        visible = true
    end

    ---@class questGuider.ui.checkBox
    local meta = setmetatable({}, {})

    local contentData = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            position = params.position,
            relativePosition = params.relativePosition,
            anchor = params.anchor,
            horizontal = true,
            propagateEvents = false,
            visible = visible,
            arrange = ui.ALIGNMENT.Center,
        },
        userData = {
            checked = params.checked or false,
            meta = meta,
        },
        events = {
            mousePress = async:callback(function(e, layout)
                if params.getScrollBoxMeta then
                    params.getScrollBoxMeta():mousePress(e)
                end
            end),

            mouseRelease = async:callback(function(e, layout)
                if e.button == 1 and (not params.getScrollBoxMeta or
                        params.getScrollBoxMeta().lastMovedDistance < 30) then
                    layout.userData.checked = not layout.userData.checked

                    if layout.userData.checked then
                        layout.content[1].content[1].props.alpha = 1
                    else
                        layout.content[1].content[1].props.alpha = 0
                    end

                    if params.event then
                        params.event(layout.userData.checked, layout)
                    end

                    params.updateFunc()
                end

                if params.getScrollBoxMeta then
                    params.getScrollBoxMeta():mouseRelease(e)
                end
            end),

            focusLoss = async:callback(function(e, layout)
                if params.getScrollBoxMeta then
                    params.getScrollBoxMeta():focusLoss(e)
                end
                tooltip.destroy(layout)
            end),

            mouseMove = async:callback(function(e, layout)
                if params.getScrollBoxMeta then
                    params.getScrollBoxMeta():mouseMove(e)
                end
                if not params.tooltipContent then return end
                tooltip.createOrMove(e, layout, params.tooltipContent)
            end),
        },
        content = ui.content {
            {
                template = templates.boxThick,
                type = ui.TYPE.Container,
                props = {
                    anchor = util.vector2(0, 0),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = texture,
                            size = boxSize,
                            inheritAlpha = false,
                            alpha = params.checked and 1 or 0,
                            color = configData.data.ui.defaultColor,
                        },
                    }
                },
            },
        }
    }

    if params.text then
        contentData.content:add(interval(4, 4))

        contentData.content:add({
            type = ui.TYPE.Text,
            props = {
                text = params.text or "",
                textColor = configData.data.ui.defaultColor,
                textSize = params.textSize or 18,
                autoSize = not params.textElementSize and true or false,
                size = params.textElementSize or nil,
                anchor = util.vector2(0, 0.5),
                multiline = params.textElementSize and true or false,
                wordWrap = params.textElementSize and true or false,
                textAlignH = params.textAlignH or ui.ALIGNMENT.Start,
                textAlignV = params.textAlignV or ui.ALIGNMENT.Start,
            },
        })
    end

    meta.getChecked = function(self)
        return contentData.userData.checked
    end

    meta.setChecked = function(self, checked)
        contentData.userData.checked = checked

        if contentData.userData.checked then
            contentData.content[1].content[1].props.alpha = 1
        else
            contentData.content[1].content[1].props.alpha = 0
        end

        params.updateFunc()
    end

    return contentData
end