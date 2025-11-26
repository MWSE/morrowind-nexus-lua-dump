---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local CoveCells = {
    ['corpse cove'] = true,
    ['corpse cove, lower cave'] = true,
    ['corpse cove, meat processing shack'] = true,
}

local GlinthollowCells = {
    ['glinthollow mine'] = true,
    ['glinthollow hive'] = true,
}

local GuldigulCells = {
    ['gundigul barrow'] = true,
    ['gundigul barrow, lower level'] = true,
}

local KilhavenCells = {
    ['kilhaven'] = true,
}

local KilhavenintCells = {
    ['kilhaven, the pale stag'] = true,
    ['kilhaven, attendant\'s dormitory'] = true,
    ['kilhaven, kilhaven trade house'] = true,
}

local TempleCells = {
    ['temple of meridia'] = true,
}

local TempleupperCells = {
    ['temple of meridia, sanctum of light'] = true,
}

local TemplelowerCells = {
    ['temple of meridia, lower sanctum'] = true,
}

local function CoveRule(playback)
    return playback.rules.cellNameExact(CoveCells)
end

local function GlinthollowRule(playback)
    return playback.rules.cellNameExact(GlinthollowCells)
end

local function GundigulRule(playback)
    return playback.rules.cellNameExact(GuldigulCells)
end

local function KilhavenRule(playback)
    return playback.rules.cellNameExact(KilhavenCells)
end

local function KilhavenintRule(playback)
    return playback.rules.cellNameExact(KilhavenintCells)
end

local function TempleRule(playback)
    return playback.rules.cellNameExact(TempleCells)
end

local function TempleupperRule(playback)
    return playback.rules.cellNameExact(TempleupperCells)
end

local function TemplelowerRule(playback)
    return playback.rules.cellNameExact(TemplelowerCells)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/AGB_Cove',
        priority = PlaylistPriority.CellExact,
        isValidCallback = CoveRule,
    },
    {
        id = 'ms/cell/AGBsch',
        priority = PlaylistPriority.CellExact,
        isValidCallback = GlinthollowRule,
    },
    {
        id = 'ms/cell/AGB_Barrow',
        priority = PlaylistPriority.CellExact,
        isValidCallback = GundigulRule,
    },
    {
        id = 'ms/cell/AGB_Kilhaven',
        priority = PlaylistPriority.CellExact,
        isValidCallback = KilhavenRule,
    },
    {
        id = 'ms/cell/AGB_Kilhavenint',
        priority = PlaylistPriority.CellExact,
        isValidCallback = KilhavenintRule,
    },
    {
        id = 'ms/region/AGB_Dunbal',
        priority = PlaylistPriority.CellExact,
        isValidCallback = TempleRule,
    },
    {
        id = 'ms/cell/AGB_USanctum',
        priority = PlaylistPriority.CellExact,
        isValidCallback = TempleupperRule,
    },
    {
        id = 'ms/cell/AGB_LSanctum',
        priority = PlaylistPriority.CellExact,
        isValidCallback = TemplelowerRule,
    },
}