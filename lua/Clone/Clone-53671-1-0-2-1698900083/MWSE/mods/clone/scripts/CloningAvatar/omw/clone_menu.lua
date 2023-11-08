
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local clone_menu = {


}local function renderListItem(text, font, selected)
    local resources = ui.content {
        {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textHeader,
            props = {
                text = "Health: 100",
                textSize = 10,
                arrange = ui.ALIGNMENT.Start,
                align = ui.ALIGNMENT.Center,
                size = util.vector2(480, 90),
            }
        },
        {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textHeader,
            props = {
                text = "Clone 1: Balmora, Guild of MagesGuild of MagesGuild of MagesGuild of MagesGuild of Mages",
                textSize = 10,
                arrange = ui.ALIGNMENT.End,
                align = ui.ALIGNMENT.Center,
                size = util.vector2(480, 90),
            }
        }
    }
    if not font then font = "white" end
    local itemIcon = nil
    local rowCountX = 1
    local template = I.MWUI.templates.boxTransparent
    return {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            selected = selected,
            text = text,
            size = util.vector2(400, 400),
        },
        events = {
            mousePress = async:callback(mouseClick),
            mouseMove = async:callback(mouseMove),
            focusLoss =  async:callback(focusLoss),
        },
        content = ui.content {
            {
                template = template,
                alignment = ui.ALIGNMENT.Center,
                props = {
                    anchor = util.vector2(0, -0.5),
                    size = util.vector2(400, 400),
                    autoSize = false
                },
                content = resources
            }
        }
    }
end
function clone_menu.createMenu()

       local  buttons = { "OK" }
    
    local contents = {}
    local table_contents = {} -- Table to hold the generated items
    for i = 1, 10, 1 do
        
        local content = {} -- Create a new table for each value of x

        table.insert(content, renderListItem("", nil, false))
        table.insert(contents, content)
    end
    if (#contents == 0) then
        error("No content items")
    end

    for index, contentx in ipairs(contents) do--Print the actual text lines
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center,
                autoSize = true
            }
        }
        table.insert(table_contents, item)
    end
end


return clone_menu