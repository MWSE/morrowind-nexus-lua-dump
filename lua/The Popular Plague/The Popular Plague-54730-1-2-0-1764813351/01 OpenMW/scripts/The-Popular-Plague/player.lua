local self = require("openmw.self")
local core = require("openmw.core")
local ambient = require("openmw.ambient")

local MUSIC_TRACK_LENGTH = 120

local previousCell = nil
local musicStarted = false
local musicEndTime = 0

local function startMusic()
    ambient.streamMusic("music\\md24\\the golden tower.mp3")
    musicStarted = true
    musicEndTime = core.getRealTime() + MUSIC_TRACK_LENGTH
end

local function stopMusic()
    ambient.stopMusic()
    musicStarted = false
    musicEndTime = core.getRealTime()
end

local function isEidolonCell(cell)
    return (cell ~= nil) and (cell.name:find("Eidolon") ~= nil)
end

local function onCellChanged()
    local isEidolon = isEidolonCell(self.cell)
    local wasEidolon = isEidolonCell(previousCell)
    if isEidolon and not wasEidolon then
        startMusic()
    elseif wasEidolon and not isEidolon then
        stopMusic()
    end
end

return {
    engineHandlers = {
        onFrame = function(dt)
            if self.cell ~= previousCell then
                onCellChanged()
                previousCell = self.cell
            end
            if musicStarted and (core.getRealTime() > musicEndTime) then
                startMusic()
            end
        end,
    },
}
