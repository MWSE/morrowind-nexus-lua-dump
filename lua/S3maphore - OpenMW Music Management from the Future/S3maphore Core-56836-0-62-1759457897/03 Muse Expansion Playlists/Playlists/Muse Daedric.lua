---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local DaedricEnemyNames = {
    ['flame atronach'] = true,
    ['frost  atronach'] = true,
    ['nomeg gwai'] = true,
    ['storm atronach'] = true,
    ['clannfear'] = true,
    ['daedroth'] = true,
    ['hrelvesuu'] = true,
    ['menta na'] = true,
    ['anhaedra'] = true,
    ['dremora'] = true,
    ['krazzt'] = true,
    ['dremora lord'] = true,
    ['lord dregas volar'] = true,
    ['golden saint'] = true,
    ['staada'] = true,
    ['hunger'] = true,
    ['ogrim'] = true,
    ['ogrim titan'] = true,
    ['scamp'] = true,
    ['lustidrike'] = true,
    ['creeper'] = true,
    ['winged twilight'] = true,
    ['molag grunda'] = true,
}

---@type ValidPlaylistCallback
local function daedricEnemyRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetExact(DaedricEnemyNames)
end

---@type ValidPlaylistCallback
local function daedricTilesetRule()
    return not Playback.state.cellIsExterior
        and Playback.rules.staticExact(Tilesets.Daedric)
end

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Daedric Ruins',
        id = 'ms/cell/daedric',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = daedricTilesetRule,
    },
    {
        -- 'MUSE - Daedric Enemies',
        id = 'ms/combat/daedric',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = daedricEnemyRule,
    }
}
