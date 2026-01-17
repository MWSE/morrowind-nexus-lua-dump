local core = require('openmw.core')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require('openmw.util')

local mDef = require('scripts.BMS.config.definition')
local mH = require("scripts.BMS.util.helpers")

local L = core.l10n(mDef.MOD_NAME)

local module = {}

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

local vGap20 = padding(0, 20)
local vMargin = padding(0, 30)
local hMargin = padding(30, 0)

local stretchingLine = {
    template = I.MWUI.templates.horizontalLineThick,
    external = { stretch = 1 },
}

local function title(text)
    return {
        template = I.MWUI.templates.textHeader,
        props = { text = text, textSize = 24 }
    }
end

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

local function window(content)
    return centerWindow({
        type = ui.TYPE.Flex,
        content = ui.content {
            vMargin,
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content { hMargin, content, hMargin }
            },
            vMargin,
        }
    })
end

module.showErrorWindow = function(messageTitle, message, plugins)
    local lines = {
        title(L("pluginErrorHead")),
        vGap20,
        stretchingLine,
        vGap20,
        text(messageTitle),
    }
    if message then
        mH.insertMultipleInArray(lines, {
            vGap20,
            text(message),
        })
    end
    if plugins then
        table.insert(lines, vGap20)
        for _, plugin in ipairs(plugins) do
            table.insert(lines, text(plugin))
        end
        mH.insertMultipleInArray(lines, {
            vGap20,
            text(L("pluginErrorMessage1")),
            text(L("pluginErrorMessage2")),
        })
    end
    return window({
        type = ui.TYPE.Flex,
        props = { arrange = ui.ALIGNMENT.Center },
        content = ui.content(lines)
    })
end

return module
