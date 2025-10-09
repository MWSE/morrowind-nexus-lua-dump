---@type S3maphorePlaylistEnv
_ENV = _ENV

local core = require 'openmw.core'

---@type IDPresenceMap
local pilgrimageCells = {
    ["fields of kummu"] = true,
    ["koal cave"] = true,
    ["koal cave entrance"] = true,
    ["mount assarnibibi"] = true,
    --- ??? These ones aren't defined in LPilgrimageCaves or LPilgrimage
    -- ["mount kand"] = true,
    -- ["mount kand, cavern"] = true,
}

---@type ValidPlaylistCallback
local function pilgrimageRule()
    return Playback.rules.cellNameExact(pilgrimageCells)
end

---@type IDPresenceMap
local valleyCells = {
    ['valley of the wind'] = true,
    ['airan\'s teeth'] = true,
}

---@type S3maphoreCellGrid[]
local valleyGrids = {
    { x = 6, y = 13, },
    { x = 7, y = 14 },
}

---@type ValidPlaylistCallback
local function valleyofthewindCellRule()
    return Playback.rules.exteriorGrid(valleyGrids)
        or Playback.rules.cellNameExact(valleyCells)
end

---@type IDPresenceMap
local sacredStonesMatches = {
    ['beast stone'] = true,
    ['earth stone'] = true,
    ['sun stone'] = true,
    ['tree stone'] = true,
    ['water stone'] = true,
    ['wind stone'] = true,
}

local hasTOTSP = core.contentFiles.has('Solstheim Tomb of The Snow Prince.esm')

---@type S3maphoreCellGrid[]
local sacredStoneGrids
if hasTOTSP then
    sacredStoneGrids = {
        { x = 19,  y = 26, },
        { x = -13, y = 30, },
        { x = -13, y = 25, },
        { x = -15, y = 31, },
        { x = -15, y = 27, },
        { x = -19, y = 29, },
    }
else
    sacredStoneGrids = {
        { x = -20, y = 24, },
        { x = -20, y = 19, },
        { x = -22, y = 25, },
        { x = -22, y = 21, },
        { x = -26, y = 23, },
        { x = -26, y = 20, },
    }
end

---@type ValidPlaylistCallback
local function sacredStonesCellRule()
    return Playback.rules.exteriorGrid(sacredStoneGrids)
        or Playback.rules.cellNameExact(sacredStonesMatches)
end

---@type ValidPlaylistCallback
local function sanctusShrineRule()
    return Playback.state.cellName == 'sanctus shrine'
end

---@type S3maphorePlaylist[]
return {

    {
        id = 'ms/cell/landmark/valley of the wind',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = valleyofthewindCellRule,
    },
    {
        id = 'ms/cell/landmark/khartag point',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = function()
            return Playback.state.cellName == 'khartag point'
        end
    },
    {
        id = 'ms/cell/landmark/pilgrimage',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = pilgrimageRule,
    },
    {
        id = 'ms/cell/landmark/sacred stones',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = sacredStonesCellRule,
    },
    {
        id = 'ms/cell/landmark/sanctus shrine',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = sanctusShrineRule,
    },
}
