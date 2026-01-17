local tracks = {
    ["Sea of Ghosts, Icy Cave"] = "mdww\\explore\\Whispers of the Lost.mp3",
    ["Sea of Ghosts, The White Wave"] = "mdww\\explore\\The White Wave.mp3",
    ["White Wave, Cabin"] = "mdww\\explore\\Sunken Dreams.mp3",
    ["White Wave, Hold"] = "mdww\\explore\\Sunken Dreams.mp3"
}


---@parma cell tes3cell?
local function isCustomMusicCell(cell)
    return (cell ~= nil) and (tracks[cell.id] ~= nil)
end


---@param e cellChangedEventData
local function onCellChanged(e)
    local isCustom = isCustomMusicCell(e.cell)
    local wasCustom = isCustomMusicCell(e.previousCell)
    if isCustom and not wasCustom then
        -- tes3.messageBox("CellChanged to custom music cell: %s", tracks[e.cell.id])
        tes3.streamMusic({ path = tracks[e.cell.id],  situation = tes3.musicSituation.explore })
    elseif wasCustom and not isCustom then
        -- tes3.messageBox("CellChanged from custom music cell, ending music...")
        tes3.skipToNextMusicTrack({ force = true })
    end
end
event.register("cellChanged", onCellChanged, { priority = 720 })


--- @param e musicSelectTrackEventData
local function onMusicSelectTrack(e)
    local cell = tes3.getPlayerCell()
    local track = tracks[cell.id]
    if track then
        if e.situation == tes3.musicSituation.combat then
            e.music = "mdww\\combat\\Ice Wraiths.mp3"
        else
            e.music = tracks[cell.id]
            e.situation = tes3.musicSituation.explore
        end
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 720 })