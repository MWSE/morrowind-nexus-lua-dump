local async = require("openmw.async")
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")

local advTable = require("scripts.morrowind_world_randomizer.utils.table")

---@class mwr.settings.minmaxSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default table|nil
---@field min number|nil
---@field max number|nil
---@field independent boolean|nil
---@field integer boolean|nil
---@field disabled boolean|nil

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

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return end
    if argument.max and number > argument.max then return end
    if argument.integer and math.floor(number) ~= number then return end
    return number
end

local function customSet(key, val)
    local data = {}
    advTable.setValueByPath(data, key, val)
    core.sendGlobalEvent("mwrbd_updateSettings", data)
end

local defaultArgument = {
    disabled = false,
    integer = false,
    min = nil,
    max = nil,
    independent = true,
}

I.Settings.registerRenderer('mwrbd_minmax', function(value, set, argument)
    ---@type mwr.settings.minmaxSetting
    argument = applyDefaults(argument, defaultArgument)
    local lastInput = nil
    local data = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.boxTransparent,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = tostring(value.min),
                            size = util.vector2(80, 0),
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                lastInput = text
                            end),
                            focusLoss = async:callback(function()
                                if not lastInput then return end
                                local number = validateNumber(lastInput, argument)
                                if not number then
                                    customSet(argument.key, {min = value.min, max = value.max})
                                    -- set({min = value.min, max = value.max})
                                end
                                if number and number ~= value then
                                    if not argument.independent and number > value.max then number = value.max end
                                    customSet(argument.key, {min = number, max = value.max})
                                    -- set({min = number, max = value.max})
                                end
                            end),
                        },
                    },
                },
            },
            {template = I.MWUI.templates.interval,},
            {
                template = I.MWUI.templates.boxTransparent,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = tostring(value.max),
                            size = util.vector2(80, 0),
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                lastInput = text
                            end),
                            focusLoss = async:callback(function()
                                if not lastInput then return end
                                local number = validateNumber(lastInput, argument)
                                if not number then
                                    -- set({min = value.min, max = value.max})
                                    customSet(argument.key, {min = value.min, max = value.max})
                                end
                                if number and number ~= value then
                                    if not argument.independent and number < value.min then number = value.min end
                                    -- set({min = value.min, max = number})
                                    customSet(argument.key, {min = value.min, max = number})
                                end
                            end),
                        },
                    },
                },
            },
        },
    }
    return disable(argument.disabled, data)
end)