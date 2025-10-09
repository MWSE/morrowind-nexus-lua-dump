---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local NoTRPlugins = {
    ['cyr_main.esm'] = true,
    ['tr_mainland.esm'] = true,
}

local function museCaveRule()
    return not Playback.state.cellIsExterior
        and not Playback.rules.staticContentFile(NoTRPlugins)
        and Playback.rules.staticExact(Tilesets.Cave)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/cave',
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = museCaveRule,
    }
}
