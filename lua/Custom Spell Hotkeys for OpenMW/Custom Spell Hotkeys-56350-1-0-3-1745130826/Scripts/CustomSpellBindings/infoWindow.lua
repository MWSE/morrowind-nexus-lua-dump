local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local _window = nil

local function closeWindow()
    if _window ~= nil then
        _window:destroy()
        _window = nil
    end
end

local function renderTextEntry(text)
    return {
        type = ui.TYPE.Container,
        content = ui.content({
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                props = {
                    autoSize = false,
                },
                content = ui.content({
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = 18,
                            textColor = I.MWUI.templates.textNormal.props.textColor,
                            arrange = ui.ALIGNMENT.Center,
                        }
                    }
                })
            }
        })
    }
end

local renderInfoWindow = function()
    local content = {}

    table.insert(content, renderTextEntry('Left clicking an entry will select it'))
    
    table.insert(content, renderTextEntry('Up Arrow or W: select previous binding'))
    table.insert(content, renderTextEntry('Down Arrow or S: select next binding'))
    table.insert(content, renderTextEntry('Delete: delete selected binding'))
    table.insert(content, renderTextEntry('Escape: resume game'))

    _window = ui.create({
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            anchor = util.vector2(0, 0),
            relativePosition = util.vector2(0, 0),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
        },
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Start,
                }
            }
        })
    })
end

return {
    renderInfoWindow = renderInfoWindow,
    closeWindow = closeWindow
}