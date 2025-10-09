local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local contextMenu = {}
local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local async = require("openmw.async")
local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end
local selectedIndex = 1
contextMenu.windowPos = v2(0.5, 0.5)
contextMenu.openedUI = nil
local listItems = {}
local destroyOnClick = true
local clickFunction
local function calculateTextScale()
    local screenSize = ui.layers[1].size
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    local textScaleSetting = 1
    return scale * textScaleSetting
end
local function mouseMove(one, data)
    local index = data.index
    if selectedIndex ~= index then
        selectedIndex = index
        contextMenu.renderContextMenu()
    end
end
local function click(one, data)
    local index = data.index
    local text = data.text
    local id = data.id
    if clickFunction then
        clickFunction(text, index, id)
    end
    if destroyOnClick then
        contextMenu.openedUI:destroy()
        contextMenu.openedUI = nil
    end
end
local function keyPress(keyEvent, data)
    if not contextMenu.openedUI then return end

    local index = selectedIndex
    if keyEvent.code == input.KEY.UpArrow then
        selectedIndex = index - 1
        contextMenu.renderContextMenu()
    elseif keyEvent.code == input.KEY.DownArrow then
        selectedIndex = index + 1
        contextMenu.renderContextMenu()
    elseif keyEvent.code == input.KEY.Enter then
       
        click(nil,{index = selectedIndex,text = listItems[selectedIndex].text,id = listItems[selectedIndex].id})
    end
end
local function renderItem(item, index, boxed)
    local itemTemplate
    local text
    local id
    if type(item) == "string" then
        text = item
        id = item
    elseif type(item) == "table" then
        text = item.text
        id = item.id
    end
    if boxed then
        itemTemplate = I.MWUI.templates.box
    else
        itemTemplate = I.MWUI.templates.padding
    end

    return {
        type = ui.TYPE.Container,
        index = index,
        text = text,
        id = id,
        events = { mouseMove = async:callback(mouseMove), mousePress = async:callback(click), keyPress = async:callback(keyPress), },
        content = ui.content {
            {
                template = itemTemplate,
                alignment = ui.ALIGNMENT.Center,
                index = index,
                text = text,
                id = id,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        index = index,
                        text = text,
                        id = id,
                        props = {
                            text = text,
                            textSize = (20) * calculateTextScale(), -- Adjust the textSize based on whether it's boxed or not
                            arrange = ui.ALIGNMENT.Center
                        },
                        events = { mouseMove = async:callback(mouseMove), mousePress = async:callback(click) },
                    }
                }
            }
        }
    }
end

function contextMenu.renderContextMenu(items, fselectedIndex, relativePosition)
    if items then
       -- listItems = items
    end
    if contextMenu.openedUI then
        contextMenu.openedUI:destroy()
    else
        I.UI.setMode("Interface", { windows = {} })
    end
    if relativePosition then
        contextMenu.windowPos = relativePosition
    end
    if fselectedIndex then
        selectedIndex = fselectedIndex
    end
    local content = {}
    for index, item in ipairs(listItems) do
        local itemLayout = renderItem(item, index, index == selectedIndex)
        table.insert(content, itemLayout)
    end
    --table.insert(content, renderItemBoxed("OK"))
    contextMenu.openedUI = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            relativePosition = contextMenu.windowPos,
        },
        events = { keyPress = async:callback(keyPress), },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Center,
                }
            }
        }
    }
    return contextMenu.openedUI
end

function contextMenu.passKeyInput(key)
    keyPress(key)
end

function contextMenu.createContextMenu(items, clickCallBack, options)
    clickFunction = clickCallBack
    listItems = {}
    for index, value in ipairs(items) do
        local text
        local id
        if type(value) == "string" then
            text = value
            id = value
        elseif type(value) == "table" then
            text = value.text
            id = value.id
        end
        table.insert(listItems,{text = text,id = id})
    end
    if not options then
        options = {}
    end
    contextMenu.windowPos = options.windowPos or util.vector2(0.5, 0.5)
    selectedIndex = options.selectedIndex or 1
    contextMenu.renderContextMenu()
end

return contextMenu
