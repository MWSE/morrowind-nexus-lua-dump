local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require('openmw.util')

local mDef = require('scripts.NCG.config.definition')
local mH = require('scripts.NCG.util.helpers')

local L = core.l10n(mDef.MOD_NAME)

local logsWindow

local module = {}

local function padding(horizontal, vertical)
    return { props = { size = util.vector2(horizontal, vertical) } }
end

local vGap10 = padding(0, 10)
local vGap20 = padding(0, 20)
local hGap10 = padding(10, 0)
local vMargin = padding(0, 30)
local hMargin = padding(30, 0)

local function title(text)
    return {
        template = I.MWUI.templates.textHeader,
        props = { text = text, textSize = 24 }
    }
end

local function head(text)
    return {
        template = I.MWUI.templates.textHeader,
        props = { text = text }
    }
end

local growingInterval = {
    external = { grow = 1 }
}

local stretchingLine = {
    template = I.MWUI.templates.horizontalLineThick,
    external = { stretch = 1 },
}

local function text(str)
    return {
        template = I.MWUI.templates.textNormal,
        props = { text = str },
    }
end

local function row(key, content, isHead)
    local left, right
    if type(key) == "string" then
        left = isHead and head(key) or text(key)
    else
        left = key
    end
    if type(content) == "string" then
        right = isHead and head(content) or text(content)
    else
        right = content
    end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { stretch = 1 },
        content = ui.content {
            left,
            hGap10,
            growingInterval,
            right,
        }
    }
end

local function headRow(key, value)
    return row(key, value, true)
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

module.closeLogsWindow = function()
    if logsWindow ~= nil then
        logsWindow:destroy()
        logsWindow = nil
    end
end

local function getLogsWindow(state)
    local messagesBlock = {
        headRow(L("messagesLogTitleHead"), L("messagesLogTimestampHead")),
        vGap10
    }
    for _, log in ipairs(state.messagesLog) do
        table.insert(messagesBlock, row(log.message, log.time))
    end

    local windowContent = {
        {
            type = ui.TYPE.Flex,
            external = { stretch = 1 },
            props = { arrange = ui.ALIGNMENT.Center },
            content = ui.content {
                title(string.format("%s - %s", L("name"), L("messagesLogTitleHead")))
            },
        },
        vGap10,
        stretchingLine,
        vGap10,
        {
            type = ui.TYPE.Flex,
            external = { stretch = 1 },
            content = ui.content(messagesBlock)
        }
    }

    return window({
        type = ui.TYPE.Flex,
        content = ui.content(windowContent),
    })
end

module.showLogsWindow = function(state)
    if logsWindow ~= nil then return end
    logsWindow = ui.create(getLogsWindow(state))
    async:newUnsavableSimulationTimer(1, function()
        if logsWindow ~= nil then
            self:sendEvent(mDef.events.refreshLogsWindow)
        end
    end)
end

module.refreshLogsWindow = function(state)
    if logsWindow == nil then return end
    logsWindow.layout = getLogsWindow(state)
    logsWindow:update()
    async:newUnsavableSimulationTimer(1, function()
        if logsWindow ~= nil then
            self:sendEvent(mDef.events.refreshLogsWindow)
        end
    end)
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
