local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
--usage: smenu = require("scripts.zackutils.SelectMenu")

local function padString(str, length)
    local strLength = string.len(str)

    if strLength >= length then
        return str -- No need to pad if the string is already longer or equal to the desired length
    end

    local padding = length - strLength                   -- Calculate the number of spaces needed
    local paddedString = str .. string.rep(" ", padding) -- Concatenate the string with the required number of spaces

    return paddedString
end
local function textContent(text, template, color)
    local tsize = 15
    if not color then
        template = I.MWUI.templates.textNormal
        color = template.props.textColor
    elseif color == "red" then
        template = I.MWUI.templates.textNormal
        color = util.color.rgba(5, 0, 0, 1)
    else
        template = I.MWUI.templates.textHeader
        color = template.props.textColor
        --  tsize = 20
    end

    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = tsize,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            textColor = color
        }
    }

end
local function renderListItem(text,font,selected)

    local resources = ui.content {
        textContent(padString(text, 30), nil, font)
    }
    if not font then font = "white" end
    local itemIcon = nil
    local rowCountX = 1
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(30, 30 * rowCountX),
            autoSize = false,
            selected = false,
        },
        events = {
            mousePress = async:callback(mouseClick),
            -- mouseRelease = async:callback(clickMeStop),
            --   mouseMove = async:callback(mouseMove)
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = resources
            }
        }
    }
end
local function drawMenuList(itemList)
    local contents = {}
    for index, text in ipairs(itemList) do
        local content = {} -- Create a new table for each value of x
   
        table.insert(content, renderListItem(text,nil,false))
        table.insert(contents,content)
    end
    local table_contents = {} -- Table to hold the generated items
    if (#contents == 0) then
        error("No content items")
    end

    for index, contentx in ipairs(contents) do
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                size = util.vector2(450, 30),
                position = util.vector2(0.8, 25 * (index - 1)),
                vertical = true,
                arrange = ui.ALIGNMENT.Start,
                autoSize = false
            },
            external = {
                -- grow = iconsize + 10
            }
        }
        table.insert(table_contents, item)
    end
    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5,0.5),
            size = util.vector2(1, 1),
            relativePosition = util.vector2(0.5,0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = false,
            vertical = true,
        },
        content = ui.content(table_contents)
    }
end

return { drawMenuList = drawMenuList }
