---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local DwemerEnemyNames = {
    ['centurion sphere'] = true,
    ['centurion spider'] = true,
    ['shock centurion'] = true,
    ['steam centurion'] = true,
    ['steam guardian'] = true,
    ['dwarven spectre'] = true,
    ['dahrk mezalf'] = true,
    ['hulking fabricant'] = true,
    ['verminous fabricant'] = true,
    ['imperfect'] = true,
    ['advanced steam centurion'] = true,
    ['centurion archer'] = true,
    ['repair spider'] = true,
    ['centurion spiderling'] = true,
    ['luminarium spider'] = true,
}

---@type ValidPlaylistCallback
local function dwarvenEnemyRule(playback)
    return playback.rules.combatTargetExact(DwemerEnemyNames)
end

---@type ValidPlaylistCallback
local function dwemerStaticRule()
    return not Playback.state.isInCombat
        and not Playback.state.cellIsExterior
        and Playback.rules.staticExact(Tilesets.Dwemer)
end

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Dwemer Ruins',
        id = 'ms/cell/dwemer',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = dwemerStaticRule,
    },
    {
        -- 'MUSE - Dwemer Enemies',
        id = 'ms/combat/dwemer',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = dwarvenEnemyRule,
    },
}
