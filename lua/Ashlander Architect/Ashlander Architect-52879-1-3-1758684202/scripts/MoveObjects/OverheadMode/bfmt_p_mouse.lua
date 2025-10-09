local core = require "openmw.core"
local input = require("openmw.input")
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local async = require('openmw.async')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local startTime = core.getRealTime() -- Start time since the game started
local storage = require('openmw.storage')


local config = require("scripts.MoveObjects.config")
local contextMenu = require("scripts.moveobjects.utility.contextMenu")
local mposx, mposy = 0, 0
local testBox

local rPressStartPos
local lPressStartPos
local colType = nearby.COLLISION_TYPE.AnyPhysical
local rWasPressed, lWasPressed = false, false
local mouseWorldPos
local canClickThings = true
local mousedOverObject
local clickedWorldPos
local clickedObject
local renameWindow

local nameToSend = ""
local function clickThing(name)
    --"Remove Last Added Object","Exit Dev Mode","Teleport Player To Pos"
    if name == "Remove Last Added Object" then
        core.sendGlobalEvent("removeLastAddedObject")
    elseif name == "Teleport Player To Pos" then
        core.sendGlobalEvent("TPPlayerToPos", clickedWorldPos)
    elseif name == "Exit Dev Mode" then
        I.BFMT_Cam.exitCamMode()
        I.CellGen2_DisplayInfo.setDevMode(false)
        core.sendGlobalEvent("resetState_AA")
    elseif name == "Finish Structure" then
        I.CellGen2_DisplayInfo.createWindow({})
    elseif name == "Add selected object as custom item" then
        renameWindow = I.DaisyUtilsUI_AA.renderTextInput(
            { "", "",
                "What would you like this object to be named?" }, "", function(name) nameToSend = name end, 
                function()
                local zOffset = self.position.z - clickedObject.position.z
                zOffset = -zOffset
                local csvline =
                    clickedObject.recordId ..
                    ",noimage," .. nameToSend .. ",Custom Objects,Custom Objects," ..
                    tostring(zOffset) .. ",0,0,static,2000,24,,,"
                renameWindow:destroy()
                renameWindow = I.DaisyUtilsUI_AA.renderTextInput(
                    { "", "",
                        "Item created. " }, csvline, function(name) end, function()
                        renameWindow:destroy()
                        renameWindow = nil
                        core.sendGlobalEvent("saveObjectGen", {id =   clickedObject.recordId,csvline = csvline })
                        async:newUnsavableSimulationTimer(0.1, function()
                            canClickThings = true
                        end)
                    end)
            end)
        return
    end

    async:newUnsavableSimulationTimer(0.1, function()
        canClickThings = true
    end)
end
local function edgeScroll(normPos)
    if not I.BFMT_Cam then return end
    local verticalMove
    local horizontalMove
    if normPos.x < 0.05 then     --left
        verticalMove = "left"
    elseif normPos.x > 0.95 then --right
        verticalMove = "right"
    end
    if normPos.y < 0.05 then                       --up
        horizontalMove = "up"
    elseif normPos.y > 0.95 and normPos.y < 1 then --down
        horizontalMove = "down"
    end
    if normPos.y < 0.05 and normPos.x < 0.05 then
        I.BFMT_Cam.edgeScroll(nil, nil)
        return
    end
    I.BFMT_Cam.edgeScroll(verticalMove, horizontalMove)
end

local function normalizeScreenPos(cursorPos)
    local screenSize = ui.layers[1].size
    local normalizedX = cursorPos.x / screenSize.x
    local normalizedY = cursorPos.y / screenSize.y
    return util.vector2(normalizedX, normalizedY)
end

local function onFrame(dt)
    if not I.BFMT_Cam then return end
    if testBox then
        testBox:destroy()
    else
    end
    if not I.BFMT_Cam.isInOverheadMode() then
        return
    end
    mposx = mposx + input.getMouseMoveX()
    mposy = mposy + input.getMouseMoveY()
    if mposx < 0 then
        mposx = 0
    end
    if mposy < 0 then
        mposy = 0
    end

    local function checkTarget(ray)
        if ray.hitObject and types.Actor.objectIsInstance(ray.hitObject) then return true end
        local delta = ray.hitPos - self.position
        return delta.z < 160 or delta.z < 0.5 * delta:length()
    end


    local function findObjectUnderMouse(cursorPos)
        local ignoreCheck = I.MoveObjects.getCurrentMainRef()
        local delta = camera.viewportToWorldVector(cursorPos)
        local basePos = camera.getPosition() + delta
        local endPos = basePos + delta * 2000
        local res = nearby.castRay(basePos, endPos, {
            collisionType = colType,

            ignore = ignoreCheck
        })
        local retPos = res.hitPos
        if not retPos then
            retPos = basePos + delta * 2000
        end
        return res.hitObject, retPos
    end
    local rightButtonPressed = input.isMouseButtonPressed(3)
    local leftButtonPressed = input.isMouseButtonPressed(1)
    local rightButtonPressedOnce = rightButtonPressed and not rWasPressed
    local leftButtonPressedOnce = leftButtonPressed and not lWasPressed
    local spos = normalizeScreenPos(util.vector2(mposx, mposy))
    edgeScroll(spos)
    local check, pos = findObjectUnderMouse(spos)
    if pos then
        mouseWorldPos = pos
    else
        print("no hitpos")
    end
    mousedOverObject = check
    if rightButtonPressed and rightButtonPressedOnce then
        rPressStartPos = util.vector2(mposx, mposy)
    end
    if leftButtonPressed and leftButtonPressedOnce then
        lPressStartPos = util.vector2(mposx, mposy)
    end
    if leftButtonPressed then
        local diff = lPressStartPos - util.vector2(mposx, mposy)
        I.MoveObjects.camMovement(diff, dt)
    end
    if rightButtonPressed then
        local diff = rPressStartPos - util.vector2(mposx, mposy)
        I.BFMT_Cam.camMovement(diff)
    end
    if rightButtonPressedOnce or leftButtonPressedOnce then
        if leftButtonPressedOnce and not contextMenu.openedUI and not I.CellGen2_DisplayInfo.hasWindow() and canClickThings then
           -- I.MoveObjects.onInputAction(input.ACTION.Use)
            if I.CellGen2_DisplayInfo.isInDevMode() and mousedOverObject then
                ui.showMessage("Added " .. mousedOverObject.recordId)
                core.sendGlobalEvent("addObject_AA", mousedOverObject)
            end
        end
        if rightButtonPressedOnce then
            if I.CellGen2_DisplayInfo.isInDevMode() then
                clickedWorldPos = pos
                canClickThings = false
                local buttons = { "Remove Last Added Object", "Exit Dev Mode", "Teleport Player To Pos",
                    "Finish Structure" }
                local ls = I.moveobjects_data.objectTypes

                if mousedOverObject then
                    local found = false
                    for index, value in ipairs(ls) do
                        if value.EditorId == mousedOverObject.recordId then
                            found = true
                        end
                    end
                    if not found then
                        clickedObject = mousedOverObject
                        table.insert(buttons, "Add selected object as custom item")
                    end
                end
                contextMenu.createContextMenu(
                    buttons, clickThing, { windowPos = spos })
            end
            --  I.MoveObjects.onInputAction(input.ACTION.Inventory)
        end
        I.BFMT_Selection.processMouseClick(pos, check, rightButtonPressedOnce, leftButtonPressedOnce)
    end
    local selObj = I.BFMT_Selection.getSelectedObjects()
    local selText = {}
    if mousedOverObject and mousedOverObject:isValid() then
        selText = { mousedOverObject.recordId }
    end

    if selObj and #selObj > 0 then
        -- selText = {}
        for index, value in ipairs(selObj) do
            --     table.insert(selText, value.type.record(value).name)
        end
    end
    testBox = I.DaisyUtilsUI.renderItemChoice(selText, mposx,
        mposy)
    lWasPressed = leftButtonPressed
    rWasPressed = rightButtonPressed
end
local function resetCursorLoc()
    mposx = 0
    mposy = 0
end
local function onKeyPress(key)
    if not I.BFMT_Cam.isInOverheadMode() then
        return
    end
    if key.symbol == 'u' then
        mposx = 0
        mposy = 0
    end
end
local function getMousedOverObject()
    return mousedOverObject
end
local function getMouseWorldPos()
    return mouseWorldPos
end
local function setColType(ty)
    colType = ty
end
--I.UI.setMode("Interface", { windows = {} })
return {
    interfaceName = "BFMT_Mouse",
    interface = {
        getMouseWorldPos = getMouseWorldPos,
        getMousedOverObject = getMousedOverObject,
        resetCursorLoc = resetCursorLoc,
        setColType = setColType,
        getMousePos = function() return util.vector2(mposx, mposy) end,
        getNormMousePos = function() return normalizeScreenPos(util.vector2(mposx, mposy)) end,
    },
    engineHandlers = { onFrame = onFrame, onKeyPress = onKeyPress, }
}
