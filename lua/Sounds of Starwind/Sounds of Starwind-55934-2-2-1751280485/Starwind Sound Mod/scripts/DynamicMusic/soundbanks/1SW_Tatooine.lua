local soundbank =      {
  interiorOnly = true,
  cellNamePatterns = {
},
  cellNames = {
        'Tatooine',
	'Tatooine, Deep Sea',
      'Tatooine, Dune Sea',
	'Tatooine, Death Canyon',
	'Tatooine, Expanse'
    
    },
cellNamePatternsExclude = {
    'Sewer',
    'Sandriver',
    'Fields'
  },

  tracks = {
    {
      path='Music/Tatooine.mp3',
      length=240
    },
	    {
      path='Music/Tatooine2.mp3',
      length=330
    },
    {
      path='Music/Tatooine3.mp3',
      length=116
    }

  }
}

return soundbank
