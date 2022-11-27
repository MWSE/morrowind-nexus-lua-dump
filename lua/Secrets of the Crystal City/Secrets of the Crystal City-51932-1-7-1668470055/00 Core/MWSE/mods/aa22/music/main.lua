-- file paths are relative to 'Data Files\\Music\\'

local SILENCE = "aa22\\special\\silence.mp3"

local TRACKS = {
    "aa22\\tew_aa_3.mp3",
}


local function isMassamaCell(cell)
    return (cell and cell.name or ""):startswith("Massama,")
end


local function onCellChanged(e)
    local isMassama = isMassamaCell(e.cell)
    local wasMassama = isMassamaCell(e.previousCell)

    if isMassama and not wasMassama then
        tes3.streamMusic({path = table.choice(TRACKS)})
    elseif wasMassama and not isMassama then
        tes3.streamMusic({path = SILENCE})
    end
end
event.register("cellChanged", onCellChanged)


local function onMusicSelectTrack(e)
    if isMassamaCell(tes3.player.cell) then
        e.music = table.choice(TRACKS)
        return false
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 360 })

event.register("initialized", function()
    mwse.overrideScript("aa22_MassamaMusic_s", function() 
    end)
end)
