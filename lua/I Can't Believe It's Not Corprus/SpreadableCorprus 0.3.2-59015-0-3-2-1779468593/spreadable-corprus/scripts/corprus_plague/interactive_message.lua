-- Player-script helper: queue I.UI.showInteractiveMessage until the UI is safe.
-- Calling it while the developer console is open can crash OpenMW (console is not a UI mode).
local I = require('openmw.interfaces')

local M = {}

local pendingMessage = nil
local deferTryFrames = 0
local frame = 0

-- If the console was toggled within this many frames, wait for the next toggle (close) before showing.
local CONSOLE_RECENT_FRAMES = 180
local CONSOLE_DEFER_FRAMES = 4
local DEFAULT_DEFER_FRAMES = 3

local lastConsoleKeyFrame = -CONSOLE_RECENT_FRAMES
local fallbackTryFrame = nil
local CONSOLE_FALLBACK_FRAMES = 120

local CONSOLE_KEY_SYMBOLS = {
    ['`'] = true,
    ['~'] = true,
}

local function isUiModeBlocking()
    local ok, mode = pcall(I.UI.getMode)
    if not ok then
        return true
    end
    return mode ~= nil
end

local function canShowInteractiveMessage()
    if not pendingMessage then
        return false
    end
    if isUiModeBlocking() then
        return false
    end
    return true
end

function M.isConsoleKey(key)
    return key ~= nil and CONSOLE_KEY_SYMBOLS[key.symbol] == true
end

function M.onConsoleKeyPressed()
    lastConsoleKeyFrame = frame
    fallbackTryFrame = nil
    if pendingMessage then
        -- Console just toggled; try after it finishes opening/closing (typically on close).
        deferTryFrames = CONSOLE_DEFER_FRAMES
    end
end

function M.schedule(message)
    if not message or message == '' then
        return
    end
    pendingMessage = message

    if frame - lastConsoleKeyFrame < CONSOLE_RECENT_FRAMES then
        -- Console was used recently; show after the next toggle (close) or a short fallback if already closed.
        fallbackTryFrame = frame + CONSOLE_FALLBACK_FRAMES
        return
    end

    fallbackTryFrame = nil
    deferTryFrames = DEFAULT_DEFER_FRAMES
end

function M.tryShow()
    if not canShowInteractiveMessage() then
        return false
    end

    local message = pendingMessage
    pendingMessage = nil

    local ok = pcall(I.UI.showInteractiveMessage, message)
    if not ok then
        pendingMessage = message
        return false
    end
    return true
end

function M.onFrame()
    frame = frame + 1

    if deferTryFrames > 0 then
        deferTryFrames = deferTryFrames - 1
        if deferTryFrames == 0 then
            M.tryShow()
        end
        return
    end

    if pendingMessage and fallbackTryFrame and frame >= fallbackTryFrame then
        fallbackTryFrame = nil
        M.tryShow()
    end
end

function M.onUiModeChanged(newMode)
    if newMode == nil and pendingMessage and deferTryFrames <= 0 then
        deferTryFrames = DEFAULT_DEFER_FRAMES
    end
end

return M
