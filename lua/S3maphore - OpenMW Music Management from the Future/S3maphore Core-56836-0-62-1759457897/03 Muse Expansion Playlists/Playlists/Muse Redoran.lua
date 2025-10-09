---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type NumericPresenceMap
local redoranFactionRule = {
    redoran = { min = 1 },
}

---@type ValidPlaylistCallback
local function redoranEnemyRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetFaction(redoranFactionRule)
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
local function redoranCellRule()
    return not Playback.state.isInCombat
        and Playback.rules.cellNameMatch(RedoranCellNames)
end

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
