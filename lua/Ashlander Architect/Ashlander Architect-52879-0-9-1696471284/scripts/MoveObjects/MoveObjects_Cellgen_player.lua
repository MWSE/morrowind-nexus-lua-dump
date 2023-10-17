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

local renameWindow = nil
local uithing = nil


local doorToActivate = nil
local doorDelay = -1

local actiToSoundMap = {
    a_zh_b_hlaalumanor_01extdoor =    "door heavy open",
    zhac_hlaaluintdoor = "door heavy open",
    a_zh_b_hlaaluhouse_01extdoor= "door heavy open",
    a_zh_b_velothimanor_intdooract = "door latched one open",
    a_zh_b_velothimanorextdoor = "door heavy open",
    a_zh_b_velothihouse_01doorext = "door heavy open",
    a_zh_b_velothihouse_intdooract = "door latched one open",
    a_zh_b_redoranmanor_01_door = "door heavy open",

    a_zh_b_redoranmanor_doorintact = "door heavy open",
    a_zh_b_redoranhutdoor = "door heavy open",
    zhac_redoranhut_intdoor = "door heavy open",
    a_zh_b_redoranhall_door = "door heavy open",

    zhac_redoranhall_intdoor = "door heavy open",
    a_zh_b_imphouse_doorext = "door heavy open",
    zhac_imphouse_intdoor = "door heavy open",
    zhac_mushroomhouse_door = "door heavy open",
    zhac_mushroomhouse_intdoor = "door heavy open",
}
local function playDoorSound(door)
local val = actiToSoundMap[door.recordId]
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
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("renameCellLabel", { text = currentText, context = buttonContext, doorID = doorID })
    renameWindow:destroy()
    I.UI.setMode()
end
local function createWindow(text)
    I.UI.setMode('Interface', { windows = {} })
    return I.ZackUtilsUI_AA.renderTextInput(
        { "", "",
            "What would you like this building to be named?" }, text, textChanged, buttonClick)
end

local function destroyWindow()
    renameWindow:destory()
end
local function onInputAction(id)
    if id == input.ACTION.Activate then
        if (input.getControlSwitch(input.CONTROL_SWITCH.Controls) == false) then
            return
        end
        local obj = I.ZackUtilsAA.getObjInCrosshairs().hitObject
        if (obj == nil) then
            return
        end
        for x, structure in ipairs(myModData:get("generatedStructures")) do
            if (structure.OutsideDoorID == obj.id and input.isCtrlPressed() == false) then
               -- I.ZackUtilsAA.createItem("zhac_soundplayer_doorSound1", self.cell, self.position)
                core.sendGlobalEvent("OutsideDoorActivate", { player = self, door = obj })
                playDoorSound(obj)
            elseif (structure.InsideDoorID == obj.id and input.isCtrlPressed() == false) then
                doorToActivate = obj
                doorDelay = 0
                --I.ZackUtilsAA.createItem("zhac_soundplayer_doorSound1", self.cell, self.position)
            elseif (structure.OutsideDoorID == obj.id and input.isCtrlPressed() == true) then
                currentText = structure.InsideCellLabel
                renameWindow = createWindow(structure.InsideCellLabel)
                doorID = structure.InsideDoorID
                buttonContext = "InsideCellLabel"
            elseif (structure.InsideDoorID == obj.id and input.isCtrlPressed() == true) then
                currentText = structure.OutsideCellLabel
                doorID = structure.InsideDoorID
                buttonContext = "OutsideCellLabel"
                renameWindow = createWindow(structure.OutsideCellLabel)
            end
        end
    end
end
local function onFrame()
    if (doorDelay > -1) then
       -- doorDelay = doorDelay + 1
      --  if (doorDelay > 60) then
            doorDelay = -1
        --    print("Door delay executed")

            core.sendGlobalEvent("InsideDoorActivate", { player = self, door = doorToActivate })
            playDoorSound(doorToActivate)
       -- end
    end
    --      renderItemChoice({"Banana","Box","Pizza"},"Box")
    local obj = I.ZackUtilsAA.getObjInCrosshairs(nil, 250).hitObject
    local targetCell = nil
    if (uithing) then
        uithing:destroy()
    end
    if (obj == nil) then
        return
    end
    if (obj:isValid() and obj.recordId == "zhac_settlement_marker") then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            if (structure.markerId == obj.id) then
                uithing = renderItemChoice({ structure.settlementName }, "")
                return
            end
        end
        uithing = renderItemChoice({ "Settlement Marker" }, "")
        return
    end
    for x, structure in ipairs(myModData:get("generatedStructures")) do
        if (structure.OutsideDoorID == obj.id) then
            targetCell = structure.InsideCellLabel
        elseif (structure.InsideDoorID == obj.id) then
            targetCell = structure.OutsideCellLabel
        end
    end
    if (targetCell == nil) then
        return
    end
    uithing = renderItemChoice({ "Door", "to", targetCell }, "Door")
end


return {
    interfaceName = "CellGenPlayer",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
    },
    eventHandlers = {
        UiModeChanged = function(data)
           -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if renameWindow ~= nil and  data.newMode == nil then
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
