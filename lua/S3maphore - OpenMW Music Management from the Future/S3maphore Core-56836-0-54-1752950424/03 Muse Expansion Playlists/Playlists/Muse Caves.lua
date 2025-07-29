---@type IDPresenceMap
local CaveStaticIds = require 'doc.caveStaticIds'

---@type IDPresenceMap
local NoTRPlugins = {
    ['cyr_main.esm'] = true,
    ['tr_mainland.esm'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/cave',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and not playback.rules.staticContentFile(NoTRPlugins)
                and playback.rules.staticExact(CaveStaticIds)
        end,
    }
}
