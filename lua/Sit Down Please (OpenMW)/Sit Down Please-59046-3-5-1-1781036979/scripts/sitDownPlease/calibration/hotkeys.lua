---@omw-context none
local M = {}

local function exactModifierDown(input, keyName)
    local keyCode = input and input.KEY and input.KEY[keyName] or nil
    if keyCode == nil or not (input and input.isKeyPressed) then return false end
    local ok, value = pcall(input.isKeyPressed, keyCode)
    return ok and value == true
end

local function genericModifierDown(input, fnName)
    local fn = input and input[fnName] or nil
    if not fn then return false end
    local ok, value = pcall(fn)
    return ok and value == true
end

local function rightModifierDown(input, rightKey, leftKey, genericFn)
    if exactModifierDown(input, rightKey) then return true end
    return genericModifierDown(input, genericFn) and not exactModifierDown(input, leftKey)
end

local function uiModeActive(I)
    if not (I and I.UI and I.UI.getMode) then return false, nil end
    local ok, mode = pcall(function() return I.UI.getMode() end)
    return ok and mode ~= nil, mode
end

function M.handle(env)
    env = env or {}
    local settings = env.settings or {}
    local debugLog = env.debugLog or function(...) end
    local source = tostring(env.source or "hotkey")

    if settings.sdpCalibrationHotkeyEnabled ~= true then
        debugLog("calibration hotkey ignored", "disabled")
        return env.lastHandledAt
    end

    local leftShift = env.leftShiftDown and env.leftShiftDown() == true
    local leftAlt = env.leftAltDown and env.leftAltDown() == true
    local rightShift = rightModifierDown(env.input, "RightShift", "LeftShift", "isShiftPressed")
    local rightAlt = rightModifierDown(env.input, "RightAlt", "LeftAlt", "isAltPressed")
    local modifierAction = leftAlt == true or rightAlt == true or rightShift == true

    if env.menuOpen == true and not modifierAction then
        if env.closeMenu then env.closeMenu(source .. "_toggle") end
        return env.lastHandledAt
    end

    local now = env.core and env.core.getRealTime and env.core.getRealTime() or nil
    if now and now - (env.lastHandledAt or -100) < (env.duplicateWindow or 0) then
        debugLog("calibration hotkey duplicate ignored", source)
        return env.lastHandledAt
    end
    local handledAt = now or env.lastHandledAt

    if env.menuOpen ~= true then
        local active, mode = uiModeActive(env.I)
        if active then
            debugLog("calibration hotkey ignored", "ui_mode", tostring(mode))
            return handledAt
        end
    end

    if rightAlt == true and rightShift == true then
        if env.sendAction then env.sendAction("spawn_test", { hotkeySpawnTest = true }) end
        debugLog("calibration hotkey spawn test requested", source)
        return handledAt
    end
    if rightAlt == true then
        if env.sendAction then env.sendAction("fill_furniture", { hotkeyFillCell = true }) end
        debugLog("calibration hotkey fill cell requested", source)
        return handledAt
    end
    if rightShift == true then
        if env.sendAction then env.sendAction("assign_nearest", { hotkeyAssignNearest = true }) end
        debugLog("calibration hotkey assign nearest requested", source)
        return handledAt
    end
    if leftAlt == true then
        if env.sendAction then env.sendAction("print", { hotkeyVisualApproval = true, visualApproval = true, captureLookTarget = true }) end
        debugLog("calibration hotkey visual approval requested", source, "shift", tostring(leftShift == true))
        return handledAt
    end

    if env.openMenu then env.openMenu(source) end
    return handledAt
end

return M
