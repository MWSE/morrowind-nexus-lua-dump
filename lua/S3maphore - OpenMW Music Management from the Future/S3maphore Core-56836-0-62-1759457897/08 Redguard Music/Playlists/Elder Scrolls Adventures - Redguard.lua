---@type IDPresenceMap
local RedguardRegions = {
  ['colovian highlands region'] = true,
  ['gilded hills region'] = true,
  ['strident coast region'] = true,
  ['gold coast region'] = true,
  ['abecean sea region'] = true,
  ['stirk isle region'] = true,
  ['dasek marsh region'] = true,
  ['kvetchi pass region'] = true,
}

---@type CellMatchPatterns
local RGCityPatterns = {
  allowed = {
    'anvil',
    'brina cross',
    'charach',
    'archad',
    'hal sadek',
    'marav',
    'thresvy',
    'salthearth',
    'goldstone',
    'fort heath',
    'fort telodrach',
    'talgiana orchard',
  },

  disallowed = {},
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
  {
    id = 'Elder Scrolls Adventures - Redguard: Regions',
    priority = PlaylistPriority.Region - 1,
    randomize = true,

    tracks = {
      'Music/redguardmusic/01. Main Theme.mp3',
      'Music/redguardmusic/02. Theme 1.mp3',
      'Music/redguardmusic/03. Theme 2.mp3',
    },

    isValidCallback = function(playback)
      return not playback.state.isInCombat
          and playback.rules.region(RedguardRegions)
    end,
  },
  {
    id = 'Elder Scrolls Adventures - Redguard: Combat',
    --- Slightly lower priority than normal since these might conflict with TR playlists
    priority = PlaylistPriority.BattleMod - 1,

    tracks = {
      'Music/redguardmusic/04. Theme 3.mp3',
      'Music/redguardmusic/05. Theme 4.mp3',
    },

    isValidCallback = function(playback)
      return playback.state.isInCombat
          and playback.rules.region(RedguardRegions)
    end,
  },
  {
    id = 'Elder Scrolls Advnetures - Redguard: Cities',
    priority = PlaylistPriority.CellMatch - 1,

    tracks = {
      'Music/redguardmusic/01. Main Theme.mp3',
      'Music/redguardmusic/02. Theme 1.mp3',
      'Music/redguardmusic/03. Theme 2.mp3',
    },

    isValidCallback = function(playback)
      return not playback.state.isInCombat
          and playback.rules.cellNameMatch(RGCityPatterns)
    end,
  }
}
