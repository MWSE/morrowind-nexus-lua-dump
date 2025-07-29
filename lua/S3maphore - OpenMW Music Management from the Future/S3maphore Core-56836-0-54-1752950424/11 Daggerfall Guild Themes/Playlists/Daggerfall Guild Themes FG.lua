---@type CellMatchPatterns
local fgMatches = {
    allowed = {
        'guild of fighters',
        'fighter\'s guild',
    },

    disallowed = {},
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type ValidPlaylistCallback
local function fgOrCellRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and (
            (
                playback.rules.cellNameMatch(fgMatches)
            )
        )
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'Daggerfall Guild Themes FG',

        tracks = {
            'Music/em_dynamicMusic/fighter_1.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = fgOrCellRule,
    },
}
