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
local config = require("scripts.MoveObjects.config")
local activeObjectTypes = {}
local myModData = storage.globalSection("MoveObjectsCellGen")
local settlementModData = storage.globalSection("AASettlements")
local cellGenStorage = storage.globalSection("AACellGen2")

local vfs = require("openmw.vfs")
local mycsvline
local isInDevMode = false
local createdWindow
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
    local horizontal = ui.layers[1].size.x / 2 - 100
    if (small == true) then
        horizontal = ui.layers[1].size.x / 2 - 25
        vertical = vertical + ui.layers[1].size.y / 2 - 100
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
local idText = ""
local nameText = ""
local function renderTextInput(textLines, data, editCallback, OKCallback, OKText)
    if (OKText == nil) then
        OKText = "OK"
    end
    print("render")
    local vertical = 50
    local horizontal = (ui.layers[1].size.x / 2) - 400

    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 25
    local vertical = vertical + ui.layers[1].size.y / 2 + 100
    --{createdCellData = createdCellData, structureGenData = structureGenData, id = structureID, offset = zOffset}

    local content = {}
    table.insert(content, I.DaisyUtilsUI_AA.textContent("Please Enter Structure ID:"))
    local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(data.id or "",
        async:callback(function(text) idText = text end), false)
    table.insert(content, textEdit)
    table.insert(content, I.DaisyUtilsUI_AA.textContent("Please Enter Structure Name:"))
    local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(data.name or "",
        async:callback(function(text) nameText = text end), false)
    table.insert(content, textEdit)

    for _, text in ipairs(textLines) do
        table.insert(content, I.DaisyUtilsUI_AA.textContent(text))
    end
    local genButton = I.DaisyUtilsUI_AA.boxedTextContent("Generate",
        async:callback(function() 
            if idText == "" then ui.showMessage("No ID provided!" ) return end
            if nameText == "" then ui.showMessage("No name provided!" ) return end
            core.sendGlobalEvent("getIDs", {id = idText, name = nameText}) end))
    table.insert(content, genButton)
    table.insert(content, I.DaisyUtilsUI_AA.textContent("cellCache data:"))
    local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(data.createdCellData or "", nil, true)
    table.insert(content, textEdit)
    table.insert(content, I.DaisyUtilsUI_AA.textContent("structuregen data:"))
    local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(data.structureGenData or "", nil, true)
    table.insert(content, textEdit)
    table.insert(content, I.DaisyUtilsUI_AA.textContent("YAML entry:"))

    local yamlBlock = ""

    if data.offset and data.id and not myyaml then
        -- Build a table representing the entry
        local entry = {
            EditorId     = data.id,
            Texture_Name = "noimage",
            Name         = data.name,
            Category     = "Prefab Buildings",
            Subcategory  = "Custom Buildings",
            Z_Offset     = tonumber(data.offset) or 0,
            XY_Offset    = 0,
            Object_Type  = "static",
            DefaultDist  = 2000,
            IntCount     = 24,
            requirements = {},
            flags        = {},
        }

        -- Convert to YAML manually (simple dump; or replace with lyaml.dump if available)
        yamlBlock = string.format([[
    - EditorId: %s
    Texture_Name: %s
    Name: %s
    Category: %s
    Subcategory: %s
    Z_Offset: %s
    XY_Offset: %s
    Object_Type: %s
    DefaultDist: %s
    IntCount: %s
    requirements: []
    flags: []
    ]], entry.EditorId, entry.Texture_Name, entry.Name, entry.Category,
    entry.Subcategory, entry.Z_Offset, entry.XY_Offset,
    entry.Object_Type, entry.DefaultDist, entry.IntCount)

        myyaml = yamlBlock
    end
   
local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(myyaml or "", nil, true)
table.insert(content, textEdit)

    -- if vfs.writeToFile then

    local cancelButton = I.DaisyUtilsUI_AA.boxedTextContent("Cancel", async:callback(OKCallback))
    table.insert(content, cancelButton)
    local okButton = I.DaisyUtilsUI_AA.boxedTextContent("Save", async:callback(function()
        if not createdWindow then return end
        createdWindow:destroy()
        createdWindow = nil
        core.sendGlobalEvent("saveDataGen", { csvline = mycsvline })
        ui.showMessage("Saved Data")
    end))
    table.insert(content, okButton)
    -- else
    --     local okButton = I.DaisyUtilsUI_AA.boxedTextContent("Done", async:callback(OKCallback))
    --     table.insert(content, okButton)

    --     end
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
    if not createdWindow then return end
    createdWindow:destroy()
    createdWindow = nil
end
local function createWindow(data)
    if createdWindow then
        createdWindow:destroy()
    end
    I.UI.setMode('Interface', { windows = {} })
    mycsvline = nil
    createdWindow = renderTextInput(
        { "", "",
            "Here is the information about the created structure" }, data, textChanged, buttonClick)
end

local function destroyWindow()
    if not createdWindow then return end
    createdWindow:destory()
end
local function hasWindow()
    if not createdWindow then return false end
    return true
end
return {
    interfaceName = "CellGen2_DisplayInfo",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
        encode_base64 = encode_base64,
        hasWindow = hasWindow,
        isInDevMode = function() return isInDevMode end,
        setDevMode = function(state) isInDevMode = state end
    },
    eventHandlers = {
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if createdWindow ~= nil and data.newMode == nil then
                createdWindow:destroy()
            end
        end,
        ZHAC_createWindow_Info = createWindow

    },
    engineHandlers = {
        onFrame = onFrame,
        onSave = onSave,
    }
}
