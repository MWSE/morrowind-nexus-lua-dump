local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require('openmw.util')

local module = {}

local currentUi
local maxLinesPerColumn = 50

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

local vMargin = padding(0, 20)
local hMargin = padding(20, 0)

local function text(str)
    return {
        template = I.MWUI.templates.textNormal,
        props = { text = str },
    }
end

local function centerWindow(content)
    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = util.vector2(.5, .5),
            anchor = util.vector2(.5, .5)
        },
        content = ui.content { content }
    }
end

module.createWindow = function(messages)
    if currentUi then
        currentUi:destroy()
    end

    local contents = { hMargin }
    local lines = {}
    for _, line in ipairs(messages) do
        table.insert(lines, text(line))
    end
    for i = 0, math.floor(#lines / maxLinesPerColumn) do
        local subLines = {}
        for j = i * maxLinesPerColumn, math.min(#lines, (i + 1) * maxLinesPerColumn) do
            table.insert(subLines, lines[j])
        end
        table.insert(contents, {
            type = ui.TYPE.Flex,
            content = ui.content(subLines)
        })
    end
    table.insert(contents, hMargin)

    currentUi = ui.create(centerWindow({
        type = ui.TYPE.Flex,
        content = ui.content {
            vMargin,
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content(contents)
            },
            vMargin,
        }
    }))
end

module.clearWindow = function()
    if currentUi then
        currentUi:destroy()
        currentUi = nil
    end
end

module.getWindow = function()
    return currentUi
end

return module
