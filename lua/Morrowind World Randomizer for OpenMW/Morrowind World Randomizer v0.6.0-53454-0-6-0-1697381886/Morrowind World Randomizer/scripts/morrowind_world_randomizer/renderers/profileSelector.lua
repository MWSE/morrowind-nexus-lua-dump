local async = require("openmw.async")
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")

local normalTextColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255)

-- part from openmw code
local function applyDefaults(argument, defaults)
    if not argument then return defaults end
    if pairs(defaults) and pairs(argument) then
        local result = {}
        for k, v in pairs(defaults) do
            result[k] = v
        end
        for k, v in pairs(argument) do
            result[k] = v
        end
        return result
    end
    return argument
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

local function loadProfileCallback(name)
    core.sendGlobalEvent("mwrbd_loadProfile", {name = name})
end

local function deleteProfileCallback(name)
    core.sendGlobalEvent("mwrbd_deleteProfile", {name = name})
end

I.Settings.registerRenderer('mwrbd_profileSelector', function(value, set, argument)
    argument = applyDefaults(argument, {
        disabled = false,
        profiles = {},
        protected = {},
        maxHeight = 5,
        loadCallback = loadProfileCallback,
        deleteCallback = deleteProfileCallback,
    })
    local index = 1
    local profiles = {}
    for i, val in pairs(argument.profiles) do
        table.insert(profiles, val)
    end
    local count = #profiles
    for i, profile in pairs(profiles) do
        if value == profile then
            index = i
            break
        end
    end
    if count == 0 then return {} end
    local upArrow = ui.texture {
        path = 'textures/omw_menu_scroll_up.dds',
    }
    local downArrow = ui.texture {
        path = 'textures/omw_menu_scroll_down.dds',
    }
    local profileUIGroup = {}
    if count > argument.maxHeight then
        table.insert(profileUIGroup, paddedBox{
            type = ui.TYPE.Image,
            props = {
                resource = upArrow,
                size = util.vector2(1, 1) * 14,
            },
            events = {
                mouseClick = async:callback(function()
                    index = math.max(argument.maxHeight * math.floor((index - argument.maxHeight - 1) / argument.maxHeight) + 1, 1)
                    set(profiles[index])
                end),
            },
        })
    end
    local startPos = argument.maxHeight * math.floor((index - 1) / argument.maxHeight) + 1
    for i = startPos, math.min(count, startPos + argument.maxHeight - 1) do
        local profile = profiles[i]
        local profileUI = {
            type = ui.TYPE.Text,
            props = {
                text = profile,
                textSize = 18,
                textAlignH = ui.ALIGNMENT.Start,
                textColor = normalTextColor,
            },
            events = {
                mouseClick = async:callback(function()
                    set(profile)
                end),
            },
        }
        if value == profile then
            table.insert(profileUIGroup, paddedBox(profileUI))
        else
            table.insert(profileUIGroup, profileUI)
        end
    end
    if count > argument.maxHeight then
        table.insert(profileUIGroup, paddedBox{
            type = ui.TYPE.Image,
            props = {
                resource = downArrow,
                size = util.vector2(1, 1) * 14,
            },
            events = {
                mouseClick = async:callback(function()
                    index = math.min(argument.maxHeight * math.floor((index + argument.maxHeight - 1) / argument.maxHeight) + 1, count)
                    set(profiles[index])
                end),
            },
        })
    end

    local buttons = {}
    table.insert(buttons, paddedBox{
            type = ui.TYPE.Text,
            props = {
                text = "Load selected",
                textSize = 18,
                textAlignH = ui.ALIGNMENT.Center,
                textColor = normalTextColor,
            },
            events = {
                mouseClick = async:callback(function()
                    if argument.loadCallback then argument.loadCallback(value) end
                end),
            },
        }
    )
    table.insert(buttons, {template = I.MWUI.templates.interval,})
    if not argument.protected[value] then
        table.insert(buttons, paddedBox{
                type = ui.TYPE.Text,
                props = {
                    text = "Delete selected",
                    textSize = 18,
                    textAlignH = ui.ALIGNMENT.Center,
                    textColor = normalTextColor,
                },
                events = {
                    mouseClick = async:callback(function()
                        if argument.deleteCallback then argument.deleteCallback(value) end
                    end),
                },
            }
        )
    end

    local data = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.End,
                },
                content = ui.content(buttons),
            },
            {template = I.MWUI.templates.interval,},
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.End,
                    size = util.vector2(400, 0),
                },
                content = ui.content(profileUIGroup),
            },
        },
    }
    return disable(argument.disabled, data)
end)

local function saveProfile(name)
    core.sendGlobalEvent("mwrbd_saveProfile", {name = name})
end

I.Settings.registerRenderer('mwrbd_createProfile', function(value, set, argument)
    argument = applyDefaults(argument, {
        disabled = false,
        callback = saveProfile,
    })
    local lastText = nil
    local data = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            paddedBox{
                type = ui.TYPE.Text,
                props = {
                    text = "Create",
                    textSize = 18,
                    textAlignH = ui.ALIGNMENT.Start,
                    textColor = normalTextColor,
                },
                events = {
                    mouseClick = async:callback(function()
                        set(lastText)
                        if argument.callback then argument.callback(lastText) end
                    end),
                },
            },
            {template = I.MWUI.templates.interval,},
            {template = I.MWUI.templates.interval,},
            paddedBox{
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = value,
                    size = util.vector2(400, 0),
                },
                events = {
                    textChanged = async:callback(function(text)
                        lastText = text
                    end),
                },
            },
        },
    }
    return disable(argument.disabled, data)
end)