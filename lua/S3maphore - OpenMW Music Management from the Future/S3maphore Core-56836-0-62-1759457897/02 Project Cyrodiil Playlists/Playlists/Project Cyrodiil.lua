---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type CellMatchPatterns
local AnvilPatterns = {
    allowed = {
        "anvil",
        "marav",
        "hal sadek",
        "archad",
        "brina cross",
        "goldstone",
        "charach"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    },
}

---@type IDPresenceMap
local StirkRegions = {
    ['stirk isle region'] = true,
    ['dasek marsh region'] = true,
}

---@type CellMatchPatterns
local SutchPatterns = {
    allowed = {
        "sutch",
        "thyra",
        "isvorhal",
        "seppaki",
        "salthearth"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    }
}

---@type CellMatchPatterns
local TemplePatterns = {
    allowed = {
        "anvil, chapel",
        "anvil, temple",
        "brina cross, chapel",
        "charach, chapel",
        "fort heath, chapel",
        "goldstone, chapel",
        "thresvy, chapel"
    },

    disallowed = {},
}

---@type IDPresenceMap
local CyrContentFiles = {
    ['cyr_main.esm'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        -- 'Project Cyrodiil - Abecean Shores/Imperial Crypts',
        id = 'ms/interior/cyrodiil tombs imperial',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(CyrContentFiles)
                and Playback.rules.staticExact(Tilesets.Crypt)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Brennan Bluffs',
        id = 'ms/region/cyrodiil brennan bluffs',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'gilded hills region'
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Colovian Barrows',
        id = 'ms/interior/cyrodiil tombs colovian',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(CyrContentFiles)
                and Playback.rules.staticExact(Tilesets.Barrows)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Caves',
        id = 'ms/interior/cyrodiil caves',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(CyrContentFiles)
                and Playback.rules.staticExact(Tilesets.Cave)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Ayleid',
        id = 'ms/interior/cyrodiil ayleid',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(CyrContentFiles)
                and Playback.rules.staticExact(Tilesets.Ayleid)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Kingdom of Sutch',
        id = 'ms/cell/cyrodiil sutch',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(SutchPatterns)
        end
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Kingdom of Anvil',
        id = 'ms/cell/cyrodiil anvil',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return Playback.rules.cellNameMatch(AnvilPatterns)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Strident Coast',
        id = 'ms/region/cyrodiil strident coast',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return Playback.state.self.cell.region == 'gold coast region'
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Stirk Isle',
        id = 'ms/region/cyrodiil stirk isle',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return Playback.rules.region(StirkRegions)
        end,
    },
    {
        -- 'Project Cyrodiil - Abecean Shores/Divine Temples',
        id = 'ms/cell/nine divine temples',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.cellIsExterior and Playback.rules.cellNameMatch(TemplePatterns)
        end,
    },
}
