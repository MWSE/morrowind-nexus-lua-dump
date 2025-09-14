---@type IDPresenceMap
local AshlandsRegions = {
    ['ashlands region'] = true,
    ['molag amur region'] = true,
    ['molag mar region'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    -- Ashlands Pack 
    {
        id = 'cell/ashlands',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.rules.region(AshlandsRegions)
        end,
    },

    -- All other regions use MUSE Regions folders
    {
        id = 'cell/ascadianisles',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'ascadian isles region'
        end,
    },
    {
        id = 'cell/azurascoast',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == "azura's coast region"
        end,
    },
    {
        id = 'cell/bittercoast',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'bitter coast region'
        end,
    },
    {
        id = 'cell/grazelands',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'grazelands region'
        end,
    },
    {
        id = 'cell/redmountain',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'red mountain region'
        end,
    },
    {
        id = 'cell/sheogorad',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'sheogorad region'
        end,
    },
    {
        id = 'cell/westgash',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'west gash region'
        end,
    },
    {
        id = 'cell/solstheim',
        priority = PlaylistPriority.Region,
        randomize = true,
        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.state.cellIsExterior
                and playback.state.self.cell.region == 'island of solstheim region'
        end,
    },
}
