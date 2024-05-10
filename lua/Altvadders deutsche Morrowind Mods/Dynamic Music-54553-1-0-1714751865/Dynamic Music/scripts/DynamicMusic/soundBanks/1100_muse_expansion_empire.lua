local soundBank =      {
  interiorOnly = true,
  id = "muse_expansion_empire",
  cellNamePatterns = {
    'Caldera',
    'Ebenherz',
    'Ebon Tower',
    'Seyda Neen',
    'Darius',
    'Feuerfalter',
    'Eisfalter',
    'falkenfalter',
    'Wolfen',
    'Rabenfels',
    'Pelagiad',
    'Mondfalter',
    'Buckfalter'

  },
  cellNamePatternsExclude = {
    'Mage\'s Guild',
    'Fighter\'s Guild',
    'Magiergilde',
    'Kriegergilde'
  },
  tracks = {
    {
      path="Music/MS/cell/Empire/exploration1.mp3",
      length=220
    },
    {
      path="Music/MS/cell/Empire/exploration2.mp3",
      length=206
    },
    {
      path="Music/MS/cell/Empire/exploration3.mp3",
      length=212
    },
    {
      path="Music/MS/cell/Empire/exploration4.mp3",
      length=210
    },
    {
      path="Music/MS/cell/Empire/exploration5.mp3",
      length=249
    }
  },
  combatTracks = {
    {
      path="Music/MS/combat/Empire/combat1.mp3",
      length=79
    },
    {
      path="Music/MS/combat/Empire/combat2.mp3",
      length=68
    },
    {
      path="Music/MS/combat/Empire/combat3.mp3",
      length=89
    }
  }
}

return soundBank
