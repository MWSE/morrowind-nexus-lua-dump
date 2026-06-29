-- interactionPlayer.lua
---@omw-context player
---@diagnostic disable: assign-type-mismatch, undefined-field, param-type-mismatch
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local auxUi = require('openmw_aux.ui')
local profiles = require('scripts/sitDownPlease/profiles/catalog')
local overlayLayers = require('scripts/sitDownPlease/ui/initialPlacementOverlay')
local initialPlacementOverlayControllerModule = require('scripts/sitDownPlease/ui/initialPlacementOverlayController')
local calibrationPanel = require('scripts/sitDownPlease/ui/calibrationPanel')
local calibrationMetadataStyle = require('scripts/sitDownPlease/ui/calibrationMetadataStyle')
local calibrationActionState = require('scripts/sitDownPlease/ui/calibrationActionState').new({ util = util })
local blockerMarkersModule = require('scripts/sitDownPlease/ui/blockerMarkers')
local calibrationCellAudit = require('scripts/sitDownPlease/calibration/cellAudit')
local targetMetadata = require('scripts/sitDownPlease/calibration/targetMetadata')
local cellContext = require('scripts/sitDownPlease/world/cellContext')
local playerStealthObserverModule = require('scripts/sitDownPlease/compatibility/playerStealthObserver')
local sdpLectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')

local settings = profiles.settings()

local dialogueModes = {
    Dialogue = true,
    Barter = true,
    Companion = true,
    Enchanting = true,
    MerchantRepair = true,
    SpellBuying = true,
    SpellCreation = true,
    Training = true,
    Travel = true,
}

local dialogueTarget = nil
local calibrationMenu = nil
local calibrationMenuOverlay = nil
local calibrationMenuActiveLayer = "Windows"
local CALIBRATION_MODE = "Interface" -- Kept only for cleanup compatibility; the calibration UI no longer depends on this mode.
local calibrationMenuStatus = ""
local lastCalibrationToastText = nil
local lastCalibrationToastAt = nil
local calibrationMenuTargetRowLayouts = nil
local calibrationMenuPrimaryActionText = nil
local calibrationMenuFilterLayout = nil
local calibrationMenuFilterButtons = nil
local calibrationMenuNudgeButtons = nil
local calibrationMenuPoseLayout = nil
local calibrationMenuTargetText = "Target: none selected"
local calibrationMenuTargetDetailRows = {
    status = "None selected",
    actor = "",
    actorScale = "",
    actorPose = "",
    actorStatus = "",
    actorDetail = "",
    actorWarnings = "",
    actorBlockers = "",
    furniture = "",
    furnitureScale = "",
    furnitureDetail = "",
    furnitureSource = "",
    furnitureModel = "",
    furnitureWarnings = "",
    furnitureBlockers = "",
    cell = "",
    slot = "",
    type = "",
    profile = "",
    profileWarnings = "",
    profileBlockers = "",
    pose = "",
    detected = "",
    blockers = "",
    overrides = "",
    rejections = "",
    normalPlay = "",
    safetyGate = "",
    warnings = "",
    genericWarnings = "",
    genericBlockers = "",
}
local calibrationMenuTargetLabel = ""
local calibrationMenuResolvedType = nil
local calibrationMenuActiveType = "auto"
local lastCalibrationHotkeyHandledAt = -100
local CALIBRATION_HOTKEY_DUPLICATE_WINDOW = 0.22
local calibrationMenuEscapeDown = false
local calibrationMenuOpenedInterfaceMode = false
local calibrationMenuModeActive = false
local lastObservedCell = nil
local lastObservedCellExterior = nil
local lastObservedPlayerPosition = nil
local lastObservedGameTime = nil
local STATION_WAIT_PRECOVER_GAME_SECONDS = 5 * 60
local function noopCallback(...)
end

local restoreSeatedDialogueCamera = noopCallback
local onSeatedDialogueState = noopCallback

local function debugLog(...)
    profiles.debugLog(settings, "player", ...)
end

local calibrationBlockerMarkers = blockerMarkersModule.create({
    interfaces = I,
    util = util,
    core = core,
    camera = camera,
    nearby = nearby,
    player = self.object,
    types = types,
    debugLog = debugLog,
})

local function calibrationBlockerMarkersEnabled()
    return settings and settings.sdpCalibrationHotkeyEnabled == true
end

local function syncCalibrationBlockerMarkers(reason)
    calibrationBlockerMarkers.setActive(calibrationBlockerMarkersEnabled(), reason or "settings")
end

local playerStealthObserver = playerStealthObserverModule.create({
    player = self,
    core = core,
    types = types,
    interfaces = I,
    debugLog = debugLog,
})
local sleepingActors = playerStealthObserver.sleepingActors

local openCalibrationMenu
local onInitialPlacementSettled
local cellIsExterior

profiles.subscribeSettings(async:callback(function()
    settings = profiles.settings()
    syncCalibrationBlockerMarkers("settings_changed")
end))
syncCalibrationBlockerMarkers("init")

local function clearDialogueTarget(reason)
    if not dialogueTarget then return end
    dialogueTarget:sendEvent('InteractionDialogueStopped', {
        player = self.object,
        reason = reason or "dialogue_stopped",
    })
    dialogueTarget = nil
    restoreSeatedDialogueCamera(reason or "dialogue_stopped")
end

local calibrationMenuAdjustmentLayout = nil
local calibrationMenuModeLayout = nil
local onDisguiseInitialPlacement
local calibrationMenuAdjustments = {
    sleeping = { x = 0, y = 0, z = 0, yaw = 0 },
    sitting = { x = 0, y = 0, z = 0, yaw = 0 },
    station = { x = 0, y = 0, z = 0, yaw = 0 },
}
local calibrationMenuProfileOffsets = {
    sleeping = { x = 0, y = 0, z = 0, yaw = 0 },
    sitting = { x = 0, y = 0, z = 0, yaw = 0 },
    station = { x = 0, y = 0, z = 0, yaw = 0 },
}
local calibrationMenuPoseNotes = {
    sleeping = "",
    sitting = "",
    station = "",
}
local calibrationMenuOverrideNotes = {
    sleeping = "",
    sitting = "",
    station = "",
}

local function zeroCalibrationDisplayState(interactionType)
    local typesToClear = {}
    if interactionType == "sitting" or interactionType == "sleeping" or interactionType == "station" then
        typesToClear[#typesToClear + 1] = interactionType
    else
        typesToClear[#typesToClear + 1] = "sitting"
        typesToClear[#typesToClear + 1] = "sleeping"
        typesToClear[#typesToClear + 1] = "station"
    end
    for _, key in ipairs(typesToClear) do
        calibrationMenuAdjustments[key] = { x = 0, y = 0, z = 0, yaw = 0 }
        calibrationMenuProfileOffsets[key] = { x = 0, y = 0, z = 0, yaw = 0 }
        calibrationMenuPoseNotes[key] = ""
        calibrationMenuOverrideNotes[key] = ""
    end
end

local function modeName(interactionType)
    if interactionType == "auto" then return "Auto" end
    if interactionType == "sitting" then return "Seat" end
    if interactionType == "station" then return "Station" end
    return "Bed"
end

local function calibrationMenuDisplayType()
    if calibrationMenuResolvedType == "sitting" or calibrationMenuResolvedType == "sleeping" or calibrationMenuResolvedType == "station" then
        return calibrationMenuResolvedType
    end
    if calibrationMenuActiveType == "sitting" or calibrationMenuActiveType == "sleeping" or calibrationMenuActiveType == "station" then
        return calibrationMenuActiveType
    end
    return nil
end

local function signedNumber(value, suffix)
    value = tonumber(value) or 0
    if math.abs(value) < 0.0005 then value = 0 end
    local text = string.format("%.3f", value):gsub("%.?0+$", "")
    if text == "-0" then text = "0" end
    local prefix = value > 0 and "+" or ""
    return prefix .. text .. (suffix or "")
end

local function adjustmentLabel()
    if calibrationMenuTargetLabel == "" then
        return "Current offset: no target selected"
    end
    local displayType = calibrationMenuDisplayType()
    if not displayType then
        return "Current offset: no target selected"
    end
    local a = calibrationMenuAdjustments[displayType] or { x = 0, y = 0, z = 0, yaw = 0 }
    local p = calibrationMenuProfileOffsets[displayType] or { x = 0, y = 0, z = 0, yaw = 0 }
    return "Current offset: X " .. signedNumber((p.x or 0) + (a.x or 0))
        .. "   Y " .. signedNumber((p.y or 0) + (a.y or 0))
        .. "   Z " .. signedNumber((p.z or 0) + (a.z or 0))
        .. "   Yaw " .. signedNumber((p.yaw or 0) + (a.yaw or 0), "°")
end

local compactReasonSections = targetMetadata.compactReasonSections
local readableTargetLabel = targetMetadata.readableTargetLabel
local compactTargetText = targetMetadata.compactTargetText
local blankTargetDetailRows = targetMetadata.blankRows
local displaySlotLabel = targetMetadata.displaySlotLabel
local targetDetailRows = targetMetadata.targetRows
local nonStandardScaleText = targetMetadata.nonStandardScaleText

local function offsetNonZero(offset)
    if not offset then return false end
    return math.abs(tonumber(offset.x) or 0) > 0.001
        or math.abs(tonumber(offset.y) or 0) > 0.001
        or math.abs(tonumber(offset.z) or 0) > 0.001
        or math.abs(tonumber(offset.yaw) or 0) > 0.001
end

local function poseNoteLabel()
    if calibrationMenuTargetLabel == "" then return "" end
    local displayType = calibrationMenuDisplayType()
    if not displayType then return "" end
    local poseNote = calibrationMenuPoseNotes[displayType] or ""
    return poseNote
end

local function poseValueLabel()
    if calibrationMenuTargetLabel == "" then return "" end
    local displayType = calibrationMenuDisplayType()
    if not displayType then return "" end
    local poseNote = calibrationMenuPoseNotes[displayType] or ""
    poseNote = poseNote:gsub("^Pose normalized:%s*", "")
    poseNote = poseNote:gsub("^Pose:%s*", "")
    return poseNote
end

local function modeLabel()
    return "Target filter"
end

local function destroyCalibrationMenuElement(element)
    if not element then return end
    if type(element) == "table" and not element.destroy and not element.layout then
        for _, child in pairs(element) do
            destroyCalibrationMenuElement(child)
        end
        return
    end
    pcall(function() auxUi.deepDestroy(element) end)
    pcall(function()
        if element.destroy then element:destroy() end
    end)
end

local function calibrationInterfaceModeName()
    if I and I.UI and I.UI.MODE and I.UI.MODE.Interface then return I.UI.MODE.Interface end
    return CALIBRATION_MODE
end

local function clearCalibrationInterfaceMode(reason)
    if not (I and I.UI) then return end
    local modeNameToClear = calibrationInterfaceModeName()
    local clearMode = true
    if tostring(reason or "") == "mode_changed" and I.UI.getMode then
        local okMode, mode = pcall(function() return I.UI.getMode() end)
        if okMode and mode ~= nil and mode ~= modeNameToClear then
            clearMode = false
        end
    end
    if clearMode then
        -- Prefer removing only our Interface mode when supported. Fall back to the
        -- older setMode(nil) behavior for OpenMW builds without removeMode.
        local removed = false
        if I.UI.removeMode then
            local okRemove = pcall(function() I.UI.removeMode(modeNameToClear) end)
            removed = okRemove == true
        end
        if not removed and I.UI.setMode then
            pcall(function() I.UI.setMode(nil) end)
        end
    end
    pcall(function() I.UI.setPauseOnMode(modeNameToClear, true) end)
end

local function showCalibrationToast(message)
    local text = tostring(message or "")
    if text == "" then return end
    local now = core.getRealTime and core.getRealTime() or nil
    if now and lastCalibrationToastText == text and lastCalibrationToastAt and (now - lastCalibrationToastAt) < 0.45 then
        debugLog("calibration status duplicate suppressed", text)
        return
    end
    lastCalibrationToastText = text
    lastCalibrationToastAt = now
    pcall(function() ui.showMessage(text, { showInDialogue = false }) end)
    pcall(function() ui.printToConsole("[SitDownPlease calibration] " .. text, ui.CONSOLE_COLOR.Info) end)
end

local function calibrationKeyHelpText()
    return "Select a target, nudge offsets, then print. Left Alt+Print marks good; Left Shift links slots."
end

local function describeUiMode()
    if not (I and I.UI) then return "ui_unavailable" end
    local modeText = "nil"
    if I.UI.getMode then
        local okMode, mode = pcall(function() return I.UI.getMode() end)
        modeText = okMode and tostring(mode) or ("getMode_error:" .. tostring(mode))
    else
        modeText = "getMode_absent"
    end
    local stackText = ""
    local modes = I.UI.modes
    if type(modes) == "table" then
        local parts = {}
        for i = 1, #modes do parts[#parts + 1] = tostring(modes[i]) end
        stackText = table.concat(parts, ",")
    end
    if stackText == "" then stackText = "empty" end
    return modeText .. " stack=" .. stackText
end

local setCalibrationTarget
local closeCalibrationMenu
local sendCalibrationMenuAction
local nudgePayload
local resetMenuAdjustment
local runCalibrationCellAudit

local function calibrationPrimaryActionLabel()
    local targetType = calibrationMenuResolvedType or calibrationMenuDisplayType() or calibrationMenuActiveType
    if targetType == "station" then return "Start Lecture" end
    return "Apply Pose"
end

local targetRowHeight = calibrationMetadataStyle.rowHeight

local function rowTextColor(key, value)
    return calibrationMetadataStyle.rowTextColor(util, key, value)
end

local function rowLabelColor(key, value)
    if calibrationMetadataStyle.rowLabelColor then
        return calibrationMetadataStyle.rowLabelColor(util, key, value)
    end
    return util.color.rgb(0.94, 0.92, 0.84)
end

local function currentCalibrationCellName()
    local ok, value = pcall(function() return cellContext.cellName(self.object and self.object.cell or nil) end)
    if ok and value and value ~= "" and value ~= "<no-cell>" then return tostring(value) end
    return ""
end

local function noTargetCellSafetyLabel()
    local releaseSafetyGate = require('scripts/sitDownPlease/assignment/releaseSafetyGate')
    if not (releaseSafetyGate and releaseSafetyGate.policy and releaseSafetyGate.visibleLabel) then return "" end
    local cell = self.object and self.object.cell or nil
    if not cell then return "" end
    local interactionType = calibrationMenuDisplayType() or calibrationMenuActiveType or "sitting"
    local policy = releaseSafetyGate.policy(settings, cell, interactionType, nil, nil, {})
    local label = releaseSafetyGate.visibleLabel(policy)
    local kept = {}
    for line in tostring(label or ""):gmatch("[^\n]+") do
        local lower = line:lower()
        if line ~= "" and not lower:find("furniture", 1, true) then
            kept[#kept + 1] = line
        end
    end
    return table.concat(kept, "\n")
end

local refreshSourceDetails = targetMetadata.applySourceDetails

local function updateNudgeEnabled(data, preserveExisting)
    if not data then
        calibrationActionState.setNudgeEnabled(false)
        return
    end
    if data.nudgeEnabled ~= nil then
        calibrationActionState.setNudgeEnabled(data.nudgeEnabled == true)
        return
    end
    if preserveExisting == true and data.sdpOwnedAssignment == nil then
        return
    end
    local interactionType = tostring(data.interactionType or calibrationMenuResolvedType or "")
    if interactionType == "station" then
        calibrationActionState.setNudgeEnabled(data.targetLabel ~= nil and data.externalPhysicalClaimed ~= true)
        return
    end
    calibrationActionState.setNudgeEnabled(data.sdpOwnedAssignment == true and data.externalPhysicalClaimed ~= true)
end

local function refreshCalibrationMenuChrome()
    if calibrationMenuModeLayout and calibrationMenuModeLayout.props then
        calibrationMenuModeLayout.props.text = modeLabel()
    end
    if calibrationMenuFilterLayout and calibrationMenuFilterLayout.props then
        calibrationMenuFilterLayout.props.text = modeLabel()
    end
    if calibrationMenuFilterButtons then
        for key, button in pairs(calibrationMenuFilterButtons) do
            local selected = key == calibrationMenuActiveType
            if button.background and button.background.props then
                button.background.props.color = selected and util.color.rgb(0.24, 0.18, 0.08) or util.color.rgb(0.08, 0.065, 0.045)
            end
            if button.textLayout and button.textLayout.props then
                button.textLayout.props.textColor = selected and util.color.rgb(1.0, 0.82, 0.42) or util.color.rgb(0.94, 0.92, 0.84)
            end
        end
    end
    if calibrationMenuNudgeButtons then
        for _, button in ipairs(calibrationMenuNudgeButtons) do
            calibrationActionState.refreshButton(button)
        end
    end
    calibrationActionState.refreshButtons(calibrationActionState.actionButtons)
    if calibrationMenuTargetRowLayouts then
        local rows = calibrationMenuTargetDetailRows or blankTargetDetailRows()
        rows.cell = currentCalibrationCellName()
        if calibrationMenuTargetLabel == "" then
            rows.safetyGate = noTargetCellSafetyLabel()
        end
        rows.pose = poseValueLabel()
        local displayType = calibrationMenuDisplayType()
        if displayType and calibrationMenuOverrideNotes[displayType] and calibrationMenuOverrideNotes[displayType] ~= "" then
            rows.overrides = calibrationMenuOverrideNotes[displayType]
        end
        if calibrationMenuTargetRowLayouts.status and calibrationMenuTargetRowLayouts.status.props then
            calibrationMenuTargetRowLayouts.status.props.text = rows.status or "None selected"
        end
        local y = tonumber(calibrationMenuTargetRowLayouts.baseY) or 76
        local order = calibrationMenuTargetRowLayouts.order or {
            "cell",
            "actor", "actorPose", "actorDetail", "actorWarnings", "actorBlockers", "actorStatus",
            "furniture", "type", "furnitureSource", "furnitureModel", "furnitureDetail", "furnitureWarnings", "furnitureBlockers",
            "focus", "focusDetail", "focusWarnings", "focusCandidates",
            "profile", "profileWarnings", "profileBlockers",
            "normalPlay",
            "safetyGate",
        }
        for index, key in ipairs(order) do
            local row = calibrationMenuTargetRowLayouts[key]
            local value = rows[key] or ""
            if key == "type" then
                value = tostring(rows.furniture or "") ~= "" and targetMetadata.typeDisplayValue(calibrationMenuResolvedType or displayType, value, rows.slot) or ""
            end
            local scale = key == "actor" and tostring(rows.actorScale or "")
                or (key == "furniture" and tostring(rows.furnitureScale or "")
                or (key == "focus" and tostring(rows.focusScale or "") or ""))
            local height = targetRowHeight(value, row)
            if row and row.label and row.label.props then
                row.label.props.text = value ~= "" and row.labelText or ""
                row.label.props.textColor = row.labelColor or (row.labelText ~= "" and rowLabelColor(key, value) or util.color.rgb(0.84, 0.78, 0.62))
                row.label.props.position = util.vector2(row.label.props.position.x, y)
                row.label.props.size = util.vector2(row.label.props.size.x, height > 0 and height or 1)
            end
            if row and row.value and row.value.props then
                row.value.props.text = value
                row.value.props.textColor = rowTextColor(key, value)
                local valueWidth = row.fullValueW or (row.value.props.size and row.value.props.size.x) or 200
                if row.scale and scale ~= "" and value ~= "" then
                    local estimatedValueW = math.min(row.scaledValueW or valueWidth, math.max(42, (#tostring(value) * 7) + 10))
                    valueWidth = estimatedValueW
                end
                local valueY = y
                local valueX = row.value.props.position.x
                if row.section == true then
                    valueY = y + 16
                    valueX = row.label and row.label.props and row.label.props.position.x or valueX
                    valueWidth = row.sectionValueW or valueWidth
                    height = height + 16
                end
                row.value.props.position = util.vector2(valueX, valueY)
                row.value.props.size = util.vector2(valueWidth, height > 0 and height or 1)
            end
            if row and row.scale and row.scale.props then
                row.scale.props.text = value ~= "" and scale or ""
                row.scale.props.textColor = util.color.rgb(0.74, 0.71, 0.63)
                local valueW = row.value and row.value.props and row.value.props.size and row.value.props.size.x or 0
                row.scale.props.position = util.vector2((row.value.props.position.x or 0) + valueW + 4, y)
                row.scale.props.size = util.vector2(row.scaleW or 86, height > 0 and height or 1)
            end
            if value ~= "" then
                local gap = calibrationPanel.nextTargetRowGap(calibrationMenuTargetRowLayouts, rows, order, index, key, row, displayType, calibrationMenuResolvedType, targetMetadata)
                y = y + height + gap
            end
        end
    end
    if calibrationMenuPrimaryActionText and calibrationMenuPrimaryActionText.props then
        calibrationMenuPrimaryActionText.props.text = calibrationPrimaryActionLabel()
    end
    if calibrationMenuAdjustmentLayout and calibrationMenuAdjustmentLayout.props then
        calibrationMenuAdjustmentLayout.props.text = adjustmentLabel()
    end
    if calibrationMenuPoseLayout and calibrationMenuPoseLayout.props then
        calibrationMenuPoseLayout.props.text = poseNoteLabel()
    end
    if calibrationMenu and calibrationMenu.update then calibrationMenu:update() end
end

local function resetCalibrationTargetFilter(reason)
    if calibrationMenuActiveType == "auto" and calibrationMenuTargetText == "Target: none selected" and calibrationMenuTargetLabel == "" then return end
    calibrationMenuActiveType = "auto"
    calibrationMenuStatus = ""
    calibrationMenuTargetText = "Target: none selected"
    calibrationMenuTargetDetailRows = blankTargetDetailRows()
    calibrationMenuTargetLabel = ""
    calibrationMenuResolvedType = nil
    calibrationActionState.clear()
    zeroCalibrationDisplayState()
    refreshCalibrationMenuChrome()
    debugLog("calibration target filter reset", tostring(reason or "reset"), "filter", "auto")
end

setCalibrationTarget = function(interactionType)
    if interactionType == "auto" or interactionType == "sitting" or interactionType == "sleeping" or interactionType == "station" then
        calibrationMenuActiveType = interactionType
        calibrationMenuStatus = ""
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetDetailRows = blankTargetDetailRows()
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        calibrationActionState.clear()
        zeroCalibrationDisplayState()
        refreshCalibrationMenuChrome()
        if interactionType == "auto" then
            showCalibrationToast("Target filter: Auto. Find Target will choose the nearest active bed, seat, or station target.")
        else
            showCalibrationToast("Target filter: " .. modeName(interactionType) .. ". Find Target will only use this furniture type.")
        end
    end
end

closeCalibrationMenu = function(reason)
    local menu = calibrationMenu
    local overlay = calibrationMenuOverlay
    calibrationMenu = nil
    calibrationMenuOverlay = nil
    if menu then
        destroyCalibrationMenuElement(menu)
    end
    if overlay and overlay ~= menu then
        destroyCalibrationMenuElement(overlay)
    end
    calibrationMenuTargetRowLayouts = nil
    calibrationMenuPrimaryActionText = nil
    calibrationMenuFilterLayout = nil
    calibrationMenuFilterButtons = nil
    calibrationMenuAdjustmentLayout = nil
    calibrationMenuModeLayout = nil
    calibrationActionState.actionButtons = nil
    calibrationMenuPoseLayout = nil
    calibrationMenuEscapeDown = false
    if calibrationMenuModeActive or calibrationMenuOpenedInterfaceMode then
        clearCalibrationInterfaceMode(reason)
    end
    calibrationMenuOpenedInterfaceMode = false
    calibrationMenuModeActive = false
    debugLog("calibration menu closed", tostring(reason or "close"))
end

local function rememberMenuAdjustment(payload)
    local displayType = calibrationMenuDisplayType() or calibrationMenuActiveType
    local a = calibrationMenuAdjustments[displayType]
    if not a then
        a = { x = 0, y = 0, z = 0, yaw = 0 }
        calibrationMenuAdjustments[displayType] = a
    end
    a.x = (tonumber(a.x) or 0) + (tonumber(payload.x) or 0)
    a.y = (tonumber(a.y) or 0) + (tonumber(payload.y) or 0)
    a.z = (tonumber(a.z) or 0) + (tonumber(payload.z) or 0)
    a.yaw = (tonumber(a.yaw) or 0) + (tonumber(payload.yaw) or 0)
end

resetMenuAdjustment = function(interactionType)
    local key = interactionType
    if key ~= "sitting" and key ~= "sleeping" then
        key = calibrationMenuDisplayType()
    end
    local a = key and calibrationMenuAdjustments[key] or nil
    if a then
        a.x, a.y, a.z, a.yaw = 0, 0, 0, 0
    end
end

local function actionStatus(action, payload)
    if action == "capture" then
        if calibrationMenuActiveType == "auto" then return "Finding the looked-at or nearest active bed, seat, or station target..." end
        return "Finding the looked-at or nearest active " .. modeName(calibrationMenuActiveType):lower() .. " target..."
    end
    if action == "cycle_target" then return "" end
    if action == "resume" or action == "send" then
        local targetType = calibrationMenuResolvedType or calibrationMenuDisplayType() or calibrationMenuActiveType
        if targetType == "station" then return "Starting the lecture..." end
        if targetType == "sleeping" then return "Asking target to lie down again..." end
        return "Asking target to sit again..."
    end
    if action == "reapply" then return "Reapplying the current position..." end
    if action == "print" and payload and payload.visualApproval == true then return "Visual approval logged to openmw.log." end
    if action == "print" then return "" end
    if action == "reset" then return "Resetting to saved profile..." end
    if action == "clear" and payload and payload.shiftDown == true then return "Clearing target and restoring calibration actor..." end
    if action == "clear" then return "Target cleared." end
    if action == "spawn_test" then
        return "Spawning NPC..."
    end
    if action == "fill_furniture" then return "Filling nearby furniture with calibration-only test assignments..." end
    if action == "remove_test" then return "Clearing test actors and their calibration assignments..." end
    if action == "nudge" then
        local axis, amount = "position", 0
        if payload then
            if payload.x then axis, amount = "X", payload.x
            elseif payload.y then axis, amount = "Y", payload.y
            elseif payload.z then axis, amount = "Z", payload.z
            elseif payload.yaw then axis, amount = "Yaw", payload.yaw
            end
        end
        return "Moved " .. axis .. " " .. signedNumber(amount, axis == "Yaw" and "°" or "") .. ". Hold Left Shift to link same-furniture slots."
    end
    return "Action requested."
end

local function menuShiftDown()
    local keyCode = input and input.KEY and input.KEY.LeftShift or nil
    if keyCode ~= nil and input and input.isKeyPressed then
        local ok, value = pcall(input.isKeyPressed, keyCode)
        if ok then return value == true end
    end
    if not (input and input.isShiftPressed) then return false end
    local ok, value = pcall(input.isShiftPressed)
    return ok and value == true
end

local function menuAltDown()
    local keyCode = input and input.KEY and input.KEY.LeftAlt or nil
    if keyCode ~= nil and input and input.isKeyPressed then
        local ok, value = pcall(input.isKeyPressed, keyCode)
        if ok then return value == true end
    end
    if not (input and input.isAltPressed) then return false end
    local ok, value = pcall(input.isAltPressed)
    return ok and value == true
end

local function sharedRayObjectIsValid(obj)
    if not obj or obj == self.object then return false end
    local ok, valid = pcall(function() return obj:isValid() end)
    return ok and valid == true
end

local function attachSharedRayTarget(payload, action)
    if action ~= "assign_nearest"
        and action ~= "spawn_test"
        and action ~= "capture"
        and action ~= "cycle_target"
        and action ~= "fill_furniture"
        and not (action == "print" and payload and payload.visualApproval == true) then
        return
    end
    local sharedRay = I and I.SharedRay
    if not (sharedRay and sharedRay.get) then return end
    local ok, hit = pcall(sharedRay.get)
    if not ok or not (hit and hit.hitObject and sharedRayObjectIsValid(hit.hitObject)) then return end
    payload.lookTarget = hit.hitObject
    payload.lookTargetPos = hit.hitPos
    payload.lookTargetTypeName = hit.hitTypeName or hit.hitType
    payload.lookTargetSource = "SharedRay"
    debugLog("calibration sharedray target attached", tostring(action), tostring(hit.hitObject.recordId or hit.hitObject.id), tostring(payload.lookTargetTypeName or "unknown"))
end

sendCalibrationMenuAction = function(action, payload)
    payload = payload or {}

    local actionTargetType = calibrationMenuActiveType
    if action == "print" then
        actionTargetType = calibrationMenuResolvedType or calibrationMenuDisplayType() or actionTargetType
    end
    if action == "resume" or action == "reapply" or action == "reenter" or action == "send" then
        local displayedType = calibrationMenuResolvedType or calibrationMenuDisplayType()
        if displayedType == "station" then actionTargetType = "station" end
    end

    payload.interactionType = actionTargetType
    payload.action = action
    payload.player = self.object
    payload.source = "developer_menu"
    payload.shiftDown = payload.shiftDown == true or menuShiftDown()
    payload.altDown = payload.altDown == true or menuAltDown()
    if action == "print" then
        payload.linkSameFurnitureSlots = payload.linkSameFurnitureSlots == true or payload.shiftDown == true
        payload.visualApproval = payload.visualApproval == true or payload.hotkeyVisualApproval == true or payload.altDown == true
        if payload.visualApproval == true and payload.captureLookTarget ~= false then
            payload.captureLookTarget = true
        end
    end
    if action == "cycle_target" then
        payload.silent = true
    elseif action == "capture" then
        payload.silentOnSuccess = true
    end

    -- Visual approval is intentionally allowed to start without an already-owned
    -- calibration target.  Attach the looked-at object when SharedRay has one,
    -- but still send the request so global-side fallback targeting can resolve the
    -- NPC/furniture slot pair in one hotkey press.
    attachSharedRayTarget(payload, action)
    local printAutotarget = action == "print" and payload.visualApproval == true
    if printAutotarget and payload.captureLookTarget == true then
        -- A hotkey approval is about the looked-at NPC/slot, not the currently
        -- selected menu filter.  Force global-side auto capture so a sleeping NPC
        -- does not become a loose sitting target just because the previous target
        -- was a chair.
        payload.interactionType = "auto"
        payload.forceTargetPrime = true
    end
    if not calibrationActionState.enabled(action, {
        targetLabel = calibrationMenuTargetLabel,
        displayType = calibrationMenuDisplayType(),
    }) and not printAutotarget then
        refreshCalibrationMenuChrome()
        return
    end

    if action == "nudge" then
        rememberMenuAdjustment(payload)
    elseif action == "reset" then
        resetMenuAdjustment(calibrationMenuDisplayType() or calibrationMenuActiveType)
    elseif action == "capture" or action == "cycle_target" or action == "spawn_test" or action == "fill_furniture" or action == "remove_test" then
        resetMenuAdjustment(calibrationMenuDisplayType() or calibrationMenuActiveType)
    elseif action == "clear" then
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetDetailRows = blankTargetDetailRows()
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        calibrationActionState.clear()
        zeroCalibrationDisplayState()
    end

    if action == "resume" and payload.interactionType == "station" then
        sdpLectureTrace.log(
            debugLog,
            "start_button_path_entered_player",
            "activeFilter", tostring(calibrationMenuActiveType),
            "resolvedType", tostring(calibrationMenuResolvedType),
            "sentType", tostring(payload.interactionType),
            "shift", tostring(payload.shiftDown == true)
        )
    end

    core.sendGlobalEvent("SitDownPleaseCalibrationMenuAction", payload)
    calibrationMenuStatus = actionStatus(action, payload)
    -- Keep transient action text out of the fragile panel. The panel shows only
    -- stable target/filter/change state; action feedback goes to OpenMW messages.
    refreshCalibrationMenuChrome()
    if action == "nudge" or action == "capture" or action == "cycle_target" or action == "assign_nearest" then return end
    showCalibrationToast(calibrationMenuStatus)
end

nudgePayload = function(axis, amount)
    local payload = {}
    payload[axis] = amount
    if axis == "x" or axis == "y" or axis == "z" or axis == "yaw" then
        local shiftDown = menuShiftDown()
        if axis == "z" then payload.syncSlotZ = shiftDown end
        if axis == "x" or axis == "y" then payload.syncSlotXY = shiftDown end
        if axis == "yaw" then payload.syncSlotYaw = shiftDown end
    end
    return payload
end

local function calibrationMenuLayer()
    return calibrationPanel.preferredLayer()
end

local function openCalibrationMenuMode()
    if not (I and I.UI) then return true end
    local interfaceMode = calibrationInterfaceModeName()
    pcall(function() I.UI.setPauseOnMode(interfaceMode, false) end)

    local modeSet = false
    local failures = {}
    if I.UI.setMode then
        local ok, err = pcall(function() I.UI.setMode(interfaceMode, { windows = {} }) end)
        if ok then
            modeSet = true
        else
            failures[#failures + 1] = "setMode:" .. tostring(err)
        end
    end
    if I.UI.addMode then
        local ok, err = pcall(function() I.UI.addMode(interfaceMode, { windows = {} }) end)
        if ok then
            modeSet = true
        else
            failures[#failures + 1] = "addMode:" .. tostring(err)
        end
    end

    if not modeSet then
        debugLog("calibration menu mode failed", tostring(interfaceMode), table.concat(failures, " | "))
        pcall(function() I.UI.setPauseOnMode(interfaceMode, true) end)
        return false
    end
    calibrationMenuOpenedInterfaceMode = true
    calibrationMenuModeActive = true
    debugLog("calibration menu interface mode requested", describeUiMode())
    return true
end

local function verifyCalibrationMenuMode()
    if not calibrationMenu then return end
    if not (I and I.UI and I.UI.getMode) then return end
    local interfaceMode = calibrationInterfaceModeName()
    local okMode, mode = pcall(function() return I.UI.getMode() end)
    if okMode and mode == interfaceMode then return end
    openCalibrationMenuMode()
    debugLog("calibration menu interface mode reasserted", describeUiMode())
end

local function buildCalibrationMenuLayout()
    local layout, refs = calibrationPanel.buildLayout({
        ui = ui,
        util = util,
        I = I,
        async = async,
        input = input,
        layerName = calibrationMenuActiveLayer,
        update = function()
            if calibrationMenu then calibrationMenu:update() end
        end,
        keyHelpText = calibrationKeyHelpText,
        targetText = function() return calibrationMenuTargetText end,
        targetDetailRows = function() return calibrationMenuTargetDetailRows end,
        modeLabel = modeLabel,
        adjustmentLabel = adjustmentLabel,
        poseNoteLabel = poseNoteLabel,
        primaryActionLabel = calibrationPrimaryActionLabel,
        nudgeEnabled = function() return calibrationActionState.isNudgeEnabled() end,
        actionEnabled = function(action)
            return calibrationActionState.enabled(action, {
                targetLabel = calibrationMenuTargetLabel,
                displayType = calibrationMenuDisplayType(),
            })
        end,
        setTarget = setCalibrationTarget,
        sendAction = sendCalibrationMenuAction,
        nudgePayload = nudgePayload,
        close = closeCalibrationMenu,
    })
    calibrationMenuTargetRowLayouts = refs and refs.targetRows or nil
    calibrationMenuPrimaryActionText = refs and refs.primaryActionText or nil
    calibrationMenuFilterLayout = refs and refs.filter or nil
    calibrationMenuFilterButtons = refs and refs.filterButtons or nil
    calibrationMenuNudgeButtons = refs and refs.nudgeButtons or nil
    calibrationActionState.actionButtons = refs and refs.actionButtons or nil
    calibrationMenuAdjustmentLayout = refs and refs.adjustment or nil
    calibrationMenuPoseLayout = refs and refs.pose or nil
    return layout
end

openCalibrationMenu = function(reason)
    if calibrationMenu then
        calibrationMenuStatus = "Calibration menu is already open."
        refreshCalibrationMenuChrome()
        debugLog("calibration menu already open", tostring(reason or "manual"))
        return
    end

    calibrationMenuStatus = ""
    calibrationMenuTargetText = calibrationMenuTargetText or "Target: none selected"
    calibrationMenuTargetDetailRows = calibrationMenuTargetDetailRows or blankTargetDetailRows()
    calibrationMenuActiveLayer = calibrationMenuLayer()
    calibrationMenuOverlay = nil

    local modeOk = openCalibrationMenuMode()
    local layout = buildCalibrationMenuLayout()
    local okCreate, element = pcall(function() return ui.create(layout) end)
    if not okCreate or not element then
        calibrationMenu = nil
        calibrationMenuOpenedInterfaceMode = false
        calibrationMenuModeActive = false
        if modeOk then clearCalibrationInterfaceMode("create_failed") end
        debugLog("calibration menu open failed", "hookshot_absolute_modal_widget", tostring(element))
        showCalibrationToast("Calibration menu failed to create. Check openmw.log.")
        return
    end

    calibrationMenu = element
    refreshCalibrationMenuChrome()
    pcall(function() calibrationMenu:update() end)

    pcall(function()
        async:newUnsavableGameTimer(0.05, verifyCalibrationMenuMode)
    end)
    if profiles.logLevel(settings) ~= "off" then
        pcall(function()
            async:newUnsavableGameTimer(0.18, function()
                if not calibrationMenu then return end
                if not runCalibrationCellAudit then return end
                local ok, message = runCalibrationCellAudit("menu_open", { force = false })
                if ok == true then
                    calibrationMenuStatus = message
                    refreshCalibrationMenuChrome()
                    debugLog("calibration cell audit auto", "menu_open", tostring(message))
                else
                    debugLog("calibration cell audit auto skipped", "menu_open", tostring(message))
                end
            end)
        end)
    end
    if menuShiftDown() then
        showCalibrationToast("Selecting looked-at target.")
        pcall(function()
            async:newUnsavableGameTimer(0.08, function()
                if calibrationMenu then
                    sendCalibrationMenuAction("capture", { silent = true })
                end
            end)
        end)
    end
    if not modeOk then
        calibrationMenuStatus = "Menu visible, but Interface mode failed. Mouse input may not work; close with Esc."
        refreshCalibrationMenuChrome()
        showCalibrationToast(calibrationMenuStatus)
    end

    debugLog("calibration menu opened", tostring(reason or "manual"), "layer", tostring(calibrationMenuActiveLayer), "modeState", describeUiMode(), "modeActive", tostring(calibrationMenuModeActive), "pattern", "hookshot_absolute_modal_widget")
end


local normalPlayOverrideSections = targetMetadata.normalPlayOverrideSections
local applyBlockerDetails = targetMetadata.applyBlockerDetails
local applyRejectionDetails = targetMetadata.applyRejectionDetails
local applyFocusDetails = targetMetadata.applyFocusDetails
local applySafetyDetails = targetMetadata.applySafetyDetails
local applyAccessDetails = targetMetadata.applyAccessDetails
local applyReleaseSafetyDetails = targetMetadata.applyReleaseSafetyDetails
local applyReasonSections = targetMetadata.applyReasonSections
local applyAssignmentContext = targetMetadata.applyAssignmentContext
local payloadHasSafetyOrBlockerDetails = targetMetadata.payloadHasSafetyOrBlockerDetails
local payloadHasScaleDetails = targetMetadata.payloadHasScaleDetails
local preserveStableTargetMetadata = targetMetadata.preserveStableRows
local cloneTargetDetailRows = targetMetadata.cloneRows

local function onCalibrationMenuStatus(data)
    calibrationMenuStatus = tostring(data and data.message or "Calibration action completed.")
    if data and data.fillOrTestExists ~= nil then
        calibrationActionState.setFillOrTestExists(data.fillOrTestExists == true)
    end
    if data and data.cleared == true then
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetDetailRows = blankTargetDetailRows()
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        calibrationActionState.clear()
        zeroCalibrationDisplayState()
        debugLog("calibration_target_display_state", calibrationMenuTargetText)
    elseif data and data.targetLabel then
        local targetLabel = readableTargetLabel(data.targetLabel)
        local previousTargetLabel = calibrationMenuTargetLabel
        local previousRows = calibrationMenuTargetDetailRows
        local sameTarget = previousTargetLabel ~= "" and targetLabel == previousTargetLabel
        local overrideReasons = tostring(data.testingOverrideReason or "")
        if data.softBlockerReason and data.softBlockerReason ~= "" then
            overrideReasons = overrideReasons ~= "" and (overrideReasons .. "," .. tostring(data.softBlockerReason)) or tostring(data.softBlockerReason)
        end
        if data.hardBlockerReason and data.hardBlockerReason ~= "" then
            overrideReasons = overrideReasons ~= "" and (overrideReasons .. "," .. tostring(data.hardBlockerReason)) or tostring(data.hardBlockerReason)
        end
        local overrideDetail = (data.testingOverride == true or overrideReasons ~= "") and compactReasonSections(overrideReasons, data.interactionType) or {}
        if data.testingOverride == true then
            overrideDetail = normalPlayOverrideSections(overrideDetail)
        end
        calibrationMenuResolvedType = data.interactionType
        updateNudgeEnabled(data, sameTarget)
        calibrationMenuTargetLabel = targetLabel
        calibrationMenuTargetText = compactTargetText(data.interactionType, targetLabel)
        calibrationMenuTargetDetailRows = targetDetailRows(data.interactionType, targetLabel, overrideDetail)
        if data.actorScale ~= nil then calibrationMenuTargetDetailRows.actorScale = nonStandardScaleText(data.actorScale, "scale") end
        if data.objectScale ~= nil then calibrationMenuTargetDetailRows.furnitureScale = nonStandardScaleText(data.objectScale, "scale") end
        if data.facingObjectScale ~= nil then
            calibrationMenuTargetDetailRows.focusScale = nonStandardScaleText(data.facingObjectScale, "scale")
        elseif data.ignoredFacingObjectScale ~= nil then
            calibrationMenuTargetDetailRows.focusScale = nonStandardScaleText(data.ignoredFacingObjectScale, "scale")
        end
        refreshSourceDetails(calibrationMenuTargetDetailRows, data)
        applyFocusDetails(calibrationMenuTargetDetailRows, data)
        applyRejectionDetails(calibrationMenuTargetDetailRows, data)
        applyBlockerDetails(calibrationMenuTargetDetailRows, data)
        applySafetyDetails(calibrationMenuTargetDetailRows, data)
        applyReleaseSafetyDetails(calibrationMenuTargetDetailRows, data)
        preserveStableTargetMetadata(calibrationMenuTargetDetailRows, previousRows, {
            preserveTargetDetails = sameTarget,
            preserveScales = sameTarget and not payloadHasScaleDetails(data),
            preserveSafety = sameTarget and not payloadHasSafetyOrBlockerDetails(data),
        })
        if data.interactionType == "sitting" and data.lectureAudienceTarget == true then
            calibrationMenuTargetDetailRows.status = "Audience seat selected"
            calibrationMenuTargetDetailRows.detected = ""
        end
        if data.profileDisplay and data.profileDisplay ~= "" then
            calibrationMenuTargetDetailRows.profile = tostring(data.profileDisplay)
        end
        if data.profileIsFallback == true then
            calibrationMenuTargetDetailRows.profileWarnings = targetMetadata.appendTextLine(calibrationMenuTargetDetailRows.profileWarnings, "Generated fallback profile")
        end
        applyAssignmentContext(calibrationMenuTargetDetailRows, data)
        applyAccessDetails(calibrationMenuTargetDetailRows, data)
        targetMetadata.sanitizeRowsForInteraction(calibrationMenuTargetDetailRows, data.interactionType)
        calibrationActionState.update(data, calibrationMenuTargetDetailRows, calibrationMenuResolvedType)
        if data.testingOverride == true and (data.interactionType == "sitting" or data.interactionType == "sleeping" or data.interactionType == "station") then
            calibrationMenuOverrideNotes[data.interactionType] = compactReasonSections(data.testingOverrideReason, data.interactionType).overrides
        elseif data.testingOverride == false and (data.interactionType == "sitting" or data.interactionType == "sleeping" or data.interactionType == "station") then
            calibrationMenuOverrideNotes[data.interactionType] = ""
        end
        debugLog("calibration_target_display_state", calibrationMenuTargetText)
    end
    refreshCalibrationMenuChrome()
    if data and data.silent == true then return end
    showCalibrationToast(calibrationMenuStatus)
end

local function onCalibrationOffsets(data)
    local interactionType = data and data.interactionType
    if interactionType ~= "sitting" and interactionType ~= "sleeping" and interactionType ~= "station" then return end
    local rawTargetLabel = tostring(data and data.targetLabel or "")
    local targetLabel = rawTargetLabel ~= "" and readableTargetLabel(rawTargetLabel) or ""
    local replaceTarget = data and data.replaceTarget == true
    if calibrationMenuTargetLabel == "" or (replaceTarget and targetLabel ~= "" and targetLabel ~= calibrationMenuTargetLabel) then
        if targetLabel ~= "" then
            calibrationMenuResolvedType = interactionType
            calibrationMenuTargetLabel = targetLabel
            calibrationMenuTargetText = compactTargetText(interactionType, targetLabel)
            calibrationMenuTargetDetailRows = targetDetailRows(interactionType, targetLabel, {})
            debugLog("calibration_offsets_target_primed", tostring(rawTargetLabel), "replace", tostring(replaceTarget == true))
        else
            debugLog("calibration_offsets_ignored_no_target", tostring(data and data.targetLabel or ""))
            return
        end
    end
    if targetLabel ~= "" and calibrationMenuTargetLabel ~= "" and targetLabel ~= calibrationMenuTargetLabel then
        debugLog("calibration_offsets_ignored_stale_target", "incoming", rawTargetLabel, "readable", targetLabel, "current", calibrationMenuTargetLabel)
        return
    end
    local previousRows = cloneTargetDetailRows(calibrationMenuTargetDetailRows)
    local sameTarget = calibrationMenuTargetLabel ~= "" and (targetLabel == "" or targetLabel == calibrationMenuTargetLabel)
    if data.profileOffset then
        calibrationMenuProfileOffsets[interactionType] = {
            x = tonumber(data.profileOffset.x) or 0,
            y = tonumber(data.profileOffset.y) or 0,
            z = tonumber(data.profileOffset.z) or 0,
            yaw = tonumber(data.profileOffset.yaw) or 0,
        }
    end
    updateNudgeEnabled(data, sameTarget)
    local animationOffset = data.animationOffset or data.animationNormalizationOffset
    if animationOffset ~= nil then
        local animationName = tostring(data.animation or data.poseAnimation or "")
        if animationName ~= "" and offsetNonZero(animationOffset) then
            calibrationMenuPoseNotes[interactionType] = "Pose normalized: " .. animationName
        elseif animationName ~= "" then
            calibrationMenuPoseNotes[interactionType] = "Pose: " .. animationName
        else
            calibrationMenuPoseNotes[interactionType] = ""
        end
    end
    if data.calibration then
        calibrationMenuAdjustments[interactionType] = {
            x = tonumber(data.calibration.x) or 0,
            y = tonumber(data.calibration.y) or 0,
            z = tonumber(data.calibration.z) or 0,
            yaw = tonumber(data.calibration.yaw) or 0,
        }
    end
    if data.actorScale ~= nil then
        calibrationMenuTargetDetailRows.actorScale = nonStandardScaleText(data.actorScale, "scale")
    end
    if data.objectScale ~= nil then
        calibrationMenuTargetDetailRows.furnitureScale = nonStandardScaleText(data.objectScale, "scale")
    end
    if data.facingObjectScale ~= nil then
        calibrationMenuTargetDetailRows.focusScale = nonStandardScaleText(data.facingObjectScale, "scale")
    elseif data.ignoredFacingObjectScale ~= nil then
        calibrationMenuTargetDetailRows.focusScale = nonStandardScaleText(data.ignoredFacingObjectScale, "scale")
    end
    refreshSourceDetails(calibrationMenuTargetDetailRows, data)
    applyFocusDetails(calibrationMenuTargetDetailRows, data)
    applyRejectionDetails(calibrationMenuTargetDetailRows, data)
    if data.profileDisplay and data.profileDisplay ~= "" then
        calibrationMenuTargetDetailRows.profile = tostring(data.profileDisplay)
    end
    if data.profileIsFallback == true then
        calibrationMenuTargetDetailRows.profileWarnings = targetMetadata.appendTextLine(calibrationMenuTargetDetailRows.profileWarnings, "Generated fallback profile")
    end
    applyAssignmentContext(calibrationMenuTargetDetailRows, data)
    calibrationMenuTargetDetailRows.slot = displaySlotLabel(calibrationMenuTargetDetailRows.slot)
    applyBlockerDetails(calibrationMenuTargetDetailRows, data)
    applySafetyDetails(calibrationMenuTargetDetailRows, data)
    if data.interactionType == "sitting" and data.lectureAudienceTarget == true then
        calibrationMenuTargetDetailRows.status = "Audience seat selected"
        calibrationMenuTargetDetailRows.detected = ""
    end
    if data.manualOverride == true then
        local reasons = tostring(data.manualOverrideReason or "")
        if data.softBlockerReason and data.softBlockerReason ~= "" then
            reasons = reasons ~= "" and (reasons .. "," .. tostring(data.softBlockerReason)) or tostring(data.softBlockerReason)
        end
        if data.hardBlockerReason and data.hardBlockerReason ~= "" then
            reasons = reasons ~= "" and (reasons .. "," .. tostring(data.hardBlockerReason)) or tostring(data.hardBlockerReason)
        end
        local sections = compactReasonSections(reasons, data.interactionType)
        if data.manualOverride == true then
            sections = normalPlayOverrideSections(sections)
        end
        calibrationMenuOverrideNotes[interactionType] = sections.overrides
        calibrationMenuTargetDetailRows.detected = sections.detected
        calibrationMenuTargetDetailRows.blockers = sections.blockers
        calibrationMenuTargetDetailRows.overrides = sections.overrides
        calibrationMenuTargetDetailRows.rejections = sections.rejections
        calibrationMenuTargetDetailRows.safetyGate = sections.safetyGate or calibrationMenuTargetDetailRows.safetyGate
        calibrationMenuTargetDetailRows.warnings = sections.warnings
        calibrationMenuTargetDetailRows.actorWarnings = ""
        calibrationMenuTargetDetailRows.actorBlockers = ""
        calibrationMenuTargetDetailRows.furnitureWarnings = ""
        calibrationMenuTargetDetailRows.furnitureBlockers = ""
        calibrationMenuTargetDetailRows.profileWarnings = ""
        calibrationMenuTargetDetailRows.profileBlockers = ""
        calibrationMenuTargetDetailRows.genericWarnings = ""
        calibrationMenuTargetDetailRows.genericBlockers = ""
        applyReasonSections(calibrationMenuTargetDetailRows, sections, data.interactionType)
        applyBlockerDetails(calibrationMenuTargetDetailRows, data)
        applyRejectionDetails(calibrationMenuTargetDetailRows, data)
        applySafetyDetails(calibrationMenuTargetDetailRows, data)
        applyReleaseSafetyDetails(calibrationMenuTargetDetailRows, data)
    elseif data.manualOverride == false and payloadHasSafetyOrBlockerDetails(data) then
        calibrationMenuOverrideNotes[interactionType] = ""
        calibrationMenuTargetDetailRows.detected = ""
        calibrationMenuTargetDetailRows.blockers = ""
        calibrationMenuTargetDetailRows.overrides = ""
        calibrationMenuTargetDetailRows.rejections = ""
        calibrationMenuTargetDetailRows.normalPlay = ""
        calibrationMenuTargetDetailRows.safetyGate = ""
        calibrationMenuTargetDetailRows.warnings = ""
        calibrationMenuTargetDetailRows.actorWarnings = ""
        calibrationMenuTargetDetailRows.actorBlockers = ""
        calibrationMenuTargetDetailRows.furnitureWarnings = ""
        calibrationMenuTargetDetailRows.furnitureBlockers = ""
        calibrationMenuTargetDetailRows.profileWarnings = ""
        calibrationMenuTargetDetailRows.profileBlockers = ""
        calibrationMenuTargetDetailRows.genericWarnings = ""
        calibrationMenuTargetDetailRows.genericBlockers = ""
        local reasons = tostring(data.testingOverrideReason or data.manualOverrideReason or "")
        if data.softBlockerReason and data.softBlockerReason ~= "" then
            reasons = reasons ~= "" and (reasons .. "," .. tostring(data.softBlockerReason)) or tostring(data.softBlockerReason)
        end
        if data.hardBlockerReason and data.hardBlockerReason ~= "" then
            reasons = reasons ~= "" and (reasons .. "," .. tostring(data.hardBlockerReason)) or tostring(data.hardBlockerReason)
        end
        applyReasonSections(calibrationMenuTargetDetailRows, compactReasonSections(reasons, data.interactionType), data.interactionType)
        applyBlockerDetails(calibrationMenuTargetDetailRows, data)
        applyRejectionDetails(calibrationMenuTargetDetailRows, data)
        applySafetyDetails(calibrationMenuTargetDetailRows, data)
        applyReleaseSafetyDetails(calibrationMenuTargetDetailRows, data)
    end
    if interactionType == "sitting" then
        if data.lectureAudienceTarget == true then
            calibrationMenuTargetDetailRows.status = "Audience seat selected"
        end
        calibrationMenuTargetDetailRows.detected = ""
    end
    applyAccessDetails(calibrationMenuTargetDetailRows, data)
    applyReleaseSafetyDetails(calibrationMenuTargetDetailRows, data)
    preserveStableTargetMetadata(calibrationMenuTargetDetailRows, previousRows, {
        preserveTargetDetails = sameTarget,
        preserveScales = sameTarget and not payloadHasScaleDetails(data),
        preserveSafety = sameTarget and not payloadHasSafetyOrBlockerDetails(data),
    })
    targetMetadata.sanitizeRowsForInteraction(calibrationMenuTargetDetailRows, interactionType)
    calibrationActionState.update(data, calibrationMenuTargetDetailRows, calibrationMenuResolvedType)
    refreshCalibrationMenuChrome()
end

local function handleCalibrationMenuKey(key)
    if not calibrationMenu then return false end
    if key and input and input.KEY and key.code == input.KEY.Escape then
        closeCalibrationMenu("escape")
        return true
    end
    return false
end

local function onCalibrationHotkey(source)
    settings = profiles.settings()
    local hotkeys = require('scripts/sitDownPlease/calibration/hotkeys')
    lastCalibrationHotkeyHandledAt = hotkeys.handle({
        settings = settings,
        input = input,
        core = core,
        I = I,
        source = source,
        menuOpen = calibrationMenu ~= nil,
        closeMenu = closeCalibrationMenu,
        openMenu = openCalibrationMenu,
        sendAction = sendCalibrationMenuAction,
        leftShiftDown = menuShiftDown,
        leftAltDown = menuAltDown,
        duplicateWindow = CALIBRATION_HOTKEY_DUPLICATE_WINDOW,
        lastHandledAt = lastCalibrationHotkeyHandledAt,
        debugLog = debugLog,
    }) or lastCalibrationHotkeyHandledAt
end

if input and input.registerTriggerHandler then
    pcall(function() input.registerTriggerHandler("SitDownPleaseOpenCalibrationMenu", async:callback(function() onCalibrationHotkey("trigger") end)) end)
end


local function playerCellLikelyHasInitialPlacement()
    settings = profiles.settings()
    if settings.disguiseInitialPlacement ~= true then return false end
    local cell = self.object and self.object.cell or nil
    if not (cell and cell.getAll) then return false end
    if cellIsExterior and cellIsExterior(cell) then return false end

    local npcsInCell = {}
    local okNpcs, npcs = pcall(function() return cell:getAll(types.NPC) end)
    if okNpcs and npcs then
        for _, npc in ipairs(npcs) do
            if npc and npc.id and npc ~= self.object then
                npcsInCell[#npcsInCell + 1] = npc
            end
        end
    end

    local currentHour = profiles.getGameHour and profiles.getGameHour() or nil
    local checkSleep = settings.sleepInitialPlacementEnabled == true
        and currentHour ~= nil
        and profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour)
    local checkSit = false -- Sitting can still be initial-placed out of sight, but it should never request the black cover.
    if not checkSleep then return false end

    local okObjects, objects = pcall(function() return cell:getAll() end)
    if not okObjects or not objects then return false end
    local sleepRadius = tonumber(settings.sleepInitialPlacementSearchRadius or settings.sleepSearchRadius or 1400) or 1400
    local sleepRadiusSq = sleepRadius * sleepRadius
    local sleepRelevantObjectSeen = false
    local function anyNpcNear(pos, radiusSq)
        if not pos then return false end
        for _, npc in ipairs(npcsInCell) do
            if npc and npc.position then
                local dx = (npc.position.x or 0) - (pos.x or 0)
                local dy = (npc.position.y or 0) - (pos.y or 0)
                local dz = math.abs((npc.position.z or 0) - (pos.z or 0))
                if dz < 360 and (dx * dx + dy * dy) <= radiusSq then return true end
            end
        end
        return false
    end
    for _, obj in ipairs(objects) do
        if obj and obj.position then
            if checkSleep and profiles.objectLooksRelevantForInteraction(obj, "sleeping", settings) then
                sleepRelevantObjectSeen = true
                if anyNpcNear(obj.position, sleepRadiusSq) then return true end
            end
            -- Sitting is deliberately excluded from black-cover probes. Seat memory and
            -- out-of-sight initial placement are handled by the global/NPC scripts.
        end
    end

    -- On load/cell entry the player script can see static beds before local NPC
    -- scripts have finished loading/reporting. The previous NPC-nearby-only probe
    -- skipped the precover in exactly the cells where the global script then did
    -- late-night initial sleep placement a couple of seconds later. Limit this
    -- object-only fallback to the sleep window so ordinary chair-heavy interiors
    -- do not get unnecessary black covers.
    if checkSleep and sleepRelevantObjectSeen then return true end

    return false
end

local function objectValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return obj:isValid() end)
    return ok and valid == true
end

runCalibrationCellAudit = function(reason, options)
    settings = profiles.settings()
    return calibrationCellAudit.run({
        core = core,
        nearby = nearby,
        async = async,
        util = util,
        profiles = profiles,
        player = self.object,
        cell = (self.object and self.object.cell) or lastObservedCell,
        settings = settings,
    }, reason, options)
end

local function positionInCameraView(pos, maxDistance)
    if not pos then return false, "missing_position" end
    local okViewport, viewport = pcall(camera.worldToViewportVector, pos + util.vector3(0, 0, 54))
    if not okViewport or not viewport then return false, "viewport_failed" end
    if (viewport.z or 0) <= 0 then return false, "behind_camera" end
    maxDistance = tonumber(maxDistance or 2200) or 2200
    if viewport.z > maxDistance then return false, "too_far" end

    local screen = ui.screenSize()
    local inPixels = viewport.x >= -96 and viewport.y >= -96
        and viewport.x <= (screen.x or 0) + 96
        and viewport.y <= (screen.y or 0) + 96
    local inNormalized = viewport.x >= -0.08 and viewport.y >= -0.08
        and viewport.x <= 1.08 and viewport.y <= 1.08
    if not (inPixels or inNormalized) then return false, "offscreen" end

    local okCameraPos, cameraPos = pcall(camera.getPosition)
    if okCameraPos and cameraPos then
        local okRay, ray = pcall(nearby.castRay, cameraPos, pos + util.vector3(0, 0, 54), {
            collisionType = nearby.COLLISION_TYPE.World,
            ignore = self.object,
            radius = 4,
        })
        if okRay and ray and ray.hit == true then
            return false, "occluded"
        end
    end
    return true, "visible"
end

local function objectOrPositionVisible(obj, pos, maxDistance)
    if objectValid(obj) and obj.cell == self.object.cell then
        local visible = positionInCameraView(obj.position, maxDistance)
        if visible then return true end
    end
    return positionInCameraView(pos, maxDistance)
end

local function currentSleepWindowState()
    settings = profiles.settings()
    if settings.sleepInitialPlacementEnabled ~= true then
        return false, true, nil, "sleep_initial_disabled"
    end
    local currentHour = profiles.getGameHour and profiles.getGameHour() or nil
    if currentHour == nil then
        return false, false, nil, "unknown_hour"
    end
    if profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        return true, true, currentHour, "inside_sleep_window"
    end
    return false, true, currentHour, "outside_sleep_window"
end

local function playerCellHasSleepRelevantObjects()
    settings = profiles.settings()
    if settings.disguiseInitialPlacement ~= true then return false end
    local insideSleepWindow, timeKnown = currentSleepWindowState()
    if not insideSleepWindow then return false end
    local cell = self.object and self.object.cell or nil
    if not (cell and cell.getAll) then return false end
    if cellIsExterior and cellIsExterior(cell) then return false end
    local okObjects, objects = pcall(function() return cell:getAll() end)
    if not okObjects or not objects then return false end
    for _, obj in ipairs(objects) do
        if obj and obj.position and profiles.objectLooksRelevantForInteraction(obj, "sleeping", settings) then
            return true
        end
    end
    return false
end

local function playerCellHasStationRelevantObjects()
    settings = profiles.settings()
    if settings.disguiseInitialPlacement ~= true then return false end
    if settings.stationLecternEnabled == false then return false end
    local cell = self.object and self.object.cell or nil
    if not (cell and cell.getAll) then return false end
    if cellIsExterior(cell) then return false end
    local okObjects, objects = pcall(function() return cell:getAll() end)
    if not okObjects or not objects then return false end
    for _, obj in ipairs(objects) do
        if obj and obj.position then
            local profile = profiles.stationProfileForObject and profiles.stationProfileForObject(obj, settings) or nil
            if profile then return true end
        end
    end
    return false
end

local function playerCellLikelyHasVisibleInitialPlacement()
    if not playerCellLikelyHasInitialPlacement() then return false end
    local cell = self.object and self.object.cell or nil
    if not (cell and cell.getAll) then return false end

    local okNpcs, npcs = pcall(function() return cell:getAll(types.NPC) end)
    if okNpcs and npcs then
        for _, npc in ipairs(npcs) do
            if npc and npc ~= self.object and objectOrPositionVisible(npc, npc.position, 1800) then
                return true
            end
        end
    end

    local currentHour = profiles.getGameHour and profiles.getGameHour() or nil
    local checkSleep = settings.sleepInitialPlacementEnabled == true
        and currentHour ~= nil
        and profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour)
    local checkSit = false -- Black-cover visibility is sleep/light-only; sitting has no overlay.
    local okObjects, objects = pcall(function() return cell:getAll() end)
    if okObjects and objects then
        for _, obj in ipairs(objects) do
            if obj and obj.position then
                local relevant = (checkSleep and profiles.objectLooksRelevantForInteraction(obj, "sleeping", settings))
                    or (checkSit and profiles.objectLooksRelevantForInteraction(obj, "sitting", settings))
                if relevant and objectOrPositionVisible(obj, obj.position, 1800) then return true end
            end
        end
    end
    return false
end

cellIsExterior = function(cell)
    if not cell then return false end
    if cell.isExterior ~= nil then return cell.isExterior == true end
    return cell.hasSky == true
end

local function transitionAllowsLoadCover(previousCell, currentCell, previousExterior, currentExterior, previousPosition, currentPosition)
    if not previousCell then return true, "initial_load" end
    if previousExterior == true and currentExterior == true then
        local distance = nil
        if previousPosition and currentPosition then
            local okDist, value = pcall(function() return (currentPosition - previousPosition):length() end)
            if okDist then distance = value end
        end
        if distance and distance > 2200 then return true, "exterior_teleport" end
        return false, "exterior_streaming"
    end
    return true, "load_or_teleport_cell_change"
end


local initialPlacementController = initialPlacementOverlayControllerModule.create({
    overlayLayers = overlayLayers,
    mainLayer = 'Notification',
    companionLayer = 'Windows',
    settings = function() return settings end,
    realTime = function() return core.getRealTime() end,
    playerCell = function() return self.object and self.object.cell or nil end,
    currentSleepWindowState = currentSleepWindowState,
    playerCellHasSleepRelevantObjects = playerCellHasSleepRelevantObjects,
    playerCellHasStationRelevantObjects = playerCellHasStationRelevantObjects,
    playerCellLikelyHasInitialPlacement = playerCellLikelyHasInitialPlacement,
    playerCellLikelyHasVisibleInitialPlacement = playerCellLikelyHasVisibleInitialPlacement,
    cellIsExterior = cellIsExterior,
    objectOrPositionVisible = objectOrPositionVisible,
    layerEnv = function()
        return {
            ui = ui,
            util = util,
            debugLog = debugLog,
            mainLayer = 'Notification',
            companionLayer = 'Windows',
            mainName = 'SitDownPleaseInitialPlacementOverlay',
            companionName = 'SitDownPleaseInitialPlacementOverlayTop',
            textName = 'SitDownPleaseInitialPlacementOverlayText',
            texturePath = 'textures/sitdownplease/sitdownplease_black.png',
            showLoadingText = true,
            loadingText = 'Loading...',
        }
    end,
    debugLog = debugLog,
})

local function resetInitialPlacementDynamicState(reason, keepOverlay)
    return initialPlacementController.resetDynamicState(reason, keepOverlay)
end

local function updateInitialPlacementOverlayFade()
    return initialPlacementController.updateFade()
end

local function maybeStartLoadCover(reason, transitionReason)
    return initialPlacementController.maybeStartLoadCover(reason, transitionReason)
end

local function maybeStartStationWaitPrecover(deltaGameTime)
    return initialPlacementController.maybeStartStationWaitPrecover(deltaGameTime)
end

local function queueTeleportPrecover(reason)
    return initialPlacementController.queueTeleportPrecover(reason)
end

local function pollCalibrationMenuEscape()
    if not calibrationMenu then
        calibrationMenuEscapeDown = false
        return
    end
    local pressed = false
    if input and input.KEY and input.KEY.Escape and input.isKeyPressed then
        local ok, value = pcall(input.isKeyPressed, input.KEY.Escape)
        pressed = ok and value == true
    end
    if pressed and not calibrationMenuEscapeDown then
        closeCalibrationMenu("escape")
    end
    calibrationMenuEscapeDown = pressed
end

local function onUpdate(dt)
    local currentCell = self.object and self.object.cell or nil
    local currentPosition = self.object and self.object.position or nil
    local currentGameTime = profiles.getGameTime and profiles.getGameTime() or nil

    if currentGameTime ~= nil and lastObservedGameTime ~= nil then
        local deltaGameTime = currentGameTime - lastObservedGameTime
        if deltaGameTime >= STATION_WAIT_PRECOVER_GAME_SECONDS then
            maybeStartStationWaitPrecover(deltaGameTime)
        end
    end
    if currentGameTime ~= nil then
        lastObservedGameTime = currentGameTime
    end

    if currentCell and currentCell ~= lastObservedCell and lastObservedCell ~= nil then
        resetInitialPlacementDynamicState("cell_transition_new_context", true)
    end

    initialPlacementController.processQueuedTeleportPrecover(currentCell)

    if calibrationMenu and I and I.UI and I.UI.getMode then
        local interfaceMode = calibrationInterfaceModeName()
        local okMode, mode = pcall(function() return I.UI.getMode() end)
        if okMode and mode ~= nil and mode ~= interfaceMode then
            closeCalibrationMenu("mode_changed")
        end
    end

    if currentCell and currentCell ~= lastObservedCell then
        local currentExterior = cellIsExterior(currentCell)
        local allowCover, transitionReason = transitionAllowsLoadCover(lastObservedCell, currentCell, lastObservedCellExterior, currentExterior, lastObservedPlayerPosition, currentPosition)
        if currentExterior == true then allowCover = false end
        local previousCell = lastObservedCell
        lastObservedCell = currentCell
        lastObservedCellExterior = currentExterior
        lastObservedPlayerPosition = currentPosition
        resetCalibrationTargetFilter("cell_change")
        calibrationBlockerMarkers.clearAll("cell_change")
        if calibrationMenu and profiles.logLevel(settings) ~= "off" then
            pcall(function()
                async:newUnsavableGameTimer(0.2, function()
                    if not calibrationMenu then return end
                    if not runCalibrationCellAudit then return end
                    local ok, message = runCalibrationCellAudit("calibration_menu_cell_change", { force = false })
                    if ok == true then
                        calibrationMenuStatus = message
                        refreshCalibrationMenuChrome()
                        debugLog("calibration cell audit auto", "cell_change", tostring(message))
                    else
                        debugLog("calibration cell audit auto skipped", "cell_change", tostring(message))
                    end
                end)
            end)
        end
        if allowCover == true then
            maybeStartLoadCover("player_cell_entry_precover", transitionReason)
        else
            debugLog("initial placement precover skipped", tostring(transitionReason), "from", tostring(previousCell), "to", tostring(currentCell))
        end
        initialPlacementController.settleNoLikelyInitialCandidates()
    elseif currentPosition then
        lastObservedPlayerPosition = currentPosition
    end

    updateInitialPlacementOverlayFade()

    pollCalibrationMenuEscape()

    calibrationBlockerMarkers.update()
    playerStealthObserver.update(dt)
end

onDisguiseInitialPlacement = function(data)
    return initialPlacementController.show(data)
end

onInitialPlacementSettled = function(data)
    return initialPlacementController.settle(data)
end

local function onInitialAssignmentScanComplete(data)
    return initialPlacementController.scanComplete(data)
end

local function onUiModeChanged(data)
    if not data then return end

    if calibrationMenu then
        local interfaceMode = calibrationInterfaceModeName()
        if data.newMode ~= nil and data.newMode ~= interfaceMode then
            closeCalibrationMenu("mode_changed")
        elseif data.newMode == nil and calibrationMenuModeActive then
            openCalibrationMenuMode()
            debugLog("calibration menu interface mode restored", describeUiMode())
        end
    end

    if data.newMode and dialogueModes[data.newMode] and data.arg then
        if dialogueTarget and dialogueTarget ~= data.arg then
            clearDialogueTarget("dialogue_target_changed")
        end

        dialogueTarget = data.arg
        debugLog("dialogue started", tostring(data.arg.recordId or data.arg.id), tostring(data.newMode))
        data.arg:sendEvent('InteractionDialogueStarted', {
            player = self.object,
            mode = data.newMode,
        })
        return
    end

    if data.oldMode and dialogueModes[data.oldMode] and not (data.newMode and dialogueModes[data.newMode]) then
        clearDialogueTarget("dialogue_mode_closed")
    elseif not data.newMode then
        clearDialogueTarget("ui_closed")
    end
end

local function onSleepingActorState(data)
    local actorId, sleeping = playerStealthObserver.setSleepingActor(data)
    if not actorId then return end

    if sleeping == true then
        debugLog("sleeping actor registered for sneak compatibility", tostring(data.recordId or actorId), tostring(data.reason))
    else
        debugLog("sleeping actor cleared for sneak compatibility", tostring(data.recordId or actorId), tostring(data.reason))
    end
end

local function onCalibrationBlockerMarker(data)
    return calibrationBlockerMarkers.show(data)
end

local function onCalibrationBlockerMarkerClear(data)
    if data and data.all == true then
        return calibrationBlockerMarkers.clearAll(data.reason or "clear_all")
    end
    return calibrationBlockerMarkers.clearActor(data)
end

local interface = {
    version = 1,
    sleepingActors = sleepingActors,
    isActorSleeping = function(actor)
        return playerStealthObserver.isActorSleeping(actor)
    end,
}

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = function() maybeStartLoadCover("player_load_precover") end,
        onInit = function() maybeStartLoadCover("player_init_precover") end,
        onTeleported = function() queueTeleportPrecover("player_teleported_precover") end,
        onKeyPress = function(key)
            if calibrationMenu and handleCalibrationMenuKey(key) then
                return
            end
        end,
    },
    eventHandlers = {
        UiModeChanged = onUiModeChanged,
        SitDownPleaseSleepingActorState = onSleepingActorState,
        SitDownPleaseSeatedDialogueState = onSeatedDialogueState,
        SitDownPleaseDisguiseInitialPlacement = onDisguiseInitialPlacement,
        SitDownPleaseInitialPlacementSettled = onInitialPlacementSettled,
        SitDownPleaseInitialAssignmentScanComplete = onInitialAssignmentScanComplete,
        SitDownPleaseCalibrationMenuStatus = onCalibrationMenuStatus,
        SitDownPleaseCalibrationOffsets = onCalibrationOffsets,
        SitDownPleaseCalibrationBlockerMarker = onCalibrationBlockerMarker,
        SitDownPleaseCalibrationBlockerMarkerClear = onCalibrationBlockerMarkerClear,
    },
    interfaceName = profiles.MOD_ID,
    interface = interface,
}
