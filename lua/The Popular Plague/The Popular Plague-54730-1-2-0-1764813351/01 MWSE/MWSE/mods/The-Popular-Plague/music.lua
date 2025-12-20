---@parma cell tes3cell?
local function isEidolonCell(cell)
    return (cell ~= nil) and (cell.id:find("Eidolon") ~= nil)
end

--- When first entering an Eidolon, trigger our custom music.
---
---@param e cellChangedEventData
local function onCellChanged(e)
    local isEidolon = isEidolonCell(e.cell)
    local wasEidolon = isEidolonCell(e.previousCell)
    if isEidolon and not wasEidolon then
        tes3.streamMusic({
            path = "md24/The Golden Tower.mp3",
            situation = tes3.musicSituation.explore,
        })
    elseif wasEidolon and not isEidolon then
        ---@diagnostic disable-next-line: missing-fields
        tes3.skipToNextMusicTrack({ force = true })
    end
end
event.register("cellChanged", onCellChanged, { priority = 720 })


--- Override new music track selections while in an Eidolon cell.
---
--- @param e musicSelectTrackEventData
local function onMusicSelectTrack(e)
    if e.situation == tes3.musicSituation.combat then
        return -- allow combat music to play as normal
    end
    local cell = tes3.getPlayerCell()
    if isEidolonCell(cell) then
        e.music = "md24/The Golden Tower.mp3"
        e.situation = tes3.musicSituation.explore
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 720 })
