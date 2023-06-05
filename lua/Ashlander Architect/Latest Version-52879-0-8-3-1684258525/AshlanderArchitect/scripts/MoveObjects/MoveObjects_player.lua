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
local async = require("openmw.async")
local activeObjectTypes = {}

local settlementModData = storage.globalSection("AASettlements")
local genModData = storage.globalSection("MoveObjectsCellGen")

local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.


local gridRefOb = nil

local currentRefs = {}
local currentMainRef = nil
local selectedItemIsReal = false --if the selected item hasn't been placed yet, we don't need to preserve it.
local placedRefs = {}
local zPosLock = 0
local zPosManOffset = 0

local tempObjects = {}

local ignoreCategories = false

local obDistance = 500
local playerpath = nil
local awaitingNewItem = false
local controllerMode = false
local awaitingNewItemToStore = false
local scrollMode = 1
local selectedIndex = 1
local selectedIndexCat = 1
local selectedIndexSubCat = 1
local selectedIndexMain = 1

local offsetX = 0
local offsetY = 0

local gridMode = 0
--0 is normal, use grid when reference point exists.
--1 is use world grid.


local offsetZ = 0

local selectedIndexBySubCategory = {}
local selectedIndexByCategory = {}


local buildModeEnabled = false
local collisionEnabled = true
local zDegrees = 0
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local function removeTempObject()
    if (selectedItemIsReal == false) then
        local indexToRemove
        for i, object in ipairs(tempObjects) do
            if object == currentMainRef then
                indexToRemove = i
                break
            end
        end
        table.remove(tempObjects, indexToRemove)
        I.ZackUtils.deleteItem(currentMainRef)
    end
end
local ctrl = input.CONTROLLER_BUTTON
local controllerButtonData = {
    { id = ctrl.A,             text = "A" },
    { id = ctrl.B,             text = "B" },
    { id = ctrl.Back,          text = "Back" },
    { id = ctrl.DPadDown,      text = "DPadDown" },
    { id = ctrl.DPadLeft,      text = "DPadLeft" },
    { id = ctrl.DPadRight,     text = "DPadRight" },
    { id = ctrl.DPadUp,        text = "DPadUp" },
    { id = ctrl.Guide,         text = "Guide" },
    { id = ctrl.LeftShoulder,  text = "Left Shoulder" },
    { id = ctrl.LeftStick,     text = "Left Stick Press" },
    { id = ctrl.RightShoulder, text = "Right Shoulder" },
    { id = ctrl.RightStick,    text = "Right Stick Press" },
    { id = ctrl.Start,         text = "Start" },
    { id = ctrl.Y,             text = "Y" },
    { id = ctrl.X,             text = "X" },
}
local ignoreButtons = {
    { id = ctrl.DPadDown,  text = "DPadDown" },
    { id = ctrl.DPadLeft,  text = "DPadLeft" },
    { id = ctrl.DPadRight, text = "DPadRight" },
    { id = ctrl.DPadUp,    text = "DPadUp" },
    { id = ctrl.Guide,     text = "Guide" },

}
local function getAllCtrlButtons()
    local ret = {}
    for i, button in ipairs(controllerButtonData) do
        local ignore = false
        for i, igbutton in ipairs(ignoreButtons) do
            if (igbutton.id == button.id) then
                ignore = true
            end
        end
        if (ignore == false) then
            table.insert(ret, button.text)
        end
    end

    return ret
end
local function textToControllerButton(buttonText)
    for i, button in ipairs(controllerButtonData) do
        if (button.text == buttonText) then
            return button.id
        end
    end
end
local function controllerButtonToText(button)

end

local function createPreviewObject()

end

I.Settings.registerPage {
    key = "AshlanderArchitect",
    l10n = "AshlanderArchitect",
    name = "AshlanderArchitect",
    description = "AshlanderArchitect"
}
I.Settings.registerGroup {
    key = "SettingsAshlanderArchitect",
    page = "AshlanderArchitect",
    l10n = "AshlanderArchitect",
    name = "AshlanderArchitect",
    description = "My Group Description",
    permanentStorage = false,
    settings = {
        {
            key = "DisableJumping",
            renderer = "checkbox",
            name = "Disable Jumping in Build Mode",
            description =
            "If set to true, then jumping will be disabled while in build mode. This allows for more buttons to be reused.",
            default = "true"
        },
        {
            key = "EnableButtonBox",
            renderer = "checkbox",
            name = "Display Button Info Window",
            description =
            "If set to true, then while in build mode, you will see a box with infomration on what keys/buttons you can press.",
            default = "true"
        },
        {
            key = "KeepOffset",
            renderer = "checkbox",
            name = "Keep objects offset from where you grabbed it",
            description =
            "If set to true, this will prevent objects from jumping to where your cursor is when you grab it.",
            default = true
        },
        {
            key = "AllowGrabAll",
            renderer = "checkbox",
            name = "Allow grabbing any object",
            default = false,
            description =
            "By default, you may only grab items, objects you can place, and natural objects like plants and rocks. This allows you to grab any object in your crosshairs.",

        }
    }
}
I.Settings.registerGroup {
    key = "SettingsAshlanderArchitectController",
    page = "AshlanderArchitect",
    l10n = "AshlanderArchitectButtons",
    name = "Ashlander Architect Controller Bindings",
    description =
    "Settings for controller mode in Ashlander Architect. LSh means Left Shoulder, RS means Right Stick Press. ",
    permanentStorage = true,
    settings = {
        {
            key = "PlaceButton",
            renderer = "select",
            l10n = "AshlanderArchitectButtons",
            name = "Place/Drop Object/Select Page Button",
            default = "A",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = getAllCtrlButtons(),
            },
        },

        {
            key = "ForceControllerMode",
            renderer = "checkbox",
            name = "Force Controller Mode",
            description =
            "If set to true, the user interface will be forced into controller mode no matter what keys are pressed.",
            default = "true"
        },
        {
            key = "UseDPadArrows",
            renderer = "checkbox",
            name = "Use DPad as Arrow Keys",
            description =
            "If set to true, the DPad will be used for navigating the menu, instead of the bumpers, A, and B. However, you will need to remap your DPad in Steam or any other tool to make then send arrow key signals instead.",
            default = "true"
        }

    }
}

local controllerSettings = storage.playerSection("SettingsAshlanderArchitectController")
local playerSettings = storage.playerSection("SettingsAshlanderArchitectController")
--windows
local currentItemName = nil
local imageBoxCenter = nil
local imageBoxLeft1 = nil
local imageBoxLeft2 = nil
local imageBoxLeft3 = nil
local imageBoxRight1 = nil
local imageBoxRight2 = nil
local imageBoxRight3 = nil


local SettlementBox = nil

local itemInfo = {}
local buttonsAndInfo = nil
local selectedItemInfo = nil
local function insertObject(objectsTable, objectType)
    local subcategoryName = objectType.Subcategory

    if not objectsTable[subcategoryName] then
        local newObject = {
            Static_ID = objectType.Static_ID,
            Name = objectType.Name,
            Category = objectType.Category,
            Subcategory = subcategoryName,
            Grid_Size = objectType.Grid_Size,
            Z_Offset = objectType.Z_Offset,
            Texture_Name = objectType.Texture_Name
        }
        objectsTable[subcategoryName] = newObject
    end
end
local function findObjectById(id)
    for _, object in ipairs(I.moveobjects_data.objectTypes) do
        if object.Static_ID:lower() == id:lower() then
            return object
        end
    end
    return nil
end


local function insertObjectsByCategory(objectTypes, categoryName)
    local objectsTable = {}

    for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
        if objectType.Category == categoryName then
            insertObject(objectsTable, objectType)
        end
    end

    return objectsTable
end
local function checkifExists(obdata)
    local obId = obdata.Static_ID
    local type = obdata.Object_Type

    if (type == "static") then
        return I.ZackUtils.CheckForRecord(obId, types.Static)
    elseif (type == "container") then
        return I.ZackUtils.CheckForRecord(obId, types.Container)
    elseif (type == "activator") then
        return I.ZackUtils.CheckForRecord(obId, types.Activator)
    elseif (type == "light") then
        return I.ZackUtils.CheckForRecord(obId, types.Light)
    elseif (type == "static") then
    end
end
local function updateActiveObjects()
    print("Updating objects")
    local factiveObjectTypes = {}
    activeObjectTypes = {}

    if currentCategory == nil and not ignoreCategories then
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if not factiveObjectTypes[categoryName] and checkifExists(objectType) then
                local firstObject = {
                    Static_ID = objectType.Static_ID,
                    Name = categoryName,
                    Category = categoryName,
                    Subcategory = subcategoryName,
                    Grid_Size = objectType.Grid_Size,
                    Z_Offset = objectType.Z_Offset,
                    Texture_Name = objectType.Texture_Name,
                    DefaultDist = objectType.DefaultDist,
                    Object_Type = objectType.Object_Type
                }
                factiveObjectTypes[categoryName] = firstObject
            end
        end
    elseif currentSubCat == nil and not ignoreCategories then
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if categoryName == currentCategory and checkifExists(objectType) then
                if not factiveObjectTypes[subcategoryName] then
                    local firstObject = {
                        Static_ID = objectType.Static_ID,
                        Name = subcategoryName,
                        Category = categoryName,
                        Subcategory = subcategoryName,
                        Grid_Size = objectType.Grid_Size,
                        Z_Offset = objectType.Z_Offset,
                        Texture_Name = objectType.Texture_Name,
                        DefaultDist = objectType.DefaultDist,
                        Object_Type = objectType.Object_Type
                    }
                    factiveObjectTypes[subcategoryName] = firstObject
                end
            end
        end
    else
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if (categoryName == currentCategory and subcategoryName == currentSubCat and checkifExists(objectType)) or ignoreCategories then
                local newObj = {
                    Static_ID = objectType.Static_ID,
                    Name = objectType.Name,
                    Category = categoryName,
                    Subcategory = subcategoryName,
                    Grid_Size = objectType.Grid_Size,
                    Z_Offset = objectType.Z_Offset,
                    Texture_Name = objectType.Texture_Name,
                    DefaultDist = objectType.DefaultDist,
                    Object_Type = objectType.Object_Type
                }
                table.insert(activeObjectTypes, newObj)
            end
        end
    end

    for _, object in pairs(factiveObjectTypes) do
        table.insert(activeObjectTypes, object)
    end

    if #activeObjectTypes == 0 then
        print("Found no objects!")
    end
end

local enableUi = true
local function canOrderNPC(npc)
    local list = settlementModData:get("settlementList")
    local settlementId = nil
    if (self.cell.isExterior) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                for i, npcId in ipairs(structure.settlementNPCs) do
                    return true
                end
            end
        end
    else
        for x, structure in ipairs(genModData:get("generatedStructures")) do
            if (self.cell.name == structure.InsideCellName) then
                local dist = math.sqrt((self.position.x - structure.InsidePos.x) ^ 2 +
                    (self.position.y - structure.InsidePos.y) ^ 2)
                if (dist < 10000) then
                    for i, settlement in ipairs(settlementModData:get("settlementList")) do
                        if (settlement and settlement.markerId == structure.settlementId) then
                            for i, npcId in ipairs(settlement.settlementNPCs) do
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end
local function updateUi()
    if selectedIndex > #activeObjectTypes then
        selectedIndex = 1
    end
    if (true) then
        -- return
    end
    if (imageBoxCenter) then
        imageBoxCenter:destroy()
    end
    if (SettlementBox) then
        SettlementBox:destroy()
    end
    if (imageBoxLeft1) then
        imageBoxLeft1:destroy()
    end
    if (imageBoxLeft2) then
        imageBoxLeft2:destroy()
    end
    if (imageBoxLeft3) then
        imageBoxLeft3:destroy()
    end
    if (imageBoxRight1) then
        imageBoxRight1:destroy()
    end
    if (imageBoxRight2) then
        imageBoxRight2:destroy()
    end
    if (imageBoxRight3) then
        imageBoxRight3:destroy()
    end
    if (buttonsAndInfo) then
        buttonsAndInfo:destroy()
    end
    if (selectedItemInfo) then
        selectedItemInfo:destroy()
    end
    if (buildModeEnabled == false) then
        return
    end
    if (enableUi == false) then
        return
    end
    if (controllerMode == false) then
        local buttonTable = {} -- "Stamp Currently selected item: left click", "Select object in crosshairs: Right Click",
        --  "Rotate Right: C",
        --  "Rotate Left: X" }
        if (currentMainRef ~= nil) then
            if (currentMainRef.type == types.NPC) then
                local hitPos = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitPos
                local hitObject = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitObject
                local done = false
                if (hitObject) then
                    if (hitObject.type == types.Activator) then
                        if (hitObject.recordId == "zhac_settlement_marker1" or hitObject.recordId == "zhac_settlement_marker_c") then
                            table.insert(buttonTable, "Send " ..
                                types.NPC.record(currentMainRef).name .. " to work at targeted marker")
                            done = true
                        else
                            for x, structure in ipairs(genModData:get("generatedStructures")) do
                                if (structure.OutsideDoorID == hitObject.id) then
                                    table.insert(buttonTable, "Send " ..
                                        types.NPC.record(currentMainRef).name .. " into " .. structure.InsideCellLabel)
                                    done = true
                                end
                                if (structure.InsideDoorID == hitObject.id) then
                                    table.insert(buttonTable, "Send " ..
                                        types.NPC.record(currentMainRef).name ..
                                        " outside of " .. structure.InsideCellLabel)
                                    done = true
                                end
                            end
                        end
                    elseif (hitObject.type == types.Creature) then
                        table.insert(buttonTable, "Order " ..
                            types.NPC.record(currentMainRef).name ..
                            " to attack " .. types.Creature.record(hitObject).name)
                        done = true
                    end
                end
                if (done == false) then
                    table.insert(buttonTable, "Send " .. types.NPC.record(currentMainRef).name .. " to targeted position")
                end
                table.insert(buttonTable, "Deselect Settler: Right Click")
            end
        end
        if (currentCategory ~= nil and currentSubCat ~= nil) then
            table.insert(buttonTable, "Stamp Currently selected object: Left Click")
        end
        if (currentMainRef == nil) then
            local hitObject = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitObject
            if (hitObject) then
                table.insert(buttonTable, "Set grid reference object to targeted object: C")
            else
                table.insert(buttonTable, "Remove grid reference object: C")
            end
        end
        if (currentMainRef ~= nil and selectedItemIsReal and currentMainRef.type ~= types.NPC) then
            table.insert(buttonTable, "Destroy selected object: V")
            table.insert(buttonTable, "Drop targeted object: Right Click")
        end
        if (currentMainRef == nil) then
            table.insert(buttonTable, "Pick up targeted object: X")
        end
        if (currentMainRef == nil) then
            table.insert(buttonTable, "Pick up targeted object: X")
        end
        if (zPosLock == 0) then
            table.insert(buttonTable, "Enable Vertical Position Lock: G")
        else
            table.insert(buttonTable, "Disable Vertical Position Lock: G")
        end
        if (collisionEnabled) then
            table.insert(buttonTable, "Disable Surface Snapping: N")
        else
            table.insert(buttonTable, "Enable Surface Snapping: N")
        end
        if (input.isAltPressed() == false and input.isCtrlPressed() == false) then
            table.insert(buttonTable, "Adjust Object Rotation: Scroll Wheel")
        elseif (input.isCtrlPressed() == true) then
            table.insert(buttonTable, "Adjust Object Vertical Position: Scroll Wheel")
        else
            table.insert(buttonTable, "Adjust Object Distance: Scroll Wheel")
        end
        buttonsAndInfo = I.ZackUtilsUI.renderItemChoice(buttonTable, 0.0, 0.01)
    else
        local buttonTable = {}
        if (currentCategory ~= nil and currentSubCat ~= nil) then
            table.insert(buttonTable, "Stamp Currently selected object: A Button")
        else
            table.insert(buttonTable, "Enter Selected Category: A Button")
        end
        if (currentMainRef ~= nil and selectedItemIsReal) then
            table.insert(buttonTable, "Destroy selected object: Y")
            table.insert(buttonTable, "Drop targeted object: X Button")
        end
        if (currentMainRef == nil) then
            table.insert(buttonTable, "Pick up targeted object: X")
        end
        if (zPosLock == 0) then
            table.insert(buttonTable, "Enable Vertical Position Lock: Y Button Long Press")
        else
            table.insert(buttonTable, "Disable Vertical Position Lock: Y Button Long Press")
        end
        if (collisionEnabled) then
            table.insert(buttonTable, "Disable Surface Snapping: Y Button")
        else
            table.insert(buttonTable, "Enable Surface Snapping: Y Button")
        end
        table.insert(buttonTable, "Adjust Object Rotation: Trigger Left and Right")
        table.insert(buttonTable, "Reset Object Rotation:Double LStick Push")
        table.insert(buttonTable, "Adjust Object Vertical Position: Trigger L&R + RStick Push")
        table.insert(buttonTable, "Reset Object Vertical Position:Double RStick Push")
        table.insert(buttonTable, "Adjust Object Distance: Trigger L&R + LStick Push")
        buttonsAndInfo = I.ZackUtilsUI.renderItemChoice(buttonTable, 0.0, 0.01)
        -- buttonsAndInfo = I.ZackUtilsUI.renderItemChoice(buttonTable, 0.8, 0.01,ui.ALIGNMENT.End)
    end
    local infoTable = {}
    table.insert(infoTable, "Vertical Position Offset: " .. util.round(zPosManOffset))
    table.insert(infoTable, "Selected Object Distance: " .. util.round(obDistance))
    table.insert(infoTable, "Currently Selected Item:")
    if (currentMainRef == nil) then
        table.insert(infoTable, "None")
        local hitObject = I.ZackUtils.getObjInCrosshairs(nil, obDistance).hitObject
        if (hitObject and hitObject.type ~= types.NPC) then
            table.insert(infoTable, "Object to select at this pos:")
            local lookUp = findObjectById(hitObject.recordId)
            if (lookUp) then
                table.insert(infoTable, lookUp.Name)
            else
                local nameCheck = I.ZackUtils.FindGameObjectName(hitObject)
                if (nameCheck) then
                    table.insert(infoTable, nameCheck)
                else
                    table.insert(infoTable, hitObject.recordId)
                end
            end
        elseif (hitObject and hitObject.type == types.NPC and canOrderNPC(hitObject)) then
            table.insert(infoTable, "Settler to select at this pos:")
            table.insert(infoTable, types.NPC.record(hitObject).name)
        end
    else
        if (currentMainRef) then
            local lookUp = findObjectById(currentMainRef.recordId)
            if (lookUp) then
                table.insert(infoTable, lookUp.Name)
            else
                local nameCheck = I.ZackUtils.FindGameObjectName(currentMainRef)
                if (nameCheck) then
                    table.insert(infoTable, nameCheck)
                else
                    table.insert(infoTable, currentMainRef.recordId)
                end
            end
        end
        table.insert(infoTable, "Vertical Rotation: " .. util.round(math.deg(currentMainRef.rotation.z)))
    end
    selectedItemInfo = I.ZackUtilsUI.renderItemChoice(infoTable, 0.9, 0.01, ui.ALIGNMENT.Start, util.vector2(0.5, 0))
    if (self.cell.isExterior and settlementModData:get("settlementList") ~= nil) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                SettlementBox = I.ZackUtilsUI.renderItemChoice({ structure.settlementName }, 0.96, 0.90)
            end
        end
    else
        if(genModData:get("generatedStructures") ~= nil) then
        for x, structure in ipairs(genModData:get("generatedStructures")) do
            if (self.cell.name == structure.InsideCellName) then
                local dist = math.sqrt((self.position.x - structure.InsidePos.x) ^ 2 +
                    (self.position.y - structure.InsidePos.y) ^ 2)
                if (dist < 10000) then
                    for i, settlement in ipairs(settlementModData:get("settlementList")) do
                        if (settlement.markerId == structure.settlementId) then
                            SettlementBox = I.ZackUtilsUI.renderItemChoice({ settlement.settlementName }, 0.96, 0.90)
                        end
                    end
                end
            end
        end
    else
        ui.showMessage("Generated structure list wasn't found.")
    end
    end


    imageBoxCenter = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex], 0.5, 0.8, 5)

    if selectedIndex > 1 then
        imageBoxLeft1 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 1], 0.4, 0.8)
    end

    if selectedIndex > 2 then
        imageBoxLeft2 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 2], 0.3, 0.8)
    end

    if selectedIndex > 3 then
        imageBoxLeft3 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 3], 0.2, 0.8)
    end

    if selectedIndex < #activeObjectTypes then
        imageBoxRight1 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 1], 0.6, 0.8)
    end

    if selectedIndex < #activeObjectTypes - 1 then
        imageBoxRight2 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 2], 0.7, 0.8)
    end

    if selectedIndex < #activeObjectTypes - 2 then
        imageBoxRight3 = I.ZackUtilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 3], 0.8, 0.8)
    end
end
local function getCameraDirData()
    local pos = camera.getPosition()
    local pitch, yaw

    pitch = -(camera.getPitch() + camera.getExtraPitch())
    yaw = (camera.getYaw() + camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local lastDist = 0
local function updateSelectedItem()
    --need to remove the selected item, and replace it with the new item.

    offsetX = 0
    offsetY = 0
    offsetZ = 0
    print("Selected item")

    if (currentSubCat == nil or currentCategory == nil and ignoreCategories == false) then
        return
    end
    if (awaitingNewItem) then
        print("Still waiting for item")
        return
    end
    if (currentMainRef == nil) then
        local tcell = self.cell
        local tpos = self.position
        local trot = util.vector3(0, 0, math.rad(zDegrees))
        if (activeObjectTypes[selectedIndex].DefaultDist ~= lastDist) then
            lastDist = activeObjectTypes[selectedIndex].DefaultDist
            obDistance = lastDist
        end
        I.ZackUtils.createItem(activeObjectTypes[selectedIndex].Static_ID, tcell, tpos, trot)
        awaitingNewItem = true
        return
    end

    if (currentMainRef.recordId == activeObjectTypes[selectedIndex].Static_ID:lower()) then
        print("This is the same as the last.")
        return
    end



    local tcell = currentMainRef.cell
    local tpos = currentMainRef.position
    local trot = util.vector3(0, 0, math.rad(zDegrees))
    if (selectedItemIsReal == false) then
        removeTempObject()
        I.ZackUtils.deleteItem(currentMainRef)
    end
    if (activeObjectTypes[selectedIndex].DefaultDist ~= lastDist) then
        lastDist = activeObjectTypes[selectedIndex].DefaultDist
        obDistance = lastDist
    end
    currentMainRef = nil
    I.ZackUtils.createItem(activeObjectTypes[selectedIndex].Static_ID, tcell, tpos, trot)
    awaitingNewItem = true
    --need to wait for stage 2
end
local function normalize_degrees(degrees)
    return (degrees % 360 + 360) % 360 - (degrees % 360 < 0 and 360 or 0)
end

local function updateBuildModeState()
    if (buildModeEnabled == true) then
        input.setControlSwitch(input.CONTROL_SWITCH.Fighting, false)
        input.setControlSwitch(input.CONTROL_SWITCH.Magic, false)
        input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, false)
        --  if(controllerMode == false) then
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        input.setControlSwitch(input.CONTROL_SWITCH.Jumping, false)
        --  end
        camera.setMode(camera.MODE.FirstPerson)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        I.ControlsZack.overrideMovementControls(false)
        I.Controls.overrideMovementControls(true)
        selectedItemIsReal = false
        if (currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then
            I.ZackUtils.createItem(activeObjectTypes[selectedIndex].Static_ID, self.cell, self.position,
                util.vector3(0, 0, math.rad(zDegrees)))
            selectedItemIsReal = false
            awaitingNewItem = true
        end
    else
        input.setControlSwitch(input.CONTROL_SWITCH.Fighting, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Magic, true)
        input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Jumping, true)
        I.ControlsZack.overrideMovementControls(true)
        I.Controls.overrideMovementControls(false)
        for i, placedItem in ipairs(placedRefs) do
            core.sendGlobalEvent("exitBuildMode", { placedItem = placedItem, player = self })
        end
        placedRefs = {}
        if (selectedItemIsReal == false) then
            removeTempObject()
            I.ZackUtils.deleteItem(currentMainRef)
        end
        currentMainRef = nil
    end
end
local function onInputAction(action)
    if (buildModeEnabled == false) then
        return
    end
    if (core.isWorldPaused()) then
        return
    end
    local rotationAmount = 10
    if (currentMainRef) then
        local findOb = findObjectById(currentMainRef.recordId)
        if (findOb) then
            if (findOb.Grid_Size > 0) then
                rotationAmount = 90
            end
        end
    end

    if (action == input.ACTION.ZoomIn and input.isCtrlPressed()) then --move towards me
        zPosManOffset = zPosManOffset + 10
        updateUi()
    elseif (action == input.ACTION.ZoomOut and input.isCtrlPressed()) then
        zPosManOffset = zPosManOffset - 10
        updateUi()
        updateUi()
    elseif (action == input.ACTION.ZoomIn and input.isAltPressed()) then --move towards me
        obDistance = obDistance + 10
        updateUi()
    elseif (action == input.ACTION.ZoomOut and input.isAltPressed()) then
        obDistance = obDistance - 10
        updateUi()
    elseif (action == input.ACTION.ZoomIn) then --move towards me
        zDegrees = normalize_degrees(zDegrees + rotationAmount)
        updateUi()
    elseif (action == input.ACTION.ZoomOut) then
        zDegrees = normalize_degrees(zDegrees - rotationAmount)
        updateUi()
    elseif (action == input.ACTION.Sneak) then
        -- for _, info in ipairs(itemInfo) do
        --  print(info.recordId, info.positionZ)
        --end
        if (scrollMode == 1) then
            scrollMode = 2
        elseif scrollMode == 2 then
            scrollMode = 3
        elseif scrollMode == 3 then
            scrollMode = 1
        end
        updateUi()
    elseif (action == input.ACTION.Inventory and controllerMode == false) then --Right Click
        if not currentMainRef then
            local hitObject = I.ZackUtils.getObjInCrosshairs().hitObject
            local hitPosReal = I.ZackUtils.getObjInCrosshairs(hitObject).hitPos
            if hitObject then
                if (hitObject and hitPosReal) then
                    offsetX = hitObject.position.x - hitPosReal.x
                    offsetY = hitObject.position.y - hitPosReal.y
                    offsetZ = hitObject.position.z - hitPosReal.z
                    print(offsetX, offsetY, offsetZ)
                end
                zDegrees = normalize_degrees(math.deg(hitObject.rotation.z))
                currentMainRef = hitObject.id
                local position = hitObject.position
                currentMainRef = hitObject
                local findOb = findObjectById(hitObject.recordId)
                if (findOb) then

                end
                selectedItemIsReal = true
                -- calculate offsetslll
            end
        else
            if (selectedItemIsReal == false) then
                removeTempObject()
                I.ZackUtils.deleteItem(currentMainRef)
            end
            currentMainRef = nil
            selectedItemIsReal = false
        end
        updateUi()
    elseif (((action == input.ACTION.Use and controllerMode == false) or action == input.ACTION.Activate and controllerMode == true) and currentSubCat ~= nil and currentCategory ~= nil and selectedItemIsReal == false) then --Left Click
        if currentMainRef == nil then
            --   I.ZackUtils.createItem(activeObjectTypes[selectedIndex].Static_ID, self.cell, self.position, self.rotation)
            selectedItemIsReal = false
            --   awaitingNewItem = true
        else
            I.ZackUtils.createItem(activeObjectTypes[selectedIndex].Static_ID, currentMainRef.cell,
                currentMainRef.position,
                currentMainRef.rotation)
            awaitingNewItemToStore = true
            ui.showMessage("Placed Object")
            selectedItemIsReal = false
        end
        updateUi()
    elseif (((action == input.ACTION.Use and controllerMode == false) or action == input.ACTION.Activate and controllerMode == true) and selectedItemIsReal == true and currentMainRef ~= nil and currentMainRef.type == types.NPC) then --Left Click
        local hitPos = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitPos
        local hitObject = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitObject
        local done = false
        if (hitObject) then
            if (hitObject.type == types.Activator) then
                if (hitObject.recordId == "zhac_settlement_marker1" or hitObject.recordId == "zhac_settlement_marker_c") then
                    ui.showMessage("Sending " ..
                        types.NPC.record(currentMainRef).name .. " to work ")
                    currentMainRef:sendEvent("setJobSite", hitObject)
                    done = true
                else
                    for x, structure in ipairs(genModData:get("generatedStructures")) do
                        if (structure.OutsideDoorID == hitObject.id) then
                            currentMainRef:sendEvent("enterBuilding", { doorId = hitObject.id })
                            ui.showMessage("Sending " ..
                                types.NPC.record(currentMainRef).name .. " into " .. structure.InsideCellLabel)
                            done = true
                        end
                        if (structure.InsideDoorID == hitObject.id) then
                            currentMainRef:sendEvent("exitBuilding", { doorId = hitObject.id })
                            ui.showMessage("Sending " ..
                                types.NPC.record(currentMainRef).name .. " outside of " .. structure.InsideCellLabel)
                            done = true
                        end
                    end
                end
            elseif (hitObject.type == types.Creature) then
                ui.showMessage("Ordering " ..
                    types.NPC.record(currentMainRef).name .. " to attack " .. types.Creature.record(hitObject).name)
                currentMainRef:sendEvent("attackTarget", hitObject)
                done = true
            end
        end
        if (done == false) then
            currentMainRef:sendEvent("goToPosition", hitPos)
            ui.showMessage("Sending " .. types.NPC.record(currentMainRef).name .. " to targeted position")
        end
    else
    end
end
local doubleClickSpeed = 10
local lastClick = 0
local function handleInput(key, controller)
    if (core.isWorldPaused()) then
        return
    end
    if (key == nil and controllerMode == false) then
        controllerMode = true
        print("Controller mode on")
        --   input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        key = { symbol = "", code = 0 }
    elseif (key == nil and controllerMode == true) then
        key = { symbol = "", code = 0 }
    end
    if (controller == nil and controllerSettings:get("ForceControllerMode") == false) then
        controllerMode = false
        controller = -1
    end
    if (controllerMode == false and key.symbol == 'b') then
        buildModeEnabled = not buildModeEnabled
        updateBuildModeState()
        updateActiveObjects()
        updateUi()
    end
    if (buildModeEnabled == false) then
        return
    end
    if (controller == input.CONTROLLER_BUTTON.RightStick) then
        if (lastClick == 0) then
            lastClick = core.getGameTime()
        elseif (core.getGameTime() - lastClick < doubleClickSpeed) then
            zPosManOffset = 0
            ui.showMessage("Reset Height Offset")
        else

        end
        lastClick = core.getGameTime()
    elseif (controller == input.CONTROLLER_BUTTON.LeftStick) then
        if (lastClick == 0) then
            lastClick = core.getGameTime()
        elseif (core.getGameTime() - lastClick < doubleClickSpeed) then
            zDegrees = 0
            ui.showMessage("Reset Rotation")
        else

        end
        lastClick = core.getGameTime()
    elseif (controller == input.CONTROLLER_BUTTON.A) then
        if (currentMainRef.type == types.NPC) then
            local hitPos = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitPos
            local hitObject = I.ZackUtils.getObjInCrosshairs(nil, 10000).hitObject
            local done = false
            if (hitObject) then
                if (hitObject.type == types.Activator) then
                    if (hitObject.recordId == "zhac_settlement_marker1") then
                        ui.showMessage("Sending " ..
                            types.NPC.record(currentMainRef).name .. " to work ")
                        currentMainRef:sendEvent("setJobSite", hitObject)
                        done = true
                    else
                        for x, structure in ipairs(genModData:get("generatedStructures")) do
                            if (structure.OutsideDoorID == hitObject.id) then
                                currentMainRef:sendEvent("enterBuilding", { doorId = hitObject.id })
                                ui.showMessage("Sending " ..
                                    types.NPC.record(currentMainRef).name .. " into " .. structure.InsideCellLabel)
                                done = true
                            end
                            if (structure.InsideDoorID == hitObject.id) then
                                currentMainRef:sendEvent("exitBuilding", { doorId = hitObject.id })
                                ui.showMessage("Sending " ..
                                    types.NPC.record(currentMainRef).name .. " outside of " .. structure.InsideCellLabel)
                                done = true
                            end
                        end
                    end
                elseif (hitObject.type == types.Creature) then
                    ui.showMessage("Ordering " ..
                        types.NPC.record(currentMainRef).name .. " to attack " .. types.Creature.record(hitObject).name)
                    currentMainRef:sendEvent("attackTarget", hitObject)
                    done = true
                end
            end
            if (done == false) then
                currentMainRef:sendEvent("goToPosition", hitPos)
                ui.showMessage("Sending " .. types.NPC.record(currentMainRef).name .. " to targeted position")
            end
        end
    elseif (controller == input.CONTROLLER_BUTTON.X) then
        if not currentMainRef then
            local hitObject = I.ZackUtils.getObjInCrosshairs().hitObject
            if hitObject and hitObject.type ~= types.NPC then
                zDegrees = normalize_degrees(math.deg(hitObject.rotation.z))

                local hitPosReal = I.ZackUtils.getObjInCrosshairs(hitObject).hitPos
                if (hitObject and hitPosReal and playerSettings:get("KeepOffset")) then
                    offsetX = hitObject.position.x - hitPosReal.x
                    offsetY = hitObject.position.y - hitPosReal.y
                    offsetZ = hitObject.position.z - hitPosReal.z
                    --    print(offsetX, offsetY, offsetZ)
                end
                currentMainRef = hitObject.id
                local position = hitObject.position
                currentMainRef = hitObject
                local findOb = findObjectById(hitObject.recordId)
                if (findOb) then

                end
                selectedItemIsReal = true
                -- calculate offsetslll
            elseif hitObject and hitObject.type == types.NPC and canOrderNPC(hitObject) then
                currentMainRef = hitObject
                selectedItemIsReal = true
            end
        else
            currentMainRef = nil
            selectedItemIsReal = false
        end
        updateUi()
    end
    if ((key.code == input.KEY.RightArrow or controller == input.CONTROLLER_BUTTON.DPadRight) and core.isWorldPaused() == false and selectedItemIsReal == false) then --right/up
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        if (selectedIndex < #activeObjectTypes) then
            selectedIndex = selectedIndex + 1

            updateUi()
            updateSelectedItem()
        end
    elseif ((key.code == input.KEY.LeftArrow or controller == input.CONTROLLER_BUTTON.DPadLeft) and core.isWorldPaused() == false and selectedItemIsReal == false) then --left/down
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        if (selectedIndex > 1) then
            selectedIndex = selectedIndex - 1
            updateUi()
            updateSelectedItem()
        end
    elseif (key.code == input.KEY.F11) then
        enableUi = not enableUi
    elseif (key.code == input.KEY.V) then
        if (selectedItemIsReal == false) then
            removeTempObject()
        end
        I.ZackUtils.deleteItem(currentMainRef)
        selectedItemIsReal = false
        currentMainRef = nil
    elseif (key.code == input.KEY.C) then
        local swingAt = I.ZackUtils.getObjInCrosshairs().hitObject
        if (swingAt ~= nil and findObjectById(swingAt.recordId) ~= nil) then
            ui.showMessage("Set grid reference object to " .. findObjectById(swingAt.recordId).Name)
            gridRefOb = swingAt
            gridRefOb = swingAt
            -- print(gridRefOb.position)
            print("set grid Ref OB" .. swingAt.recordId .. gridRefOb.recordId)
        else
            ui.showMessage("Removed grid reference object")
            print("Removed Grid Ob")
            gridRefOb = nil
        end
    elseif ((key.code == input.KEY.UpArrow or controller == input.CONTROLLER_BUTTON.DPadUp) and ignoreCategories == false and currentCategory == nil and currentSubCat == nil and selectedItemIsReal == false) then --selecting the category
        currentCategory = activeObjectTypes[selectedIndex].Category
        selectedIndexCat = selectedIndex
        selectedIndex = selectedIndexSubCat
        print("Entering cat")
        updateActiveObjects()
    elseif ((key.code == input.KEY.UpArrow or controller == input.CONTROLLER_BUTTON.DPadUp and currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false)) then --selecting the subcategory
        currentSubCat = activeObjectTypes[selectedIndex].Subcategory
        updateActiveObjects()
        selectedIndexSubCat = selectedIndex
        selectedIndex = selectedIndexMain
        print("Entering subcat")
        updateUi()
        updateSelectedItem()
    elseif ((key.code == input.KEY.UpArrow or controller == input.CONTROLLER_BUTTON.DPadUp and  ignoreCategories == true)) then --selecting the subcategory
     
        updateActiveObjects()
        print("Entering subcat")
        updateUi()
        updateSelectedItem()
    elseif (((key.code == input.KEY.DownArrow) or controller == input.CONTROLLER_BUTTON.DPadDown )and currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then --Go back to select the subcat
        removeTempObject()
        I.ZackUtils.deleteItem(currentMainRef)
        selectedIndexMain = selectedIndex
        selectedIndex = selectedIndexSubCat

        currentMainRef = nil
        currentSubCat = nil
        updateActiveObjects()
    elseif (((key.code == input.KEY.DownArrow) or controller == input.CONTROLLER_BUTTON.DPadDown) and currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false) then --go back to category
        currentCategory = nil
        updateActiveObjects()
        selectedIndexSubCat = selectedIndex
        selectedIndex = selectedIndexCat
    end

    if key.symbol == 'x' then
    elseif key.symbol == 'g' and zPosLock == 0 and currentMainRef ~= nil then
        zPosLock = currentMainRef.position.z
        updateUi()
    elseif key.symbol == 'g' and zPosLock ~= 0 then
        zPosLock = 0
        updateUi()
    elseif key.symbol == 'n' then --stamp
        collisionEnabled = not collisionEnabled
    elseif key.symbol == 'z' then

    end
end
local backStart = 0
local YPress = 0
local BPress = 0
local function onControllerButtonRelease(id)
    if (id == input.CONTROLLER_BUTTON.Back) then
        if core.getGameTime() - backStart > 15 then
            buildModeEnabled = not buildModeEnabled
            updateBuildModeState()
            updateActiveObjects()
            updateUi()
        else --single press
            if (selectedItemIsReal == false) then
                removeTempObject()
            end
            if (currentMainRef.type ~= types.NPC) then
                I.ZackUtils.deleteItem(currentMainRef)
                currentMainRef = nil
                selectedItemIsReal = false
            end
        end
    end
    if (id == input.CONTROLLER_BUTTON.Y) then
        --print(core.getGameTime() - YPress)
        if core.getGameTime() - YPress > 15 and currentMainRef ~= nil then --double pressed
            if (zPosLock == 0) then
                zPosLock = currentMainRef.position.z
                ui.showMessage("Locked Z Position")
            else
                zPosLock = 0
            end
        else
            collisionEnabled = not collisionEnabled
            updateUi()
        end
    end
    if (id == input.CONTROLLER_BUTTON.B) then
        -- print(core.getGameTime() - BPress)
        if core.getGameTime() - BPress > 15 then --double pressed
            local swingAt = I.ZackUtils.getObjInCrosshairs().hitObject
            if (swingAt ~= nil and findObjectById(swingAt.recordId) ~= nil) then
                ui.showMessage("Set grid reference object to " .. findObjectById(swingAt.recordId).Name)
                gridRefOb = swingAt
                gridRefOb = swingAt
                -- print(gridRefOb.position)
                print("set grid Ref OB" .. swingAt.recordId .. gridRefOb.recordId)
            else
                ui.showMessage("Removed grid reference object")
                print("Removed Grid Ob")
                gridRefOb = nil
            end
        else
            if (currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then --Go back to select the subcat
                removeTempObject()
                I.ZackUtils.deleteItem(currentMainRef)
                selectedIndexMain = selectedIndex
                selectedIndex = selectedIndexSubCat

                currentMainRef = nil
                currentSubCat = nil
                updateActiveObjects()
            elseif (currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false) then --go back to category
                currentCategory = nil
                updateActiveObjects()
                selectedIndexSubCat = selectedIndex
                selectedIndex = selectedIndexCat
            end
        end
    end
end
local function onControllerButtonPress(id)
    if (id == input.CONTROLLER_BUTTON.Back) then
        backStart = core.getGameTime()
    end
    if (id == input.CONTROLLER_BUTTON.Y) then
        YPress = core.getGameTime()
    end
    if (id == input.CONTROLLER_BUTTON.B) then
        BPress = core.getGameTime()
    end
    handleInput(nil, id)
end
local function onKeyPress(key)
    handleInput(key, nil)
end


local waitTime = 0
local function onUpdate(dt)

end
local categories = {}
local function onLoad()

end
local rightSkip = false
local leftSkip = false
local lookMode = false
local thingToKill = nil
local wasSwinging = false
local function onFrame(dt)
    -- updateUi()

    if (core.isWorldPaused()) then
        return
    end
    if (#tempObjects > 1) then
        print("Error! Too many!")
    end
    if (self.controls.use > 0 and types.Actor.stance(self) == types.Actor.STANCE.Weapon) then
      --  wasSwinging = true
      --  print("Swinging")
    else
        --if (wasSwinging == true) then
        --    local swingAt = I.ZackUtils.getObjInCrosshairs()
        --    if (swingAt.hitObject) then
        --        if string.sub(swingAt.hitObject.recordId, 1, 12) == "terrain_rock" then
        --            ui.showMessage("You mine the rocks")
        --            thingToKill = swingAt.hitObject
        --        elseif string.sub(swingAt.hitObject.recordId, 1, 10) == "flora_tree" then
        --            ui.showMessage("You cut down the tree")
        --            thingToKill = swingAt.hitObject
        --        end
        --    else
       --         print("No hit")
       --     end

         --   wasSwinging = false
        --end
    end
    if (thingToKill) then
        I.ZackUtils.teleportItem(thingToKill,
            util.vector3(thingToKill.position.x, thingToKill.position.y, thingToKill.position.z - 10),
            thingToKill.rotation)

        if (thingToKill.position.z < 0) then
            I.ZackUtils.deleteItem(thingToKill)
            thingToKill = nil
        end
    end
    if (buildModeEnabled == false) then
        return
    end
    waitTime = waitTime + dt
    if (waitTime > 0.3) then
        waitTime = 0
        updateUi()
    end
    if (awaitingNewItem == true) then
        -- create a new item result
        currentMainRef = I.ZackUtils.createItemResult()
        -- check if the item result is not nil
        if (currentMainRef ~= nil) then
            table.insert(tempObjects, currentMainRef)
            -- save the item info to the table
            table.insert(itemInfo,
                {
                    recordId = currentMainRef.recordId,
                    --     positionZ = currentMainRef.position.z - currentMainRef.boundingBox.min.z
                })
            -- reset the awaitingNewItem flag
            awaitingNewItem = false
        end
    end
    if (awaitingNewItemToStore == true) then
        local testRef = I.ZackUtils.createItemResult()
        if (testRef ~= nil) then
            if (gridRefOb == nil and findObjectById(testRef.recordId).Grid_Size > 0) then
                gridRefOb = testRef
                print("Setting RefOb")
                --  print(gridRefOb.position)
            end
            awaitingNewItemToStore = false
            table.insert(placedRefs, testRef)
            core.sendGlobalEvent("exitBuildMode", { placedItem = testRef, player = self })
        end
    end
    ---
    --normally the controller view stick can't be used while in controls disabled mode, so we re-enable it while the stick is used
    if ((input.getAxisValue(input.CONTROLLER_AXIS.RightX) > 0.1 or input.getAxisValue(input.CONTROLLER_AXIS.RightX) < -0.1) or (input.getAxisValue(input.CONTROLLER_AXIS.RightY) > 0.1 or input.getAxisValue(input.CONTROLLER_AXIS.RightY) < -0.1)) then
        if (lookMode == false) then
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)

            I.ControlsZack.overrideMovementControls(true)
            I.Controls.overrideMovementControls(false)
            lookMode = true
        end
    else
        if (lookMode == true) then
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)

            I.ControlsZack.overrideMovementControls(false)
            I.Controls.overrideMovementControls(true)
            lookMode = false
        end
    end
    ---
    if (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.RightStick)) then
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0) then
            zPosManOffset = zPosManOffset + (1 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight))
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0) then
            zPosManOffset = zPosManOffset - (1 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft))
        end
    elseif (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftStick)) then
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0) then
            obDistance = obDistance + (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight))
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0) then
            obDistance = obDistance - (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft))
        end
    else
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0 and rightSkip == false) then
            local grid = false
            local findOb = findObjectById(currentMainRef.recordId)
            if (findOb) then
                gridSize = findOb.Grid_Size
                grid = gridSize > 0
            end
            if (grid and gridRefOb == nil) then
                grid = false
            end
            if (grid) then
                zDegrees = normalize_degrees(zDegrees + 90)
                rightSkip = true
            else
                zDegrees = normalize_degrees(zDegrees + (2 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)))
            end
            zDegrees = normalize_degrees(zDegrees + (2 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)))
        elseif (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) == 0) then
            rightSkip = false
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0 and leftSkip == false) then
            local grid = false
            local findOb = findObjectById(currentMainRef.recordId)
            if (findOb) then
                gridSize = findOb.Grid_Size
                grid = gridSize > 0
            end
            if (grid and gridRefOb == nil) then
                grid = false
            end
            if (grid) then
                zDegrees = normalize_degrees(zDegrees - 90)
                leftSkip = true
            else
                zDegrees = normalize_degrees(zDegrees - (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft)))
            end
        elseif (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) == 0) then
            leftSkip = false
        end
    end


    if (playerpath ~= nil and #playerpath > 0) then
        local currentPoint = playerpath[1]
        I.ZackUtils.teleportItem(self, currentPoint)
        table.remove(playerpath, 1)
    end
    if currentMainRef and currentMainRef.type ~= types.NPC then
        local hitObject = currentMainRef
        local hitPos
        if I.ZackUtils.getObjInCrosshairs(hitObject, obDistance).hitPos and collisionEnabled then
            hitPos = I.ZackUtils.getObjInCrosshairs(hitObject, obDistance).hitPos
        else
            hitPos = I.ZackUtils.getPosInCrosshairs(obDistance)
        end
        if (hitPos == nil) then
            return
        end
        local pos, v = getCameraDirData()
        local dist = 50
        local toPos
        local toRot = util.vector3(currentMainRef.rotation.x, currentMainRef.rotation.y, math.rad(zDegrees))
        local zPos = hitPos.z
        if (zPosLock == 1) then
            zPosLock = currentMainRef.position.z
            -- print("Now locked")
        elseif (zPosLock == 0) then --do nothing
            -- print("Not locked")
        else
            zPos = zPosLock
            -- print("Is locked")
        end
        local zOffset = 0
        local gridSize = 0
        if (currentMainRef == nil) then
            return
        end
        local findOb = findObjectById(currentMainRef.recordId)
        if (findOb) then
            if (findOb.Grid_Size > 0) then
                zDegrees = normalize_degrees(math.floor((zDegrees + 45) / 90) * 90)
            end
        end

        local grid = false
        if (findOb) then
            if (hitObject) then
                zOffset = findOb.Z_Offset --hitObject.position.z - hitObject.boundingBox.min.z
            end
            -- zOffset = findOb.Z_Offset
            gridSize = findOb.Grid_Size
            grid = gridSize > 0
        end
        if (grid and gridRefOb == nil) then
            print("grid ref ob is nil")
            grid = false
        end

        if (grid == false) then
            toPos = pos + v * dist
            toPos = util.vector3(hitPos.x + offsetX, hitPos.y + offsetY, zPos + zOffset + zPosManOffset + offsetZ)
        else
            toPos = util.vector3(
                math.floor((gridRefOb.position.x + 128) / gridSize) *
                gridSize,
                math.floor((gridRefOb.position.y + 128) / gridSize) *
                gridSize,
                math.floor((gridRefOb.position.z + 148) /
                    gridSize) *
                gridSize - 128 + zPosManOffset
            )
            toPos = toPos - gridRefOb.position

            toPos = util.vector3(
                (math.floor((hitPos.x + 128) / gridSize) *
                    gridSize) - toPos.x,
                (math.floor((hitPos.y + 128) / gridSize) *
                    gridSize) - toPos.y,
                (math.floor((zPos + 148) /
                        gridSize) *
                    gridSize - 128) - toPos.z
            )
        end
        local zPos = toPos.z
        if (zPosLock > 0) then
            zPos = zPosLock
        end

        if hitPos and hitObject then
            I.ZackUtils.teleportItem(hitObject,

                util.vector3(toPos.x, toPos.y, zPos), toRot)
        end
    end
end
local function onSave()
    buildModeEnabled = false
    updateBuildModeState()
end

return {
    interfaceName = "MoveObjects",
    interface = {
        version = 1,
    },
    eventHandlers = {
        StartControlMode = StartControlMode,
    },
    engineHandlers = {
        onInputAction = onInputAction,
        onControllerButtonPress = onControllerButtonPress,
        onControllerButtonRelease = onControllerButtonRelease,
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onFrame = onFrame,
        onLoad = onLoad,
        onSave = onSave,
        onInit = onLoad,
    }
}
