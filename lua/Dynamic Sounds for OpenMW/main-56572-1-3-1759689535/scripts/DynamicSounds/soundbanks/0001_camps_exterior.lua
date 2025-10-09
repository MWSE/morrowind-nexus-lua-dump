local soundbank = {

    isInterior = false,
    affectingCells = {
		-- base game
        'Ahemmusa Camp',
        'Erabenimsun Camp',
        'Urshilaku Camp',
        'Zainab Camp',
        -- TR
        'Ishanuran Camp',
        'Obainat Camp',
        'Ernabapalit Camp',
        'Tirigan Camp',
        'Urnuridun Camp',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\cities\\village_lp.wav",
            loop = true,
        },
        {
            soundPath = "sounds\\DynamicSounds\\misc\\windchime.wav",
            loop = false,
            PlayChancePercent = 40,
        },        
 
    },

    objects = {
    },

}


return soundbank