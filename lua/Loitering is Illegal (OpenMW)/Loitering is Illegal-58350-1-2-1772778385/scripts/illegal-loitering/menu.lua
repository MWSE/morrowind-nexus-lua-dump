local async = require('openmw.async')
local core = require('openmw.core')
local menu = require('openmw.menu')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local SECTION_NAME = 'illegalLoitering'

local pageOptions = {
    name = 'Illegal Loitering',
    searchHints = 'illegal loitering illegal loiter rest wait bounty safe cell',
    element = nil,
}

local element = nil
local subscribed = false
local updateElement = nil

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content { layout },
        }
    end
    return layout
end

local function getLastMarked()
    if menu.getState() ~= menu.STATE.Running then return nil end
    local section = storage.globalSection(SECTION_NAME)
    local last = section:get('lastMarkedCell')
    if type(last) ~= 'table' then return nil end
    return last.name or last.id
end

local function buildLayout()
    local running = menu.getState() == menu.STATE.Running

    local statusText = nil
    if running then
        local last = getLastMarked()
        if last then statusText = string.format('Last marked safe: %s', tostring(last)) end
    end

    local markButton = {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = 'Mark current cell as safe',
                        },
                    },
                },
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(150, 0),
                    visible = false,
                    propagateEvents = false,
                },
            },
        },
        events = {
            mouseClick = async:callback(function()
                if menu.getState() ~= menu.STATE.Running then
                    ui.showMessage('Load a game first.')
                    return
                end
                core.sendGlobalEvent('illegalLoitering_RequestMarkCurrentCellSafe')
                ui.showMessage('Marked current cell as safe.')
                async:newUnsavableSimulationTimer(0, function()
                    if updateElement then updateElement() end
                end)
            end),
        },
    }
    markButton = disable(not running, markButton)

    local resetButton = {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = 'Reset safe cell list.',
                        },
                    },
                },
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(150, 0),
                    visible = false,
                    propagateEvents = false,
                },
            },
        },
        events = {
            mouseClick = async:callback(function()
                if menu.getState() ~= menu.STATE.Running then
                    ui.showMessage('Load a game first.')
                    return
                end
                core.sendGlobalEvent('illegalLoitering_RequestResetSafeCells')
                ui.showMessage('Safe cells reset.')
                async:newUnsavableSimulationTimer(0, function()
                    if updateElement then updateElement() end
                end)
            end),
        },
    }
    resetButton = disable(not running, resetButton)

    return {
        name = 'illegalLoiteringSettings',
        type = ui.TYPE.Flex,
        props = {
            position = util.vector2(10, 10),
            size = util.vector2(560, 360),
        },
        content = ui.content((function()
            local content = ui.content {
            {
                template = I.MWUI.templates.textHeader,
                props = {
                    text = 'Illegal Loitering',
                    textSize = 22,
                },
            },
            {
                template = I.MWUI.templates.textParagraph,
                props = {
                    size = util.vector2(520, 0),
                    text = 'Adds bounty when you rest/wait in an illegal interior. If a place is actually your home but gets detected as illegal, mark it safe here.',
                },
            },
            { template = I.MWUI.templates.interval },
            markButton,
            { template = I.MWUI.templates.interval },
            resetButton,
            { template = I.MWUI.templates.interval },
            }
            if statusText then
                content:add {
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        size = util.vector2(520, 0),
                        text = statusText,
                    },
                }
            end
            return content
        end)()),
    }
end

updateElement = function()
    if not element then return end
    element.layout = buildLayout()
    element:update()
end

local function ensureSubscribed()
    if subscribed then return end
    if menu.getState() ~= menu.STATE.Running then return end

    local section = storage.globalSection(SECTION_NAME)
    section:subscribe(async:callback(function()
        updateElement()
    end))
    subscribed = true
end

element = ui.create(buildLayout())
pageOptions.element = element
ui.registerSettingsPage(pageOptions)
ensureSubscribed()
updateElement()

return {
    engineHandlers = {
        onStateChanged = function()
            ensureSubscribed()
            updateElement()
        end,
    },
}
