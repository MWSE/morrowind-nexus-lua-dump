local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local vfs = require('openmw.vfs')

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local acti = require("openmw.interfaces").Activation
local playerSelected
local iconsize = 4
--local calculateTextScale() = 0.8
local Actor = require("openmw.types").Actor

local playerSettings = storage.playerSection("SettingsAshlanderArchitect")

local function imageContent(resource, size)
    if (size == nil) then
        size = iconsize
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(ui.screenSize().y / size, ui.screenSize().y / size),
            relativeSize = util.vector2(0.2, 0.2)
        }
    }
end



local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end

local function calculateTextScale()
    local screenSize = ui.screenSize()
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    local textScaleSetting = playerSettings:get("textScale") or 1
    return scale * textScaleSetting
end
local function textContent(text, template, color)
    if (template == nil) then
        template = I.MWUI.templates.textHeader
    else
        if (color ~= nil) then
            template.props.textColor = color
        end
    end
    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = 20 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function textContentLeft(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            relativePosition = v2(0.5, 0.5),
            text = tostring(text),
            textSize = 10 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function paddedTextContent(text)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {
                    anchor = util.vector2(0, -0.5)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBoxed(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBold(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function renderTextInput(textLines, existingText, editCallback, OKCallback, OKText)
    if (OKText == nil) then
        OKText = "OK"
    end
    print("render")
    local vertical = 50
    local horizontal = (ui.screenSize().x / 2) - 400

    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 25
    local vertical = vertical + ui.screenSize().y / 2 + 100

    local content = {}
    for _, text in ipairs(textLines) do
        table.insert(content, I.ZackUtilsUI_AA.textContent(text))
    end
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(existingText, async:callback(editCallback))
    local okButton = I.ZackUtilsUI_AA.boxedTextContent(OKText, async:callback(OKCallback))
    table.insert(content, textEdit)
    table.insert(content, okButton)

    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            --   position = v2(horizontal, vertical),
            vertical = false,
            relativeSize = util.vector2(0.1, 0.1),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(400, 10),
                }
            }
        }
    }
end
local function renderItem(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBBoxed(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoiceReal(itemList, selectedItem, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        if (item == selectedItem) then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    table.insert(content, renderItemBoxed("OK"))
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local RecordStorage = storage.globalSection("RecordStorage")
local function convertStringToTable(inputString)
    local dataTable = {}
    local entryCount = 0

    for entry in string.gmatch(inputString, "([^|]+)") do
        local itemID, count = string.match(entry, "(.-);(.+)")
        if not itemID then
            return
        end
        local createdRecords = RecordStorage:get("createdRecords")

        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        count = tonumber(count)

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }
        if (dataEntry.itemID ~= nil) then
            table.insert(dataTable, dataEntry)
            entryCount = entryCount + 1
            --   print(itemID)
        end
    end

    -- Handle single item case
    if entryCount == 0 then
        local itemID, count = string.match(inputString, "(.-);(.+)")
        local createdRecords = RecordStorage:get("createdRecords")

        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        count = tonumber(count)

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }

        table.insert(dataTable, dataEntry)
    end

    return dataTable
end
local auxUi = require('openmw_aux.ui')
local function renderIcon(icon, text, red)
    local iconsize = 32
    local template = auxUi.deepLayoutCopy(I.MWUI.templates.textHeader)
    local color = nil
    if (red) then
        color = ui.CONSOLE_COLOR.Error
    end
    template.textSize = 2
    local iconResource = ui.texture({ path = icon })
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(iconsize, iconsize)
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    imageContent(iconResource, iconsize),
                    textContent(tostring(text), template, color)
                }
            }
        }
    }
end
local function renderObjectRequirements(tableItem, horizontal, vertical, size)
    if not tableItem then return end


    if not tableItem.itemRequired then return end

    if (tableItem.itemRequired == nil or tableItem.itemRequired == "" or tableItem.itemRequired == " ") then
        --print("Item not found" .. tableItem.Static_ID)
        return
    else
    end
    local data = convertStringToTable(tableItem.itemRequired)
    if not data then return end
    local content = {}
    local createdRecords = RecordStorage:get("createdRecords")
    for index, dataob in ipairs(data) do
        local obRecord = nil
        local itemID = dataob.itemID
        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        obRecord = types.Miscellaneous.record(itemID)
        --  local resource = ui.texture { -- texture in the top left corner of the atlas
        -- path = obRecord.icon
        -- }
        local carriedCount = types.Actor.inventory(self):countOf(dataob.itemID)

        local itemLayout = renderIcon(obRecord.icon, dataob.count, carriedCount < dataob.count)
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            vertical = false,
            horizontal = true
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = false,
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end
local function renderItemChoice(itemList, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        local itemLayout = renderItem(item)
        itemLayout.template = I.MWUI.templates.padding
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local scale = 1.2

local function renderTextWithBox(tableItem, horizontal, vertical, size)
    if (size == nil) then
        size = 8 * scale
    else
        size = size * scale
    end


    local content = {}
    local itemLayout = renderItemBold(tableItem.Name)
    table.insert(content, itemLayout)
    local resource
    if vfs.fileExists('textures/ashlanderarchitect/' .. tableItem.Static_ID .. ".jpg") then
        resource = ui.texture { -- texture in the top left corner of the atlas
            path = 'textures/ashlanderarchitect/' .. tableItem.Static_ID .. ".jpg"
        }
    elseif vfs.fileExists('textures/ashlanderarchitect/' .. tableItem.Texture_Name .. ".jpg") then
        resource = ui.texture { -- texture in the top left corner of the atlas
            path = 'textures/ashlanderarchitect/' .. tableItem.Texture_Name .. ".jpg"
        }
    elseif vfs.fileExists('textures/ashlanderarchitect/' .. tableItem.Texture_Name .. ".png") then
        resource = ui.texture { -- texture in the top left corner of the atlas
            path = 'textures/ashlanderarchitect/' .. tableItem.Texture_Name .. ".png"
        }
    else
        resource = ui.texture { -- texture in the top left corner of the atlas
            path = 'textures/ashlanderarchitect/' .. "cs-icon" .. ".png"
        }

    end
    table.insert(content, imageContent(resource, size))
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content(content)
    }
end

local function boxedTextContent(text, callback, textScale, name)
    if textScale == nil then
        textScale = 1
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        events = { mouseClick = callback },
                        props = {
                            text = text,
                            textSize = (15 * calculateTextScale()) * textScale,
                            align = ui.ALIGNMENT.Center,
                            name = name,
                        }
                    }
                }
            }
        }
    }
end
local function boxedTextEditContent(text, callback, isMultiline)
    local multiLine = false
    local height = 30
    if isMultiline then
        multiLine = true
        height = 200
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5),
                    size = util.vector2(400, 10),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.TextEdit,
                        template = I.MWUI.templates.textEditLine,
                        events = { textChanged = callback },
                        props = {
                            text = text,
                            size = util.vector2(1400, height),
                            textAlignH = 15,
                            textSize = 15 * calculateTextScale(),
                            align = ui.ALIGNMENT.Center,
                            multiline = multiLine,
                        }
                    }
                }
            }
        }
    }
end
return {
    interfaceName = "ZackUtilsUI_AA",
    interface = {
        version = 1,
        imageContent = imageContent,
        textContent = textContent,
        textContentLeft = textContentLeft,
        paddedTextContent = paddedTextContent,
        boxedTextContent = boxedTextContent,
        hoverOne = hoverOne,
        hoverTwo = hoverTwo,
        hoverNone = hoverNone,
        boxedTextEditContent = boxedTextEditContent,
        renderItemChoice = renderItemChoice,
        renderTextWithBox = renderTextWithBox,
        renderTextInput = renderTextInput,
        renderTravelOptions = renderTravelOptions,
        renderItemChoiceReal = renderItemChoiceReal,
        renderObjectRequirements = renderObjectRequirements,
    },
}
