local TombCells = {
    ["andas ancestral tomb"] = true,
    ["andas ancestral tomb, cavern"] = true,
    ["andas ancestral tomb, depths"] = true,

    ["baram ancestral tomb"] = true,
    ["baram ancestral tomb, prison"] = true,
    ["baram ancestral tomb, sanctum"] = true,
    ["baram ancestral tomb, shrine"] = true,

    ["sadryon ancestral tomb"] = true,
    ["verelnim ancestral tomb"] = true,

    ["yanuvabdas, inner sanctum"] = true,
    ["yanuvabdas, prison"] = true,
}

return {
    {
        id = "Tombs of Zafirbel Bay - Silence",
        priority = 1,
        randomize = false,
        cycleTracks = true,
        interruptMode = INTERRUPT.Other,
        fadeOut = 0,

        tracks = {
            "Music/sch/SouD/Sil_90.mp3",
            "Music/sch/SouD/Sil_90.mp3",
        },

        isValidCallback = function()
            return Playback.rules.cellNameExact(TombCells)
        end,
    },
}