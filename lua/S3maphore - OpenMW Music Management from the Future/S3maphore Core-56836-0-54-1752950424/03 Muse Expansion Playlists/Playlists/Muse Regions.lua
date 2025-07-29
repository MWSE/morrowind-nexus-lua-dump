---@type IDPresenceMap
local AshlandsRegions = {
    ['ashlands region'] = true,
    ['molag amur region'] = true,
    ['molag mar region'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/region/ashlands pack',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.rules.region(AshlandsRegions)
        end,
    },
    {
        id = 'ms/region/ascadian isles region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'ascadian isles region'
        end,
    },
    {
        id = 'ms/region/azura\'s coast region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'azura\'s coast region'
        end,
    },
    {
        id = 'ms/region/bitter coast region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'bitter coast region'
        end,
    },
    {
        id = 'ms/region/grazelands region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'grazelands region'
        end,
    },
    {
        id = 'ms/region/red mountain region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'red mountain region'
        end,
    },
    {
        id = 'ms/region/sheogorad region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'sheogorad'
        end,
    },
    {
        id = 'ms/region/west gash region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'west gash region'
        end,
    }
}
