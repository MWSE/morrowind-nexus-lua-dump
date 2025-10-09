---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local CrystalCityCells = {
    ['massama,'] = true,
    ['massama, abandoned house'] = true,
    ['massama, argonian clanhouse'] = true,
    ['massama, catacombs'] = true,
    ['massama cave'] = true,
    ['massama, city'] = true,
    ['massama, commons'] = true,
    ['massama, deekul\'s tavern'] = true,
    ['massama, derelict manor'] = true,
    ['massama, dilapidated house'] = true,
    ['massama, frees-with-fire, smith'] = true,
    ['massama, house of miners'] = true,
    ['massama, house of the poor'] = true,
    ['massama, jowia, clothier'] = true,
    ['massama, khajiit clanhouse'] = true,
    ['massama, lighthouse'] = true,
    ['massama, magician\'s club'] = true,
    ['massama, ma\'zasha, trader'] = true,
    ['massama, office of glass'] = true,
    ['massama, picks-the-leaves, alchemist'] = true,
    ['massama, refugee common house'] = true,
    ['massama, ruined tower'] = true,
    ['massama, sirramus manor'] = true,
    ['massama, smuggler\'s den'] = true,
    ['massama, temple of the three'] = true,
    ['massama, the lazy lantern'] = true,
    ['massama, tiwa-duun, fisherman'] = true,
    ['massama, trinibane manor'] = true,
    ['massama, twin moons club'] = true,
    ['massama, uxith-kei garrison'] = true,
}

local function crystalCityRule(playback)
    return playback.rules.cellNameExact(CrystalCityCells)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'MOMW Patches - Secrets of the Crystal City',
        priority = PlaylistPriority.CellExact,

        tracks = {
            'music/aa22/tew_aa_3.mp3',
        },

        isValidCallback = crystalCityRule,
    },
}
