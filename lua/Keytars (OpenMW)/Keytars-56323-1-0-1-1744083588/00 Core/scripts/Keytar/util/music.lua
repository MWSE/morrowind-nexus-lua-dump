local bpm = 147
local animFps = 24
local animFramesPerBeat = 10
local animBpm = animFps * 60 / animFramesPerBeat
local bpmConstant = bpm / animBpm

local songBeatLength = 1 / (bpm / 60) -- in seconds
local songBeatCount = 480
local songLength = songBeatLength * songBeatCount -- in seconds

local M = {}

function M.getBpmConstant()
    return bpmConstant
end

function M.getSongLength()
    return songLength
end

function M.getAnimStartPoint(timeOffset)
    if timeOffset == -1 then
        return 0
    end
    local songTime = timeOffset % (songBeatLength * 16) -- in seconds
    local animTime = songTime / (songBeatLength * 16) -- from 0 to 1
    return animTime
end

return M