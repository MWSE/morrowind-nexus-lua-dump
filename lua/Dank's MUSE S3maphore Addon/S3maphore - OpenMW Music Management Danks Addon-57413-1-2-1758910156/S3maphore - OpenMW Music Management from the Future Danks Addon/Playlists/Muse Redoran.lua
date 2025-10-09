---@type IDPresenceMap
local RedoranEnemyNames = {
    ['redoran guard'] = true,
    ['bolvyn venim'] = true,
    ['minor arobar'] = true,
    ['garisa llethri'] = true,
    ['mistress brara morvayn'] = true,
    ['hlaren ramoran'] = true,
    ['athyn sarethi'] = true,
    ['banden indarys'] = true,
}

---@type ValidPlaylistCallback
local function redoranEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(RedoranEnemyNames)
end

---@type CellMatchPatterns
local RedoranCellNames = {
    allowed = {
        'ald-ruhn',
        'maar gan',
        'ald velothi',
        'khuul',
        'indarys manor',
        'gnisis',
    },

    disallowed = {
        'sewers',
        'eggmine',
    },
}

---@type ValidPlaylistCallback
local function redoranCellRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(RedoranCellNames)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Redoran Settlement',
        id = 'ms/cell/redoran',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = redoranCellRule,

    },
    {
        -- 'MUSE - Redoran Enemies',
        id = 'ms/combat/redoran',
        priority = PlaylistPriority.BattleMod,

        isValidCallback = redoranEnemyRule,
    }
}
