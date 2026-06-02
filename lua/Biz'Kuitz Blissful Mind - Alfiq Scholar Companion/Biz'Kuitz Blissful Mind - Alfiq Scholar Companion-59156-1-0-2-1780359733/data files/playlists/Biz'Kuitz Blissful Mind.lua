local BizkuitzCells = {
    ['old ebonheart, tail tales'] = true,
	}
return {
    {
        id = "Bizkuitz Blissful Mind",
        priority = 1,
        randomize = false,
        cycleTracks = true,
        interruptMode = INTERRUPT.Other,
        fadeOut = 0,

        tracks = {
            "Music/mlss/bizkuitz_theme.mp3",
        },

        isValidCallback = function()
            return Playback.rules.cellNameExact(BizkuitzCells)
        end,
    },
}