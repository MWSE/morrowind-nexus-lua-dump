local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local commonData = require("scripts.proximityTool.common")
local config = require("scripts.proximityTool.config")

local tableLib = require("scripts.proximityTool.utils.table")
local uiUtils = require("scripts.proximityTool.ui.utils")

local tooltip = require("scripts.proximityTool.ui.tooltip")

local this = {}

---@param forRecord boolean?
function this.tooltipMoveOrCreate(coord, layout, forRecord)
    if not layout.userData or not layout.userData.data then return end

    if not tooltip.isExists(layout) then
        local foundDescription = false

        local tooltipLayoutContent = ui.content {}

        local screenSize = uiUtils.getScaledScreenSize()
        local fontSize = config.data.ui.fontSize + 5

        local function drawDescription(record)
            if not record.description then return end

            local dCol = record.descriptionColor

            local line = {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                },
                content = ui.content {}
            }

            local added = false
            local textWidth
            local function addDescrLine(str, color)
                if str and str ~= "" then
                    added = true

                    textWidth = textWidth or math.min(screenSize.x * 0.4, (utf8.len(str) or string.len(str)) * fontSize * 0.7)

                    line.content:add{
                        type = ui.TYPE.TextEdit,
                        props = {
                            text = str,
                            textSize = fontSize,
                            multiline = true,
                            wordWrap = true,
                            autoSize = true,
                            size = util.vector2(textWidth, 0),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            readOnly = true,
                            textColor = color or config.data.ui.defaultColor,
                        },
                    }
                end
            end

            if type(record.description) == "string" then
                local color = dCol and util.color.rgb(dCol[1], dCol[2], dCol[3])
                if dCol then
                    if type(dCol[1]) == "number" then
                        color = util.color.rgb(dCol[1], dCol[2], dCol[3])
                    else
                        color = util.color.rgb(dCol[1][1], dCol[1][2], dCol[1][3])
                    end
                else
                    color = commonData.defaultColor
                end
                addDescrLine(record.description, color)
            else
                for i, str in pairs(record.description) do ---@diagnostic disable-line: param-type-mismatch
                    textWidth = math.max(textWidth or 0, math.min(screenSize.x * 0.4, (utf8.len(str) or string.len(str)) * fontSize * 0.7))
                end

                for i, str in ipairs(record.description) do ---@diagnostic disable-line: param-type-mismatch
                    local color
                    if dCol then
                        if type(dCol[1]) == "number" then
                            color = util.color.rgb(dCol[1], dCol[2], dCol[3])
                        else
                            local colDt = dCol[i] or commonData.defaultColorData
                            color = util.color.rgb(colDt[1], colDt[2], colDt[3])
                        end
                    else
                        color = config.data.ui.defaultColor
                    end
                    addDescrLine(str, color)
                end
            end

            if not added then return end

            if foundDescription then
                tooltipLayoutContent:add{
                    template = I.MWUI.templates.interval,
                }
            end

            foundDescription = true

            tooltipLayoutContent:add(line)
        end


        if forRecord then
            ---@type proximityTool.markerRecord
            local record = layout.userData.record
            if not record or record.invalid or record.alpha == 0 then return end

            drawDescription(record)
        else
            ---@type proximityTool.activeMarker
            local markerHandler = layout.userData.data
            if not markerHandler then return end

            ---@type proximityTool.activeMarkerData[]
            local records = tableLib.values(markerHandler.markers, function (a, b)
                return (a.record.priority or 0) > (b.record.priority or 0)
            end)

            for _, recDt in ipairs(records) do
                local record = recDt.record
                if record and not record.invalid and record.alpha ~= 0 then
                    drawDescription(record)
                end
            end
        end

        if foundDescription then
            tooltip.createOrMove(coord, layout, tooltipLayoutContent)
        end

    else
        tooltip.createOrMove(coord, layout, nil)
    end
end


function this.tooltipDestroy(layout)
    tooltip.destroy(layout)
end

return this