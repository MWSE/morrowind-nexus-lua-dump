local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local self = require("openmw.self")
--usage: smenu = require("scripts.DaisyUtils.MessageBox")
local playerSettings = storage.playerSection("MessageBoxData")
local winCreated
local winName 
local hoveringText
local hoverTextTimer = 0

local function onUpdate(dt)
  if hoverTextTimer > 0 then
    hoverTextTimer = hoverTextTimer - .1
    if hoverTextTimer <= 0 then
      hoveringText = nil
    end
  end
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

local function textContent(text, template, color)
    --local tsize = 16
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
    if text == "Immersive Travel" then template = I.MWUI.templates.textHeader end

    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            --textColor = color,
        }
    }
end
local function mouseClick(mouseEvent, data)
    if not data.props.selected then return end
    winCreated:destroy()
    I.UI.setMode(nil)
    if winName == "IFT" then self:sendEvent("Rss_DestinationSelected",{text = data.props.text}) end
end

local function mouseMove(mouseEvent,data)
  
end

local function focusGain(text) 
  if (text ~= nil) then 
    hoveringText = text 
    hoverTextTimer = 5
  end
end

local function focusLoss()
  
end

local function renderListItem(text, font, selected)
    
    font = nil
    if (hoveringText == text) then 
      font = "white"
    end
    
    local resources = ui.content {
        textContent(padString(text, 30), nil, font)
    }
    if not font then font = "white" end
    local itemIcon = nil
    local rowCountX = 1
    local template = I.MWUI.templates.padding
    if not selected then
        template = I.MWUI.templates.padding
    end
    
    local events = {}
    if (selected) then
      events = {
          mousePress = async:callback(mouseClick),
          mouseMove = async:callback(mouseMove),
          focusGain =  async:callback(function() focusGain(text) end),
          focusLoss =  async:callback(function() focusLoss() end),
      }
  end
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(30, 30 * rowCountX),
            autoSize = true,
            selected = selected,
            text = text,
        },
        events = events,
        content = ui.content {
            {
                template = template,
                alignment = ui.ALIGNMENT.Center,
                content = resources
            }
        }
    }
end

local function hideMessageBox(data) 
  if winCreated then 
    winCreated:destroy() 
    winCreated = nil
    --I.UI.setMode(nil)  -- RE-ENABLE THIS LINE IF YOU NEED TO SHOW THE MESSAGE BOX BY ITSELF WITHOUT THE TRAVEL SCREEN
  end
end

local function showMessageBox(windowName, textLines, buttons)
    hideMessageBox({})
    if not buttons then
        buttons = { "OK" }
    end
    local contents = {}
    local table_contents = {} -- Table to hold the generated items
    for index, text in ipairs(textLines) do
        local content = {} -- Create a new table for each value of x

        table.insert(content, renderListItem(text, nil, false))
        table.insert(contents, content)
    end
    local buttonContent = {} -- Create a new table for each value of x
    for index, text in ipairs(buttons) do
        table.insert(buttonContent, renderListItem(text, nil, true))
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
                autoSize = true,
            }
        }
        table.insert(table_contents, item)
    end

    local itemx = {--This contains the buttons, so that they can be arranged at the bottom
        type = ui.TYPE.Flex,
        content = ui.content(buttonContent),
        props = {
            --size = util.vector2(450, 30),
            vertical = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true
        }
    }
    table.insert(table_contents, itemx)
    
    local bottomPadding = {
        type = ui.TYPE.Flex,
        content = ui.content({renderListItem("", nil, false)}),
    }
    table.insert(table_contents, bottomPadding)

    local itemK = {--This includes the top text, and the botton buttons.
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
    --I.UI.setMode('Interface', { windows = {} }) -- RE-ENABLE THIS LINE IF YOU NEED TO SHOW THE MESSAGE BOX BY ITSELF WITHOUT THE TRAVEL SCREEN
    local xui = ui.create {--This is the window itself.
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        events = {
            focusLoss = async:callback(focusLoss),
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.25 - (#buttons - 4) * .01),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
            vertical = true,
        },
        content = ui.content({itemK})
    }
    xui.layout.props.xui = xui
    winCreated = xui
    winName = windowName
    --I.ZU_UIManager.storeUI("MessageBox", xui)
    return xui
end

local function showMessageBoxEvent(data)
  showMessageBox(data.winName, data.textLines, data.buttons)
end


return {
  engineHandlers = {
      onUpdate = onUpdate,
  },
  eventHandlers = { 
    Rss_ShowMessageBoxEvent = showMessageBoxEvent,
    Rss_HideMessageBox = hideMessageBox,
  },
}
