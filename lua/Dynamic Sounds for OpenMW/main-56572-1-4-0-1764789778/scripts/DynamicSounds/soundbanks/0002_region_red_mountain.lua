local soundbank = {
  affectingRegions = {
		"red mountain region",
  },
  ambientLoopSounds = {
			{
          soundPath = "sounds\\DynamicSounds\\dungeon\\amb_os_whine_001.wav",
          volume = 2,
          loop = false,
      }, 
			{
          soundPath = "sounds\\DynamicSounds\\dungeon\\amb_os_whine_002.wav",
          volume = 2,
          loop = false,
          PlayChancePercent=10,
      }, 
			{
          soundPath = "sounds\\DynamicSounds\\dungeon\\amb_os_whine_003.wav",
          volume = 2,
          loop = false,
          PlayChancePercent=10,
      }, 
			{
          soundPath = "sounds\\DynamicSounds\\dungeon\\amb_os_whine_004.wav",
          volume = 2,
          loop = false,
          PlayChancePercent=10,
      },  
			{
          soundPath = "sounds\\DynamicSounds\\natural\\quake.wav",
          volume = 2,
          loop = false,
          PlayChancePercent=10,
      },        
  },
  
  objects = {
  },
                   
}
return soundbank


