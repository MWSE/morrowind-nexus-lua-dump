---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local CaeSchDBA = {
    ['arys ancestral tomb'] = true,
    ['nammu ruhn'] = true,
}

local function CoveRule(playback)
    return playback.rules.cellNameExact(CaeSchDBA)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'sch/DBA',
        priority = PlaylistPriority.CellExact,
        isValidCallback = CoveRule,
    },
}