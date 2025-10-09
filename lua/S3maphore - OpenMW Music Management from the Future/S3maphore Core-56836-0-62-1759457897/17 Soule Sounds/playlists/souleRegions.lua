---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local AzurasCoastRegions = {
    ['azura\'s coast region'] = true,
    ['sheogorad region'] = true,
    ['sheogorad'] = true,
}

---@type ValidPlaylistCallback
local function azurasCoastRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(AzurasCoastRegions)
end

---@type ValidPlaylistCallback
local function azurasCoastNightRegionRule()
    return azurasCoastRegionRule()
        and not Playback.rules.timeOfDay(6, 20)
end

---@type IDPresenceMap
local MoesringRegions = {
    ['solstheim, moesring mountains'] = true,
    ['moesring mountains region'] = true,
}

---@type ValidPlaylistCallback
local function moesringRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(MoesringRegions)
end

---@type ValidPlaylistCallback
local function moesringNightRegionRule()
    return moesringRegionRule()
        and not Playback.rules.timeOfDay(6, 20)
end

---@type IDPresenceMap
local AshlandsRegions = {
    ['ashlands region'] = true,
    ['molag amur region'] = true,
    ['molag mar region'] = true,
}

---@type ValidPlaylistCallback
local function ashlandsRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(AshlandsRegions)
end

---@type IDPresenceMap
local AscadianislesRegions = {
    ['ascadian isles region'] = true,
    ['bitter coast region'] = true,
}

---@type ValidPlaylistCallback
local function ascadianIslesRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(AscadianislesRegions)
end

---@type ValidPlaylistCallback
local function ascadianislesNightRegionRule()
    return ascadianIslesRegionRule()
        and not Playback.rules.timeOfDay(7, 20)
end

---@type IDPresenceMap
local MournholdRegions = {
    ['mournhold region'] = true,
}

---@type ValidPlaylistCallback
local function mournholdRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(MournholdRegions)
end

---@type IDPresenceMap
local redMountainRegions = {
    ['red mountain region'] = true,
    ['firemoth region'] = true,
}

---@type ValidPlaylistCallback
local function redMountainRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(redMountainRegions)
end

---@type ValidPlaylistCallback
local function redMountainNightRegionRule()
    return redMountainRegionRule()
        and not Playback.rules.timeOfDay(7, 20)
end

---@type IDPresenceMap
local SolstheimRegions = {
    ['brodir grove region'] = true,
    ['felsaad coast region'] = true,
    ['hirstaang forest region'] = true,
    ['isinfier plains region'] = true,
    ['solstheim, brodir grove region'] = true,
    ['solstheim, felsaad coast region'] = true,
    ['solstheim, hirstaang forest'] = true,
    ['solstheim, isinfier plains'] = true,
    ['thirsk region'] = true,
}

---@type ValidPlaylistCallback
local function solstheimRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(SolstheimRegions)
end

---@type ValidPlaylistCallback
local function solstheimNightRegionRule()
    return solstheimRegionRule()
        and not Playback.rules.timeOfDay(7, 20)
end

---@type IDPresenceMap
local WestgashRegions = {
    ['west gash region'] = true,
    ['grazelands region'] = true,
}

---@type ValidPlaylistCallback
local function westGashRegionRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(WestgashRegions)
end

---@type ValidPlaylistCallback
local function westGashNightRegionRule()
    return westGashRegionRule()
        and not Playback.rules.timeOfDay(7, 20)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/region/azura\'s coast',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = azurasCoastRegionRule,
    },
    {
        id = 'ms/region/azura\'s coast/night',

        exclusions = {
            playlists = {
                'ms/region/azura\'s coast/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = azurasCoastNightRegionRule,
    },
    {
        id = 'ms/region/moesring mountains',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = moesringRegionRule,
    },
    {
        id = 'ms/region/moesring mountains/night',

        exclusions = {
            playlists = {
                'ms/region/moesring mountains/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = moesringNightRegionRule,
    },
    {
        id = 'ms/region/ashlands',

        exclusions = {
            playlists = {
                'ms/region/ashlands/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = ashlandsRegionRule,
    },
    {
        id = 'ms/region/ashlands/night',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = ashlandsRegionRule,
    },
    {
        id = 'ms/region/ascadian isles',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = ascadianIslesRegionRule,
    },
    {
        id = 'ms/region/ascadian isles/night',

        exclusions = {
            playlists = {
                'ms/region/ascadian isles/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = ascadianislesNightRegionRule,
    },
    {
        id = 'ms/cell/public/mournhold',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = mournholdRegionRule,
    },
    {
        id = 'ms/region/red mountain',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = redMountainRegionRule,
    },
    {
        id = 'ms/region/red mountain/night',

        exclusions = {
            playlists = {
                'ms/region/red mountain/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = redMountainNightRegionRule,
    },
    {
        id = 'ms/region/solstheim',

        exclusions = {
            playlists = {
                'ms/region/solstheim/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = solstheimRegionRule,
    },
    {
        id = 'ms/region/solstheim/night',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = solstheimNightRegionRule,
    },
    {
        id = 'ms/region/west gash',

        exclusions = {
            playlists = {
                'ms/region/west gash/night'
            },
            tracks = {},
        },

        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = westGashRegionRule,
    },
    {
        id = 'ms/region/west gash/night',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = westGashNightRegionRule,
    }
}
