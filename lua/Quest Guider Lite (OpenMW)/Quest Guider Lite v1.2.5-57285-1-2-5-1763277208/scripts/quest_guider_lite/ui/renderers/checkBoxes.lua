local core = require("openmw.core")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local templates = I.MWUI.templates

local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local interval = require("scripts.quest_guider_lite.ui.interval")

local commonData = require("scripts.quest_guider_lite.common")

---@class UI.renderer.checkBoxesRenderer.checkBoxes
---@field name string l10n
---@field key string
---@field default boolean

---@class UI.renderer.yesNoWithCheckbox.params
---@field l10n string?
---@field checkBoxes UI.renderer.checkBoxesRenderer.checkBoxes[]


I.Settings.registerRenderer("AdvWMap:checkboxes", function(value, set, argument)
    do
        local args = {}
        for n, v in pairs(argument) do
            args[n] = v
        end
        argument = args
    end
    ---@type UI.renderer.yesNoWithCheckbox.params
    argument = argument or {}
    argument.l10n = argument.l10n or commonData.l10nKey
    argument.checkBoxes = argument.checkBoxes or {}

    local l10n = core.l10n(argument.l10n)

    local checkBoxesLay = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content{

        },
    }

    for i, dt in ipairs(argument.checkBoxes) do
        if i > 1 then
            checkBoxesLay.content:add(interval(0, 8))
        end
        checkBoxesLay.content:add(
            checkBox{
                updateFunc = function ()
                    set(value)
                end,
                textSize = 16,
                text = l10n(dt.name or ""),
                checked = value[dt.key],
                event = function (checked, layout)
                    value[dt.key] = not value[dt.key]
                    set(value)
                end
            }
        )
    end

    local layout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content {
            checkBoxesLay,
        },
    }

    return checkBoxesLay
end)