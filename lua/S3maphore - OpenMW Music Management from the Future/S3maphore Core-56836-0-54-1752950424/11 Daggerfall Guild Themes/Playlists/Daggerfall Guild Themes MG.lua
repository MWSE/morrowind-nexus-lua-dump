---@type CellMatchPatterns
local mgMatches = {
    allowed = {
        'guild of mages',
        'mage\'s guild',
    },

    disallowed = {},
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type ValidPlaylistCallback
local function mgOrCellRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and (
            (
                playback.rules.cellNameMatch(mgMatches)
            )
        )
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'Daggerfall Guild Themes MG',

        tracks = {
            'Music/em_dynamicMusic/mage_2.mp3',
            'Music/em_dynamicMusic/mage_3.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = mgOrCellRule,
    },
}
