local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local async = require("openmw.async")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local ambient = require('openmw.ambient')

local function onFrame(dt)

end

if (core.API_REVISION < 51) then
    I.Settings.registerPage {
        key = "SettingsCorporealCarryableContainers",
        l10n = "AshlanderArchitect",
        name = "CC Containers",
        description = "Corporeal Carryable Containers requires a newer version of OpenMW. Please update."
    }
    error("Corporeal Carryable Containers requires a newer version of OpenMW. Please update.")
end
local oldName = nil
I.Settings.registerPage {
    key = "SettingsCorporealCarryableContainers",
    l10n = "AshlanderArchitect",
    name = "CC Containers",
    description = "Corporeal Carryable Containers"
}

I.Settings.registerGroup {
    key = "SettingsCorporealCarryableContainers",
    page = "SettingsCorporealCarryableContainers",
    l10n = "AshlanderArchitect",
    name = "Corporeal Carryable Containers",
    description = "Corporeal Carryable Containers",
    permanentStorage = false,
    settings = {
        {
            key = "UseBaseWeight",
            renderer = "checkbox",
            name = "Include Base Weight",
            description =
            "If enabled, Carryable container will have the item's base weight(the weight of the container itself) included in the weight calculation.",

            default = true
        },
        {
            key = "extractGold",
            renderer = "checkbox",
            name = "Extract Gold",
            description =
            "If enabled, any gold in containers when be moved into the player's inventory when talking to someone. The amount that was in the container will be returned when the game is unpaused, if the player still has that much. If the player already had gold in their inventory, that will be used last.",

            default = true
        },
        {
            key = "emergencyItemExtraction",
            renderer = "checkbox",
            name = "Emergency Item Extraction",
            description =
            "Toggle this to move all items from the item storage to your inventory. This is intended for use in the case where the mod is broken or corrupted. Do not click this unless you are sure it is the only option.",

            default = true
        },
    }
}

local playerSettings = storage.playerSection("SettingsCorporealCarryableContainers")
playerSettings:subscribe(async:callback(function(section, key)
    if key then
        if (key == "UseBaseWeight") then
            core.sendGlobalEvent("updateUBW", playerSettings:get("UseBaseWeight"))
        elseif (key == "extractGold") then
            core.sendGlobalEvent("updateExtractGold", playerSettings:get("extractGold"))
        elseif key == "emergencyItemExtraction" then
            core.sendGlobalEvent("emergencyItemExtraction")
        end
    end
end))
local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end
local function calculateTextScale()
    local screenSize = ui.screenSize()
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    return scale
end
local function boxedTextEditContent(text, callback)
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
                            size = util.vector2(400, 30),
                            textAlignH = 15,
                            textSize = 25 * calculateTextScale(),
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function textContent(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = tostring(text),
            textSize = 10 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function boxedTextContent(text, callback)
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
                            textSize = 15 * calculateTextScale(),
                            align = ui.ALIGNMENT.Center
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
    local vertical = 50
    local horizontal = (ui.screenSize().x / 2) - 400

    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 25
    local vertical = vertical + ui.screenSize().y / 2 + 100

    local content = {}
    for _, text in ipairs(textLines) do
        table.insert(content, textContent(text))
    end
    local textEdit = boxedTextEditContent(existingText, async:callback(editCallback))
    local okButton = boxedTextContent(OKText, async:callback(OKCallback))
    table.insert(content, textEdit)
    table.insert(content, okButton)

    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            position = util.vector2(horizontal, vertical),
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
local renameWin = nil
local winText = ""
local function textChanged(tx)
    winText = tx
end
local activeObject = nil
local function buttonClick()
    renameWin:destroy()
    if (oldName == winText or winText == "") then
        return
    end
    core.sendGlobalEvent("renameContainer", { newName = winText, object = activeObject })
    ui.showMessage("You renamed the container.")
    I.UI.setMode()
    activeObject = nil
    winText = ""
end
local function createWindow(text)
    return renderTextInput(
        { "", "",
            "What would you like this container to be named?" }, text, textChanged, buttonClick)
end

local function CCCstartRename(data)
    local object = data.object
    I.UI.setMode("Interface", { windows = {} })
    local cccData = data.data
    activeObject = object
    local currentName = data.currentName
    oldName = currentName
    winText = currentName
    renameWin = createWindow(currentName)
end
local wasSneaking = false
local function onUpdate(dt)
    local isSneaking = self.controls.sneak
    if (isSneaking ~= wasSneaking) then
        core.sendGlobalEvent("CCCSneakUpdate", isSneaking)
    end
    wasSneaking = isSneaking
end
local function splitString(inputString)
    local result = {}
    local currentItem = ""
    local insideQuotes = false

    for i = 1, #inputString do
        local char = inputString:sub(i, i)

        if char == "'" or char == '"' then
            insideQuotes = not insideQuotes
            currentItem = currentItem .. char
        elseif char == " " and not insideQuotes then
            if currentItem ~= "" then
                table.insert(result, currentItem)
                currentItem = ""
            end
        else
            currentItem = currentItem .. char
        end
    end

    if currentItem ~= "" then
        table.insert(result, currentItem)
    end

    -- Check if the last item is a number and remove it along with the space in front
    local lastItem = result[#result]
    local lastItemNumber = tonumber(lastItem)
    local wholeStringMinusLastNumber = inputString
    if lastItemNumber then
        table.remove(result)
        wholeStringMinusLastNumber = inputString:sub(1, #inputString - #lastItem - 1)
    end

    return result, lastItemNumber, wholeStringMinusLastNumber
end
local function onConsoleCommand(mode, cmd, selectedObject)
    local cmdSpl = splitString(cmd)
    if (cmdSpl[1] == "renamec") then
        local name = string.sub(cmd, string.len(cmdSpl[1]) + 2) --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it.
        core.sendGlobalEvent("renameContainer", { newName = name, object = selectedObject })
    end
end
local openedContainer
local function openContainerInv(obj)
    I.UI.setMode("Container", { target = obj })
    openedContainer = obj
end
return {
    engineHandlers = { onConsoleCommand = onConsoleCommand, onConsume = onConsume, onUpdate = onUpdate },
    eventHandlers = {
        CCCstartRename   = CCCstartRename,
        openContainerInv = openContainerInv,
        CCC_Message      = function(message)
            ui.showMessage(message)
        end,
        CCC_PlaySound    = function(sound)
            ambient.playSound(sound)
        end,
        UiModeChanged    = function(data)
            if data.oldMode == "Container" and openedContainer then
                -- I.UI.setMode("Interface", { windows = {} })
                core.sendGlobalEvent("updateClosedCont")
                openedContainer = nil
            end
        end
    }
}
