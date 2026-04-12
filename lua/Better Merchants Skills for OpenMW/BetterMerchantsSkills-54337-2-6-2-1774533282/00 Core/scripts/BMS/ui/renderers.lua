local core = require('openmw.core')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local mDef = require('scripts.BMS.config.definition')

local L = core.l10n(mDef.MOD_NAME)

local growingInterval = { external = { grow = 1 } }
local lineLength = 250
local lineHeight = 25
local numberWidth = 30
local noteAlpha = 0.75

local defaultNumberArgument = {
    disabled = false,
    integer = false,
    min = nil,
    max = nil,
}

local actorLevelArgument = {
    integer = true,
    min = 1,
    max = 100,
}

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return argument.min end
    if argument.max and number > argument.max then return argument.max end
    if argument.integer and math.floor(number) ~= number then return math.floor(number) end
    return number
end

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

local function disable(disabled, layout)
    if not disabled then
        return layout
    end
    return {
        template = I.MWUI.templates.disabled,
        content = ui.content { layout },
    }
end

local function paddedBox(layout)
    return {
        type = ui.TYPE.Flex,
        props = { size = util.vector2(0, lineHeight), arrange = ui.ALIGNMENT.Center },
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content {
                    {
                        template = I.MWUI.templates.box,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.padding,
                                content = ui.content { layout },
                            }
                        }
                    }
                }
            },
            growingInterval,
        }
    }
end

local function textEdit(value, width, onValidated)
    local lastInput = tostring(value)
    return paddedBox({
        template = I.MWUI.templates.textEditLine,
        props = {
            text = lastInput,
            size = util.vector2(width, 0),
            textAlignH = ui.ALIGNMENT.End,
        },
        events = {
            textChanged = async:callback(function(text) lastInput = text end),
            focusLoss = async:callback(function() onValidated(lastInput) end),
            keyPress = async:callback(function(event)
                -- Return and numpad Enter keys
                if event.code == 40 or event.code == 88 then
                    onValidated(lastInput)
                end
            end)
        },
    })
end

local function paddedBlock(layout)
    return {
        type = ui.TYPE.Flex,
        props = { size = util.vector2(0, lineHeight), arrange = ui.ALIGNMENT.Center },
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.End },
                content = ui.content {
                    {
                        template = I.MWUI.templates.padding,
                        content = ui.content { layout },
                    }
                }
            },
            growingInterval,
        }
    }
end

local function textBlock(text, note)
    local alpha = note and noteAlpha or 1
    return {
        type = ui.TYPE.Flex,
        props = { size = util.vector2(0, lineHeight) },
        content = ui.content {
            growingInterval,
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { text = text, alpha = alpha },
            },
            growingInterval,
        }
    }
end

I.Settings.registerRenderer(mDef.renderers.number, function(value, set, argument)
    argument = applyDefaults(argument, defaultNumberArgument)
    local body = {
        textEdit(value,
                numberWidth,
                function(lastInput)
                    local number = validateNumber(lastInput, argument)
                    set(number and number or value)
                end
        )
    }
    if argument.isPercent then
        table.insert(body, textBlock("%"))
    end
    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content(body),
    })
end)

local npcLevel = 10
I.Settings.registerRenderer(mDef.renderers.scalingPercent, function(value, set, argument)
    local currPercent = mDef.difficultyPercent(value, argument.playerLevel)
    local baseSkill = mDef.baseSkill(npcLevel)
    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = { size = util.vector2(lineLength, 0), arrange = ui.ALIGNMENT.End },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    textBlock(L("difficultyFrom")),
                    textEdit(
                            value.from,
                            numberWidth,
                            function(lastInput)
                                local arg = applyDefaults(argument.from, defaultNumberArgument)
                                arg.max = math.min(arg.max, value.to)
                                local number = validateNumber(lastInput, arg)
                                set(number and { from = number, to = value.to, maxLvl = value.maxLvl } or value)
                            end
                    ),
                    textBlock(L("difficultyFromPlayerLevel")),
                }
            },
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    textBlock(L("difficultyTo")),
                    textEdit(
                            value.to,
                            numberWidth,
                            function(lastInput)
                                local arg = applyDefaults(argument.to, defaultNumberArgument)
                                arg.min = math.max(arg.min, value.from)
                                local number = validateNumber(lastInput, arg)
                                set(number and { from = value.from, to = number, maxLvl = value.maxLvl } or value)
                            end
                    ),
                    textBlock(L("difficultyMaxLevel")),
                    textEdit(
                            value.maxLvl,
                            numberWidth,
                            function(lastInput)
                                local number = validateNumber(lastInput, argument.maxLvl)
                                set(number and { from = value.from, to = value.to, maxLvl = number } or value)
                            end
                    ),
                    textBlock(L("difficultyAndAbove")),
                },
            },
            paddedBlock({
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { text = L("difficultyCurrent", { current = currPercent }), alpha = noteAlpha },
            }),
            paddedBlock({
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = { text = L("difficultyInteractiveExample"), alpha = noteAlpha },
            }),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    textBlock(L("difficultyNpcLevel"), true),
                    textEdit(
                            npcLevel,
                            numberWidth,
                            function(lastInput)
                                local number = validateNumber(lastInput, actorLevelArgument)
                                npcLevel = number and number or npcLevel
                                set(value)
                            end
                    ),
                    textBlock(L("difficultyCurrentMaxSkill", { current = util.round(baseSkill * currPercent / 100), max = util.round(baseSkill * value.to / 100) }), true),
                },
            },
        })
    })
end)