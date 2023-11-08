local utils = require("telamur.utils")
local MUSICDIR = "Data Files\\Music\\telamur\\"
local SILENCE = "telamur\\Special\\silence.mp3"
local previousCell

--- @type function
local isTelAmurCell = utils.cells.isTelAmurCell

--- @type string[]
local whitelistedTracks = {}

--- @param e musicSelectTrackEventData
local function prioritiseTelAmurMusic(e)
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    if isTelAmur then
        e.music = table.choice(whitelistedTracks)
        e.situation = tes3.musicSituation.uninterruptible
        previousCell = cell
        return false
    end
end

local function onCombatStopped()
    if tes3.player.mobile.inCombat then return end -- Because MW can be really dumb with that one
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    if isTelAmur then
        tes3.streamMusic{path = table.choice(whitelistedTracks), situation = tes3.musicSituation.uninterruptible}
        previousCell = cell
    end
end

local function telAmurConditionCheck()
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    local wasTelAmur = previousCell and isTelAmurCell(previousCell)

    if isTelAmur and not wasTelAmur then
        tes3.streamMusic{path = table.choice(whitelistedTracks), situation = tes3.musicSituation.uninterruptible}
    elseif wasTelAmur and not isTelAmur then
        tes3.streamMusic{path = SILENCE, situation = tes3.musicSituation.explore}
    end
    previousCell = cell
end

local function populateTracks()
    for track in lfs.dir(MUSICDIR) do
		if (track ~= ".." and track ~= "." and track ~= "Special") and (string.endswith(track, ".mp3")) then
            table.insert(whitelistedTracks, #whitelistedTracks+1, "telamur\\" .. track)
        end
    end
    assert(whitelistedTracks, "Missing music files!")
end

local function resetOnLoad()
    previousCell = nil
end

populateTracks()
event.register(tes3.event.musicSelectTrack, prioritiseTelAmurMusic, { priority = 360 })
event.register(tes3.event.cellChanged, telAmurConditionCheck)
event.register(tes3.event.load, resetOnLoad)
event.register(tes3.event.combatStopped, onCombatStopped)
