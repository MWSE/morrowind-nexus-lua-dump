local OuterRimCells = {
    ['the outer rim'] = true,
    ['the outer rim, freighter'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'Rickoff/The Outer Rim',
        priority = 490,
        randomize = true,
        isValidCallback = function(playback)
            return playback.rules.cellNameExact(OuterRimCells)
        end,
    },
    {
        id = 'Rickoff/Club Arkngthand',
        priority = 489,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.self.cell.id == 'nar shaddaa, club arkngthand'
        end,
    }
}
