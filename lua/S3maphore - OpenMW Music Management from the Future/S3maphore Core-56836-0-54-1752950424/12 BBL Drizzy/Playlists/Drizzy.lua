---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local DrizzyCells = {
    allowed = {
        'dagoth',
    },

    disallowed = {},
}

---@type S3maphorePlaylist[]
return {
    {
        id = "s3/drizzy",
        --- Override the Sixth House playlist
        priority = PlaylistPriority.Faction - 1,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.rules.cellNameMatch(DrizzyCells)
        end,
    },
}
