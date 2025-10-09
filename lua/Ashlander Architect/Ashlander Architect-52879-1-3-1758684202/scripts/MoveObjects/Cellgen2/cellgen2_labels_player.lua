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


local settlementModData = storage.globalSection("AASettlements")

local renameWindow = nil
local uithing = nil

local currentSettlement = nil

local bedCount = 0

local genModData = storage.globalSection("MoveObjectsCellGen")

local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.

local function getCurrentSettlementName()
    local list = settlementModData:get("settlementList")
    local settlementId = nil
    if (self.cell.isExterior) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                return structure.settlementName
            end
        end
    else
        local intData = cellGenStorage:get("CellGenData")
        for x, sett in ipairs(list) do
            for index, value in ipairs(intData) do
                if value.settlementId == sett.markerId and self.cell.name == value.cellName then
                    local dist = math.sqrt((self.position.x - value.interiorPos.x) ^ 2 +
                        (self.position.y - value.interiorPos.y) ^ 2)
                    if (dist < sett.settlementDiameter / 2) then
                        return sett.settlementName
                    end
                end
            end
        end
    end
    return nil
end

local function getDoorDestinationStr(obj)
    local check = cellGenStorage:get("doorData")[obj.id]
    if check then
        local name = cellGenStorage:get("cellNames")[check.targetCell]
        if name then
            return name, check.targetCell
        end
        local settlmenetCheck = getCurrentSettlementName()
        if check.targetCell ~= self.cell.name and settlmenetCheck then
            return settlmenetCheck, check.targetCell
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
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("cellRename2", { text = currentText, context = buttonContext, originalCell = baseCell })
    renameWindow:destroy()
    I.UI.setMode()
end
local function createWindow(text,context)
    I.UI.setMode('Interface', { windows = {} })
    return I.DaisyUtilsUI_AA.renderTextInput(
        { "", "",
            "What would you like this building to be named?" }, text, textChanged, buttonClick)
end

local function destroyWindow()
    renameWindow:destory()
end
local function onInputAction(id)
    if id == input.ACTION.Activate then
        local buildMode = I.MoveObjects.getBuildModeState()
        if (input.getControlSwitch(input.CONTROL_SWITCH.Controls) == false and not buildMode) then
            return
        end
        local doorSoundMap = cellGenStorage:get("doorSoundMap")
        local obj = I.DaisyUtilsAA.getObjInCrosshairs().hitObject
        if (obj == nil) then
            return
        end
        if not doorSoundMap[obj.recordId] then
            return
        else

        end
        local doorDest, originalCell = getDoorDestinationStr(obj)
        local check = cellGenStorage:get("doorData")[obj.id]
        if not check then return end
        print(check.targetCell)
        if doorDest then
            if not input.isCtrlPressed() and not buildMode then
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
local cellGenStorage = storage.globalSection("AACellGen2")


local function getCellName(baseCellName)
    if not cellGenStorage:get("cellNames")[baseCellName] then
        return baseCellName
    else
        return cellGenStorage:get("cellNames")[baseCellName] 
    end
end
local function onFrame()
    --      renderItemChoice({"Banana","Box","Pizza"},"Box")
    local obj = I.DaisyUtilsAA.getObjInCrosshairs(nil, 250).hitObject
    local targetCell = nil
    if (uithing) then
        uithing:destroy()
    end
    if (obj == nil) then
        return
    end

    local doorSoundMap = cellGenStorage:get("doorSoundMap")
    if not doorSoundMap[obj.recordId] then
        return
    else
        targetCell = getDoorDestinationStr(obj)
    end
    if (targetCell == nil) then
        return
    end
    uithing = renderItemChoice({ "Door", "to", targetCell }, "Door")
end
local function getLabelForCell()
    local list = settlementModData:get("settlementList")
    local settlementId = nil
    if (self.cell.isExterior) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                return structure.settlementName
            end
        end
    else
        local intData = cellGenStorage:get("CellGenData")
        local cellName = getCellName(self.cell.name)
        if cellName then
            return cellName

        end
    end
    return self.cell.name
end
return {
    interfaceName = "CellGen2_Labels",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
        getLabelForCell = getLabelForCell
    },
    eventHandlers = {
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if renameWindow ~= nil and data.newMode == nil then
                renameWindow:destroy()
            end
        end,

    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
    }
}
