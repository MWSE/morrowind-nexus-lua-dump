---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local ImperialPatterns = {
    disallowed = {
        "sewer",
        "dungeon",
        "fields",
    },
    allowed = {
        'firewatch',
        'helnim',
        'old ebonheart',
        'teyn',
    },
}

---@type CellMatchPatterns
local IndorilPatterns = {
    allowed = {
        'ammar',
        'akamora',
        'bisandryon',
        'bosmora',
        'enamor dayn',
        'sailen',
        'dreynim',
        'gorne',
        'roa dyr',
        'meralag',
        'vhul',
        'dondril',
        'aimrah',
        'felms ithul',
        'saveri',
        'eravan',
        'selyn',
        'velonith',
        'rilsoan',
        'darvonis',
        'othrenis',
    },
    disallowed = {
        'sewer',
        'dungeon',
    }
}

---@type CellMatchPatterns
local TelvanniSettlementMatches = {
    allowed = {
        'alt bosara',
        'gah sadrith',
        'llothanis',
        'marog',
        'tel aranyon',
        'tel mothrivra',
        'tel muthada',
        'tel oren',
        'tel ouada',
        'verulas pass',
    },
    disallowed = {
        'dungeon',
        'sewer',
    }
}

---@type CellMatchPatterns
local TempleSettlementMatches = {
    allowed = {
        'necrom',
        'almas thirr',
    },
    disallowed = {
        'dungeon',
        'sewer',
    }
}

---@type CellMatchPatterns
local PortTelvannisPatterns = {
    allowed = {
        'port telvannis'
    },

    disallowed = {},
}

---@type IDPresenceMap
local OrethanRegions = {
    ['alt orethan region'] = true,
    ['lan orethan region'] = true,
}

---@type IDPresenceMap
local MournholdRegions = {
    ['mephalan vales region'] = true,
    ['sundered scar region'] = true,
    ['nedothril region'] = true,
}

---@type IDPresenceMap
local SeaRegions = {
    ['padomaic ocean region'] = true,
    ['sea of ghosts region'] = true,
}

---@type IDPresenceMap
local TelvannisRegions = {
    ['aranyon pass region'] = true,
    ['boethiah\'s spine region'] = true,
    ['dagon urul region'] = true,
    ['molagreahd region'] = true,
    ['sunad mora region'] = true,
    ['telvanni isles region'] = true,
}

---@type IDPresenceMap
local ThirrRegions = {
    ['roth roryn region'] = true,
    ['thirr valley region'] = true,
    ['othreleth woods region'] = true,
}

---@type IDPresenceMap
local UpperVelothisRegions = {
    ['clambering moor region'] = true,
    ['velothi mountains region'] = true,
    ['uld vraech region'] = true,
}

---@type IDPresenceMap
local TContentFiles = {
    ['tr_mainland.esm'] = true,
}

---@type CellMatchPatterns
local TombCellMatches = {
    allowed = {
        'ancestral tomb',
        'barrow',
        'burial',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function caveTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.staticExact(Tilesets.Cave)
end

---@type ValidPlaylistCallback
local function tombTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.cellNameMatch(TombCellMatches)
end

---@type PlaylistFallback
local TRFallbackData = {
    tracks = {
        'music/ms/general/trairdepths/dreamy athmospheres 1.mp3',
        'music/ms/general/trairdepths/dreamy athmospheres 2.mp3',
    },
    playlistChance = 0.60,
}

---@type PlaylistFallback
local TRDungeonFallback = {
    tracks = {
        'music/ms/general/tr dungeon/darkness.mp3',
    },
    playlistChance = 0.33,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/region/aanthirin',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'aanthirin region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Thirr',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'music/ms/region/aanthirin/thirr.mp3',
            'music/ms/region/aanthirin/thirr 1.mp3',
            'music/ms/region/aanthirin/thirr 2.mp3'
        },

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.region(ThirrRegions)
        end,
    },
    {
        id = 'ms/region/armun ashlands region',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'armun ashlands region'
        end,
    },
    {
        id = 'ms/region/grey meadows region',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'grey meadows region'
        end,
    },
    {
        id = 'ms/region/alt orethan region',
        priority = PlaylistPriority.Never,
        randomize = true,

        isValidCallback = function()
            return false
        end,
    },
    {
        id = 'ms/region/lan orethan',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = {
            playlists = {
                'ms/region/alt orethan region',
            },
            tracks = {
                'music/ms/general/trairdepths/dreamy athmospheres 1.mp3',
                'music/ms/general/trairdepths/dreamy athmospheres 2.mp3',
            },
            playlistChance = 0.60,
        },

        isValidCallback = function()
            return Playback.rules.region(OrethanRegions)
        end,
    },
    {
        id = 'ms/interior/tr dwemer',
        priority = PlaylistPriority.Tileset - 1,
        randomize = true,

        fallback = TRDungeonFallback,

        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(TContentFiles)
                and Playback.rules.staticExact(Tilesets.Dwemer)
        end,
    },
    {
        id = 'ms/interior/tr cave',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        fallback = TRDungeonFallback,

        isValidCallback = caveTRRule,
    },
    {
        id = 'ms/interior/tr tomb',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        fallback = TRDungeonFallback,

        isValidCallback = tombTRRule,
    },
    {
        id = 'ms/region/mournhold hills',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.region(MournholdRegions)
        end,
    },
    {
        id = 'ms/cell/imperialcity',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(ImperialPatterns)
        end,
    },
    {
        id = 'ms/cell/mourncity',
        priority = PlaylistPriority.City,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(IndorilPatterns)
        end,
    },
    {
        id = 'ms/region/telvanni isles',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(PortTelvannisPatterns)
        end,
    },
    {
        id = 'ms/cell/telcity',
        priority = PlaylistPriority.City,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(TelvanniSettlementMatches)
        end,
    },
    {
        id = 'ms/region/sacred lands region',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(TempleSettlementMatches)
        end,
    },
    {
        id = 'ms/region/sacred lands region',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'sacred lands region'
        end,
    },
    {
        id = 'ms/region/seas',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return Playback.rules.region(SeaRegions)
        end,
    },
    {
        id = 'ms/region/telvannis',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.region(TelvannisRegions)
        end,
    },
    {
        id = 'ms/region/velothis upper',
        priority = PlaylistPriority.Region,
        randomize = true,

        fallback = TRFallbackData,

        isValidCallback = function()
            return Playback.rules.region(UpperVelothisRegions)
        end
    }
}
