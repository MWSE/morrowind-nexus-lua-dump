local PlaylistPriority = require 'doc.playlistPriority'

---@type CellMatchPatterns
local VivecMatches = {
    allowed = {
        'vivec',
    },

    disallowed = {
        'sewers',
        'underworks',
    },
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/vivec',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.rules.cellNameMatch(VivecMatches)
        end,
    }
}
