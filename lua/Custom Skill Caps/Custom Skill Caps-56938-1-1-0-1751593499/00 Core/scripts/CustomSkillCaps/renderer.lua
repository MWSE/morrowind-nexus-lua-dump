local async = require('openmw.async')local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')

local info = require('scripts.CustomSkillCaps.info')

if core.API_REVISION < info.minApiVersion then
    return
end

local myui = require('scripts.' .. info.name .. '.myui')

-- Custom disable function
local function disable(disabled, layout, darken, collapse)
    --Collapsible renderers would be nice, but currently resizing stuff breaks the settings page
    collapse = false
    if disabled then
        local template = myui.templates.disabled
        if darken then
            template = I.MWUI.templates.disabled
        end
        local disabledContent = nil
        if not collapse then 
            disabledContent = ui.content {
                    layout
                }
        end
        return {
            template = template,
            content = disabledContent
        }
    else
        return layout
    end
end

-- Custom selection renderer
I.Settings.registerRenderer(info.name .. 'Select', function(value, set, argument)
    local L = core.l10n(argument.l10n)
    local optionsContent = ui.content {}
    for _, item in pairs(argument.items) do
        local itemColor = nil
        if item == value then
            itemColor = myui.interactiveTextColors.active.default
        end
        local itemLayout = {
            type = ui.TYPE.Container,
            template = myui.padding(0, 2),
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = L(item), textColor = itemColor, textAlignV = ui.ALIGNMENT.Center},
                    events = {
                        mouseClick = async:callback(function(mouseEvent, data)
                            set(item)
                        end)
                    }
                }
            }
        }
        optionsContent:add(itemLayout)
    end
    local rendererLayout = {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.box,
        props = {visible = true},
        content = ui.content {
            {
                type = ui.TYPE.Container,
                template = myui.padding(6,2),
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {arrange = ui.ALIGNMENT.Center},
                        content = optionsContent
                    }
                }
            }
        }
    }
    return disable(argument.disabled, rendererLayout, true, true)
end)