-- interactionPlayer.lua
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
local overlayLayers = require('scripts/sitDownPlease/ui/placementOverlayLayers')

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
local stealthPollTimer = 0
local lastSneakState = nil
local lastSneakKnown = nil
local lastMoveState = nil
local lastInvisibleState = nil
local lastChameleonState = nil
local sleepingActors = {}
local initialPlacementOverlay = nil
local initialPlacementOverlayTop = nil
local initialPlacementOverlayText = nil
local initialPlacementOverlayUntil = 0
local initialPlacementOverlayVisibleSensitive = false
local initialPlacementOverlayMinUntil = 0
local initialPlacementLoadBridgeUntil = 0
local initialPlacementAwaitingAssignmentScan = false
local initialPlacementLocalResultsPending = 0
local initialPlacementPendingActorIds = {}
local initialPlacementScanSource = nil
local initialPlacementOverlayFadeSeconds = 0.35
local initialPlacementSuppressFreshPostCoverUntil = 0
local initialPlacementOverlayFailSafeUntil = 0
local INITIAL_PLACEMENT_DYNAMIC_TICK_SECONDS = 0.35
local INITIAL_PLACEMENT_LOAD_BRIDGE_FAILSAFE_SECONDS = 10.0
local INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS = 5.0
local INITIAL_PLACEMENT_INITIAL_LOAD_POST_POSE_HOLD_SECONDS = 0.65
local INITIAL_PLACEMENT_CELL_POST_POSE_HOLD_SECONDS = 0.65
local INITIAL_PLACEMENT_OVERLAY_MAIN_LAYER = 'Notification'
local INITIAL_PLACEMENT_OVERLAY_COMPANION_LAYER = 'Windows'
local calibrationMenu = nil
local calibrationMenuOverlay = nil
local calibrationMenuActiveLayer = "Windows"
local CALIBRATION_MODE = "Interface" -- Kept only for cleanup compatibility; the calibration UI no longer depends on this mode.
local calibrationMenuStatus = ""
local calibrationMenuStatusLayout = nil -- legacy nil; action status now goes to messages, not panel text.
local lastCalibrationToastText = nil
local lastCalibrationToastAt = nil
local calibrationMenuTargetLayout = nil
local calibrationMenuFilterLayout = nil
local calibrationMenuPoseLayout = nil
local calibrationMenuTargetText = "Target: none selected"
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
local pendingTeleportPrecover = false
local pendingTeleportPrecoverReason = nil
local pendingTeleportPrecoverAt = 0
local pendingTeleportPrecoverCell = nil
local lastTeleportPrecoverAt = -100
local restoreSeatedDialogueCamera = function() end
local onSeatedDialogueState = function() end

local function debugLog(...)
    profiles.debugLog(settings, "player", ...)
end

local function degreesToRadians(value)
    return (tonumber(value) or 0) * math.pi / 180
end

local openCalibrationMenu
local onInitialPlacementSettled

profiles.subscribeSettings(async:callback(function()
    settings = profiles.settings()
end))

local function clearDialogueTarget(reason)
    if not dialogueTarget then return end
    dialogueTarget:sendEvent('InteractionDialogueStopped', {
        player = self.object,
        reason = reason or "dialogue_stopped",
    })
    dialogueTarget = nil
    restoreSeatedDialogueCamera(reason or "dialogue_stopped")
end

local function readPlayerStealthState()
    local isSneaking = false
    local known = false
    local isMoving = false
    local isInvisible = false
    local chameleon = 0

    local okControls, controlsData = pcall(function()
        local controls = self.controls
        if not controls then return nil end
        local sneak = nil
        if controls.sneak ~= nil then sneak = controls.sneak end
        if sneak == nil and controls.isSneaking ~= nil then sneak = controls.isSneaking end
        if sneak == nil and controls.sneaking ~= nil then sneak = controls.sneaking end

        local movement = tonumber(controls.movement or 0) or 0
        local sideMovement = tonumber(controls.sideMovement or 0) or 0
        return {
            sneak = sneak,
            moving = math.abs(movement) > 0.01 or math.abs(sideMovement) > 0.01,
        }
    end)

    if okControls and controlsData then
        local value = controlsData.sneak
        if value ~= nil then
            known = true
            if type(value) == "number" then
                isSneaking = value ~= 0
            else
                isSneaking = value == true
            end
        end
        isMoving = controlsData.moving == true
    end

    local okEffects = pcall(function()
        if not (types and types.Actor and types.Actor.activeEffects) then return end
        local activeEffects = types.Actor.activeEffects(self.object)
        if not activeEffects then return end
        local magic = core and core.magic and core.magic.EFFECT_TYPE
        if not magic then return end
        local invisibility = activeEffects:getEffect(magic.Invisibility)
        isInvisible = invisibility ~= nil and tonumber(invisibility.magnitude or 0) > 0
        local cham = activeEffects:getEffect(magic.Chameleon)
        chameleon = cham and tonumber(cham.magnitude or 0) or 0
    end)
    if not okEffects then
        isInvisible = false
        chameleon = 0
    end

    return {
        isSneaking = isSneaking,
        known = known,
        isMoving = isMoving,
        isInvisible = isInvisible,
        chameleon = chameleon,
    }
end

local function publishStealthState(force)
    local state = readPlayerStealthState()
    if not force
        and state.isSneaking == lastSneakState
        and state.known == lastSneakKnown
        and state.isMoving == lastMoveState
        and state.isInvisible == lastInvisibleState
        and state.chameleon == lastChameleonState then
        return
    end

    lastSneakState = state.isSneaking
    lastSneakKnown = state.known
    lastMoveState = state.isMoving
    lastInvisibleState = state.isInvisible
    lastChameleonState = state.chameleon

    core.sendGlobalEvent('SitDownPleasePlayerStealthState', {
        player = self.object,
        isSneaking = state.isSneaking,
        known = state.known,
        isMoving = state.isMoving,
        isInvisible = state.isInvisible,
        chameleon = state.chameleon,
    })
end

local function clearSneakIsGoodNowStatus(actorId, reason)
    -- Optional compatibility, no hard dependency. Sneak Is Good Now exposes its
    -- player-side observer status table. If the sleeping actor is in that table,
    -- destroy the marker before removing the entry; otherwise the UI element can
    -- stick around because Sneak! no longer updates the removed status object.
    local sig = I and I.SneakIsGoodNow
    local statuses = sig and sig.observerActorStatuses
    if not statuses then return false end

    local ast = statuses[actorId]
    if not ast then return false end

    ast.noticing = false
    ast.progress = 0.0
    ast.successRolls = 3
    ast.sneakChance = 100
    ast.isKnockedOut = true
    ast.inLOS = false

    if ast.marker then
        local ok = pcall(function()
            if ast.marker.destroy then
                ast.marker:destroy()
            elseif ast.marker.disappear then
                ast.marker:disappear(false, true)
            end
        end)
        if not ok then
            debugLog("sneak compatibility marker cleanup failed", tostring(actorId), tostring(reason))
        end
        ast.marker = nil
    end

    statuses[actorId] = nil
    return true
end

local function suppressSneakIsGoodNowForSleepingActors()
    for actorId, info in pairs(sleepingActors) do
        local actor = info and info.actor
        local valid = false
        if actor then
            local okValid, isValid = pcall(function() return actor:isValid() end)
            valid = okValid and isValid == true
        end

        if not valid then
            sleepingActors[actorId] = nil
            clearSneakIsGoodNowStatus(actorId, "invalid_sleeping_actor")
        else
            clearSneakIsGoodNowStatus(actorId, info.reason or "sleeping")
        end
    end
end


local calibrationMenuAdjustmentLayout = nil
local calibrationMenuModeLayout = nil
local lastPlayerCellKey = nil
local onDisguiseInitialPlacement
local calibrationMenuAdjustments = {
    sleeping = { x = 0, y = 0, z = 0, yaw = 0 },
    sitting = { x = 0, y = 0, z = 0, yaw = 0 },
}
local calibrationMenuProfileOffsets = {
    sleeping = { x = 0, y = 0, z = 0, yaw = 0 },
    sitting = { x = 0, y = 0, z = 0, yaw = 0 },
}
local calibrationMenuPoseNotes = {
    sleeping = "",
    sitting = "",
}
local calibrationMenuOverrideNotes = {
    sleeping = "",
    sitting = "",
}

local function zeroCalibrationDisplayState(interactionType)
    local typesToClear = {}
    if interactionType == "sitting" or interactionType == "sleeping" then
        typesToClear[#typesToClear + 1] = interactionType
    else
        typesToClear[#typesToClear + 1] = "sitting"
        typesToClear[#typesToClear + 1] = "sleeping"
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
    return "Bed"
end

local function calibrationMenuDisplayType()
    if calibrationMenuResolvedType == "sitting" or calibrationMenuResolvedType == "sleeping" then
        return calibrationMenuResolvedType
    end
    if calibrationMenuActiveType == "sitting" or calibrationMenuActiveType == "sleeping" then
        return calibrationMenuActiveType
    end
    return nil
end

local function signedNumber(value, suffix)
    value = tonumber(value) or 0
    local prefix = value > 0 and "+" or ""
    return prefix .. tostring(value) .. (suffix or "")
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

local function readableOverrideReason(reason)
    local text = tostring(reason or "")
    if text == "" or text == "nil" then return "Testing override applied" end
    text = text:gsub("seat_surface_blocked_by_item", "seat item blocker")
    text = text:gsub("tight_table_or_counter_rejected", "clearance blocker")
    text = text:gsub("barter_service_npc", "service NPC gate")
    text = text:gsub("trainer_service_npc", "trainer gate")
    text = text:gsub("travel_service_npc", "travel service gate")
    text = text:gsub("service_npc", "service NPC gate")
    text = text:gsub("guard_or_publican_class", "guard/publican gate")
    text = text:gsub("publican_class", "publican gate")
    text = text:gsub("locked_route_door", "locked route door")
    text = text:gsub("blocked_route_door", "blocked route door")
    text = text:gsub("bench_slot_unavailable_short_length", "bench slot fallback")
    text = text:gsub("_", " ")
    text = text:gsub(",", " + ")
    return "Testing override: " .. text
end

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
    local overrideNote = calibrationMenuOverrideNotes[displayType] or ""
    if poseNote ~= "" and overrideNote ~= "" then return poseNote .. " · " .. overrideNote end
    return poseNote ~= "" and poseNote or overrideNote
end

local function modeLabel()
    if calibrationMenuActiveType == "auto" then
        return "Target filter: Auto"
    end
    return "Target filter: " .. modeName(calibrationMenuActiveType)
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
    return "Click buttons directly. Esc closes. The configured hotkey toggles this menu."
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

local function refreshCalibrationMenuChrome()
    if calibrationMenuModeLayout and calibrationMenuModeLayout.props then
        calibrationMenuModeLayout.props.text = modeLabel()
    end
    if calibrationMenuFilterLayout and calibrationMenuFilterLayout.props then
        calibrationMenuFilterLayout.props.text = modeLabel()
    end
    if calibrationMenuTargetLayout and calibrationMenuTargetLayout.props then
        calibrationMenuTargetLayout.props.text = calibrationMenuTargetText or "Target: none selected"
    end
    if calibrationMenuStatusLayout and calibrationMenuStatusLayout.props then
        calibrationMenuStatusLayout.props.text = calibrationMenuStatus
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
    calibrationMenuTargetLabel = ""
    calibrationMenuResolvedType = nil
    zeroCalibrationDisplayState()
    refreshCalibrationMenuChrome()
    debugLog("calibration target filter reset", tostring(reason or "reset"), "filter", "auto")
end

setCalibrationTarget = function(interactionType)
    if interactionType == "auto" or interactionType == "sitting" or interactionType == "sleeping" then
        calibrationMenuActiveType = interactionType
        calibrationMenuStatus = ""
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        zeroCalibrationDisplayState()
        refreshCalibrationMenuChrome()
        if interactionType == "auto" then
            showCalibrationToast("Target filter: Auto. Find Target will choose the nearest active bed or seat target.")
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
    calibrationMenuStatusLayout = nil
    calibrationMenuTargetLayout = nil
    calibrationMenuFilterLayout = nil
    calibrationMenuAdjustmentLayout = nil
    calibrationMenuModeLayout = nil
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
        if calibrationMenuActiveType == "auto" then return "Finding the nearest active bed or seat target..." end
        return "Finding the nearest active " .. modeName(calibrationMenuActiveType):lower() .. " target..."
    end
    if action == "resume" or action == "send" then return "Asking the target to sit or lie down again..." end
    if action == "reapply" then return "Reapplying the current position..." end
    if action == "print" then return "Printing the profile line to openmw.log..." end
    if action == "reset" then return "Resetting to the saved profile..." end
    if action == "clear" then return "Target cleared." end
    if action == "spawn_test" then
        local label = calibrationMenuActiveType == "auto" and "target" or modeName(calibrationMenuActiveType):lower()
        return "Spawning Admiral Rolston and assigning him to the nearest free " .. label .. "..."
    end
    if action == "remove_test" then return "Removing Admiral Rolston..." end
    if action == "nudge" then
        local axis, amount = "position", 0
        if payload then
            if payload.x then axis, amount = "X", payload.x
            elseif payload.y then axis, amount = "Y", payload.y
            elseif payload.z then axis, amount = "Z", payload.z
            elseif payload.yaw then axis, amount = "Yaw", payload.yaw
            end
        end
        return "Moved " .. axis .. " " .. signedNumber(amount, axis == "Yaw" and "°" or "") .. ". Use Sit / Lay Down Please only if the target has stood up."
    end
    return "Action requested."
end

sendCalibrationMenuAction = function(action, payload)
    payload = payload or {}
    if action == "nudge" then
        rememberMenuAdjustment(payload)
    elseif action == "reset" then
        resetMenuAdjustment(calibrationMenuDisplayType() or calibrationMenuActiveType)
    elseif action == "capture" or action == "spawn_test" or action == "remove_test" then
        resetMenuAdjustment(calibrationMenuDisplayType() or calibrationMenuActiveType)
    elseif action == "clear" then
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        zeroCalibrationDisplayState()
    end
    payload.interactionType = calibrationMenuActiveType
    payload.action = action
    payload.player = self.object
    payload.source = "developer_menu"
    core.sendGlobalEvent("SitDownPleaseCalibrationMenuAction", payload)
    calibrationMenuStatus = actionStatus(action, payload)
    -- Keep transient action text out of the fragile panel. The panel shows only
    -- stable target/filter/change state; action feedback goes to OpenMW messages.
    refreshCalibrationMenuChrome()
    showCalibrationToast(calibrationMenuStatus)
end

local function textBlock(text, size, width, height, align)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = tostring(text or ""),
            textSize = size or 15,
            textColor = util.color.rgb(0.88, 0.86, 0.78),
            textShadow = true,
            textShadowColor = util.color.rgb(0, 0, 0),
            multiline = true,
            wordWrap = true,
            size = util.vector2(width or 560, height or 24),
            textAlignH = align or ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
end

local function button(label, onClick, width, height, textSize)
    return {
        template = I.MWUI.templates.boxThick or I.MWUI.templates.boxSolid,
        props = { size = util.vector2(width or 120, height or 30) },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = tostring(label),
                            textColor = util.color.rgb(0.88, 0.86, 0.78),
                            textShadow = true,
                            textShadowColor = util.color.rgb(0, 0, 0),
                            textSize = textSize or 14,
                            size = util.vector2((width or 120) - 8, height or 30),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                    },
                },
            },
        },
        events = {
            mouseClick = async:callback(function()
                if onClick then onClick() end
            end),
        },
    }
end

local function row(items, width, height, arrange)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = arrange or ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Center,
            size = util.vector2(width or 560, height or 34),
        },
        content = ui.content(items),
    }
end

local function gap(width, height)
    return { type = ui.TYPE.Widget, props = { size = util.vector2(width or 8, height or 8) } }
end

local function divider(width)
    return { type = ui.TYPE.Widget, template = I.MWUI.templates.boxSolid, props = { size = util.vector2(width or 560, 1) } }
end

local function sectionTitle(number, title)
    return textBlock(tostring(number) .. ". " .. tostring(title), 16, 560, 28)
end

nudgePayload = function(axis, amount)
    local payload = {}
    payload[axis] = amount
    return payload
end

local function axisNudgeRow(axis, label, values)
    local items = { textBlock(label, 14, 48, 28, ui.ALIGNMENT.Center) }
    for _, value in ipairs(values) do
        local prefix = value > 0 and "+" or ""
        local suffix = axis == "yaw" and "°" or ""
        items[#items + 1] = button(prefix .. tostring(value) .. suffix, function()
            sendCalibrationMenuAction("nudge", nudgePayload(axis, value))
        end, 52, 28, 13)
        items[#items + 1] = gap(4, 1)
    end
    return row(items, 560, 30)
end

local function calibrationMenuLayer()
    -- In this mod stack a Windows-layer Lua root can be created with Interface
    -- mode active but still render behind gameplay. Modal is a proven visible
    -- custom UI layer here (CraftingFramework/OpenMWHookshot).
    return "Modal"
end

local function getCalibrationUiSize()
    local okLayer, layerSize = pcall(function()
        local layerName = calibrationMenuActiveLayer or calibrationMenuLayer()
        local layerIndex = ui.layers and ui.layers.indexOf and ui.layers.indexOf(layerName) or nil
        local layer = layerIndex and ui.layers[layerIndex] or nil
        return layer and layer.size or nil
    end)
    if okLayer and layerSize and layerSize.x and layerSize.y and layerSize.x > 0 and layerSize.y > 0 then
        return layerSize
    end
    local okScreen, screen = pcall(ui.screenSize)
    if okScreen and screen and screen.x and screen.y then return screen end
    return util.vector2(1280, 720)
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
    local screen = getCalibrationUiSize()
    local panelWidth = math.min(620, math.max(588, screen.x - 160))
    local panelHeight = math.min(610, math.max(540, screen.y - 96))
    local panelSize = util.vector2(panelWidth, panelHeight)
    local panelPosition = util.vector2((screen.x - panelWidth) / 2, (screen.y - panelHeight) / 2)
    local contentWidth = panelWidth - 48
    local moveValues = { -20, -5, -1, 1, 5, 20 }
    local yawValues = { -45, -15, -1, 1, 15, 45 }
    local COLOR_BG = util.color.rgb(0, 0, 0)
    local COLOR_PANEL = util.color.rgb(0.03, 0.025, 0.02)
    local COLOR_BUTTON = util.color.rgb(0.08, 0.065, 0.045)
    local COLOR_BUTTON_FOCUS = util.color.rgb(0.22, 0.18, 0.11)
    local COLOR_TEXT = util.color.rgb(0.88, 0.86, 0.78)
    local COLOR_MUTED = util.color.rgb(0.66, 0.62, 0.52)
    local COLOR_GOLD = util.color.rgb(1.0, 0.82, 0.42)
    local white = ui.texture { path = "white" }
    local content = ui.content {}

    local function addText(name, text, x, y, w, h, size, color, align, noWrap)
        local layout = {
            name = name,
            type = ui.TYPE.Text,
            props = {
                position = util.vector2(x, y),
                size = util.vector2(w, h),
                text = tostring(text or ""),
                textColor = color or COLOR_TEXT,
                textShadow = true,
                textShadowColor = COLOR_BG,
                textSize = size or 15,
                textAlignH = align or ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                multiline = noWrap ~= true,
                wordWrap = noWrap ~= true,
            },
        }
        content:add(layout)
        return layout
    end

    local function addRule(y)
        content:add({
            type = ui.TYPE.Image,
            props = {
                position = util.vector2(24, y),
                size = util.vector2(contentWidth, 1),
                resource = white,
                color = util.color.rgb(0.55, 0.47, 0.30),
                alpha = 0.8,
            },
        })
    end

    local function addButton(label, x, y, w, h, onClick, size)
        local background = {
            name = "background",
            type = ui.TYPE.Image,
            props = {
                relativeSize = util.vector2(1, 1),
                resource = white,
                color = COLOR_BUTTON,
                alpha = 0.95,
            },
        }
        local buttonLayout = {
            type = ui.TYPE.Widget,
            props = {
                position = util.vector2(x, y),
                size = util.vector2(w, h),
            },
            content = ui.content {
                background,
                {
                    name = "text",
                    type = ui.TYPE.Text,
                    props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        size = util.vector2(w - 8, h),
                        text = tostring(label),
                        textColor = COLOR_TEXT,
                        textShadow = true,
                        textShadowColor = COLOR_BG,
                        textSize = size or 14,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                {
                    name = "clickbox",
                    type = ui.TYPE.Widget,
                    props = { relativeSize = util.vector2(1, 1) },
                    events = {
                        mouseClick = async:callback(function()
                            if onClick then onClick() end
                        end),
                        focusGain = async:callback(function()
                            background.props.color = COLOR_BUTTON_FOCUS
                            if calibrationMenu then calibrationMenu:update() end
                        end),
                        focusLoss = async:callback(function()
                            background.props.color = COLOR_BUTTON
                            if calibrationMenu then calibrationMenu:update() end
                        end),
                    },
                },
            },
        }
        content:add(buttonLayout)
        return buttonLayout
    end

    content:add({
        name = "panelBackground",
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.26,
        },
    })
    content:add({
        name = "readableHeaderBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, 10),
            size = util.vector2(panelWidth - 20, 118),
            resource = white,
            color = COLOR_PANEL,
                alpha = 0.58,
        },
    })
    content:add({
        name = "readableFooterBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, 486),
            size = util.vector2(panelWidth - 20, 116),
            resource = white,
            color = COLOR_PANEL,
                alpha = 0.44,
        },
    })
    content:add({
        name = "panelBorder",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(2, 2),
            size = util.vector2(panelWidth - 4, panelHeight - 4),
            resource = white,
            color = util.color.rgb(0.28, 0.22, 0.12),
            alpha = 0.35,
        },
    })

    addText("title", "Sit Down Please: Developer Calibration", 24, 16, contentWidth, 28, 17, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("help", calibrationKeyHelpText(), 24, 42, contentWidth, 22, 12, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    calibrationMenuTargetLayout = addText("target", calibrationMenuTargetText, 24, 66, contentWidth, 24, 13, COLOR_TEXT, ui.ALIGNMENT.Start, true)
    calibrationMenuFilterLayout = addText("filter", modeLabel(), 24, 94, 152, 28, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    addButton("Auto", 182, 92, 74, 28, function() setCalibrationTarget("auto") end, 13)
    addButton("Bed", 264, 92, 66, 28, function() setCalibrationTarget("sleeping") end, 13)
    addButton("Seat", 338, 92, 66, 28, function() setCalibrationTarget("sitting") end, 13)
    addRule(132)

    addText("findTitle", "1. Select Target", 24, 142, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("findHelp", "Find captures an active target. Assign uses the nearest eligible standing NPC.", 24, 166, contentWidth, 22, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    addButton("Find Target", 24, 194, 116, 30, function() sendCalibrationMenuAction("capture") end, 13)
    addButton("Assign Nearest", 148, 194, 138, 30, function() sendCalibrationMenuAction("assign_nearest") end, 12)
    addButton("Spawn Test NPC", 294, 194, 130, 30, function() sendCalibrationMenuAction("spawn_test") end, 12)
    addButton("Remove Test", 432, 194, 116, 30, function() sendCalibrationMenuAction("remove_test") end, 12)
    addRule(236)

    addText("nudgeTitle", "2. Nudge Position", 24, 246, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("nudgeHelp", "Offsets are furniture-local. Click small steps once close; changes apply immediately.", 24, 270, contentWidth, 22, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)

    local function addNudgeRow(axis, label, y, values)
        addText("axis_" .. axis, label, 28, y, 42, 30, 14, COLOR_TEXT, ui.ALIGNMENT.Center)
        local x = 78
        for _, value in ipairs(values) do
            local prefix = value > 0 and "+" or ""
            local suffix = axis == "yaw" and "°" or ""
            addButton(prefix .. tostring(value) .. suffix, x, y, 52, 28, function()
                sendCalibrationMenuAction("nudge", nudgePayload(axis, value))
            end, 13)
            x = x + 58
        end
    end

    addNudgeRow("x", "X", 310, moveValues)
    addNudgeRow("y", "Y", 344, moveValues)
    addNudgeRow("z", "Z", 378, moveValues)
    addNudgeRow("yaw", "Yaw", 412, yawValues)
    calibrationMenuAdjustmentLayout = addText("adjustment", adjustmentLabel(), 24, 450, contentWidth, 26, 14, COLOR_TEXT, ui.ALIGNMENT.Start, true)
    calibrationMenuPoseLayout = addText("pose", poseNoteLabel(), 24, 468, contentWidth, 14, 12, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    addRule(486)

    addText("finishTitle", "3. Finish", 24, 494, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addButton("Sit / Lay Down Please", 24, 524, 188, 32, function() sendCalibrationMenuAction("resume") end, 13)
    addButton("Print Profile Line", 220, 524, 162, 32, function() sendCalibrationMenuAction("print") end, 14)
    addButton("Reset to Saved", 390, 524, 142, 32, function() sendCalibrationMenuAction("reset") end, 14)
    addButton("Clear Target", 24, 566, 132, 30, function() sendCalibrationMenuAction("clear") end, 13)
    addButton("Close", 164, 566, 96, 30, function() closeCalibrationMenu("button") end, 13)

    return {
        type = ui.TYPE.Widget,
        layer = calibrationMenuActiveLayer,
        name = "SitDownPleaseCalibrationMenuRoot",
        props = {
            position = panelPosition,
            size = panelSize,
        },
        events = {
            keyPress = async:callback(function(key)
                if key and input and input.KEY and key.code == input.KEY.Escape then
                    closeCalibrationMenu("escape")
                end
            end),
        },
        content = content,
    }
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
    pcall(function() calibrationMenu:update() end)

    pcall(function()
        async:newUnsavableGameTimer(0.05, verifyCalibrationMenuMode)
    end)
    if not modeOk then
        calibrationMenuStatus = "Menu visible, but Interface mode failed. Mouse input may not work; close with Esc."
        refreshCalibrationMenuChrome()
        showCalibrationToast(calibrationMenuStatus)
    end

    debugLog("calibration menu opened", tostring(reason or "manual"), "layer", tostring(calibrationMenuActiveLayer), "modeState", describeUiMode(), "modeActive", tostring(calibrationMenuModeActive), "pattern", "hookshot_absolute_modal_widget")
end

local function onCalibrationMenuStatus(data)
    calibrationMenuStatus = tostring(data and data.message or "Calibration action completed.")
    if data and data.cleared == true then
        calibrationMenuTargetText = "Target: none selected"
        calibrationMenuTargetLabel = ""
        calibrationMenuResolvedType = nil
        zeroCalibrationDisplayState()
        debugLog("calibration_target_display_state", calibrationMenuTargetText)
    elseif data and data.targetLabel then
        local targetLabel = tostring(data.targetLabel)
        if targetLabel == "" or targetLabel == "nil -> nil (default)" then
            targetLabel = "target selected; waiting for confirmation"
        end
        local typeLabel = data.interactionType == "sitting" and "Seat" or (data.interactionType == "sleeping" and "Bed" or "Target")
        calibrationMenuResolvedType = data.interactionType
        calibrationMenuTargetLabel = targetLabel
        calibrationMenuTargetText = "Resolved target: " .. typeLabel .. " · " .. targetLabel
        if data.testingOverride == true and (data.interactionType == "sitting" or data.interactionType == "sleeping") then
            calibrationMenuOverrideNotes[data.interactionType] = readableOverrideReason(data.testingOverrideReason)
        elseif data.interactionType == "sitting" or data.interactionType == "sleeping" then
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
    if interactionType ~= "sitting" and interactionType ~= "sleeping" then return end
    if calibrationMenuTargetLabel == "" then
        debugLog("calibration_offsets_ignored_no_target", tostring(data and data.targetLabel or ""))
        return
    end
    local targetLabel = tostring(data and data.targetLabel or "")
    if targetLabel ~= "" and calibrationMenuTargetLabel ~= "" and targetLabel ~= calibrationMenuTargetLabel then
        debugLog("calibration_offsets_ignored_stale_target", "incoming", targetLabel, "current", calibrationMenuTargetLabel)
        return
    end
    if data.profileOffset then
        calibrationMenuProfileOffsets[interactionType] = {
            x = tonumber(data.profileOffset.x) or 0,
            y = tonumber(data.profileOffset.y) or 0,
            z = tonumber(data.profileOffset.z) or 0,
            yaw = tonumber(data.profileOffset.yaw) or 0,
        }
    end
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
    if data.manualOverride == true then
        calibrationMenuOverrideNotes[interactionType] = readableOverrideReason(data.manualOverrideReason)
    else
        calibrationMenuOverrideNotes[interactionType] = ""
    end
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
    if settings.sdpCalibrationHotkeyEnabled ~= true then
        debugLog("calibration hotkey ignored", "disabled")
        return
    end
    if calibrationMenu then
        closeCalibrationMenu(tostring(source or "hotkey") .. "_toggle")
        return
    end

    local now = core.getRealTime()
    if now - (lastCalibrationHotkeyHandledAt or -100) < CALIBRATION_HOTKEY_DUPLICATE_WINDOW then
        debugLog("calibration hotkey duplicate ignored", tostring(source or "trigger"))
        return
    end
    lastCalibrationHotkeyHandledAt = now

    if I and I.UI and I.UI.getMode then
        local okMode, mode = pcall(function() return I.UI.getMode() end)
        if okMode and mode ~= nil then
            debugLog("calibration hotkey ignored", "ui_mode", tostring(mode))
            return
        end
    end
    if openCalibrationMenu then openCalibrationMenu(tostring(source or "hotkey")) end
end

if input and input.registerTriggerHandler then
    pcall(function() input.registerTriggerHandler("SitDownPleaseOpenCalibrationMenu", async:callback(function() onCalibrationHotkey("trigger") end)) end)
end


local function playerCellLikelyHasInitialPlacement()
    settings = profiles.settings()
    if settings.disguiseInitialPlacement ~= true then return false end
    local cell = self.object and self.object.cell or nil
    if not (cell and cell.getAll) then return false end

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
    local okObjects, objects = pcall(function() return cell:getAll() end)
    if not okObjects or not objects then return false end
    for _, obj in ipairs(objects) do
        if obj and obj.position and profiles.objectLooksRelevantForInteraction(obj, "sleeping", settings) then
            return true
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

local function cellIsExterior(cell)
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


local function countInitialPlacementPendingActors()
    local count = 0
    for _ in pairs(initialPlacementPendingActorIds or {}) do count = count + 1 end
    return count
end

local function syncInitialPlacementPendingCount()
    local actorCount = countInitialPlacementPendingActors()
    if actorCount > 0 then
        initialPlacementLocalResultsPending = actorCount
    else
        initialPlacementLocalResultsPending = math.max(0, tonumber(initialPlacementLocalResultsPending or 0) or 0)
    end
    return initialPlacementLocalResultsPending
end

local function clearInitialPlacementPending(reason)
    initialPlacementAwaitingAssignmentScan = false
    initialPlacementLocalResultsPending = 0
    initialPlacementPendingActorIds = {}
    initialPlacementScanSource = nil
    initialPlacementOverlayFailSafeUntil = 0
    debugLog("initial placement overlay pending state cleared", tostring(reason or "clear"))
end

local function completeInitialPlacementActor(actorId, reason)
    if actorId == nil then return false end
    actorId = tostring(actorId)
    if actorId == "" then return false end
    local had = initialPlacementPendingActorIds and initialPlacementPendingActorIds[actorId] ~= nil
    if had then
        initialPlacementPendingActorIds[actorId] = nil
        initialPlacementLocalResultsPending = countInitialPlacementPendingActors()
        debugLog("initial placement overlay actor result received", actorId, tostring(reason or "result"), "pending", tostring(initialPlacementLocalResultsPending))
        return true
    end
    return false
end

local function releaseInitialPlacementOverlaySoon(reason, holdDuration)
    clearInitialPlacementPending(reason or "release")
    local now = core.getRealTime()
    if initialPlacementOverlay then
        local hold = tonumber(holdDuration or 0.08) or 0.08
        initialPlacementOverlayUntil = math.min(math.max(initialPlacementOverlayUntil or 0, now + 0.02), now + hold)
        debugLog("initial placement overlay release armed", tostring(reason or "release"), "hold", tostring(hold), "until", tostring(initialPlacementOverlayUntil - now))
    end
end

local function resetInitialPlacementDynamicState(reason, keepOverlay)
    local hadPending = initialPlacementAwaitingAssignmentScan == true or ((tonumber(initialPlacementLocalResultsPending) or 0) > 0) or countInitialPlacementPendingActors() > 0
    initialPlacementAwaitingAssignmentScan = false
    initialPlacementLocalResultsPending = 0
    initialPlacementPendingActorIds = {}
    initialPlacementScanSource = nil
    initialPlacementOverlayFailSafeUntil = 0
    initialPlacementLoadBridgeUntil = 0
    if hadPending then
        debugLog("initial placement overlay stale pending cleared", tostring(reason or "reset"))
    end
    if initialPlacementOverlay and keepOverlay ~= true then
        initialPlacementOverlayUntil = math.min(initialPlacementOverlayUntil or 0, core.getRealTime() + 0.08)
    end
end

local function overlayLayerEnv()
    return {
        ui = ui,
        util = util,
        debugLog = debugLog,
        mainLayer = INITIAL_PLACEMENT_OVERLAY_MAIN_LAYER,
        companionLayer = INITIAL_PLACEMENT_OVERLAY_COMPANION_LAYER,
        mainName = 'SitDownPleaseInitialPlacementOverlay',
        companionName = 'SitDownPleaseInitialPlacementOverlayTop',
        textName = 'SitDownPleaseInitialPlacementOverlayText',
        texturePath = 'textures/sitdownplease_black.png',
        showLoadingText = true,
        loadingText = 'Loading...',
    }
end
local function destroyInitialPlacementOverlay()
    local main = initialPlacementOverlay
    local top = initialPlacementOverlayTop
    local text = initialPlacementOverlayText
    overlayLayers.destroyPair(main, top, text)
    initialPlacementOverlay = nil
    initialPlacementOverlayTop = nil
    initialPlacementOverlayText = nil
    initialPlacementOverlayVisibleSensitive = false
    initialPlacementOverlayMinUntil = 0
    initialPlacementOverlayFailSafeUntil = 0
end

local function setOverlayAlpha(alpha)
    if not initialPlacementOverlay then return end
    overlayLayers.setAlpha(initialPlacementOverlay, initialPlacementOverlayTop, initialPlacementOverlayText, alpha)
end

local function updateInitialPlacementOverlayFade()
    if not initialPlacementOverlay then return end
    local now = core.getRealTime()
    local pendingCount = syncInitialPlacementPendingCount()
    local dynamicPending = initialPlacementAwaitingAssignmentScan == true or pendingCount > 0
    if dynamicPending then
        local failSafeUntil = tonumber(initialPlacementOverlayFailSafeUntil or 0) or 0
        if failSafeUntil <= 0 then
            debugLog("initial placement overlay dynamic stale release no failsafe", "awaitingScan", tostring(initialPlacementAwaitingAssignmentScan), "pending", tostring(pendingCount))
            releaseInitialPlacementOverlaySoon("stale_pending_no_failsafe", 0.10)
        elseif now >= failSafeUntil then
            debugLog("initial placement overlay dynamic failsafe release", "awaitingScan", tostring(initialPlacementAwaitingAssignmentScan), "pending", tostring(pendingCount))
            releaseInitialPlacementOverlaySoon("dynamic_failsafe", 0.12)
        else
            initialPlacementOverlayUntil = now + INITIAL_PLACEMENT_DYNAMIC_TICK_SECONDS
            setOverlayAlpha(1.0)
            debugLog("initial placement overlay dynamic hold pending events", "awaitingScan", tostring(initialPlacementAwaitingAssignmentScan), "pending", tostring(pendingCount), "failsafeRemaining", tostring(failSafeUntil - now))
            return
        end
    end
    local remaining = (initialPlacementOverlayUntil or 0) - now
    if remaining <= 0 then
        destroyInitialPlacementOverlay()
        return
    end
    local fade = tonumber(initialPlacementOverlayFadeSeconds or 0.35) or 0.35
    if fade > 0 and remaining < fade then
        setOverlayAlpha(remaining / fade)
    else
        setOverlayAlpha(1.0)
    end
end

local function maybeStartLoadCover(reason, transitionReason)
    if not onDisguiseInitialPlacement then return end
    settings = profiles.settings()
    if settings.disguiseInitialPlacement ~= true then return end
    local now = core.getRealTime()
    local existingCover = initialPlacementOverlay ~= nil

    local insideSleepWindow, timeKnown, currentHour, sleepWindowReason = currentSleepWindowState()
    local loadBridge = reason == "player_load_precover" or reason == "player_init_precover"
    local uncertainSleepWindow = timeKnown ~= true
    local sleepWindowAllowsCover = insideSleepWindow == true or uncertainSleepWindow == true

    -- If the clock is known and the user-configured sleep window says this is
    -- not sleep time, do not run speculative precover. Explicit sleep-placement
    -- events are still covered in onDisguiseInitialPlacement as a flash-safety net.
    if timeKnown == true and insideSleepWindow ~= true then
        debugLog("initial placement precover skipped", tostring(reason or "player_load_precover"), "likely", "false", "transition", tostring(transitionReason), "sleepWindow", tostring(sleepWindowReason), "hour", tostring(currentHour))
        return
    end

    if loadBridge and sleepWindowAllowsCover then
        local duration = 0.85
        local failSafeDuration = INITIAL_PLACEMENT_LOAD_BRIDGE_FAILSAFE_SECONDS
        local holdDuration = uncertainSleepWindow and 0.25 or 0.45
        initialPlacementAwaitingAssignmentScan = true
        initialPlacementOverlayFailSafeUntil = math.max(initialPlacementOverlayFailSafeUntil or 0, core.getRealTime() + failSafeDuration)
        initialPlacementLoadBridgeUntil = math.max(initialPlacementLoadBridgeUntil or 0, core.getRealTime() + failSafeDuration)
        onDisguiseInitialPlacement({
            interactionType = "scan",
            reason = reason or "player_load_precover",
            duration = duration,
            holdDuration = holdDuration,
            failSafeDuration = failSafeDuration,
            precover = true,
            early = true,
            bridge = true,
            visibilityReason = uncertainSleepWindow and "load_bridge_unknown_sleep_window" or "load_bridge_sleep_window",
        })
        debugLog("initial placement load bridge precover", tostring(reason or "player_load_precover"), "hour", tostring(currentHour), "sleepWindow", tostring(sleepWindowReason), "dynamic", "true", "duration", tostring(duration), "failsafe", tostring(failSafeDuration))
        return
    end

    local cellEntrySleepObjects = playerCellHasSleepRelevantObjects()
    if not cellEntrySleepObjects and existingCover then
        initialPlacementLoadBridgeUntil = math.max(initialPlacementLoadBridgeUntil or 0, now + 0.34)
        onDisguiseInitialPlacement({
            interactionType = "scan",
            reason = reason or "player_cell_entry_precover",
            duration = 0.34,
            holdDuration = 0.12,
            precover = true,
            early = true,
            bridge = true,
            visibilityReason = "existing_cover_no_candidates",
        })
        debugLog("initial placement overlay skipped no_candidates_existing_cover", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
        return
    end
    local currentCell = self.object and self.object.cell or nil
    local speculativeInteriorCover = not cellEntrySleepObjects
        and transitionReason == "load_or_teleport_cell_change"
        and currentCell ~= nil
        and cellIsExterior(currentCell) ~= true
        and sleepWindowAllowsCover == true
    if speculativeInteriorCover then
        local duration = 0.55
        local failSafeDuration = INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS
        initialPlacementAwaitingAssignmentScan = true
        initialPlacementOverlayFailSafeUntil = math.max(initialPlacementOverlayFailSafeUntil or 0, now + failSafeDuration)
        initialPlacementLoadBridgeUntil = math.max(initialPlacementLoadBridgeUntil or 0, now + failSafeDuration)
        onDisguiseInitialPlacement({
            interactionType = "scan",
            reason = reason or "player_cell_entry_precover",
            duration = duration,
            holdDuration = 0.18,
            failSafeDuration = failSafeDuration,
            precover = true,
            early = true,
            bridge = true,
            visibilityReason = "interior_sleep_window_scan_pending",
        })
        debugLog("initial placement overlay speculative interior precover", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false", "dynamic", "true", "duration", tostring(duration), "failsafe", tostring(failSafeDuration))
        return
    end
    if not cellEntrySleepObjects and reason == "player_teleported_precover" then
        debugLog("initial placement overlay skipped fast_transition_no_candidates", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
        return
    end
    if not cellEntrySleepObjects and transitionReason == "load_or_teleport_cell_change" then
        debugLog("initial placement overlay skipped no_sleep_objects", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
        return
    end
    local cellEntryCover = (reason == "player_cell_entry_precover" or reason == "player_teleported_precover")
        and transitionReason ~= "exterior_streaming"
        and sleepWindowAllowsCover
        and cellEntrySleepObjects
    if cellEntryCover then
        local teleportedPrecover = reason == "player_teleported_precover"
        local duration = teleportedPrecover and 0.54 or (uncertainSleepWindow and 0.26 or 0.42)
        local failSafeDuration = INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS
        local holdDuration = teleportedPrecover and 0.12 or (uncertainSleepWindow and 0.06 or 0.12)
        initialPlacementOverlayFailSafeUntil = math.max(initialPlacementOverlayFailSafeUntil or 0, core.getRealTime() + failSafeDuration)
        initialPlacementLoadBridgeUntil = math.max(initialPlacementLoadBridgeUntil or 0, core.getRealTime() + failSafeDuration)
        onDisguiseInitialPlacement({
            interactionType = "scan",
            reason = reason or "player_cell_entry_precover",
            duration = duration,
            holdDuration = holdDuration,
            failSafeDuration = failSafeDuration,
            precover = true,
            early = true,
            bridge = true,
            visibilityReason = "cell_entry_sleep_objects",
        })
        debugLog("initial placement cell-entry precover", tostring(reason or "player_cell_entry_precover"), "transition", tostring(transitionReason), "sleepObjects", tostring(cellEntrySleepObjects), "hour", tostring(currentHour), "sleepWindow", tostring(sleepWindowReason), "duration", tostring(duration))
        return
    end

    if insideSleepWindow == true and playerCellLikelyHasInitialPlacement() then
        onDisguiseInitialPlacement({
            interactionType = "scan",
            reason = reason or "player_load_precover",
            duration = 0.68,
            holdDuration = 0.22,
            precover = true,
            early = true,
        })
    else
        debugLog("initial placement precover skipped", tostring(reason or "player_load_precover"), "likely", "false", "transition", tostring(transitionReason), "sleepWindow", tostring(sleepWindowReason), "hour", tostring(currentHour))
    end
end

local function queueTeleportPrecover(reason)
    -- onTeleported can run inside engine delayed-action handling. Creating UI
    -- directly there caused "DelayedAction is not allowed to create another
    -- DelayedAction". Queue a single precover for the next player update tick.
    local now = core.getRealTime()
    if now - (lastTeleportPrecoverAt or -100) < 0.18 then return end
    pendingTeleportPrecover = true
    pendingTeleportPrecoverReason = reason or "player_teleported_precover"
    pendingTeleportPrecoverAt = now
    pendingTeleportPrecoverCell = self.object and self.object.cell or nil
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

    if currentCell and currentCell ~= lastObservedCell and lastObservedCell ~= nil then
        resetInitialPlacementDynamicState("cell_transition_new_context", true)
    end

    if pendingTeleportPrecover and currentCell then
        local queuedCell = pendingTeleportPrecoverCell
        pendingTeleportPrecover = false
        pendingTeleportPrecoverCell = nil
        lastTeleportPrecoverAt = core.getRealTime()
        if queuedCell ~= nil and queuedCell == currentCell then
            debugLog("initial placement precover skipped", tostring(pendingTeleportPrecoverReason or "player_teleported_precover"), "transition", "same_cell_teleport")
        elseif cellIsExterior(currentCell) and not playerCellHasSleepRelevantObjects() then
            debugLog("initial placement precover skipped", tostring(pendingTeleportPrecoverReason or "player_teleported_precover"), "transition", "teleport_to_exterior_no_sleep_objects")
        else
            maybeStartLoadCover(pendingTeleportPrecoverReason or "player_teleported_precover", "load_or_teleport_cell_change")
        end
    end

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
        local previousCell = lastObservedCell
        lastObservedCell = currentCell
        lastObservedCellExterior = currentExterior
        lastObservedPlayerPosition = currentPosition
        resetCalibrationTargetFilter("cell_change")
        if allowCover == true then
            maybeStartLoadCover("player_cell_entry_precover", transitionReason)
        else
            debugLog("initial placement precover skipped", tostring(transitionReason), "from", tostring(previousCell), "to", tostring(currentCell))
        end
        local okLikely, likelyPlacement = pcall(playerCellLikelyHasInitialPlacement)
        if okLikely and likelyPlacement == false then
            if initialPlacementAwaitingAssignmentScan == true then
                debugLog("initial placement overlay held awaiting assignment scan", "player_no_likely_initial_candidates")
            elseif core.getRealTime() >= (initialPlacementLoadBridgeUntil or 0) then
                onInitialPlacementSettled({ reason = "player_no_likely_initial_candidates" })
            else
                debugLog("initial placement settle deferred", "player_no_likely_initial_candidates", "bridgeUntil", tostring((initialPlacementLoadBridgeUntil or 0) - core.getRealTime()))
            end
        elseif not okLikely then
            debugLog("initial placement precover probe failed", tostring(likelyPlacement))
        end
    elseif currentPosition then
        lastObservedPlayerPosition = currentPosition
    end

    updateInitialPlacementOverlayFade()

    pollCalibrationMenuEscape()

    suppressSneakIsGoodNowForSleepingActors()

    stealthPollTimer = stealthPollTimer + dt
    if stealthPollTimer < 0.5 then return end
    stealthPollTimer = 0
    publishStealthState(false)
end

onDisguiseInitialPlacement = function(data)
    if settings.disguiseInitialPlacement ~= true then return end
    if data and data.interactionType == "sitting" then
        debugLog("initial placement overlay skipped", "sitting", tostring(data.reason or "initial_placement"), "visibility", "sitting_no_black_cover")
        return
    end
    if data and data.reason == "sleep_initial_placement" and not initialPlacementOverlay then
        if core.getRealTime() < (initialPlacementSuppressFreshPostCoverUntil or 0) then
            debugLog("initial placement overlay skipped post-settle fresh show", tostring(data.reason))
            return
        end
        debugLog("initial placement overlay skipped post-placement without active cover", tostring(data.reason))
        return
    end
    local visible = false
    local visibleReason = "not_checked"
    if data and data.precover == true then
        if data.bridge == true then
            visible, visibleReason = true, tostring(data.visibilityReason or "load_bridge")
        elseif data.early == true then
            visible, visibleReason = playerCellLikelyHasInitialPlacement(), "early_likely_initial_placement"
        else
            visible, visibleReason = playerCellLikelyHasVisibleInitialPlacement(), "precover_probe"
        end
    elseif data and data.reason == "initial_placement_pending" then
        -- This event is sent before the actual snap/animation start. If the global
        -- script has decided initial placement is happening, use it as an explicit
        -- cover trigger even if the camera visibility probe says the actor/object is
        -- offscreen during cell-load timing.
        visible, visibleReason = true, "initial_placement_pending"
    else
        visible, visibleReason = objectOrPositionVisible(data and data.actor or nil, data and data.targetPosition or nil, 2400)
        if not visible then
            visible, visibleReason = objectOrPositionVisible(data and data.object or nil, data and data.targetPosition or nil, 2400)
        end
    end
    if visible ~= true then
        debugLog("initial placement overlay skipped", tostring(data and data.interactionType), tostring(data and data.reason), "visibility", tostring(visibleReason))
        return
    end
    if initialPlacementOverlay and data then
        debugLog("initial placement overlay duplicate show suppressed", tostring(data.reason), "visibility", tostring(visibleReason))
        debugLog("initial placement overlay prevented show_settle_show", tostring(data.reason))
    end
    if data and (data.reason == "player_cell_entry_precover" or data.reason == "player_teleported_precover" or data.precover == true) then
        debugLog("initial placement overlay shown real_initial_candidates", tostring(data.reason), "visibility", tostring(visibleReason))
    end

    local duration = tonumber(data and data.duration or 0.65) or 0.65
    if duration <= 0 then return end
    local maxDuration = (data and data.bridge == true) and 1.2 or 2.4
    local clampedDuration = math.min(math.max(duration, 0.2), maxDuration)
    local untilTime = core.getRealTime() + clampedDuration
    if data and data.bridge == true then
        local failSafeDuration = tonumber(data.failSafeDuration or 0) or 0
        if failSafeDuration > 0 then
            initialPlacementOverlayFailSafeUntil = math.max(initialPlacementOverlayFailSafeUntil or 0, core.getRealTime() + failSafeDuration)
        end
        debugLog("initial placement overlay dynamic timing armed", tostring(data.reason), "displayTick", tostring(clampedDuration), "failsafe", tostring(failSafeDuration))
    end
    local holdDuration = tonumber(data and data.holdDuration or 0) or 0
    local minUntil = holdDuration > 0 and (core.getRealTime() + holdDuration) or untilTime
    initialPlacementOverlayVisibleSensitive = true
    initialPlacementOverlayMinUntil = math.max(initialPlacementOverlayMinUntil or 0, minUntil)
    debugLog("initial placement overlay visible state before cell render", "existing", tostring(initialPlacementOverlay ~= nil), "reason", tostring(data and data.reason), "visibility", tostring(visibleReason))

    if initialPlacementOverlay then
        initialPlacementOverlayUntil = math.max(initialPlacementOverlayUntil or 0, untilTime)
        if not initialPlacementOverlayTop then
            initialPlacementOverlayTop, initialPlacementOverlayText = overlayLayers.ensureCompanion(overlayLayerEnv(), initialPlacementOverlayTop, initialPlacementOverlayText)
            if initialPlacementOverlayTop then debugLog("initial placement overlay top companion restored", tostring(data and data.reason), "layer", INITIAL_PLACEMENT_OVERLAY_COMPANION_LAYER) end
        end
        setOverlayAlpha(1.0)
        debugLog("initial placement overlay reused existing cover", tostring(data and data.interactionType), tostring(data and data.reason), "duration", tostring(clampedDuration), "visibility", tostring(visibleReason), "layer", INITIAL_PLACEMENT_OVERLAY_MAIN_LAYER .. "+" .. INITIAL_PLACEMENT_OVERLAY_COMPANION_LAYER)
        if data and data.bridge == true then
            debugLog("initial placement overlay continuous load bridge", tostring(data.reason), "until", tostring(initialPlacementOverlayUntil - core.getRealTime()))
        end
        return
    end

    initialPlacementOverlayUntil = untilTime
    initialPlacementOverlay, initialPlacementOverlayTop, initialPlacementOverlayText = overlayLayers.createPair(overlayLayerEnv())
    if not initialPlacementOverlay and not initialPlacementOverlayTop then
        initialPlacementOverlayUntil = 0
        debugLog("initial placement overlay failed", "all_layers")
        return
    end
    -- Use the Notification-layer cover as the state sentinel when available; fall back to the companion layer.
    if not initialPlacementOverlay then initialPlacementOverlay = initialPlacementOverlayTop end
    debugLog("initial placement overlay", tostring(data and data.interactionType), tostring(data and data.reason), "duration", tostring(clampedDuration), "visibility", tostring(visibleReason), "layer", INITIAL_PLACEMENT_OVERLAY_MAIN_LAYER .. "+" .. INITIAL_PLACEMENT_OVERLAY_COMPANION_LAYER)
end

onInitialPlacementSettled = function(data)
    local reason = tostring(data and data.reason or "settled")
    local actorId = data and (data.actorId or data.npcId)
    if actorId then
        completeInitialPlacementActor(actorId, reason)
    end

    if reason == "initial_handoff_timeout" or reason == "pending_local_invalid" or reason == "pending_local_released" then
        releaseInitialPlacementOverlaySoon(reason, tonumber(data and data.holdDuration or 0.10) or 0.10)
        return
    end

    if initialPlacementAwaitingAssignmentScan == true then
        debugLog("initial placement overlay not settled pending local results", reason, "pending", tostring(syncInitialPlacementPendingCount()), "scan", "awaiting")
        return
    end

    local pendingCount = syncInitialPlacementPendingCount()
    if actorId == nil and (reason == "sleep_initial_placement_done" or reason == "initial_placement_rejected" or reason == "sleep_initial_placement_rejected" or reason == "sleep_initial_placement_failed" or reason == "dead_actor") then
        if pendingCount > 0 then
            debugLog("initial placement overlay aggregate settle ignored pending actor results", reason, "pending", tostring(pendingCount))
            return
        end
    end

    if pendingCount > 0 then
        debugLog("initial placement overlay not settled pending local results", reason, "pending", tostring(pendingCount))
        return
    end

    if initialPlacementOverlay then
        local holdDuration = tonumber(data and data.holdDuration or 0) or 0
        if reason == "sleep_initial_placement_done" then
            local source = tostring(initialPlacementScanSource or "")
            local postPoseHold = (source == "initial_load") and INITIAL_PLACEMENT_INITIAL_LOAD_POST_POSE_HOLD_SECONDS or INITIAL_PLACEMENT_CELL_POST_POSE_HOLD_SECONDS
            if holdDuration < postPoseHold then holdDuration = postPoseHold end
            debugLog("initial placement overlay post animation settle hold", "source", tostring(source), "hold", tostring(holdDuration))
        end
        local settleUntil = core.getRealTime() + (holdDuration > 0 and holdDuration or 0.08)
        if initialPlacementOverlayVisibleSensitive then
            settleUntil = math.max(settleUntil, initialPlacementOverlayMinUntil or 0)
        end
        initialPlacementAwaitingAssignmentScan = false
        initialPlacementOverlayUntil = settleUntil
        initialPlacementOverlayFailSafeUntil = 0
        initialPlacementSuppressFreshPostCoverUntil = core.getRealTime() + math.max(0.9, holdDuration + 0.3)
        debugLog("initial placement overlay final settle after all initial candidates resolved", reason, "hold", tostring(holdDuration), "until", tostring(initialPlacementOverlayUntil - core.getRealTime()), "dynamicRelease", "true")
    else
        clearInitialPlacementPending("settled_without_overlay")
    end
end

local function onInitialAssignmentScanComplete(data)
    initialPlacementAwaitingAssignmentScan = false
    initialPlacementScanSource = data and data.source or nil
    initialPlacementPendingActorIds = {}
    local actorIds = data and data.initialSleepActorIds or nil
    local actorIdCount = 0
    if type(actorIds) == "table" then
        for _, actorId in ipairs(actorIds) do
            if actorId ~= nil then
                initialPlacementPendingActorIds[tostring(actorId)] = true
                actorIdCount = actorIdCount + 1
            end
        end
    end
    if actorIdCount > 0 then
        initialPlacementLocalResultsPending = actorIdCount
    else
        initialPlacementLocalResultsPending = tonumber(data and data.initialSleepSentConsider or 0) or 0
    end
    debugLog("initial placement overlay scan complete", "pending", tostring(initialPlacementLocalResultsPending), "actorIds", tostring(actorIdCount), "source", tostring(data and data.source))
    if initialPlacementLocalResultsPending <= 0 then
        debugLog("initial placement overlay released after scan no candidates")
        onInitialPlacementSettled({ reason = "released_after_scan_no_candidates", holdDuration = 0.08 })
    elseif initialPlacementOverlay then
        debugLog("initial placement overlay continuous load bridge", "assignment_scan_candidates", "sent", tostring(initialPlacementLocalResultsPending))
        debugLog("initial placement overlay not settled pending local results", "assignment_scan_candidates", "pending", tostring(initialPlacementLocalResultsPending))
    end
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
    if not data then return end
    local actor = data.actor
    local actorId = data.actorId or (actor and actor.id)
    if not actorId then return end

    if data.sleeping == true then
        sleepingActors[actorId] = { actor = actor, recordId = data.recordId, reason = data.reason }
        suppressSneakIsGoodNowForSleepingActors()
        debugLog("sleeping actor registered for sneak compatibility", tostring(data.recordId or actorId), tostring(data.reason))
    else
        sleepingActors[actorId] = nil
        clearSneakIsGoodNowStatus(actorId, data.reason or "sleeping_actor_cleared")
        debugLog("sleeping actor cleared for sneak compatibility", tostring(data.recordId or actorId), tostring(data.reason))
    end
end

local interface = {
    version = 1,
    sleepingActors = sleepingActors,
    isActorSleeping = function(actor)
        return actor and actor.id and sleepingActors[actor.id] ~= nil or false
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
    },
    interfaceName = profiles.MOD_ID,
    interface = interface,
}
