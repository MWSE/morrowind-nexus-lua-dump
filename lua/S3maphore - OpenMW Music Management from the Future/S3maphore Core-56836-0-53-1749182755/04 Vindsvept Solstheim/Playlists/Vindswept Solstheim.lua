---@type IDPresenceMap
local FelsaadRegions = {
    ['felsaad coast region'] = true,
    ['thirsk region'] = true,
}

---@type CellMatchPatterns
local LakeMatches = {
    allowed = {
        'fjalding',
    },

    disallowed = {},
}

---@type CellMatchPatterns
local TownMatches = {
    allowed = {
        'solstheim',
        'skaal village',
        'raven rock',
        'frostmoth',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function felsaadRegionRule(playback)
    return playback.rules.region(FelsaadRegions)
end

---@type ValidPlaylistCallback
local function hirstaangRegionRule(playback)
    return playback.state.self.cell.region == 'hirstaang forest region'
end

---@type ValidPlaylistCallback
local function isinfierRegionRule(playback)
    return playback.state.self.cell.region == 'isinfier plains region'
end

---@type ValidPlaylistCallback
local function lakeCellRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(LakeMatches)
end

---@type ValidPlaylistCallback
local function moesringRegionRule(playback)
    return playback.state.self.cell.region == 'moesring mountains region'
end

---@type ValidPlaylistCallback
local function solstheimTownRule(playback)
    return playback.rules.cellNameMatch(TownMatches)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'Vindswept Solstheim - Lake',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Celtic Folk Music - Vindsvept - Lake of Light.mp3'
        },

        isValidCallback = lakeCellRule,
    },
    {
        -- Make a nighttime variant of this playlist
        id = 'Vindsvept Solstheim - Town',
        priority = PlaylistPriority.City,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Tavern Folk Music - Vindsvept - Hearthfire.mp3',
            'Music/Vindsvept/Emotional Far East Music - Vindsvept - Clarity.mp3',
            'Music/Vindsvept/Harp Ambient Music - Vindsvept - The Fae.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Munins Return.mp3',
        },

        isValidCallback = solstheimTownRule,
    },
    {
        id = 'Vindsvept Soltheim - Moesring',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Orchestral Music - Vindsvept - Bringer of Rain.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Hugins Flight.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Munins Return.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Reverie.mp3',
            'Music/Vindsvept/Folk Music - Vindsvept - What Lies Beyond.mp3',
        },

        isValidCallback = moesringRegionRule,
    },
    {
        id = 'Vindsvept Solstheim/Hirstaang',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Relaxing Folk Music - Vindsvept - Frozen in Time.mp3',
            'Music/Vindsvept/Celtic Folk Music - Vindsvept - Nightfall.mp3',
            'Music/Vindsvept/Harp Ambient Music - Vindsvept - The Fae.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Reverie.mp3',
            'Music/Vindsvept/Folk Music - Vindsvept - What Lies Beyond.mp3',
        },

        isValidCallback = hirstaangRegionRule,
    },
    {
        id = 'Vindsvept Solstheim/Isinfier Plains',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Wayworn.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Hugins Flight.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Munins Return.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Reverie.mp3',
            'Music/Vindsvept/Folk Music - Vindsvept - What Lies Beyond.mp3',
        },

        isValidCallback = isinfierRegionRule,
    },
    {
        id = 'Vindsvept Solstheim/Felsaad Coast',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/Vindsvept/Celtic Folk Music - Vindsvept - Lake of Light.mp3',
            'Music/Vindsvept/Celtic Folk Music - Vindsvept - Nightfall.mp3',
            'Music/Vindsvept/Harp Ambient Music - Vindsvept - The Fae.mp3',
            'Music/Vindsvept/Emotional Folk Music - Vindsvept - Reverie.mp3',
            'Music/Vindsvept/Folk Music - Vindsvept - What Lies Beyond.mp3',
        },

        isValidCallback = felsaadRegionRule,
    },
}
