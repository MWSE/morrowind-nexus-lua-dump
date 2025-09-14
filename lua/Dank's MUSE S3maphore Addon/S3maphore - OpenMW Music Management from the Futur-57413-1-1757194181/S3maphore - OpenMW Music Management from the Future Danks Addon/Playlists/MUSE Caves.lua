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

        -- Add your dungeon ambient tracks here
        tracks = {
            "Music/cell/caves/dungeon_10.mp3",
      "Music/cell/caves/dungeon_11.mp3",
      "Music/cell/caves/dungeon_12.mp3",
      "Music/cell/caves/dungeon_13.mp3",
      "Music/cell/caves/dungeon_14.mp3",
      "Music/cell/caves/dungeon_15.mp3",
      "Music/cell/caves/dungeon_16.mp3",
      "Music/cell/caves/dungeon_17.mp3",
      "Music/cell/caves/dungeon_18.mp3",
      "Music/cell/caves/dungeon_19.mp3",
      "Music/cell/caves/dungeon_20.mp3",
      "Music/cell/caves/dungeon_21.mp3",
      "Music/cell/caves/dungeon_22.mp3",
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and not playback.rules.staticContentFile(NoTRPlugins)
                and playback.rules.staticExact(CaveStaticIds)
        end,
    }
}
