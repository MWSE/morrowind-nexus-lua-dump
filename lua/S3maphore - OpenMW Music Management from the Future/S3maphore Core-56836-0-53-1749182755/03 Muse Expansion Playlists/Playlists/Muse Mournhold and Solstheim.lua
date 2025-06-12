---@type CellMatchPatterns
local MournholdMatches = {
    allowed = {
        'mournhold',
    },

    disallowed = {
        'old mournhold',
    }
}

---@type IDPresenceMap
local SolstheimRegions = {
    ['solstheim, hirstaang forest'] = true,
    ['solstheim, brodir grove region'] = true,
    ['solstheim, thirsk'] = true,
    ['solstheim, isinfier plains'] = true,
    ['solstheim, moesring mountains'] = true,
    ['solstheim, felsaad coast region'] = true,
    ['solstheim, lake fjalding'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/mournhold',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        --- For *actual* mournhold by Bethesda, you will never be in a true exterior, but a quasi-exterior
        --- However the PlaybackState indicates true for real and fake exteriors
        isValidCallback = function(playback)
            return not playback.state.self.cell.isExterior
                and playback.rules.cellNameMatch(MournholdMatches)
        end,
    },
    {
        id = 'ms/cell/solstheim pack',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.rules.region(SolstheimRegions)
        end,
    }
}
