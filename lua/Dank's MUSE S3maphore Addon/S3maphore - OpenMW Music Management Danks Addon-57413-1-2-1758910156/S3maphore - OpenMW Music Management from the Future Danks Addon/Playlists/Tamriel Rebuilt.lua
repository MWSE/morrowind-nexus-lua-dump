---@type IDPresenceMap
local DwemerStaticIds = {
    ['in_dwe_archway00_end'] = true,
    ['in_dwe_archway00_exp'] = true,
    ['in_dwe_corr2_00_exp'] = true,
    ['in_dwe_corr4_exp'] = true,
    ['in_dwe_end00_exp'] = true,
    ['in_dwe_hall00_exp'] = true,
    ['in_dwe_hall_enter_00'] = true,
    ['in_dwe_hall_wall00_bk'] = true,
    ['in_dwe_hall_wall00_exp'] = true,
    ['in_dwe_pillar00_exp'] = true,
    ['in_dwe_pill_bk00'] = true,
    ['in_dwe_pill_bk01'] = true,
    ['in_dwe_pill_bk02'] = true,
    ['in_dwe_pill_bk03'] = true,
    ['in_dwe_pipe00_exp'] = true,
    ['in_dwe_ramp00_exp'] = true,
    ['in_dwe_rod00_exp'] = true,
    ['in_dwe_rod01_exp'] = true,
    ['in_dwe_rubble00'] = true,
    ['in_dwe_rubble01'] = true,
    ['in_dwe_rubble02'] = true,
    ['in_dwe_slate00'] = true,
    ['in_dwe_slate01'] = true,
    ['in_dwe_slate02'] = true,
    ['in_dwe_slate03'] = true,
    ['in_dwe_slate04'] = true,
    ['in_dwe_slate05'] = true,
    ['in_dwe_slate06'] = true,
    ['in_dwe_slate07'] = true,
    ['in_dwe_slate08'] = true,
    ['in_dwe_slate09'] = true,
    ['in_dwe_slate10'] = true,
    ['in_dwe_slate11'] = true,
    ['in_dwe_turbine00_exp'] = true,
    ['in_dwe_utilcorr00_exp'] = true,
    ['in_dwe_utilcorr01_exp'] = true,
    ['in_dwe_weathmach00_exp'] = true,
    ['in_dwr_tower_int00'] = true,
    ['in_dwr_tower_int000'] = true,
    ['in_dwr_tower_int001'] = true,
    ['in_dwrv_corr1_00'] = true,
    ['in_dwrv_corr2_00'] = true,
    ['in_dwrv_corr2_01'] = true,
    ['in_dwrv_corr2_02'] = true,
    ['in_dwrv_corr2_03'] = true,
    ['in_dwrv_corr2_04'] = true,
    ['in_dwrv_corr3_00'] = true,
    ['in_dwrv_corr3_01'] = true,
    ['in_dwrv_corr3_02'] = true,
    ['in_dwrv_corr4_00'] = true,
    ['in_dwrv_corr4_01'] = true,
    ['in_dwrv_corr4_02'] = true,
    ['in_dwrv_corr4_03'] = true,
    ['in_dwrv_corr4_04'] = true,
    ['in_dwrv_corr4_05'] = true,
    ['in_dwrv_doorjam00'] = true,
    ['in_dwrv_door_static00'] = true,
    ['in_dwrv_enter00_dn'] = true,
    ['in_dwrv_gear00'] = true,
    ['in_dwrv_gear10'] = true,
    ['in_dwrv_gear20'] = true,
    ['in_dwrv_hall2_00'] = true,
    ['in_dwrv_hall3_00'] = true,
    ['in_dwrv_hall4_00'] = true,
    ['in_dwrv_hall4_01'] = true,
    ['in_dwrv_hall4_02'] = true,
    ['in_dwrv_hall4_03'] = true,
    ['in_dwrv_lift00'] = true,
    ['in_dwrv_obsrv00'] = true,
    ['in_dwrv_oilslick00'] = true,
    ['in_dwrv_scope00'] = true,
    ['in_dwrv_scope10'] = true,
    ['in_dwrv_scope20'] = true,
    ['in_dwrv_scope30'] = true,
    ['in_dwrv_scope40'] = true,
    ['in_dwrv_scope50'] = true,
    ['in_dwrv_shaft00'] = true,
    ['in_dwrv_shaft10'] = true,
    ['in_dwrv_wall00'] = true,
    ['in_dwrv_wall10'] = true,
    ['in_dwrv_wall_nchuleftingth1'] = true,
}

local CaveStaticIds = require 'doc.caveStaticIds'

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

local PlaylistPriority = require 'doc.playlistPriority'

---@type ValidPlaylistCallback
local function caveTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.staticExact(CaveStaticIds)
end

---@type ValidPlaylistCallback
local function tombTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.cellNameMatch(TombCellMatches)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'Tamriel Rebuilt - Aanthirin',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Aanthirin/Aanthirin 1.mp3',
            'Music/MS/region/Aanthirin/Aanthirin 2.mp3',
            'Music/MS/region/Aanthirin/Thirr.mp3',
            'Music/MS/region/Aanthirin/Thirr 1.mp3',
            'Music/MS/region/Aanthirin/Thirr 2.mp3'
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'aanthirin region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Thirr',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Aanthirin/Thirr.mp3',
            'Music/MS/region/Aanthirin/Thirr 1.mp3',
            'Music/MS/region/Aanthirin/Thirr 2.mp3'
        },

        isValidCallback = function(playback)
            return playback.rules.region(ThirrRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Armun Ashlands',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Armun Ashlands Region/Ashlands.mp3',

        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'armun ashlands region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Grey Meadows',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Grey Meadows Region/Grey Meadows 1.mp3',
            'Music/MS/region/Grey Meadows Region/Grey Meadows 2.mp3',
        },
        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'grey meadows region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Orethan',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Alt Orethan Region/Mournhold fields.mp3',
            'Music/MS/region/Lan Orethan/Lan Orethan.mp3',
            'Music/MS/region/Lan Orethan/Mournhold explore.mp3',
            'Music/MS/region/Lan Orethan/Road To Mournhold.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(OrethanRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Dwemer Ruins',
        priority = PlaylistPriority.Tileset - 1,
        randomize = true,
        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/tr dwemer/Dwemer ruins.mp3',
            'Music/MS/interior/tr dwemer/Resonance.mp3',
        },
        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(TContentFiles)
                and playback.rules.staticExact(DwemerStaticIds)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Caves',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/TR cave/Cave 1.mp3',
            'Music/MS/interior/TR cave/Cave 2.mp3',
        },

        isValidCallback = caveTRRule,
    },
    {
        id = 'Tamriel Rebuilt - Tombs',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/TR tomb/Tombs.mp3',
        },

        isValidCallback = tombTRRule,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Regions',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 1.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 2.mp3',
            'Music/MS/region/Mournhold hills/Mournhold explore.mp3',
            'Music/MS/region/Mournhold hills/Mournhold fields.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(MournholdRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Imperial',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/cell/ImperialCity/Beacon of Cyrodiil.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(ImperialPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Setlement',
        priority = PlaylistPriority.City,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/cell/MournCity/Indoril Settlement.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(IndorilPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Port Telvannis',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/region/Telvanni Isles/Port Telvannis.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(PortTelvannisPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvanni Settlement',
        priority = PlaylistPriority.City,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/cell/TelCity/Telvanni settlement.mp3',

        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(TelvanniSettlementMatches)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Temple Settlement',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 1.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 3.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 4.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(TempleSettlementMatches)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Sacred Lands',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 1.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 3.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 4.mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'sacred lands region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Seas',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/region/Seas/Dreamy athmospheres 1.mp3',
            'Music/MS/region/Seas/Dreamy athmospheres 2.mp3',
        },
        isValidCallback = function(playback)
            return playback.rules.region(SeaRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvannis Regions',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Telvannis/Tellvannis 1.mp3',
            'Music/MS/region/Telvannis/Tellvannis 2.mp3',
            'Music/MS/region/Telvannis/Telvannis fields.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(TelvannisRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Upper Velothis',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Velothis Upper/Through The Mountains.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(UpperVelothisRegions)
        end
    }
}
