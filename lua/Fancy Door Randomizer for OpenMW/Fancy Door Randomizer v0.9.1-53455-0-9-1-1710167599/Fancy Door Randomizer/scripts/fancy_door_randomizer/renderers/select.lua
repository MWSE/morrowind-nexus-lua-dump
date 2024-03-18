local I = require("openmw.interfaces")
local core = require('openmw.core')
local ui = require('openmw.ui')
local async = require("openmw.async")

local config = require("scripts.fancy_door_randomizer.config")

local l10nName = "fancy_door_randomizer"

local randomizationModes = config.modes

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content {
                layout,
            },
        }
    else
        return layout
    end
end

local function paddedBox(layout)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { layout },
            },
        }
    }
end

I.Settings.registerRenderer('fdrbd_select', function(value, set, argument)
    local default = {
        disabled = false,
        l10n = l10nName,
        items = randomizationModes,
    }
    if not argument then
        argument = default
    end
    local l10n = core.l10n(argument.l10n)
    local index = nil
    local itemCount = 0
    for i, item in ipairs(argument.items) do
        itemCount = itemCount + 1
        if item == value then
            index = i
        end
    end
    if not index then return {} end
    local label = l10n(value)
    local body = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            { template = I.MWUI.templates.interval },
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = label,
                },
                external = {
                    grow = 1,
                },
                events = {
                    mouseClick = async:callback(function()
                        index = (index) % itemCount + 1
                        set(argument.items[index])
                    end),
                },
            },
            { template = I.MWUI.templates.interval },
        },
    }
    return disable(argument.disabled, paddedBox(body))
end)