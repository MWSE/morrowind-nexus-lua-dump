-- MUSE_Vivec.lua — plays your Music/cell/vivec/* in all Vivec areas

local PlaylistPriority = require 'doc.playlistPriority'

---@type CellMatchPatterns
local VivecMatches = {
  -- Substring matches (case-insensitive)
  allowed = {
    'vivec',            -- catches all Vivec cells by name
    'foreign quarter',
    'hlaalu canton',
    'redoran canton',
    'telvanni canton',
    'temple canton',
    'st%.? delyn',      -- "St. Delyn" / "St Delyn"
    'st%.? olms',       -- "St. Olms"  / "St Olms"
    'plaza',
    'canalworks',
    'waistworks',
    'underworks',
    'sewers',
    'arena',            -- Arena + Arena Canton
  },
  disallowed = {},      -- nothing excluded
}

---@type S3maphorePlaylist[]
return {
  {
    id            = 'ms/cell/vivec',
    priority      = PlaylistPriority.CellMatch,
    randomize     = true,
    

    -- Explicit list so we don’t rely on folder scans
    tracks = {
      "Music/cell/vivec/vivec_1.mp3",
      "Music/cell/vivec/vivec_2.mp3",
      "Music/cell/vivec/vivec_3.mp3",
      "Music/cell/vivec/vivec_4.mp3",
      "Music/cell/vivec/vivec_5.mp3",
      "Music/cell/vivec/vivec_6.mp3",
      "Music/cell/vivec/vivec_7.mp3",
      "Music/cell/vivec/vivec_8.mp3",
      "Music/cell/vivec/vivec_9.mp3",
      "Music/cell/vivec/vivec_10.mp3",
      "Music/cell/vivec/vivec_11.mp3",
      "Music/cell/vivec/vivec_12.mp3",
      "Music/cell/vivec/vivec_13.mp3",
      "Music/cell/vivec/vivec_14.mp3",
      "Music/cell/vivec/vivec_15.mp3",
      "Music/cell/vivec/vivec_16.mp3",
      "Music/cell/vivec/vivec_17.mp3",
    },

    isValidCallback = function(playback)
      return not playback.state.isInCombat
         and playback.rules.cellNameMatch(VivecMatches)
    end,
  },
}
