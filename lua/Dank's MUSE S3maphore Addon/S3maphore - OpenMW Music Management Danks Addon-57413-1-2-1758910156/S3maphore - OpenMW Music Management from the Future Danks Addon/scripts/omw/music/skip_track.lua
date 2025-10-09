
-- skip_track.lua
-- Press F8 to skip the currently playing music track.

local Input = require('openmw.input')
local Core  = require('openmw.core')
local UI    = require('openmw.ui')
local Async = require('openmw.async')

-- Key used to skip tracks
local SKIP_KEY = Input.KEY.F8

-- Function to request next track
local function requestNextTrack()
    -- Show a little confirmation on screen
    UI.showMessage('Skipping track...')

    -- Fire events that most MUSE/S3maphore playlists listen for
    Core.sendGlobalEvent('muse_forceNextTrack')
    Core.sendGlobalEvent('s3m_nextTrack')
    Core.sendGlobalEvent('s3m_stopTrack')

    -- Fallback: stop then advance on the next frame
    Async.runUnsafely(function()
        Async.sleep(0.05)
        Core.sendGlobalEvent('muse_forceNextTrack')
    end)
end

-- Listen for key presses
local function onKeyPress(e)
    if e.code == SKIP_KEY then
        requestNextTrack()
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
    },
}
