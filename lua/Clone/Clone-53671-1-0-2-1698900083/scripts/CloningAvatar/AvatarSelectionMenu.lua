local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local self = require("openmw.self")
local cloneData
--usage:
local playerSettings = storage.playerSection("MessageBoxData")
local winCreated
local selMenu = {}

local winName
local textSize = 20
local menuOptions
local function addMenuOption(id, text, selected)
    local val = { id = id, text = text, selected = selected or false, highlighted = false }
    table.insert(menuOptions, val)
    return val
end
local function padString(str, length)
    if true == true then
        return str
    end
    local strLength = string.len(str)

    if strLength >= length then
        return str -- No need to pad if the string is already longer or equal to the desired length
    end

    local padding = length - strLength                   -- Calculate the number of spaces needed
    local paddedString = str .. string.rep(" ", padding) -- Concatenate the string with the required number of spaces

    return paddedString
end
local function focusLoss()

end
local function textContent(text, template, color)
    local tsize = textSize
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
local function boxedContainer(element)
    return {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- size = util.vector2(400, 400),
        },
        content =ui.content{element}
    }
end
local function mouseClick(mouseEvent, data)
    local id = data.props.id
    for key, value in ipairs(menuOptions) do
        if value.id == id then
            if menuOptions[key].selected == true then
                core.sendGlobalEvent("SwitchToClone", id)
                ui.showMessage("Clicked again" .. id)
                I.UI.setMode(nil)
                winCreated:destroy()
                return
            end
            menuOptions[key].selected = true
            print("Selected " .. id)
        else
            menuOptions[key].selected = false
        end
    end
    print(id)
    selMenu.showMessageBox()
    --I.UI.setMode(nil)
    --ui.showMessage("Clicked " .. data.props.text)
    -- self:sendEvent("ButtonClicked",{name = winName,text = data.props.text})
end
local function mouseMove(mouseEvent, data)
    --make the button lit up when moused over
    local changed = false
    local id = data.props.id
    for key, value in ipairs(menuOptions) do
        if value.id == id and menuOptions[key].highlighted == false then
            menuOptions[key].highlighted = true
            changed = true
        elseif value.highlighted == true then
            menuOptions[key].highlighted = false
            changed = true
        end
    end
    if changed then
        selMenu.showMessageBox()
    end
end
local function renderListItem(id)
    local data = menuOptions[id]
    local text = data.text
    local texttemplate = I.MWUI.templates.textHeader
    if not data.highlighted then
        texttemplate = I.MWUI.templates.textNormal
    end
    local resources = ui.content {
        {
            type = ui.TYPE.Text,
            template = texttemplate,
            props = {
                text = text,
                id = menuOptions[id].id,
                textSize = textSize,
                arrange = ui.ALIGNMENT.End,
                align = ui.ALIGNMENT.Center,
                --size = util.vector2(1480, 90),
            }
        }
    }
    local itemIcon = nil
    local rowCountX = 1
    local template = I.MWUI.templates.boxTransparent
    if not data.selected then
        template = I.MWUI.templates.padding
    end
    return {
        type = ui.TYPE.Container,
        props = {
            autoSize = false,
            selected = data.selected,
            text = text,
            id = menuOptions[id].id,
            -- size = util.vector2(400, 400),
        },
        events = {
            mousePress = async:callback(mouseClick),
            --  mouseMove = async:callback(mouseMove),
            --  focusLoss = async:callback(focusLoss),
        },
        content = ui.content {
            {
                events = {
                    -- mousePress = async:callback(mouseClick),
                    ----     mouseMove = async:callback(mouseMove),
                    --    focusLoss = async:callback(focusLoss),
                },
                template = template,
                alignment = ui.ALIGNMENT.Center,
                props = {
                    anchor = util.vector2(0, -0.5),
                    --  size = util.vector2(400, 400),
                    autoSize = false,
                    id = menuOptions[id].id,
                },
                content = resources
            },
        }
    }
end
local staticList = { "Health: 100", "Name: Yes" }
function selMenu.showMessageBox(ncloneData, textLines, buttons)
    if ncloneData then
        cloneData = ncloneData
        menuOptions = nil
    end
    if winCreated then
        winCreated:destroy()
    end
    if not buttons then
        buttons = { "OK" }
    end
    local contents = {}
    local contents2 = {}
    local table_contents = {}  -- Table to hold the generated items
    local table_contents2 = {} -- Table to hold the generated items
    local selectedMenuOption
    if not menuOptions then
        menuOptions = {}
        for index, value in ipairs(cloneData) do
            local selected = false
            if value.realId == self.id then
                selected = true
                selectedMenuOption = value.id
            end
            local mopt = addMenuOption(value.id, value.name, selected)
            local content = {} -- Create a new table for each value of x

            table.insert(content, renderListItem(mopt.id))
            table.insert(contents, content)
        end
    else
        for key, value in ipairs(menuOptions) do
            local mopt = value
            local content = {} -- Create a new table for each value of x
            if value.selected then
                selectedMenuOption = value.id
            end
            table.insert(content, renderListItem(mopt.id))
            table.insert(contents, content)
        end
    end
    if (#contents == 0) then
        error("No content items")
    end
    for index, value in ipairs(cloneData) do
        if value.id == selectedMenuOption then
            for key, valuex in pairs(value.info) do

                local mopt = valuex
                local content = {} -- Create a new table for each value of x
        
                table.insert(content, textContent(valuex))
                table.insert(contents2, content)
            end
        end
    end
    for key, value in ipairs(staticList) do
    end

    for index, contentx in ipairs(contents) do --Print the actual text lines
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

    for index, contentx in ipairs(contents2) do --Print the actual text lines
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
        table.insert(table_contents2, item)
    end


    local itemK = { --This includes the top text, and the botton buttons.
        type = ui.TYPE.Flex,
        content = ui.content(table_contents),
        props = {
            -- size = util.vector2(450, 300),
            horizontal = false,
            vertical = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        },
    }
    itemK = boxedContainer(itemK)
    local itemB = { --This includes the top text, and the botton buttons.
        type = ui.TYPE.Flex,
        content = ui.content(table_contents2),
        props = {
            --  size = util.vector2(450, 300),
            horizontal = false,
            vertical = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        },
    }
    local headerMenu = { --This includes the top text, and the botton buttons.
        type = ui.TYPE.Flex,
        content = ui.content({ textContent("Clone Selection") }),
        props = {
            --  size = util.vector2(450, 300),
            horizontal = true,
            vertical = false,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        },
    }
    local horizontalMenu = { --This includes the top text, and the botton buttons.
        type = ui.TYPE.Flex,
        content = ui.content({ itemK, itemB }),
        props = {
            --  size = util.vector2(450, 300),
            horizontal = true,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
            autoSize = true
        },
    }
    local verticalMenu = { --This includes the top text, and the botton buttons.
        type = ui.TYPE.Flex,
        content = ui.content({ headerMenu, horizontalMenu }),
        props = {
            --  size = util.vector2(450, 300),
            horizontal = false,
            vertical = false,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        },
    }
    I.UI.setMode('Interface', { windows = {} })
    local xui = ui.create { --This is the window itself.
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        events = {
            focusLoss = async:callback(focusLoss),
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
            vertical = true,
        },
        content = ui.content({ verticalMenu })
    }
    xui.layout.props.xui = xui
    winCreated = xui
    --I.ZU_UIManager.storeUI("MessageBox", xui)
    return xui
end

return selMenu
