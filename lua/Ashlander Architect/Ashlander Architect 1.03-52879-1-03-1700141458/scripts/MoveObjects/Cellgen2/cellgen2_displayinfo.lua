local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local async = require("openmw.async")
local activeObjectTypes = {}
local myModData = storage.globalSection("MoveObjectsCellGen")
local settlementModData = storage.globalSection("AASettlements")
local cellGenStorage = storage.globalSection("AACellGen2")



local function getDoorDestinationStr(obj)
    local check = cellGenStorage:get("doorData")[obj.id]
    if check then
        local name = cellGenStorage:get("cellNames")[check.targetCell]
        if name then
            return name, check.targetCell
        end
        return check.targetCell, check.targetCell
    end
end
local renameWindow = nil
local uithing = nil


local doorToActivate = nil
local doorDelay = -1

local function playDoorSound(door)
    local doorSoundMap = cellGenStorage:get("doorSoundMap")
    local val = doorSoundMap[door.recordId]
    if not val then return end
    ambient.playSound(val)
end
local function renderItemBold(item, bold)
    local template = I.MWUI.templates.textHeader

    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = template,
                        props = {
                            text = item,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
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
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoice(itemList, currentItem, small)
    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 100
    if (small == true) then
        horizontal = ui.screenSize().x / 2 - 25
        vertical = vertical + ui.screenSize().y / 2 - 100
    else
    end
    local content = {}
    for _, item in ipairs(itemList) do
        if item == currentItem then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(0.5, 0.05),
            anchor = v2(0.5, 0.5),
            --position = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center
                }
            }
        }
    }
end
local currentText = ""
local buttonContext = ""
local doorID = ""
local function textChanged(firstField)
    currentText = (firstField)
end
local baseCell
local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function encode_base64(text)
    local result = {}
    local len = string.len(text)
    local index = 1

    local function char_to_byte(c)
        return string.byte(c) or 0
    end

    local function rshift(num, bits)
        return math.floor(num / (2 ^ bits))
    end

    local function band(num, bits)
        return num % (2 ^ bits)
    end

    while index <= len do
        local char1 = char_to_byte(string.sub(text, index, index))
        index = index + 1
        local char2 = char_to_byte(string.sub(text, index, index))
        index = index + 1
        local char3 = char_to_byte(string.sub(text, index, index))
        index = index + 1

        local enc1 = rshift(char1, 2)
        local enc2 = band(band(char1, 0x03) * 16 + rshift(char2 or 0, 4), 0xFF)
        local enc3 = band(band(char2 or 0, 0x0F) * 4 + rshift(char3 or 0, 6), 0xFF)
        local enc4 = band(char3 or 0, 0x3F)

        if not char2 then
            enc3, enc4 = 64, 64
        elseif not char3 then
            enc4 = 64
        end

        result[#result + 1] = string.sub(base64_chars, enc1 + 1, enc1 + 1)
        result[#result + 1] = string.sub(base64_chars, enc2 + 1, enc2 + 1)
        result[#result + 1] = string.sub(base64_chars, enc3 + 1, enc3 + 1)
        result[#result + 1] = string.sub(base64_chars, enc4 + 1, enc4 + 1)
    end

    return table.concat(result)
end
local function renderTextInput(textLines, data, editCallback, OKCallback, OKText)
    if (OKText == nil) then
        OKText = "OK"
    end
    print("render")
    local vertical = 50
    local horizontal = (ui.screenSize().x / 2) - 400

    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 25
    local vertical = vertical + ui.screenSize().y / 2 + 100
    --{createdCellData = createdCellData, structureGenData = structureGenData, id = structureID, offset = zOffset}

    local content = {}
    for _, text in ipairs(textLines) do
        table.insert(content, I.ZackUtilsUI_AA.textContent(text))
    end
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(data.id, nil,false)
    table.insert(content, textEdit)
    table.insert(content, I.ZackUtilsUI_AA.textContent("cellCache data:"))
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(data.createdCellData, nil,true)
    table.insert(content, textEdit)
    table.insert(content, I.ZackUtilsUI_AA.textContent("structuregen data:"))
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(data.structureGenData, nil,true)
    table.insert(content, textEdit)
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(data.offset, nil,false)
    table.insert(content, textEdit)
    local okButton = I.ZackUtilsUI_AA.boxedTextContent(OKText, async:callback(OKCallback))
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
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("cellRename2", { text = currentText, context = buttonContext, originalCell = baseCell })
    renameWindow:destroy()
    I.UI.setMode()
end
local function createWindow(data)
   -- I.UI.setMode('Interface', { windows = {} })
  --  return renderTextInput(
   ---     { "", "",
    --        "Here is the information about the created structure" }, data, textChanged, buttonClick)
end

local function destroyWindow()
    renameWindow:destory()
end
local function onInputAction(id)
    if id == input.ACTION.Activate then
        if (input.getControlSwitch(input.CONTROL_SWITCH.Controls) == false) then
            return
        end
        local doorSoundMap = cellGenStorage:get("doorSoundMap")
        local obj = I.ZackUtilsAA.getObjInCrosshairs().hitObject
        if (obj == nil) then
            return
        end
        if not doorSoundMap[obj.recordId] then
            return
        else

        end
        local doorDest, originalCell = getDoorDestinationStr(obj)
        local check = cellGenStorage:get("doorData")[obj.id]
        if not check then
            return
           -- error("Unable to find cell for door")
        end
        print(check.targetCell)
        if doorDest then
            if not input.isCtrlPressed() then
                playDoorSound(obj)
                core.sendGlobalEvent("doorCheck", obj)
            else
                baseCell = originalCell
                currentText = doorDest
                renameWindow = createWindow(currentText)
            end
        end
    end
end


return {
    interfaceName = "CellGen2_DisplayInfo",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
        encode_base64 = encode_base64,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if renameWindow ~= nil and data.newMode == nil then
                renameWindow:destroy()
            end
        end,
        ZHAC_createWindow = createWindow

    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
    }
}
