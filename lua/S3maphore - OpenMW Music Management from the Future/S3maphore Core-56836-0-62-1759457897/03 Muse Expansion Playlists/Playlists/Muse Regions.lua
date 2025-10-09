---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local AshlandsRegions = {
    ['ashlands region'] = true,
    ['molag amur region'] = true,
    ['molag mar region'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/region/ashlands pack',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.rules.region(AshlandsRegions)
        end,
    },
    {
        id = 'ms/region/ascadian isles region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'ascadian isles region'
        end,
    },
    {
        id = 'ms/region/azura\'s coast region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'azura\'s coast region'
        end,
    },
    {
        id = 'ms/region/bitter coast region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'bitter coast region'
        end,
    },
    {
        id = 'ms/region/grazelands region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'grazelands region'
        end,
    },
    {
        id = 'ms/region/red mountain region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'red mountain region'
        end,
    },
    {
        id = 'ms/region/sheogorad region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'sheogorad'
        end,
    },
    {
        id = 'ms/region/west gash region',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'west gash region'
        end,
    }
}
