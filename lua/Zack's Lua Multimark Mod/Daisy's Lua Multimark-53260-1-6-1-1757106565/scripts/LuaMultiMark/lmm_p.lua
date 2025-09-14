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
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local editMode = false
local keys = input.KEY
local ctrl = input.CONTROLLER_BUTTON
local markData = {}
local lastPosData = nil
local menuMode = false
local markCount = 1
local recallWindow = nil -- Define a comparison function to compare the 'numVal' property
local bindingsWin = nil
local zutilsUI = require("scripts.luamultimark.zu_ui")
--local camera_controller = require("scripts.LuaMultiMark.camera_controller")
local gmst_checker = require("scripts.LuaMultiMark.GMST_Checker")

local effect_checker = require("scripts.LuaMultiMark.Effect_Checker")

local function getMarkDataLength()
    local count = 0
    for index, value in pairs(markData) do
        count = count + 1
    end
    return count
end
local timePassed = 0
local gmstNeeded = true

if gmstNeeded then
    local isValid = gmst_checker.checkValues()
    local isValid2 = effect_checker.checkValues()
    if not isValid or not isValid2 then
        I.Settings.registerPage {
            key = "SettingsMultiMark",
            l10n = "SettingsMultiMark",
            name = "Daisy's Lua Multimark",
            description = "Your game settings are not set as expected, likely due to a load order issue. Please ensure that the mod is loaded after the base game and any other mods that may affect the GMSTs sEffectSummonCreature04, sEffectSummonCreature05, sMagicCreature04ID, and sMagicCreature05ID."
        }
        return {
            engineHandlers = {
                onUpdate = function(dt)
                    timePassed = timePassed + dt
                    if timePassed > 1 then
                        timePassed = 0
                        ui.showMessage(
                            "Lua MultiMark: Game settings are not set correctly. Check your load order, for more info open your mod settings menu.")
                    end
                end

            }
        }
    else
        print("GMSTs are valid")
    end
end
I.Settings.registerPage {
    key = "SettingsMultiMark",
    l10n = "SettingsMultiMark",
    name = "Daisy's Lua Multimark",
    description = "These settings allow you to modify the behavior of multimark."
}
local itemWindowLocs = {
    TopLeft = "Top Left",
    TopRight = "Top Right",
    BottomLeft = "Bottom Left",
    BottomRight = "Bottom Right",
    Disabled = "Disabled"
}
local function getWindowLocs()
    local ret = {}
    for key, value in pairs(itemWindowLocs) do
        table.insert(ret, value)
    end
    return ret
end

local function closeWindows()
    if recallWindow then
        recallWindow:destroy()
        --recallWindow = nil
    end
    if bindingsWin then
        bindingsWin:destroy()
        bindingsWin = nil
    end
end

I.Settings.registerGroup {
    key = "SettingsMultiMark",
    page = "SettingsMultiMark",
    l10n = "SettingsMultiMark",
    name = "Main Settings",
    permanentStorage = true,
    settings = {

        {
            key = "levelsPerMark",
            renderer = "number",
            name = "Skill Requirement Per Mark",
            description =
            "How many points of Mysticism will be required per mark location. If this is set to 5, and you have 25 Mysticism, you will have 5 mark points.",
            default = 5
        },
        {
            key = "baseMarkCount",
            renderer = "number",
            name = "Base Mark Count",
            description =
            "How many mark points will be available at level 0. May be negative. If this is set to 5, and you have 25 Mysticism, you will have 10 mark points. If it is set to -5, you will have not have any mark points until you hit 30 mysticism.",
            default = 0
        },
        {
            key = "enableFollowerTP",
            renderer = "checkbox",
            name = "Allow Follower Teleportation",
            description =
            "If enabled, will allow followers to teleport with you when you cast recall.",
            default = true
        },
        {
            key = "tableRowCount",
            renderer = "number",
            name = "List Length",
            description =
            "How many location marks are shown in a list. Default is 10.",
            default = 10
        },
        -- {
        --     key = "enableCameraFreeze",
        --     renderer = "checkbox",
        --     name = "Enable Camera Freeze",
        --      description =
        --     "If enabled, will freeze the camera while in the recall menu. May cause you to be frozen when leaving that menu, so turn it off if you have issues.",
        --     default = false
        -- },
        {
            key = "InfoWindowLocation",
            renderer = "select",
            l10n = "AshlanderArchitectButtons",
            name = "Info Window Location",
            description =
            "Allows you to change the window that will display the button information, also allows you to disable it.",
            default = "Top Left",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = getWindowLocs()
            },
        },
    },

}

local playerSettings = storage.playerSection("SettingsMultiMark")
local function compareNumVal(a, b)
    return a.numVal < b.numVal
end

local camData = nil
local playerRot = nil
local function canTeleport()
    if types.Player.isTeleportingEnabled ~= nil then --0.49(recent)
        local check = types.Player.isTeleportingEnabled(self)
        if not check then
            ui.showMessage(core.getGMST("sTeleportDisabled"))
            return false
        else
            return true
        end
    end
    if self.cell.name == "Akulakhan's Chamber" then
        return false
    end
    return true
end

local function setPauseMode(val)
    menuMode = val
    if core.API_REVISION > 30 then
        if val then
            I.UI.setMode('Interface', { windows = {} })
        else
            I.UI.setMode()
        end
        return
    end
end

local lastWinState = false
local keyBindings = require("scripts.LuaMultiMark.lmm_bindings")
local function contextCheck(keyBinding, context)
    for index, value in ipairs(keyBinding.context) do
        if value:lower() == context:lower() then
            return true
        end
    end
    return false
end

function keyBindings.getButtonLabel(bindingName, controllerMode)
    local binding = bindingName
    if not binding then return "nothing" end
    if not controllerMode then
        for key, value in pairs(input.KEY) do
            if value == binding.key then
                return key
            end
        end
    else
        for key, value in pairs(input.CONTROLLER_BUTTON) do
            if value == binding.ctrl then
                return key
            end
        end
    end
end

local inputAction = nil
-- replaced previous checkBinding. Added isController check(which should probably be
-- a singe onLoad(or even more suited once called function) to see if it mouse or controller but this works as is now)
local function checkBinding(kbinding, key, ctrl, isController)
    if kbinding.context and not contextCheck(kbinding, recallWindow.context) then
        return false
    end

    local action = (not isController and kbinding.mouseAction) or kbinding.inputAction

    if key == kbinding.key or ctrl == kbinding.ctrl then
        return true
    end

    if inputAction ~= nil then
        if inputAction == action or inputAction == kbinding.inputAction2 then
            return true
        end
    end

    if kbinding.key2 and key == kbinding.key2 then
        return true
    end

    return false
end

local function enterEditMode()
    editMode = true
    recallWindow.editMode = true
    recallWindow.editLine = recallWindow:getItemAt(recallWindow.selectedPosX, recallWindow.selectedPosY).label
end

--- Returns the index of the currently selected mark in `markData` based on selected UI position.
--- Seems to function for a x,y type of selection tracking but not sure it actually has any mapping for that
--- since for list variant it completely disregards second variable and uses X as a RowY equivalent
-- @return number: The index (1-based) of the selected mark in `markData`, or -1 if not found.
local function getSelectedMarkIndex()
    if not recallWindow then
        return -1
    end

    local selectedX = recallWindow.selectedPosX
    local selectedY = recallWindow.selectedPosY

    local selectedData = recallWindow:getItemAt(selectedX, selectedY)
    if not selectedData then
        return -1
    end

    for index, mark in ipairs(markData) do
        if mark == selectedData then
            return index
        end
    end

    return -1
end
--- Swap two marks' order by swapping their numVal, then resort & refresh the list.
local function swapMarkOrderByIndices(i, j)
    if not markData[i] or not markData[j] then return end
    -- swap the ordering key so saved data reflects the change
    markData[i].numVal, markData[j].numVal = markData[j].numVal, markData[i].numVal
    table.sort(markData, compareNumVal)
    if recallWindow then
        recallWindow.list = markData
    end
end

--- Move the currently selected mark up/down by delta (-1 up, +1 down).
--- Keeps the highlight on the moved item and adjusts scroll when needed.
local function moveSelectedMark(delta)
    if not recallWindow or not recallWindow.listMode then return end
    local selectedx = recallWindow.selectedPosX
    local selectedy = recallWindow.selectedPosY

    -- Find absolute index (in markData) of the selected row
    local idx = getSelectedMarkIndex()
    if idx < 1 then return end

    local newIdx = idx + delta
    if newIdx < 1 or newIdx > #markData then return end

    swapMarkOrderByIndices(idx, newIdx)

    -- Visually keep the selection on the moved item:
    local listLen = I.LMM.getListLength()
    if delta < 0 then
        -- moved up: shift the selection up one "visible" row if possible,
        -- otherwise scroll up if we're at the top of the window
        if recallWindow.selectedPosX > 1 then
            recallWindow.selectedPosX = recallWindow.selectedPosX - 1
        elseif recallWindow.scrollOffset > 0 then
            recallWindow.scrollOffset = recallWindow.scrollOffset - 1
        end
    else
        -- moved down: shift the selection down one "visible" row if possible,
        -- otherwise scroll down to keep it in view
        local nextX = recallWindow.selectedPosX + 1
        if nextX <= listLen and recallWindow:getItemAt(nextX, selectedy) then
            recallWindow.selectedPosX = nextX
        else
            -- hit bottom of window; advance scroll if there are more items
            recallWindow.scrollOffset = recallWindow.scrollOffset + 1
        end
    end

    recallWindow:reDraw()
end
local function doRecall(index, iw)
    if not iw then
        iw = recallWindow
    end
    if not iw and not recallWindow then return end
    local data = recallWindow:getItemAt(index, iw.selectedPosY)
    if data then
        if playerSettings:get("enableFollowerTP") == true then
            for index, value in ipairs(nearby.actors) do
                if value.type ~= self.type then
                    value:sendEvent("teleportFollower",
                        { destPos = data.position, destCell = data.cell, destRot = data.rotation })
                end
            end
        end
        core.sendGlobalEvent("LMM_TeleportToCell",
            {
                item = self,
                cellname = data.cell,
                position = data.position,
                rotation = data.rotation
            })
    end
    closeWindows()
    setPauseMode(false)
end

local function saveMarkOverwrite(selectedx, selectedy)
    if not recallWindow then
        return
    end
    local data = recallWindow:getItemAt(selectedx, selectedy)
    local useMark = 0
    local usePosition = -1
    if data then
        for index, value in ipairs(markData) do
            if value == data then
                table.remove(markData, index)
                usePosition = index
                useMark = value.numVal
                table.sort(markData, compareNumVal)
                recallWindow.list = markData
                if not recallWindow:getItemAt(selectedx, selectedy) then
                    recallWindow.selectedPosX = recallWindow.selectedPosX - 1
                end
                break
            end
        end
    end
    if playerSettings:get("enableCameraFreeze") == true then
        core.sendGlobalEvent("LMM_paralyzePlayer", "end")
    end
    I.LMM.saveMarkLoc(useMark, true, usePosition)

    closeWindows()

    setPauseMode(false)
end

--- Handles user input for the recall window, including edit mode, navigation, selection, and mark management.
-- @param key number | nil: The key code pressed (can be nil when using inputAction instead).
-- @param ctrl boolean | nil: True if the input is from controller, false if from keyboard/mouse, nil if unknown.
-- @param str string | nil: The character string entered (used in edit mode), can be nil.
-- @param action number | nil: An action ID from input bindings, used for matching controller/mouse input.
local function processInput(key, ctrl, str, action)
    if ctrl ~= nil then
        keyBindings.controllerMode = ctrl
    end

    inputAction = action

    -- Handle edit mode
    if editMode then
        if checkBinding(keyBindings.finishTextEdit, key, ctrl) or key == keys.Enter then
            editMode = false
            recallWindow.editMode = false

            local line = recallWindow.editLine
            local data = recallWindow:getItemAt(recallWindow.selectedPosX, recallWindow.selectedPosY)
            if data then
                for _, value in ipairs(markData) do
                    if value == data then
                        data.label = line
                        recallWindow.list = markData
                        table.sort(markData, compareNumVal)
                        break
                    end
                end
            end
        elseif key == keys.Backspace then
            recallWindow.editLine = recallWindow.editLine:sub(1, -2)
        else
            if str and str ~= "" then
                if input.isShiftPressed() then
                    str = str:upper()
                end
                recallWindow.editLine = recallWindow.editLine .. str
            end
        end

        recallWindow:reDraw()
        return
    end

    if not recallWindow then
        lastWinState = true
        return
    end

    lastWinState = false

    local selectedx = recallWindow.selectedPosX
    local selectedy = recallWindow.selectedPosY
    local isController = keyBindings.controllerMode

    -- Move up
    if checkBinding(keyBindings.navUp, key, ctrl, isController) then
        if recallWindow.listMode then
            if input.isShiftPressed() then
                -- NEW: raise the selected item
                moveSelectedMark(-1)
            else
                -- existing navigation
                if selectedx > 1 and recallWindow:getItemAt(selectedx - 1, selectedy) then
                    recallWindow.selectedPosX = selectedx - 1
                elseif recallWindow.scrollOffset > 0 then
                    recallWindow.scrollOffset = recallWindow.scrollOffset - 1
                end
            end
        end

        -- Move down
    elseif checkBinding(keyBindings.navDown, key, ctrl, isController) then
        if recallWindow.listMode then
            if input.isShiftPressed() then
                -- NEW: lower the selected item
                moveSelectedMark(1)
            else
                -- existing navigation
                local listWidth = I.LMM.getListLength()
                local nextX = selectedx + 1
                local item = recallWindow:getItemAt(nextX, selectedy)

                if nextX < listWidth and item then
                    recallWindow.selectedPosX = nextX
                elseif nextX >= listWidth and item then
                    recallWindow.scrollOffset = recallWindow.scrollOffset + 1
                end
            end
        end
    elseif checkBinding(keyBindings.selectMarkOverwrite, key, ctrl) and not lastWinState then
        saveMarkOverwrite(selectedx, selectedy)
        return
        -- not sure it is a good idea, because it still invokes keypress and thus
        -- any binding on a number(ie item or spell) will be used after teleportation
        -- is it desireable?
        -- suggested course of action is to use `input.registerTriggerHandler(key, callback)`
        -- meaning another major rework and refactor
    elseif tonumber(str) then
        local data = recallWindow:getItemAt(tonumber(str), selectedy)
        if data then
            if playerSettings:get("enableFollowerTP") then
                for _, actor in ipairs(nearby.actors) do
                    if actor.type ~= self.type then
                        actor:sendEvent("teleportFollower", {
                            destPos = data.position,
                            destCell = data.cell,
                            destRot = data.rotation
                        })
                    end
                end
            end

            core.sendGlobalEvent("LMM_TeleportToCell", {
                item = self,
                cellname = data.cell,
                position = data.position,
                rotation = data.rotation
            })
        end

        closeWindows()
        setPauseMode(false)
        return
    elseif checkBinding(keyBindings.selectMarkDest, key, ctrl)
        and not lastWinState and recallWindow.context == "normal" then
        if not canTeleport() then return end
        doRecall(recallWindow.selectedPosX)
        return
    elseif checkBinding(keyBindings.enterEditMode, key, ctrl)
        and recallWindow:getItemAt(selectedx, selectedy)
        and not editMode then
        enterEditMode()
    elseif checkBinding(keyBindings.deleteItem, key, ctrl) then
        local data = recallWindow:getItemAt(selectedx, selectedy)
        if data then
            for index, value in ipairs(markData) do
                if value == data then
                    table.remove(markData, index)
                    table.sort(markData, compareNumVal)
                    recallWindow.list = markData

                    if not recallWindow:getItemAt(selectedx, selectedy) then
                        recallWindow.selectedPosX = math.max(1, selectedx - 1)
                    end
                    break
                end
            end
        end
    elseif checkBinding(keyBindings.cancelMenu, key, ctrl)
        or checkBinding(keyBindings.cancelMenuOverwrite, key, ctrl) then
        closeWindows()
        setPauseMode(false)

        if playerSettings:get("enableCameraFreeze") then
            core.sendGlobalEvent("LMM_paralyzePlayer", "end")
        end
        return
    end

    recallWindow:reDraw()
end

local function drawListMenu(buttonTable)
    --closeWindows()
    local winLoc = playerSettings:get("InfoWindowLocation")
    local wx = 0
    local wy = 0
    local align = nil
    local anchor = nil
    if winLoc == itemWindowLocs.TopLeft then
        wx = 0
        wy = 0
        align = ui.ALIGNMENT.Start
    elseif winLoc == itemWindowLocs.TopRight then
        wx = 1
        wy = 0
        anchor = util.vector2(1, 0)
        align = ui.ALIGNMENT.End
    elseif winLoc == itemWindowLocs.BottomLeft then
        wx = 0
        wy = 1
        anchor = util.vector2(0, 1)
        align = ui.ALIGNMENT.End
    elseif winLoc == itemWindowLocs.BottomRight then
        wx = 1
        wy = 1
        anchor = util.vector2(1, 1)
        align = ui.ALIGNMENT.Start
    elseif winLoc == itemWindowLocs.Disabled then
        return
    end
    bindingsWin = zutilsUI.renderItemChoice(buttonTable, wx, wy, align, anchor)
end

--- Opens the mark menu UI if teleportation is allowed and marks are available.
--- Sorts the mark data, creates the item selection window, configures control hints,
--- and activates the interface. Also pauses the game during interaction.
---
--- @param context string|nil Optional UI context to initialize the recall window (e.g., "normal", "overwrite").
local function openMarkMenu(context)
    if not canTeleport() then return end
    if getMarkDataLength() == 0 then
        ui.showMessage("There are no marked locations. Cast the spell mark before casting recall.")
        return
    end

    table.sort(markData, compareNumVal)

    -- print("openMarkMenu markData.rowCountY: " .. tostring(markData.rowCountY))

    local lengthY = I.LMM.getListLength()
    recallWindow = I.LMM_Window.createItemWindow(markData, 0.5, 0.5, context, lengthY)

    local buttonTable = {}
    local kb = I.LMM.getKeyBindings()
    if kb.controllerMode then
        table.insert(buttonTable, "DPad: Navigate (Hold shift to reorder list)")
    else
        table.insert(buttonTable, "Arrow Keys: Navigate (Hold shift to reorder list)")
    end

    local bindings = I.LMM.getKeyBindings()
    for _, binding in pairs(bindings) do
        if type(binding) == "table" and binding.label and contextCheck(binding, recallWindow.context) then
            local labelText = string.format(
                "%s: %s",
                binding.label,
                kb.getButtonLabel(binding, kb.controllerMode)
            )
            table.insert(buttonTable, labelText)
        end
    end

    drawListMenu(buttonTable)
    recallWindow.selected = true
    -- Question is why is it in the bottom?
    setPauseMode(true)
end

local function trim(s)
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
end

local function formatRegion(regionString)
    -- remove the word "region"
    -- capitalize the first letter of each word
    regionString = string.gsub(regionString, "(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    -- trim any leading/trailing whitespace
    regionString = trim(regionString)
    return regionString
end

local function getAvailableSlot()
    local i = 1
    table.sort(markData, compareNumVal)
    if markData[1] == nil then
        return 1
    end
    local lowest = markData[1].numVal -- Initialize lowest with the first element's numVal
    for i = 2, getMarkDataLength() do
        if markData[i] and markData[i].numVal < lowest then
            lowest = markData[i].numVal -- Update lowest if a smaller value is found
        end
    end

    return lowest
end

--- Returns the number of rows to display in the list.
--- Ensures fallback to default (10) if the setting is missing, zero, or invalid.
--- @return integer: Number of list rows to display
local function getListLength()
    local listY = tonumber(playerSettings:get("tableRowCount")) or 0

    if listY <= 0 then
        return 10 -- Default fallback
    end

    return math.floor(listY)
end

local function getMaxSlots()
    local baseMark = playerSettings:get("baseMarkCount")
    local skillMult = playerSettings:get("levelsPerMark")
    if skillMult == 0 then
        return 800
    end
    local myMyst = types.NPC.stats.skills["mysticism"](self).modified
    local totalSlots = (myMyst / skillMult) + baseMark
    return math.floor(totalSlots)
end

local function saveMarkLoc(useMarkCount, force, usePosition)
    if not canTeleport() then return end
    if usePosition == -1 then
        usePosition = nil
    end
    local firstLabel = self.cell.name
    if firstLabel == "" or firstLabel == nil then
        firstLabel = formatRegion(self.cell.region)
    end
    if firstLabel == "" or firstLabel == nil then
        firstLabel = "Wilderness"
    end
    if I.CellGen2_Labels then
        local check = I.CellGen2_Labels.getLabelForCell()
        if check then
            firstLabel = check
        end
    end
    if getMaxSlots() <= 0 then
        ui.showMessage("Your mysticism level is too low to use this spell.")
        return
    elseif getMarkDataLength() >= getMaxSlots() and not force then
        ui.showMessage("Your mysticism level is too low to save another marked location.")
        openMarkMenu("overwrite")
        return
    end

    if not useMarkCount then
        useMarkCount = markCount
    end
    ui.showMessage("Location marked as " .. firstLabel)
    local data = {
        position = self.position,
        rotation = self.rotation,
        cell = self.cell.id,
        label = firstLabel,
        numVal = useMarkCount
    }
    if usePosition then
        table.insert(markData, usePosition,
            data)
    else
        table.insert(markData,
            data)
    end

    table.sort(markData, compareNumVal)
    markCount = markCount + 1
end
local function isMarking()
    local eff = types.Actor.activeEffects(self):getEffect("mark")
    return eff and eff.magnitude > 0
end
local lastAxis = 0
local threshHold = 0.3
local lastRightPress = false

local prevCell = nil
local prevPos = nil
local prevRot = nil
local wasRecalling = false
local wasMarking = false
local function onUpdate(dt)
    if core.isWorldPaused() then return end
    if not markData then
        markData = {}
    end

    if menuMode then
        local controllerAxis = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
        if controllerAxis > threshHold and lastAxis < threshHold then
            processInput(nil, nil, nil, input.ACTION.ZoomIn)
        elseif controllerAxis > -threshHold and lastAxis < -threshHold then
            processInput(nil, nil, nil, input.ACTION.ZoomOut)
        end
        lastAxis = controllerAxis
        local rightButtonPressed = input.isMouseButtonPressed(3)
        if rightButtonPressed and not lastRightPress then
            closeWindows()
            setPauseMode(false)
        end
        lastRightPress = rightButtonPressed
        return
    end
end

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end

local function onLoad(data)
    if data then
        markData = data.markData
        if data.revVer <= 40 and data.revVer ~= core.API_REVISION then
            --   markData = data.markData
            for index, value in ipairs(markData) do --Apparently this is not needed
                -- value.rotation = createRotation(0,0,0)
            end
        end
        if data.markCount then
            markCount = data.markCount
        end
    end
end

local function onSave()
    if menuMode == true then
        closeWindows()
        setPauseMode(false)
    end
    return { markData = markData, markCount = markCount, revVer = core.API_REVISION }
end

local lastPress = 0
local function onControllerButtonPress(ctrl)
    if menuMode == true then
        if (core.getRealTime() < lastPress + 0.002) then
            return
        end
        processInput(nil, ctrl)
        lastPress = core.getRealTime()
    end
end

local function onControllerButtonRelease(ctrl)

end

local function onKeyPress(key)
    if menuMode == true then
        processInput(key.code, nil, key.symbol)
    end
end

local function onInputAction(action)
    if menuMode == true then
        processInput(nil, nil, nil, action)
    end
end

return {
    interfaceName = "LMM",
    interface = {
        version = 1,
        openMarkMenu = openMarkMenu,
        saveMarkLoc = saveMarkLoc,
        getKeyBindings = function() return keyBindings end,
        getMarkDataLength = getMarkDataLength,
        getMaxSlots = getMaxSlots,
        getListLength = getListLength,
        getSelectedMarkIndex = getSelectedMarkIndex,
        doRecall = doRecall,
        enterEditMode = enterEditMode,
        processInput = processInput,
        saveMarkOverwrite = saveMarkOverwrite,
        onSave = onSave,
        onLoad = onLoad,

    },
    eventHandlers = {
        openMarkMenu = openMarkMenu,
        saveMarkLoc = saveMarkLoc,
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if recallWindow ~= nil and data.newMode == nil then
                closeWindows()
                recallWindow = nil
                setPauseMode(false)
            elseif recallWindow == nil then
                --    print("RCW is nil")
            elseif data.newMode ~= nil then
                --    print("newMode is nnil")
            end
        end,
    },
    engineHandlers = {
        onControllerButtonPress = onControllerButtonPress,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInputAction = onInputAction,
    }
}
